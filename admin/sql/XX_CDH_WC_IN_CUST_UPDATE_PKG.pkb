CREATE OR REPLACE PACKAGE BODY xx_cdh_wc_in_cust_update_pkg
AS
-- +========================================================================+
-- |                  Office Depot - Webcollect CDH                         |
-- +========================================================================+
-- | Name        : XX_CDH_WC_IN_CUST_UPDATE_PKG.pkb                         |
-- | Description : To update the customer profile and import dunning        |
-- |               contacts and contact pints from webcollect to oracle     |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      22-Mar-2012  Jay Gupta             Initial version             |
-- |2.0      28-Aug-2012  Dheeraj V             QC 19432 fixes              |
-- |2.1      03-Sep-2013  Manasa D              I2188 - Changed for R12     |
-- |                                            Retrofit                    |
-- |3.0      28-Aug-2014  Sridevi K             I2188 - Modified for        |
-- |                                            Defect30204                 |
-- |4.0      22-Oct-2015  Manikant Kasu         removed schema alias as part|
-- |                                            of R12.2.2 retrofit         |
-- +========================================================================+

   -- +========================================================================+
-- | Name        : cust_dunn_contact_update                                 |
-- | Description : To update the collector in customer profile              |
-- +========================================================================+
   gc_debug_flag          CHAR (1);
   gn_site_use_id         NUMBER;
   gn_cust_acct_site_id   NUMBER;
   gn_account_number      NUMBER;
   gn_cust_account_id     NUMBER;
   gn_party_id            NUMBER;
   gn_person_party_id     NUMBER;

-- +========================================================================+
-- | Name        : create_site_profile                                      |
-- | Description : To create the Bill-To site profile if does not exist     |
-- |               with webcollect collector assignment                     |
-- |               Added for v 2.0, QC 19432
-- +========================================================================+
   PROCEDURE log_message (p_message VARCHAR2);

   PROCEDURE create_site_profile (
      ln_site_id        IN       NUMBER,
      ln_collector_id   IN       NUMBER,
      x_ret_msg         OUT      VARCHAR2
   )
   IS
      CURSOR cur_prof_id (site_id IN NUMBER)
      IS
         SELECT prof.cust_account_profile_id
           FROM hz_cust_accounts acc,
                hz_cust_acct_sites_all site,
                hz_cust_site_uses_all uses,
                hz_customer_profiles prof
          WHERE acc.cust_account_id = site.cust_account_id
            AND site.cust_acct_site_id = uses.cust_acct_site_id
            AND acc.cust_account_id = prof.cust_account_id
            AND prof.site_use_id IS NULL
            AND uses.site_use_id = site_id;

      prof_rec                    hz_customer_profile_v2pub.customer_profile_rec_type;
      ln_cust_profile_id          NUMBER;
      l_return_status             VARCHAR2 (5);
      l_msg_count                 NUMBER;
      l_msg_data                  VARCHAR2 (4000);
      x_error_message             VARCHAR2 (4000);
      l_site_account_profile_id   NUMBER;
      le_failed                   EXCEPTION;
   BEGIN
      x_ret_msg := 'E';

      OPEN cur_prof_id (ln_site_id);

      FETCH cur_prof_id
       INTO ln_cust_profile_id;

      hz_customer_profile_v2pub.get_customer_profile_rec
                            (p_init_msg_list                => 'T',
                             p_cust_account_profile_id      => ln_cust_profile_id,
                             x_customer_profile_rec         => prof_rec,
                             x_return_status                => l_return_status,
                             x_msg_count                    => l_msg_count,
                             x_msg_data                     => l_msg_data
                            );

      IF l_return_status <> fnd_api.g_ret_sts_success
      THEN
         x_error_message := NULL;

         IF (l_msg_count > 0)
         THEN
            FOR counter IN 1 .. l_msg_count
            LOOP
               x_error_message :=
                     x_error_message
                  || ' '
                  || fnd_msg_pub.get (counter, fnd_api.g_false);
            END LOOP;
         END IF;

         log_message (   'Error occured while fetching Customer Profile'
                      || x_error_message
                     );
         fnd_msg_pub.delete_msg;
         RAISE le_failed;
      END IF;

      prof_rec.cust_account_profile_id := NULL;
      prof_rec.site_use_id := ln_site_id;
      prof_rec.collector_id := ln_collector_id;
      hz_customer_profile_v2pub.create_customer_profile
                      (p_init_msg_list                => 'T',
                       p_customer_profile_rec         => prof_rec,
                       p_create_profile_amt           => fnd_api.g_false,
                       x_cust_account_profile_id      => l_site_account_profile_id,
                       x_return_status                => l_return_status,
                       x_msg_count                    => l_msg_count,
                       x_msg_data                     => l_msg_data
                      );

      IF l_return_status <> fnd_api.g_ret_sts_success
      THEN
         x_error_message := NULL;

         IF (l_msg_count > 0)
         THEN
            FOR counter IN 1 .. l_msg_count
            LOOP
               x_error_message :=
                     x_error_message
                  || ' '
                  || fnd_msg_pub.get (counter, fnd_api.g_false);
            END LOOP;
         END IF;

         log_message ('Error occured while creating profile'
                      || x_error_message
                     );
         fnd_msg_pub.delete_msg;
         RAISE le_failed;
      END IF;

      x_ret_msg := 'S';
      log_message ('Bill-To profile created sucessfully');
   EXCEPTION
      WHEN le_failed
      THEN
         NULL;
      WHEN OTHERS
      THEN
         log_message (   'Exception occured while creating site profile'
                      || SQLERRM
                     );
   END;

-- +========================================================================+
-- | Name        : log_message                                              |
-- | Description : To write into the log file                               |
-- +========================================================================+
   PROCEDURE log_message (p_message VARCHAR2)
   IS
   BEGIN
      IF gc_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_message);
      END IF;
   END;

-- +========================================================================+
-- | Name        : Create Contact                                           |
-- | Description : To create new contact                                    |
-- +========================================================================+
   PROCEDURE create_contact (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      x_org_contact_id    OUT   NUMBER,
      x_return_status     OUT   VARCHAR2
   )
   IS
      CURSOR coll_rel_cur (
         c_cust_account_id   hz_cust_accounts.cust_account_id%TYPE
      )
      IS
         SELECT hr.relationship_id
           FROM hz_relationships hr, hz_cust_accounts hca
          WHERE hca.party_id = hr.object_id
            AND hr.relationship_code = 'COLLECTIONS_OF'
            AND hr.status = 'A'
            AND hca.cust_account_id = c_cust_account_id;

      CURSOR role_resp_cur (
         c_cust_acct_site_id   hz_cust_account_roles.cust_acct_site_id%TYPE
      )
      IS
         SELECT hrr.responsibility_id
           FROM hz_cust_account_roles hcar, hz_role_responsibility hrr
          WHERE hcar.cust_account_role_id = hrr.cust_account_role_id
            AND hrr.responsibility_type = 'DUN'
            AND hrr.primary_flag = 'Y'
            AND hcar.cust_acct_site_id = c_cust_acct_site_id;

      ln_job_ex                        NUMBER;
      ln_cust_account_id               hz_cust_accounts.cust_account_id%TYPE;
      -- Used for create person API
      lr_person_rec                    hz_party_v2pub.person_rec_type;
      lc_party_number                  hz_parties.party_number%TYPE;
      ln_profile_id                    NUMBER;
      lc_create_person_return_status   VARCHAR2 (2000);
      ln_create_person_msg_count       NUMBER;
      lc_create_person_msg_data        VARCHAR2 (2000);
      -- Used for get_relationship_rec API
      lr_rel_rec                       hz_relationship_v2pub.relationship_rec_type;
      lc_coll_rel_return_status        VARCHAR2 (2000);
      ln_coll_rel_msg_count            NUMBER;
      ln_coll_rel_msg_data             VARCHAR2 (2000);
      lr_rel_rec_in                    hz_relationship_v2pub.relationship_rec_type;
      -- Used for update update_relationship API
      ln_rel_object_version_number     NUMBER;
      ln_party_object_version_number   NUMBER;
      lc_upd_coll_rel_return_status    VARCHAR2 (2000);
      ln_upd_coll_rel_msg_count        NUMBER;
      ln_upd_coll_rel_msg_data         VARCHAR2 (2000);
      -- used for create_org_contact API
      lr_org_contact_rec               hz_party_contact_v2pub.org_contact_rec_type;
      ln_party_id                      hz_parties.party_id%TYPE;
      ln_org_contact_id_apcontact      NUMBER;
      ln_party_rel_id                  NUMBER;
      ln_party_id_create_org_contact   NUMBER;
      lc_party_number_org_contact      VARCHAR2 (2000);
      lc_org_contact_return_status     VARCHAR2 (2000);
      ln_org_contact_msg_count         NUMBER;
      lc_org_contact_msg_data          VARCHAR2 (2000);
      -- Used for create_cust_account_role
      lr_cust_account_role_rec         hz_cust_account_role_v2pub.cust_account_role_rec_type;
      ln_cust_account_role_id          NUMBER;
      lc_cust_acct_role_rtrn_status    VARCHAR2 (1000);
      ln_cust_acct_role_msg_count      NUMBER;
      lc_cust_acct_role_msg_data       VARCHAR2 (1000);
      -- Used for update_role_responsibility  API
      lr_role_responsibility_rec       hz_cust_account_role_v2pub.role_responsibility_rec_type;
      lc_get_role_resp_return_status   VARCHAR2 (2000);
      ln_get_role_resp_msg_count       NUMBER;
      lc_get_role_resp_msg_data        VARCHAR2 (2000);
      -- used for create_role_responsibility API
      lr_role_responsibility_rec_in    hz_cust_account_role_v2pub.role_responsibility_rec_type;
      ln_responsibility_id             NUMBER;
      lc_role_resp_return_status       VARCHAR2 (1000);
      ln_role_resp_msg_count           NUMBER;
      lc_role_resp_msg_data            VARCHAR2 (1000);
      lc_upd_role_resp_return_status   VARCHAR2 (2000);
      ln_upd_role_resp_msg_count       NUMBER;
      lc_upd_role_resp_msg_data        VARCHAR2 (2000);
      ln_resp_object_version_number    hz_role_responsibility.object_version_number%TYPE;
   BEGIN
      log_message ('Procedure - Create Contact');
      SAVEPOINT create_dunning_contact;
      x_return_status := 'S';
      -- Create the person in HZ_PARTIES table
