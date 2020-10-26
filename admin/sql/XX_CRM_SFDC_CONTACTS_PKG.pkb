create or replace PACKAGE BODY xx_crm_sfdc_contacts_pkg
AS
-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CRM_SFDC_CONTACTS_PKG.pkb                              |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | Table hanfler for xx_crm_sfdc_contacts.                                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       22-AUG-2011  Phil Price         Initial version                 |
-- |2.0       30-OCT-2014  Sridevi K          Modified for Defect32267        |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- |1.2       19-Oct-2020  Divyansh Saini     Added procedure for email update|
-- +==========================================================================+

   --
--  "who" info
--
   anonymous_apps_user   CONSTANT NUMBER := -1;

-------------------------------------------------------------------------------
   FUNCTION dti
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      RETURN (TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss') || ': ');
   END dti;

-- ============================================================================

   -------------------------------------------------------------------------------
   FUNCTION getval (p_val IN VARCHAR2)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (p_val IS NULL)
      THEN
         RETURN '<null>';
      ELSIF (p_val = fnd_api.g_miss_char)
      THEN
         RETURN '<missing>';
      ELSE
         RETURN p_val;
      END IF;
   END getval;

-- ===========================================================================

   -------------------------------------------------------------------------------
   FUNCTION getval (p_val IN NUMBER)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (p_val IS NULL)
      THEN
         RETURN '<null>';
      ELSIF (p_val = fnd_api.g_miss_num)
      THEN
         RETURN '<missing>';
      ELSE
         RETURN TO_CHAR (p_val);
      END IF;
   END getval;

-- ===========================================================================

   -------------------------------------------------------------------------------
   FUNCTION getval (p_val IN DATE)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (p_val IS NULL)
      THEN
         RETURN '<null>';
      ELSIF (p_val = fnd_api.g_miss_date)
      THEN
         RETURN '<missing>';
      ELSE
         RETURN TO_CHAR (p_val, 'DD-MON-YYYY HH24:MI:SS');
      END IF;
   END getval;

-- ===========================================================================

   -------------------------------------------------------------------------------
   FUNCTION getval (p_val IN BOOLEAN)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (p_val IS NULL)
      THEN
         RETURN '<null>';
      ELSIF (p_val = TRUE)
      THEN
         RETURN '<TRUE>';
      ELSIF (p_val = FALSE)
      THEN
         RETURN '<FALSE>';
      ELSE
         RETURN '<???>';
      END IF;
   END getval;

-- ===========================================================================

   -------------------------------------------------------------------------------
   FUNCTION build_error_prefix (sfdc_contact_obj IN xx_crm_sfdc_contact_obj)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
   BEGIN
      RETURN (   'party_id='
              || getval (sfdc_contact_obj.party_id)
              || ' aosr='
              || getval (sfdc_contact_obj.sfdc_account_osr)
              || ' msgver='
              || getval (sfdc_contact_obj.sfdc_message_version)
             );
   END build_error_prefix;

-- ===========================================================================

   -------------------------------------------------------------------------------
   PROCEDURE insert_contacts (
      sfdc_contact_obj   IN              xx_crm_sfdc_contact_obj,
      x_return_status    OUT NOCOPY      VARCHAR2,
      x_error_message    OUT NOCOPY      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_rtn_sts   VARCHAR2 (1) := fnd_api.g_ret_sts_success;
      l_id        NUMBER       := NULL;
      l_curr_dt   DATE         := SYSDATE;
      l_user_id   NUMBER       := NULL;
      i           PLS_INTEGER;
   BEGIN
      IF (sfdc_contact_obj IS NULL)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               'sfdc_contact_obj parameter is NULL but it must have a value.';
         RETURN;
      END IF;

      IF (sfdc_contact_obj.contact_objs IS NULL)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               build_error_prefix (sfdc_contact_obj)
            || ': sfdc_contact_obj.contact_objs parameter is NULL but it must have a value.';
         RETURN;
      END IF;

      IF (sfdc_contact_obj.contact_objs.COUNT < 1)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               build_error_prefix (sfdc_contact_obj)
            || ': sfdc_contact_obj.contact_objs parameter has no contacts but it must have at least one.';
         RETURN;
      END IF;

      IF (sfdc_contact_obj.party_id IS NULL)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               build_error_prefix (sfdc_contact_obj)
            || ': sfdc_contact_obj.party_id parameter is NULL but it must have a value.';
         RETURN;
      END IF;

      IF (sfdc_contact_obj.sfdc_account_osr IS NULL)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               build_error_prefix (sfdc_contact_obj)
            || ': sfdc_contact_obj.sfdc_account_osr parameter is NULL but it must have a value.';
         RETURN;
      END IF;

      BEGIN
         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE user_name = 'ODCRMBPEL';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_user_id := anonymous_apps_user;
      END;

      FOR i IN 1 .. sfdc_contact_obj.contact_objs.COUNT
      LOOP
         SELECT xx_crm_sfdc_contacts_s.NEXTVAL
           INTO l_id
           FROM DUAL;

         --Added primary_contact_flag for Defect32267
        /* Formatted on 2014/10/30 12:35 (Formatter Plus v4.8.8) */
INSERT INTO xx_crm_sfdc_contacts
            (ID, sfdc_account_id,
             sfdc_message_version,
             party_id,
             contact_role,
             contact_salutation,
             contact_first_name,
             contact_last_name,
             contact_job_title,
             contact_phone_number,
             contact_fax_number,
             contact_email_addr, import_status, import_attempt_count,
             creation_date, created_by, last_update_date, last_updated_by,
             last_update_login, primary_contact_flag
            )
     VALUES (l_id, --  id
             sfdc_contact_obj.sfdc_account_osr,--  sfdc_account_id
             sfdc_contact_obj.sfdc_message_version, --sfdc_message_version
             sfdc_contact_obj.party_id,--  party_id
             sfdc_contact_obj.contact_objs (i).contact_role,--  contact_role
             sfdc_contact_obj.contact_objs (i).salutation, --  contact_salutation
             sfdc_contact_obj.contact_objs (i).first_name,--  contact_first_name
             sfdc_contact_obj.contact_objs (i).last_name,--  contact_last_name
             sfdc_contact_obj.contact_objs (i).job_title, --  contact_job_title
             sfdc_contact_obj.contact_objs (i).phone_number,--  contact_phone_number
             sfdc_contact_obj.contact_objs (i).fax_number, --  contact_fax_number
             sfdc_contact_obj.contact_objs (i).email_address, --  contact_email_addr
             'NEW', --  import_status
             0, --  import_attempt_count
             l_curr_dt, --  creation_date
             l_user_id, --  created_by
             l_curr_dt, --  last_update_date
             l_user_id, --last_updated_by
             NULL,      --  last_update_login
             sfdc_contact_obj.contact_objs (i).primary_contact_flag --primary flag
            );
      END LOOP;

      x_return_status := fnd_api.g_ret_sts_success;
      x_error_message := NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_error_message :=
               build_error_prefix (sfdc_contact_obj)
            || ':EXCEPTION SQLERRM='
            || SQLERRM;
   END insert_contacts;

/*
  Procedure to update email address  
*/
   
PROCEDURE insert_contact_email(p_acct_orig_sys_reference  in            varchar2,
                               p_email_address            in            varchar2,
                                x_return_status          out nocopy    varchar2,
                                x_error_message          out nocopy    varchar2)
is
     l_id                    NUMBER;
     l_user_id               NUMBER;
     lv_primary_contact_flag VARCHAR2(2);
     l_contact_point_rec     HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
     l_email_rec             HZ_CONTACT_POINT_V2PUB.email_rec_type;
     ln_contact_point_id     NUMBER;
     ln_object_version       NUMBER;
     ln_party_id             NUMBER;
     ln_account_id           NUMBER;
     lv_error_msg            VARCHAR2(2000);
     x_ret_status            VARCHAR2(2000);
     x_msg_count             NUMBER;
     x_msg_data              VARCHAR2(2000);
     e_contact_error         EXCEPTION;
begin
  --this is for BSD work out inserting corrected email address for a a direct customer.
  --we need to derive the Billing Contact
  --Add the corrected email to the Billing contact's contact_point
  --First alter the table to add acct_orig_sys_reference
  BEGIN
     SELECT user_id
       INTO l_user_id
       FROM fnd_user
      WHERE user_name = 'ODCRMBPEL';
  EXCEPTION
     WHEN OTHERS
     THEN
        l_user_id := anonymous_apps_user;
  END;

  SELECT xx_crm_sfdc_contacts_s.NEXTVAL
           INTO l_id
           FROM DUAL;

    --
    --Fetch required details for update
    --
    BEGIN
        SELECT cust_account_id 
          INTO ln_account_id 
          FROM hz_cust_accounts hca
         WHERE hca.orig_system_reference = p_acct_orig_sys_reference;
        
        SELECT hp.party_id,contact_point_id,hcp.object_version_number,PRIMARY_FLAG
          INTO ln_party_id,ln_contact_point_id,ln_object_version,lv_primary_contact_flag
          FROM hz_cust_accounts hca,
               hz_parties hp,
               hz_contact_points hcp
         WHERE hp.party_id = hca.party_id
           AND hp.party_id = hcp.owner_table_id
           AND hcp.owner_table_name  = 'HZ_PARTIES'
           AND hcp.contact_point_type = 'EMAIL'
           AND hcp.status = 'A'
           AND hp.status = 'A'
           AND hca.status = 'A'
           AND hca.cust_account_id = ln_account_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
          lv_error_msg := 'Contact point details not found for '||p_acct_orig_sys_reference;
          raise e_contact_error;
      WHEN TOO_MANY_ROWS THEN
          lv_error_msg := 'Multiple active emails for party for '||p_acct_orig_sys_reference;
          raise e_contact_error;
      WHEN OTHERS THEN
          lv_error_msg := 'Error while fetching contact details '||SQLERRM;
          raise e_contact_error;
    END;

         --Added primary_contact_flag for Defect32267
        /* Formatted on 2014/10/30 12:35 (Formatter Plus v4.8.8) */
   INSERT INTO xx_crm_sfdc_contacts
        (ID, 
         sfdc_account_id,
         sfdc_message_version,
         party_id,
         contact_role,
         contact_salutation,
         contact_first_name,
         contact_last_name,
         contact_job_title,
         contact_phone_number,
         contact_fax_number,
         contact_email_addr, import_status, import_attempt_count,
         creation_date, created_by, last_update_date, last_updated_by,
         last_update_login, primary_contact_flag,acct_orig_sys_reference
        )
  VALUES (l_id, --  id
         null,--  sfdc_account_id
         null, --sfdc_message_version
         ln_party_id,--  party_id
         null,--lv_contact_role,--  contact_role
         null, --  contact_salutation
         null,--  contact_first_name
         null,--  contact_last_name
         null, --  contact_job_title
         null,--  contact_phone_number
         null, --  contact_fax_number
         p_email_address, --  contact_email_addr
         'NEW', --  import_status
         0, --  import_attempt_count
         SYSDATE, --  creation_date
         l_user_id, --  created_by
         SYSDATE, --  last_update_date
         l_user_id, --last_updated_by
         NULL,      --  last_update_login
         lv_primary_contact_flag --primary flag
         ,p_acct_orig_sys_reference
        );

    --
    -- Creating record types for API
    --
    l_contact_point_rec.owner_table_id     := ln_party_id;
    l_contact_point_rec.contact_point_id   := ln_contact_point_id;
    l_contact_point_rec.contact_point_type := 'EMAIL';
    l_contact_point_rec.owner_table_name   := 'HZ_PARTIES';
    l_email_rec.email_address              := p_email_address;
 --
 -- Calling update email API
 --
    HZ_CONTACT_POINT_V2PUB.update_email_contact_point
       (
        p_contact_point_rec      =>  l_contact_point_rec,  
        p_email_rec              =>  l_email_rec, 
        p_object_version_number  =>  ln_object_version,        
        x_return_status          =>  x_ret_status,
        x_msg_count              =>  x_msg_count,
        x_msg_data               =>  x_msg_data
      );
    --
    -- validating API results
    --
    IF (x_ret_status <> 'S') then
        IF x_msg_count > 1 THEN
            FOR i IN 1..x_msg_count LOOP
                lv_error_msg := SUBSTR(lv_error_msg||substr(FND_MSG_PUB.Get( p_encoded => FND_API.G_FALSE ),1,255),1,4000);
            END LOOP;
        END IF;
        raise e_contact_error;
    ELSE
        x_error_message := 'Contact updated for '||p_acct_orig_sys_reference;
        x_return_status :=x_ret_status;
    END IF; 
  
  x_return_status := 'S';
  x_error_message := NULL;
exception
    WHEN e_contact_error THEN
        x_return_status  :='E';
        x_error_message     := lv_error_msg; 
  when others then
    x_return_status := 'E';
    x_error_message := SQLERRM;
end;
END xx_crm_sfdc_contacts_pkg;
/