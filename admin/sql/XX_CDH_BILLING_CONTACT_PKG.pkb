SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OF
SET TERM ON
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE BODY XX_CDH_BILLING_CONTACT_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                                                                        |
-- +========================================================================+
-- | Name        : XX_CDH_BILLING_CONTACTS_PKG                              |
-- | Description : 1) To import Billing contacts and contact points into    |
-- |                  Oracle.                                               |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      07-Jul-2012  Devendra Petkar       Initial version             |
-- +========================================================================+



   gc_debug_flag	VARCHAR2(1);


-- +========================================================================+
-- | Name        : log_message                                              |
-- | Description : To write into the log file                               |
-- +========================================================================+

   PROCEDURE log_message (p_message VARCHAR2)
   IS
   BEGIN
   	 xx_cdh_ebl_util_pkg.log_error(p_message);

      IF gc_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_message);
      END IF;
   END;


-- +========================================================================+
-- | Name        : Create Contact                                           |
-- | Description : To create new contact                                    |
-- +========================================================================+

----------------------------------------------Create Billing Contact Start---------------------------------------------------------------------

   PROCEDURE create_contact (
	p_contact_first_name VARCHAR2
	,p_contact_last_name VARCHAR2
	,p_party_id          NUMBER
	,p_cust_account_id   NUMBER
	,p_account_number    NUMBER
	,p_cust_acct_site_id NUMBER
	,x_person_party_id OUT NUMBER
	,x_org_contact_id   OUT NUMBER
	,x_return_status     OUT   VARCHAR2
   )
   IS

      CURSOR coll_rel_cur (
         c_cust_account_id   hz_cust_accounts.cust_account_id%TYPE
      )
      IS
         SELECT hr.relationship_id
           FROM hz_relationships hr, hz_cust_accounts hca
          WHERE hca.party_id = hr.object_id
            AND hr.relationship_code = 'CONTACT_OF'
            AND hr.status = 'A'
            AND hca.cust_account_id = c_cust_account_id;

      CURSOR role_resp_cur (
         c_cust_acct_site_id   hz_cust_account_roles.cust_acct_site_id%TYPE
      )
      IS
         SELECT hrr.responsibility_id
           FROM hz_cust_account_roles hcar, hz_role_responsibility hrr
          WHERE hcar.cust_account_role_id = hrr.cust_account_role_id
            AND hrr.responsibility_type = 'BILLING'
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
      SAVEPOINT create_billing_contact;
      x_return_status := 'S';
      -- Create the person in HZ_PARTIES table