-----------------------------------------------------------------------
      log_message ('Calling API to Create Person');
      lr_person_rec.created_by_module := 'XXCONV';
      lr_person_rec.person_first_name := p_contact_int_rec.contact_first_name;
      lr_person_rec.person_last_name := p_contact_int_rec.contact_last_name;
      hz_party_v2pub.create_person
                          (p_init_msg_list      => 'T',
                           p_person_rec         => lr_person_rec,
                           x_party_id           => gn_person_party_id,
                           x_party_number       => lc_party_number,
                           x_profile_id         => ln_profile_id,
                           x_return_status      => lc_create_person_return_status,
                           x_msg_count          => ln_create_person_msg_count,
                           x_msg_data           => lc_create_person_msg_data
                          );
      log_message (   'lc_create_person_return_status : '
                   || lc_create_person_return_status
                  );

      IF    lc_create_person_return_status = fnd_api.g_ret_sts_error
         OR lc_create_person_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_dunning_contact;
         log_message (   'FALSE_'
                      || gn_account_number
                      || '"'
                      || ','
                      || '"Error'
                      || '"'
                      || ','
                      || '"Create Person API failed, API error message:  '
                      || lc_create_person_msg_data
                     );
         x_return_status := 'E';
         GOTO last_statement;
      END IF;

--------------------------------------------------------------
-- Set the relationship status of existing COLLECTIONS OF as inactive
      log_message ('Calling API to get the relationship details');

      FOR coll_rel_rec IN coll_rel_cur (gn_cust_account_id)  -- arwalgaurav ag
      LOOP
         log_message ('Relationship id: ' || coll_rel_rec.relationship_id);
         hz_relationship_v2pub.get_relationship_rec
                          (p_init_msg_list        => fnd_api.g_true,
                           p_relationship_id      => coll_rel_rec.relationship_id,
                           x_rel_rec              => lr_rel_rec,
                           x_return_status        => lc_coll_rel_return_status,
                           x_msg_count            => ln_coll_rel_msg_count,
                           x_msg_data             => ln_coll_rel_msg_data
                          );

         IF    lc_coll_rel_return_status = fnd_api.g_ret_sts_error
            OR lc_coll_rel_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            ROLLBACK TO create_dunning_contact;
            log_message
               (   'FALSE_'
                || gn_account_number
                || '"'
                || ','
                || '"Error'
                || '"'
                || ','
                || '"Get Relationship Record API failed for relationship_id: '
                || lr_rel_rec.relationship_id
                || ', API error message:  '
                || ln_coll_rel_msg_data
               );
            x_return_status := 'E';
            GOTO last_statement;
         END IF;

         log_message (   '**********Updating Relationship id: '
                      || lr_rel_rec.relationship_id
                     );
         lr_rel_rec_in := lr_rel_rec;
         lr_rel_rec_in.status := 'I';

         BEGIN
            SELECT hr.object_version_number
              INTO ln_rel_object_version_number
              FROM hz_relationships hr
             WHERE hr.relationship_id = lr_rel_rec.relationship_id
               AND hr.directional_flag = 'F';

            SELECT hp.object_version_number
              INTO ln_party_object_version_number
              FROM hz_parties hp
             WHERE hp.party_id = lr_rel_rec.party_rec.party_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message
                  ('Error while extracting Relationship and party Object Version Number'
                  );
               x_return_status := 'E';
               GOTO last_statement;
         END;

         hz_relationship_v2pub.update_relationship
             (p_init_msg_list                    => 'T',
              p_relationship_rec                 => lr_rel_rec_in,
              p_object_version_number            => ln_rel_object_version_number,
              p_party_object_version_number      => ln_party_object_version_number,
              x_return_status                    => lc_upd_coll_rel_return_status,
              x_msg_count                        => ln_upd_coll_rel_msg_count,
              x_msg_data                         => ln_upd_coll_rel_msg_data
             );

         IF    lc_upd_coll_rel_return_status = fnd_api.g_ret_sts_error
            OR lc_upd_coll_rel_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            ROLLBACK TO create_dunning_contact;
            log_message
                  (   'FALSE_'
                   || gn_account_number
                   || '"'
                   || ','
                   || '"Error'
                   || '"'
                   || ','
                   || '"Update Relationship API failed for relationship_id: '
                   || lr_rel_rec_in.relationship_id
                   || ', API error message:  '
                   || ln_upd_coll_rel_msg_data
                  );
            x_return_status := 'E';
            GOTO last_statement;
         END IF;
      END LOOP;

------------------------------------------------------------------------
/* Create the person as collections contact in HZ_ORG_CONTACTS AND HZ_RELATIONSHIPS tables */
      lr_org_contact_rec.created_by_module := 'XXCONV';
      lr_org_contact_rec.party_rel_rec.subject_id := gn_person_party_id;
      lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
      lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
      lr_org_contact_rec.party_rel_rec.object_id := gn_party_id;
      lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
      lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
      lr_org_contact_rec.party_rel_rec.relationship_code := 'COLLECTIONS_OF';
      lr_org_contact_rec.party_rel_rec.relationship_type := 'COLLECTIONS';
      lr_org_contact_rec.party_rel_rec.start_date :=
         NVL (TO_DATE (p_contact_int_rec.contact_start_date,
                       'RRRR-MM-DD HH24:MI:SS'
                      ),
              SYSDATE
             );
      lr_org_contact_rec.party_rel_rec.end_date :=
         TO_DATE (p_contact_int_rec.contact_end_date, 'RRRR-MM-DD HH24:MI:SS');
      lr_org_contact_rec.job_title := p_contact_int_rec.job_title;
      log_message ('**********Create Org cotact: Subject id: ' || gn_party_id);
      hz_party_contact_v2pub.create_org_contact
                             (p_init_msg_list        => 'T',
                              p_org_contact_rec      => lr_org_contact_rec,
                              x_org_contact_id       => ln_org_contact_id_apcontact,
                              x_party_rel_id         => ln_party_rel_id,
                              x_party_id             => ln_party_id_create_org_contact,
                              x_party_number         => lc_party_number_org_contact,
                              x_return_status        => lc_org_contact_return_status,
                              x_msg_count            => ln_org_contact_msg_count,
                              x_msg_data             => lc_org_contact_msg_data
                             );
      x_org_contact_id := ln_org_contact_id_apcontact;

      IF    lc_org_contact_return_status = fnd_api.g_ret_sts_error
         OR lc_org_contact_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_dunning_contact;
         log_message
                   (   'FALSE_'
                    || gn_account_number
                    || '"'
                    || ','
                    || '"Error'
                    || '"'
                    || ','
                    || '"Create Org Contact API failed, API error message:  '
                    || lc_org_contact_msg_data
                   );
         x_return_status := 'E';
         GOTO last_statement;
      END IF;

-------------------------------------------------------------------------------------------------------------------

      -- Create the person as CONTACT for the customer site
      lr_cust_account_role_rec.party_id := ln_party_id_create_org_contact;
      lr_cust_account_role_rec.cust_account_id := gn_cust_account_id;
      lr_cust_account_role_rec.cust_acct_site_id := gn_cust_acct_site_id;
      lr_cust_account_role_rec.role_type := 'CONTACT';
      lr_cust_account_role_rec.created_by_module := 'XXCONV';
      --lr_cust_account_role_rec.primary_flag :=
      --                             p_contact_int_rec.contact_role_primary_flag;
      log_message ('Create cust account role:  : ' || gn_cust_account_id);
      log_message (   'Create cust account role: ln_cust_acct_site_id_in: '
                   || gn_cust_acct_site_id
                  );
      log_message
              (   'Create cust account role: ln_party_id_create_org_contact: '
               || ln_party_id_create_org_contact
              );
      hz_cust_account_role_v2pub.create_cust_account_role
                         (p_init_msg_list              => 'T',
                          p_cust_account_role_rec      => lr_cust_account_role_rec,
                          x_cust_account_role_id       => ln_cust_account_role_id,
                          x_return_status              => lc_cust_acct_role_rtrn_status,
                          x_msg_count                  => ln_cust_acct_role_msg_count,
                          x_msg_data                   => lc_cust_acct_role_msg_data
                         );
      log_message
               (   'Create cust account role: lc_cust_acct_role_rtrn_status: '
                || lc_cust_acct_role_rtrn_status
               );

      IF    lc_cust_acct_role_rtrn_status = fnd_api.g_ret_sts_error
         OR lc_cust_acct_role_rtrn_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_dunning_contact;
         log_message
             (   'FALSE_'
              || gn_account_number
              || '"'
              || ','
              || '"Error'
              || '"'
              || ','
              || '"Create Cust Account Role API failed, API error message:  '
              || lc_cust_acct_role_msg_data
             );
         x_return_status := 'E';
         GOTO last_statement;
      END IF;

