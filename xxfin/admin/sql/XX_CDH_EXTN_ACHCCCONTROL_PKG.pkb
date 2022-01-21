create or replace
PACKAGE BODY xx_cdh_extn_achcccontrol_pkg
AS
-- +=====================================================================+
-- |                  Office Depot                                       |
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
-- |                                              added chk_achcc        |
-- |1.2       14-Apr-2015   Sridevi K            updated for Defect1064  |
-- |                                              added is_fin_child     |
-- |1.3       4-Jun-2015    Sridevi K            Added get_row_count     |
-- |                                             defect#1371             |
-- |1.4       12-Nov-2015   Havish Kasina        Removed the Schema      |
-- |                                             References as per R12.2 |
-- |                                             Retrofit Changes        |
-- +=====================================================================+
   gc_package          VARCHAR2 (100) := 'XX_CDH_EXTN_ACHCCCONTROL_PKG';
   gc_none             VARCHAR2 (100) := 'NONE';
   gc_ach              VARCHAR2 (100) := 'ACH';
   gc_cc               VARCHAR2 (100) := 'CC';
   gc_both             VARCHAR2 (100) := 'BOTH';
   gc_ach_attribname   VARCHAR2 (100) := 'ACH_BANK_CONTROL';
   gc_cc_attribname    VARCHAR2 (100) := 'CREDITCARD_CONTROL';

   FUNCTION is_fin_parent (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2
   IS
      ln_party_id    NUMBER (15);
      lc_exists      VARCHAR2 (1)   := 'N';
      lc_procedure   VARCHAR2 (100) := 'is_fin_parent';
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        =>    'Fecthing party id for cust account id'
                                        || p_cust_account_id
                     );

      SELECT party_id
        INTO ln_party_id
        FROM hz_cust_accounts
       WHERE cust_account_id = p_cust_account_id;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'ln_party_id:' || ln_party_id
                     );

      SELECT 'Y'
        INTO lc_exists
        FROM hz_relationships
       WHERE relationship_type = 'OD_FIN_HIER'
         AND direction_code = 'P'
         AND status = 'A'
         AND directional_flag = 'F'
         AND subject_id = ln_party_id
        AND SYSDATE BETWEEN start_date AND NVL(end_date,SYSDATE+1)
         AND ROWNUM = 1;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'l_exists:' || lc_exists
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      RETURN lc_exists;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'l_exists: N'
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
      WHEN OTHERS
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        =>    'Exception:checking fin hierarchy'
                                           || SQLCODE
                                           || ' '
                                           || SQLERRM
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
   END is_fin_parent;
   
   FUNCTION is_fin_child (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2
   IS
      ln_party_id    NUMBER (15);
      lc_child      VARCHAR2 (1)   := 'N';
      lc_procedure   VARCHAR2 (100) := 'is_fin_child';
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        =>    'Fecthing party id for cust account id'
                                        || p_cust_account_id
                     );

      SELECT party_id
        INTO ln_party_id
        FROM hz_cust_accounts
       WHERE cust_account_id = p_cust_account_id;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'ln_party_id:' || ln_party_id
                     );

      SELECT 'Y'
        INTO lc_child
        FROM hz_relationships
       WHERE relationship_type = 'OD_FIN_HIER'
         AND direction_code = 'C'
         AND status = 'A'
         --AND directional_flag = 'B'
         AND subject_id = ln_party_id
        AND SYSDATE BETWEEN start_date AND NVL(end_date,SYSDATE+1)
         AND ROWNUM = 1;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'l_child:' || lc_child
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      RETURN lc_child;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'l_child: N'
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
      WHEN OTHERS
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        =>    'Exception:checking fin hierarchy'
                                           || SQLCODE
                                           || ' '
                                           || SQLERRM
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
   END is_fin_child;

   FUNCTION chk_creditauth_resp
      RETURN VARCHAR2
   IS
      CURSOR lcu_chk_creditauth
      IS
         SELECT 'Y' AS exist
           FROM fnd_lookup_values_vl flv,
                fnd_responsibility_vl frv
          WHERE flv.lookup_type = 'OD_CREDIT_AUTH_RESP'
            AND flv.lookup_code = frv.responsibility_key
            AND flv.enabled_flag = 'Y'
            AND TRUNC (SYSDATE) BETWEEN TRUNC (flv.start_date_active)
                                    AND TRUNC (NVL (flv.end_date_active,
                                                    SYSDATE + 1
                                                   )
                                              )
            AND frv.responsibility_id = fnd_profile.VALUE ('RESP_ID')
            AND ROWNUM = 1;

      lc_exists      VARCHAR2 (1)   := 'N';
      lc_procedure   VARCHAR2 (100) := 'chk_creditauth_resp';
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );

      OPEN lcu_chk_creditauth;

      FETCH lcu_chk_creditauth
       INTO lc_exists;

      CLOSE lcu_chk_creditauth;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'l_exists:' || lc_exists
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      RETURN lc_exists;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_log.STRING
             (log_level      => fnd_log.level_statement,
              module         => gc_package || '.' || lc_procedure,
              MESSAGE        =>    'Exception:checking credit auth responsibilities'
                                || SQLCODE
                                || ' '
                                || SQLERRM
             );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
   END chk_creditauth_resp;

   FUNCTION chk_creditauth (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2
   IS
      lc_exists       VARCHAR2 (1)   := 'N';
      lc_fin_parent   VARCHAR2 (1)   := 'N';
      lc_fin_child   VARCHAR2 (1)   := 'N';
      lc_chk_resp     VARCHAR2 (1)   := 'N';
      lc_procedure    VARCHAR2 (100) := 'chk_creditauth';
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );
      lc_chk_resp := chk_creditauth_resp;

      IF lc_chk_resp = 'Y'
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'Checking fin hierarchy'
                        );
         lc_fin_parent := is_fin_parent (p_cust_account_id);
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'lc_fin_parent' || lc_fin_parent
                        );

         IF lc_fin_parent = 'Y'
         THEN
            lc_exists := 'Y';
         ELSE
            fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'Checking fin hierarchy child'
                        );
           lc_fin_child := is_fin_child (p_cust_account_id);
           IF lc_fin_child = 'Y'
           THEN
            fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'Fin hierarchy child...credit auth will not be updateable'
                        );
            lc_exists := 'N';
           Else
            fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => '...credit auth will be updateable'
                        );
            lc_exists := 'Y';
           END IF; 
           fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'lc_fin_child' || lc_fin_child
                        );
         END IF;
      ELSE
         lc_exists := 'N';
      END IF;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'lc_exists:' || lc_exists
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      RETURN lc_exists;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        =>    'Exception:checking credit auth '
                                           || SQLCODE
                                           || ' '
                                           || SQLERRM
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
   END chk_creditauth;


 FUNCTION chk_achcc (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE
   )
      RETURN VARCHAR2
   IS
      lc_exists       VARCHAR2 (1)   := 'N';
      lc_fin_parent   VARCHAR2 (1)   := 'N';
      lc_chk_resp     VARCHAR2 (1)   := 'N';
      lc_procedure    VARCHAR2 (100) := 'chk_achcc';
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );
      lc_chk_resp := chk_creditauth_resp;

      IF lc_chk_resp = 'Y'
      THEN
         lc_exists := 'Y';
     ELSE
         lc_exists := 'N';
      END IF;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'lc_exists:' || lc_exists
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      RETURN lc_exists;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        =>    'Exception:checking ach/cc '
                                           || SQLCODE
                                           || ' '
                                           || SQLERRM
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         RETURN 'N';
   END chk_achcc;
   
   PROCEDURE get_irec_achcc_attribs (
      p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE,
      x_ach_flag OUT NOCOPY VARCHAR2 ,
      x_cc_flag  OUT NOCOPY VARCHAR2
   )
   IS
      lc_irec_achcc_chk   VARCHAR2 (50)  := gc_ach;
      lc_procedure        VARCHAR2 (100) := 'chk_irec_achcc_attribs';
      
      
      lc_ach_flag varchar2(1) := 'N';
      lc_cc_flag varchar2(1) := 'N';

      CURSOR lcu_chk_attribvalue (
         p_cust_account_id   IN   hz_cust_accounts.cust_account_id%TYPE,
         p_grp_name          IN   ego_attr_groups_v.attr_group_name%TYPE
      )
      IS
         SELECT xb.c_ext_attr1
           FROM xx_cdh_cust_acct_ext_b xb, ego_attr_groups_v grp
          WHERE grp.application_id = 222
            AND grp.attr_group_name = p_grp_name
            AND grp.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
            AND xb.attr_group_id = grp.attr_group_id
            AND xb.cust_account_id = p_cust_account_id;
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );
     
     x_ach_flag  := 'N';
      x_cc_flag  := 'N';
     
      OPEN lcu_chk_attribvalue(p_cust_account_id,gc_ach_attribname);
       
      FETCH lcu_chk_attribvalue
       INTO lc_ach_flag;

      CLOSE lcu_chk_attribvalue;


     OPEN lcu_chk_attribvalue(p_cust_account_id,gc_cc_attribname);
       
      FETCH lcu_chk_attribvalue
       INTO lc_cc_flag;

      CLOSE lcu_chk_attribvalue;

      x_ach_flag := lc_ach_flag;
      x_cc_flag := lc_cc_flag;
      
      
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Out Parameters'||'x_ach_flag:'||x_ach_flag||' x_cc_flag:'||x_cc_flag
                     );
                     
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
      
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        =>    'Exception:checking ach cc attribs '
                                           || SQLCODE
                                           || ' '
                                           || SQLERRM
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => gc_package || '.' || lc_procedure,
                         MESSAGE        => 'End ' || lc_procedure
                        );
         
   END get_irec_achcc_attribs;

 PROCEDURE get_row_count (
      p_cust_account_id   IN              hz_cust_accounts.cust_account_id%TYPE,
      p_attr_group_id     IN              xx_cdh_cust_acct_ext_b.attr_group_id%TYPE,
      x_count             OUT NOCOPY      NUMBER,
      x_attr_group_name   OUT NOCOPY      VARCHAR
   )
   IS
      lc_procedure   VARCHAR2 (100) := 'get_row_count';
      ln_count       NUMBER         := 0;

      CURSOR lcu_count
      IS
         SELECT COUNT (extension_id)
           FROM xx_cdh_cust_acct_ext_b xb
          WHERE 1 = 1
            AND xb.attr_group_id = p_attr_group_id
            AND xb.cust_account_id = p_cust_account_id;

      CURSOR lcu_grpname
      IS
         SELECT grp.attr_group_name
           FROM ego_attr_groups_v grp
          WHERE grp.application_id = 222
            AND grp.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
            AND grp.attr_group_id = p_attr_group_id;
   BEGIN

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Begin ' || lc_procedure
                     );

     fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Getting row count '
                     );


      OPEN lcu_count;

      FETCH lcu_count
       INTO ln_count;

      CLOSE lcu_count;

      x_count := ln_count;


     fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Getting attribute group name '
                     );

      OPEN lcu_grpname;

      FETCH lcu_grpname
       INTO x_attr_group_name;

      CLOSE lcu_grpname;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'Out Parameters' || 'x_count'
                                        || x_count
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => gc_package || '.' || lc_procedure,
                      MESSAGE        => 'End ' || lc_procedure
                     );
   END get_row_count;
   
END xx_cdh_extn_achcccontrol_pkg;
/

