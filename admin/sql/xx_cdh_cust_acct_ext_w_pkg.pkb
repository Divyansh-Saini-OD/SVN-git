create or replace PACKAGE BODY xx_cdh_cust_acct_ext_w_pkg
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_CUST_ACCT_EXT_W_PKG                                              |
-- | Description:  This package is the Wrapper for the Package XX_CDH_CUST_ACCT_EXT_PKG   |
-- |                                              |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date         Author               Remarks                                 |
-- |=======   ===========  ==================   ==========================================|
-- |DRAFT 1A  17-MAR-2010      Mangala            Initial draft version                   |
-- |DRAFT 1B  17-DEC-2016     Sridhar           Modified complete_cust_doc procedure for 39912                   |
-- |1.1       20-Nov-2018    Reddy Sekhar       Code changes for Req NAIT-61952 and 66520 |
-- |1.2       08-APR-2020    Divyansh Saini     Code changes for tariff                   |
-- |                                                                                      |
-- |======================================================================================|
-- | Subversion Info:                                                                     |
-- | $HeadURL: file:///app/svnrepos/od/crm/trunk/xxcrm/admin/sql/XX_CDH_CUST_ACCT_EXT_W_PKG.pkb $                                                                          |
-- | $Rev: 291512 $                                                                              |
-- | $Date: 2018-11-21 03:38:19 -0500 (Wed, 21 Nov 2018) $                                                                             |
-- |                                                                                      |
-- +======================================================================================+
AS
-- +==================================================================================+
-- | Name             : INSERT_ROW                                                    |
-- | Description      : This procedure shall insert data into XX_CDH_CUST_ACCT_EXT_B  |
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                           |
-- |                                              |
-- +==================================================================================+
   PROCEDURE insert_row (
      x_rowid               IN OUT NOCOPY   VARCHAR2,
      p_extension_id        IN              NUMBER,
      p_cust_account_id     IN              NUMBER,
      p_attr_group_id       IN              NUMBER,
      p_c_ext_attr1         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr2         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr3         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr4         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr5         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr6         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr7         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr8         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr9         IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr10        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr11        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr12        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr13        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr14        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr15        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr16        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr17        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr18        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr19        IN              VARCHAR2 DEFAULT NULL,
      p_c_ext_attr20        IN              VARCHAR2 DEFAULT NULL,
      p_n_ext_attr1         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr2         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr3         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr4         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr5         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr6         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr7         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr8         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr9         IN              NUMBER DEFAULT NULL,
      p_n_ext_attr10        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr11        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr12        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr13        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr14        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr15        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr16        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr17        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr18        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr19        IN              NUMBER DEFAULT NULL,
      p_n_ext_attr20        IN              NUMBER DEFAULT NULL,
      p_d_ext_attr1         IN              DATE DEFAULT NULL,
      p_d_ext_attr2         IN              DATE DEFAULT NULL,
      p_d_ext_attr3         IN              DATE DEFAULT NULL,
      p_d_ext_attr4         IN              DATE DEFAULT NULL,
      p_d_ext_attr5         IN              DATE DEFAULT NULL,
      p_d_ext_attr6         IN              DATE DEFAULT NULL,
      p_d_ext_attr7         IN              DATE DEFAULT NULL,
      p_d_ext_attr8         IN              DATE DEFAULT NULL,
      p_d_ext_attr9         IN              DATE DEFAULT NULL,
      p_d_ext_attr10        IN              DATE DEFAULT NULL,
      p_tl_ext_attr1        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr2        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr3        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr4        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr5        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr6        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr7        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr8        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr9        IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr10       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr11       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr12       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr13       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr14       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr15       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr16       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr17       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr18       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr19       IN              VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr20       IN              VARCHAR2 DEFAULT NULL,
      p_creation_date       IN              DATE DEFAULT SYSDATE,
      p_created_by          IN              NUMBER DEFAULT fnd_global.user_id,
      p_last_update_date    IN              DATE DEFAULT SYSDATE,
      p_last_updated_by     IN              NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login   IN              NUMBER DEFAULT fnd_global.user_id,
	  p_bc_pod_flag         IN              VARCHAR2 DEFAULT NULL, --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520,
      p_fee_option          IN              VARCHAR2 DEFAULT NULL --code added for 1.2
	  )
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.insert_row (x_rowid,
                                           p_extension_id,
                                           p_cust_account_id,
                                           p_attr_group_id,
                                           p_c_ext_attr1,
                                           p_c_ext_attr2,
                                           p_c_ext_attr3,
                                           p_c_ext_attr4,
                                           p_c_ext_attr5,
                                           p_c_ext_attr6,
                                           p_c_ext_attr7,
                                           p_c_ext_attr8,
                                           p_c_ext_attr9,
                                           p_c_ext_attr10,
                                           p_c_ext_attr11,
                                           p_c_ext_attr12,
                                           p_c_ext_attr13,
                                           p_c_ext_attr14,
                                           p_c_ext_attr15,
                                           p_c_ext_attr16,
                                           p_c_ext_attr17,
                                           p_c_ext_attr18,
                                           p_c_ext_attr19,
                                           p_c_ext_attr20,
                                           p_n_ext_attr1,
                                           p_n_ext_attr2,
                                           p_n_ext_attr3,
                                           p_n_ext_attr4,
                                           p_n_ext_attr5,
                                           p_n_ext_attr6,
                                           p_n_ext_attr7,
                                           p_n_ext_attr8,
                                           p_n_ext_attr9,
                                           p_n_ext_attr10,
                                           p_n_ext_attr11,
                                           p_n_ext_attr12,
                                           p_n_ext_attr13,
                                           p_n_ext_attr14,
                                           p_n_ext_attr15,
                                           p_n_ext_attr16,
                                           p_n_ext_attr17,
                                           p_n_ext_attr18,
                                           p_n_ext_attr19,
                                           p_n_ext_attr20,
                                           TRUNC (p_d_ext_attr1),
                                           TRUNC (p_d_ext_attr2),
                                           p_d_ext_attr3,
                                           p_d_ext_attr4,
                                           p_d_ext_attr5,
                                           p_d_ext_attr6,
                                           p_d_ext_attr7,
                                           p_d_ext_attr8,
                                           TRUNC (p_d_ext_attr9),
                                           TRUNC (p_d_ext_attr10),
                                           p_tl_ext_attr1,
                                           p_tl_ext_attr2,
                                           p_tl_ext_attr3,
                                           p_tl_ext_attr4,
                                           p_tl_ext_attr5,
                                           p_tl_ext_attr6,
                                           p_tl_ext_attr7,
                                           p_tl_ext_attr8,
                                           p_tl_ext_attr9,
                                           p_tl_ext_attr10,
                                           p_tl_ext_attr11,
                                           p_tl_ext_attr12,
                                           p_tl_ext_attr13,
                                           p_tl_ext_attr14,
                                           p_tl_ext_attr15,
                                           p_tl_ext_attr16,
                                           p_tl_ext_attr17,
                                           p_tl_ext_attr18,
                                           p_tl_ext_attr19,
                                           p_tl_ext_attr20,
                                           p_creation_date,
                                           p_created_by,
                                           p_last_update_date,
                                           p_last_updated_by,
                                           p_last_update_login,
										   p_bc_pod_flag  --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
										   ,p_fee_option
                                           );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END insert_row;