-------------------------------------------------------------------------------------------------------------------

      -- To reset the primary flat to N for the exisiting contacts
      FOR role_resp_rec IN role_resp_cur (gn_cust_acct_site_id)
      LOOP
         hz_cust_account_role_v2pub.get_role_responsibility_rec
                 (p_init_msg_list                => 'T',
                  p_responsibility_id            => role_resp_rec.responsibility_id,
                  x_role_responsibility_rec      => lr_role_responsibility_rec_in,
                  x_return_status                => lc_get_role_resp_return_status,
                  x_msg_count                    => ln_get_role_resp_msg_count,
                  x_msg_data                     => lc_get_role_resp_msg_data
                 );

         IF    lc_get_role_resp_return_status = fnd_api.g_ret_sts_error
            OR lc_get_role_resp_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            ROLLBACK TO create_dunning_contact;
            log_message
               (   'FALSE_'
                || gn_account_number
                || '"'
                || ','
                || '"Error'
                || '"'
                || ','
                || '"Get Role Responsiblity Rec API failed for responsibility_id: '
                || role_resp_rec.responsibility_id
                || ' , API error message:  '
                || lc_get_role_resp_msg_data
               );
            x_return_status := 'E';
            GOTO last_statement;
         END IF;

         BEGIN
            SELECT hrr.object_version_number
              INTO ln_resp_object_version_number
              FROM hz_role_responsibility hrr
             WHERE hrr.responsibility_id = role_resp_rec.responsibility_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message
                  ('Error while extracting Responsibility Object Version Number'
                  );
               x_return_status := 'E';
               GOTO last_statement;
         END;

         log_message (   'role_resp_rec.responsibility_id: '
                      || role_resp_rec.responsibility_id
                     );
         lr_role_responsibility_rec_in.primary_flag := 'N';
         hz_cust_account_role_v2pub.update_role_responsibility
                  (p_init_msg_list                => 'T',
                   p_role_responsibility_rec      => lr_role_responsibility_rec_in,
                   p_object_version_number        => ln_resp_object_version_number,
                   x_return_status                => lc_upd_role_resp_return_status,
                   x_msg_count                    => ln_upd_role_resp_msg_count,
                   x_msg_data                     => lc_upd_role_resp_msg_data
                  );

         IF    lc_upd_role_resp_return_status = fnd_api.g_ret_sts_error
            OR lc_upd_role_resp_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            ROLLBACK TO create_dunning_contact;
            log_message
               (   'FALSE_'
                || gn_account_number
                || '"'
                || ','
                || '"Error'
                || '"'
                || ','
                || '"Get Role Responsiblity Rec API failed for responsibility_id: '
                || role_resp_rec.responsibility_id
                || ' , API error message:  '
                || lc_upd_role_resp_msg_data
               );
            x_return_status := 'E';
            GOTO last_statement;
         END IF;
      END LOOP;

-------------------------------------------------------------------------------------------------------------------
-- Set the contact role as Dunning
      lr_role_responsibility_rec.cust_account_role_id :=
                                                       ln_cust_account_role_id;
      lr_role_responsibility_rec.responsibility_type := 'DUN';
      lr_role_responsibility_rec.created_by_module := 'XXCONV';
      lr_role_responsibility_rec.primary_flag := 'Y';
      log_message (   'Create responsibiltiy: ln_cust_account_role_id: '
                   || ln_cust_account_role_id
                  );
      hz_cust_account_role_v2pub.create_role_responsibility
                     (p_init_msg_list                => 'T',
                      p_role_responsibility_rec      => lr_role_responsibility_rec,
                      x_responsibility_id            => ln_responsibility_id,
                      x_return_status                => lc_role_resp_return_status,
                      x_msg_count                    => ln_role_resp_msg_count,
                      x_msg_data                     => lc_role_resp_msg_data
                     );

      IF    lc_role_resp_return_status = fnd_api.g_ret_sts_error
         OR lc_role_resp_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_dunning_contact;
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Role Responsibility API failed, API error message: '
             || lc_role_resp_msg_data
            );
         x_return_status := 'E';
      END IF;

      <<last_statement>>
      NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK TO create_dunning_contact;
         log_message (SQLERRM);
         x_return_status := 'E';
   END create_contact;

-- +========================================================================+
-- | Name        : Create_Email                                             |
-- | Description : For creating the new email contact point                 |
-- +========================================================================+
   PROCEDURE create_email (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_owner_table_id          NUMBER,
      x_return_status     OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_email       hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec                     hz_contact_point_v2pub.email_rec_type;
      lr_phone_rec_dummy               hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_contact_point_id              NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Craete Email');
      x_return_status := 'S';
      lr_contact_point_rec_email.contact_point_type := 'EMAIL';
      lr_contact_point_rec_email.owner_table_name := 'HZ_PARTIES';
      lr_contact_point_rec_email.owner_table_id := p_owner_table_id;

      IF (p_contact_int_rec.contact_point_primary_flag = 'E')
      THEN
         lr_contact_point_rec_email.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_email.primary_flag := 'N';
      END IF;

      lr_contact_point_rec_email.contact_point_purpose :=
                                               p_contact_int_rec.email_purpose;
      lr_contact_point_rec_email.created_by_module := 'XXCONV';
      lr_email_rec.email_format := 'MAILHTML';
      lr_email_rec.email_address := p_contact_int_rec.email_address;
      --Added for Defect30204
      lr_contact_point_rec_email.orig_system_reference :=
                                                   p_contact_int_rec.email_osr;
      --End-Added for Defect30204
      log_message ('Calling API - Create Email');
      hz_contact_point_v2pub.create_contact_point
                           (p_init_msg_list          => 'T',
                            p_contact_point_rec      => lr_contact_point_rec_email,
                            p_edi_rec                => lr_edi_rec,
                            p_email_rec              => lr_email_rec,
                            p_phone_rec              => lr_phone_rec_dummy,
                            p_telex_rec              => lr_telex_rec,
                            p_web_rec                => lr_web_rec,
                            x_contact_point_id       => ln_contact_point_id,
                            x_return_status          => lc_contact_point_return_status,
                            x_msg_count              => ln_contact_point_msg_count,
                            x_msg_data               => lc_contact_point_msg_data
                           );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Email, API error message: '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Create Email program = ' || SQLERRM);
         x_return_status := 'E';
   END create_email;

-- +========================================================================+
-- | Name        : Create Phone                                             |
-- | Description : To create phone for contact                              |
-- +========================================================================+
   PROCEDURE create_phone (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_owner_table_id          NUMBER,
      x_return_status     OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_phone       hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec_dummy               hz_contact_point_v2pub.email_rec_type;
      lr_phone_rec                     hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_contact_point_id              NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Create Phone');
      x_return_status := 'S';
      lr_contact_point_rec_phone.contact_point_type := 'PHONE';
      lr_contact_point_rec_phone.owner_table_name := 'HZ_PARTIES';
      lr_contact_point_rec_phone.owner_table_id := p_owner_table_id;
      lr_contact_point_rec_phone.contact_point_purpose :=
                                              p_contact_int_rec.phone_purpose;

      IF (p_contact_int_rec.contact_point_primary_flag = 'P')
      THEN
         lr_contact_point_rec_phone.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_phone.primary_flag := 'N';
      END IF;

      lr_contact_point_rec_phone.created_by_module := 'XXCONV';
      lr_phone_rec.phone_area_code := p_contact_int_rec.phone_area_code;
      lr_phone_rec.phone_country_code := p_contact_int_rec.phone_country_code;
      lr_phone_rec.phone_number := p_contact_int_rec.phone_number;
      lr_phone_rec.phone_line_type := 'GEN';
      lr_phone_rec.phone_extension := p_contact_int_rec.extension;
      --Added for Defect30204
      lr_contact_point_rec_phone.orig_system_reference :=
                                                   p_contact_int_rec.phone_osr;
      --End-Added for Defect30204
      log_message ('Calling API - Create Phone');
      hz_contact_point_v2pub.create_contact_point
                           (p_init_msg_list          => 'T',
                            p_contact_point_rec      => lr_contact_point_rec_phone,
                            p_edi_rec                => lr_edi_rec,
                            p_email_rec              => lr_email_rec_dummy,
                            p_phone_rec              => lr_phone_rec,
                            p_telex_rec              => lr_telex_rec,
                            p_web_rec                => lr_web_rec,
                            x_contact_point_id       => ln_contact_point_id,
                            x_return_status          => lc_contact_point_return_status,
                            x_msg_count              => ln_contact_point_msg_count,
                            x_msg_data               => lc_contact_point_msg_data
                           );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Phone, API error message:  '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Create Phone program = ' || SQLERRM);
         x_return_status := 'E';
   END create_phone;

-- +========================================================================+
-- | Name        : Create Fax                                               |
-- | Description : To create phone for contact                              |
-- +========================================================================+
   PROCEDURE create_fax (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_owner_table_id          NUMBER,
      x_return_status     OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_fax         hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec_dummy               hz_contact_point_v2pub.email_rec_type;
      lr_fax_rec                       hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_contact_point_id              NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Create Fax');
      x_return_status := 'S';
      lr_contact_point_rec_fax.contact_point_type := 'PHONE';
      lr_contact_point_rec_fax.owner_table_name := 'HZ_PARTIES';
      lr_contact_point_rec_fax.owner_table_id := p_owner_table_id;
      lr_contact_point_rec_fax.contact_point_purpose :=
                                                p_contact_int_rec.fax_purpose;

      IF (p_contact_int_rec.contact_point_primary_flag = 'F')
      THEN
         lr_contact_point_rec_fax.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_fax.primary_flag := 'N';
      END IF;

      lr_contact_point_rec_fax.created_by_module := 'XXCONV';
      lr_fax_rec.phone_area_code := p_contact_int_rec.fax_area_code;
      lr_fax_rec.phone_country_code := p_contact_int_rec.fax_country_code;
      lr_fax_rec.phone_number := p_contact_int_rec.fax_number;
      lr_fax_rec.phone_line_type := 'FAX';
      --Added for Defect30204
      lr_contact_point_rec_fax.orig_system_reference :=
                                                     p_contact_int_rec.fax_osr;
      --End-Added for Defect30204
      log_message ('Calling API - Create Fax');
      hz_contact_point_v2pub.create_contact_point
                           (p_init_msg_list          => 'T',
                            p_contact_point_rec      => lr_contact_point_rec_fax,
                            p_edi_rec                => lr_edi_rec,
                            p_email_rec              => lr_email_rec_dummy,
                            p_phone_rec              => lr_fax_rec,
                            p_telex_rec              => lr_telex_rec,
                            p_web_rec                => lr_web_rec,
                            x_contact_point_id       => ln_contact_point_id,
                            x_return_status          => lc_contact_point_return_status,
                            x_msg_count              => ln_contact_point_msg_count,
                            x_msg_data               => lc_contact_point_msg_data
                           );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Fax, API error message: '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Create Fax program = ' || SQLERRM);
         x_return_status := 'E';
   END create_fax;

