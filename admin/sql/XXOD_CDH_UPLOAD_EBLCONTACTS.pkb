
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY xxod_cdh_upload_eblcontacts
/* ===============================================================================================+
 |                       Copyright (c) 2008 Office Depot                                          |
 |                       Boca Raton, FL, USA                                                      |
 |                       All rights reserved.                                                     |
 +================================================================================================+
 |File Name     XXOD_CDH_UPLOAD_EBLCONTACTS.pkb                                                   |
 |Description                                                                                     |
 |              Package specification and body for submitting the                                 |
 |              request set programmatically for Ebl Contacts Upload                              |
 |                                                                                                |
 |  Date        Author              Comments                                                      |
 |  07-Jul-12   Devendra Petkar      Initial version                                              |
 |  16-Oct-12   Satish Siliveri     load_ebl_contact_int - added trim for the defect 20757        |
 |  19-Feb-14   Darshini            I2186 - Replaced the table - 'hz_contact_restrictions'        |
 |                                  with - 'hz_contact_preferences' for Defect# 28358             |
 |  22-OCT-15   Vasu Raparla         Removed Schema references for R12.2                          |
 |=============================================================================================== */

AS
----------------------------
--Declaring Global Variables
----------------------------
-- +========================================================================+
-- | Name        : log_message                                              |
-- | Description : To write into the log file                               |
-- +========================================================================+

   PROCEDURE log_message (p_message VARCHAR2)
   IS
   BEGIN
      --fnd_file.put_line (fnd_file.LOG, p_message);
     --DBMS_OUTPUT.put_line (p_message);
      xx_cdh_ebl_util_pkg.log_error (p_message);
   END;

-- +========================================================================+
-- | Name        : Create Contact                                           |
-- | Description : To create new contact                                    |
-- +========================================================================+

   ----------------------------------------------Create Billing Contact Start---------------------------------------------------------------------
   PROCEDURE create_contact (
      p_contact_first_name         VARCHAR2,
      p_contact_last_name          VARCHAR2,
      p_party_id                   NUMBER,
      p_cust_account_id            NUMBER,
      p_account_number             NUMBER,
      p_cust_acct_site_id          NUMBER,
      x_person_party_id      OUT   NUMBER,
      x_org_contact_id       OUT   NUMBER,
      x_return_status        OUT   VARCHAR2
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
            AND sysdate between nvl(hr.start_date, sysdate) and nvl(hr.end_date, sysdate+1)
            AND hca.cust_account_id = c_cust_account_id;

      CURSOR role_resp_cur (
         c_cust_account_id   hz_cust_account_roles.cust_account_id%TYPE
      )
      IS
         SELECT hrr.responsibility_id
           FROM hz_cust_account_roles hcar, hz_role_responsibility hrr
          WHERE hcar.cust_account_role_id = hrr.cust_account_role_id
            AND hrr.responsibility_type = 'BILLING'
            AND hrr.primary_flag = 'Y'
            AND hcar.cust_account_id = c_cust_account_id;

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
         log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Person API failed, API error message:  ' || lc_create_person_msg_data );
         x_return_status := 'E';
         GOTO last_statement;
      END IF;

--------------------------------------------------------------

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
      lr_org_contact_rec.party_rel_rec.status := 'A';
      lr_org_contact_rec.party_rel_rec.start_date := SYSDATE;

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
      x_org_contact_id := ln_org_contact_id_apcontact;

      IF    lc_org_contact_return_status = fnd_api.g_ret_sts_error
         OR lc_org_contact_return_status = fnd_api.g_ret_sts_unexp_error
      THEN
         ROLLBACK TO create_billing_contact;
          log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Org Contact API failed, API error message:  ' || lc_org_contact_msg_data );
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

      --lr_cust_account_role_rec.primary_flag := p_contact_role_primary_flag;

      log_message ('Create cust account role:  : ' || p_cust_account_id
                   ||  'Create cust account role: ln_cust_acct_site_id_in: '
                   || p_cust_acct_site_id || 'Create cust account role: ln_party_id_create_org_contact: '
                   || ln_party_id_create_org_contact);

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
          log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Cust Account Role API failed, API error message:  ' || lc_cust_acct_role_msg_data );
         x_return_status := 'E';
         GOTO last_statement;
      END IF;

-------------------------------------------------------------------------------------------------------------------

      -- To reset the primary flag to N for the exisiting contacts
      FOR role_resp_rec IN role_resp_cur (p_cust_account_id)
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
             log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Get Role Responsiblity Rec API failed for responsibility_id: ' || role_resp_rec.responsibility_id || ' , API error message:  ' || lc_get_role_resp_msg_data );
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
            ROLLBACK TO create_billing_contact;
             log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Get Role Responsiblity Rec API failed for responsibility_id: ' || role_resp_rec.responsibility_id || ' , API error message:  ' || lc_upd_role_resp_msg_data );
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
         ROLLBACK TO create_billing_contact;
          log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Role Responsibility API failed, API error message: ' || lc_role_resp_msg_data );
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
      p_owner_table_id         NUMBER,
      p_email_address          VARCHAR2,
      p_account_number         NUMBER,
      x_return_status    OUT   VARCHAR2
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
         log_message ( 'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Email, API error message: ' || lc_contact_point_msg_data );
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
      p_owner_table_id          NUMBER,
      p_account_number          NUMBER,
      p_phone_area_code         VARCHAR2,
      p_phone_number            VARCHAR2,
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
      lr_contact_point_rec_phone.contact_point_purpose := 'BILLING';
      --Contact Point Primary Flag always should be Y
      lr_contact_point_rec_phone.primary_flag := 'Y';
      lr_contact_point_rec_phone.created_by_module := 'XXCONV';
      lr_phone_rec.phone_area_code := p_phone_area_code;
      --lr_phone_rec.phone_country_code := p_contact_int_rec.phone_country_code;
      lr_phone_rec.phone_number := p_phone_number;
      lr_phone_rec.phone_line_type := 'GEN';
      --lr_phone_rec.phone_extension := p_contact_int_rec.extension;
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
          log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Phone, API error message:  ' || lc_contact_point_msg_data );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Create Phone program = ' || SQLERRM);
         x_return_status := 'E';
   END create_phone;