-- +==============================================================================+
-- | Name             : LOCK_ROW                                                  |
-- | Description      : This procedure shall lock rows into XX_CDH_CUST_ACCT_EXT_B    |
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                           |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE lock_row (
      p_extension_id      IN   NUMBER,
      p_cust_account_id   IN   NUMBER,
      p_attr_group_id     IN   NUMBER,
      p_c_ext_attr1       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr2       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr3       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr4       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr5       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr6       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr7       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr8       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr9       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr10      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr11      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr12      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr13      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr14      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr15      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr16      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr17      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr18      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr19      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr20      IN   VARCHAR2 DEFAULT NULL,
      p_n_ext_attr1       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr2       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr3       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr4       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr5       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr6       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr7       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr8       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr9       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr10      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr11      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr12      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr13      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr14      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr15      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr16      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr17      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr18      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr19      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr20      IN   NUMBER DEFAULT NULL,
      p_d_ext_attr1       IN   DATE DEFAULT NULL,
      p_d_ext_attr2       IN   DATE DEFAULT NULL,
      p_d_ext_attr3       IN   DATE DEFAULT NULL,
      p_d_ext_attr4       IN   DATE DEFAULT NULL,
      p_d_ext_attr5       IN   DATE DEFAULT NULL,
      p_d_ext_attr6       IN   DATE DEFAULT NULL,
      p_d_ext_attr7       IN   DATE DEFAULT NULL,
      p_d_ext_attr8       IN   DATE DEFAULT NULL,
      p_d_ext_attr9       IN   DATE DEFAULT NULL,
      p_d_ext_attr10      IN   DATE DEFAULT NULL,
      p_tl_ext_attr1      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr2      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr3      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr4      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr5      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr6      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr7      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr8      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr9      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr10     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr11     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr12     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr13     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr14     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr15     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr16     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr17     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr18     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr19     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr20     IN   VARCHAR2 DEFAULT NULL,
	  p_bc_pod_flag       IN   VARCHAR2 DEFAULT NULL --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
	  ,p_fee_option          IN              VARCHAR2 DEFAULT NULL --code added for 1.2
      )
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.lock_row (p_extension_id,
                                         p_cust_account_id,
                                         p_attr_group_id,
                                         p_c_ext_attr1,
                                         p_c_ext_attr2,
                                         p_c_ext_attr3,
                                         p_c_ext_attr4,
                                         p_c_ext_attr5,
                                         p_c_ext_attr6,
                                         p_c_ext_attr7,
                                         p_c_ext_attr8,
                                         p_c_ext_attr9,
                                         p_c_ext_attr10,
                                         p_c_ext_attr11,
                                         p_c_ext_attr12,
                                         p_c_ext_attr13,
                                         p_c_ext_attr14,
                                         p_c_ext_attr15,
                                         p_c_ext_attr16,
                                         p_c_ext_attr17,
                                         p_c_ext_attr18,
                                         p_c_ext_attr19,
                                         p_c_ext_attr20,
                                         p_n_ext_attr1,
                                         p_n_ext_attr2,
                                         p_n_ext_attr3,
                                         p_n_ext_attr4,
                                         p_n_ext_attr5,
                                         p_n_ext_attr6,
                                         p_n_ext_attr7,
                                         p_n_ext_attr8,
                                         p_n_ext_attr9,
                                         p_n_ext_attr10,
                                         p_n_ext_attr11,
                                         p_n_ext_attr12,
                                         p_n_ext_attr13,
                                         p_n_ext_attr14,
                                         p_n_ext_attr15,
                                         p_n_ext_attr16,
                                         p_n_ext_attr17,
                                         p_n_ext_attr18,
                                         p_n_ext_attr19,
                                         p_n_ext_attr20,
                                         p_d_ext_attr1,
                                         p_d_ext_attr2,
                                         p_d_ext_attr3,
                                         p_d_ext_attr4,
                                         p_d_ext_attr5,
                                         p_d_ext_attr6,
                                         p_d_ext_attr7,
                                         p_d_ext_attr8,
                                         p_d_ext_attr9,
                                         p_d_ext_attr10,
                                         p_tl_ext_attr1,
                                         p_tl_ext_attr2,
                                         p_tl_ext_attr3,
                                         p_tl_ext_attr4,
                                         p_tl_ext_attr5,
                                         p_tl_ext_attr6,
                                         p_tl_ext_attr7,
                                         p_tl_ext_attr8,
                                         p_tl_ext_attr9,
                                         p_tl_ext_attr10,
                                         p_tl_ext_attr11,
                                         p_tl_ext_attr12,
                                         p_tl_ext_attr13,
                                         p_tl_ext_attr14,
                                         p_tl_ext_attr15,
                                         p_tl_ext_attr16,
                                         p_tl_ext_attr17,
                                         p_tl_ext_attr18,
                                         p_tl_ext_attr19,
                                         p_tl_ext_attr20,
										 p_bc_pod_flag, --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
										 p_fee_option --code added for 1.2
                                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END lock_row;

-- +==============================================================================+
-- | Name             : UPDATE_ROW                                                |
-- | Description      : This procedure shall update data into XX_CDH_CUST_ACCT_EXT_B  |
-- |                    and XX_CDH_CUST_ACCT_EXT_TL tables.                           |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE update_row (
      p_extension_id        IN   NUMBER,
      p_cust_account_id     IN   NUMBER,
      p_attr_group_id       IN   NUMBER,
      p_c_ext_attr1         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr2         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr3         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr4         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr5         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr6         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr7         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr8         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr9         IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr10        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr11        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr12        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr13        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr14        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr15        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr16        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr17        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr18        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr19        IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr20        IN   VARCHAR2 DEFAULT NULL,
      p_n_ext_attr1         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr2         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr3         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr4         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr5         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr6         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr7         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr8         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr9         IN   NUMBER DEFAULT NULL,
      p_n_ext_attr10        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr11        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr12        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr13        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr14        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr15        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr16        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr17        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr18        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr19        IN   NUMBER DEFAULT NULL,
      p_n_ext_attr20        IN   NUMBER DEFAULT NULL,
      p_d_ext_attr1         IN   DATE DEFAULT NULL,
      p_d_ext_attr2         IN   DATE DEFAULT NULL,
      p_d_ext_attr3         IN   DATE DEFAULT NULL,
      p_d_ext_attr4         IN   DATE DEFAULT NULL,
      p_d_ext_attr5         IN   DATE DEFAULT NULL,
      p_d_ext_attr6         IN   DATE DEFAULT NULL,
      p_d_ext_attr7         IN   DATE DEFAULT NULL,
      p_d_ext_attr8         IN   DATE DEFAULT NULL,
      p_d_ext_attr9         IN   DATE DEFAULT NULL,
      p_d_ext_attr10        IN   DATE DEFAULT NULL,
      p_tl_ext_attr1        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr2        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr3        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr4        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr5        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr6        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr7        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr8        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr9        IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr10       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr11       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr12       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr13       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr14       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr15       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr16       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr17       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr18       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr19       IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr20       IN   VARCHAR2 DEFAULT NULL,
      p_last_update_date    IN   DATE DEFAULT SYSDATE,
      p_last_updated_by     IN   NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login   IN   NUMBER DEFAULT fnd_global.user_id,
	  p_bc_pod_flag         IN   VARCHAR2 DEFAULT NULL --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
	  ,p_fee_option          IN              VARCHAR2 DEFAULT NULL --code added for 1.2
      )
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.update_row (p_extension_id,
                                           p_cust_account_id,
                                           p_attr_group_id,
                                           p_c_ext_attr1,
                                           p_c_ext_attr2,
                                           p_c_ext_attr3,
                                           p_c_ext_attr4,
                                           p_c_ext_attr5,
                                           p_c_ext_attr6,
                                           p_c_ext_attr7,
                                           p_c_ext_attr8,
                                           p_c_ext_attr9,
                                           p_c_ext_attr10,
                                           p_c_ext_attr11,
                                           p_c_ext_attr12,
                                           p_c_ext_attr13,
                                           p_c_ext_attr14,
                                           p_c_ext_attr15,
                                           p_c_ext_attr16,
                                           p_c_ext_attr17,
                                           p_c_ext_attr18,
                                           p_c_ext_attr19,
                                           p_c_ext_attr20,
                                           p_n_ext_attr1,
                                           p_n_ext_attr2,
                                           p_n_ext_attr3,
                                           p_n_ext_attr4,
                                           p_n_ext_attr5,
                                           p_n_ext_attr6,
                                           p_n_ext_attr7,
                                           p_n_ext_attr8,
                                           p_n_ext_attr9,
                                           p_n_ext_attr10,
                                           p_n_ext_attr11,
                                           p_n_ext_attr12,
                                           p_n_ext_attr13,
                                           p_n_ext_attr14,
                                           p_n_ext_attr15,
                                           p_n_ext_attr16,
                                           p_n_ext_attr17,
                                           p_n_ext_attr18,
                                           p_n_ext_attr19,
                                           p_n_ext_attr20,
                                           TRUNC (p_d_ext_attr1),
                                           TRUNC (p_d_ext_attr2),
                                           p_d_ext_attr3,
                                           p_d_ext_attr4,
                                           p_d_ext_attr5,
                                           p_d_ext_attr6,
                                           p_d_ext_attr7,
                                           p_d_ext_attr8,
                                           TRUNC (p_d_ext_attr9),
                                           TRUNC (p_d_ext_attr10),
                                           p_tl_ext_attr1,
                                           p_tl_ext_attr2,
                                           p_tl_ext_attr3,
                                           p_tl_ext_attr4,
                                           p_tl_ext_attr5,
                                           p_tl_ext_attr6,
                                           p_tl_ext_attr7,
                                           p_tl_ext_attr8,
                                           p_tl_ext_attr9,
                                           p_tl_ext_attr10,
                                           p_tl_ext_attr11,
                                           p_tl_ext_attr12,
                                           p_tl_ext_attr13,
                                           p_tl_ext_attr14,
                                           p_tl_ext_attr15,
                                           p_tl_ext_attr16,
                                           p_tl_ext_attr17,
                                           p_tl_ext_attr18,
                                           p_tl_ext_attr19,
                                           p_tl_ext_attr20,
                                           p_last_update_date,
                                           p_last_updated_by,
                                           p_last_update_login,
										   p_bc_pod_flag --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
										   ,p_fee_option       --code added for 1.2
                                          );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END update_row;

-- +==============================================================================+
-- | Name             : DELETE_ROW                                                |
-- | Description      : This procedure shall delete data  in XX_CDH_CUST_ACCT_EXT_B   |
-- |                    XX_CDH_CUST_ACCT_EXT_TL table for the given extension id.     |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE delete_row (p_extension_id IN NUMBER)
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.delete_row (p_extension_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END delete_row;

-- +==============================================================================+
-- | Name             : ADD_LANGUAGE                                              |
-- | Description      : This procedure shall insert and update data  in           |
-- |                    XX_CDH_CUST_ACCT_EXT_TL table.                                |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE add_language
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.add_language ();
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END add_language;

-- +==============================================================================+
-- | Name             : LOAD_ROW                                                  |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE load_row (
      p_extension_id      IN   NUMBER,
      p_cust_account_id   IN   NUMBER,
      p_attr_group_id     IN   NUMBER,
      p_c_ext_attr1       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr2       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr3       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr4       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr5       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr6       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr7       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr8       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr9       IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr10      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr11      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr12      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr13      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr14      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr15      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr16      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr17      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr18      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr19      IN   VARCHAR2 DEFAULT NULL,
      p_c_ext_attr20      IN   VARCHAR2 DEFAULT NULL,
      p_n_ext_attr1       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr2       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr3       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr4       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr5       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr6       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr7       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr8       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr9       IN   NUMBER DEFAULT NULL,
      p_n_ext_attr10      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr11      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr12      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr13      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr14      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr15      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr16      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr17      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr18      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr19      IN   NUMBER DEFAULT NULL,
      p_n_ext_attr20      IN   NUMBER DEFAULT NULL,
      p_d_ext_attr1       IN   DATE DEFAULT NULL,
      p_d_ext_attr2       IN   DATE DEFAULT NULL,
      p_d_ext_attr3       IN   DATE DEFAULT NULL,
      p_d_ext_attr4       IN   DATE DEFAULT NULL,
      p_d_ext_attr5       IN   DATE DEFAULT NULL,
      p_d_ext_attr6       IN   DATE DEFAULT NULL,
      p_d_ext_attr7       IN   DATE DEFAULT NULL,
      p_d_ext_attr8       IN   DATE DEFAULT NULL,
      p_d_ext_attr9       IN   DATE DEFAULT NULL,
      p_d_ext_attr10      IN   DATE DEFAULT NULL,
      p_tl_ext_attr1      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr2      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr3      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr4      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr5      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr6      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr7      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr8      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr9      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr10     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr11     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr12     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr13     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr14     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr15     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr16     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr17     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr18     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr19     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr20     IN   VARCHAR2 DEFAULT NULL,
      p_owner             IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.load_row (p_extension_id,
                                         p_cust_account_id,
                                         p_attr_group_id,
                                         p_c_ext_attr1,
                                         p_c_ext_attr2,
                                         p_c_ext_attr3,
                                         p_c_ext_attr4,
                                         p_c_ext_attr5,
                                         p_c_ext_attr6,
                                         p_c_ext_attr7,
                                         p_c_ext_attr8,
                                         p_c_ext_attr9,
                                         p_c_ext_attr10,
                                         p_c_ext_attr11,
                                         p_c_ext_attr12,
                                         p_c_ext_attr13,
                                         p_c_ext_attr14,
                                         p_c_ext_attr15,
                                         p_c_ext_attr16,
                                         p_c_ext_attr17,
                                         p_c_ext_attr18,
                                         p_c_ext_attr19,
                                         p_c_ext_attr20,
                                         p_n_ext_attr1,
                                         p_n_ext_attr2,
                                         p_n_ext_attr3,
                                         p_n_ext_attr4,
                                         p_n_ext_attr5,
                                         p_n_ext_attr6,
                                         p_n_ext_attr7,
                                         p_n_ext_attr8,
                                         p_n_ext_attr9,
                                         p_n_ext_attr10,
                                         p_n_ext_attr11,
                                         p_n_ext_attr12,
                                         p_n_ext_attr13,
                                         p_n_ext_attr14,
                                         p_n_ext_attr15,
                                         p_n_ext_attr16,
                                         p_n_ext_attr17,
                                         p_n_ext_attr18,
                                         p_n_ext_attr19,
                                         p_n_ext_attr20,
                                         p_d_ext_attr1,
                                         p_d_ext_attr2,
                                         p_d_ext_attr3,
                                         p_d_ext_attr4,
                                         p_d_ext_attr5,
                                         p_d_ext_attr6,
                                         p_d_ext_attr7,
                                         p_d_ext_attr8,
                                         p_d_ext_attr9,
                                         p_d_ext_attr10,
                                         p_tl_ext_attr1,
                                         p_tl_ext_attr2,
                                         p_tl_ext_attr3,
                                         p_tl_ext_attr4,
                                         p_tl_ext_attr5,
                                         p_tl_ext_attr6,
                                         p_tl_ext_attr7,
                                         p_tl_ext_attr8,
                                         p_tl_ext_attr9,
                                         p_tl_ext_attr10,
                                         p_tl_ext_attr11,
                                         p_tl_ext_attr12,
                                         p_tl_ext_attr13,
                                         p_tl_ext_attr14,
                                         p_tl_ext_attr15,
                                         p_tl_ext_attr16,
                                         p_tl_ext_attr17,
                                         p_tl_ext_attr18,
                                         p_tl_ext_attr19,
                                         p_tl_ext_attr20,
                                         p_owner
                                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END load_row;

-- +==============================================================================+
-- | Name             : TRANSLATE_ROW                                             |
-- | Description      : This procedure is not being implemented.                  |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE translate_row (
      p_extension_id      IN   NUMBER,
      p_cust_account_id   IN   NUMBER,
      p_attr_group_id     IN   NUMBER,
      p_tl_ext_attr1      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr2      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr3      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr4      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr5      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr6      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr7      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr8      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr9      IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr10     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr11     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr12     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr13     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr14     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr15     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr16     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr17     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr18     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr19     IN   VARCHAR2 DEFAULT NULL,
      p_tl_ext_attr20     IN   VARCHAR2 DEFAULT NULL,
      p_owner             IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      xx_cdh_cust_acct_ext_pkg.translate_row (p_extension_id,
                                              p_cust_account_id,
                                              p_attr_group_id,
                                              p_tl_ext_attr1,
                                              p_tl_ext_attr2,
                                              p_tl_ext_attr3,
                                              p_tl_ext_attr4,
                                              p_tl_ext_attr5,
                                              p_tl_ext_attr6,
                                              p_tl_ext_attr7,
                                              p_tl_ext_attr8,
                                              p_tl_ext_attr9,
                                              p_tl_ext_attr10,
                                              p_tl_ext_attr11,
                                              p_tl_ext_attr12,
                                              p_tl_ext_attr13,
                                              p_tl_ext_attr14,
                                              p_tl_ext_attr15,
                                              p_tl_ext_attr16,
                                              p_tl_ext_attr17,
                                              p_tl_ext_attr18,
                                              p_tl_ext_attr19,
                                              p_tl_ext_attr20,
                                              p_owner
                                             );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END translate_row;

-- +==============================================================================+
-- | Name             : COMPLETE_CUST_DOC                                         |
-- | Description      : This procedure is to validate if new Pay Doc Exceptions   |
-- |                    are included to the Cust Doc Id . If so the older Pay Doc |
-- |                    will be end dated                     .                   |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE complete_cust_doc (
      p_doc_id         IN       NUMBER,
      p_cust_acct_id   IN       NUMBER,
      p_payment_term   IN OUT   VARCHAR2,
      p_doc_type       IN       VARCHAR2,
      p_direct_flag    IN       VARCHAR2,
      p_req_st_date    IN       DATE,
      p_combo_type     IN       VARCHAR2,
      p_update_flag    IN       VARCHAR2,
      x_process_flag   OUT      NUMBER,
      x_cust_doc_id    OUT      NUMBER,
      x_cust_doc_id1   OUT      NUMBER
   )
   IS
      ln_cur_paydoc    NUMBER;
      ln_cur_paydoc1   NUMBER;
      lc_pay_term      VARCHAR2 (100);
      lc_doc_type      VARCHAR2 (100);
      lc_dir_flag      VARCHAR2 (1);
      ln_exten_id      NUMBER;
      ld_eff_st_dt     DATE;
      ln_attr_grp      NUMBER;
      ld_req_date      DATE;
      lc_err_line      VARCHAR2 (100);
      lc_combo         VARCHAR2 (10);

      CURSOR lcu_get_old_payterm (p_cust_id NUMBER, p_grp_id NUMBER)
      IS
         SELECT MAX (c_ext_attr14)
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_id
            AND attr_group_id = p_grp_id                          --attr group
            AND c_ext_attr2 = 'Y'                                  --Pay Doc Y
            AND d_ext_attr2 IS NOT NULL                       -- End Date Null
            AND c_ext_attr16 = 'COMPLETE'
            AND d_ext_attr2 =
                   (SELECT MAX (d_ext_attr2)
                      FROM xx_cdh_cust_acct_ext_b
                     WHERE cust_account_id = p_cust_id
                       AND attr_group_id = p_grp_id               --attr group
                       AND c_ext_attr2 = 'Y'                       --Pay Doc Y
                       AND d_ext_attr2 IS NOT NULL                 -- End Date
                       AND c_ext_attr16 = 'COMPLETE');

      ln_cnt           NUMBER;
   BEGIN
      x_cust_doc_id := 0;
      x_cust_doc_id1 := 0;
      x_process_flag := 0;
      xx_cdh_ebl_util_pkg.log_error ('Begin COMPLETE_CUST_DOC');
      --Getting Attribute Group Id for Cust Documents.
      lc_err_line := 'Getting Attribute Group Id for Cust Documents.';

      SELECT attr_group_id
        INTO ln_attr_grp
        FROM ego_attr_groups_v
       WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
         AND attr_group_name = 'BILLDOCS';

      xx_cdh_ebl_util_pkg.log_error (   'COMPLETE_CUST_DOC: attr grp id '
                                     || ln_attr_grp
                                    );
      --Check If Same Combo(in case of combo)/Non Combo document exist
      lc_err_line :=
              'Check If Same Combo(in case of combo)/Non Combo document exist';

      SELECT COUNT (1)
        INTO ln_cnt
        FROM xx_cdh_cust_acct_ext_b
       WHERE cust_account_id = p_cust_acct_id
         AND attr_group_id = ln_attr_grp                          --attr group
         AND c_ext_attr2 = 'Y'                                     --Pay Doc Y
         AND d_ext_attr2 IS NULL                              -- End Date Null
         AND c_ext_attr16 = 'COMPLETE'                      -- Status Complete
         AND NVL (c_ext_attr13, 'NULL') = NVL (p_combo_type, 'NULL');

      -- Same Combo

      --There exist One pay doc, which can be end-dated
      --This is Regular Scnerio and we will end date this pay doc* /* Condition Apply :) */
      IF ln_cnt = 1
      THEN
         lc_err_line :=
            'Get Record Details to End date old pay doc(Correspondig Combo or Non Combo)';

         SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                extension_id, c_ext_attr13
           INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                ln_exten_id, lc_combo
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acct_id
            AND attr_group_id = ln_attr_grp                       --attr group
            AND c_ext_attr2 = 'Y'                                  --Pay Doc Y
            AND d_ext_attr2 IS NULL                           -- End Date Null
            AND c_ext_attr16 = 'COMPLETE'                   -- Status Complete
            AND NVL (c_ext_attr13, 'NULL') = NVL (p_combo_type, 'NULL');

         -- Same Combo
         IF    lc_pay_term != p_payment_term
            OR lc_doc_type != p_doc_type
            OR lc_dir_flag != p_direct_flag
         THEN
            x_process_flag := 1;
         END IF;

--lc_pay_term != p_payment_term OR lc_doc_type != p_doc_type OR lc_dir_flag != p_direct_flag THEN
         IF lc_combo IS NOT NULL AND x_process_flag = 1
         THEN
            lc_err_line := 'Get count of corresponding combo';

            SELECT COUNT (1)
              INTO ln_cnt
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND attr_group_id = ln_attr_grp                    --attr group
               AND c_ext_attr2 = 'Y'                               --Pay Doc Y
               AND d_ext_attr2 IS NULL                        -- End Date Null
               AND c_ext_attr16 = 'COMPLETE'                -- Status Complete
               AND c_ext_attr13 =
                      DECODE (p_combo_type,
                              'CR', 'DB',
                              'DB', 'CR',
                              p_combo_type
                             );                                  -- Same Combo

            --Corresponding combo type to be endated
            IF ln_cnt = 1
            THEN
               lc_err_line := 'Getting Details of Corresponding Combo record';

               SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                      extension_id, c_ext_attr13
                 INTO x_cust_doc_id1, lc_pay_term, lc_dir_flag, lc_doc_type,
                      ln_exten_id, lc_combo
                 FROM xx_cdh_cust_acct_ext_b
                WHERE cust_account_id = p_cust_acct_id
                  AND attr_group_id = ln_attr_grp                 --attr group
                  AND c_ext_attr2 = 'Y'                            --Pay Doc Y
                  AND d_ext_attr2 IS NULL                     -- End Date Null
                  AND c_ext_attr16 = 'COMPLETE'             -- Status Complete
                  AND c_ext_attr13 =
                         DECODE (p_combo_type,
                                 'CR', 'DB',
                                 'DB', 'CR',
                                 p_combo_type
                                );                               -- Same Combo
            --IF ln_cnt=1 THEN
            ELSIF     ln_cnt = 0
                  AND p_combo_type IS NOT NULL
                  AND p_combo_type != lc_combo
            THEN
               x_cust_doc_id1 := -1;
            END IF;                       --IF ln_cnt=1 THEN(Check ELSIF also)
         END IF;              --lc_combo is NOT NULL AND x_process_flag=1 THEN
      --END IF; --ln_cnt=1 THEN

      --This is exception case. Might be one of following
      --1.) There exist Combo/Non-combo pay doc for Non-Combo/Combo Pay doc
      --2.) First Combo Pay doc created and Non Combo end-dated by Earlier Update.
      --3.) User Enter Invalid combination. We are not Validating this as per assumption
      ELSIF ln_cnt = 0
      THEN
         --Trying to get count of Pay doc with End date Null
         --Result 1 means Non combo Exist
         --Result 2 means Combo Exist
         --Result >2 OR Result=0 means some exception. Not yet handled here
         lc_err_line := 'Get count of Pay doc with End date Null';

         SELECT COUNT (1)
           INTO ln_cnt
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acct_id
            AND attr_group_id = ln_attr_grp                       --attr group
            AND c_ext_attr2 = 'Y'                                  --Pay Doc Y
            AND d_ext_attr2 IS NULL                           -- End Date Null
            AND c_ext_attr16 = 'COMPLETE';                  -- Status Complete

         --Result 1. Non Combo Exist for Combo Type created.
         IF ln_cnt = 1
         THEN
            lc_err_line := 'Get Details of Non Combo Pay doc to compare';

            SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                   extension_id, c_ext_attr13
              INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                   ln_exten_id, lc_combo
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND attr_group_id = ln_attr_grp                    --attr group
               AND c_ext_attr2 = 'Y'                               --Pay Doc Y
               AND d_ext_attr2 IS NULL                        -- End Date Null
               AND c_ext_attr16 = 'COMPLETE';

            IF    lc_pay_term != p_payment_term
               OR lc_doc_type != p_doc_type
               OR lc_dir_flag != p_direct_flag
            THEN
               x_process_flag := 1;
            END IF;

--lc_pay_term != p_payment_term OR lc_doc_type != p_doc_type OR lc_dir_flag != p_direct_flag THEN

            --If process record is COMBO and Found Record is also combo, No Update required
            IF     lc_combo IS NOT NULL
               AND p_combo_type IS NOT NULL
               AND p_combo_type != lc_combo
            THEN
               x_cust_doc_id := 0;

               OPEN lcu_get_old_payterm (p_cust_acct_id, ln_attr_grp);

               FETCH lcu_get_old_payterm
                INTO lc_pay_term;

               CLOSE lcu_get_old_payterm;
            END IF;

            IF     lc_combo IS NOT NULL
               AND p_combo_type IS NOT NULL
               AND x_process_flag = 1
               AND p_combo_type != lc_combo
            THEN
               --Throw Mis-Match Error
               x_cust_doc_id1 := -1;
            END IF;           --lc_combo is NOT NULL AND x_process_flag=1 THEN
         END IF;

         --IF ln_cnt=0 THEN  --Result 1. Non Combo Exist for Combo Type created.

         --Two Combo Records exist for current Non Combo
         IF ln_cnt = 2
         THEN
            lc_err_line := 'Get Details of Pay doc with Combo Type CR';

            SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                   extension_id
              INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                   ln_exten_id
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND attr_group_id = ln_attr_grp                    --attr group
               AND c_ext_attr2 = 'Y'                               --Pay Doc Y
               AND d_ext_attr2 IS NULL                        -- End Date Null
               AND c_ext_attr16 = 'COMPLETE'
               AND c_ext_attr13 = 'CR';

            IF    lc_pay_term != p_payment_term
               OR lc_doc_type != p_doc_type
               OR lc_dir_flag != p_direct_flag
            THEN
               x_process_flag := 1;
            END IF;

--IF lc_pay_term != p_payment_term OR lc_doc_type != p_doc_type OR lc_dir_flag != p_direct_flag THEN
            lc_err_line := 'Get Details of Pay doc with Combo Type DB';

            SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                   extension_id
              INTO x_cust_doc_id1, lc_pay_term, lc_dir_flag, lc_doc_type,
                   ln_exten_id
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND attr_group_id = ln_attr_grp                    --attr group
               AND c_ext_attr2 = 'Y'                               --Pay Doc Y
               AND d_ext_attr2 IS NULL                        -- End Date Null
               AND c_ext_attr16 = 'COMPLETE'                          --Status
               AND c_ext_attr13 = 'DB';                           --Combo Type

            IF    lc_pay_term != p_payment_term
               OR lc_doc_type != p_doc_type
               OR lc_dir_flag != p_direct_flag
            THEN
               x_process_flag := 1;
            END IF;
--IF lc_pay_term != p_payment_term OR lc_doc_type != p_doc_type OR lc_dir_flag != p_direct_flag THEN
         END IF;                                               --ln_cnt=2 THEN
      END IF;                                               --IF ln_cnt=0 THEN

--------------- ADDED FOR DEFECT 39912
      IF lc_pay_term IS NOT NULL
      THEN
         p_payment_term := lc_pay_term;
      END IF;

--------------- ADDED FOR DEFECT
      IF p_req_st_date < TRUNC (SYSDATE)
      THEN
         ld_req_date := SYSDATE;
      ELSE
         ld_req_date := p_req_st_date;
      END IF;

      lc_err_line := 'Calling Compute Effective Date';
      ld_eff_st_dt :=
         xx_ar_inv_freq_pkg.compute_effective_date (p_payment_term,
                                                    ld_req_date
                                                   );

      --Setting up out parameters
      IF p_update_flag = 'Y'
      THEN
         lc_err_line := 'Updating Current cust doc id status and start Date';

         --Update current cust doc to complete
         UPDATE xx_cdh_cust_acct_ext_b
            SET n_ext_attr19 = x_process_flag,
                c_ext_attr16 = 'COMPLETE',
                d_ext_attr1 = TRUNC (ld_eff_st_dt) + 1
          WHERE cust_account_id = p_cust_acct_id AND n_ext_attr2 = p_doc_id;

         --Update previous pay doc end date
         IF NVL (x_cust_doc_id, 1) > 0
         THEN
            UPDATE xx_cdh_cust_acct_ext_b
               SET d_ext_attr2 = TRUNC (ld_eff_st_dt)
             WHERE cust_account_id = p_cust_acct_id
               AND n_ext_attr2 IN (x_cust_doc_id, x_cust_doc_id1);
         END IF;
      END IF;

      xx_cdh_ebl_util_pkg.log_error ('End COMPLETE_CUST_DOC');
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END complete_cust_doc;

   PROCEDURE complete_cust_doc_old (
      p_doc_id         IN       NUMBER,
      p_cust_acct_id   IN       NUMBER,
      p_payment_term   IN OUT   VARCHAR2,
      p_doc_type       IN       VARCHAR2,
      p_direct_flag    IN       VARCHAR2,
      p_req_st_date    IN       DATE,
      p_combo_type     IN       VARCHAR2,
      p_update_flag    IN       VARCHAR2,
      x_process_flag   OUT      NUMBER,
      x_cust_doc_id    OUT      NUMBER,
      x_cust_doc_id1   OUT      NUMBER
   )
   IS
      ln_cur_paydoc    NUMBER;
      ln_cur_paydoc1   NUMBER;
      lc_pay_term      VARCHAR2 (100);
      lc_doc_type      VARCHAR2 (100);
      lc_dir_flag      VARCHAR2 (1);
      ln_exten_id      NUMBER;
      ld_eff_st_dt     DATE;
      ln_attr_grp      NUMBER;
      ld_req_date      DATE;
      ln_cnt           NUMBER;
   BEGIN
      x_cust_doc_id := NULL;
      x_cust_doc_id1 := NULL;
      xx_cdh_ebl_util_pkg.log_error ('Begin COMPLETE_CUST_DOC');

      SELECT attr_group_id
        INTO ln_attr_grp
        FROM ego_attr_groups_v
       WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
         AND attr_group_name = 'BILLDOCS';

      xx_cdh_ebl_util_pkg.log_error (   'COMPLETE_CUST_DOC: attr grp id '
                                     || ln_attr_grp
                                    );

      BEGIN                                         -- For including Exception
         SELECT COUNT (1)
           INTO ln_cnt
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acct_id
            AND attr_group_id = ln_attr_grp
            AND c_ext_attr2 = 'Y'
            AND d_ext_attr2 IS NULL
            AND c_ext_attr16 = 'COMPLETE'
            AND NVL (c_ext_attr13, 'NULL') = NVL (p_combo_type, 'NULL');

         xx_cdh_ebl_util_pkg.log_error
                        (   'COMPLETE_CUST_DOC: First Matching Pay doc count '
                         || ln_cnt
                        );

         IF ln_cnt = 1
         THEN                    --Matching Pay doc exist, Get the cust_doc_id
            --Selecting existing valid pay doc.
            SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                   extension_id
              INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                   ln_exten_id
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND c_ext_attr2 = 'Y'
               AND d_ext_attr2 IS NULL
               AND c_ext_attr16 = 'COMPLETE'
               AND NVL (c_ext_attr13, 'NULL') = NVL (p_combo_type, 'NULL')
               AND attr_group_id = ln_attr_grp;
         ELSIF ln_cnt = 0
         THEN
            --Matching pay doc not found, Check for combo/non combo pay doc(s)
            SELECT COUNT (1)
              INTO ln_cnt
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_acct_id
               AND attr_group_id = ln_attr_grp
               AND c_ext_attr2 = 'Y'
               AND d_ext_attr2 IS NULL
               AND c_ext_attr16 = 'COMPLETE';

            IF ln_cnt = 0
            THEN      --Might be first time AB Customer/eBill doc type, Ignore
               x_cust_doc_id1 := NULL;
               x_cust_doc_id := NULL;
               x_process_flag := 1;
            ELSIF ln_cnt = 1
            THEN                  --Matching Non Combo pay doc for Combo found
               SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                      extension_id
                 INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                      ln_exten_id
                 FROM xx_cdh_cust_acct_ext_b
                WHERE cust_account_id = p_cust_acct_id
                  AND attr_group_id = ln_attr_grp
                  AND c_ext_attr2 = 'Y'
                  AND d_ext_attr2 IS NULL
                  AND c_ext_attr16 = 'COMPLETE';
            ELSIF ln_cnt = 2
            THEN                  --Matching Combo Pay doc for Non Combo found
               SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                      extension_id
                 INTO x_cust_doc_id, lc_pay_term, lc_dir_flag, lc_doc_type,
                      ln_exten_id
                 FROM xx_cdh_cust_acct_ext_b
                WHERE cust_account_id = p_cust_acct_id
                  AND c_ext_attr2 = 'Y'
                  AND d_ext_attr2 IS NULL
                  AND c_ext_attr16 = 'COMPLETE'
                  AND c_ext_attr13 = 'CR'
                  AND attr_group_id = ln_attr_grp;

               SELECT n_ext_attr2, c_ext_attr14, c_ext_attr7, c_ext_attr1,
                      extension_id
                 INTO x_cust_doc_id1, lc_pay_term, lc_dir_flag, lc_doc_type,
                      ln_exten_id
                 FROM xx_cdh_cust_acct_ext_b
                WHERE cust_account_id = p_cust_acct_id
                  AND c_ext_attr2 = 'Y'
                  AND d_ext_attr2 IS NULL
                  AND c_ext_attr16 = 'COMPLETE'
                  AND c_ext_attr13 = 'DB'
                  AND attr_group_id = ln_attr_grp;
            END IF;
         END IF;

         --Any change in parameter, set process flag to 1
         IF    lc_pay_term != p_payment_term
            OR lc_doc_type != p_doc_type
            OR lc_dir_flag != p_direct_flag
         THEN
            x_process_flag := 1;
         ELSE
            x_process_flag := 0;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            ln_cur_paydoc := NULL;
            x_cust_doc_id := 0;
            x_cust_doc_id1 := 0;
            lc_pay_term := NULL;
            lc_dir_flag := NULL;
            lc_doc_type := NULL;
            ln_exten_id := NULL;
            x_process_flag := 1;
      END;

      p_payment_term := lc_pay_term;

      IF p_req_st_date < TRUNC (SYSDATE)
      THEN
         ld_req_date := SYSDATE;
      ELSE
         ld_req_date := p_req_st_date;
      END IF;

      ld_eff_st_dt :=
         xx_ar_inv_freq_pkg.compute_effective_date (p_payment_term,
                                                    ld_req_date
                                                   );

      --Setting up out parameters
      IF p_update_flag = 'Y' AND x_cust_doc_id1 >= 0
      THEN
         --Update current cust doc to complete
         UPDATE xx_cdh_cust_acct_ext_b
            SET n_ext_attr19 = x_process_flag,
                c_ext_attr16 = 'COMPLETE',
                d_ext_attr1 = TRUNC (ld_eff_st_dt) + 1
          WHERE cust_account_id = p_cust_acct_id AND n_ext_attr2 = p_doc_id;

         --Update previous pay doc end date
         IF NVL (x_cust_doc_id, 1) > 0
         THEN
            UPDATE xx_cdh_cust_acct_ext_b
               SET d_ext_attr2 = TRUNC (ld_eff_st_dt)
             WHERE cust_account_id = p_cust_acct_id
               AND n_ext_attr2 IN (x_cust_doc_id, x_cust_doc_id1);
         END IF;
      END IF;

      xx_cdh_ebl_util_pkg.log_error ('End COMPLETE_CUST_DOC');
   END complete_cust_doc_old;

-- +==============================================================================+
-- | Name             : VALIDATE_CUST_DOC                                         |
-- | Description      : This procedure is to validate the Pay Doc Exceptions      |
-- |                                                                              |
-- |                                                          .                   |
-- |                                                                              |
-- +==============================================================================+
   PROCEDURE validate_cust_doc (
      p_cust_account_id   IN       NUMBER,
      x_vld_pay_doc_cnt   OUT      NUMBER,
      x_vld_pay_doc_id1   OUT      NUMBER,
      x_vld_pay_doc_id2   OUT      NUMBER,
      x_combo_type        OUT      VARCHAR2,
      x_cons_flag         OUT      VARCHAR2,
      x_error_msg         OUT      VARCHAR2
   )
   IS
      ln_attr_grp     NUMBER;
      lc_error_line   VARCHAR2 (1000);
   BEGIN
      -- Initialize all the values
      x_vld_pay_doc_cnt := 0;
      x_combo_type := NULL;
      x_cons_flag := NULL;

      BEGIN                                                  -- For Exception
         SELECT attr_group_id
           INTO ln_attr_grp
           FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
            AND attr_group_name = 'BILLDOCS';

         lc_error_line := 'XXOD_EBL_FETCH_ATTR_GRP_ID';

         SELECT COUNT (1)
           INTO x_vld_pay_doc_cnt
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_account_id
            AND attr_group_id = ln_attr_grp
            AND c_ext_attr2 = 'Y'
            AND SYSDATE BETWEEN NVL (d_ext_attr1, SYSDATE)
                            AND NVL (d_ext_attr2, SYSDATE + 1)
            AND c_ext_attr16 = 'COMPLETE';

         IF (x_vld_pay_doc_cnt = 0)
         THEN
            lc_error_line := 'XXOD_EBL_NO_PAYDOC';
            x_vld_pay_doc_id1 := NULL;
            x_vld_pay_doc_id2 := NULL;
            x_combo_type := NULL;
         ELSIF (x_vld_pay_doc_cnt = 1)
         THEN
            lc_error_line := 'XXOD_EBL_PAYDOC_NON_COMBO';

            SELECT n_ext_attr2
              INTO x_vld_pay_doc_id1
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_account_id
               AND c_ext_attr2 = 'Y'
               AND c_ext_attr16 = 'COMPLETE'
               AND c_ext_attr13 IS NULL
               AND SYSDATE BETWEEN NVL (d_ext_attr1, SYSDATE)
                               AND NVL (d_ext_attr2, SYSDATE + 1)
               AND attr_group_id = ln_attr_grp;

            x_combo_type := 'N';
         ELSIF (x_vld_pay_doc_cnt = 2)
         THEN
            lc_error_line := 'XXOD_EBL_PAYDOC_COMBO_ERR';

            SELECT n_ext_attr2
              INTO x_vld_pay_doc_id1
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_account_id
               AND c_ext_attr2 = 'Y'
               AND c_ext_attr16 = 'COMPLETE'
               AND SYSDATE BETWEEN NVL (d_ext_attr1, SYSDATE)
                               AND NVL (d_ext_attr2, SYSDATE + 1)
               AND c_ext_attr13 = 'CR'
               AND attr_group_id = ln_attr_grp;

            SELECT n_ext_attr2
              INTO x_vld_pay_doc_id2
              FROM xx_cdh_cust_acct_ext_b
             WHERE cust_account_id = p_cust_account_id
               AND c_ext_attr2 = 'Y'
               AND c_ext_attr16 = 'COMPLETE'
               AND SYSDATE BETWEEN NVL (d_ext_attr1, SYSDATE)
                               AND NVL (d_ext_attr2, SYSDATE + 1)
               AND c_ext_attr13 = 'DB'
               AND attr_group_id = ln_attr_grp;

            x_combo_type := 'Y';
         END IF;

         -- Cons Flag
         SELECT cons_inv_flag
           INTO x_cons_flag
           FROM hz_customer_profiles
          WHERE cust_account_id = p_cust_account_id AND site_use_id IS NULL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_msg := lc_error_line;
      END;
   END validate_cust_doc;

   FUNCTION get_pay_doc_valid_date (
      p_cust_acc_id   NUMBER,
      p_attr_grp_id   NUMBER,
      p_combo_type    VARCHAR2
   )
      RETURN DATE
   IS
      ld_max_dt   DATE;

      CURSOR lcu_get_date (p_combo VARCHAR2)
      IS
         SELECT MAX (d_ext_attr1)
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acc_id
            AND d_ext_attr2 IS NULL
            AND c_ext_attr16 = 'COMPLETE'
            AND c_ext_attr2 = 'Y'
            AND attr_group_id = p_attr_grp_id
            AND NVL (c_ext_attr13, 'NULL') = NVL (p_combo, 'NULL');

      CURSOR lcu_get_nc_date
      IS
         SELECT MAX (d_ext_attr1)
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acc_id
            AND d_ext_attr2 IS NOT NULL
            AND c_ext_attr16 = 'COMPLETE'
            AND c_ext_attr2 = 'Y'
            AND attr_group_id = p_attr_grp_id;
   --AND nvl(c_ext_attr13,'NULL')=nvl(p_combo,'NULL');
   BEGIN
      IF p_combo_type IS NULL
      THEN
         SELECT MAX (d_ext_attr1)
           INTO ld_max_dt
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id = p_cust_acc_id
            AND d_ext_attr2 IS NULL
            AND c_ext_attr16 = 'COMPLETE'
            AND c_ext_attr2 = 'Y'
            AND attr_group_id = p_attr_grp_id;
      END IF;

      IF p_combo_type = 'CR'
      THEN
         OPEN lcu_get_date ('CR');

         FETCH lcu_get_date
          INTO ld_max_dt;

         CLOSE lcu_get_date;

         IF ld_max_dt IS NULL
         THEN
            OPEN lcu_get_date (NULL);

            FETCH lcu_get_date
             INTO ld_max_dt;

            CLOSE lcu_get_date;
         END IF;
      END IF;

      IF p_combo_type = 'DB'
      THEN
         OPEN lcu_get_date ('DB');

         FETCH lcu_get_date
          INTO ld_max_dt;

         CLOSE lcu_get_date;

         IF ld_max_dt IS NULL
         THEN
            OPEN lcu_get_date (NULL);

            FETCH lcu_get_date
             INTO ld_max_dt;

            CLOSE lcu_get_date;
         END IF;
      END IF;

      IF ld_max_dt IS NULL
      THEN
         OPEN lcu_get_nc_date;

         FETCH lcu_get_nc_date
          INTO ld_max_dt;

         CLOSE lcu_get_nc_date;
      END IF;

      IF ld_max_dt IS NULL
      THEN
         ld_max_dt := TRUNC (SYSDATE);
      END IF;

      RETURN ld_max_dt;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN TRUNC (SYSDATE);
   END get_pay_doc_valid_date;
END xx_cdh_cust_acct_ext_w_pkg;