-- +========================================================================+
-- | Name        : Update Contact                                           |
-- | Description : To update the contact information                        |
-- +========================================================================+
   PROCEDURE update_contact (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      x_return_status     OUT   VARCHAR2
   )
   IS
      CURSOR lcu_contact_check (
         c_cust_account_id   hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE
      )
      IS
         --Commented for R12 Retrofit
         /*   select   PARTY.PARTY_ID,
         PARTY.OBJECT_VERSION_NUMBER PARTY_OBJECT_VERSION_NUMBER,
         ORG_CONT.ORG_CONTACT_ID,
         ORG_CONT.OBJECT_VERSION_NUMBER CONT_OBJECT_VERSION_NUMBER,
         REL.OBJECT_VERSION_NUMBER REL_OBJECT_VERSION_NUMBER
         from HZ_CONTACT_POINTS CONT_POINT,
              HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
              HZ_PARTIES PARTY,
              HZ_PARTIES REL_PARTY,
              HZ_RELATIONSHIPS REL,
              HZ_ORG_CONTACTS ORG_CONT ,
              HZ_CUST_ACCOUNTS ROLE_ACCT,
              HZ_CONTACT_RESTRICTIONS CONT_RES,
              HZ_PERSON_LANGUAGE PER_LANG
         WHERE ACCT_ROLE.PARTY_ID             = REL.PARTY_ID
         AND ACCT_ROLE.ROLE_TYPE              = 'CONTACT'
         AND ORG_CONT.PARTY_RELATIONSHIP_ID   = REL.RELATIONSHIP_ID
         AND REL.SUBJECT_ID                   = PARTY.PARTY_ID
         AND REL_PARTY.PARTY_ID               = REL.PARTY_ID
         and CONT_POINT.OWNER_TABLE_ID(+)     = REL_PARTY.PARTY_ID
         AND CONT_POINT.CONTACT_POINT_TYPE(+) = 'ABC'
         AND CONT_POINT.PRIMARY_FLAG(+)       = 'Y'
         AND ACCT_ROLE.CUST_ACCOUNT_ID        = ROLE_ACCT.CUST_ACCOUNT_ID
         AND ROLE_ACCT.PARTY_ID               = REL.OBJECT_ID
         AND PARTY.PARTY_ID                   = PER_LANG.PARTY_ID(+)
         AND PER_LANG.NATIVE_LANGUAGE(+)      = 'Y'
         AND PARTY.PARTY_ID                   = CONT_RES.SUBJECT_ID(+)
         and CONT_RES.SUBJECT_TABLE(+)        = 'HZ_PARTIES'
         and CONT_POINT.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
         and ORG_CONT.ORIG_SYSTEM_REFERENCE= c_contact_osr
              and ROLE_ACCT.CUST_ACCOUNT_ID = c_cust_account_id;*/

         --Changed for R12 Retrofit
         SELECT party.party_id,
                party.object_version_number party_object_version_number,
                org_cont.org_contact_id,
                org_cont.object_version_number cont_object_version_number,
                rel.object_version_number rel_object_version_number
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                (SELECT *
                   FROM hz_contact_preferences
                  WHERE preference_code = 'DO_NOT'
                    AND contact_level_table <> 'HZ_CONTACT_POINTS') cont_res,
                hz_person_language per_lang
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND cont_point.owner_table_id(+) = rel_party.party_id
            AND cont_point.contact_point_type(+) = 'ABC'
            AND cont_point.primary_flag(+) = 'Y'
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND party.party_id = per_lang.party_id(+)
            AND per_lang.native_language(+) = 'Y'
            AND party.party_id = cont_res.contact_level_table_id(+)
            AND cont_res.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;

      -- Used for create person API
      lr_person_rec                    hz_party_v2pub.person_rec_type;
      ln_party_object_version_number   NUMBER;
      ln_profile_id                    NUMBER;
      lc_create_person_return_status   VARCHAR2 (2000);
      ln_create_person_msg_count       NUMBER;
      lc_create_person_msg_data        VARCHAR2 (2000);
      -- used for create_org_contact API
      lr_org_contact_rec               hz_party_contact_v2pub.org_contact_rec_type;
      ln_cont_object_version_number    NUMBER;
      ln_rel_object_version_number     NUMBER;
      lc_org_contact_return_status     VARCHAR2 (2000);
      ln_org_contact_msg_count         NUMBER;
      lc_org_contact_msg_data          VARCHAR2 (2000);
      ln_party_id                      hz_parties.party_id%TYPE;
      ln_org_contact_id                hz_org_contacts.org_contact_id%TYPE;
   BEGIN
      log_message ('Procedure - Update Contact');
      x_return_status := 'S';

      OPEN lcu_contact_check (gn_cust_account_id,
                              p_contact_int_rec.contact_id
                             );

      FETCH lcu_contact_check
       INTO ln_party_id, ln_party_object_version_number, ln_org_contact_id,
            ln_cont_object_version_number, ln_rel_object_version_number;

      CLOSE lcu_contact_check;

      log_message ('ln_party_id= ' || ln_party_id);
      log_message (   'ln_party_object_version_number= '
                   || ln_party_object_version_number
                  );
      log_message ('ln_org_contact_id= ' || ln_org_contact_id);
      log_message (   'ln_cont_object_version_number= '
                   || ln_cont_object_version_number
                  );
      log_message (   'ln_rel_object_version_number= '
                   || ln_rel_object_version_number
                  );

      IF p_contact_int_rec.contact_end_date IS NULL
      THEN
--------------------------------------------------
         IF    p_contact_int_rec.contact_last_name IS NOT NULL
            OR p_contact_int_rec.contact_first_name IS NOT NULL
         THEN
            log_message
                  ('Calling Update_Person API - Update last name, first name');
            log_message ('ln_party_id : ' || ln_party_id);
            log_message (   'ln_party_object_version_number : '
                         || ln_party_object_version_number
                        );
            lr_person_rec.person_first_name :=
                                          p_contact_int_rec.contact_first_name;
            lr_person_rec.person_last_name :=
                                           p_contact_int_rec.contact_last_name;
            lr_person_rec.party_rec.party_id := ln_party_id;
            log_message ('Calling hz_party_v2pub.update_person');
            hz_party_v2pub.update_person
               (p_init_msg_list                    => 'T',
                p_person_rec                       => lr_person_rec,
                p_party_object_version_number      => ln_party_object_version_number,
                x_profile_id                       => ln_profile_id,
                x_return_status                    => lc_create_person_return_status,
                x_msg_count                        => ln_create_person_msg_count,
                x_msg_data                         => lc_create_person_msg_data
               );

            IF    lc_create_person_return_status = fnd_api.g_ret_sts_error
               OR lc_create_person_return_status =
                                                 fnd_api.g_ret_sts_unexp_error
            THEN
               log_message
                        (   'FALSE_'
                         || gn_account_number
                         || '"'
                         || ','
                         || '"Error'
                         || '"'
                         || ','
                         || '"Update Person API failed, API error message:  '
                         || lc_create_person_msg_data
                        );
               log_message ('Error - Update Contact');
               x_return_status := 'E';
            ELSE
               log_message ('Success - Update Contact');
               x_return_status := 'S';
            END IF;
         END IF;
      END IF;

--------------------------------------------------------------
      IF x_return_status = 'S'
      THEN
         IF    p_contact_int_rec.contact_end_date IS NOT NULL
            OR p_contact_int_rec.job_title IS NOT NULL
         THEN
            lr_org_contact_rec.party_rel_rec.end_date :=
                                           p_contact_int_rec.contact_end_date;
            lr_org_contact_rec.job_title := p_contact_int_rec.job_title;
            lr_org_contact_rec.org_contact_id := ln_org_contact_id;
            log_message ('Update Org cotact: object_id: ' || gn_party_id);
            log_message ('Update Org cotact: Subject id: ' || ln_party_id);
            log_message ('Calling update_org_contact  ');
            --   FND_GLOBAL.apps_initialize(    58590,  50658,  20049       );
            hz_party_contact_v2pub.update_org_contact
               (p_init_msg_list                    => 'T',
                p_org_contact_rec                  => lr_org_contact_rec,
                p_cont_object_version_number       => ln_cont_object_version_number,
                p_rel_object_version_number        => ln_rel_object_version_number,
                p_party_object_version_number      => ln_party_object_version_number,
                x_return_status                    => lc_org_contact_return_status,
                x_msg_count                        => ln_org_contact_msg_count,
                x_msg_data                         => lc_org_contact_msg_data
               );
            log_message (   'lc_org_contact_return_status  :   '
                         || lc_org_contact_return_status
                        );

            IF    lc_org_contact_return_status = fnd_api.g_ret_sts_error
               OR lc_org_contact_return_status = fnd_api.g_ret_sts_unexp_error
            THEN
               log_message
                   (   'FALSE_'
                    || gn_account_number
                    || '"'
                    || ','
                    || '"Error'
                    || '"'
                    || ','
                    || '"Update Org Contact API failed, API error message:  '
                    || lc_org_contact_msg_data
                   );
               x_return_status := 'E';
               log_message ('Error - Update Contact Org');
            ELSE
               x_return_status := 'S';
               log_message ('Success - Update Contact Org');
            END IF;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         log_message ('Error in Update contact program = ' || SQLERRM);
   END update_contact;

-- +========================================================================+
-- | Name        : Update Email                                             |
-- | Description : To update the Email                                      |
-- +========================================================================+
   PROCEDURE update_email (
      p_contact_int_rec          xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_contact_point_id         NUMBER,
      p_ojb_ver_number           NUMBER,
      x_return_status      OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_email       hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec                     hz_contact_point_v2pub.email_rec_type;
      lr_phone_rec_dummy               hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_object_version_number         NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Update Email');
      x_return_status := 'S';
      lr_contact_point_rec_email.contact_point_type := 'EMAIL';
      lr_contact_point_rec_email.owner_table_name := 'HZ_PARTIES';

      --lr_contact_point_rec_email.owner_table_id := p_owner_table_id;
      IF (p_contact_int_rec.contact_point_primary_flag = 'E')
      THEN
         lr_contact_point_rec_email.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_email.primary_flag := 'N';
      END IF;

      lr_contact_point_rec_email.contact_point_purpose :=
                                               p_contact_int_rec.email_purpose;
      --  lr_contact_point_rec_email.created_by_module := 'XXCONV';
      lr_contact_point_rec_email.contact_point_id := p_contact_point_id;
      lr_email_rec.email_format := 'MAILHTML';
      lr_email_rec.email_address := p_contact_int_rec.email_address;
      ln_object_version_number := p_ojb_ver_number;
      log_message ('Calling API - Update Phone');
      hz_contact_point_v2pub.update_contact_point
                         (p_init_msg_list              => 'T',
                          p_contact_point_rec          => lr_contact_point_rec_email,
                          p_edi_rec                    => lr_edi_rec,
                          p_email_rec                  => lr_email_rec,
                          p_phone_rec                  => lr_phone_rec_dummy,
                          p_telex_rec                  => lr_telex_rec,
                          p_web_rec                    => lr_web_rec,
                          p_object_version_number      => ln_object_version_number,
                          x_return_status              => lc_contact_point_return_status,
                          x_msg_count                  => ln_contact_point_msg_count,
                          x_msg_data                   => lc_contact_point_msg_data
                         );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Email, API error message: '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Email program = ' || SQLERRM);
         x_return_status := 'E';
   END update_email;

