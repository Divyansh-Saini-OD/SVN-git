SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_conv_stat_info_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                         Wipro Technologies                        |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_STAT_INFO_PKG.pkb                      |
-- | Description :  CDH Customer Statistical Information Package Body  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  06-Aug-2007 Shabbar Hasan      Initial draft version     |
-- |2.0       18-NOV-2015  Manikant Kasu     Removed schema alias as   |
-- |                                         part of GSCC R12.2.2      |
-- |                                         Retrofit
-- | 2.1        26-JUN-16  Sridhar pamu      Modified the code to include sys_op_map_nonnull
-- |                                         when comparing column values for DEFECT 37917/
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        :  tca_ent_stat_info                                  |
-- | Description :  This procedure is invoked from OD: CDH TCA Entities|
-- |                Statistical Info Program Concurrent Request.It     |
-- |                extracts those accounts from hz_cust_accounts which|
-- |                have been created / modified on or after a given   |
-- |                date and inserts them into a custom table,         |
-- |                XX_CDH_TCA_ENTITY_STAT_INFO.                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  Last Update Date                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE tca_ent_stat_info (
      x_errbuf             OUT NOCOPY      VARCHAR2,
      x_retcode            OUT NOCOPY      NUMBER,
      p_last_update_date   IN              VARCHAR2
   )
   AS
      CURSOR lcu_cust_account
      IS
         SELECT   fu.user_name user_name,
                  hca.created_by_module created_by_module,
                  hca.last_update_date last_update_date,
                  DECODE (TRUNC (hca.creation_date),
                          TRUNC (hca.last_update_date), 'Creates',
                          DECODE (hca.status, 'A', 'Updates', 'Deletes')
                         ) status,
                  hca.attribute18 od_customer_type, COUNT (1) VALUE
             FROM hz_cust_accounts hca, fnd_user fu
            WHERE fu.user_id = hca.last_updated_by
              AND TRUNC (hca.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  hca.created_by_module,
                  hca.last_update_date,
                  DECODE (TRUNC (hca.creation_date),
                          TRUNC (hca.last_update_date), 'Creates',
                          DECODE (hca.status, 'A', 'Updates', 'Deletes')
                         ),
                  hca.attribute18;

      CURSOR lcu_cust_account_site
      IS
         SELECT   fu.user_name user_name,
                  hcasa.created_by_module created_by_module,
                  hcasa.last_update_date last_update_date,
                  DECODE (TRUNC (hcasa.creation_date),
                          TRUNC (hcasa.last_update_date), 'Creates',
                          DECODE (hcasa.status, 'A', 'Updates', 'Deletes')
                         ) status,
                  COUNT (1) VALUE
             FROM hz_cust_acct_sites_all hcasa, fnd_user fu
            WHERE fu.user_id = hcasa.last_updated_by
              AND TRUNC (hcasa.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  hcasa.created_by_module,
                  hcasa.last_update_date,
                  DECODE (TRUNC (hcasa.creation_date),
                          TRUNC (hcasa.last_update_date), 'Creates',
                          DECODE (hcasa.status, 'A', 'Updates', 'Deletes')
                         );

      CURSOR lcu_contact_point
      IS
         SELECT   fu.user_name user_name,
                  hcp.created_by_module created_by_module,
                  hcp.last_update_date last_update_date,
                  DECODE (TRUNC (hcp.creation_date),
                          TRUNC (hcp.last_update_date), 'Creates',
                          DECODE (hcp.status, 'A', 'Updates', 'Deletes')
                         ) status,
                  hcp.contact_point_type contact_point_type, COUNT (1) VALUE
             FROM hz_contact_points hcp, fnd_user fu
            WHERE fu.user_id = hcp.last_updated_by
              AND TRUNC (hcp.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  hcp.created_by_module,
                  hcp.last_update_date,
                  DECODE (TRUNC (hcp.creation_date),
                          TRUNC (hcp.last_update_date), 'Creates',
                          DECODE (hcp.status, 'A', 'Updates', 'Deletes')
                         ),
                  hcp.contact_point_type;

      CURSOR lcu_contacts
      IS
         SELECT   fu.user_name user_name,
                  hcar.created_by_module created_by_module,
                  hcar.last_update_date last_update_date,
                  DECODE (TRUNC (hcar.creation_date),
                          TRUNC (hcar.last_update_date), 'Creates',
                          DECODE (hcar.status, 'A', 'Updates', 'Deletes')
                         ) status,
                  COUNT (1) VALUE
             FROM hz_cust_account_roles hcar, fnd_user fu
            WHERE fu.user_id = hcar.last_updated_by
              AND TRUNC (hcar.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  hcar.created_by_module,
                  hcar.last_update_date,
                  DECODE (TRUNC (hcar.creation_date),
                          TRUNC (hcar.last_update_date), 'Creates',
                          DECODE (hcar.status, 'A', 'Updates', 'Deletes')
                         );

      CURSOR lcu_contact_roles
      IS
         SELECT   fu.user_name user_name,
                  hrr.created_by_module created_by_module,
                  hrr.last_update_date last_update_date,
                  DECODE (TRUNC (hrr.creation_date),
                          TRUNC (hrr.last_update_date), 'Creates',
                          DECODE (hcar.status, 'A', 'Updates', 'Deletes')
                         ) status,
                  COUNT (1) VALUE
             FROM hz_role_responsibility hrr,
                  hz_cust_account_roles hcar,
                  fnd_user fu
            WHERE fu.user_id = hrr.last_updated_by
              AND hrr.cust_account_role_id = hcar.cust_account_role_id
              AND TRUNC (hrr.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  hrr.created_by_module,
                  hrr.last_update_date,
                  DECODE (TRUNC (hrr.creation_date),
                          TRUNC (hrr.last_update_date), 'Creates',
                          DECODE (hcar.status, 'A', 'Updates', 'Deletes')
                         );

      CURSOR lcu_web_contacts
      IS
         SELECT   fu.user_name user_name,
                  DECODE (fu.user_name,
                          'ODCRMBPEL', 'BO_API',
                          'ODCDH', 'XXCONV',
                          'SVC_ESP_CRM', 'XXCONV',
                          'OTHERS'
                         ) created_by_module,
                  xcasev.last_update_date last_update_date,
                  DECODE (TRUNC (xcasev.creation_date),
                          TRUNC (xcasev.last_update_date), 'Creates',
                          'Updates'
                         ) status,
                  COUNT (1) VALUE
             FROM xx_cdh_as_ext_webcts_v xcaewv,
                  xx_cdh_acct_site_ext_vl xcasev,
                  fnd_user fu
            WHERE fu.user_id = xcasev.last_updated_by
              AND xcasev.extension_id = xcaewv.extension_id
              AND TRUNC (xcasev.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  xcasev.last_update_date,
                  DECODE (TRUNC (xcasev.creation_date),
                          TRUNC (xcasev.last_update_date), 'Creates',
                          'Updates'
                         );

      CURSOR lcu_bill_docs
      IS
         SELECT   fu.user_name user_name,
                  DECODE (fu.user_name,
                          'ODCRMBPEL', 'BO_API',
                          'ODCDH', 'XXCONV',
                          'SVC_ESP_CRM', 'XXCONV',
                          'OTHERS'
                         ) created_by_module,
                  xccaev.last_update_date last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         ) status,
                  COUNT (1) VALUE
             FROM xx_cdh_a_ext_billdocs_v xcaebv,
                  xx_cdh_cust_acct_ext_vl xccaev,
                  fnd_user fu
            WHERE fu.user_id = xccaev.last_updated_by
              AND xccaev.extension_id = xcaebv.extension_id
              AND TRUNC (xccaev.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  xccaev.last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         );

      CURSOR lcu_spc_card
      IS
         SELECT   fu.user_name user_name,
                  DECODE (fu.user_name,
                          'ODCRMBPEL', 'BO_API',
                          'ODCDH', 'XXCONV',
                          'SVC_ESP_CRM', 'XXCONV',
                          'OTHERS'
                         ) created_by_module,
                  xccaev.last_update_date last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         ) status,
                  COUNT (1) VALUE
             FROM xx_cdh_a_ext_spc_info_v xcaesiv,
                  xx_cdh_cust_acct_ext_vl xccaev,
                  fnd_user fu
            WHERE fu.user_id = xccaev.last_updated_by
              AND xccaev.extension_id = xcaesiv.extension_id
              AND TRUNC (xccaev.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  xccaev.last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         );

      CURSOR lcu_soft_header
      IS
         SELECT   fu.user_name user_name,
                  DECODE (fu.user_name,
                          'ODCRMBPEL', 'BO_API',
                          'ODCDH', 'XXCONV',
                          'SVC_ESP_CRM', 'XXCONV',
                          'OTHERS'
                         ) created_by_module,
                  xccaev.last_update_date last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         ) status,
                  COUNT (1) VALUE
             FROM xx_cdh_a_ext_rpt_softh_v xcaersv,
                  xx_cdh_cust_acct_ext_vl xccaev,
                  fnd_user fu
            WHERE fu.user_id = xccaev.last_updated_by
              AND xccaev.extension_id = xcaersv.extension_id
              AND TRUNC (xccaev.last_update_date) >=
                     TRUNC (TO_DATE (p_last_update_date,
                                     'YYYY/MM/DD HH24:MI:SS'
                                    )
                           )
         GROUP BY fu.user_name,
                  xccaev.last_update_date,
                  DECODE (TRUNC (xccaev.creation_date),
                          TRUNC (xccaev.last_update_date), 'Creates',
                          'Updates'
                         );
   BEGIN
      fnd_file.put_line (fnd_file.LOG, 'Date ' || p_last_update_date);

      FOR lr_cur_cust_acct IN lcu_cust_account
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_cust_acct.user_name user_name,
                             lr_cur_cust_acct.created_by_module
                                                           created_by_module,
                             lr_cur_cust_acct.last_update_date
                                                            last_update_date,
                             lr_cur_cust_acct.status status,
                             lr_cur_cust_acct.od_customer_type
                                                            od_customer_type,
                             lr_cur_cust_acct.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'ACCOUNT'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status
               AND sys_op_map_nonnull (xctesi.group_name5) =
                                       sys_op_map_nonnull (d.od_customer_type))
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, group_name5, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('ACCOUNT', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.od_customer_type, d.VALUE, SYSDATE,
                          fnd_global.user_id, SYSDATE, fnd_global.user_id,
                          fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for accounts '
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_cust_acct_site IN lcu_cust_account_site
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_cust_acct_site.user_name user_name,
                             lr_cur_cust_acct_site.created_by_module
                                                           created_by_module,
                             lr_cur_cust_acct_site.last_update_date
                                                            last_update_date,
                             lr_cur_cust_acct_site.status status,
                             lr_cur_cust_acct_site.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'ACCOUNT SITE'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('ACCOUNT SITE', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for account sites'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_contact_pt IN lcu_contact_point
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_contact_pt.user_name user_name,
                             lr_cur_contact_pt.created_by_module
                                                           created_by_module,
                             lr_cur_contact_pt.last_update_date
                                                            last_update_date,
                             lr_cur_contact_pt.status status,
                             lr_cur_contact_pt.contact_point_type
                                                          contact_point_type,
                             lr_cur_contact_pt.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'CONTACT POINTS'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status
               AND sys_op_map_nonnull (xctesi.group_name5) =
                                     sys_op_map_nonnull (d.contact_point_type))
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, group_name5, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('CONTACT POINTS', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.contact_point_type, d.VALUE, SYSDATE,
                          fnd_global.user_id, SYSDATE, fnd_global.user_id,
                          fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for contact points'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_cont IN lcu_contacts
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_cont.user_name user_name,
                             lr_cur_cont.created_by_module created_by_module,
                             lr_cur_cont.last_update_date last_update_date,
                             lr_cur_cont.status status,
                             lr_cur_cont.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'CONTACTS'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('CONTACTS', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for contacts'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_cont_roles IN lcu_contact_roles
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_cont_roles.user_name user_name,
                             lr_cur_cont_roles.created_by_module
                                                           created_by_module,
                             lr_cur_cont_roles.last_update_date
                                                            last_update_date,
                             lr_cur_cont_roles.status status,
                             lr_cur_cont_roles.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'CONTACT ROLES'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('CONTACT ROLES', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for contact roles'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_web_cont IN lcu_web_contacts
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_web_cont.user_name user_name,
                             lr_cur_web_cont.created_by_module
                                                           created_by_module,
                             lr_cur_web_cont.last_update_date
                                                            last_update_date,
                             lr_cur_web_cont.status status,
                             lr_cur_web_cont.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'WEB CONTACTS'
               AND xctesi.group_name1 = d.user_name
               AND sys_op_map_nonnull (xctesi.group_name2) =
                                      sys_op_map_nonnull (d.created_by_module)
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('WEB CONTACTS', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for web contacts'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_bill_doc IN lcu_bill_docs
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_bill_doc.user_name user_name,
                             lr_cur_bill_doc.created_by_module
                                                           created_by_module,
                             lr_cur_bill_doc.last_update_date
                                                            last_update_date,
                             lr_cur_bill_doc.status status,
                             lr_cur_bill_doc.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'BILL DOCS'
               AND xctesi.group_name1 = d.user_name
               AND xctesi.group_name2 = d.created_by_module
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('BILL DOCS', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for bill docs'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_spc_card IN lcu_spc_card
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_spc_card.user_name user_name,
                             lr_cur_spc_card.created_by_module
                                                           created_by_module,
                             lr_cur_spc_card.last_update_date
                                                            last_update_date,
                             lr_cur_spc_card.status status,
                             lr_cur_spc_card.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'SPC CARD'
               AND xctesi.group_name1 = d.user_name
               AND xctesi.group_name2 = d.created_by_module
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('SPC CARD', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for spc card'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      FOR lr_cur_soft_head IN lcu_soft_header
      LOOP
         BEGIN
            MERGE INTO xx_cdh_tca_entity_stat_info xctesi
               USING (SELECT lr_cur_soft_head.user_name user_name,
                             lr_cur_soft_head.created_by_module
                                                           created_by_module,
                             lr_cur_soft_head.last_update_date
                                                            last_update_date,
                             lr_cur_soft_head.status status,
                             lr_cur_soft_head.VALUE VALUE
                        FROM DUAL) d
               ON (xctesi.summary_name = 'SOFT HEADER'
               AND xctesi.group_name1 = d.user_name
               AND xctesi.group_name2 = d.created_by_module
               AND xctesi.group_name3 =
                        TO_CHAR (d.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
               AND xctesi.group_name4 = d.status)
               WHEN MATCHED THEN
                  UPDATE
                     SET VALUE = d.VALUE, last_update_date = SYSDATE,
                         last_updated_by = fnd_global.user_id,
                         last_update_login = fnd_global.login_id
               WHEN NOT MATCHED THEN
                  INSERT (summary_name, group_name1, group_name2, group_name3,
                          group_name4, VALUE, last_update_date,
                          last_updated_by, creation_date, created_by,
                          last_update_login)
                  VALUES ('SOFT HEADER', d.user_name, d.created_by_module,
                          TO_CHAR (d.last_update_date,
                                   'DD-MON-YYYY HH24:MI:SS'
                                  ),
                          d.status, d.VALUE, SYSDATE, fnd_global.user_id,
                          SYSDATE, fnd_global.user_id, fnd_global.login_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while Merging data into xx_cdh_tca_entity_stat_info. for soft header'
                   || SQLERRM
                  );
               x_retcode := 1;
         END;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                      (fnd_file.LOG,
                          'Exception raised in procedure tca_ent_stat_info. '
                       || SQLERRM
                      );
         ROLLBACK;
         x_retcode := 2;
   END tca_ent_stat_info;
END xx_cdh_conv_stat_info_pkg;
/

SHOW errors;