-- +========================================================================+
-- | Name        : insert_billdoc_contact                                   |
-- | Description : Insert Bill Doc                                          |
-- +========================================================================+
   PROCEDURE insert_billdoc_contact (
      p_org_contact_id            NUMBER,
      p_cust_account_id           NUMBER,
      p_cust_acct_site_id         NUMBER,
      p_cust_doc_id               NUMBER,
      p_tmp_rowid                 ROWID,
      x_return_status       OUT   VARCHAR2
   )
   IS
      lc_curr_dt             DATE   := SYSDATE;
      lc_org_id              NUMBER := fnd_profile.VALUE ('org_id');
      lc_user_id             NUMBER := fnd_global.user_id;
      lc_last_update_login   NUMBER := fnd_global.login_id;
      lc_conc_program_id     NUMBER := fnd_global.conc_program_id;
      lc_conc_request_id     NUMBER := fnd_global.conc_request_id;
      lc_conc_prog_appl_id   NUMBER := fnd_global.prog_appl_id;
      lc_conc_login_id       NUMBER := fnd_global.conc_login_id;
      l_ebl_doc_contact_id   NUMBER;
      lc_contact_exit        NUMBER;
   BEGIN
      IF p_cust_acct_site_id IS NOT NULL
      THEN
         SELECT COUNT (*)
           INTO lc_contact_exit
           FROM xx_cdh_ebl_contacts
          WHERE org_contact_id = p_org_contact_id
            AND attribute1 = p_cust_account_id
            AND cust_doc_id = p_cust_doc_id
            AND cust_acct_site_id = p_cust_acct_site_id;
      ELSE
         SELECT COUNT (*)
           INTO lc_contact_exit
           FROM xx_cdh_ebl_contacts
          WHERE org_contact_id = p_org_contact_id
            AND attribute1 = p_cust_account_id
            AND cust_doc_id = p_cust_doc_id;
      END IF;

      log_message ('Check Contact is present' || lc_contact_exit);

      IF lc_contact_exit = 0
      THEN
         SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
           INTO l_ebl_doc_contact_id
           FROM DUAL;

         INSERT INTO xx_cdh_ebl_contacts
                     (ebl_doc_contact_id, cust_doc_id, org_contact_id,
                      cust_acct_site_id, attribute1, creation_date,
                      created_by, last_update_date, last_updated_by,
                      last_update_login, request_id,
                      program_application_id, program_id, program_update_date
                     )
              VALUES (l_ebl_doc_contact_id,               -- ebl_doc_contact_id
                      p_cust_doc_id,                      -- cust_doc_id
                      p_org_contact_id,                   -- org_contact_id
                      p_cust_acct_site_id,                -- cust_acct_site_id
                      p_cust_account_id,                  -- attribute1
                      lc_curr_dt,                         -- creation_date
                      lc_user_id,                         -- created_by
                      lc_curr_dt,                         -- last_update_date
                      lc_user_id,                         -- last_updated_by
                      lc_last_update_login,               -- last_update_login
                      lc_conc_request_id,                 -- request_id
                      lc_conc_prog_appl_id,               -- program_application_id
                      lc_conc_program_id,                 -- program_id
                      lc_curr_dt                          -- program_update_date
                     );

         COMMIT;

            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments =
                      comments || CHR (13)
                      || ' Contact is added in document. ',
                   process_flag = 'S'
             WHERE ROWID = p_tmp_rowid;

     ELSE

                 UPDATE xxod_cdh_ebl_contacts_stg
               SET comments =
                      comments || CHR (13)
                      || ' Error in adding Contact in document. ',
                   process_flag = 'E'
             WHERE ROWID = p_tmp_rowid;


      END IF;
   END insert_billdoc_contact;