-- +========================================================================+
-- | Name        : Update Phone                                             |
-- | Description : To update the Phone                                      |
-- +========================================================================+
   PROCEDURE update_phone (
      p_contact_int_rec          xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_contact_point_id         NUMBER,
      p_ojb_ver_number           NUMBER,
      x_return_status      OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_phone       hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec_dummy               hz_contact_point_v2pub.email_rec_type;
      lr_phone_rec                     hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_object_version_number         NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Update Phone');
      x_return_status := 'S';
      lr_contact_point_rec_phone.contact_point_type := 'PHONE';
      lr_contact_point_rec_phone.owner_table_name := 'HZ_PARTIES';
      --lr_contact_point_rec_phone.owner_table_id := p_owner_table_id;
      lr_contact_point_rec_phone.contact_point_purpose :=
                                              p_contact_int_rec.phone_purpose;

      IF (p_contact_int_rec.contact_point_primary_flag = 'P')
      THEN
         lr_contact_point_rec_phone.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_phone.primary_flag := 'N';
      END IF;

      --  lr_contact_point_rec_phone.created_by_module := 'XXCONV';
      lr_contact_point_rec_phone.contact_point_id := p_contact_point_id;
      lr_phone_rec.phone_area_code := p_contact_int_rec.phone_area_code;
      lr_phone_rec.phone_country_code := p_contact_int_rec.phone_country_code;
      lr_phone_rec.phone_number := p_contact_int_rec.phone_number;
      lr_phone_rec.phone_line_type := 'GEN';
      lr_phone_rec.phone_extension := p_contact_int_rec.extension;
      ln_object_version_number := p_ojb_ver_number;
      log_message ('Calling API - Update Phone');
      hz_contact_point_v2pub.update_contact_point
                         (p_init_msg_list              => 'T',
                          p_contact_point_rec          => lr_contact_point_rec_phone,
                          p_edi_rec                    => lr_edi_rec,
                          p_email_rec                  => lr_email_rec_dummy,
                          p_phone_rec                  => lr_phone_rec,
                          p_telex_rec                  => lr_telex_rec,
                          p_web_rec                    => lr_web_rec,
                          p_object_version_number      => ln_object_version_number,
                          x_return_status              => lc_contact_point_return_status,
                          x_msg_count                  => ln_contact_point_msg_count,
                          x_msg_data                   => lc_contact_point_msg_data
                         );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Phone, API error message:  '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Phone Program = ' || SQLERRM);
         x_return_status := 'E';
   END update_phone;

-- +========================================================================+
-- | Name        : Update Fax                                               |
-- | Description : To update the Fax                                        |
-- +========================================================================+
   PROCEDURE update_fax (
      p_contact_int_rec          xx_crm_wc_cust_dcca_int%ROWTYPE,
      p_contact_point_id         NUMBER,
      p_ojb_ver_number           NUMBER,
      x_return_status      OUT   VARCHAR2
   )
   IS
      lr_contact_point_rec_fax         hz_contact_point_v2pub.contact_point_rec_type;
      lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec_dummy               hz_contact_point_v2pub.email_rec_type;
      lr_fax_rec                       hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
      ln_object_version_number         NUMBER;
      lc_contact_point_return_status   VARCHAR2 (2000);
      ln_contact_point_msg_count       NUMBER;
      lc_contact_point_msg_data        VARCHAR2 (2000);
   BEGIN
      log_message ('Procedure - Update Fax');
      x_return_status := 'S';
      lr_contact_point_rec_fax.contact_point_type := 'PHONE';
      lr_contact_point_rec_fax.owner_table_name := 'HZ_PARTIES';
      --lr_contact_point_rec_fax.owner_table_id := p_owner_table_id;
      lr_contact_point_rec_fax.contact_point_purpose :=
                                                p_contact_int_rec.fax_purpose;

      IF (p_contact_int_rec.contact_point_primary_flag = 'F')
      THEN
         lr_contact_point_rec_fax.primary_flag := 'Y';
      ELSE
         lr_contact_point_rec_fax.primary_flag := 'N';
      END IF;

      --  lr_contact_point_rec_fax.created_by_module := 'XXCONV';
      lr_contact_point_rec_fax.contact_point_id := p_contact_point_id;
      lr_fax_rec.phone_area_code := p_contact_int_rec.fax_area_code;
      lr_fax_rec.phone_country_code := p_contact_int_rec.fax_country_code;
      lr_fax_rec.phone_number := p_contact_int_rec.fax_number;
      lr_fax_rec.phone_line_type := 'FAX';
      ln_object_version_number := p_ojb_ver_number;
      log_message ('Calling API - Update Fax');
      hz_contact_point_v2pub.update_contact_point
                         (p_init_msg_list              => 'T',
                          p_contact_point_rec          => lr_contact_point_rec_fax,
                          p_edi_rec                    => lr_edi_rec,
                          p_email_rec                  => lr_email_rec_dummy,
                          p_phone_rec                  => lr_fax_rec,
                          p_telex_rec                  => lr_telex_rec,
                          p_web_rec                    => lr_web_rec,
                          p_object_version_number      => ln_object_version_number,
                          x_return_status              => lc_contact_point_return_status,
                          x_msg_count                  => ln_contact_point_msg_count,
                          x_msg_data                   => lc_contact_point_msg_data
                         );

      IF    lc_contact_point_return_status = fnd_api.g_ret_sts_error
         OR lc_contact_point_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         log_message
            (   'FALSE_'
             || gn_account_number
             || '"'
             || ','
             || '"Error'
             || '"'
             || ','
             || '"Create Contact Point API failed for Fax, API error message: '
             || lc_contact_point_msg_data
            );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Fax program = ' || SQLERRM);
         x_return_status := 'E';
   END update_fax;

