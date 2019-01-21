CREATE OR REPLACE PACKAGE BODY xxcrm_import_sfdc_contacts_pkg
-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XXCRM_IMPORT_SFDC_CONTACTS_PKG.pkb                        |
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
-- | Import AP and Ebill contacts from SFDC to Ebiz.                          |
-- |                                                                          |
-- | Contact records are placed in Ebiz staging table from salesforce.com by  |
-- | a SOA process.  This program reads all contacts not yet imported into    |
-- | Ebiz where a prospect has been converted into a customer.                |
-- |                                                                          |
-- | Import each contact found if the corresponding corresponding Party       |
-- | is a customer.  Contacts are typically selected for import shortly after |
-- | their corresponding party site changes status from a prospect to         |
-- | a customer.                                                              |
-- |                                                                          |
-- | Parameters  :                                                            |
-- |                                                                          |
-- |   p_timeout_days                                                         |
-- |       Dont process records in xx_xrm_sfdc_contacts with                  |
-- |       last_updated_date < (sysdate - p_timeout_days).                    |
-- |       If p_timeout_days is <= 0 all records in xx_xrm_sfdc_contacts will |
-- |       be processed.                                                      |
-- |                                                                          |
-- |   p_purge_days                                                           |
-- |       Delete records from xx_xrm_sfdc_contacts with                      |
-- |       last_updated_date < (sysdate - p_purge_days) AND import_status in  |
-- |       (NEW, ERROR). If p_purge_days <= 0 no records will be deleted.     |
-- |       The purge process is performed last.  Records eligible for purge   |
-- |       will be processeed instead of purged if they are imported during   |
-- |       the current execution of the program (results in changing          |
-- |       last_updated_date to sysdate).                                     |
-- |                                                                          |
-- |   p_reprocess_errors                                                     |
-- |       Y = Process records with import_status = ERROR in addition to      |
-- |           normal processing. Old records with ERROR status will not be   |
-- |           re-processed if they don't meet the p_timeout_days test.       |
-- |                                                                          |
-- |           Any other value causes records with import_status = ERROR to   |
-- |           be ignored.                                                    |
-- |                                                                          |
-- | Notes:                                                                   |
-- |                                                                          |
-- | Since the AP and eBill contacts are created in salesforce.com only for   |
-- | the purpose of sending them to Ebiz they will be deleted from salesforce |
-- | shortly after tey are sent.  As a result, no contact OSR info will be    |
-- | received from salesforce.                                                |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       25-JUL-2011  Phil Price         Initial version                 |
-- |2.0       30-Oct-2014  Sridevi            For Defect32267                 |
-- |3.0       30-Jun-2015  Sreedhar Mohan     logic for OSRs for unique ID    |
-- |3.1       9-Jul-2015   Sridevi K          Modified create_one_contact     |
-- |                                          for Primary flag                |
-- |3.2       15-Jul-2015   Sridevi K         Modified create_one_contact     |
-- |                                          for Defect35086                 |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for |
-- |                                         GSCC compliance QC#37898         |
-- |3.4       10-Nov-2016   Vasu R           Removed the schema reference for |
-- |                                         GSCC compliance                  |
-- +==========================================================================+
AS
-- ============================================================================
-- Global Constants
-- ============================================================================
   g_package                        CONSTANT VARCHAR2 (30)
                                              := 'XXCRM_IMPORT_SFDC_CONTACTS';
--
-- Subversion keywords
--
   g_svn_head_url                   CONSTANT VARCHAR2 (500)
      := '$HeadURL$';
   g_svn_revision                   CONSTANT VARCHAR2 (100)
                                                          := '$Rev$';
   g_svn_date                       CONSTANT VARCHAR2 (100)
                   := '$Date$';
--
-- Debug levels
--
   dbg_off                          CONSTANT NUMBER         := 0;
   dbg_low                          CONSTANT NUMBER         := 1;
   dbg_med                          CONSTANT NUMBER         := 2;
   dbg_hi                           CONSTANT NUMBER         := 3;
--
--  Log message levels
--
   log_info                         CONSTANT VARCHAR2 (1)   := 'I';
   log_warn                         CONSTANT VARCHAR2 (1)   := 'W';
   log_err                          CONSTANT VARCHAR2 (1)   := 'E';
--
-- Concurrent Manager completion statuses
--
   conc_status_ok                   CONSTANT NUMBER         := 0;
   conc_status_warning              CONSTANT NUMBER         := 1;
   conc_status_error                CONSTANT NUMBER         := 2;
--
--  "who" info
--
   anonymous_apps_user              CONSTANT NUMBER         := -1;
--
-- Possible values for import_status in xx_crm_sfdc_contacts
--

   -- Record inserted into this table but not imported yet.
--   Could be that customer account for this party_id has not been created yet,
--   or the concurrent program that imports the contacts into Ebiz hasn't executed yet.
--
   imp_sts_new                      CONSTANT VARCHAR2 (20)  := 'NEW';
-- party_id associated with this contact andit will be imported.
--   Status was NEW and conc program that imports the contacts into Ebiz
--   has determined that a customer account exists for the party_id.
--
   imp_sts_ready_for_import         CONSTANT VARCHAR2 (20)  := 'PENDING';
-- Conc program that imports the contacts into Ebiz inserted the contact record into
-- the import interface tables and executed the conc programs that perform the import.
--
   imp_sts_imported                 CONSTANT VARCHAR2 (20)  := 'IMPORTED';
--
-- Attempted to import the contact but an error occurred.
--
   imp_sts_error                    CONSTANT VARCHAR2 (20)  := 'ERROR';
--
-- OSR Prefixes / suffixes
--
-- The OSR value must be unique for each record so we add a prefix or suffix where needed.
--
   phone_contact_point_osr_prefix   CONSTANT VARCHAR2 (1)   := 'P';
   fax_contact_point_osr_prefix     CONSTANT VARCHAR2 (1)   := 'F';
   email_contact_point_osr_prefix   CONSTANT VARCHAR2 (1)   := 'E';
-- Ebiz prospects created from SFDC already use the SFDC account ID as its OSR value.
-- In order to not conflict with the prospect OSR value, we append a suffix to the OSR value.
   contact_osr_suffix               CONSTANT VARCHAR2 (10)  := '-CONTACT';
   ebill_contact_osr_suffix         CONSTANT VARCHAR2 (10)  := '-EBILL';
   ap_contact_osr_suffix            CONSTANT VARCHAR2 (10)  := '-AP';
--
-- End of OSR info
--

   --
-- Misc constants
--
   sq                               CONSTANT VARCHAR2 (1)   := CHR (39);
                                                              -- single quote
   lf                               CONSTANT VARCHAR2 (1)   := CHR (10);
                                                                 -- line feed
   our_module_name                  CONSTANT VARCHAR2 (20)
                                                     := 'XXCRM_SFDC_CONTACTS';
   sfdc_orig_system                 CONSTANT VARCHAR2 (10)  := 'SFDC';
                               -- must exist in hz_orig_systems_b.orig_system
--
-- Global variables
--
   g_conc_mgr_env                            BOOLEAN;
   g_commit                                  BOOLEAN;
   g_error_ct                                NUMBER         := 0;
   g_warning_ct                              NUMBER         := 0;
   g_debug_level                             NUMBER         := dbg_off;
   g_org_id                                  NUMBER
                                              := fnd_profile.VALUE ('org_id');
   g_user_id                                 NUMBER     := fnd_global.user_id;
   g_last_update_login                       NUMBER    := fnd_global.login_id;
   g_conc_program_id                         NUMBER
                                                := fnd_global.conc_program_id;
   g_conc_request_id                         NUMBER
                                                := fnd_global.conc_request_id;
   g_conc_prog_appl_id                       NUMBER
                                                   := fnd_global.prog_appl_id;
   g_conc_login_id                           NUMBER
                                                  := fnd_global.conc_login_id;
--
-- Contact roles this program works with
--
   g_ap_contact_role                         VARCHAR2 (50)  := NULL;
   g_ebill_contact_role                      VARCHAR2 (50)  := NULL;

--
-- Cursors
--

   -- Tried "for update of..." but no rows were returned in uatgb
-- when "hca" subquery is included.  Related to VPD???
   CURSOR c_find_contacts2 (
      c_timneout_days         NUMBER,
      c_error_import_status   VARCHAR2
   )
   IS
      SELECT ID
        FROM xx_crm_sfdc_contacts cont
       WHERE last_update_date >= (TRUNC (SYSDATE) - c_timneout_days)
         AND (   (import_status = imp_sts_new)
              OR (import_status = c_error_import_status)
             )
         AND EXISTS (SELECT 'x'
                       FROM hz_cust_accounts hca
                      WHERE cont.party_id = hca.party_id AND hca.status = 'A');

   CURSOR c_find_contacts3
   IS
      SELECT        ID, sfdc_account_id, party_id, contact_role,
                    contact_salutation, contact_first_name, contact_last_name,
                    contact_job_title, contact_phone_number,
                    contact_fax_number, contact_email_addr,
                    primary_contact_flag, creation_date, created_by,
                    last_update_date, last_updated_by, import_status,
                    import_error, import_attempt_count
               FROM xx_crm_sfdc_contacts cont
              WHERE import_status = imp_sts_ready_for_import
           ORDER BY ID
      FOR UPDATE OF import_status,
                    last_update_date,
                    last_updated_by,
                    import_error;

-- ============================================================================

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
   FUNCTION getval2 (p_val IN VARCHAR2)
      RETURN VARCHAR2
   IS
-------------------------------------------------------------------------------
-- Same as getval for varchar2 data type except a single space character is
-- returned if p_val is null.
   BEGIN
      IF (p_val IS NULL)
      THEN
         RETURN (' ');
      ELSIF (p_val = fnd_api.g_miss_char)
      THEN
         RETURN '<missing>';
      ELSE
         RETURN p_val;
      END IF;
   END getval2;

-- ===========================================================================

   -------------------------------------------------------------------------------
   FUNCTION compare_values_vc (val1 IN VARCHAR2, val2 IN VARCHAR2)
      RETURN BOOLEAN
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF ((val1 = val2) OR ((val1 IS NULL) AND (val2 IS NULL)))
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END compare_values_vc;

-- ============================================================================

   -------------------------------------------------------------------------------
   FUNCTION compare_values_num (val1 IN NUMBER, val2 IN NUMBER)
      RETURN BOOLEAN
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF ((val1 = val2) OR ((val1 IS NULL) AND (val2 IS NULL)))
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END compare_values_num;

-- ============================================================================

   -------------------------------------------------------------------------------
   FUNCTION compare_values_dt (val1 IN DATE, val2 IN DATE)
      RETURN BOOLEAN
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF ((val1 = val2) OR ((val1 IS NULL) AND (val2 IS NULL)))
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END compare_values_dt;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE wrtdbg (p_debug_level IN NUMBER, p_buff IN VARCHAR2)
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (g_debug_level >= p_debug_level)
      THEN
         IF (g_conc_mgr_env = TRUE)
         THEN
            IF (p_buff = CHR (10))
            THEN
               fnd_file.put_line (fnd_file.LOG, 'DBG: ');
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'DBG: ' || dti || p_buff);
            END IF;
         ELSE
            IF (p_buff = CHR (10))
            THEN
               DBMS_OUTPUT.put_line ('DBG: ');
            ELSE
               DBMS_OUTPUT.put_line ('DBG: ' || dti || p_buff);
            END IF;
         END IF;
      END IF;
   END wrtdbg;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE wrtlog (p_buff IN VARCHAR2)
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (g_conc_mgr_env = TRUE)
      THEN
         IF (p_buff = CHR (10))
         THEN
            fnd_file.put_line (fnd_file.LOG, ' ');
         ELSE
            fnd_file.put_line (fnd_file.LOG, p_buff);
         END IF;
      ELSE
         IF (p_buff = CHR (10))
         THEN
            DBMS_OUTPUT.put_line ('LOG: ');
         ELSE
            DBMS_OUTPUT.put_line ('LOG: ' || p_buff);
         END IF;
      END IF;
   END wrtlog;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE wrtlog (p_level IN VARCHAR2, p_buff IN VARCHAR2)
   IS