-- +========================================================================+
-- | Name        : create_billing_contact                                 |
-- | Description : To update/create the contact and contact points          |
-- +========================================================================+
   PROCEDURE create_billing_contact (
      p_cust_account_id            NUMBER,
      p_account_number             NUMBER,
      p_party_id                   NUMBER,
      p_cust_acct_site_id          NUMBER,
      p_contact_first_name         VARCHAR2,
      p_contact_last_name          VARCHAR2,
      p_email_address              VARCHAR2,
      p_phone_area_code            VARCHAR2,
      p_phone_number               VARCHAR2,
      p_tmp_rowid                  ROWID,
      p_org_contact_id       OUT   NUMBER,
      x_return_status        OUT   VARCHAR2
   )
   IS
      CURSOR lcu_contact_check (
         c_cust_account_id   hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE
      )
      IS
	     /*
         SELECT 'Y', rel.party_id
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                hz_contact_restrictions cont_res,
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
            AND party.party_id = cont_res.subject_id(+)
            AND cont_res.subject_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;
			*/
	SELECT 'Y', rel.party_id
           FROM hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;

        CURSOR lcu_contact_point_check (
         c_cust_account_id     hz_cust_accounts_all.cust_account_id%TYPE,
         c_contact_osr         hz_org_contacts.orig_system_reference%TYPE,
         c_contact_point_osr   hz_contact_points.orig_system_reference%TYPE
      )
      IS
         SELECT 'Y', cont_point.contact_point_id,
                cont_point.object_version_number
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                --hz_contact_restrictions cont_res, --Commented and added for defect# 28358
				hz_contact_preferences cont_pref,
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
            --AND party.party_id = cont_res.subject_id(+)  --Commented and added for defect# 28358 
            --AND cont_res.subject_table(+) = 'HZ_PARTIES'
			AND party.party_id = cont_pref.contact_level_table_id(+)
            AND cont_pref.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND cont_point.orig_system_reference = c_contact_point_osr
            AND role_acct.cust_account_id = c_cust_account_id;


      lc_contact_billing_check   CHAR (1);
      lc_contact_check           CHAR (1);
      lc_contact_point_check     CHAR (1);
      ln_owner_table_id          hz_contact_points.owner_table_id%TYPE := NULL;
      ln_object_version_number   hz_contact_points.object_version_number%TYPE;
      ln_contact_point_id        hz_contact_points.contact_point_id%TYPE
                                                                       := NULL;
      lc_cont_ret_status         VARCHAR (10);
      lc_email_ret_status        VARCHAR (10);
      lc_phone_ret_status        VARCHAR (10);
      lc_fax_ret_status          VARCHAR (10);
      lc_contact_osr             hz_org_contacts.orig_system_reference%TYPE;
      ln_org_contact_id          hz_org_contacts.org_contact_id%TYPE;
      ln_person_party_id         NUMBER;
   BEGIN
      lc_contact_billing_check := 'N';
      x_return_status := 'S';
      --log_message ('Checking if any billing contact exists');

      -- Checking if already billing contact exists
      log_message ('Creating new Contact');
      create_contact (p_contact_first_name,
                      p_contact_last_name,
                      p_party_id,
                      p_cust_account_id,
                      p_account_number,
                      p_cust_acct_site_id,
                      ln_person_party_id,
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

      p_org_contact_id := ln_org_contact_id;

      OPEN lcu_contact_check (p_cust_account_id, lc_contact_osr);

      FETCH lcu_contact_check
       INTO lc_contact_check, ln_owner_table_id;

      CLOSE lcu_contact_check;

      log_message ('ln_owner_table_id = ' || ln_owner_table_id);

      IF lc_cont_ret_status = 'S'
      THEN
         log_message ('Success - Create Contact');

         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments = comments || CHR (13) || ' Contact Created ' || ln_org_contact_id || '.'
          WHERE ROWID = p_tmp_rowid;

         IF p_email_address IS NOT NULL
         THEN
            log_message ('Creating email');
            create_email (ln_owner_table_id,
                          p_email_address,
                          p_account_number,
                          lc_email_ret_status
                         );

            IF lc_email_ret_status = 'S'
            THEN
               log_message ('Success - Create Email');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments = comments || CHR (13) || ' Email Created.'
                WHERE ROWID = p_tmp_rowid;
            ELSE
               log_message ('Error - Create Email');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                              comments || CHR (13)
                              || ' Error in Email Create.'
                WHERE ROWID = p_tmp_rowid;
            END IF;
         END IF;

         IF p_phone_number IS NOT NULL
         THEN
            log_message ('Creating Phone');
            create_phone (ln_owner_table_id,
                          p_account_number,
                          p_phone_area_code,
                          p_phone_number,
                          lc_phone_ret_status
                         );

            IF lc_phone_ret_status = 'S'
            THEN
               log_message ('Success - Create Phone');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments = comments || CHR (13) || ' Phone Created.'
                WHERE ROWID = p_tmp_rowid;
            ELSE
               log_message ('Error - Create Phone');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                              comments || CHR (13)
                              || ' Error in Phone Create.'
                WHERE ROWID = p_tmp_rowid;
            END IF;
         END IF;
      ELSE
         log_message ('Error - Create Contact');

         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments =
                      comments
                   || CHR (13)
                   || ' Error in Contact Create. New Contact OSR is not valid!'
          WHERE ROWID = p_tmp_rowid;
      END IF;
   END create_billing_contact;

----------------------------------------------Create Billing Contact End---------------------------------------------------------------------
----------------------------------------------Update Billing Contact Start---------------------------------------------------------------------
   PROCEDURE update_contact (
      p_cust_account_id            NUMBER,
      p_contact_osr                VARCHAR2,
      p_contact_first_name         VARCHAR2,
      p_contact_last_name          VARCHAR2,
      p_account_number             NUMBER,
      p_party_id                   NUMBER,
      x_org_contact_id       OUT   NUMBER,
      x_return_status        OUT   VARCHAR2
   )
   IS
      CURSOR lcu_contact_check (
         c_cust_account_id   hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE
      )
      IS
	     /*
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
                hz_contact_restrictions cont_res,
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
            AND party.party_id = cont_res.subject_id(+)
            AND cont_res.subject_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;
			*/
	SELECT party.party_id,
                party.object_version_number party_object_version_number,
                org_cont.org_contact_id,
                org_cont.object_version_number cont_object_version_number,
                rel.object_version_number rel_object_version_number
           FROM hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
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

      OPEN lcu_contact_check (p_cust_account_id, p_contact_osr);

      FETCH lcu_contact_check
       INTO ln_party_id, ln_party_object_version_number, ln_org_contact_id,
            ln_cont_object_version_number, ln_rel_object_version_number;

      CLOSE lcu_contact_check;

--      x_org_contact_id := ln_org_contact_id;
      log_message ('ln_party_id= ' || ln_party_id
                                   || 'ln_party_object_version_number= ' || ln_party_object_version_number
                                   || 'ln_org_contact_id= ' || ln_org_contact_id
                                   || 'ln_cont_object_version_number= ' || ln_cont_object_version_number
                                   ||  'ln_rel_object_version_number= ' || ln_rel_object_version_number
                  );

      IF p_contact_last_name IS NOT NULL OR p_contact_first_name IS NOT NULL
      THEN
         log_message ('Calling Update_Person API - Update last name, first name ln_party_id : ' || ln_party_id
                      || 'ln_party_object_version_number : ' || ln_party_object_version_number
                     );
         lr_person_rec.person_first_name := p_contact_first_name;
         lr_person_rec.person_last_name := p_contact_last_name;
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
            OR lc_create_person_return_status = fnd_api.g_ret_sts_unexp_error
         THEN
            log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Update Person API failed, API error message:  ' || lc_create_person_msg_data );
            log_message ('Error - Update Contact');
            x_return_status := 'E';
         ELSE
            log_message ('Success - Update Contact');
            x_return_status := 'S';
         END IF;
      END IF;

      IF x_return_status = 'S'
      THEN
         lr_org_contact_rec.org_contact_id := ln_org_contact_id;
         log_message ('Update Org cotact: object_id: ' || p_party_id);
         log_message ('Update Org cotact: Subject id: ' || ln_party_id);
         log_message ('Calling update_org_contact  ');
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
            log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Update Org Contact API failed, API error message:  ' || lc_org_contact_msg_data );
            x_return_status := 'E';
            log_message ('Error - Update Contact Org');
         ELSE
            x_return_status := 'S';
            log_message ('Success - Update Contact Org');
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
      p_contact_point_id         NUMBER,
      p_ojb_ver_number           NUMBER,
      p_email_address            VARCHAR2,
      p_account_number           NUMBER,
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

      --Contact Point primary Flag should always be Y
      lr_contact_point_rec_email.primary_flag := 'Y';
      lr_contact_point_rec_email.contact_point_purpose := 'BILLING';
      --  lr_contact_point_rec_email.created_by_module := 'XXCONV';
      lr_contact_point_rec_email.contact_point_id := p_contact_point_id;
      lr_email_rec.email_format := 'MAILHTML';
      lr_email_rec.email_address := p_email_address;
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
         log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Email, API error message: ' || lc_contact_point_msg_data );
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
      p_contact_point_id         NUMBER,
      p_ojb_ver_number           NUMBER,
      p_account_number           NUMBER,
      p_phone_area_code          VARCHAR2,
      p_phone_number             VARCHAR2,
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
      lr_contact_point_rec_phone.contact_point_purpose := 'BILLING';
      --Contact Point Primary Flag should always be Y
      lr_contact_point_rec_phone.primary_flag := 'Y';
      --  lr_contact_point_rec_phone.created_by_module := 'XXCONV';
      lr_contact_point_rec_phone.contact_point_id := p_contact_point_id;
      lr_phone_rec.phone_area_code := p_phone_area_code;
--      lr_phone_rec.phone_country_code := p_contact_int_rec.phone_country_code;
      lr_phone_rec.phone_number := p_phone_number;
      lr_phone_rec.phone_line_type := 'GEN';
--      lr_phone_rec.phone_extension := p_contact_int_rec.extension;
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
         log_message (   'FALSE_' || p_account_number || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Phone, API error message:  ' || lc_contact_point_msg_data );
         x_return_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error in Update Phone Program = ' || SQLERRM);
         x_return_status := 'E';
   END update_phone;

----------------------------------------------Update Billing Contact Start---------------------------------------------------------------------
   PROCEDURE update_billing_contact (
      p_contact_osr          IN       VARCHAR2,
      p_contact_first_name            VARCHAR2,
      p_contact_last_name             VARCHAR2,
      p_email_address                 VARCHAR2,
      p_phone_area_code               VARCHAR2,
      p_phone_number                  VARCHAR2,
      p_party_id                      NUMBER,
      p_cust_account_id               NUMBER,
      p_account_number                NUMBER,
      p_cust_acct_site_id             NUMBER,
      p_cust_doc_id          IN       NUMBER,
      p_tmp_rowid            IN       ROWID,
      x_return_status        OUT      VARCHAR2
   )
   IS
      lc_contact_billing_check   CHAR (1);
      lc_contact_check           CHAR (1);
      lc_contact_point_check     CHAR (1);
      ln_owner_table_id          hz_contact_points.owner_table_id%TYPE
                                                                      := NULL;
      ln_object_version_number   hz_contact_points.object_version_number%TYPE
                                                                      := NULL;
      ln_contact_point_id        hz_contact_points.contact_point_id%TYPE
                                                                      := NULL;
      lc_cont_ret_status         VARCHAR (10);
      lc_email_ret_status        VARCHAR (10);
      lc_phone_ret_status        VARCHAR (10);
      lc_fax_ret_status          VARCHAR (10);
      lc_contact_osr             hz_org_contacts.orig_system_reference%TYPE;
      lc_org_contact_id          hz_org_contacts.org_contact_id%TYPE;
      l_org_contact_id           NUMBER;
      l_sqlerrm                  VARCHAR2 (100);
      lc_contact_exit            NUMBER;
      lc_curr_dt                 DATE                              := SYSDATE;
      lc_org_id                  NUMBER       := fnd_profile.VALUE ('org_id');
      lc_user_id                 NUMBER                 := fnd_global.user_id;
      lc_last_update_login       NUMBER                := fnd_global.login_id;
      lc_conc_program_id         NUMBER         := fnd_global.conc_program_id;
      lc_conc_request_id         NUMBER         := fnd_global.conc_request_id;
      lc_conc_prog_appl_id       NUMBER            := fnd_global.prog_appl_id;
      lc_conc_login_id           NUMBER           := fnd_global.conc_login_id;
      l_ebl_doc_contact_id       NUMBER;
      l_create_email             VARCHAR2 (1);
      l_create_phone             VARCHAR2 (1);

      CURSOR lcu_contact_check (
         c_cust_account_id   hz_cust_account_roles.cust_acct_site_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE
      )
      IS
	SELECT 'Y', rel.party_id
           FROM hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND org_cont.orig_system_reference = c_contact_osr
            AND role_acct.cust_account_id = c_cust_account_id;

      CURSOR lcu_contact_point_check (
         c_cust_account_id   hz_cust_accounts_all.cust_account_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE,
         c_email_address     hz_contact_points.email_address%TYPE
      )
      IS
         SELECT 'Y', cont_point.contact_point_id,
                cont_point.object_version_number
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                --hz_contact_restrictions cont_res, --Commented and added for defect# 28358
				hz_contact_preferences cont_pref,
                hz_person_language per_lang
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND cont_point.owner_table_id(+) = rel_party.party_id
            AND cont_point.contact_point_type = 'EMAIL'
            AND cont_point.primary_flag(+) = 'Y'
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND party.party_id = per_lang.party_id(+)
            AND per_lang.native_language(+) = 'Y'
            --AND party.party_id = cont_res.subject_id(+)  --Commented and added for defect# 28358
            --AND cont_res.subject_table(+) = 'HZ_PARTIES'
			AND party.party_id = cont_pref.contact_level_table_id(+)
            AND cont_pref.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND org_cont.orig_system_reference = c_contact_osr
            AND UPPER (cont_point.email_address) = UPPER (c_email_address)
            AND role_acct.cust_account_id = c_cust_account_id;

      CURSOR lcu_contact_point_check_phone (
         c_cust_account_id   hz_cust_accounts_all.cust_account_id%TYPE,
         c_contact_osr       hz_org_contacts.orig_system_reference%TYPE,
         c_phone_area_code   hz_contact_points.phone_area_code%TYPE,
         c_phone_number      hz_contact_points.phone_number%TYPE
      )
      IS
         SELECT 'Y', cont_point.contact_point_id,
                cont_point.object_version_number
           FROM hz_contact_points cont_point,
                hz_cust_account_roles acct_role,
                hz_parties party,
                hz_parties rel_party,
                hz_relationships rel,
                hz_org_contacts org_cont,
                hz_cust_accounts role_acct,
                --hz_contact_restrictions cont_res, --Commented and added for defect# 28358
				hz_contact_preferences cont_pref,
                hz_person_language per_lang
          WHERE acct_role.party_id = rel.party_id
            AND acct_role.role_type = 'CONTACT'
            AND org_cont.party_relationship_id = rel.relationship_id
            AND rel.subject_id = party.party_id
            AND rel_party.party_id = rel.party_id
            AND cont_point.owner_table_id(+) = rel_party.party_id
            AND cont_point.contact_point_type = 'PHONE'
			AND cont_point.phone_line_type = 'GEN'
            AND cont_point.primary_flag(+) = 'Y'
            AND acct_role.cust_account_id = role_acct.cust_account_id
            AND role_acct.party_id = rel.object_id
            AND party.party_id = per_lang.party_id(+)
            AND per_lang.native_language(+) = 'Y'
            --AND party.party_id = cont_res.subject_id(+) --Commented and added for defect# 28358
            --AND cont_res.subject_table(+) = 'HZ_PARTIES'
			AND party.party_id = cont_pref.contact_level_table_id(+)
            AND cont_pref.contact_level_table(+) = 'HZ_PARTIES'
            AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
            AND role_acct.cust_account_id = c_cust_account_id
            AND org_cont.orig_system_reference = c_contact_osr
            AND cont_point.phone_area_code = c_phone_area_code
            AND cont_point.phone_number = c_phone_number;
   BEGIN
      lc_contact_billing_check := 'N';
      x_return_status := 'S';
      lc_contact_check := 'N';
      log_message ('Checking if Contact exists');
      log_message ('p_cust_account_id ' || p_cust_account_id);
      log_message ('p_contact_osr ' || p_contact_osr);

      OPEN lcu_contact_check (p_cust_account_id, p_contact_osr);

      FETCH lcu_contact_check
       INTO lc_contact_check, ln_owner_table_id;

      CLOSE lcu_contact_check;

      IF lc_contact_check = 'Y'
      THEN
         log_message ('Contact OSR exists');

         BEGIN
            SELECT MAX (org_cont.org_contact_id)
              INTO lc_org_contact_id
              FROM hz_relationships hr,
                   hz_cust_accounts hca,
                   hz_parties hp,
                   hz_org_contacts org_cont
             WHERE hca.party_id = hr.object_id
               AND hr.relationship_code = 'CONTACT_OF'
               AND hr.status = 'A'
               AND hr.subject_id = hp.party_id
               AND hp.status = 'A'
               AND hp.party_type = 'PERSON'
               AND hr.relationship_id = org_cont.party_relationship_id
               AND UPPER (NVL (hp.person_first_name, '99999')) =
                                   UPPER (NVL (p_contact_first_name, '99999'))
               AND UPPER (NVL (hp.person_last_name, '99999')) =
                                    UPPER (NVL (p_contact_last_name, '99999'))
               AND hca.cust_account_id = p_cust_account_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_org_contact_id := NULL;
         END;

         lc_cont_ret_status := 'S';

         IF lc_org_contact_id IS NULL
         THEN
            update_contact (p_cust_account_id,
                            p_contact_osr,
                            p_contact_first_name,
                            p_contact_last_name,
                            p_account_number,
                            p_party_id,
                            lc_org_contact_id,
                            lc_cont_ret_status
                           );
         ELSE
            log_message ('Contact is already Present');

--            UPDATE xxod_cdh_ebl_contacts_stg
--               SET comments =
--                         comments || CHR (13)
--                         || ' Contact is already present.'
--             WHERE ROWID = p_tmp_rowid;
         END IF;

--         x_org_contact_id := lc_org_contact_id;
         IF lc_cont_ret_status = 'S'
         THEN
            log_message ('Success - Update Contact');

            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments = comments || CHR (13) || ' Contact is updated or already present.'
             WHERE ROWID = p_tmp_rowid;
         ELSE
            log_message ('Error - Update Contact');

            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments =
                            comments || CHR (13)
                            || ' Error in Contact update.'
             WHERE ROWID = p_tmp_rowid;
         END IF;

         l_create_email := 'N';

         IF p_email_address IS NOT NULL
         THEN
            lc_contact_point_check := 'N';

            OPEN lcu_contact_point_check (p_cust_account_id,
                                          p_contact_osr,
                                          p_email_address
                                         );

            FETCH lcu_contact_point_check
             INTO lc_contact_point_check, ln_contact_point_id,
                  ln_object_version_number;

            CLOSE lcu_contact_point_check;

            IF lc_contact_point_check = 'Y'
            THEN
               log_message ('Email OSR - Exists');
               log_message ('Updating email');
               update_email (ln_contact_point_id,
                             ln_object_version_number,
                             p_email_address,
                             p_account_number,
                             lc_email_ret_status
                            );

               IF lc_email_ret_status = 'S'
               THEN
                  log_message ('Success - Update Email');

                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET comments =
                               comments
                            || CHR (13)
                            || ' Email is updated or already exist.'
                   WHERE ROWID = p_tmp_rowid;
               ELSE
                  log_message ('Error - Update Email');

                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET comments =
                             comments || CHR (13)
                             || ' Error in email updated.'
                   WHERE ROWID = p_tmp_rowid;
               END IF;
            ELSE
               log_message ('Create New Email');
               l_create_email := 'Y';
            END IF;
         END IF;

         IF l_create_email = 'Y'
         THEN
            log_message ('Creating email');
            create_email (ln_owner_table_id,
                          p_email_address,
                          p_account_number,
                          lc_email_ret_status
                         );

            IF lc_email_ret_status = 'S'
            THEN
               log_message ('Success - Create Email');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                               comments || CHR (13)
                               || ' New Email is created.'
                WHERE ROWID = p_tmp_rowid;
            ELSE
               log_message ('Error - Create Email');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                                comments || CHR (13)
                                || ' New Email is Failed.'
                WHERE ROWID = p_tmp_rowid;
            END IF;
         END IF;

         l_create_phone := 'N';

         IF p_phone_number IS NOT NULL
         THEN
            lc_contact_point_check := 'N';
            log_message ('Phone Number= ' || p_phone_number);
            log_message (' p_cust_account_id ' || p_cust_account_id);
            log_message (' p_contact_osr ' || p_contact_osr);
            log_message (' p_phone_area_code ' || p_phone_area_code);
            log_message (' p_phone_number ' || p_phone_number);

            OPEN lcu_contact_point_check_phone (p_cust_account_id,
                                                p_contact_osr,
                                                p_phone_area_code,
                                                p_phone_number
                                               );

            FETCH lcu_contact_point_check_phone
             INTO lc_contact_point_check, ln_contact_point_id,
                  ln_object_version_number;

            CLOSE lcu_contact_point_check_phone;

            IF lc_contact_point_check = 'Y'
            THEN
               log_message ('Phone OSR - Exists');
               log_message ('Updating Phone');
               update_phone (ln_contact_point_id,
                             ln_object_version_number,
                             p_account_number,
                             p_phone_area_code,
                             p_phone_number,
                             lc_phone_ret_status
                            );

               IF lc_phone_ret_status = 'S'
               THEN
                  log_message ('Success - Update Phone');

                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET comments =
                               comments
                            || CHR (13)
                            || ' Phone is updated or already exist.'
                   WHERE ROWID = p_tmp_rowid;
               ELSE
                  log_message ('Error - Update Phone');

                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET comments =
                              comments || CHR (13)
                              || ' Error in Phone Update.'
                   WHERE ROWID = p_tmp_rowid;
               END IF;
            ELSE
               log_message ('Invalid - Phone OSR');
               l_create_phone := 'Y';
            END IF;
         END IF;

         IF l_create_phone = 'Y'
         THEN
            log_message ('Creating Phone');
            create_phone (ln_owner_table_id,
                          p_account_number,
                          p_phone_area_code,
                          p_phone_number,
                          lc_phone_ret_status
                         );

            IF lc_phone_ret_status = 'S'
            THEN
               log_message ('Success - Create Phone');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                               comments || CHR (13)
                               || ' New Phone is created.'
                WHERE ROWID = p_tmp_rowid;
            ELSE
               log_message ('Error - Create Phone');

               UPDATE xxod_cdh_ebl_contacts_stg
                  SET comments =
                          comments || CHR (13)
                          || ' Error in new Phone create.'
                WHERE ROWID = p_tmp_rowid;
            END IF;
         END IF;
      ELSE
         log_message ('Invalid - Contact OSR');

         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments = comments || CHR (13) || ' Invalid Contact OSR.'
          WHERE ROWID = p_tmp_rowid;

         x_return_status := 'E';
      END IF;                                         --lc_contact_check = 'Y'

      SELECT org_contact_id
        INTO l_org_contact_id
        FROM hz_org_contacts org_cont
       WHERE orig_system_reference = p_contact_osr AND status = 'A';

      log_message (' ORG Contact Id ' || l_org_contact_id || ' is found. ');

      IF p_cust_acct_site_id IS NOT NULL
      THEN
         SELECT COUNT (*)
           INTO lc_contact_exit
           FROM xx_cdh_ebl_contacts
          WHERE org_contact_id = l_org_contact_id
            AND attribute1 = p_cust_account_id
            AND cust_doc_id = p_cust_doc_id
            AND cust_acct_site_id = p_cust_acct_site_id;
      ELSE
         SELECT COUNT (*)
           INTO lc_contact_exit
           FROM xx_cdh_ebl_contacts
          WHERE org_contact_id = l_org_contact_id
            AND attribute1 = p_cust_account_id
            AND cust_doc_id = p_cust_doc_id
            AND cust_acct_site_id IS NULL;
      END IF;

      IF lc_contact_exit = 0
      THEN
         SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
           INTO l_ebl_doc_contact_id
           FROM DUAL;

         INSERT INTO xx_cdh_ebl_contacts
                     (ebl_doc_contact_id, cust_doc_id, org_contact_id,
                      cust_acct_site_id, attribute1, creation_date,
                      created_by, last_update_date, last_updated_by,
                      last_update_login, request_id,
                      program_application_id, program_id, program_update_date
                     )
              VALUES (l_ebl_doc_contact_id,                 -- ebl_doc_contact_id
                      p_cust_doc_id,                        -- cust_doc_id
                      l_org_contact_id,                     -- org_contact_id
                      p_cust_acct_site_id,                  -- cust_acct_site_id
                      p_cust_account_id,                    -- attribute1
                      lc_curr_dt,                           -- creation_date
                      lc_user_id,                           -- created_by
                      lc_curr_dt,                           -- last_update_date
                      lc_user_id,                           -- last_updated_by
                      lc_last_update_login,                 -- last_update_login
                      lc_conc_request_id,                   -- request_id
                      lc_conc_prog_appl_id,                 -- program_application_id
                      lc_conc_program_id,                   -- program_id
                      lc_curr_dt                            -- program_update_date
                     );

--                    COMMIT;
         IF SQL%ROWCOUNT > 0
         THEN
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments =
                      comments || CHR (13)
                      || ' Contact is added in document. ',
                   process_flag = 'S'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Insert Successful ');
         ELSE
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments =
                         comments
                      || CHR (13)
                      || ' Error in Contact add in document ',
                   process_flag = 'E'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Insert Unsuccessful ');
         END IF;
      ELSE
         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments =
                      comments
                   || CHR (13)
                   || ' Contact is already present in document. ',
                process_flag = 'S'
          WHERE ROWID = p_tmp_rowid;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_sqlerrm := SUBSTR (SQLERRM, 1, 100);

         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments =
                         comments || CHR (13) || ' Update Billing Contact is Failed -'
                         || l_sqlerrm||'.',
                process_flag = 'E'
          WHERE ROWID = p_tmp_rowid;
   END update_billing_contact;

----------------------------------------------Update Billing Contact End---------------------------------------------------------------------

   ----------------------------------------------Delete Billing Contact Start---------------------------------------------------------------------
   PROCEDURE delete_billing_contact (
      p_contact_osr         IN       VARCHAR2,
      p_cust_account_id     IN       NUMBER,
      p_cust_doc_id         IN       NUMBER,
      p_cust_acct_site_id   IN       NUMBER,
      p_tmp_rowid           IN       ROWID,
      x_return_status       OUT      VARCHAR2
   )
   IS
      l_org_contact_id   NUMBER;
      l_sqlerrm          VARCHAR2 (100);
   BEGIN
      SELECT org_contact_id
        INTO l_org_contact_id
        FROM hz_org_contacts org_cont
       WHERE orig_system_reference = p_contact_osr AND status = 'A';

      UPDATE xxod_cdh_ebl_contacts_stg
         SET comments = comments || CHR (13) || ' ORG Contact Id ' || l_org_contact_id || ' is found. '
       WHERE ROWID = p_tmp_rowid;

      log_message (' ORG Contact Id ' || l_org_contact_id || ' is found ');

      IF p_cust_acct_site_id IS NOT NULL
      THEN
         DELETE FROM xx_cdh_ebl_contacts
               WHERE org_contact_id = l_org_contact_id
                 AND attribute1 = p_cust_account_id
                 AND cust_doc_id = p_cust_doc_id
                 AND cust_acct_site_id = p_cust_acct_site_id;

         IF SQL%ROWCOUNT > 0
         THEN
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments = comments || CHR (13) || 'Delete Successful. ',
                   process_flag = 'S'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Delete Successful ');
         ELSE
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments = comments || CHR (13) || 'Delete Unsuccessful. ',
                   process_flag = 'E'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Delete Unsuccessful ');
         END IF;
      ELSE
         DELETE FROM xx_cdh_ebl_contacts
               WHERE org_contact_id = l_org_contact_id
                 AND attribute1 = p_cust_account_id
                 AND cust_doc_id = p_cust_doc_id;

         IF SQL%ROWCOUNT > 0
         THEN
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments = comments || CHR (13) || 'Delete Successful. ',
                   process_flag = 'S'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Delete Successful ');
         ELSE
            UPDATE xxod_cdh_ebl_contacts_stg
               SET comments = comments || CHR (13) || 'Delete Unsuccessful. ',
                   process_flag = 'E'
             WHERE ROWID = p_tmp_rowid;

            log_message ('Delete Unsuccessful ');
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_sqlerrm := SUBSTR (SQLERRM, 1, 100);

         UPDATE xxod_cdh_ebl_contacts_stg
            SET comments =
                         comments || CHR (13) || ' Record Failed '
                         || l_sqlerrm||'.',
                process_flag = 'E'
          WHERE ROWID = p_tmp_rowid;
   END delete_billing_contact;

----------------------------------------------Delete Billing Contact End---------------------------------------------------------------------
   PROCEDURE xx_cdh_billing_contact_main (
      x_errbuf       OUT NOCOPY      VARCHAR2,
      x_retcode      OUT NOCOPY      VARCHAR2,
      p_debug_flag   IN              VARCHAR2,
      p_batch_id     IN              NUMBER
   )
   IS
      l_cust_account_id          hz_cust_accounts.cust_account_id%TYPE;
      l_account_number           hz_cust_accounts.account_number%TYPE;
      lc_org_contact_id          hz_org_contacts.org_contact_id%TYPE;
      l_cust_acct_site_id        NUMBER;
      l_party_id                 NUMBER;
      l_org_id                   NUMBER;
      lc_contact_return_status   VARCHAR2 (1);
      lc_comments                VARCHAR2 (4000);
      lc_bill_doc_cnt            NUMBER;
      l_exception                VARCHAR2 (100);

      CURSOR lcu_cust_details
      IS
         SELECT   ebl_cont.ROWID tmp_rowid, ebl_cont.aops_account_number,
                  ebl_cont.aops_address_seq, ebl_cont.contact_first_name,
                  ebl_cont.contact_last_name, ebl_cont.contact_osr,
                  ebl_cont.contact_status, ebl_cont.email_address,
                  ebl_cont.phone_area_code, ebl_cont.phone_number,
                  ebl_cont.cust_doc_id
             FROM xxod_cdh_ebl_contacts_stg ebl_cont
            WHERE NVL (process_flag, 'N') IN ('N', 'E')
              AND batch_id = p_batch_id
         ORDER BY cust_doc_id;
   BEGIN

      log_message ('Starting Main Program');

      -- Open the cursor lcu_cust_details
      FOR cust_in IN lcu_cust_details
      LOOP
         BEGIN
            log_message
                ('................ Contact creation is start .............. ');
            log_message (   ' Aops Account Number = '  || cust_in.aops_account_number
                                      || ' Site Sequence Number = ' || cust_in.aops_address_seq
                                                 || ' Contact Original System Reference  = '
                         || cust_in.contact_osr || 'OSR  ' || LPAD (cust_in.aops_account_number, 8, '0') || '-' || LPAD (cust_in.aops_address_seq, 5, '0') || '-' || 'A0' );

            BEGIN
               IF TRIM (cust_in.aops_address_seq) IS NOT NULL
               THEN
                  SELECT hcas.cust_acct_site_id, hcas.cust_account_id,
                         hca.account_number, hca.party_id, hcas.org_id
                    INTO l_cust_acct_site_id, l_cust_account_id,
                         l_account_number, l_party_id, l_org_id
                    FROM hz_cust_acct_sites_all hcas, hz_cust_accounts hca
                   WHERE hcas.orig_system_reference =
                               LPAD (cust_in.aops_account_number, 8, '0')
                            || '-'
                            || LPAD (cust_in.aops_address_seq, 5, '0')
                            || '-'
                            || 'A0'
                     AND hcas.cust_account_id = hca.cust_account_id
                     AND hca.status = 'A'
                     AND hcas.status = 'A';
               ELSIF TRIM (cust_in.aops_address_seq) IS NULL
               THEN
                  SELECT hca.cust_account_id, hca.account_number,
                         hca.party_id
                    INTO l_cust_account_id, l_account_number,
                         l_party_id
                    FROM hz_cust_accounts hca
                   WHERE hca.orig_system_reference = LPAD (cust_in.aops_account_number, 8, '0') || '-00001-A0'
                     AND hca.status = 'A';

                  l_cust_acct_site_id := NULL;
                  l_org_id := NULL;
               ELSE
                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET process_flag = 'E',
                         comments = ' AOPS account number is invalid. '
                   WHERE ROWID = cust_in.tmp_rowid;

                  GOTO last_statement_main;
               END IF;

               lc_comments := lc_comments || ' Account is present ';

               -- Setting process flag as E
               UPDATE xxod_cdh_ebl_contacts_stg
                  SET process_flag = 'E',
                      comments = ' AOPS account number is present. '
                WHERE ROWID = cust_in.tmp_rowid;

               log_message (' Aops Account Number = ' || l_account_number
                                   ||' Cust Account Id = ' || l_cust_account_id
                                   ||' Cust Acct Site Id  = ' || l_cust_acct_site_id
                                   ||' Party Id = ' || l_party_id
                                   ||' Contact First Name = '|| cust_in.contact_first_name
                                   ||' Contact Last Name  = '|| cust_in.contact_last_name
                                   ||' Email Address = ' || cust_in.email_address
                                   ||' Area Code = ' || cust_in.phone_area_code
                                   ||' Phone Number  = ' || cust_in.phone_number
                                   ||' Contact OSR = ' || cust_in.contact_osr
                                   ||' Doc Id = ' || cust_in.cust_doc_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_comments := lc_comments || ' AOPS account number is invalid.  ';

                  UPDATE xxod_cdh_ebl_contacts_stg
                     SET process_flag = 'E',
                         comments = lc_comments
                   WHERE ROWID = cust_in.tmp_rowid;

                  GOTO last_statement_main;
            END;

            IF cust_in.contact_osr IS NULL AND cust_in.contact_status = 'A'
            THEN
               BEGIN
                  SELECT MAX (org_cont.org_contact_id)
                    INTO lc_org_contact_id
                    FROM hz_relationships hr,
                         hz_cust_accounts hca,
                         hz_parties hp,
                         hz_org_contacts org_cont
                   WHERE hca.party_id = hr.object_id
                     AND hr.relationship_code = 'CONTACT_OF'
                     AND hr.status = 'A'
                     AND hr.subject_id = hp.party_id
                     AND hp.status = 'A'
                     AND hp.party_type = 'PERSON'
                     AND hr.relationship_id = org_cont.party_relationship_id
                     AND UPPER (NVL (hp.person_first_name, '99999')) =
                             UPPER (NVL (cust_in.contact_first_name, '99999'))
                     AND UPPER (NVL (hp.person_last_name, '99999')) =
                              UPPER (NVL (cust_in.contact_last_name, '99999'))
                     AND hca.cust_account_id = l_cust_account_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_org_contact_id := NULL;
               END;

               IF lc_org_contact_id IS NULL
               THEN
                  create_billing_contact (l_cust_account_id,
                                          l_account_number,
                                          l_party_id,
                                          l_cust_acct_site_id,
                                          cust_in.contact_first_name,
                                          cust_in.contact_last_name,
                                          cust_in.email_address,
                                          cust_in.phone_area_code,
                                          cust_in.phone_number,
                                          cust_in.tmp_rowid,
                                          lc_org_contact_id,
                                          lc_contact_return_status
                                         );
               END IF;

               IF lc_org_contact_id IS NOT NULL
               THEN
                  insert_billdoc_contact (lc_org_contact_id,
                                          l_cust_account_id,
                                          l_cust_acct_site_id,
                                          cust_in.cust_doc_id,
                                          cust_in.tmp_rowid,
                                          lc_contact_return_status
                                         );
               END IF;
            END IF;

            IF cust_in.contact_osr IS NOT NULL
               AND cust_in.contact_status = 'A'
            THEN
               update_billing_contact (cust_in.contact_osr,
                                       cust_in.contact_first_name,
                                       cust_in.contact_last_name,
                                       cust_in.email_address,
                                       cust_in.phone_area_code,
                                       cust_in.phone_number,
                                       l_party_id,
                                       l_cust_account_id,
                                       l_account_number,
                                       l_cust_acct_site_id,
                                       cust_in.cust_doc_id,
                                       cust_in.tmp_rowid,
                                       lc_contact_return_status
                                      );
            END IF;

            IF cust_in.contact_osr IS NOT NULL
               AND cust_in.contact_status = 'I'
            THEN
               delete_billing_contact (cust_in.contact_osr,
                                       l_cust_account_id,
                                       cust_in.cust_doc_id,
                                       l_cust_acct_site_id,
                                       cust_in.tmp_rowid,
                                       lc_contact_return_status
                                      );
            END IF;
         END;

         <<last_statement_main>>
         NULL;
      END LOOP;
   -- Close the cursor lcu_cust_details

   --COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message (SQLERRM);
   END xx_cdh_billing_contact_main;

   PROCEDURE load_ebl_contact_int (
      p_errbuf      OUT      VARCHAR2,
      p_retcode     OUT      NUMBER,
      p_file_upload_id   IN  NUMBER
   )
   IS
      -- Variable declaration
      v_file                   UTL_FILE.file_type;
      lc_message               VARCHAR2 (32767);
      ln_total_records         NUMBER             := 0;
      lc_sqlerrm               VARCHAR2 (1000);
      lc_error_debug           VARCHAR2 (1000);
      lc_contact_last_name     VARCHAR2 (100);
      lc_contact_first_name    VARCHAR2 (100);
      lc_email_address         VARCHAR2 (100);
      lc_phone_area_code       VARCHAR2 (100);
      lc_phone_number          VARCHAR2 (100);
      lc_aops_account_number   VARCHAR2 (100);
      lc_aops_address_seq      VARCHAR2 (100);
      lc_contact_osr           VARCHAR2 (100);
      lc_contact_status        VARCHAR2 (100);
      lc_cust_doc_id           VARCHAR2 (100);
      ln_line                  NUMBER             := 0;
      v_record_number          NUMBER             := 1;

      CURSOR cur_filercords
      IS
        SELECT     TRIM ('"' from SUBSTR (LIST,
                                    INSTR (LIST, ',', 1, LEVEL) + 1,
                                    INSTR (LIST, ',', 1, LEVEL + 1)
                                  - INSTR (LIST, ',', 1, LEVEL)
                                  - 1
                                 )
                        ) AS list_member
                  FROM (
                        SELECT REPLACE(LIST1,chr(13),',') LIST , file_data1 file_data
                           FROM
                               (
                                SELECT ',' || file_data || ',' LIST1, file_data  file_data1
                                      FROM XXCRM_EBL_CONT_UPLOADS WHERE file_upload_id = p_file_upload_id
                               )
                       )
         CONNECT BY LEVEL <=
                         LENGTH (LIST)
                       - LENGTH (REPLACE (LIST, ',', ''))
                       + 1;
   BEGIN
      lc_error_debug := 'Start of Inserting file data into staging table'|| TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');

                FOR i IN cur_filercords
                  LOOP
                      log_message (   i.list_member ||' -- '||v_record_number);
                     IF v_record_number = 1
                     THEN
                        lc_contact_last_name := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 2
                     THEN
                        lc_contact_first_name := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 3
                     THEN
                        lc_email_address := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 4
                     THEN
                        lc_phone_area_code := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 5
                     THEN
                        lc_phone_number := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 6
                     THEN
                        lc_aops_account_number := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 7
                     THEN
                        lc_aops_address_seq := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 8
                     THEN
                        lc_contact_osr := TRIM(i.list_member); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 9
                     THEN
                        lc_contact_status := UPPER (TRIM(i.list_member)); /* added trim for the defect 20757*/
                     ELSIF v_record_number = 10
                     THEN
                        lc_cust_doc_id := TRIM(i.list_member); /* added trim for the defect 20757*/
                        v_record_number := 0;
                        lc_cust_doc_id := TRIM (REPLACE (lc_cust_doc_id, CHR (13), ''));
                        log_message ('lc_contact_last_name - '|| lc_contact_last_name);
                        log_message ('lc_contact_first_name - '|| lc_contact_first_name);
                        log_message ('lc_email_address - ' || lc_email_address);
                        log_message ('lc_phone_area_code - ' || lc_phone_area_code);
                        log_message ('lc_phone_number - ' || lc_phone_number);
                        log_message ('lc_aops_account_number - '|| lc_aops_account_number);
                        log_message ('lc_aops_address_seq - ' || lc_aops_address_seq);
                        log_message ('lc_contact_osr - ' || lc_contact_osr);
                        log_message ('lc_contact_status - ' || lc_contact_status);
                        log_message ('lc_cust_doc_id - ' || lc_cust_doc_id);

                      IF ln_line <> 0 THEN

                        INSERT INTO xxod_cdh_ebl_contacts_stg
                              (batch_id, contact_last_name,
                               contact_first_name, email_address,
                               phone_area_code, phone_number,
                               aops_account_number, aops_address_seq,
                               contact_osr, contact_status,
                               cust_doc_id
                              )
                        VALUES (p_file_upload_id, lc_contact_last_name,
                               lc_contact_first_name, lc_email_address,
                               lc_phone_area_code, lc_phone_number,
                               lc_aops_account_number, lc_aops_address_seq,
                               lc_contact_osr, lc_contact_status,
                               lc_cust_doc_id
                              );

                       ELSE
                         ln_line := 1;
                       END IF;
                               COMMIT;

                                IF SQL%ROWCOUNT > 0
                                THEN
                                   ln_total_records := ln_total_records + 1;
                                END IF;

                               COMMIT;


                     END IF;

                     v_record_number := v_record_number + 1;
                     log_message (v_record_number);

                  END LOOP;




      lc_error_debug := 'Loop ended here';
      log_message (lc_error_debug);
      lc_error_debug := 'End of Inserting file data into staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      log_message (lc_error_debug);


   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_debug := SQLCODE || '-' || SQLERRM;
         log_message ('Exception when others--' || lc_error_debug);
         p_retcode := 2;
	       rollback;
   END load_ebl_contact_int;


   PROCEDURE upload (
      p_errbuf           OUT NOCOPY      VARCHAR2,
      p_retcode          OUT NOCOPY      VARCHAR2,
      p_request_set_id   OUT NOCOPY      NUMBER,
      p_file_upload_id   IN              NUMBER
   )
   IS
      errbuf                     VARCHAR2 (2000)                  := p_errbuf;
      retcode                    VARCHAR2 (1)                    := p_retcode;
      lc_message                 VARCHAR2 (100);
      lb_success                 BOOLEAN;
      req_id                     NUMBER;
      req_data                   VARCHAR2 (10);
      l_request_set_name         VARCHAR2 (30);
      srs_failed                 EXCEPTION;
      submitprog_failed          EXCEPTION;
      submitset_failed           EXCEPTION;
      le_submit_failed           EXCEPTION;
      request_desc               VARCHAR2 (240);
      /* Description for submit_request  */
      x_user_id                  fnd_user.user_id%TYPE;
      x_resp_id                  fnd_responsibility.responsibility_id%TYPE;
      x_resp_appl_id             fnd_responsibility.application_id%TYPE;
      b_complete                 BOOLEAN                              := TRUE;
      l_count                    NUMBER;
      l_request_id               NUMBER;
      ln_batch_id                NUMBER;
      lv_return_status           VARCHAR2 (1);
      ln_msg_count               NUMBER;
      lv_msg_data                VARCHAR2 (2000);
      l_osr                      VARCHAR2 (240);
      l_user_id                  NUMBER;
      l_responsibility_id        NUMBER;
      l_responsibility_appl_id   NUMBER;
      l_apps_org_id              NUMBER;
      l_responsibility_key       VARCHAR2 (120);
      l_app_dev_view_resp_id     NUMBER;
      l_prof_val                 VARCHAR2 (30);
      l_prof_upd_status          BOOLEAN;
      v_user_id                  NUMBER;
      v_resp_id                  NUMBER;
      v_app_id                   NUMBER;
   BEGIN


-----------------------------------------------------------------------------
-- Insert into Int table - Start
-----------------------------------------------------------------------------
      load_ebl_contact_int (p_errbuf         => lv_msg_data,
                            p_retcode        => lv_return_status,
                            p_file_upload_id      => p_file_upload_id
                           );

      IF lv_return_status <> fnd_api.g_ret_sts_success
      THEN
         log_message ('Error while Insert into Int Table - ' || lv_msg_data);
         GOTO goto_last_line;
      ELSE
         log_message ('Insert into Int Table - Successful ');
      END IF;

      lc_message := 'Insert into Int table - End ';
      log_message (lc_message);
----------------------------------------------------------
--Insert into Int table - End
----------------------------------------------------------


      -----------------------------------------------------------------------------
--  Create Billing Contact - Start
-----------------------------------------------------------------------------
      log_message ('Start of xx_cdh_billing_contact_main  - Start');
      xx_cdh_billing_contact_main (x_errbuf          => lv_msg_data,
                                   x_retcode         => lv_return_status,
                                   p_debug_flag      => 'Y',
                                   p_batch_id        => p_file_upload_id
                                  );
      log_message
         ('Start of XX_CDH_BILLING_CONTACT_PKG.xx_cdh_billing_contact_main  -  End'
         );

      IF lv_return_status <> fnd_api.g_ret_sts_success
      THEN
         log_message ('Error while Create Billing Contact  - ' || lv_msg_data);
         GOTO goto_last_line;
      ELSE
         log_message ('Create Billing Contact  - Successful ');
      END IF;

      lc_message := 'Create Billing Contact  - End ';
      log_message (lc_message);
      req_id := p_file_upload_id;
-----------------------------------------------------------------------------
--  Create Billing Contact - End
-----------------------------------------------------------------------------
      COMMIT;
      log_message ('2 req_id:' || p_file_upload_id);
      log_message ('Finished.');
      errbuf := SUBSTR (fnd_message.get, 1, 240);
      retcode := 0;
      log_message ('errbuf: ' || errbuf);
      p_errbuf := errbuf;
      retcode := 0;
      p_retcode := retcode;

      p_request_set_id := req_id;
      <<goto_last_line>>
      ROLLBACK;
   EXCEPTION
      WHEN srs_failed
      THEN
         errbuf := 'Call to update billing contact failed: ' || fnd_message.get;
         retcode := 2;
         log_message (errbuf);
      WHEN submitprog_failed
      THEN
         errbuf := 'Call to update billing contact failed: ' || fnd_message.get;
         retcode := 2;
         log_message (errbuf);
      WHEN submitset_failed
      THEN
         errbuf := 'Call to update billing contact failed: ' || fnd_message.get;
         retcode := 2;
         log_message (errbuf);
      WHEN OTHERS
      THEN
         errbuf :=
                 'Call to update billing contact - unknown error: ' || SQLERRM;
         retcode := 2;
         log_message (errbuf);
   END upload;
END xxod_cdh_upload_eblcontacts;
/

SHOW ERRORS;