-- +========================================================================+
-- | Name        : cust_dunn_contact_update                                 |
-- | Description : To update/create the contact and contact points          |
-- +========================================================================+
   PROCEDURE cust_dunn_contact_update (
      p_contact_int_rec         xx_crm_wc_cust_dcca_int%ROWTYPE,
      x_return_status     OUT   VARCHAR2
   )
   IS
      CURSOR lcu_contact_check (
         c_cust_account_id   hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE
      )
      IS
          --Commented for R12 Retrofit
         /* select 'Y', REL.PARTY_ID
         from HZ_CONTACT_POINTS CONT_POINT,
              HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
              HZ_PARTIES PARTY,
              HZ_PARTIES REL_PARTY,
              HZ_RELATIONSHIPS REL,
              HZ_ORG_CONTACTS ORG_CONT ,
              HZ_CUST_ACCOUNTS ROLE_ACCT,
              HZ_CONTACT_RESTRICTIONS CONT_RES,
              HZ_PERSON_LANGUAGE PER_LANG
         WHERE ACCT_ROLE.PARTY_ID             = REL.PARTY_ID
         AND ACCT_ROLE.ROLE_TYPE              = 'CONTACT'
         AND ORG_CONT.PARTY_RELATIONSHIP_ID   = REL.RELATIONSHIP_ID
         AND REL.SUBJECT_ID                   = PARTY.PARTY_ID
         AND REL_PARTY.PARTY_ID               = REL.PARTY_ID
         and CONT_POINT.OWNER_TABLE_ID(+)     = REL_PARTY.PARTY_ID
         AND CONT_POINT.CONTACT_POINT_TYPE(+) = 'ABC'
         AND CONT_POINT.PRIMARY_FLAG(+)       = 'Y'
         AND ACCT_ROLE.CUST_ACCOUNT_ID        = ROLE_ACCT.CUST_ACCOUNT_ID
         AND ROLE_ACCT.PARTY_ID               = REL.OBJECT_ID
         AND PARTY.PARTY_ID                   = PER_LANG.PARTY_ID(+)
         AND PER_LANG.NATIVE_LANGUAGE(+)      = 'Y'
         AND PARTY.PARTY_ID                   = CONT_RES.SUBJECT_ID(+)
         and CONT_RES.SUBJECT_TABLE(+)        = 'HZ_PARTIES'
         and CONT_POINT.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
         and ORG_CONT.ORIG_SYSTEM_REFERENCE= c_contact_osr
              and ROLE_ACCT.CUST_ACCOUNT_ID = c_cust_account_id;*/

         --Added for R12 Retrofit
         SELECT 'Y', rel.party_id
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                (SELECT *
                   FROM hz_contact_preferences
                  WHERE preference_code = 'DO_NOT'
                    AND contact_level_table <> 'HZ_CONTACT_POINTS') cont_res,
                hz_person_language per_lang
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND cont_point.owner_table_id(+) = rel_party.party_id
            AND cont_point.contact_point_type(+) = 'ABC'
            AND cont_point.primary_flag(+) = 'Y'
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND party.party_id = per_lang.party_id(+)
            AND per_lang.native_language(+) = 'Y'
            AND party.party_id = cont_res.contact_level_table_id(+)
            AND cont_res.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;

      CURSOR lcu_contact_point_check (
         c_cust_account_id     hz_cust_accounts_all.cust_account_id%TYPE,
         c_contact_osr         hz_org_contacts.orig_system_reference%TYPE,
         c_contact_point_osr   hz_contact_points.orig_system_reference%TYPE
      )
      IS
          --Commented for R12 Retrofit
          /*select 'Y', CONT_POINT.contact_point_id, CONT_POINT.object_version_number
          from HZ_CONTACT_POINTS CONT_POINT,
               HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
               HZ_PARTIES PARTY,
               HZ_PARTIES REL_PARTY,
               HZ_RELATIONSHIPS REL,
               HZ_ORG_CONTACTS ORG_CONT ,
               HZ_CUST_ACCOUNTS ROLE_ACCT,
               HZ_CONTACT_RESTRICTIONS CONT_RES,
               HZ_PERSON_LANGUAGE PER_LANG
          WHERE ACCT_ROLE.PARTY_ID             = REL.PARTY_ID
          AND ACCT_ROLE.ROLE_TYPE              = 'CONTACT'
          AND ORG_CONT.PARTY_RELATIONSHIP_ID   = REL.RELATIONSHIP_ID
          AND REL.SUBJECT_ID                   = PARTY.PARTY_ID
          AND REL_PARTY.PARTY_ID               = REL.PARTY_ID
          and CONT_POINT.OWNER_TABLE_ID(+)     = REL_PARTY.PARTY_ID
         -- AND CONT_POINT.CONTACT_POINT_TYPE(+) = 'EMAIL'
          AND CONT_POINT.PRIMARY_FLAG(+)       = 'Y'
          AND ACCT_ROLE.CUST_ACCOUNT_ID        = ROLE_ACCT.CUST_ACCOUNT_ID
          AND ROLE_ACCT.PARTY_ID               = REL.OBJECT_ID
          AND PARTY.PARTY_ID                   = PER_LANG.PARTY_ID(+)
          AND PER_LANG.NATIVE_LANGUAGE(+)      = 'Y'
          AND PARTY.PARTY_ID                   = CONT_RES.SUBJECT_ID(+)
          and CONT_RES.SUBJECT_TABLE(+)        = 'HZ_PARTIES'
          and CONT_POINT.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
          and ORG_CONT.ORIG_SYSTEM_REFERENCE= c_contact_osr
          and CONT_POINT.ORIG_SYSTEM_REFERENCE=c_contact_point_osr
               and ROLE_ACCT.CUST_ACCOUNT_ID = c_cust_account_id;*/

         --Changed for R12 Retrofit
         SELECT 'Y', cont_point.contact_point_id,
                cont_point.object_version_number
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                (SELECT *
                   FROM hz_contact_preferences
                  WHERE preference_code = 'DO_NOT'
                    AND contact_level_table <> 'HZ_CONTACT_POINTS') cont_res,
                hz_person_language per_lang
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND cont_point.owner_table_id(+) = rel_party.party_id
            -- AND CONT_POINT.CONTACT_POINT_TYPE(+) = 'EMAIL'
            AND cont_point.primary_flag(+) = 'Y'
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND party.party_id = per_lang.party_id(+)
            AND per_lang.native_language(+) = 'Y'
            AND party.party_id = cont_res.contact_level_table_id(+)
            AND cont_res.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND cont_point.orig_system_reference = c_contact_point_osr
            AND role_acct.cust_account_id = c_cust_account_id;

      lc_contact_dun_check       CHAR (1);
      lc_contact_check           CHAR (1);
      lc_contact_point_check     CHAR (1);
      ln_owner_table_id          hz_contact_points.owner_table_id%TYPE := NULL;
      ln_object_version_number   hz_contact_points.object_version_number%TYPE
                                                                       := NULL;
      ln_contact_point_id        hz_contact_points.contact_point_id%TYPE
                                                                       := NULL;
      lc_cont_ret_status         VARCHAR (10);
      lc_email_ret_status        VARCHAR (10);
      lc_phone_ret_status        VARCHAR (10);
      lc_fax_ret_status          VARCHAR (10);
      lc_contact_osr             hz_org_contacts.orig_system_reference%TYPE;
      ln_org_contact_id          hz_org_contacts.org_contact_id%TYPE;
   BEGIN
      lc_contact_dun_check := 'N';
      x_return_status := 'S';

      --log_message ('Checking if any dunning contact exists');
      IF p_contact_int_rec.contact_end_date IS NULL
      THEN
         IF     p_contact_int_rec.webcollect_contact_id IS NOT NULL
            AND p_contact_int_rec.contact_id IS NULL
         THEN
            -- Checking if already dunning contact exists
            IF p_contact_int_rec.contact_last_name IS NOT NULL
            THEN
               log_message ('Creating new Contact');
               create_contact (p_contact_int_rec,
                               ln_org_contact_id,
                               lc_cont_ret_status
                              );

               BEGIN
                  SELECT orig_system_reference
                    INTO lc_contact_osr
                    FROM hz_org_contacts
                   WHERE org_contact_id = ln_org_contact_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_contact_osr := NULL;
               END;

               OPEN lcu_contact_check (gn_cust_account_id, lc_contact_osr);

               FETCH lcu_contact_check
                INTO lc_contact_check, ln_owner_table_id;

               CLOSE lcu_contact_check;

               log_message ('ln_owner_table_id = ' || ln_owner_table_id);

               IF lc_cont_ret_status = 'S'
               THEN
                  log_message ('Success - Create Contact');

                  IF p_contact_int_rec.email_address IS NOT NULL
                  THEN
                     log_message ('Creating email');
                     create_email (p_contact_int_rec,
                                   ln_owner_table_id,
                                   lc_email_ret_status
                                  );

                     IF lc_email_ret_status = 'S'
                     THEN
                        log_message ('Success - Create Email');
                     ELSE
                        log_message ('Error - Create Email');
                     END IF;
                  END IF;

                  IF p_contact_int_rec.phone_number IS NOT NULL
                  THEN
                     log_message ('Creating Phone');
                     create_phone (p_contact_int_rec,
                                   ln_owner_table_id,
                                   lc_phone_ret_status
                                  );

                     IF lc_phone_ret_status = 'S'
                     THEN
                        log_message ('Success - Create Phone');
                     ELSE
                        log_message ('Error - Create Phone');
                     END IF;
                  END IF;

                  IF p_contact_int_rec.fax_number IS NOT NULL
                  THEN
                     log_message ('Creating fax');
                     create_fax (p_contact_int_rec,
                                 ln_owner_table_id,
                                 lc_fax_ret_status
                                );

                     IF lc_fax_ret_status = 'S'
                     THEN
                        log_message ('Success - Create Fax');
                     ELSE
                        log_message ('Error - Create Fax');
                     END IF;
                  END IF;
               ELSE
                  log_message ('Error - Create Contact');
               END IF;
            END IF;
         ELSE
            IF p_contact_int_rec.contact_id IS NOT NULL
            THEN
               lc_contact_check := 'N';
               log_message ('Contact OSR= ' || p_contact_int_rec.contact_id);
               log_message ('Checking if Contact OSR exists');

               OPEN lcu_contact_check (gn_cust_account_id,
                                       p_contact_int_rec.contact_id
                                      );

               FETCH lcu_contact_check
                INTO lc_contact_check, ln_owner_table_id;

               CLOSE lcu_contact_check;

               IF lc_contact_check = 'Y'
               THEN
                  log_message ('Contact OSR exists');
                  update_contact (p_contact_int_rec, lc_cont_ret_status);

                  IF lc_cont_ret_status = 'S'
                  THEN
                     log_message ('Success - Update Contact');
                  ELSE
                     log_message ('Error - Update Contact');
                  END IF;

                  IF p_contact_int_rec.email_address IS NOT NULL
                  THEN
                     IF p_contact_int_rec.email_osr IS NOT NULL
                     THEN
                        lc_contact_point_check := 'N';
                        log_message (   'Email OSR= '
                                     || p_contact_int_rec.email_osr
                                    );

                        OPEN lcu_contact_point_check
                                                (gn_cust_account_id,
                                                 p_contact_int_rec.contact_id,
                                                 p_contact_int_rec.email_osr
                                                );

                        FETCH lcu_contact_point_check
                         INTO lc_contact_point_check, ln_contact_point_id,
                              ln_object_version_number;

                        CLOSE lcu_contact_point_check;

                        IF lc_contact_point_check = 'Y'
                        THEN
                           log_message ('Email OSR - Exists');
                           log_message ('Updating email');
                           update_email (p_contact_int_rec,
                                         ln_contact_point_id,
                                         ln_object_version_number,
                                         lc_email_ret_status
                                        );

                           IF lc_email_ret_status = 'S'
                           THEN
                              log_message ('Success - Update Email');
                           ELSE
                              log_message ('Error - Update Email');
                           END IF;
                        ELSE
                              -- log_message ('Invalid - Email OSR');
                           --Added for defect 30204
                           log_message ('Email OSR - Not Existing');
                           log_message ('creating email');
                           create_email (p_contact_int_rec,
                                         ln_owner_table_id,
                                         lc_email_ret_status
                                        );

                           IF lc_email_ret_status = 'S'
                           THEN
                              log_message ('Success - create Email');
                           ELSE
                              log_message ('Error - create Email');
                           END IF;
                        --End - Added for defect 30204
                        END IF;
                     ELSE
                        log_message ('Creating email');
                        create_email (p_contact_int_rec,
                                      ln_owner_table_id,
                                      lc_email_ret_status
                                     );

                        IF lc_email_ret_status = 'S'
                        THEN
                           log_message ('Success - Create Email');
                        ELSE
                           log_message ('Error - Create Email');
                        END IF;
                     END IF;
                  END IF;

                  IF p_contact_int_rec.phone_number IS NOT NULL
                  THEN
                     IF p_contact_int_rec.phone_osr IS NOT NULL
                     THEN
                        lc_contact_point_check := 'N';
                        log_message (   'Phone OSR= '
                                     || p_contact_int_rec.phone_osr
                                    );

                        OPEN lcu_contact_point_check
                                                (gn_cust_account_id,
                                                 p_contact_int_rec.contact_id,
                                                 p_contact_int_rec.phone_osr
                                                );

                        FETCH lcu_contact_point_check
                         INTO lc_contact_point_check, ln_contact_point_id,
                              ln_object_version_number;

                        CLOSE lcu_contact_point_check;

                        IF lc_contact_point_check = 'Y'
                        THEN
                           log_message ('Phone OSR - Exists');
                           log_message ('Updating Phone');
                           update_phone (p_contact_int_rec,
                                         ln_contact_point_id,
                                         ln_object_version_number,
                                         lc_phone_ret_status
                                        );

                           IF lc_phone_ret_status = 'S'
                           THEN
                              log_message ('Success - Update Phone');
                           ELSE
                              log_message ('Error - Update Phone');
                           END IF;
                        ELSE
                           --log_message ('Invalid - Phone OSR');
                           --Added for defect 30204
                           log_message ('Phone OSR - Not Existing');
                           log_message ('creating phone');
                           create_phone (p_contact_int_rec,
                                         ln_owner_table_id,
                                         lc_phone_ret_status
                                        );

                           IF lc_phone_ret_status = 'S'
                           THEN
                              log_message ('Success - Create Phone');
                           ELSE
                              log_message ('Error - Create Phone');
                           END IF;
                        --End - Added for defect 30204
                        END IF;
                     ELSE
                        log_message ('Creating Phone');
                        create_phone (p_contact_int_rec,
                                      ln_owner_table_id,
                                      lc_phone_ret_status
                                     );

                        IF lc_phone_ret_status = 'S'
                        THEN
                           log_message ('Success - Create Phone');
                        ELSE
                           log_message ('Error - Create Phone');
                        END IF;
                     END IF;
                  END IF;

                  IF p_contact_int_rec.fax_number IS NOT NULL
                  THEN
                     IF p_contact_int_rec.fax_osr IS NOT NULL
                     THEN
                        lc_contact_point_check := 'N';
                        log_message ('FAX OSR= ' || p_contact_int_rec.fax_osr);

                        OPEN lcu_contact_point_check
                                               (gn_cust_account_id,
                                                p_contact_int_rec.contact_id,
                                                p_contact_int_rec.fax_osr
                                               );

                        FETCH lcu_contact_point_check
                         INTO lc_contact_point_check, ln_contact_point_id,
                              ln_object_version_number;

                        CLOSE lcu_contact_point_check;

                        IF lc_contact_point_check = 'Y'
                        THEN
                           log_message ('FAX OSR - Exists');
                           log_message ('Updating Fax');
                           update_fax (p_contact_int_rec,
                                       ln_contact_point_id,
                                       ln_object_version_number,
                                       lc_fax_ret_status
                                      );

                           IF lc_fax_ret_status = 'S'
                           THEN
                              log_message ('Success - Update Fax');
                           ELSE
                              log_message ('Error - Update Fax');
                           END IF;
                        ELSE
                           --log_message ('Invalid - FAX OSR');
                           --Added for defect 30204
                           log_message ('Fax OSR - Not Existing');
                           log_message ('creating fax');
                           create_fax (p_contact_int_rec,
                                       ln_owner_table_id,
                                       lc_fax_ret_status
                                      );

                           IF lc_fax_ret_status = 'S'
                           THEN
                              log_message ('Success - Create fax');
                           ELSE
                              log_message ('Error - Create Fax');
                           END IF;
                        --End - Added for defect 30204
                        END IF;
                     ELSE
                        log_message ('Creating Fax');
                        create_fax (p_contact_int_rec,
                                    ln_owner_table_id,
                                    lc_fax_ret_status
                                   );

                        IF lc_fax_ret_status = 'S'
                        THEN
                           log_message ('Success - Create fax');
                        ELSE
                           log_message ('Error - Create Fax');
                        END IF;
                     END IF;
                  END IF;
               ELSE
                  log_message ('Invalid - Contact OSR');
                  x_return_status := 'E';
               END IF;                                --lc_contact_check = 'Y'
            END IF;                 --p_contact_int_rec.contact_id IS NOT NULL
         END IF;         --p_contact_int_rec.webcollect_contact_id IS NOT NULL
      ELSE
         IF p_contact_int_rec.contact_id IS NOT NULL
         THEN
            OPEN lcu_contact_check (gn_cust_account_id,
                                    p_contact_int_rec.contact_id
                                   );

            FETCH lcu_contact_check
             INTO lc_contact_check, ln_owner_table_id;

            CLOSE lcu_contact_check;

            IF lc_contact_check = 'Y'
            THEN
               log_message ('Updating Contact for end date');
               update_contact (p_contact_int_rec, lc_cont_ret_status);

               IF lc_cont_ret_status = 'S'
               THEN
                  log_message ('Success - updated Contact');
               ELSE
                  log_message ('Error - updated Contact');
               END IF;
            ELSE
               log_message ('Error - Contact ID Invalid');
            END IF;
         ELSE
            log_message ('Error - Contact ID is not present for update');
         END IF;
      END IF;                                                   -- end_date if
   END cust_dunn_contact_update;