-----------------------------------------------------------------------
      log_message ('Calling API to Create Person');
      lr_person_rec.created_by_module := 'XXCONV';
      lr_person_rec.person_first_name := p_contact_first_name;
      lr_person_rec.person_last_name := p_contact_last_name;
      hz_party_v2pub.create_person
                          (p_init_msg_list      => 'T',
                           p_person_rec         => lr_person_rec,
                           x_party_id           => x_person_party_id,
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
         ROLLBACK TO create_billing_contact;
         log_message (   'FALSE_'
                      || p_account_number
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
-- Set the relationship status of existing contact_of as inactive
      log_message ('Calling API to get the relationship details');

      FOR coll_rel_rec IN coll_rel_cur (p_cust_account_id)  -- arwalgaurav ag
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
             ROLLBACK TO create_billing_contact;
            log_message
               (   'FALSE_'
                || p_account_number
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
              ROLLBACK TO create_billing_contact;
            log_message
                  (   'FALSE_'
                   || p_account_number
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
/* Create the person as contact_od contact in HZ_ORG_CONTACTS AND HZ_RELATIONSHIPS tables */
      lr_org_contact_rec.created_by_module := 'XXCONV';
      lr_org_contact_rec.party_rel_rec.subject_id := x_person_party_id;
      lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
      lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
      lr_org_contact_rec.party_rel_rec.object_id := p_party_id;
      lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
      lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
      lr_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
      lr_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
      lr_org_contact_rec.party_rel_rec.status := 'A' ;
      lr_org_contact_rec.party_rel_rec.start_date :=  SYSDATE;
--      lr_org_contact_rec.party_rel_rec.end_date :=
--                                            to_date(p_contact_end_date,'RRRR-MM-DD HH24:MI:SS');
--      lr_org_contact_rec.job_title := p_job_title;
      log_message ('**********Create Org cotact: Subject id: ' || p_party_id);
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

      X_ORG_CONTACT_ID := ln_org_contact_id_apcontact;

      IF    lc_org_contact_return_status = fnd_api.g_ret_sts_error
         OR lc_org_contact_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_billing_contact;
         log_message
                   (   'FALSE_'
                    || p_account_number
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
      lr_cust_account_role_rec.cust_account_id := p_cust_account_id;
      --commented - as per business, we need to create billing contact only at acct level
      --lr_cust_account_role_rec.cust_acct_site_id := p_cust_acct_site_id;
      --
      lr_cust_account_role_rec.role_type := 'CONTACT';
      lr_cust_account_role_rec.created_by_module := 'XXCONV';
      --lr_cust_account_role_rec.primary_flag :=
      --                             p_contact_role_primary_flag;
      log_message ('Create cust account role:  : ' || p_cust_account_id);
      log_message (   'Create cust account role: ln_cust_acct_site_id_in: '
                   || p_cust_acct_site_id
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
         ROLLBACK TO create_billing_contact;
         log_message
             (   'FALSE_'
              || p_account_number
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
      FOR role_resp_rec IN role_resp_cur (p_cust_acct_site_id)
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
            ROLLBACK TO create_billing_contact;
            log_message
               (   'FALSE_'
                || p_account_number
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

         log_message ( 'role_resp_rec.responsibility_id: '
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
            ROLLBACK TO create_billing_contact;
            log_message
               (   'FALSE_'
                || p_account_number
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
-- Set the contact role as Billing
      lr_role_responsibility_rec.cust_account_role_id :=
                                                       ln_cust_account_role_id;
      lr_role_responsibility_rec.responsibility_type := 'BILLING';
      lr_role_responsibility_rec.created_by_module := 'XXCONV';
      lr_role_responsibility_rec.primary_flag := 'Y';
      log_message
              (   'Create responsibiltiy: ln_cust_account_role_id: '
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
         ROLLBACK TO create_billing_contact;
         log_message
            (   'FALSE_'
             || p_account_number
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
         ROLLBACK TO create_billing_contact;
         log_message (SQLERRM);
         x_return_status := 'E';
   END create_contact;



-- +========================================================================+
-- | Name        : Create_Email                                             |
-- | Description : For creating the new email contact point                 |
-- +========================================================================+

   PROCEDURE create_email (
       p_owner_table_id          NUMBER
       ,p_email_address           VARCHAR2
       ,p_account_number       NUMBER
      ,x_return_status     OUT   VARCHAR2
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

      --Contact Point Primary Flag always should be Y
      lr_contact_point_rec_email.primary_flag := 'Y';


      lr_contact_point_rec_email.contact_point_purpose := 'BILLING';
      lr_contact_point_rec_email.created_by_module := 'XXCONV';
      lr_email_rec.email_format := 'MAILHTML';
      lr_email_rec.email_address := p_email_address;
      log_message('Calling API - Create Email');

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
             || p_account_number
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
         log_message('Error in Create Email program = '||SQLERRM);
         x_return_status := 'E';
   END create_email;



-- +========================================================================+
-- | Name        : Create Phone                                             |
-- | Description : To create phone for contact                              |
-- +========================================================================+

   PROCEDURE create_phone (
	 p_owner_table_id          NUMBER
	 ,p_account_number        NUMBER
         ,p_phone_area_code       VARCHAR2
         ,p_phone_number          VARCHAR2
	,x_return_status     OUT   VARCHAR2
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
      lr_contact_point_rec_phone.contact_point_purpose := 'BILLING';

      --Contact Point Primary Flag always should be Y
      lr_contact_point_rec_phone.primary_flag := 'Y';

      lr_contact_point_rec_phone.created_by_module := 'XXCONV';
      lr_phone_rec.phone_area_code := p_phone_area_code;
      --lr_phone_rec.phone_country_code := p_contact_int_rec.phone_country_code;
      lr_phone_rec.phone_number := p_phone_number;
      lr_phone_rec.phone_line_type := 'GEN';
      --lr_phone_rec.phone_extension := p_contact_int_rec.extension;
      log_message('Calling API - Create Phone');

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
             || p_account_number
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
         log_message('Error in Create Phone program = '||SQLERRM);
         x_return_status := 'E';
   END create_phone;




-- +========================================================================+
-- | Name        : insert_billdoc_contact                                   |
-- | Description : Insert Bill Doc                                          |
-- +========================================================================+

   PROCEDURE insert_billdoc_contact (
	 p_org_contact_id          NUMBER
         ,p_cust_account_id          NUMBER
         ,p_cust_acct_site_id          NUMBER
         ,p_cust_doc_id          NUMBER
	,x_return_status     OUT   VARCHAR2
   )
   IS

   lc_curr_dt DATE := sysdate;
   lc_org_id            number := FND_PROFILE.VALUE('org_id');
   lc_user_id           number := FND_GLOBAL.USER_ID;
   lc_last_update_login number := FND_GLOBAL.LOGIN_ID;
   lc_conc_program_id   number := FND_GLOBAL.CONC_PROGRAM_ID;
   lc_conc_request_id   number := FND_GLOBAL.CONC_REQUEST_ID;
   lc_conc_prog_appl_id number := FND_GLOBAL.PROG_APPL_ID;
   lc_conc_login_id     number := FND_GLOBAL.CONC_LOGIN_ID;
   l_ebl_doc_contact_id	NUMBER;
   lc_contact_exit NUMBER;

  BEGIN


		IF p_cust_acct_site_id IS NOT NULL THEN


			   SELECT COUNT(*) INTO lc_contact_exit  FROM apps.xx_cdh_ebl_contacts
			   WHERE org_contact_id = p_org_contact_id AND  attribute1 = p_cust_account_id
			   AND cust_doc_id = p_cust_doc_id AND cust_acct_site_id = p_cust_acct_site_id ;

		ELSE

			   SELECT COUNT(*) INTO lc_contact_exit  FROM apps.xx_cdh_ebl_contacts
			   WHERE org_contact_id = p_org_contact_id AND  attribute1 = p_cust_account_id
			   AND cust_doc_id = p_cust_doc_id  ;

		END IF;


	   log_message ('Check Contact is present'||lc_contact_exit);

		IF lc_contact_exit = 0 THEN



			    SELECT apps.xx_cdh_ebl_doc_contact_id_s.nextval
			      INTO l_ebl_doc_contact_id
			      FROM dual;



			     INSERT INTO apps.xx_cdh_ebl_contacts (ebl_doc_contact_id,
								  cust_doc_id,
								  org_contact_id,
								  cust_acct_site_id,
								  attribute1,
								  creation_date,
								  created_by,
								  last_update_date,
								  last_updated_by,
								  last_update_login,
								  request_id,
								  program_application_id,
								  program_id,
								  program_update_date)
				VALUES (l_ebl_doc_contact_id,        -- ebl_doc_contact_id
					p_cust_doc_id,               -- cust_doc_id
					p_org_contact_id,            -- org_contact_id
					p_cust_acct_site_id,         -- cust_acct_site_id
					p_cust_account_id ,          -- attribute1
					lc_curr_dt,                   -- creation_date
					lc_user_id,                   -- created_by
					lc_curr_dt,                   -- last_update_date
					lc_user_id,                   -- last_updated_by
					lc_last_update_login,         -- last_update_login
					lc_conc_request_id,           -- request_id
					lc_conc_prog_appl_id,         -- program_application_id
					lc_conc_program_id,           -- program_id
					lc_curr_dt);                  -- program_update_date

			COMMIT;
		END IF;

END insert_billdoc_contact;





-- +========================================================================+
-- | Name        : create_billing_contact                                 |
-- | Description : To update/create the contact and contact points          |
-- +========================================================================+

   PROCEDURE create_billing_contact (
      p_cust_account_id   NUMBER
     ,p_account_number    NUMBER
     ,p_party_id          NUMBER
     ,p_cust_acct_site_id NUMBER
     ,p_contact_first_name VARCHAR2
     ,p_contact_last_name VARCHAR2
     ,p_email_address           VARCHAR2
     ,p_phone_area_code       VARCHAR2
     ,p_phone_number          VARCHAR2
     ,p_tmp_rowid rowid
     ,p_org_contact_id   OUT   NUMBER
     ,x_return_status     OUT   VARCHAR2
  )
   IS

      CURSOR lcu_contact_check (
         c_cust_account_id     hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr         hz_org_contacts.orig_system_reference%TYPE
      )
      IS
         SELECT 'Y', REL.PARTY_ID
	   FROM HZ_CONTACT_POINTS CONT_POINT,
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
           and ROLE_ACCT.CUST_ACCOUNT_ID = c_cust_account_id;


      CURSOR lcu_contact_point_check (
         c_cust_account_id   hz_cust_accounts_all.cust_account_id%TYPE,
         c_contact_osr         hz_org_contacts.orig_system_reference%TYPE,
         c_contact_point_osr   hz_contact_points.orig_system_reference%TYPE
      )
      IS
         SELECT 'Y', CONT_POINT.contact_point_id, CONT_POINT.object_version_number
	   FROM HZ_CONTACT_POINTS CONT_POINT,
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
           and ROLE_ACCT.CUST_ACCOUNT_ID = c_cust_account_id;

         lc_contact_billing_check       CHAR (1);
         lc_contact_check           CHAR (1);
         lc_contact_point_check     CHAR (1);
         ln_owner_table_id          hz_contact_points.owner_table_id%TYPE := NULL;
         ln_object_version_number   hz_contact_points.object_version_number%TYPE;
         ln_contact_point_id        hz_contact_points.contact_point_id%TYPE  := NULL;
         lc_cont_ret_status         VARCHAR (10);
         lc_email_ret_status        VARCHAR (10);
         lc_phone_ret_status        VARCHAR (10);
         lc_fax_ret_status          VARCHAR (10);
         lc_contact_OSR hz_org_contacts.orig_system_reference%type;
         ln_org_contact_id hz_org_contacts.ORG_CONTACT_ID%type;
         ln_person_party_id         NUMBER;
   BEGIN
      lc_contact_billing_check := 'N';
      x_return_status := 'S';
      --log_message ('Checking if any billing contact exists');

            -- Checking if already billing contact exists

               log_message ('Creating new Contact');
               create_contact ( p_contact_first_name ,p_contact_last_name ,p_party_id ,p_cust_account_id ,p_account_number ,p_cust_acct_site_id ,ln_person_party_id, ln_org_contact_id, lc_cont_ret_status );


               BEGIN
                  SELECT ORIG_SYSTEM_REFERENCE
                 INTO lc_contact_osr
                FROM HZ_ORG_CONTACTS
               WHERE ORG_CONTACT_ID = ln_org_contact_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     lc_contact_OSR := NULL;
               END;

	       p_org_contact_id := ln_org_contact_id;

               OPEN lcu_contact_check (p_cust_account_id,
                                       lc_contact_OSR
                                      );

               FETCH lcu_contact_check
                INTO lc_contact_check, ln_owner_table_id;
               CLOSE lcu_contact_check;
               log_message('ln_owner_table_id = '||ln_owner_table_id);

               IF lc_cont_ret_status = 'S'
               THEN
                  log_message ('Success - Create Contact');

		UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Contact Created '||ln_org_contact_id||' -- '
		WHERE ROWID = p_tmp_rowid;

                  IF p_email_address IS NOT NULL
                  THEN
                     log_message ('Creating email');
                     create_email (
                                   ln_owner_table_id,
				   p_email_address,
				   p_account_number,
                                   lc_email_ret_status
                                  );

                     IF lc_email_ret_status = 'S'
                     THEN
                        log_message ('Success - Create Email');

			UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Email Created  -- '
			WHERE ROWID = p_tmp_rowid;


		     ELSE
                        log_message ('Error - Create Email');

			UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Error - Create Email  -- '
			WHERE ROWID = p_tmp_rowid;

		     END IF;


		  END IF;

                  IF p_phone_number IS NOT NULL
                  THEN
                     log_message ('Creating Phone');
                     create_phone ( ln_owner_table_id
		                   ,p_account_number
				   ,p_phone_area_code
				   ,p_phone_number
                                   ,lc_phone_ret_status
                                  );

                     IF lc_phone_ret_status = 'S'
                     THEN
                        log_message ('Success - Create Phone');

			UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Phone Created  -- '
			WHERE ROWID = p_tmp_rowid;


		     ELSE
                        log_message ('Error - Create Phone');

			UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Error - Create Phone  -- '
			WHERE ROWID = p_tmp_rowid;

		     END IF;
                  END IF;

               ELSE
                  log_message ('Error - Create Contact');

		   UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Error - Create Contact  -- '
		   WHERE ROWID = p_tmp_rowid;


               END IF;

   END create_billing_contact;


----------------------------------------------Create Billing Contact End---------------------------------------------------------------------


----------------------------------------------Update Billing Contact Start---------------------------------------------------------------------

   PROCEDURE update_billing_contact (
		 p_contact_osr      IN  VARCHAR2
		,p_cust_account_id      IN NUMBER
		,p_cust_doc_id	IN NUMBER
		,p_cust_acct_site_id IN NUMBER
		,p_tmp_rowid        IN ROWID
		,x_return_status     OUT   VARCHAR2
   )
   IS
	l_org_contact_id NUMBER;
        l_sqlerrm        VARCHAR2(100);
	lc_contact_exit   NUMBER;
	lc_curr_dt DATE := sysdate;
	lc_org_id            number := FND_PROFILE.VALUE('org_id');
	lc_user_id           number := FND_GLOBAL.USER_ID;
	lc_last_update_login number := FND_GLOBAL.LOGIN_ID;
	lc_conc_program_id   number := FND_GLOBAL.CONC_PROGRAM_ID;
	lc_conc_request_id   number := FND_GLOBAL.CONC_REQUEST_ID;
	lc_conc_prog_appl_id number := FND_GLOBAL.PROG_APPL_ID;
	lc_conc_login_id     number := FND_GLOBAL.CONC_LOGIN_ID;
	l_ebl_doc_contact_id	NUMBER;
	BEGIN

		SELECT org_contact_id INTO l_org_contact_id
			FROM apps.hz_org_contacts org_cont
		WHERE orig_system_reference= p_contact_osr and status='A';

		UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' ORG Contact Id '||l_org_contact_id||' is found '
		WHERE ROWID = p_tmp_rowid;

		log_message (' ORG Contact Id '||l_org_contact_id||' is found ');



			IF p_cust_acct_site_id IS NOT NULL THEN


				   SELECT COUNT(*) INTO lc_contact_exit  FROM apps.xx_cdh_ebl_contacts
				   WHERE org_contact_id = l_org_contact_id AND  attribute1 = p_cust_account_id
				   AND cust_doc_id = p_cust_doc_id AND cust_acct_site_id = p_cust_acct_site_id ;

			ELSE

				   SELECT COUNT(*) INTO lc_contact_exit  FROM apps.xx_cdh_ebl_contacts
				   WHERE org_contact_id = l_org_contact_id AND  attribute1 = p_cust_account_id
				   AND cust_doc_id = p_cust_doc_id AND cust_acct_site_id IS NULL ;

			END IF;


			   IF lc_contact_exit = 0 THEN



				    SELECT apps.xx_cdh_ebl_doc_contact_id_s.nextval
				      INTO l_ebl_doc_contact_id
				      FROM dual;


				     INSERT INTO apps.xx_cdh_ebl_contacts (ebl_doc_contact_id,
									  cust_doc_id,
									  org_contact_id,
									  cust_acct_site_id,
									  attribute1,
									  creation_date,
									  created_by,
									  last_update_date,
									  last_updated_by,
									  last_update_login,
									  request_id,
									  program_application_id,
									  program_id,
									  program_update_date)
					VALUES (l_ebl_doc_contact_id,        -- ebl_doc_contact_id
						p_cust_doc_id,               -- cust_doc_id
						l_org_contact_id,            -- org_contact_id
						p_cust_acct_site_id,         -- cust_acct_site_id
						p_cust_account_id ,          -- attribute1
						lc_curr_dt,                   -- creation_date
						lc_user_id,                   -- created_by
						lc_curr_dt,                   -- last_update_date
						lc_user_id,                   -- last_updated_by
						lc_last_update_login,         -- last_update_login
						lc_conc_request_id,           -- request_id
						lc_conc_prog_appl_id,         -- program_application_id
						lc_conc_program_id,           -- program_id
						lc_curr_dt);                  -- program_update_date

--					COMMIT;




					  IF SQL%ROWCOUNT > 0 THEN

					     UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Insert Successful ' , process_flag= 'S'
					     WHERE ROWID = p_tmp_rowid;

					     log_message ('Insert Successful ');

					  ELSE

					      UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Insert Unsuccessful ' , process_flag= 'E'
					      WHERE ROWID = p_tmp_rowid;

					     log_message ('Insert Unsuccessful ');

					  END IF;


			   ELSE

					UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Contact already Present ' , process_flag= 'E'
					     WHERE ROWID = p_tmp_rowid;

			   END IF;


		COMMIT;


	EXCEPTION
	WHEN OTHERS THEN

          l_sqlerrm := SUBSTR(sqlerrm,1,100);

	UPDATE xxod_cdh_ebl_contacts_stg
		SET comments = comments||' Record Failed ' || l_sqlerrm, process_flag='E'
	WHERE ROWID = p_tmp_rowid;


  END  update_billing_contact;

----------------------------------------------Update Billing Contact End---------------------------------------------------------------------


----------------------------------------------Delete Billing Contact Start---------------------------------------------------------------------

   PROCEDURE delete_billing_contact (
		 p_contact_osr      IN  VARCHAR2
		,p_cust_account_id      IN NUMBER
		,p_cust_doc_id	IN NUMBER
		,p_cust_acct_site_id IN NUMBER
		,p_tmp_rowid        IN ROWID
		,x_return_status     OUT   VARCHAR2
   )
   IS
	l_org_contact_id NUMBER;
        l_sqlerrm        VARCHAR2(100);
	BEGIN

		SELECT org_contact_id INTO l_org_contact_id
			FROM apps.hz_org_contacts org_cont
		WHERE orig_system_reference= p_contact_osr and status='A';

		UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' ORG Contact Id '||l_org_contact_id||' is found '
		WHERE ROWID = p_tmp_rowid;

		log_message (' ORG Contact Id '||l_org_contact_id||' is found ');


		IF p_cust_acct_site_id IS NOT NULL THEN


			   DELETE FROM apps.xx_cdh_ebl_contacts
			   WHERE org_contact_id = l_org_contact_id AND  attribute1 = p_cust_account_id
			   AND cust_doc_id = p_cust_doc_id AND cust_acct_site_id = p_cust_acct_site_id ;

                  IF SQL%ROWCOUNT > 0 THEN

                     UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Delete Successful ' , process_flag= 'S'
                     WHERE ROWID = p_tmp_rowid;

		     log_message ('Delete Successful ');

                  ELSE

                      UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Delete Unsuccessful ' , process_flag= 'E'
                      WHERE ROWID = p_tmp_rowid;

		     log_message ('Delete Unsuccessful ');

                  END IF;


         ELSE

            DELETE FROM apps.xx_cdh_ebl_contacts
            WHERE org_contact_id = l_org_contact_id AND  attribute1 = p_cust_account_id
            AND cust_doc_id = p_cust_doc_id ;

                  IF SQL%ROWCOUNT > 0 THEN

                     UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Delete Successful ' , process_flag= 'S'
                     WHERE ROWID = p_tmp_rowid;

		     log_message ('Delete Successful ');

                  ELSE

                      UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||'Delete Unsuccessful ' , process_flag= 'E'
                      WHERE ROWID = p_tmp_rowid;

		     log_message ('Delete Unsuccessful ');

                  END IF;



         END IF;




	EXCEPTION
	WHEN OTHERS THEN

          l_sqlerrm := SUBSTR(sqlerrm,1,100);

	UPDATE xxod_cdh_ebl_contacts_stg
		SET comments = comments||' Record Failed ' || l_sqlerrm, process_flag='E'
	WHERE ROWID = p_tmp_rowid;


  END  delete_billing_contact;


----------------------------------------------Delete Billing Contact End---------------------------------------------------------------------


   PROCEDURE xx_cdh_billing_contact_main (
      x_errbuf       OUT NOCOPY      VARCHAR2
      ,x_retcode      OUT NOCOPY      VARCHAR2
      ,p_debug_flag   IN              VARCHAR2
      ,p_batch_id     IN              NUMBER
   )
   IS


	l_cust_account_id	   hz_cust_accounts.cust_account_id%TYPE;
	l_account_number	   hz_cust_accounts.account_number%TYPE;
	lc_org_contact_id	   hz_org_contacts.org_contact_id%TYPE;
	l_cust_acct_site_id   NUMBER;
	l_party_id            NUMBER;
	l_org_id               NUMBER;
	lc_contact_return_status   VARCHAR2(1);
	lc_comments              VARCHAR2(4000);
        lc_bill_doc_cnt     NUMBER;


      CURSOR lcu_cust_details
      IS
         SELECT   ebl_cont.rowid tmp_rowid,  ebl_cont.aops_account_number , ebl_cont.aops_address_seq , ebl_cont.contact_first_name
		  ,ebl_cont.contact_last_name, ebl_cont.contact_osr,  ebl_cont.contact_status , ebl_cont.email_address
		  ,ebl_cont.phone_area_code, ebl_cont.phone_number, ebl_cont.cust_doc_id
             FROM xxod_cdh_ebl_contacts_stg ebl_cont
            WHERE NVL (process_flag, 'N') IN ('N', 'E')
	          AND batch_id = p_batch_id
         ORDER BY cust_doc_id;

   BEGIN
      gc_debug_flag := p_debug_flag;
      log_message ('Starting Main Program');


      -- Open the cursor lcu_cust_details
      FOR cust_in IN lcu_cust_details
      LOOP

	 BEGIN



			log_message ('................ Contact creation is start .............. ');
			log_message (' Aops Account Number = ' || cust_in.aops_account_number);
			log_message (' Site Sequence Number = ' || cust_in.AOPS_ADDRESS_SEQ);
			log_message (' Contact Original System Reference  = ' || cust_in.contact_osr);
			log_message ('OSR  '||LPAD(cust_in.aops_account_number,8,'0') || '-' || LPAD(cust_in.AOPS_ADDRESS_SEQ,5,'0') || '-' || 'A0');


			BEGIN


				IF TRIM(cust_in.aops_address_seq) IS NOT NULL THEN

				    SELECT HCAS.cust_acct_site_id
					 , HCAS.cust_account_id
					 , HCA.account_number
					 , HCA.party_id
					 , HCAS.org_id
					 INTO
					  l_cust_acct_site_id
					 ,l_cust_account_id
					 ,l_account_number
					 ,l_party_id
					 ,l_org_id
				      FROM hz_cust_acct_sites_all HCAS
					 , hz_cust_accounts HCA
				     WHERE HCAS.orig_system_reference = LPAD(cust_in.aops_account_number,8,'0') || '-' || LPAD(cust_in.AOPS_ADDRESS_SEQ,5,'0') || '-' || 'A0'
				       AND HCAS.cust_account_id = HCA.cust_account_id
				       AND HCA.status = 'A'
				       AND HCAS.status = 'A' ;

				 ELSIF TRIM(cust_in.aops_address_seq) IS NULL THEN


				    SELECT HCA.cust_account_id
					 , HCA.account_number
					 , HCA.party_id
					 INTO
					  l_cust_account_id
					 ,l_account_number
					 ,l_party_id
				      FROM hz_cust_accounts HCA
				     WHERE HCA.orig_system_reference = LPAD(cust_in.aops_account_number,8,'0') || '-00001-A0'
				       AND HCA.status = 'A';

				       l_cust_acct_site_id := NULL;
				       l_org_id		:= NULL;

				ELSE

					UPDATE xxod_cdh_ebl_contacts_stg SET process_flag = 'E' , comments = comments||' Account is not present '
					WHERE ROWID = cust_in.tmp_rowid;

					GOTO LAST_STATEMENT_MAIN;

				END IF;


				lc_comments := lc_comments||' Account is present ';

				UPDATE xxod_cdh_ebl_contacts_stg SET comments = comments||' Account is present '
				WHERE ROWID = cust_in.tmp_rowid;


				log_message (' Aops Account Number = ' || l_account_number);

				log_message (' Cust Account Id = ' || l_cust_account_id);

				log_message (' Cust Acct Site Id  = ' || l_cust_acct_site_id);

				log_message (' Party Id = ' || l_party_id);

				log_message (' Contact First Name = ' || cust_in.contact_first_name);

				log_message (' Contact Last Name  = ' || cust_in.contact_last_name);

				log_message (' Email Address = ' || cust_in.email_address);

				log_message (' Area Code = ' || cust_in.phone_area_code);

				log_message (' Phone Number  = ' || cust_in.phone_number);

				log_message (' Contact OSR = ' || cust_in.contact_osr);

				log_message (' Doc Id = ' || cust_in.cust_doc_id);



			EXCEPTION
			   WHEN OTHERS THEN
				lc_comments := lc_comments||' Account is not present ';

				UPDATE xxod_cdh_ebl_contacts_stg SET process_flag = 'E' , comments = lc_comments
				WHERE ROWID = cust_in.tmp_rowid;

			   GOTO LAST_STATEMENT_MAIN;

			END;



			IF cust_in.contact_osr IS NULL AND cust_in.contact_status = 'A' THEN



				   BEGIN
					SELECT MAX ( org_cont.org_contact_id ) INTO lc_org_contact_id
					 FROM hz_relationships hr, hz_cust_accounts hca, hz_parties hp, hz_org_contacts org_cont
					WHERE hca.party_id = hr.object_id
					     AND hr.relationship_code = 'CONTACT_OF'
					     AND hr.status = 'A'
					     AND hr.subject_id = hp.party_id
					     AND hp.status = 'A'
					     AND hp.party_type = 'PERSON'
					     AND hr.relationship_id = org_cont.party_relationship_id
					     AND UPPER(NVL(hp.person_first_name,'99999')) = UPPER(NVL(cust_in.contact_first_name,'99999'))
					     AND UPPER(NVL(hp.person_last_name,'99999')) = UPPER(NVL(cust_in.contact_last_name,'99999'))
					     AND hca.cust_account_id = l_cust_account_id;

				  EXCEPTION
				   WHEN OTHERS THEN
					lc_org_contact_id := null;
				  END;

				IF lc_org_contact_id IS null THEN

				  create_billing_contact (l_cust_account_id ,l_account_number ,l_party_id ,l_cust_acct_site_id ,cust_in.contact_first_name ,cust_in.contact_last_name ,cust_in.email_address ,cust_in.phone_area_code ,cust_in.phone_number ,cust_in.tmp_rowid , lc_org_contact_id ,lc_contact_return_status );

				END IF;


				IF lc_org_contact_id IS NOT NULL THEN

				insert_billdoc_contact(lc_org_contact_id ,l_cust_account_id ,l_cust_acct_site_id, cust_in.cust_doc_id, lc_contact_return_status );

				END IF;


			END IF;

			IF  cust_in.contact_osr IS NOT NULL AND cust_in.contact_status = 'A' THEN

				update_billing_contact ( cust_in.contact_osr,l_cust_account_id, cust_in.cust_doc_id, l_cust_acct_site_id, cust_in.tmp_rowid, lc_contact_return_status );


			END IF;


			IF  cust_in.contact_osr IS NOT NULL AND cust_in.contact_status = 'I' THEN

				delete_billing_contact ( cust_in.contact_osr,l_cust_account_id, cust_in.cust_doc_id, l_cust_acct_site_id, cust_in.tmp_rowid, lc_contact_return_status );


			END IF;



	END;

	<<LAST_STATEMENT_MAIN>>
	NULL;

     END LOOP;
     -- Close the cursor lcu_cust_details

 --COMMIT;

   EXCEPTION
      WHEN OTHERS
      THEN
         log_message(sqlerrm);

   END xx_cdh_billing_contact_main;
END XX_CDH_BILLING_CONTACT_PKG;
/

SHOW ERROR

ALTER PACKAGE XX_CDH_BILLING_CONTACT_PKG COMPILE PACKAGE;
ALTER PACKAGE XX_CDH_BILLING_CONTACT_PKG COMPILE BODY;
ALTER PACKAGE XXOD_CDH_UPLOAD_EBLCONTACTS COMPILE PACKAGE;
ALTER PACKAGE XXOD_CDH_UPLOAD_EBLCONTACTS COMPILE BODY;


