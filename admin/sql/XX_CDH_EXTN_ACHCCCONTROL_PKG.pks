-- +=====================================================================+
-- |                  Office Depot                                        |
-- +=====================================================================+
-- | Name     :   CDH Additional attributes for ECheck                   |
-- | Rice id  :   E0255                                                  |
-- | Description :                                                       |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       27-Mar-2015   Sridevi K            Initial version         |
-- |1.1       9-Apr-2015    Sridevi K            updated for Defect1064  |
--                                               added chk_achcc         |
-- |1.2       14-Apr-2015   Sridevi K            updated for Defect1064  |
-- |                                              added is_fin_child     |
-- |1.3       4-Jun-2015    Sridevi K            Added get_row_count     |
-- |                                             defect#1371             |
-- |1.4       12-Nov-2015   Havish Kasina        Removed the Schema      |
-- |                                             References as per R12.2 |
-- |                                             Retrofit Changes        |
-- +=====================================================================+

CREATE OR REPLACE PACKAGE xx_cdh_extn_achcccontrol_pkg
AS
   FUNCTION is_fin_parent (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2;

 FUNCTION is_fin_child (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION chk_creditauth_resp
      RETURN VARCHAR2;

   FUNCTION chk_creditauth (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION chk_achcc (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2;

   PROCEDURE get_irec_achcc_attribs (
      p_cust_account_id   IN              hz_cust_accounts.cust_account_id%TYPE,
      x_ach_flag          OUT NOCOPY      VARCHAR2,
      x_cc_flag           OUT NOCOPY      VARCHAR2
   );

   PROCEDURE get_row_count (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE,
      p_ATTR_GROUP_ID   IN   XX_CDH_CUST_ACCT_EXT_B.ATTR_GROUP_ID%TYPE,
      x_count OUT NOCOPY NUMBER,
      x_attr_group_name OUT NOCOPY VARCHAR
   );

END xx_cdh_extn_achcccontrol_pkg;
/