-- +========================================================================+
-- | Name        : cust_prof_coll_update                                    |
-- | Description : To update the collector in customer profile              |
-- +========================================================================+
   PROCEDURE cust_prof_coll_update (
      p_collector_id          NUMBER,
      x_return_status   OUT   VARCHAR2
   )
   IS
      lrec_prof_rec                hz_customer_profile_v2pub.customer_profile_rec_type;
      lc_prof_return_status        CHAR (1);
      ln_prof_msg_count            NUMBER;
      lc_prof_msg_data             VARCHAR2 (2000);
      ln_cust_account_profile_id   hz_customer_profiles.cust_account_profile_id%TYPE;
      ln_object_version_number     hz_customer_profiles.object_version_number%TYPE;
      lc_error_flag                CHAR (1);
   BEGIN
      log_message ('Starting Customer Profile Update Program');
      x_return_status := 'S';

      BEGIN
         SELECT cust_account_profile_id, object_version_number
           INTO ln_cust_account_profile_id, ln_object_version_number
           FROM hz_customer_profiles
          WHERE site_use_id = gn_site_use_id;
      EXCEPTION
--QC 19432 start
         WHEN NO_DATA_FOUND
         THEN
            log_message ('Bill-To profile does not exist, creating profile');
            create_site_profile (gn_site_use_id,
                                 p_collector_id,
                                 x_return_status
                                );
            RETURN;
--QC 19432 end
         WHEN OTHERS
         THEN
            log_message ('Error while extracting profile');
            x_return_status := 'E';
-- added below line for QC 19432
            RETURN;
      END;

      log_message (   'cust_account_profile_id= '
                   || ln_cust_account_profile_id
                   || ','
                   || ' object_version_number= '
                   || ln_object_version_number
                  );

      IF x_return_status = 'S'
      THEN
         log_message ('Extracting profile details');
         hz_customer_profile_v2pub.get_customer_profile_rec
                    (p_init_msg_list                => 'T',
                     p_cust_account_profile_id      => ln_cust_account_profile_id,
                     x_customer_profile_rec         => lrec_prof_rec,
                     x_return_status                => lc_prof_return_status,
                     x_msg_count                    => ln_prof_msg_count,
                     x_msg_data                     => lc_prof_msg_data
                    );

         IF    lc_prof_return_status = fnd_api.g_ret_sts_error
            OR lc_prof_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            log_message
               (   'FALSE_'
                || gn_account_number
                || '"'
                || ','
                || '"Error'
                || '"'
                || ','
                || '"Update Customer profile for Collector Assignment Failed for Fetch: '
                || lc_prof_msg_data
               );
            x_return_status := 'E';
         END IF;

         log_message ('Profile get Status= ' || lc_prof_return_status);
         log_message ('Current Collector ID= ' || lrec_prof_rec.collector_id);
         log_message ('New Collector ID= ' || p_collector_id);

         IF     x_return_status = 'S'
            AND lrec_prof_rec.collector_id <> p_collector_id
         THEN
            log_message
                       ('Updateing Customer profile for collector assignment');
            lrec_prof_rec.collector_id := p_collector_id;
            hz_customer_profile_v2pub.update_customer_profile
                        (p_init_msg_list              => 'T',
                         p_customer_profile_rec       => lrec_prof_rec,
                         p_object_version_number      => ln_object_version_number,
                         x_return_status              => lc_prof_return_status,
                         x_msg_count                  => ln_prof_msg_count,
                         x_msg_data                   => lc_prof_msg_data
                        );

            IF    lc_prof_return_status = fnd_api.g_ret_sts_error
               OR lc_prof_return_status = fnd_api.g_ret_sts_unexp_error
            THEN
               log_message
                  (   'FALSE_'
                   || gn_account_number
                   || '"'
                   || ','
                   || '"Error'
                   || '"'
                   || ','
                   || '"Create Contact Point API failed for Fax, API error message: '
                   || lc_prof_msg_data
                  );
               x_return_status := 'E';
            END IF;
         ELSE
            log_message ('Same collector - Update not required');
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Customer Profile Pragram = ' || SQLERRM
                     );
         x_return_status := 'E';
   END cust_prof_coll_update;

-- +========================================================================+
-- | Name        : cust_prof_coll_update                                    |
-- | Description : To update the collector in customer profile              |
-- +========================================================================+
   PROCEDURE acct_prof_coll_update (
      p_collector_id          NUMBER,
      x_return_status   OUT   VARCHAR2
   )
   IS
      lrec_prof_rec                hz_customer_profile_v2pub.customer_profile_rec_type;
      lc_prof_return_status        CHAR (1);
      ln_prof_msg_count            NUMBER;
      lc_prof_msg_data             VARCHAR2 (2000);
      ln_cust_account_profile_id   hz_customer_profiles.cust_account_profile_id%TYPE;
      ln_object_version_number     hz_customer_profiles.object_version_number%TYPE;
      ln_collector_id              hz_customer_profiles.collector_id%TYPE;
      lc_error_flag                CHAR (1);
   BEGIN
      log_message ('Starting Customer Profile Update Program');
      x_return_status := 'S';

      BEGIN
         SELECT cust_account_profile_id, object_version_number,
                collector_id
           INTO ln_cust_account_profile_id, ln_object_version_number,
                ln_collector_id
           FROM hz_customer_profiles
          WHERE cust_account_id = gn_cust_account_id
            AND site_use_id IS NULL
            AND status = 'A';
      EXCEPTION
--QC 19432 start
         WHEN NO_DATA_FOUND
         THEN
            log_message ('Account profile does not exist');
            x_return_status := 'E';
            RETURN;
--QC 19432 end
         WHEN OTHERS
         THEN
            x_return_status := 'E';
