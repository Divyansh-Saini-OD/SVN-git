SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY xx_crm_sfdc_contacts_pkg
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
END xx_crm_sfdc_contacts_pkg;
/

show errors