-------------------------------------------------------------------------------
   BEGIN
      wrtlog (dti || p_level || ': ' || p_buff);
   END wrtlog;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE wrtout (p_buff IN VARCHAR2)
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (g_conc_mgr_env = TRUE)
      THEN
         IF (p_buff = CHR (10))
         THEN
            fnd_file.put_line (fnd_file.output, ' ');
         ELSE
            fnd_file.put_line (fnd_file.output, p_buff);
         END IF;
      ELSE
         IF (p_buff = CHR (10))
         THEN
            DBMS_OUTPUT.put_line ('OUT: ');
         ELSE
            DBMS_OUTPUT.put_line ('OUT: ' || p_buff);
         END IF;
      END IF;
   END wrtout;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE wrtall (p_buff IN VARCHAR2)
   IS
-------------------------------------------------------------------------------
   BEGIN
      wrtlog (p_buff);
      wrtout (p_buff);
   END wrtall;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE report_svn_info
   IS
-------------------------------------------------------------------------------
      lc_svn_file_name   VARCHAR2 (200);
   BEGIN
      lc_svn_file_name :=
                   REGEXP_REPLACE (g_svn_head_url, '(.*/)([^/]*)( \$)', '\2');
      wrtlog (   lc_svn_file_name
              || ' '
              || RTRIM (g_svn_revision, '$')
              || g_svn_date
             );
      wrtlog (' ');
   END report_svn_info;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE initialize (
      p_commit_flag   IN       VARCHAR2,
      p_debug_level   IN       NUMBER,
      p_sql_trace     IN       VARCHAR2,
      p_msg           OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc   VARCHAR2 (80)  := 'INITIALIZE';
      l_ctx    VARCHAR2 (200) := NULL;
   BEGIN
      g_debug_level := p_debug_level;
      g_warning_ct := 0;
      g_error_ct := 0;

      IF (p_sql_trace = 'Y')
      THEN
         l_ctx := 'Setting SQL trace ON';
         wrtlog (dti || 'Setting SQL trace ON');
         l_ctx := 'alter session max_dump_file_size';

         EXECUTE IMMEDIATE 'ALTER SESSION SET max_dump_file_size = unlimited';

         l_ctx := 'alter session tracefile_identifier';

         EXECUTE IMMEDIATE    'ALTER SESSION SET tracefile_identifier = '
                           || sq
                           || g_package
                           || sq;

         l_ctx := 'alter session timed_statistics';

         EXECUTE IMMEDIATE 'ALTER SESSION SET timed_statistics = true';

         l_ctx := 'alter session events 10046';

         EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''10046 trace name context forever, level 12''';
      END IF;

      IF (p_commit_flag = 'Y')
      THEN
         g_commit := TRUE;
      ELSE
         g_commit := FALSE;
      END IF;

      IF (g_user_id = anonymous_apps_user)
      THEN
         g_conc_mgr_env := FALSE;
         g_conc_program_id := NULL;
         g_conc_request_id := NULL;
         g_conc_prog_appl_id := NULL;
         g_conc_login_id := NULL;
         DBMS_OUTPUT.ENABLE (NULL);                  -- NULL = unlimited size
         wrtlog (log_info, 'NOT executing in concurrent manager environment');
      ELSE
         g_conc_mgr_env := TRUE;
         wrtlog (log_info, 'Executing in concurrent manager environment');
      END IF;

      report_svn_info;
      wrtdbg (dbg_low, '"who" values:');
      wrtdbg (dbg_low, '               USER_ID = ' || getval (g_user_id));
      wrtdbg (dbg_low,
              '     LAST_UPDATE_LOGIN = ' || getval (g_last_update_login)
             );
      wrtdbg (dbg_low,
              '       CONC_REQUEST_ID = ' || getval (g_conc_request_id)
             );
      wrtdbg (dbg_low,
              '     CONC_PROG_APPL_ID = ' || getval (g_conc_prog_appl_id)
             );
      wrtdbg (dbg_low,
              '       CONC_PROGRAM_ID = ' || getval (g_conc_program_id)
             );
      wrtdbg (dbg_low,
              '         CONC_LOGIN_ID = ' || getval (g_conc_login_id));
      wrtdbg (dbg_low, '                ORG_ID = ' || getval (g_org_id));
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END initialize;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE decode_api_error (
      p_proc            IN       VARCHAR2,
      p_call            IN       VARCHAR2,
      p_return_status   IN       VARCHAR2,
      p_msg_count       IN       NUMBER,
      p_msg_data        IN       VARCHAR2,
      p_addtl_info      IN       VARCHAR2,
      p_msg             OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc       VARCHAR2 (80)   := 'decode_api_error';
      l_ctx        VARCHAR2 (2000) := NULL;
      l_err_str    VARCHAR2 (2000);
      l_next_msg   VARCHAR2 (2000);
   BEGIN
      l_err_str :=
            'procedure='
         || p_proc
         || ' API_call='
         || p_call
         || ' FAILED with return_status='
         || getval (p_return_status);

      IF ((p_addtl_info IS NOT NULL) AND (LENGTH (p_addtl_info) > 0))
      THEN
         l_err_str := l_err_str || ' - addtl info=' || p_addtl_info;
      END IF;

      IF (p_msg_count = 1)
      THEN
         l_err_str := l_err_str || '. Error=' || p_msg_data;
      ELSE
         l_err_str := l_err_str || '. Error=';

         FOR i IN 1 .. p_msg_count
         LOOP
            l_next_msg :=
               fnd_msg_pub.get (p_encoded        => fnd_api.g_false,
                                p_msg_index      => i
                               );

            IF (i = 1)
            THEN
               l_err_str := SUBSTR (l_err_str || l_next_msg, 1, 2000);
            ELSE
               l_err_str := SUBSTR (l_err_str || '. ' || l_next_msg, 1, 2000);
            END IF;
         END LOOP;
      END IF;

      p_msg := l_err_str;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error (-20001,
                                     'l_proc='
                                  || l_proc
                                  || ' SQLCODE='
                                  || SQLCODE
                                  || ' SQLERRM='
                                  || SQLERRM
                                 );
   END decode_api_error;

-- ===========================================================================

   -------------------------------------------------------------------------------
   PROCEDURE add_to_warnings (
      p_existing_warnings   IN OUT NOCOPY   VARCHAR2,
      p_new_warning         IN              VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
   BEGIN
      IF (p_existing_warnings IS NULL)
      THEN
         p_existing_warnings := SUBSTR (p_new_warning, 1, 2000);
      ELSE
         p_existing_warnings :=
            SUBSTR (p_existing_warnings || '. ' || lf || p_new_warning,
                    1,
                    2000
                   );
      END IF;
   END add_to_warnings;

-- ===========================================================================

   -------------------------------------------------------------------------------
   PROCEDURE link_ebill_contact_to_paydoc (
      p_cust_account_id     IN              NUMBER,
      p_cust_account_num    IN              VARCHAR2,
      p_cust_acct_site_id   IN              NUMBER,
      p_org_contact_id      IN              NUMBER,
      p_warnings            IN OUT NOCOPY   VARCHAR2,
      p_msg                 OUT             VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc                 VARCHAR2 (80)  := 'link_ebill_contact_to_paydoc';
      l_ctx                  VARCHAR2 (200)                           := NULL;
      l_curr_dt              DATE                                  := SYSDATE;
      l_okay                 BOOLEAN                                  := TRUE;
      l_cust_doc_id          NUMBER                                   := NULL;
      l_delivery_method      xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE;
      l_ebl_doc_contact_id   NUMBER;
      l_extension_id         NUMBER;
   BEGIN
      wrtdbg (dbg_med, 'Enter ' || l_proc);

      BEGIN
         l_ctx :=
               'select from xx_cdh_cust_acct_ext_b - p_cust_account_id='
            || getval (p_cust_account_id);

         SELECT n_ext_attr2, c_ext_attr3, extension_id
           INTO l_cust_doc_id, l_delivery_method, l_extension_id
           FROM (SELECT n_ext_attr2, c_ext_attr3, extension_id,
                        RANK () OVER (ORDER BY creation_date DESC) latest
                   FROM xx_cdh_cust_acct_ext_b cae
                  WHERE cust_account_id = p_cust_account_id
                    AND c_ext_attr2 = 'Y'  -- indicates the record is a paydoc
                    AND NVL (c_ext_attr13, 'DB') =
                           'DB'
                           -- billdoc combo type (value can be DB, CR or null)
                    AND c_ext_attr16 in (
                           'IN_PROCESS', 'COMPLETE')
                               -- status (value can be COMPLETE or IN_PROCESS)
                    AND c_ext_attr3 = 'ePDF'
                    AND TRUNC (SYSDATE) BETWEEN NVL (d_ext_attr1, SYSDATE - 1)
                                                                 -- start date
                                            AND NVL (d_ext_attr2, SYSDATE + 1)
                                                                   -- end date
                    AND attr_group_id =
                           (SELECT attr_group_id
                              FROM ego_attr_groups_v eag
                             WHERE eag.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                               AND eag.attr_group_name = 'BILLDOCS'
                               AND eag.application_id =
                                        (SELECT application_id
                                           FROM fnd_application
                                          WHERE application_short_name = 'AR')))
          WHERE latest = 1;

         wrtdbg (dbg_med,
                 '        l_cust_doc_id = ' || getval (l_cust_doc_id));
         wrtdbg (dbg_med,
                 '    l_delivery_method = ' || getval (l_delivery_method)
                );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            add_to_warnings
               (p_warnings,
                   'Cannot link eBill contact to paydoc because paydoc not found for customer # '
                || getval (p_cust_account_num)
               );
            l_okay := FALSE;
      END;

      wrtdbg (dbg_med,
                 '  l_okay='
              || getval (l_okay)
              || ' l_cust_doc_id='
              || getval (l_cust_doc_id)
             );

      IF (l_okay)
      THEN
         SAVEPOINT ebill_save01;
         l_ctx := 'select xx_cdh_ebl_doc_contact_id_s.nextval';

         SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
           INTO l_ebl_doc_contact_id
           FROM DUAL;

         l_ctx :=
               'insert into xx_cdh_ebl_contacts - l_ebl_doc_contact_id='
            || getval (l_ebl_doc_contact_id);

         INSERT INTO xx_cdh_ebl_contacts
                     (ebl_doc_contact_id, cust_doc_id, org_contact_id,
                      --cust_acct_site_id,
                      attribute1, creation_date, created_by,
                      last_update_date, last_updated_by, last_update_login,
                      request_id, program_application_id,
                      program_id, program_update_date
                     )
              VALUES (l_ebl_doc_contact_id,              -- ebl_doc_contact_id
                                           l_cust_doc_id,       -- cust_doc_id
                                                         p_org_contact_id,
                                                             -- org_contact_id
                      --p_cust_acct_site_id,         -- cust_acct_site_id
                      TO_CHAR (p_cust_account_id),               -- attribute1
                                                  l_curr_dt,  -- creation_date
                                                            g_user_id,
                                                                 -- created_by
                      l_curr_dt,                           -- last_update_date
                                g_user_id,                  -- last_updated_by
                                          g_last_update_login,
                                                          -- last_update_login
                      g_conc_request_id,                         -- request_id
                                        g_conc_prog_appl_id,
                                                     -- program_application_id
                      g_conc_program_id,                         -- program_id
                                        l_curr_dt
                     );                                 -- program_update_date
      END IF;

      wrtdbg (dbg_med, 'Exit ' || l_proc);
	  
      UPDATE xx_cdh_cust_acct_ext_b
         SET c_ext_attr16 = 'COMPLETE',
             last_update_date = SYSDATE
       WHERE extension_id = l_extension_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END link_ebill_contact_to_paydoc;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE get_cust_account_info (
      p_party_id            IN       NUMBER,
      p_cust_account_id     OUT      NUMBER,
      p_cust_account_num    OUT      VARCHAR2,
      p_cust_account_name   OUT      VARCHAR2,
      p_ab_flag             OUT      VARCHAR2,
      p_msg                 OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc   VARCHAR2 (80)  := 'get_cust_account_info';
      l_ctx    VARCHAR2 (200) := NULL;

      CURSOR c_cust_info (c_party_id NUMBER)
      IS
         SELECT acct.cust_account_id, acct.account_number,
                hp.party_name customer_name,
                NVL (prof.attribute3, 'N') ab_flag
           FROM hz_cust_accounts acct,
                hz_customer_profiles prof,
                hz_parties hp
          WHERE hp.party_id = acct.party_id
            AND acct.cust_account_id = prof.cust_account_id(+)
            AND prof.site_use_id IS NULL
            AND hp.party_id = c_party_id;
   BEGIN
      wrtdbg (dbg_med, 'Enter ' || l_proc);
      wrtdbg (dbg_med, '  p_party_id = ' || getval (p_party_id));
      l_ctx := 'open c_cust_info - p_party_id=' || getval (p_party_id);

      OPEN c_cust_info (p_party_id);

      l_ctx := 'fetch c_cust_info - p_party_id=' || getval (p_party_id);

      FETCH c_cust_info
       INTO p_cust_account_id, p_cust_account_num, p_cust_account_name,
            p_ab_flag;

      l_ctx := 'close c_cust_info';

      CLOSE c_cust_info;

      wrtdbg (dbg_med, 'After fetch from c_cust_info:');
      wrtdbg (dbg_med,
              '      p_cust_account_id = ' || getval (p_cust_account_id)
             );
      wrtdbg (dbg_med,
              '     p_cust_account_num = ' || getval (p_cust_account_num)
             );
      wrtdbg (dbg_med,
              '    p_cust_account_name = ' || getval (p_cust_account_name)
             );
      wrtdbg (dbg_med, '              p_ab_flag = ' || getval (p_ab_flag));

      IF (p_cust_account_id IS NULL)
      THEN
         p_msg := 'Customer not found for party_id = ' || getval (p_party_id);
      END IF;

      wrtdbg (dbg_med, 'Exit ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END get_cust_account_info;

-- ============================================================================

   -------------------------------------------------------------------------------
   FUNCTION find_ext (
      p_phone_number       IN       VARCHAR2,
      p_start_search_pos   IN       NUMBER,
      p_search_str         IN       VARCHAR2,
      p_start_pos          OUT      NUMBER,
      p_len                OUT      NUMBER
   )
      RETURN BOOLEAN
   IS
-------------------------------------------------------------------------------
      l_proc        VARCHAR2 (80)   := 'find_ext';
      l_ctx         VARCHAR2 (2000) := NULL;
      l_found       BOOLEAN;
      l_start_pos   NUMBER          := 0;
      l_len         NUMBER          := 0;
   BEGIN
      wrtdbg (dbg_med, 'Enter ' || l_proc);
      wrtdbg (dbg_med, '      p_phone_number = ' || getval (p_phone_number));
      wrtdbg (dbg_med,
              '  p_start_search_pos = ' || getval (p_start_search_pos)
             );
      wrtdbg (dbg_med, '        p_search_str = ' || getval (p_search_str));
      l_found := FALSE;
      p_start_pos := NULL;
      p_len := NULL;
      l_start_pos := INSTR (p_phone_number, p_search_str, p_start_search_pos);

      IF (l_start_pos > 0)
      THEN
         l_found := TRUE;
         p_start_pos := l_start_pos;
         p_len := LENGTH (p_search_str);
      END IF;

      wrtdbg (dbg_med, 'About to exit ' || l_proc);
      wrtdbg (dbg_med, '  p_start_pos = ' || getval (p_start_pos));
      wrtdbg (dbg_med, '        p_len = ' || getval (p_len));
      wrtdbg (dbg_med, '      l_found = ' || getval (l_found));
      wrtdbg (dbg_med, 'Exit ' || l_proc);
      RETURN (l_found);
   END find_ext;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE format_raw_phone (
      p_raw_phone_in               IN       VARCHAR2,
      p_raw_phone_out              OUT      VARCHAR2,
      p_default_country_code_out   OUT      VARCHAR2,
      p_phone_extension_out        OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc        VARCHAR2 (80)   := 'format_raw_phone';
      l_ctx         VARCHAR2 (2000) := NULL;
      l_raw_phone   VARCHAR2 (100);
      l_tmp_phone   VARCHAR2 (100);
      l_match_str   VARCHAR2 (10);
      l_start_pos   NUMBER;
      l_len         NUMBER;
   BEGIN
      wrtdbg (dbg_hi, 'Enter ' || l_proc);
      wrtdbg (dbg_hi, '  p_raw_phone_in = ' || getval (p_raw_phone_in));
      p_raw_phone_out := NULL;
      p_default_country_code_out := NULL;
      p_phone_extension_out := NULL;

      IF (p_raw_phone_in IS NULL)
      THEN
         RETURN;
      END IF;

      l_raw_phone := TRIM (p_raw_phone_in);

      --
      -- If l_raw_phone starts with "+" it means the country code is already embedded in the phone number.
      -- If l_raw_phone starts with "1" it menas the US country code is already embedded in the phone number.
      --
      IF (SUBSTR (l_raw_phone, 1, 1) NOT IN ('+', '1'))
      THEN
         p_default_country_code_out := '1';
      END IF;

      --
      -- Standard Oracle API doesn't parse phone extension from the raw phone number.
      -- We will attempt to do it here.
      -- If an extension was entered and it can't be parsed, it will be included
      -- with the phone number in the Ebiz screens.
      --
      -- We start looking for the extension after the 10th digit.
      --
      l_tmp_phone := UPPER (l_raw_phone);

      IF (find_ext (l_tmp_phone, 10, 'EXT.', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      ELSIF (find_ext (l_tmp_phone, 10, 'EXT', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      ELSIF (find_ext (l_tmp_phone, 10, 'EX.', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      ELSIF (find_ext (l_tmp_phone, 10, 'EX', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      ELSIF (find_ext (l_tmp_phone, 10, 'X.', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      ELSIF (find_ext (l_tmp_phone, 10, 'X', l_start_pos, l_len) = TRUE)
      THEN
         NULL;
      END IF;

      IF (l_start_pos IS NULL)
      THEN
         p_raw_phone_out := TRIM (p_raw_phone_in);
      ELSE
         p_raw_phone_out := TRIM (SUBSTR (l_raw_phone, 1, l_start_pos - 1));
         p_phone_extension_out :=
                             TRIM (SUBSTR (l_raw_phone, l_start_pos + l_len));
      END IF;

      wrtdbg (dbg_hi, 'About to exit ' || l_proc);
      wrtdbg (dbg_hi,
              '             p_raw_phone_out = ' || getval (p_raw_phone_out)
             );
      wrtdbg (dbg_hi,
                 '  p_default_country_code_out = '
              || getval (p_default_country_code_out)
             );
      wrtdbg (dbg_hi,
                 '       p_phone_extension_out = '
              || getval (p_phone_extension_out)
             );
      wrtdbg (dbg_hi, 'Exit ' || l_proc);
   END format_raw_phone;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE create_contact_points (
      p_party_id                 IN       NUMBER,
      p_sfdc_account_osr         IN       VARCHAR2,
      p_contact_role             IN       VARCHAR2,
      p_phone_number             IN       VARCHAR2,
      p_fax_number               IN       VARCHAR2,
      p_email_addr               IN       VARCHAR2,
      p_phone_contact_point_id   OUT      NUMBER,
      p_fax_contact_point_id     OUT      NUMBER,
      p_email_contact_point_id   OUT      NUMBER,
      p_email_osr                OUT      VARCHAR2,
      p_phone_osr                OUT      VARCHAR2,
      p_fax_osr                  OUT      VARCHAR2,
      p_msg                      OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc                  VARCHAR2 (80)        := 'create_contact_points';
      l_ctx                   VARCHAR2 (2000)                         := NULL;
      contact_point_rec       hz_contact_point_v2pub.contact_point_rec_type;
      edi_rec                 hz_contact_point_v2pub.edi_rec_type;
      email_rec               hz_contact_point_v2pub.email_rec_type;
      phone_rec               hz_contact_point_v2pub.phone_rec_type;
      x_contact_point_id      NUMBER;
      x_return_status         VARCHAR2 (2000);
      x_msg_count             NUMBER;
      x_msg_data              VARCHAR2 (2000);
      l_osr_suffix            VARCHAR2 (50);
      l_dunning_purpose_set   BOOLEAN                                := FALSE;
-- set email to dunning purpose.  If email doesn't exist, set dunning purpose to fax.
   BEGIN
      --
      -- Here is the general flow:
      --   - If a phone and fax number are provide, the phone will be primary.
      --   - For AP contact only:
      --       - If both email address and fax are provided, the email purpose is set to Dunning and the fax purpose is set to Collections
      --       - If only one of the above is provided, the purpose is set to Dunning.
      --
      wrtdbg (dbg_med, 'Enter ' || l_proc);
      wrtdbg (dbg_med, '          p_party_id = ' || getval (p_party_id));
      wrtdbg (dbg_med,
              '  p_sfdc_account_osr = ' || getval (p_sfdc_account_osr)
             );
      wrtdbg (dbg_med, '      p_contact_role = ' || getval (p_contact_role));
      wrtdbg (dbg_med, '      p_phone_number = ' || getval (p_phone_number));
      wrtdbg (dbg_med, '        p_fax_number = ' || getval (p_fax_number));
      wrtdbg (dbg_med, '        p_email_addr = ' || getval (p_email_addr));

      IF (p_contact_role = g_ap_contact_role)
      THEN
         l_osr_suffix := ap_contact_osr_suffix;
      ELSE
         l_osr_suffix := ebill_contact_osr_suffix;
      END IF;

      p_phone_contact_point_id := NULL;
      p_fax_contact_point_id := NULL;
      p_email_contact_point_id := NULL;
      contact_point_rec := NULL;
      edi_rec := NULL;
      email_rec := NULL;
      phone_rec := NULL;

      --
      -- Create EMAIL contact point
      --
      IF (p_email_addr IS NOT NULL)
      THEN
         contact_point_rec := NULL;
         email_rec := NULL;
         p_email_osr :=
               email_contact_point_osr_prefix
            || p_sfdc_account_osr
            || l_osr_suffix;
         contact_point_rec.contact_point_type := 'EMAIL';
                    -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE
         contact_point_rec.owner_table_name := 'HZ_PARTIES';
                                               -- could also be HZ_PARTY_SITES
         contact_point_rec.owner_table_id := p_party_id;
                                                     -- FK of owner_table_name
         contact_point_rec.created_by_module := our_module_name;
         contact_point_rec.orig_system := sfdc_orig_system;
         contact_point_rec.orig_system_reference := p_email_osr || xx_crm_sfdc_contacts_s.NEXTVAL;
         contact_point_rec.status := 'A';

         --contact_point_rec.primary_flag          :=
         --contact_point_rec.application_id        :=
         IF (p_contact_role = g_ap_contact_role)
         THEN
            contact_point_rec.contact_point_purpose := 'DUNNING';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
            l_dunning_purpose_set := TRUE;
         ELSE                                     -- this is the eBill contact
            contact_point_rec.contact_point_purpose := 'BILLING';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
         END IF;

         email_rec.email_format := 'MAILHTML';
                          -- value from ar_lookups, lookup_type = EMAIL_FORMAT
         email_rec.email_address := TRIM (p_email_addr);
         wrtdbg
            (dbg_med,
             'About to call hz_contact_point_v2pub.create_email_contact_point:'
            );
         wrtdbg (dbg_med,
                    '       contact_point_type = '
                 || getval (contact_point_rec.contact_point_type)
                );
         wrtdbg (dbg_med,
                    '    contact_point_purpose = '
                 || getval (contact_point_rec.contact_point_purpose)
                );
         wrtdbg (dbg_med,
                    '                 orig_sys = '
                 || getval (contact_point_rec.orig_system)
                );
         wrtdbg (dbg_med,
                    '             orig_sys_ref = '
                 || getval (contact_point_rec.orig_system_reference)
                );
         wrtdbg (dbg_med,
                    '             email_format = '
                 || getval (email_rec.email_format)
                );
         wrtdbg (dbg_med,
                    '            email_address = '
                 || getval (email_rec.email_address)
                );
         hz_contact_point_v2pub.create_email_contact_point
                                    (p_init_msg_list          => fnd_api.g_true,
                                     p_contact_point_rec      => contact_point_rec,
                                     p_email_rec              => email_rec,
                                     x_contact_point_id       => x_contact_point_id,
                                     x_return_status          => x_return_status,
                                     x_msg_count              => x_msg_count,
                                     x_msg_data               => x_msg_data
                                    );

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            p_email_contact_point_id := x_contact_point_id;
         ELSE
            decode_api_error
               (p_proc               => l_proc,
                p_call               => 'hz_contact_point_v2pub.create_email_contact_point',
                p_return_status      => x_return_status,
                p_msg_count          => x_msg_count,
                p_msg_data           => x_msg_data,
                p_addtl_info         =>    'EMAIL: p_party_id='
                                        || getval (p_party_id)
                                        || ' email='
                                        || getval (p_email_addr),
                p_msg                => p_msg
               );
            RETURN;
         END IF;
      END IF;

      --
      -- Create FAX contact point
      --
      IF (p_fax_number IS NOT NULL)
      THEN
         contact_point_rec := NULL;
         phone_rec := NULL;
         p_fax_osr :=
            fax_contact_point_osr_prefix || p_sfdc_account_osr
            || l_osr_suffix;
         contact_point_rec.contact_point_type := 'PHONE';
                   -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE
         contact_point_rec.owner_table_name := 'HZ_PARTIES';
                                              -- could also be HZ_PARTY_SITES
         contact_point_rec.owner_table_id := p_party_id;
                                                    -- FK of owner_table_name
         contact_point_rec.created_by_module := our_module_name;
         contact_point_rec.orig_system := sfdc_orig_system;
         contact_point_rec.orig_system_reference := p_fax_osr || xx_crm_sfdc_contacts_s.NEXTVAL;
         contact_point_rec.status := 'A';

         --contact_point_rec.primary_flag          :=
         --contact_point_rec.application_id        :=
         IF (p_contact_role = g_ap_contact_role)
         THEN
            IF (l_dunning_purpose_set)
            THEN
               contact_point_rec.contact_point_purpose := 'COLLECTIONS';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
            ELSE
               contact_point_rec.contact_point_purpose := 'DUNNING';
               l_dunning_purpose_set := TRUE;
            END IF;
         ELSE                                     -- this is the eBill contact
            contact_point_rec.contact_point_purpose := 'BILLING';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
         END IF;

         phone_rec.phone_line_type := 'FAX';
                           -- validated against AR lookup type PHONE_LINE_TYPE
         format_raw_phone
                  (p_raw_phone_in                  => p_fax_number,
                   p_raw_phone_out                 => phone_rec.raw_phone_number,
                   p_default_country_code_out      => phone_rec.phone_country_code,
                   p_phone_extension_out           => phone_rec.phone_extension
                  );
         wrtdbg
            (dbg_med,
             'About to call hz_contact_point_v2pub.create_phone_contact_point for FAX:'
            );
         wrtdbg (dbg_med,
                    '       contact_point_type = '
                 || getval (contact_point_rec.contact_point_type)
                );
         wrtdbg (dbg_med,
                    '          phone_line_type = '
                 || getval (phone_rec.phone_line_type)
                );
         wrtdbg (dbg_med,
                    '    contact_point_purpose = '
                 || getval (contact_point_rec.contact_point_purpose)
                );
         wrtdbg (dbg_med,
                    '                 orig_sys = '
                 || getval (contact_point_rec.orig_system)
                );
         wrtdbg (dbg_med,
                    '             orig_sys_ref = '
                 || getval (contact_point_rec.orig_system_reference)
                );
         wrtdbg (dbg_med,
                    '             country_code = '
                 || getval (phone_rec.phone_country_code)
                );
         wrtdbg (dbg_med,
                    '         raw_phone_number = '
                 || getval (phone_rec.raw_phone_number)
                );
         wrtdbg (dbg_med,
                    '                extension = '
                 || getval (phone_rec.phone_extension)
                );
         hz_contact_point_v2pub.create_phone_contact_point
                                    (p_init_msg_list          => fnd_api.g_true,
                                     p_contact_point_rec      => contact_point_rec,
                                     p_phone_rec              => phone_rec,
                                     x_contact_point_id       => x_contact_point_id,
                                     x_return_status          => x_return_status,
                                     x_msg_count              => x_msg_count,
                                     x_msg_data               => x_msg_data
                                    );

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            p_fax_contact_point_id := x_contact_point_id;
         ELSE
            decode_api_error
               (p_proc               => l_proc,
                p_call               => 'hz_contact_point_v2pub.create_phone_contact_point(FAX)',
                p_return_status      => x_return_status,
                p_msg_count          => x_msg_count,
                p_msg_data           => x_msg_data,
                p_addtl_info         =>    'PHONE: p_party_id='
                                        || getval (p_party_id)
                                        || ' phone='
                                        || getval (p_phone_number),
                p_msg                => p_msg
               );
            RETURN;
         END IF;
      END IF;

      --
      -- Create PHONE contact point
      --
      IF (p_phone_number IS NOT NULL)
      THEN
         contact_point_rec := NULL;
         phone_rec := NULL;
         p_phone_osr :=
               phone_contact_point_osr_prefix
            || p_sfdc_account_osr
            || l_osr_suffix;
         contact_point_rec.contact_point_type := 'PHONE';
                    -- value from ar_lookups, lookup_type = COMMUNICATION_TYPE
         contact_point_rec.owner_table_name := 'HZ_PARTIES';
                                               -- could also be HZ_PARTY_SITES
         contact_point_rec.owner_table_id := p_party_id;
                                                     -- FK of owner_table_name
         contact_point_rec.created_by_module := our_module_name;
         contact_point_rec.orig_system := sfdc_orig_system;
         contact_point_rec.orig_system_reference := p_phone_osr || xx_crm_sfdc_contacts_s.NEXTVAL;
         contact_point_rec.status := 'A';

         --contact_point_rec.primary_flag          :=
         --contact_point_rec.application_id        :=
         IF (p_contact_role = g_ap_contact_role)
         THEN
            IF (l_dunning_purpose_set)
            THEN
               contact_point_rec.contact_point_purpose := 'COLLECTIONS';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
            ELSE
               contact_point_rec.contact_point_purpose := 'DUNNING';
               l_dunning_purpose_set := TRUE;
            END IF;
         ELSE                                     -- this is the eBill contact
            contact_point_rec.contact_point_purpose := 'BILLING';
                -- value from ar_lookups, lookup_type = CONTACT_POINT_PURPOSE
         END IF;

         phone_rec.phone_line_type := 'GEN';
                           -- validated against AR lookup type PHONE_LINE_TYPE
         format_raw_phone
                  (p_raw_phone_in                  => p_phone_number,
                   p_raw_phone_out                 => phone_rec.raw_phone_number,
                   p_default_country_code_out      => phone_rec.phone_country_code,
                   p_phone_extension_out           => phone_rec.phone_extension
                  );
         wrtdbg
            (dbg_med,
             'About to call hz_contact_point_v2pub.create_phone_contact_point for GEN:'
            );
         wrtdbg (dbg_med,
                    '       contact_point_type = '
                 || getval (contact_point_rec.contact_point_type)
                );
         wrtdbg (dbg_med,
                    '          phone_line_type = '
                 || getval (phone_rec.phone_line_type)
                );
         wrtdbg (dbg_med,
                    '    contact_point_purpose = '
                 || getval (contact_point_rec.contact_point_purpose)
                );
         wrtdbg (dbg_med,
                    '                 orig_sys = '
                 || getval (contact_point_rec.orig_system)
                );
         wrtdbg (dbg_med,
                    '             orig_sys_ref = '
                 || getval (contact_point_rec.orig_system_reference)
                );
         wrtdbg (dbg_med,
                    '             country_code = '
                 || getval (phone_rec.phone_country_code)
                );
         wrtdbg (dbg_med,
                    '         raw_phone_number = '
                 || getval (phone_rec.raw_phone_number)
                );
         wrtdbg (dbg_med,
                    '                extension = '
                 || getval (phone_rec.phone_extension)
                );
         hz_contact_point_v2pub.create_phone_contact_point
                                    (p_init_msg_list          => fnd_api.g_true,
                                     p_contact_point_rec      => contact_point_rec,
                                     p_phone_rec              => phone_rec,
                                     x_contact_point_id       => x_contact_point_id,
                                     x_return_status          => x_return_status,
                                     x_msg_count              => x_msg_count,
                                     x_msg_data               => x_msg_data
                                    );

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            p_phone_contact_point_id := x_contact_point_id;
         ELSE
            decode_api_error
               (p_proc               => l_proc,
                p_call               => 'hz_contact_point_v2pub.create_phone_contact_point(GEN)',
                p_return_status      => x_return_status,
                p_msg_count          => x_msg_count,
                p_msg_data           => x_msg_data,
                p_addtl_info         =>    'PHONE: p_party_id='
                                        || getval (p_party_id)
                                        || ' phone='
                                        || getval (p_phone_number),
                p_msg                => p_msg
               );
            RETURN;
         END IF;
      END IF;

      wrtdbg (dbg_med, 'About to exit ' || l_proc);
      wrtdbg (dbg_med,
                 '    p_phone_contact_point_id = '
              || getval (p_phone_contact_point_id)
             );
      wrtdbg (dbg_med,
                 '      p_fax_contact_point_id = '
              || getval (p_fax_contact_point_id)
             );
      wrtdbg (dbg_med,
                 '    p_email_contact_point_id = '
              || getval (p_email_contact_point_id)
             );
      wrtdbg (dbg_med, 'Exit ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END create_contact_points;

-- ===========================================================================

   ------------------------------------------------------------------------------
   FUNCTION get_billto_acct_site (
      p_cust_account_id    IN       NUMBER,
      p_cust_account_num   IN       VARCHAR2,
      p_msg                OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
------------------------------------------------------------------------------
      l_proc                VARCHAR2 (80)  := 'get_billto_acct_site';
      l_ctx                 VARCHAR2 (200) := NULL;
      l_cust_acct_site_id   NUMBER         := NULL;

      CURSOR c_site_info (c_cust_account_id NUMBER)
      IS
         --
         -- The AOPS site with the OSR nnnnnnnn-00001-AO should be the only bill-to site.
         -- Just in case more than one bill-to site exists, we use "order by" to attempt
         -- to fetch site 00001.
         --
         SELECT   cas.cust_acct_site_id
             FROM hz_cust_acct_sites cas, hz_cust_site_uses csu
            WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
              AND csu.site_use_code = 'BILL_TO'
              AND cas.status = 'A'
              AND csu.status = 'A'
              AND cas.cust_account_id = c_cust_account_id
         ORDER BY cas.orig_system_reference;
   BEGIN
      l_ctx :=
         'open c_site_info - p_cust_account_id='
         || getval (p_cust_account_id);

      OPEN c_site_info (p_cust_account_id);

      l_ctx :=
            'fetch c_site_info - p_cust_account_id='
         || getval (p_cust_account_id);

      FETCH c_site_info
       INTO l_cust_acct_site_id;

      l_ctx :=
         'close c_site_info - p_cust_account_id='
         || getval (p_cust_account_id);

      CLOSE c_site_info;

      IF (l_cust_acct_site_id IS NULL)
      THEN
         l_cust_acct_site_id := -1;
         p_msg :=
               'Bill-To site not found for customer number '
            || getval (p_cust_account_num);
      END IF;

      RETURN (l_cust_acct_site_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
         RETURN (-1);
   END get_billto_acct_site;

-- ===========================================================================

   ------------------------------------------------------------------------------
   PROCEDURE create_one_contact (
      p_party_id            IN              VARCHAR2,
      p_cust_account_id     IN              NUMBER,
      p_cust_account_num    IN              VARCHAR2,
      p_cust_acct_site_id   IN              NUMBER,
      p_sfdc_account_osr    IN              VARCHAR2,
      p_contact_role        IN              VARCHAR2,
      p_salutation          IN              VARCHAR2,
      p_first_name          IN              VARCHAR2,
      p_last_name           IN              VARCHAR2,
      p_job_title           IN              VARCHAR2,
      p_phone_number        IN              VARCHAR2,
      p_fax_number          IN              VARCHAR2,
      p_email_addr          IN              VARCHAR2,
      p_primary_flag        IN              VARCHAR2,
      -- output parameters
      p_org_contact_id      OUT             NUMBER,
      p_person_party_osr    OUT             VARCHAR2,
      p_email_osr           OUT             VARCHAR2,
      p_phone_osr           OUT             VARCHAR2,
      p_fax_osr             OUT             VARCHAR2,
      p_warnings            IN OUT NOCOPY   VARCHAR2,
      p_msg                 OUT             VARCHAR2
   )
   IS
------------------------------------------------------------------------------
      l_proc                     VARCHAR2 (80)        := 'create_one_contact';
      l_ctx                      VARCHAR2 (200)                       := NULL;
      x_return_status            VARCHAR2 (1);
      x_msg_count                NUMBER;
      x_msg_data                 VARCHAR2 (2000);
      x_person_party_id          NUMBER;
      x_person_party_number      hz_parties.party_number%TYPE;
      x_person_profile_id        NUMBER;
      x_cust_acct_role_id        NUMBER;
      x_cust_acct_role_resp_id   NUMBER;
      l_phone_contact_point_id   NUMBER;
      l_fax_contact_point_id     NUMBER;
      l_email_contact_point_id   NUMBER;
      l_job_title                hz_org_contacts.job_title%TYPE;
      l_salutation_code          ar_lookups.lookup_code%TYPE;
      l_relationship_type        VARCHAR2 (20);
      l_relationship_code        VARCHAR2 (20);
      x_contact_id               NUMBER;
      x_party_relationship_id    NUMBER;
      x_contact_party_id         NUMBER;
      x_contact_party_number     hz_parties.party_number%TYPE;
      person_rec                 hz_party_v2pub.person_rec_type;
      org_contact_rec            hz_party_contact_v2pub.org_contact_rec_type;
      acct_role_rec              hz_cust_account_role_v2pub.cust_account_role_rec_type;
      acct_role_resp_rec         hz_cust_account_role_v2pub.role_responsibility_rec_type;
      l_person_party             NUMBER                                  := 0;
	  ln_count                   NUMBER                                  := 0;
   BEGIN
      wrtdbg (dbg_med, 'Enter ' || l_proc);
      wrtdbg (dbg_med,
              '   p_cust_account_id = ' || getval (p_cust_account_id)
             );
      wrtdbg (dbg_med,
              '  p_cust_account_num = ' || getval (p_cust_account_num)
             );
      wrtdbg (dbg_med,
              ' p_cust_acct_site_id = ' || getval (p_cust_acct_site_id)
             );
      wrtdbg (dbg_med, '      p_contact_role = ' || getval (p_contact_role));
      wrtdbg (dbg_med, '         p_job_title = ' || getval (p_job_title));
      wrtdbg (dbg_med,
              '         p_primary_flag = ' || getval (p_primary_flag));

      --
      -- If this is eBill cojntact, use Job title requested.
      -- If this is AP contact, Job Title must be set to "AP".
      --
      IF (p_contact_role = g_ap_contact_role)
      THEN
         p_person_party_osr := p_sfdc_account_osr || ap_contact_osr_suffix;
         l_job_title := 'AP';
         l_relationship_type := 'COLLECTIONS';
                      -- allows contact to be displayed in Collections screen
         l_relationship_code := 'COLLECTIONS_OF';
                      -- allows contact to be displayed in Collections screen
      ELSE
         p_person_party_osr := p_sfdc_account_osr || ebill_contact_osr_suffix || xx_crm_sfdc_contacts_s.NEXTVAL;
         l_job_title := p_job_title;
         l_relationship_type := 'CONTACT';
         l_relationship_code := 'CONTACT_OF';
      END IF;

      wrtdbg (dbg_med,
              '  p_person_party_osr = ' || getval (p_person_party_osr)
             );

      --
      -- Use salutation only if it is valid.
      -- Our interface table has the lookup meaning (i.e. Mr.) but we need to supply the lookup_code value (i.e. MR.).
      --
      IF (p_salutation IS NOT NULL)
      THEN
         BEGIN
            l_ctx := 'select from ar_lookups';

            SELECT lookup_code
              INTO l_salutation_code
              FROM ar_lookups
             WHERE lookup_type = 'CONTACT_TITLE'
               AND enabled_flag = 'Y'
               AND TRUNC (SYSDATE) BETWEEN start_date_active
                                       AND NVL (end_date_active, SYSDATE + 1)
               AND UPPER (meaning) = UPPER (p_salutation);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_salutation_code := NULL;
         END;

         wrtdbg (dbg_med,
                 '    l_salutation_code = ' || getval (l_salutation_code)
                );
         person_rec.person_pre_name_adjunct := l_salutation_code;

         IF (l_salutation_code IS NULL)
         THEN
            add_to_warnings (p_warnings,
                                'Salutation "'
                             || getval (p_salutation)
                             || '" not valid in Ebiz and will be ignored.'
                            );
         END IF;
      END IF;

      l_person_party := -1;

      BEGIN
         SELECT party_id
           INTO l_person_party
           FROM hz_parties
          WHERE orig_system_reference = p_person_party_osr;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_person_party := -1;
      END;

      wrtdbg (dbg_med,
              '  checking if person party exists = ' || l_person_party
             );

      IF l_person_party = -1
      THEN
         wrtdbg (dbg_med, '  Creating person...');
         --
         -- Create person party for the contact
         --
         l_ctx := 'create_person';
         person_rec.created_by_module := our_module_name;
         person_rec.person_first_name := p_first_name;
         person_rec.person_last_name := p_last_name;
         person_rec.party_rec.orig_system := sfdc_orig_system;
         person_rec.party_rec.orig_system_reference := p_person_party_osr;
         hz_party_v2pub.create_person
                                    (p_init_msg_list      => fnd_api.g_true,
                                     p_person_rec         => person_rec,
                                     x_party_id           => x_person_party_id,
                                     x_party_number       => x_person_party_number,
                                     x_profile_id         => x_person_profile_id,
                                     x_return_status      => x_return_status,
                                     x_msg_count          => x_msg_count,
                                     x_msg_data           => x_msg_data
                                    );

         IF (x_return_status != fnd_api.g_ret_sts_success)
         THEN
            decode_api_error (p_proc               => l_proc,
                              p_call               => 'hz_party_v2pub.create_person',
                              p_return_status      => x_return_status,
                              p_msg_count          => x_msg_count,
                              p_msg_data           => x_msg_data,
                              p_addtl_info         =>    'p_sfdc_account_osr='
                                                      || getval
                                                            (p_sfdc_account_osr
                                                            ),
                              p_msg                => p_msg
                             );
            RETURN;
         END IF;

         --
         -- Associate the new person party (contact) with the organization party
         --
         l_ctx := 'create_org_contact';
         org_contact_rec.created_by_module := our_module_name;
         org_contact_rec.orig_system := sfdc_orig_system;
         org_contact_rec.orig_system_reference := p_person_party_osr;
         org_contact_rec.job_title := l_job_title;
         org_contact_rec.party_rel_rec.subject_id := x_person_party_id;
         org_contact_rec.party_rel_rec.subject_type := 'PERSON';
         org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
         org_contact_rec.party_rel_rec.object_id := p_party_id;
         org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
         org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
         org_contact_rec.party_rel_rec.relationship_code :=
                                                           l_relationship_code;
         org_contact_rec.party_rel_rec.relationship_type :=
                                                           l_relationship_type;
         org_contact_rec.party_rel_rec.status := 'A';
         org_contact_rec.party_rel_rec.created_by_module := our_module_name;
         org_contact_rec.party_rel_rec.attribute20 := NULL;
                                 -- Import batch id (not used by this program)
         -- org_contact_rec.party_rel_rec.start_date         := sysdate;   -- commented out;  defaults to current date / time
         hz_party_contact_v2pub.create_org_contact
            (p_init_msg_list        => fnd_api.g_true,
             p_org_contact_rec      => org_contact_rec,
             x_org_contact_id       => x_contact_id,
             x_party_rel_id         => x_party_relationship_id,
                                           -- hz_relationships.relationship_id
             x_party_id             => x_contact_party_id,
                                          -- relationship record in hz_parties
             x_party_number         => x_contact_party_number,
             x_return_status        => x_return_status,
             x_msg_count            => x_msg_count,
             x_msg_data             => x_msg_data
            );

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            p_org_contact_id := x_contact_id;
         ELSE
            decode_api_error
                      (p_proc               => l_proc,
                       p_call               => 'hz_party_contact_v2pub.create_org_contact',
                       p_return_status      => x_return_status,
                       p_msg_count          => x_msg_count,
                       p_msg_data           => x_msg_data,
                       p_addtl_info         =>    'p_sfdc_account_osr='
                                               || getval (p_sfdc_account_osr),
                       p_msg                => p_msg
                      );
            RETURN;
         END IF;
      ELSE
         wrtdbg (dbg_med, '  assigning l_person_party to x_contact_party_id');
         x_contact_party_id := l_person_party;
      END IF;

      wrtdbg (dbg_med, '  creating contact role');
      --
      -- Create the contact role for the customer account
      --
      acct_role_rec.created_by_module := our_module_name;
      acct_role_rec.orig_system := sfdc_orig_system;
      acct_role_rec.orig_system_reference := p_person_party_osr;
      acct_role_rec.party_id := x_contact_party_id;
     -- this is the relationship party w/ name = contact person + company name
      acct_role_rec.cust_account_id := p_cust_account_id;
      acct_role_rec.cust_acct_site_id := p_cust_acct_site_id;
           -- should be null for eBill contact and have a value for AP contact
      acct_role_rec.role_type := 'CONTACT';
                   -- validated from ar_lookups.lookup_type = 'ACCT_ROLE_TYPE'
      /*Modified for Defect35086 */
	  /*  ln_count:=0;
		  BEGIN
			SELECT COUNT(*)
			INTO ln_count
			FROM xx_crm_sfdc_contacts
			WHERE contact_role =g_ebill_contact_role
			AND cust_account_id=p_cust_account_id;
		  EXCEPTION
		  WHEN OTHERS THEN
			ln_count:=0;
		  END;
		  IF ln_count                   > 1 THEN 
			acct_role_rec.primary_flag := p_primary_flag;
		  ELSE
			acct_role_rec.primary_flag := NULL;
		  END IF; */
		  --   acct_role_rec.primary_flag := p_primary_flag;
		 /*End - Modified for Defect35086 */  
      -- acct_role_rec.status                :=
      -- acct_role_rec.application_id        :=
	  acct_role_rec.primary_flag := NULL;
      hz_cust_account_role_v2pub.create_cust_account_role
                               (p_init_msg_list              => fnd_api.g_true,
                                p_cust_account_role_rec      => acct_role_rec,
                                x_cust_account_role_id       => x_cust_acct_role_id,
                                x_return_status              => x_return_status,
                                x_msg_count                  => x_msg_count,
                                x_msg_data                   => x_msg_data
                               );

      IF (x_return_status = fnd_api.g_ret_sts_success)
      THEN
         NULL;
      ELSE
         decode_api_error
            (p_proc               => l_proc,
             p_call               => 'hz_cust_account_role_v2pub.create_cust_account_role',
             p_return_status      => x_return_status,
             p_msg_count          => x_msg_count,
             p_msg_data           => x_msg_data,
             p_addtl_info         =>    'p_sfdc_account_osr='
                                     || getval (p_sfdc_account_osr),
             p_msg                => p_msg
            );
         RETURN;
      END IF;

      --
      -- Create the contact role responsibility for the customer account
      --
      acct_role_resp_rec.created_by_module := our_module_name;
      acct_role_resp_rec.orig_system_reference := p_person_party_osr;
      acct_role_resp_rec.cust_account_role_id := x_cust_acct_role_id;
      acct_role_resp_rec.primary_flag := 'Y';

      IF (p_contact_role = g_ap_contact_role)
      THEN
         acct_role_resp_rec.responsibility_type := 'DUN';
                   -- validated from ar_lookups.lookup_type = 'SITE_USE_CODE'
      ELSE                                        -- this is the eBill contact
         acct_role_resp_rec.responsibility_type := 'BILLING';
	 acct_role_resp_rec.primary_flag := NVL(p_primary_flag,'N'); 
                   -- validated from ar_lookups.lookup_type = 'SITE_USE_CODE'
      END IF;

      --acct_role_resp_rec.application_id
      hz_cust_account_role_v2pub.create_role_responsibility
                             (p_init_msg_list                => fnd_api.g_true,
                              p_role_responsibility_rec      => acct_role_resp_rec,
                              x_responsibility_id            => x_cust_acct_role_resp_id,
                              x_return_status                => x_return_status,
                              x_msg_count                    => x_msg_count,
                              x_msg_data                     => x_msg_data
                             );

      IF (x_return_status = fnd_api.g_ret_sts_success)
      THEN
         NULL;
      ELSE
         decode_api_error
            (p_proc               => l_proc,
             p_call               => 'hz_cust_account_role_v2pub.create_role_responsibility',
             p_return_status      => x_return_status,
             p_msg_count          => x_msg_count,
             p_msg_data           => x_msg_data,
             p_addtl_info         =>    'p_sfdc_account_osr='
                                     || getval (p_sfdc_account_osr),
             p_msg                => p_msg
            );
         RETURN;
      END IF;

      wrtdbg (dbg_med,
              '          x_person_party_id = ' || getval (x_person_party_id)
             );
      wrtdbg (dbg_med,
                 '      x_person_party_number = '
              || getval (x_person_party_number)
             );
      wrtdbg (dbg_med,
              '        x_person_profile_id = ' || getval (x_person_profile_id)
             );
      wrtdbg (dbg_med,
              '               x_contact_id = ' || getval (x_contact_id)
             );
      wrtdbg (dbg_med,
                 '    x_party_relationship_id = '
              || getval (x_party_relationship_id)
             );
      wrtdbg (dbg_med,
              '         x_contact_party_id = ' || getval (x_contact_party_id)
             );
      wrtdbg (dbg_med,
                 '     x_contact_party_number = '
              || getval (x_contact_party_number)
             );
      wrtdbg (dbg_med,
              '        x_cust_acct_role_id = ' || getval (x_cust_acct_role_id)
             );
      wrtdbg (dbg_med,
                 '   x_cust_acct_role_resp_id = '
              || getval (x_cust_acct_role_resp_id)
             );
      wrtdbg (dbg_med,
              '         p_person_party_osr = ' || getval (p_person_party_osr)
             );
      --
      -- Create the contact points for the relationship party, not the person party.
      -- This is because the contact person doesn't own the phone # and email addr.
      -- The contat person has these contact points only because of their relationship
      -- with the organization party.
      --
      -- Note: x_contact_party_id: this is the party with the name org-person with party_type = "PARTY_RELATIONSHIP
      --
      create_contact_points
                        (p_party_id                    => x_contact_party_id,
                         p_sfdc_account_osr            => p_sfdc_account_osr,
                         p_contact_role                => p_contact_role,
                         p_phone_number                => p_phone_number,
                         p_fax_number                  => p_fax_number,
                         p_email_addr                  => p_email_addr,
                         p_phone_contact_point_id      => l_phone_contact_point_id,
                         p_fax_contact_point_id        => l_fax_contact_point_id,
                         p_email_contact_point_id      => l_email_contact_point_id,
                         p_email_osr                   => p_email_osr,
                         p_phone_osr                   => p_phone_osr,
                         p_fax_osr                     => p_fax_osr,
                         p_msg                         => p_msg
                        );

      IF (p_msg IS NOT NULL)
      THEN
         RETURN;
      END IF;

      wrtdbg (dbg_med,
              '                p_email_osr = ' || getval (p_email_osr)
             );
      wrtdbg (dbg_med,
              '                p_phone_osr = ' || getval (p_phone_osr)
             );
      wrtdbg (dbg_med, '                  p_fax_osr = ' || getval (p_fax_osr));
      wrtdbg (dbg_med, 'Exit ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END create_one_contact;

-- ============================================================================

   ------------------------------------------------------------------------------
   PROCEDURE write_report_header
   IS
------------------------------------------------------------------------------
   BEGIN
      wrtall (' ');
      wrtall (' ');
      wrtall ('Customer                          Contact');
      wrtall
         ('Number   Customer Name            Type    Name                     Email                     Phone           Fax             Status'
         );
      wrtall
         ('-------- ------------------------ ------- ------------------------ ------------------------- --------------- --------------- -------'
         );
   END write_report_header;

-- ============================================================================

   ------------------------------------------------------------------------------
   PROCEDURE report_contact_result (
      p_count               IN   NUMBER,
      p_cust_account_num    IN   VARCHAR2,
      p_cust_account_name   IN   VARCHAR2,
      p_contact_role        IN   VARCHAR2,
      p_first_name          IN   VARCHAR2,
      p_last_name           IN   VARCHAR2,
      p_phone_number        IN   VARCHAR2,
      p_fax_number          IN   VARCHAR2,
      p_email_addr          IN   VARCHAR2,
      p_status              IN   VARCHAR2
   )
   IS
------------------------------------------------------------------------------
      l_proc           VARCHAR2 (80)  := 'report_contact_result';
      l_ctx            VARCHAR2 (200) := NULL;
      l_contact_name   VARCHAR2 (100);
      l_contact_type   VARCHAR2 (50);
   BEGIN
      IF (p_contact_role = g_ap_contact_role)
      THEN
         l_contact_type := 'AP';
      ELSIF (p_contact_role = g_ebill_contact_role)
      THEN
         l_contact_type := 'eBill';
      ELSE
         l_contact_type := p_contact_role;
      END IF;

      l_contact_name := RTRIM (p_first_name || ' ' || p_last_name);
             -- if both first and last are null, rtrim will set result to null
      wrtall (   RPAD (getval2 (p_cust_account_num), 8)
              || ' '
              || RPAD (getval2 (p_cust_account_name), 24)
              || ' '
              || RPAD (getval2 (l_contact_type), 7)
              || ' '
              || RPAD (getval2 (l_contact_name), 24)
              || ' '
              || RPAD (getval2 (p_email_addr), 25)
              || ' '
              || RPAD (getval2 (p_phone_number), 15)
              || ' '
              || RPAD (getval2 (p_fax_number), 15)
              || ' '
              || getval2 (INITCAP (p_status))
             );
   END report_contact_result;

-- ============================================================================

   ------------------------------------------------------------------------------
   PROCEDURE create_contacts (p_rdy_for_import_ct IN NUMBER, p_msg OUT VARCHAR2)
   IS
-------------------------------------------------------------------------------
      l_proc                  VARCHAR2 (80)              := 'create_contacts';
      l_ctx                   VARCHAR2 (200)                          := NULL;
      l_fetch_ct              NUMBER                                     := 0;
      l_warnings              VARCHAR2 (2000);
      l_error                 VARCHAR2 (2000);
      l_import_status         VARCHAR2 (10);
      l_contact_role          VARCHAR2 (50);
      l_contact_site_id       NUMBER;
      l_billto_acct_site_id   NUMBER;
      l_person_party_id       NUMBER;
      l_org_contact_id        NUMBER;
      l_cust_account_id       NUMBER;
      l_cust_account_num      hz_cust_accounts.account_number%TYPE;
      l_cust_account_name     hz_parties.party_name%TYPE;
      l_cust_ab_flag          hz_customer_profiles.attribute3%TYPE;
                                        -- customer "AB" account billing flag
      l_person_party_osr      hz_parties.orig_system_reference%TYPE;
      l_email_osr             hz_contact_points.orig_system_reference%TYPE;
      l_phone_osr             hz_contact_points.orig_system_reference%TYPE;
      l_fax_osr               hz_contact_points.orig_system_reference%TYPE;
      sfdc_rec3               c_find_contacts3%ROWTYPE;

      CURSOR cust_profs (p_acct_id NUMBER)
      IS
         SELECT cust_account_profile_id, object_version_number
           FROM hz_customer_profiles
          WHERE cust_account_id = p_acct_id
            AND (   NVL (cons_inv_flag, 'N') <> 'Y'
                 OR NVL (cons_inv_type, 'XX') <> 'DETAIL'
                );

      l_prof_rec              hz_customer_profile_v2pub.customer_profile_rec_type;
      l_con_exists            NUMBER;
      x_ret_status            VARCHAR2 (50);
      x_m_data                VARCHAR2 (2000);
      x_m_count               NUMBER;
   BEGIN
      wrtdbg (dbg_med, 'Enter ' || l_proc);
      l_ctx := 'open c_find_contacts3';

      OPEN c_find_contacts3;

      write_report_header;

      LOOP
         SAVEPOINT save01;

         FETCH c_find_contacts3
          INTO sfdc_rec3;

         EXIT WHEN c_find_contacts3%NOTFOUND;
         l_fetch_ct := l_fetch_ct + 1;
         l_warnings := NULL;
         l_error := NULL;
         l_billto_acct_site_id := NULL;
         l_person_party_osr := NULL;
         l_email_osr := NULL;
         l_phone_osr := NULL;
         l_fax_osr := NULL;
         wrtdbg (dbg_hi, 'xx_crm_sfdc_contacts l_fetch_ct:' || l_fetch_ct);
         wrtdbg (dbg_hi,
                 '                       id = ' || getval (sfdc_rec3.ID)
                );
         wrtdbg (dbg_hi,
                    '          sfdc_account_id = '
                 || getval (sfdc_rec3.sfdc_account_id)
                );
         wrtdbg (dbg_hi,
                 '                 party_id = ' || getval (sfdc_rec3.party_id)
                );
         wrtdbg (dbg_hi,
                    '             contact_role = '
                 || getval (sfdc_rec3.contact_role)
                );
         wrtdbg (dbg_hi,
                    '       contact_salutation = '
                 || getval (sfdc_rec3.contact_salutation)
                );
         wrtdbg (dbg_hi,
                    '       contact_first_name = '
                 || getval (sfdc_rec3.contact_first_name)
                );
         wrtdbg (dbg_hi,
                    '        contact_last_name = '
                 || getval (sfdc_rec3.contact_last_name)
                );
         wrtdbg (dbg_hi,
                    '        contact_job_title = '
                 || getval (sfdc_rec3.contact_job_title)
                );
         wrtdbg (dbg_hi,
                    '     contact_phone_number = '
                 || getval (sfdc_rec3.contact_phone_number)
                );
         wrtdbg (dbg_hi,
                    '       contact_fax_number = '
                 || getval (sfdc_rec3.contact_fax_number)
                );
         wrtdbg (dbg_hi,
                    '       contact_email_addr = '
                 || getval (sfdc_rec3.contact_email_addr)
                );
         wrtdbg (dbg_hi,
                    '       primary_contact_flag = '
                 || getval (sfdc_rec3.primary_contact_flag)
                );
         wrtdbg (dbg_hi,
                    '            creation_date = '
                 || getval (sfdc_rec3.creation_date)
                );
         wrtdbg (dbg_hi,
                    '               created_by = '
                 || getval (sfdc_rec3.created_by)
                );
         wrtdbg (dbg_hi,
                    '         last_update_date = '
                 || getval (sfdc_rec3.last_update_date)
                );
         wrtdbg (dbg_hi,
                    '          last_updated_by = '
                 || getval (sfdc_rec3.last_updated_by)
                );
         wrtdbg (dbg_hi,
                    '            import_status = '
                 || getval (sfdc_rec3.import_status)
                );
         wrtdbg (dbg_hi,
                    '             import_error = '
                 || getval (SUBSTR (sfdc_rec3.import_error, 1, 200))
                );
         wrtdbg (dbg_hi,
                    '     import_attempt_count = '
                 || getval (sfdc_rec3.import_attempt_count)
                );
         l_contact_role := UPPER (sfdc_rec3.contact_role);
                                            -- role will not be case sensitive

         IF (   (l_contact_role IS NULL)
             OR (l_contact_role NOT IN
                                    (g_ap_contact_role, g_ebill_contact_role)
                )
            )
         THEN
            p_msg :=
                  'id='
               || getval (sfdc_rec3.ID)
               || ' Found a record with contact role "'
               || getval (l_contact_role)
               || '" but the only roles allowed are: "'
               || g_ap_contact_role
               || '" and "'
               || g_ebill_contact_role
               || '"';
         END IF;

         IF (p_msg IS NULL)
         THEN
            get_cust_account_info
                                 (p_party_id               => sfdc_rec3.party_id,
                                  p_cust_account_id        => l_cust_account_id,
                                  p_cust_account_num       => l_cust_account_num,
                                  p_cust_account_name      => l_cust_account_name,
                                  p_ab_flag                => l_cust_ab_flag,
                                  p_msg                    => p_msg
                                 );
         END IF;

         -- ** Logic To Copy 'Consolidated' to Customer Profile begins **
         BEGIN
            SELECT COUNT (1)
              INTO l_con_exists
              FROM xx_cdh_cust_acct_ext_b
             WHERE attr_group_id =
                      (SELECT attr_group_id
                         FROM ego_attr_groups_v eag
                        WHERE eag.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                          AND eag.attr_group_name = 'BILLDOCS'
                          AND eag.application_id =
                                        (SELECT application_id
                                           FROM fnd_application
                                          WHERE application_short_name = 'AR'))
               AND c_ext_attr1 = 'Consolidated Bill'
               AND cust_account_id = l_cust_account_id;

            IF l_con_exists > 0
            THEN
               FOR l_prof IN cust_profs (l_cust_account_id)
               LOOP
                  l_prof_rec.cons_inv_flag := 'Y';
                  l_prof_rec.cons_inv_type := 'DETAIL';
                  l_prof_rec.cust_account_profile_id :=
                                               l_prof.cust_account_profile_id;
                  hz_customer_profile_v2pub.update_customer_profile
                     (p_init_msg_list              => fnd_api.g_false,
                      p_customer_profile_rec       => l_prof_rec,
                      p_object_version_number      => l_prof.object_version_number,
                      x_return_status              => x_ret_status,
                      x_msg_count                  => x_m_count,
                      x_msg_data                   => x_m_data
                     );

                  IF x_ret_status <> 'S'
                  THEN
                     fnd_file.put_line
                           (fnd_file.LOG,
                               'Consolidated Bill not copied for Account ID:'
                            || l_cust_account_id
                            || ' -- '
                            || x_m_data
                           );
                  END IF;
               END LOOP;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                           (fnd_file.LOG,
                               'Consolidated Bill not copied for Account ID:'
                            || l_cust_account_id
                            || ' -- '
                            || SQLERRM
                           );
         END;

         -- ** Logic To Copy 'Consolidated' to Customer Profile ends **
         IF (p_msg IS NULL)
         THEN
            IF (l_cust_ab_flag != 'Y')
            THEN
               p_msg :=
                     'Cannot create eBill contact because Account Billing (AB) is not set to "Y".  Value="'
                  || getval (l_cust_ab_flag)
                  || '"';
            END IF;
         END IF;

         IF (p_msg IS NULL)
         THEN
            l_billto_acct_site_id :=
               get_billto_acct_site
                                   (p_cust_account_id       => l_cust_account_id,
                                    p_cust_account_num      => l_cust_account_num,
                                    p_msg                   => p_msg
                                   );
         END IF;

         IF (p_msg IS NULL)
         THEN
            --
            -- The AP Contact is associated with the bill-to site.
            -- The eBill contact is associated with the customer account (not at site level).
            --
            IF (l_contact_role = g_ap_contact_role)
            THEN
               l_contact_site_id := l_billto_acct_site_id;
            ELSE
               l_contact_site_id := NULL;
            END IF;
            
            create_one_contact
                          (p_party_id               => sfdc_rec3.party_id,
                           p_cust_account_id        => l_cust_account_id,
                           p_cust_account_num       => l_cust_account_num,
                           p_cust_acct_site_id      => l_contact_site_id,
                           p_sfdc_account_osr       =>    sfdc_rec3.sfdc_account_id
                                                       || contact_osr_suffix,
                           p_contact_role           => l_contact_role,
                           p_salutation             => sfdc_rec3.contact_salutation,
                           p_first_name             => sfdc_rec3.contact_first_name,
                           p_last_name              => sfdc_rec3.contact_last_name,
                           p_job_title              => sfdc_rec3.contact_job_title,
                           p_phone_number           => sfdc_rec3.contact_phone_number,
                           p_fax_number             => sfdc_rec3.contact_fax_number,
                           p_email_addr             => sfdc_rec3.contact_email_addr,
                           p_primary_flag           => sfdc_rec3.primary_contact_flag,
                           -- output parameters
                           p_org_contact_id         => l_org_contact_id,
                           p_person_party_osr       => l_person_party_osr,
                           p_email_osr              => l_email_osr,
                           p_phone_osr              => l_phone_osr,
                           p_fax_osr                => l_fax_osr,
                           p_warnings               => l_warnings,
                           p_msg                    => p_msg
                          );
         END IF;

         IF (p_msg IS NULL)
         THEN
            IF (l_contact_role = g_ebill_contact_role)
            THEN
               link_ebill_contact_to_paydoc
                               (p_cust_account_id        => l_cust_account_id,
                                p_cust_account_num       => l_cust_account_num,
                                p_cust_acct_site_id      => l_billto_acct_site_id,
                                p_org_contact_id         => l_org_contact_id,
                                p_warnings               => l_warnings,
                                p_msg                    => p_msg
                               );
            END IF;
         END IF;

         IF (p_msg IS NOT NULL)
         THEN
            g_error_ct := g_error_ct + 1;
            l_error := p_msg;
            p_msg := NULL;
            l_import_status := imp_sts_error;
            wrtdbg (dbg_med,
                       '*** ROLLBACK TO SAVEPOINT save01 *** l_error='
                    || getval (l_error)
                   );
            ROLLBACK TO save01;
            wrtall (   'Error:   id='
                    || sfdc_rec3.ID
                    || ' party_id='
                    || sfdc_rec3.party_id
                    || ' msg='
                    || l_error
                   );
         ELSE
            l_import_status := imp_sts_imported;
         END IF;

         IF (l_warnings IS NOT NULL)
         THEN
            g_warning_ct := g_warning_ct + 1;
            wrtall (   'Warning: id='
                    || sfdc_rec3.ID
                    || ' party_id='
                    || sfdc_rec3.party_id
                    || ' msg='
                    || l_warnings
                   );
         END IF;

         -- An import warning is a problem that occurred but didn't prevent the contact from being created.
         -- The import_status is set to IMP_STS_IMPORTED.  Example: invalid contact name salutation

         -- An import error is a problem that caused us to rollback the attempt to create the contact.
         -- The import_status is set to IMP_STS_ERROR and the contact was not created.
         l_ctx := 'update xx_crm_sfdc_contacts - id=' || getval (sfdc_rec3.ID);

         UPDATE xx_crm_sfdc_contacts
            SET cust_account_id = l_cust_account_id,
                org_contact_id = l_org_contact_id,
                person_party_osr = l_person_party_osr,
                email_osr = l_email_osr,
                phone_osr = l_phone_osr,
                fax_osr = l_fax_osr,
                import_status = l_import_status,
                import_warnings = l_warnings,
                import_error = l_error,
                import_attempt_count =
                                    NVL (sfdc_rec3.import_attempt_count, 0)
                                    + 1,
                last_update_date = SYSDATE,
                last_updated_by = g_user_id
          WHERE CURRENT OF c_find_contacts3;

         IF (SQL%ROWCOUNT != 1)
         THEN
            p_msg :=
                  'Attempted to update table xx_crm_sfdc_contacts for id='
               || getval (sfdc_rec3.ID)
               || '.  Expected rowcount=1 but actual rowcount='
               || SQL%ROWCOUNT
               || '.';
            RETURN;
         END IF;

         report_contact_result
                            (p_count                  => l_fetch_ct,
                             p_cust_account_num       => l_cust_account_num,
                             p_cust_account_name      => l_cust_account_name,
                             p_contact_role           => l_contact_role,
                             p_first_name             => sfdc_rec3.contact_first_name,
                             p_last_name              => sfdc_rec3.contact_last_name,
                             p_phone_number           => sfdc_rec3.contact_phone_number,
                             p_fax_number             => sfdc_rec3.contact_fax_number,
                             p_email_addr             => sfdc_rec3.contact_email_addr,
                             p_status                 => l_import_status
                            );
      END LOOP;

      l_ctx := 'close c_find_contacts3';

      CLOSE c_find_contacts3;

      IF (l_fetch_ct = 0)
      THEN
         wrtall ('*** No contacts were imported.');
      END IF;

      wrtlog (g_warning_ct || ' warnings were generated');
      wrtlog (g_error_ct || ' errors were generated');
      wrtlog (dti || 'Exit ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END create_contacts;

-- ============================================================================

   -------------------------------------------------------------------------------
   FUNCTION find_contacts_ready_for_import (
      p_timeout_days       IN       NUMBER,
      p_reprocess_errors   IN       VARCHAR2,
      p_msg                OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
-------------------------------------------------------------------------------
      l_proc                      VARCHAR2 (80)
                                          := 'find_contacts_ready_for_import';
      l_ctx                       VARCHAR2 (200)             := NULL;
      l_timeout_days              NUMBER           := NVL (p_timeout_days, 0);
      l_reprocess_errors          VARCHAR2 (1)
                                             := NVL (p_reprocess_errors, 'N');
      l_tmp_error_import_status   VARCHAR2 (50);
      l_fetch_ct                  NUMBER                     := 0;
      l_dt_vc                     VARCHAR2 (25);
      sfdc_rec2                   c_find_contacts2%ROWTYPE;
   BEGIN
      wrtlog (dti || 'Start ' || l_proc || '...');

      IF (l_timeout_days <= 0)
      THEN
         l_timeout_days := 999999;
           -- use a number larger than the earliest possible last_update_date
         wrtall
            ('No time limit has been requested for record selection.  "Timeout Days" parameter was not set to a positive number.'
            );
      ELSE
         l_dt_vc :=
                  TO_CHAR ((TRUNC (SYSDATE) - l_timeout_days), 'DD-MON-YYYY');
         wrtall
            (   'Records will be considered for import that were last updated on or after '
             || l_dt_vc
             || '.'
            );
      END IF;

      IF (l_reprocess_errors = 'Y')
      THEN
         l_tmp_error_import_status := imp_sts_error;
      ELSE
         l_tmp_error_import_status :=
                                    imp_sts_error || '-dont-reporcess-errors';
      END IF;

      l_ctx :=
            'open c_find_contacts2 - c_timneout_days='
         || getval (l_timeout_days)
         || ' l_tmp_error_import_status='
         || getval (l_tmp_error_import_status);
      wrtdbg (dbg_med, l_ctx);

      OPEN c_find_contacts2
                           (c_timneout_days            => l_timeout_days,
                            c_error_import_status      => l_tmp_error_import_status
                           );

      LOOP
         FETCH c_find_contacts2
          INTO sfdc_rec2;

         EXIT WHEN c_find_contacts2%NOTFOUND;
         l_fetch_ct := l_fetch_ct + 1;
         wrtdbg (dbg_hi, 'xx_crm_sfdc_contacts l_fetch_ct:' || l_fetch_ct);
         wrtdbg (dbg_hi,
                 '                      id = ' || getval (sfdc_rec2.ID)
                );
         l_ctx :=
               'update xx_crm_sfdc_contacts - sfdc_rec2.id='
            || getval (sfdc_rec2.ID);

         UPDATE xx_crm_sfdc_contacts
            SET last_update_date = SYSDATE,
                last_updated_by = g_user_id,
                import_status = imp_sts_ready_for_import
          WHERE ID = sfdc_rec2.ID;

         IF (SQL%ROWCOUNT != 1)
         THEN
            p_msg :=
                  l_proc
               || ' ('
               || l_ctx
               || ') expected to update 1 record but actual count = '
               || getval (SQL%ROWCOUNT);
            RETURN (-1);
         END IF;
      END LOOP;

      l_ctx := 'close c_find_contacts2';

      CLOSE c_find_contacts2;

      wrtdbg (dbg_med,
              'Exit ' || l_proc || ' - l_fetch_ct=' || getval (l_fetch_ct)
             );
      wrtlog (dti || 'End ' || l_proc);
      RETURN (l_fetch_ct);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
         RETURN (-1);
   END find_contacts_ready_for_import;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE purge_old_records (p_purge_days IN NUMBER, p_msg OUT VARCHAR2)
   IS
-------------------------------------------------------------------------------
      l_proc    VARCHAR2 (80)  := 'purge_old_records';
      l_ctx     VARCHAR2 (200) := NULL;
      l_dt_vc   VARCHAR2 (25);
   BEGIN
      wrtlog (dti || 'Start ' || l_proc);
      l_dt_vc := TO_CHAR ((TRUNC (SYSDATE) - p_purge_days), 'DD-MON-YYYY');
      wrtall (' ');
      wrtlog
         (   'Records will be purged from interface table that were last updated '
          || l_dt_vc
          || ' or earlier.'
         );
      l_ctx := 'delete from xx_crm_sfdc_contacts';

      DELETE FROM xx_crm_sfdc_contacts
            WHERE last_update_date < (TRUNC (SYSDATE) - p_purge_days);

      wrtlog
            (   SQL%ROWCOUNT
             || ' records were purged from interface table xx_crm_sfdc_contacts.'
            );
      wrtout (   SQL%ROWCOUNT
              || ' records were purged from the interface table.'
             );
      wrtlog (dti || 'End ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END purge_old_records;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE doit (
      p_timeout_days       IN       NUMBER,
      p_purge_days         IN       NUMBER,
      p_reprocess_errors   IN       VARCHAR2,
      p_msg                OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
      l_proc                VARCHAR2 (80)  := 'doit';
      l_ctx                 VARCHAR2 (200) := NULL;
      l_rdy_for_import_ct   NUMBER;
   BEGIN
      wrtdbg (dbg_med, 'Start ' || l_proc);
      l_rdy_for_import_ct :=
         find_contacts_ready_for_import
                                   (p_timeout_days          => p_timeout_days,
                                    p_reprocess_errors      => p_reprocess_errors,
                                    p_msg                   => p_msg
                                   );

      IF (p_msg IS NULL)
      THEN
         IF (g_commit)
         THEN
            l_ctx := 'commit';
            COMMIT;
         END IF;

         -- Even if we didnt find any contacts to import in find_contacts_ready_for_import
         -- we still call create_contacts in case some were left in the PENDING status due
         -- to an error the last time the program ran.
         --
         create_contacts (p_rdy_for_import_ct      => l_rdy_for_import_ct,
                          p_msg                    => p_msg
                         );
      END IF;

      IF (p_msg IS NULL)
      THEN
         IF (NVL (p_purge_days, 0) > 0)
         THEN
            purge_old_records (p_purge_days => p_purge_days, p_msg => p_msg);
         ELSE
            wrtall ('*** Purge of old interface records not requested ***');
         END IF;
      END IF;

      --
      -- Uncomment code below to force program to end with a Warning (assuming an error does not occur)
      --
      -- g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'End ' || l_proc);
      wrtdbg (dbg_med, 'Exit ' || l_proc);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msg :=
               l_proc
            || ' ('
            || l_ctx
            || ') SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
   END doit;

-- ============================================================================

   -------------------------------------------------------------------------------
   PROCEDURE do_main (
      errbuf               OUT      VARCHAR2,
      retcode              OUT      NUMBER,
      p_ap_role            IN       VARCHAR2,
      p_ebill_role         IN       VARCHAR2,
      p_timeout_days       IN       NUMBER DEFAULT 90,
      p_purge_days         IN       NUMBER DEFAULT 365,
      p_reprocess_errors   IN       VARCHAR2 DEFAULT 'N',
      p_commit_flag        IN       VARCHAR2 DEFAULT 'Y',
      p_debug_level        IN       NUMBER DEFAULT 0,
      p_sql_trace          IN       VARCHAR2 DEFAULT 'N'
   )
   IS
-------------------------------------------------------------------------------
      l_proc        VARCHAR2 (80)   := 'do_main';
      l_ctx         VARCHAR2 (200)  := NULL;
      l_error_msg   VARCHAR2 (2000) := NULL;
      l_msg         VARCHAR2 (500);
      l_fnd_rtn     BOOLEAN;
   BEGIN
--  dbms_profiler.start_profiler (G_PACKAGE); -- DEBUG ONLY ////////
      initialize (p_commit_flag      => p_commit_flag,
                  p_debug_level      => p_debug_level,
                  p_sql_trace        => p_sql_trace,
                  p_msg              => l_msg
                 );
      --
      -- This must be after "initialize" so we know whether wrtlog
      -- goes to stdout or the concurrent log.
      --
      wrtlog ('.');
      wrtlog (dti || 'Parameters for package ' || g_package || ':');
      wrtlog (dti || '             p_ap_role = ' || getval (p_ap_role));
      wrtlog (dti || '          p_ebill_role = ' || getval (p_ebill_role));
      wrtlog (dti || '        p_timeout_days = ' || getval (p_timeout_days));
      wrtlog (dti || '          p_purge_days = ' || getval (p_purge_days));
      wrtlog (dti || '    p_reprocess_errors = '
              || getval (p_reprocess_errors)
             );
      wrtlog (dti || '         p_commit_flag = ' || getval (p_commit_flag));
      wrtlog (dti || '         p_debug_level = ' || getval (p_debug_level));
      wrtlog (dti || '           p_sql_trace = ' || getval (p_sql_trace));
      wrtlog ('.');
      wrtdbg (dbg_low, dti || 'Enter ' || l_proc);

      IF (p_ap_role IS NULL)
      THEN
         l_msg := 'p_ap_role parameter must be provided but it was null.';
      END IF;

      IF (l_msg IS NULL)
      THEN
         IF (p_ebill_role IS NULL)
         THEN
            l_msg :=
                   'p_ebill_role parameter must be provided but it was null.';
         END IF;
      END IF;

      IF (l_msg IS NULL)
      THEN
         g_ap_contact_role := UPPER (p_ap_role);
         g_ebill_contact_role := UPPER (p_ebill_role);
         doit (p_timeout_days          => p_timeout_days,
               p_purge_days            => p_purge_days,
               p_reprocess_errors      => p_reprocess_errors,
               p_msg                   => l_msg
              );
      END IF;

      IF (l_msg IS NOT NULL)
      THEN
         l_error_msg := 'ERROR: ' || l_msg;
         wrtall (l_error_msg);
         retcode := conc_status_error;
         errbuf := 'Check log for Error information.';

         IF (g_commit)
         THEN
            l_ctx := 'rollback';
            ROLLBACK;
         END IF;
      ELSE
         IF ((g_warning_ct = 0) AND (g_error_ct = 0))
         THEN
            retcode := conc_status_ok;
            errbuf := NULL;
         ELSE
            retcode := conc_status_warning;
            errbuf := 'Check log for Warning information.';
            --
            -- When the completion code is WARNING, ORacle does not populate
            -- the Completion Text in the Concurrent Requests "View Details"
            -- screen unless we call fnd_concurrent.set_completion_status.
            -- This info is accurate as of release 11.5.5.
            --
            l_fnd_rtn :=
                     fnd_concurrent.set_completion_status ('WARNING', errbuf);
         END IF;

         IF (l_msg IS NULL) AND (g_commit)
         THEN
            l_ctx := 'commit';
            COMMIT;
         END IF;
      END IF;

      IF (p_sql_trace = 'Y')
      THEN
         l_ctx := 'Setting SQL trace OFF';
         wrtlog (dti || 'Setting SQL trace OFF');
         l_ctx := 'alter session - trace off';

         EXECUTE IMMEDIATE 'alter session set events ''10046 trace name context off''';
      END IF;

--  dbms_profiler.stop_profiler;  --  DEBUG ONLY  //////
      wrtdbg (dbg_low,
                 dti
              || 'Exit '
              || l_proc
              || ' - retocde='
              || retcode
              || ' errbuf='
              || errbuf
             );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_error_msg :=
               l_proc
            || ': '
            || l_ctx
            || ' - SQLERRM='
            || SQLERRM
            || lf
            || 'Error stack:'
            || CHR (10)
            || DBMS_UTILITY.format_error_backtrace;
         raise_application_error (-20001, l_error_msg);
   END do_main;
-- ============================================================================
END xxcrm_import_sfdc_contacts_pkg;
/


show errors