--QC 19432, added below line
            RETURN;
      END;

      IF p_collector_id = ln_collector_id
      THEN
         log_message ('Colector information is already present');
         x_return_status := 'P';
      END IF;

      log_message (   'cust_account_profile_id= '
                   || ln_cust_account_profile_id
                   || ','
                   || ' object_version_number= '
                   || ln_object_version_number
                  );

      IF x_return_status = 'S'
      THEN
         log_message ('Extracting profile details');
         hz_customer_profile_v2pub.get_customer_profile_rec
                    (p_init_msg_list                => 'T',
                     p_cust_account_profile_id      => ln_cust_account_profile_id,
                     x_customer_profile_rec         => lrec_prof_rec,
                     x_return_status                => lc_prof_return_status,
                     x_msg_count                    => ln_prof_msg_count,
                     x_msg_data                     => lc_prof_msg_data
                    );

         IF    lc_prof_return_status = fnd_api.g_ret_sts_error
            OR lc_prof_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            log_message
               (   'FALSE_'
                || gn_account_number
                || '"'
                || ','
                || '"Error'
                || '"'
                || ','
                || '"Update Customer profile for Collector Assignment Failed for Fetch: '
                || lc_prof_msg_data
               );
            x_return_status := 'E';
         END IF;

         log_message ('Profile get Status= ' || lc_prof_return_status);
         log_message ('Current Collector ID= ' || lrec_prof_rec.collector_id);
         log_message ('New Collector ID= ' || p_collector_id);

         IF     x_return_status = 'S'
            AND lrec_prof_rec.collector_id <> p_collector_id
         THEN
            log_message ('Updataing Account profile for collector assignment');
            lrec_prof_rec.collector_id := p_collector_id;
            hz_customer_profile_v2pub.update_customer_profile
                        (p_init_msg_list              => 'T',
                         p_customer_profile_rec       => lrec_prof_rec,
                         p_object_version_number      => ln_object_version_number,
                         x_return_status              => lc_prof_return_status,
                         x_msg_count                  => ln_prof_msg_count,
                         x_msg_data                   => lc_prof_msg_data
                        );

            IF    lc_prof_return_status = fnd_api.g_ret_sts_error
               OR lc_prof_return_status = fnd_api.g_ret_sts_unexp_error
            THEN
--added below for QC 19432
               log_message
                  (   'FALSE_'
                   || gn_account_number
                   || '"'
                   || ','
                   || '"Error'
                   || '"'
                   || ','
                   || '"Update collector for account failed, API error message: '
                   || lc_prof_msg_data
                  );
--commented below for QC 19432
/*     log_message
          (   'FALSE_'
           || gn_account_number
           || '"'
           || ','
           || '"Error'
           || '"'
           || ','
         || '"Create Contact Point API failed for Fax, API error message: '
           || lc_prof_msg_data
          );
*/
               x_return_status := 'E';
            END IF;
         ELSE
            log_message ('Same collector - Update not required');
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Customer Profile Pragram = ' || SQLERRM
                     );
         x_return_status := 'E';
   END acct_prof_coll_update;

-- +========================================================================+
-- | Name        : xx_cdh_inbound_main                                      |
-- | Description : This is the main program, invoked by CP                  |
-- +========================================================================+
   PROCEDURE xx_cdh_inbound_main (
      x_errbuf       OUT NOCOPY      VARCHAR2,
      x_retcode      OUT NOCOPY      VARCHAR2,
      p_debug_flag   IN              VARCHAR2
   )
   IS
      CURSOR lcu_site_details (c_site_use_id VARCHAR2)
      IS
--added for QC 19432, fix for org_id, inactive status.
         SELECT hcs.cust_acct_site_id, hcs.cust_account_id,
                hca.account_number, hca.party_id
           FROM hz_cust_acct_sites_all hcs,
                hz_cust_accounts hca,
                hz_cust_site_uses_all hcu
          WHERE hca.cust_account_id = hcs.cust_account_id
            AND hcs.cust_acct_site_id = hcu.cust_acct_site_id
            AND hcu.site_use_code = 'BILL_TO'
            AND hcu.site_use_id = c_site_use_id;

--commented for QC 19432
/*         SELECT hcs.cust_acct_site_id, hcs.cust_account_id,
                hca.account_number, hca.party_id
           FROM hz_cust_acct_sites hcs,
                hz_cust_accounts hca,
                hz_cust_site_uses_all hcu
          WHERE hca.cust_account_id = hcs.cust_account_id
            AND hcs.cust_acct_site_id = hcu.cust_acct_site_id
            AND hcu.site_use_code = 'BILL_TO'
            AND hcs.status = 'A'
            AND hca.status = 'A'
            AND hcu.status = 'A'
            AND hcu.site_use_id = c_site_use_id;
*/
      CURSOR lcu_cust_details
      IS
         SELECT   cust_ib.*
             FROM xx_crm_wc_cust_dcca_int cust_ib
            WHERE NVL (cust_ib.process_flag, 'N') IN ('N', 'E')
         ORDER BY cust_ib.site_use_id;

      lc_site_use_flag                CHAR (1);
      lc_site_orig_system_reference   hz_cust_acct_sites.orig_system_reference%TYPE;
      ln_collector_id                 ar_collectors.collector_id%TYPE;
      lc_cust_cont_status             VARCHAR2 (10);
      lc_cust_prof_status             VARCHAR2 (10);
      lc_acct_prof_status             VARCHAR2 (10);
      lc_acct_prof_update             VARCHAR2 (10);
   --lc_message                      VARCHAR2 (500);
   BEGIN
      gc_debug_flag := p_debug_flag;
      log_message ('Starting Main Program');

      --   FND_GLOBAL.apps_initialize(    58590,  50658,  20049       );
         -- Open the cursor
      FOR cust_in IN lcu_cust_details
      LOOP
         BEGIN
            log_message ('************************************************');
            log_message ('Site_use_id= ' || cust_in.site_use_id);
            lc_cust_prof_status := 'S';
            lc_cust_cont_status := 'S';
            gn_site_use_id := cust_in.site_use_id;

            OPEN lcu_site_details (gn_site_use_id);

            FETCH lcu_site_details
             INTO gn_cust_acct_site_id, gn_cust_account_id,
                  gn_account_number, gn_party_id;

            lc_acct_prof_update := 'N';

--QC 19432, moved the below 4 lines inside the IF block, fix for misleading log.
/*
         log_message('gn_cust_acct_site_id = '||gn_cust_acct_site_id);
         log_message('gn_cust_account_id = '||gn_cust_account_id);
         log_message('gn_account_number = '||gn_account_number);
         log_message('gn_party_id = '||gn_party_id);
*/
            IF (lcu_site_details%FOUND)
            THEN
               log_message ('gn_cust_acct_site_id = ' || gn_cust_acct_site_id);
               log_message ('gn_cust_account_id = ' || gn_cust_account_id);
               log_message ('gn_account_number = ' || gn_account_number);
               log_message ('gn_party_id = ' || gn_party_id);
               -- Start - Updating Customer Profile for collector
               log_message ('-------------------------------');
               log_message ('calling Procedure cust_prof_coll_update');

               IF cust_in.collector_id IS NOT NULL
               THEN
                  cust_prof_coll_update (cust_in.collector_id,
                                         lc_cust_prof_status
                                        );
               ELSE
                  log_message
                     ('Collector Assignment update is not required - Collector information is not passed'
                     );
               END IF;

               IF lc_cust_prof_status = 'E'
               THEN
                  log_message ('Error while updating Customer profile');
               ELSE
                  log_message
                     ('Successfully returned from Customer Profile update for colector program'
                     );
                  lc_acct_prof_update := 'Y';
               END IF;

-- Account Profile is update added to update collector information
               IF lc_acct_prof_update = 'Y'
               THEN
                  -- Start - Updating Account Level Profile for collector
                  log_message ('-------------------------------');
                  log_message ('calling Procedure acct_prof_coll_update');
                  acct_prof_coll_update (cust_in.collector_id,
                                         lc_acct_prof_status
                                        );

                  IF lc_acct_prof_status = 'E'
                  THEN
                     log_message ('Error while updating Account profile');
                  ELSIF lc_acct_prof_status = 'P'
                  THEN
                     log_message
                            ('Main - Colector information is already present');
                  ELSE
                     log_message
                        ('Successfully returned from Account Profile update for colector program'
                        );
                  END IF;
               END IF;

               log_message ('-------------------------------');
               -- End - Updating Customer Profile for collector

               -- Start - Updating/Creating Customer Contact and Contact points
               log_message ('======================================');
               log_message ('calling Procedure cust_dunn_contact_update');
               cust_dunn_contact_update (cust_in, lc_cust_cont_status);

               IF lc_cust_cont_status = 'E'
               THEN
                  log_message
                     ('Failed while creating/updating the Customer Contact or Contact Points'
                     );
               ELSE
                  log_message
                     ('Successfully created/updated the Customer Contact or Contact Points'
                     );
               END IF;

               log_message ('======================================');
            -- End - Updating/Creating Customer Contact and Contact points
            END IF;

            log_message ('lc_cust_prof_status = ' || lc_cust_prof_status);
            log_message ('lc_cust_cont_status = ' || lc_cust_cont_status);

            IF lc_cust_prof_status = 'E' AND lc_cust_cont_status = 'E'
            THEN
               UPDATE xx_crm_wc_cust_dcca_int
                  SET process_flag = 'E',
                      process_status = 'ERROR'
                WHERE site_use_id = cust_in.site_use_id
                  AND (   contact_id = cust_in.contact_id
                       OR webcollect_contact_id =
                                                 cust_in.webcollect_contact_id
                      );

               log_message
                  ('Customer Profile Collector and Customer Contact Information not correct'
                  );
            ELSE
               UPDATE xx_crm_wc_cust_dcca_int
                  SET process_flag = 'S',
                      process_status = 'SUCCESS'
                WHERE site_use_id = cust_in.site_use_id
                  AND (   contact_id = cust_in.contact_id
                       OR webcollect_contact_id =
                                                 cust_in.webcollect_contact_id
                      );

               log_message ('Successfully processed the record');
            END IF;

            COMMIT;

            CLOSE lcu_site_details;
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message ('Site Use ID = ' || gn_site_use_id);
               log_message (SQLERRM);

               CLOSE lcu_site_details;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message (SQLERRM);
   END xx_cdh_inbound_main;
END xx_cdh_wc_in_cust_update_pkg;
/

SHOW ERRORS;
