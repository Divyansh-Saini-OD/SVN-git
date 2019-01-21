/* Formatted on 2007/09/06 17:06 (Formatter Plus v4.8.5) */
-- +====================================================================================================+
-- |                  Office Depot - Project Simplify                 					|
-- |                Oracle NAC Consulting Organization                 					|
-- +====================================================================================================+
-- | Name        :  XX_EXTERNAL_USERS_PKG.pkb                          					|
-- | Description : Package body for E1328_BSD_iReceivables_interface   					|
-- |               This package performs the following                 					|
-- |              1. Setup the contact at a bill to level              					|
-- |              2. Insert web user details into xx_external_users    					|
-- |              3. Assign responsibilites and party id  when the     					|
-- |                 webuser is created in fnd_user                    					|
-- |                                                                   					|
-- |                                                                   					|
-- |Change Record:                                                     					|
-- |===============                                                    					|
-- |Version   Date        Author             Remarks                   					|
-- |========  =========== ================== ===========================================================|
-- |DRAFT 1a  19-Aug-2007 Ramesh Raghupathi Initial draft version.      				|
-- |          10-Dec-2007 Yusuf Ali         Modified code for permissions flag.          		|
-- |          31-Dec-2007 Yusuf Ali         Incorporated granular API for creating contact at account   |
-- |					    site level and creating role for web user.			|
-- |          02-Jan-2008 Yusuf Ali	    Removed call to create_role_resp procedure from       	|
-- |					    save_ext_user procedure.                                    |
-- |          07-Jan-2008 Yusuf Ali	    Created cursor to retrieve party id and cust account role id|
-- |			  Kathirvel Perumal 	from cust account roles table in create_role_resp       |
-- |						procedure and create equi-join query to get org id from |
-- |						cust acct sites all table in save_ext_usr procedure.	|
-- |	      07-Jan-2008 Yusuf Ali         Created cursor for fetching responsibility id and created   |
-- |                                        log_debug procedure to messages.                            |
-- |          08-Jan-2008 Narayan Bh.	    Modified cursors to accept ln_acct_role_id parameter for    |
-- |                      Yusuf Ali	    l_get_responsibility_id_cur, l_get_party_id_cur to accept   |
-- |                      Alok Sahay        OSR, and both cursors to select object version to pass into |
-- |                                        appropriate granular API call, changed query in             |
-- |                                        save_ext_user to obtain org id for instance where           |
-- |                                        cust_acct_site_id IS NOT NULL.				|
-- |	      08-Jan-2008 Narayan Bh	    Created new query in create_role_resp to take               |
-- |					    ln_bill_to_site_use_id to get cust_acct_site_id from 	|
-- |  					    hz_cust_site_uses_all.					|
-- |          09-Jan-2008 Alok Sahay 	    Removed permission flag variable (not being used) for 	|
-- | 					    condition where permission flag is S/M in create role resp	|
-- |					    procedure							|
-- |          09-Jan-2008 Yusuf Ali         Created/moved get_site_use_id to beginning of 		|
-- | 			  Alok Sahay	    create_role_resp procedure.				     	|
-- +====================================================================================================+
create or replace
PACKAGE BODY XX_EXTERNAL_USERS_PKG
AS

   -- ++===================================================================+
   -- | Name             : GET_SITE_USE_ID                                |
   -- | Description      : This procedure returns the Oracle unique ID    |
   -- |                    based on the values from AOPS                  |
   -- |                                                                   |
   -- | Parameters :      p_orig_system                                   |
   -- |                   p_orig_sys_reference                            |
   -- |                   p_owner_table_name                              |
   -- |                   x_owner_table_id                                |
   -- +===================================================================+

  PROCEDURE log_debug(p_message in VARCHAR2)
  IS
  pragma autonomous_transaction;
  BEGIN
    INSERT INTO XX_IREC_DEBUG (msg) values (p_message);
    commit;

  end log_debug;

   PROCEDURE get_site_use_id (
    p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE,
    p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE,
    p_owner_table_name   IN  hz_orig_sys_references.owner_table_name%TYPE,
    x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
   )
   IS
   /* ======================================================================== */
  -- The get_site_use_id returns the Oracle unique ID based on the values
  -- from the legacy system (AOPS)
  --
  --  #param 1 p_orig_system            Legacy system identfier
  --  #param 2 p_orig_system_reference  Unique ID from legacy system
  --  #param 3 p_owner_table_name       table_name from Oracle EBS
  --  #param 4 x_owner_table_id         return Oracle unique ID
      ln_owner_table_id   hz_orig_sys_references.owner_table_id%TYPE;
      x_retcode           VARCHAR2 (100);
      x_errbuf            VARCHAR2 (100);
   BEGIN
      x_owner_table_id := NULL;
      x_retcode := 0;
      x_errbuf := NULL;

      SELECT owner_table_id
        INTO ln_owner_table_id
        FROM hz_orig_sys_references
       WHERE orig_system = p_orig_system
         AND orig_system_reference = p_orig_sys_reference
         AND owner_table_name = p_owner_table_name
         AND status = 'A';

      x_owner_table_id := ln_owner_table_id;
      x_retcode := 0;
      x_errbuf := NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_retcode := 104;
         x_owner_table_id := NULL;
         x_errbuf := 'OSR entered does not exist.';
      WHEN TOO_MANY_ROWS
      THEN
         x_retcode := 2;
         x_owner_table_id := NULL;
         x_errbuf := 'OSR entered returns multiple rows.';
      WHEN OTHERS
      THEN
         x_retcode := 3;
         x_owner_table_id := NULL;
         x_errbuf :=
                   'Unexpected Error while fetching id for OSR - ' || SQLERRM;
   END get_site_use_id;

   -- +===================================================================+
   -- | Name             : DECIPHER                                       |
   -- | Description      : This function provides the clear text password |
   -- |                    for an encryted password using the decoder key |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_encrypted_string                              |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+

   FUNCTION decipher (p_encrypted_string IN VARCHAR2)
   RETURN VARCHAR2
   IS
  /* ======================================================================== */
  --  This function provides the clear text password for an encryted password
  --  using the decoder key
  --
  --  #param 1 p_encrypted_string       Encrypted password string of web user

      lv_encrypted_string   VARCHAR2 (100); -- := '4QPI6SN';
      lv_decrypted_string   VARCHAR2 (100);
      ln_i                  NUMBER (20)    := 1;
      lv_length             NUMBER (10);
      lv_clear_text         VARCHAR2 (100);
   BEGIN
      SELECT LENGTH (p_encrypted_string)
        INTO lv_length
        FROM DUAL;

      WHILE ln_i <= lv_length
      LOOP
         SELECT DECODE (SUBSTR (UPPER (p_encrypted_string), ln_i, 1),
                        'Q', 'A',
                        'G', 'B',
                        'T', 'C',
                        'Z', 'D',
                         5,  'E',
                        'J', 'F',
                        'O', 'G',
                         7,  'H',
                        'P', 'I',
                        'A', 'J',
                        'F', 'K',
                         0,  'L',
                         3,  'M',
                        'R', 'N',
                        'D', 'O',
                        'U', 'P',
                        'H', 'Q',
                         8,  'R',
                         4,  'S',
                        'L', 'T',
                        'V', 'U',
                        'B', 'V',
                         9,  'W',
                        'E', 'X',
                         2,  'Y',
                        'M', 'Z',
                        'X',  0,
                        'I',  1,
                         6,   2,
                        'S',  3,
                        'N',  4,
                        'Y',  5,
                        'K',  6,
                        'W',  7,
                         1,   8,
                        'C',  9
                       )
           INTO lv_decrypted_string
           FROM DUAL;

         --   log_debug( 'Decrypted password: '|| lv_decrypted_string );
         lv_clear_text := lv_clear_text || lv_decrypted_string;
         ln_i := ln_i + 1;
      END LOOP;

      -- log_debug( 'lv_clear_text: '|| lv_clear_text );
      RETURN lv_clear_text;
   END decipher;

   -- +===================================================================+
   -- | Name             : PROCESS_OID                                    |
   -- | Description      : This procedure connects to an OID instance and |
   -- |                    updates the userpassword attribute for a       |
   -- |                    given user                                     |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_username                                      |
   -- |                   x_retcode                                       |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE process_oid ( p_username IN  VARCHAR2
                         , x_retcode  OUT NUMBER
                         )
   AS
  /* ======================================================================== */
  --  process_oid  connects to an OID instance and updates the userpassword
  --  attribute for a given user
  --
  --  #param 1 p_user_name  user name of bsd web user
  --  #param 2 x_retcode    return success or failure
     retval         PLS_INTEGER;
     my_session     DBMS_LDAP.SESSION;
     ldap_host      VARCHAR2 (256);
     ldap_port      VARCHAR2 (256);
     ldap_user      VARCHAR2 (256);
     ldap_passwd    VARCHAR2 (256);
     userdn         VARCHAR2 (256);
     newpwd         VARCHAR2 (256);
     newmail        VARCHAR2 (256);
     my_mod         DBMS_LDAP.mod_array;
     my_values      DBMS_LDAP.string_collection;
     lv_cn          varchar2(10);
     lv_attr_val    varchar2(50);
     lv_password    varchar2(50);

     le_oid_conn_error   EXCEPTION;
     le_pwd_modify_error EXCEPTION;

   BEGIN
     /*
       oidServer=chileba05d.na.odcorp.net
       oidPort=13060
       oidSecDN=cn=euspoc,cn=users,dc=odcorp,dc=net
       oidSecCred=euspoc1
       oidExtCont=ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net
       oidExtSiteID=
     */

     BEGIN
       SELECT xx_decipher(password) into lv_password
       FROM xxcrm.xx_external_users
       WHERE userid = substr(p_username, 4, length(p_username));
       log_debug ('USER: '|| substr(p_username, 4, length(p_username)));
     EXCEPTION
       when no_data_found then
         x_retcode := 105;
         raise;
     END;

     retval := -1;
     ldap_host   := 'chileba05d.na.odcorp.net';
     ldap_port   := '13060';
     ldap_user   := 'cn=euspoc,cn=users,dc=odcorp,dc=net';
     ldap_passwd := 'euspoc1';

     userdn := 'cn=' || p_username || ',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net';

     log_debug (RPAD ('LDAP Host ', 25, ' ') || ': ' || ldap_host);
     log_debug (RPAD ('LDAP Port ', 25, ' ') || ': ' || ldap_port);
     DBMS_LDAP.use_exception := TRUE;
     my_session := DBMS_LDAP.init (ldap_host, ldap_port);

     retval := DBMS_LDAP.simple_bind_s (my_session, ldap_user, ldap_passwd);
     IF retval = 1
     THEN
       log_debug ( RPAD ('simple_bind_s ', 25, ' ')
                              || ': '
                              || TO_CHAR (retval)
                            );
       raise le_oid_conn_error;
     END IF;

     my_mod := DBMS_LDAP.create_mod_array (1);
     my_values (1) := lv_password;
     DBMS_LDAP.populate_mod_array ( my_mod
                                  , DBMS_LDAP.mod_replace
                                  , 'userpassword'
                                  , my_values
                                  );
     -- Repeat the below lines multiple times to modify several attributes
     -- at the same time. Just set the my_values(1) to the new value and change the 3rd
     -- parameter of the populate_mod_array to the name of the attribute to modify.
     -- my_values(1) := newmail;
     -- DBMS_LDAP.populate_mod_array(my_mod, DBMS_LDAP.MOD_REPLACE, 'mail', my_values);
     retval := DBMS_LDAP.modify_s (my_session, userdn, my_mod);
     IF retval = 1
     THEN
       log_debug ( RPAD ('modify_s returns', 25, ' ')
                              || ': '
                              || TO_CHAR (retval)
                            );
       raise le_pwd_modify_error;
     END IF;

     DBMS_LDAP.free_mod_array (my_mod);
     retval := DBMS_LDAP.unbind_s (my_session);
     --         log_debug (   RPAD ('unbind_res Returns ', 25, ' ')
     --                               || ': '
     --                               || TO_CHAR (retval)
     --                              );

     log_debug ('Directory operation Successful .. exiting');
   EXCEPTION
     when le_oid_conn_error then
       x_retcode := 106;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.PROCESS_OID'
	   , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0013_OID_CONNECTION_ERROR'
       , p_error_message           => 'Error connection to OID server check credentials'
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
     when le_pwd_modify_error then
       x_retcode := 107;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.PROCESS_OID'
	   , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0014_PWD_MODIFY_ERROR'
       , p_error_message           => 'Error updating user password in OID for user'|| p_username
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
     when others then
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.PROCESS_OID'
	   , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0015_UNKNOWN_ERROR'
       , p_error_message           => 'SQLCODE: '|| sqlcode || 'SQLERRM: '|| sqlerrm
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
   END process_oid;

   -- +===================================================================+
   -- | Name             : CREATE_ROLE_RESP                               |
   -- | Description      : This procedure validates the keys passed from  |
   -- |                    the legacy system (AOPS) and when a matching   |
   -- |                    account site and contact is found in Oracle    |
   -- |                    EBS will set the contact at bill to site for   |
   -- |                    he incoming ship to and inserts the user if it |
   -- |                   is a create and updates the user when modify in |
   -- |                   the xx_external_users tables. This procedue is  |
   -- |                   called from SaveiReceivables BPEL process       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_cust_acct_cnt_os                              |
   -- |                   p_cust_acct_cnt_osr                             |
   -- |                   p_cust_acct_site_osr                            |
   -- |                   p_action                                        |
   -- |                   p_permission_flag                               |
   -- |                   x_party_id                                      |
   -- |                   x_retcode                                       |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE create_role_resp (
      p_cust_acct_cnt_os     IN       VARCHAR2,
      p_cust_acct_cnt_osr    IN       VARCHAR2,
      p_cust_acct_site_osr   IN       VARCHAR2,
      p_action               IN       VARCHAR2,
      p_permission_flag      IN       VARCHAR2,
      x_party_id             OUT      NUMBER,
      x_retcode              OUT      VARCHAR2
   )
   IS
  /* ======================================================================== */
  --  create_role_resp validates the keys passed from the legacy system (AOPS)
  --  and when a matching account site and contact is found in Oracle EBS will
  --  set the contact at bill to site for the incoming ship to and inserts the
  --  user if it is a create and updates the user when modify in the
  --  xx_external_users tables. This procedure is called from SaveiReceivables
  --  BPEL process
  --
  --  #param 1 p_cust_acct_cnt_os   Legacy system identifier
  --  #param 2 p_cust_acct_cnt_osr  AOPS unique ID of bsd web contact
  --  #param 3 p_cust_acct_site_osr AOPS unique ID of account site
  --  #param 4 p_permission_flag    Flag to ID if contact relationship
  --                                should tie to account/account site
  --  #param 5 p_action             CREATE ( 'C' )
  --  #param 6 x_party_id           return party id of the relationship
  --  #param 7 x_retcode            return success or failure

      l_cust_acct_cnt_bo        hz_cust_acct_contact_bo;
      x_cust_acct_cnt_bo        hz_cust_acct_contact_bo;
      l_role_resp_obj           hz_role_responsibility_obj;

      ln_bill_to_site_use_id  NUMBER;
      l_dummy                   NUMBER (10);
      l_return_status           VARCHAR2 (30);
      l_msg_count               NUMBER (10);
      l_msg_data                VARCHAR2 (2000);
      l_cust_acct_cnt_id        NUMBER (10);
      l_cust_acct_cnt_os        VARCHAR2 (50);
      l_cust_acct_cnt_osr       VARCHAR2 (50);
      l_cust_acct_site_osr      VARCHAR2 (50);
      l_action                  VARCHAR2 (1);
      l_role_id                 NUMBER;
      ln_role_id                NUMBER;
      ln_parent_id              NUMBER;
      lv_parent_os              VARCHAR2 (50);
      lv_parent_osr             VARCHAR2 (50);
      lv_parent_obj             VARCHAR2 (50);
      ln_cust_acct_site_id      NUMBER (15);
      ln_cust_acct_id           NUMBER (10);
      ln_cust_account_id        NUMBER (10);
      ln_orig_sys_ref           VARCHAR2 (30);
      lv_billto_orig_sys_ref    VARCHAR2 (30);
      ln_bill_to_site_id        NUMBER (10);
      ln_org_contact_id         NUMBER (10);
      l_cust_acct_role_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.cust_account_role_rec_type;
      gv_init_msg_list          VARCHAR2(1)  := fnd_api.g_true;
      l_role_responsibility_rec HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;
      l_ROLE_REC_TYPE           HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
      ln_responsibility_id      NUMBER;
      ln_get_responsibility_id      NUMBER;
      ln_cust_account_role_id   NUMBER;
      ln_cnt_party_id           NUMBER;
      ln_cust_acct_roles_party_id   NUMBER;
      ln_relationship_party_id  NUMBER;
      lv_cust_acct_cnt_os       VARCHAR2(50);
      --lc_permission_flag        VARCHAR2(1);
      ln_object_version_number  NUMBER := 1;
      ln_acct_role_id           NUMBER;

      -- Exceptions
      le_role_api_error         EXCEPTION;
      le_resp_api_error         EXCEPTION;
      le_bo_api_error           EXCEPTION;
      le_contact_not_found      EXCEPTION;
      le_relationship_not_found EXCEPTION;

      CURSOR lc_fetch_rel_party_id_cur ( p_org_contact_id IN NUMBER )
      IS
      SELECT hr.party_id
      FROM   hz_relationships hr,
             hz_org_contacts  hoc
      WHERE  hoc.org_contact_id = p_org_contact_id
      AND    hr.relationship_id = hoc.party_relationship_id
      AND    hr.status = 'A';

      CURSOR  l_get_party_id_cur (p_cust_acct_cnt_osr IN VARCHAR2) IS
      SELECT  cust_account_role_id, party_id, object_version_number
      FROM    hz_cust_account_roles
      WHERE   cust_acct_site_id IS NOT NULL
      AND     orig_system_reference=p_cust_acct_cnt_osr;

      CURSOR l_get_responsibility_id_cur(ln_acct_role_id in NUMBER)
      IS
      SELECT  responsibility_id, object_version_number
      FROM    HZ_ROLE_RESPONSIBILITY
      WHERE   cust_account_role_id = ln_acct_role_id
      --AND     orig_system_reference = p_cust_acct_cnt_osr
      and     responsibility_type = 'SELF_SERVICE_USER';

   BEGIN
       
       log_debug (to_char(sysdate,'mm/dd/yyyy hh:mi:ss AM') ||' *** PROCEDURE create_role_resp **** ');

      --DBMS_APPLICATION_INFO.set_client_info('404');
      
      FND_GLOBAL.APPS_INITIALIZE(58590, 50658, 20049);
      MO_GLOBAL.INIT;
      MO_GLOBAL.SET_POLICY_CONTEXT('S', 404);
      FND_MSG_PUB.INITIALIZE;


      
      get_site_use_id ( p_cust_acct_cnt_os
                             , SUBSTR(p_cust_acct_site_osr, 1,
                               INSTR(p_cust_acct_site_osr, '-') -1 ) || '-00001-A0'
                             , 'HZ_CUST_ACCOUNTS'
                             , ln_cust_acct_id  --
                             );

      log_debug(' Cust Account ID : ' || ln_cust_acct_id);     
      
      
      IF p_permission_flag in ('X', 'C', 'L')
      THEN
        lv_parent_obj := 'CUST_ACCT_SITE';
        lv_cust_acct_cnt_os := 'A0';
        lv_parent_os := NULL;-- Ex:'A0';
        lv_parent_osr := NULL;-- Ex:'28655959-07804-A0-HVOP-1';
      ELSE
        lv_parent_obj := 'CUST_ACCT';
        lv_cust_acct_cnt_os := 'A0';
        lv_parent_os := p_cust_acct_cnt_os;
        lv_parent_osr := SUBSTR(p_cust_acct_site_osr, 1,
                          INSTR(p_cust_acct_site_osr, '-') -1 ) || '-00001-A0';-- Ex:'28655959-07804-A0-HVOP-1';
      END IF;


      BEGIN
        /*SELECT permission_flag
        INTO lc_permission_flag
        FROM xxcrm.xx_external_users
        WHERE CONTACT_OSR = p_cust_acct_cnt_osr
        AND ACCT_SITE_OSR = p_cust_acct_site_osr;
        */
        --BEGIN CODE CHANGE
        --  12/10/2007
        
        
        log_debug ('permission flag from parameter is: ' || p_permission_flag);
        IF p_permission_flag IN ('X', 'L', 'C')
        THEN
          get_site_use_id ( p_cust_acct_cnt_os
                          , p_cust_acct_site_osr
                          , 'HZ_CUST_ACCT_SITES_ALL'
                          , ln_cust_acct_site_id
                          );
          log_debug ('p_cust_acct_cnt_os: '||p_cust_acct_cnt_os );
          log_debug ('p_cust_acct_site_osr: '||p_cust_acct_site_osr );
          log_debug ('ln_cust_acct_site_id: '||ln_cust_acct_site_id );

          SELECT orig_system_reference, bill_to_site_use_id
          INTO lv_billto_orig_sys_ref, ln_bill_to_site_use_id
          FROM hz_cust_site_uses_all
          WHERE cust_acct_site_id = ln_cust_acct_site_id
          AND   site_use_code = 'SHIP_TO';

          log_debug(' Bill to Site Use ID : ' || ln_bill_to_site_use_id);

--          SELECT cust_acct_site_id INTO ln_bill_to_site_id
--          from hz_cust_site_uses_all
--          where site_use_id = ln_bill_to_site_use_id;

          -- AKS 08-Jan-2008
          
          
          IF ln_bill_to_site_use_id IS NOT NULL
          THEN
             log_debug ('Get Bill To Associated with Ship To Record' );
             SELECT cust_acct_site_id INTO ln_bill_to_site_id
             from hz_cust_site_uses_all
             where site_use_id = ln_bill_to_site_use_id;
             
             
          ELSE
             log_debug ('Get Default Bill To Record' );

            log_debug(' Cust Account ID : ' || ln_cust_acct_id);

             SELECT hcas.cust_acct_site_id,
                    hcas.orig_system_reference
             INTO   ln_bill_to_site_id,
                    ln_orig_sys_ref
             FROM   hz_cust_acct_sites_all hcas,
                    hz_cust_site_uses_all hcasu
             WHERE  hcas.cust_account_id = ln_cust_acct_id
             AND    hcas.cust_acct_site_id = hcasu.cust_acct_site_id
             AND    hcasu.primary_flag = 'Y'
             AND    hcasu.site_use_code = 'BILL_TO';
          END IF; -- ln_bill_to_site_use_id IS NOT NULL
          -- AKS 08-Jan-2008

          log_debug(' Bill to Site ID : ' || ln_bill_to_site_id);
          ln_cust_acct_site_id:=ln_bill_to_site_id; --NB 09-JAN
        END IF;

--        IF p_permission_flag IN ('M', 'S')
--        THEN
--          get_site_use_id ( p_cust_acct_cnt_os
--                          , SUBSTR(p_cust_acct_site_osr, 1,
--                            INSTR(p_cust_acct_site_osr, '-') -1 ) || '-00001-A0'
--                          , 'HZ_CUST_ACCOUNTS'
--                          , ln_cust_account_id
--                          );
--          log_debug ('ln_cust_account_id: '||ln_cust_account_id );
--        END IF;

       EXCEPTION
        when no_data_found then
          log_debug ('I am here 1 ' );
          x_retcode := 200;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
		  , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0002_SHIPTO_NOT_FOUND'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.create_role_resp: Ship To OSR: '|| p_cust_acct_site_osr ||' from AOPS not found in CDH'
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
        when others then
          log_debug ('I am here 2 ' );
          x_retcode := 201;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0016_SHIPTO_QUERY_FAILED'
          , p_error_message           => 'SQLCODE: '||sqlcode||' SQLERRM: '||SQLERRM
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
      END;

      -- AKS 08-Jan-2008
      /*
      BEGIN

        IF p_permission_flag in ('X', 'C', 'L')
        THEN
            SELECT cust_account_id, cust_acct_site_id, orig_system_reference
            INTO ln_cust_acct_id, ln_cust_acct_site_id, ln_orig_sys_ref
            FROM hz_cust_acct_sites_all
            WHERE cust_acct_site_id = ln_bill_to_site_id;

            log_debug ('A');

        END IF;

        EXCEPTION
         when no_data_found then
           log_debug ('I am here 3 ' );
           select b.cust_acct_site_id into ln_bill_to_site_id
           from hz_cust_acct_sites_all a
              , hz_cust_site_uses_all b
           where a.CUST_ACCT_SITE_ID = b.cust_acct_site_id
             and a.cust_account_id = ( select cust_account_id
                                     from hz_cust_acct_sites_all
                                     where cust_acct_site_id = ln_cust_acct_site_id
                                   )
             and b.primary_flag = 'Y'
             and b.site_use_code = 'BILL_TO';

           log_debug ('ln_bill_to_site_id: '||ln_bill_to_site_id );
           ln_parent_id := ln_bill_to_site_id;

           SELECT cust_account_id, cust_acct_site_id, orig_system_reference
           INTO ln_cust_acct_id, ln_cust_acct_site_id, ln_orig_sys_ref
           FROM hz_cust_acct_sites_all
           WHERE cust_acct_site_id = ln_bill_to_site_id;

         when others then
          x_retcode := 203;
  	  log_debug ('sqlcode: '|| sqlcode );
          log_debug ('sqlerrm: '|| sqlerrm );
          xx_com_error_log_pub.log_error
           ( p_application_name        => 'XXCRM'
           , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
           , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
           , p_module_name             => 'CDH'
           , p_error_message_code      => 'XX_CDH_0017_BILLTO_QUERY_FAILED'
           , p_error_message           => 'SQLCODE: '||sqlcode||' SQLERRM: '||SQLERRM
           , p_error_message_severity  => 'MAJOR'
           , p_error_status            => 'ACTIVE'
           , p_notify_flag             => 'Y'
           , p_recipient               => NULL
           );
           raise;
        END;
        */
      -- AKS 08-Jan-2008

      BEGIN
        get_site_use_id ( p_cust_acct_cnt_os
                        , p_cust_acct_cnt_osr
                        , 'HZ_ORG_CONTACTS'
                        , ln_org_contact_id
                        );

        log_debug ('ln_contact_id: '|| ln_org_contact_id );

        IF ln_org_contact_id IS NULL
        THEN
        log_debug ('le_contact_not_found raised');
          raise le_contact_not_found;
        END IF;

        FOR lc_fetch_rel_party_id_rec IN lc_fetch_rel_party_id_cur (ln_org_contact_id)
        LOOP
          ln_relationship_party_id := lc_fetch_rel_party_id_rec.party_id;
          EXIT;
        END LOOP;

        log_debug ('ln_relationship_party_id: '|| ln_relationship_party_id );

        IF ln_relationship_party_id IS NULL
        THEN
          raise le_relationship_not_found;
        END IF;

      EXCEPTION
        when le_contact_not_found then
          x_retcode := 204;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0001_CONTACT_NOT_FOUND'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.create_role_resp: ContactOSR: '|| p_cust_acct_cnt_osr||' from AOPS not found in CDH'
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
        when le_relationship_not_found then
          x_retcode := 205;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0003_RELATIONSHIP_NOT_FOUND'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.create_role_resp: Relationship does not exist for contact: '|| p_cust_acct_cnt_osr ||' with ship to org: '|| p_cust_acct_site_osr
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
        when others then
          x_retcode := 206;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0018_CONTACT_QUERY_FAILED'
          , p_error_message           => 'SQLCODE: '||sqlcode||' SQLERRM: '||SQLERRM
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
      END;
/*

  -- Below code is commented in case there are some issues with BO api's
  -- then this code can be used to achieve the same functionality

      IF (p_action = 'C')
      THEN


         -- Role part start using granular V2 API

         l_cust_acct_role_rec := NULL;

         --l_cust_acct_role_rec.cust_account_role_id  :=
         l_cust_acct_role_rec.party_id              := ln_relationship_party_id;
         l_cust_acct_role_rec.cust_account_id       := ln_cust_acct_id;
         l_cust_acct_role_rec.cust_acct_site_id     := ln_cust_acct_site_id;
         --l_cust_acct_role_rec.primary_flag        :=
         l_cust_acct_role_rec.role_type             := 'CONTACT';
         --l_cust_acct_role_rec.source_code         :=
         --l_cust_acct_role_rec.attribute_category    :=
         --l_cust_acct_role_rec.attribute1            :=
         --l_cust_acct_role_rec.attribute2            :=
         --l_cust_acct_role_rec.attribute3            :=
         --l_cust_acct_role_rec.attribute4            :=
         --l_cust_acct_role_rec.attribute5            :=
         --l_cust_acct_role_rec.attribute6            :=
         --l_cust_acct_role_rec.attribute7            :=
         --l_cust_acct_role_rec.attribute8            :=
         --l_cust_acct_role_rec.attribute9            :=
         --l_cust_acct_role_rec.attribute10           :=
         --l_cust_acct_role_rec.attribute11           :=
         --l_cust_acct_role_rec.attribute12           :=
         --l_cust_acct_role_rec.attribute13           :=
         --l_cust_acct_role_rec.attribute14           :=
         --l_cust_acct_role_rec.attribute15           :=
         --l_cust_acct_role_rec.attribute16           :=
         --l_cust_acct_role_rec.attribute17           :=
         --l_cust_acct_role_rec.attribute18           :=
         --l_cust_acct_role_rec.attribute19           :=
         --l_cust_acct_role_rec.attribute20           :=
         --l_cust_acct_role_rec.attribute21           :=
         --l_cust_acct_role_rec.attribute22           :=
         --l_cust_acct_role_rec.attribute23           :=
         --l_cust_acct_role_rec.attribute24           :=
         l_cust_acct_role_rec.orig_system_reference := p_cust_acct_cnt_osr;
         l_cust_acct_role_rec.orig_system           := 'A0';
         --l_cust_acct_role_rec.attribute25           :=
         --l_cust_acct_role_rec.status                := lt_acct_contacts_tbl(i).status;
         l_cust_acct_role_rec.created_by_module     := 'V2 API';
         --l_cust_acct_role_rec.application_id        := lt_acct_contacts_tbl(i).program_application_id;

--         fnd_file.put_line(fnd_file.log, 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role.');

         l_return_status  := NULL;
         l_msg_count      := 0;
         l_msg_data       := NULL;

         HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role
         ( p_init_msg_list          => gv_init_msg_list
         , p_cust_account_role_rec  => l_cust_acct_role_rec
         , x_cust_account_role_id   => ln_cust_account_role_id
         , x_return_status          => l_return_status
         , x_msg_count              => l_msg_count
         , x_msg_data               => l_msg_data
         );

        IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
          NULL;
        ELSE
          raise le_role_api_error;
        END IF;


        log_debug ('x_msg_data: '|| l_msg_data );
        log_debug ('x_msg_count: '|| l_msg_count );
        log_debug ('x_return_status: '|| l_return_status );
        log_debug ('ln_cust_account_role_id: '|| ln_cust_account_role_id );

        IF(l_msg_count > 1) THEN
        FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
          log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
        END LOOP;
        END IF;

       -- Role part end using granular V2 API

       -- responsibility part start  using granular V2 API
       l_role_responsibility_rec := NULL;
       l_role_responsibility_rec.cust_account_role_id  := ln_cust_account_role_id;
       l_role_responsibility_rec.responsibility_type   := 'SELF_SERVICE_USER';
       l_role_responsibility_rec.primary_flag          := 'Y';
       l_role_responsibility_rec.attribute_category    := NULL;
       l_role_responsibility_rec.attribute1            := NULL;
       l_role_responsibility_rec.attribute2            := NULL;
       l_role_responsibility_rec.attribute3            := NULL;
       l_role_responsibility_rec.attribute4            := NULL;
       l_role_responsibility_rec.attribute5            := NULL;
       l_role_responsibility_rec.attribute6            := NULL;
       l_role_responsibility_rec.attribute7            := NULL;
       l_role_responsibility_rec.attribute8            := NULL;
       l_role_responsibility_rec.attribute9            := NULL;
       l_role_responsibility_rec.attribute10           := NULL;
       l_role_responsibility_rec.attribute11           := NULL;
       l_role_responsibility_rec.attribute12           := NULL;
       l_role_responsibility_rec.attribute13           := NULL;
       l_role_responsibility_rec.attribute14           := NULL;
       l_role_responsibility_rec.attribute15           := NULL;
       --l_role_responsibility_rec.orig_system_reference :=
       l_role_responsibility_rec.created_by_module     := 'V2 API';
       -- l_role_responsibility_rec.application_id        := lt_role_resp_tbl(i).program_application_id;
       -- fnd_file.put_line(fnd_file.log, 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility.');

        HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
        (  p_init_msg_list            => gv_init_msg_list
        ,  p_role_responsibility_rec  => l_role_responsibility_rec
        ,  x_responsibility_id        => ln_responsibility_id
        ,  x_return_status            => l_return_status
        ,  x_msg_count                => l_msg_count
        ,  x_msg_data                 => l_msg_data
        );

        IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
          NULL;
        ELSE
          raise le_resp_api_error;
        END IF;



        log_debug ('x_msg_data: '|| l_msg_data );
        log_debug ('x_msg_count: '|| l_msg_count );
        log_debug ('x_return_status: '|| l_return_status );
        log_debug ('ln_responsibility_id: '|| ln_responsibility_id );

        IF(l_msg_count > 1) THEN
        FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
          log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
        END LOOP;
        END IF;

        -- responsibility part end using granular V2 API


        x_retcode := 0;
        x_party_id := ln_relationship_party_id;
        log_debug ('x_party_id: '|| ln_relationship_party_id );
        log_debug ('retcode: ' || x_retcode );
        log_debug ('x_msg_data: '|| l_msg_data );
        log_debug ('x_msg_count: '|| l_msg_count );
        log_debug ('x_return_status: '|| l_return_status );

        IF(l_msg_count > 1) THEN
        FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
          log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
        END LOOP;
        END IF;
      COMMIT;
      END IF;

*/
      -- Create Role Responsibility using BO API'S
      BEGIN

      log_debug('BO API call is next!');
        IF p_action IN ('C', 'U')
        THEN
          IF p_permission_flag in ('X', 'L', 'C')
          THEN
          log_debug('ln_cust_acct_site_id' ||ln_cust_acct_site_id);
          log_debug('ln_cust_acct_id' ||ln_cust_acct_id);

          --Determine if account contact exist
          /*select party_id into ln_cust_acct_roles_party_id
            from hz_orig_sys_references
          where
            orig_system_reference = p_cust_acct_cnt_osr
          and
            owner_table_name = 'HZ_CUST_ACCOUNT_ROLES'
          and
            status = 'A';
          */

          OPEN l_get_party_id_cur (p_cust_acct_cnt_osr);
          FETCH  l_get_party_id_cur INTO ln_acct_role_id, ln_cust_acct_roles_party_id, ln_object_version_number;
          CLOSE l_get_party_id_cur;

          IF ln_cust_acct_roles_party_id IS NOT NULL
          THEN
           l_ROLE_REC_TYPE.cust_account_role_id  := ln_acct_role_id;
           l_ROLE_REC_TYPE.party_id              := ln_relationship_party_id;
           l_ROLE_REC_TYPE.cust_account_id       := ln_cust_acct_id;
           --l_ROLE_REC_TYPE.cust_acct_site_id     := ln_cust_acct_site_id;
           l_ROLE_REC_TYPE.primary_flag          := 'N';
           l_ROLE_REC_TYPE.role_type             := 'CONTACT';
           --l_ROLE_REC_TYPE.orig_system_reference := p_cust_acct_cnt_osr;
           --l_ROLE_REC_TYPE.orig_system           := p_cust_acct_cnt_os;
           l_ROLE_REC_TYPE.status                := 'A';
           l_ROLE_REC_TYPE.created_by_module     := 'V2 API';

          log_debug('i AM HERE BEFORE UPDATE ACCOUNT ROLE');
           HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role(
                        p_init_msg_list                  => FND_API.G_FALSE
                      , p_cust_account_role_rec          => l_ROLE_REC_TYPE
                      , p_object_version_number           => ln_object_version_number
                      , x_return_status                  => l_return_status
                      , x_msg_count                      => l_msg_count
                      , x_msg_data                       => l_msg_data
                      );
                       log_debug('Here is the role id '||ln_acct_role_id);
          log_debug('i AM HERE after UPDATE ACCOUNT ROLE, here is the status: ' || l_return_status);
          log_debug('Contact OSR' ||p_cust_acct_cnt_osr);

          IF(l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             IF(l_msg_count > 1) THEN
               FOR I IN 1..l_msg_count LOOP
                 log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
               END LOOP;
             ELSE
               log_debug('Msg Data     : '||l_msg_data);
             END IF;
           END IF;

          OPEN l_get_responsibility_id_cur (ln_acct_role_id);
          FETCH  l_get_responsibility_id_cur INTO ln_get_responsibility_id, ln_object_version_number;
          CLOSE l_get_responsibility_id_cur;

          log_debug('Responsibility id: ' || ln_get_responsibility_id);

          l_role_responsibility_rec                       := NULL;
          l_role_responsibility_rec.cust_account_role_id  := l_role_id;
          l_role_responsibility_rec.responsibility_id     := ln_get_responsibility_id;--MAKE CHANGE HERE
          l_role_responsibility_rec.responsibility_type   := 'SELF_SERVICE_USER';
          l_role_responsibility_rec.primary_flag          := 'Y';
          l_role_responsibility_rec.created_by_module     := 'V2 API';

          log_debug('i AM HERE before UPDATE ROLE RESP');

          HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
          (  p_init_msg_list            => FND_API.G_FALSE
          ,  p_role_responsibility_rec  => l_role_responsibility_rec
          ,  p_object_version_number    => ln_object_version_number
          ,  x_return_status            => l_return_status
          ,  x_msg_count                => l_msg_count
          ,  x_msg_data                 => l_msg_data
          );

          IF(l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             IF(l_msg_count > 1) THEN
               FOR I IN 1..l_msg_count LOOP
                 log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
               END LOOP;
             ELSE
               log_debug('Msg Data     : '||l_msg_data);
             END IF;
           END IF;


          log_debug('i AM HERE AFTER UPDATE ROLE RESP');
          ELSE
            l_ROLE_REC_TYPE.party_id              := ln_relationship_party_id;
             l_ROLE_REC_TYPE.cust_account_id       := ln_cust_acct_id;
             l_ROLE_REC_TYPE.cust_acct_site_id     := ln_cust_acct_site_id;
             l_ROLE_REC_TYPE.primary_flag          := 'N';
             l_ROLE_REC_TYPE.role_type             := 'CONTACT';
             l_ROLE_REC_TYPE.orig_system_reference := p_cust_acct_cnt_osr;
             l_ROLE_REC_TYPE.orig_system           := p_cust_acct_cnt_os;
             l_ROLE_REC_TYPE.status                := 'A';
             l_ROLE_REC_TYPE.created_by_module     := 'V2 API';

            log_debug('i AM HERE BEFORE CREATE ACCOUNT ROLE');
             HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(
                          p_init_msg_list                  => FND_API.G_FALSE
                        , p_cust_account_role_rec          => l_ROLE_REC_TYPE
                        , x_cust_account_role_id           => l_role_id
                        , x_return_status                  => l_return_status
                        , x_msg_count                      => l_msg_count
                        , x_msg_data                       => l_msg_data
                        );
                        
            IF(l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             IF(l_msg_count > 1) THEN
               FOR I IN 1..l_msg_count LOOP
                 log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
               END LOOP;
             ELSE
               log_debug('Msg Data BEFORE CREATE ACCOUNT ROLE: '||l_msg_data);
             END IF;
           END IF;
                         log_debug('Here is the role id '||l_role_id);
                         log_debug('After create cust account role status: ' || l_return_status);
            log_debug('i AM HERE after CREATE ACCOUNT ROLE');

            l_role_responsibility_rec                       := NULL;
            l_role_responsibility_rec.cust_account_role_id  := l_role_id;
            l_role_responsibility_rec.responsibility_type   := 'SELF_SERVICE_USER';
            l_role_responsibility_rec.primary_flag          := 'Y';
            l_role_responsibility_rec.created_by_module     := 'V2 API';

            log_debug('i AM HERE before CREATE ROLE RESP');

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
            (  p_init_msg_list            => FND_API.G_FALSE
            ,  p_role_responsibility_rec  => l_role_responsibility_rec
            ,  x_responsibility_id        => ln_responsibility_id
            ,  x_return_status            => l_return_status
            ,  x_msg_count                => l_msg_count
            ,  x_msg_data                 => l_msg_data
            );
            
            IF(l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             IF(l_msg_count > 1) THEN
               FOR I IN 1..l_msg_count LOOP
                 log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
               END LOOP;
             ELSE
               log_debug('Msg Data AFTER CREATE ROLE RESP: '||l_msg_data);
             END IF;
           END IF;
           
            log_debug('i AM HERE AFTER CREATE ROLE RESP');
          END IF;
           /*
           l_cust_acct_cnt_bo :=
            hz_cust_acct_contact_bo.create_object
            ( p_orig_system                => p_cust_acct_cnt_os
            , p_orig_system_reference      => p_cust_acct_cnt_osr
            , p_contact_person_id          => 399608	--ln_relationship_party_id -- Org contact purpose
            , p_role_type                  => 'CONTACT'
            , p_cust_acct_site_id          => ln_cust_acct_site_id -- maintain the contact at cust site level
          --  , p_relationship_code          => 'CONTACT_OF'
          --  , p_relationship_type          => 'CONTACT'
            , p_status                     => 'A'
            );*/
          END IF;

          IF p_permission_flag in ('M', 'S')
          THEN
          log_debug('Inside m/s condition');
           l_cust_acct_cnt_bo :=
            hz_cust_acct_contact_bo.create_object
            ( p_orig_system                => p_cust_acct_cnt_os
            , p_orig_system_reference      => p_cust_acct_cnt_osr
            , p_contact_person_id          => ln_relationship_party_id -- Org contact purpose
            , p_relationship_code          => 'CONTACT_OF'
            , p_relationship_type          => 'CONTACT'
            , p_role_type                  => 'CONTACT'
            --, p_cust_acct_site_id          => ln_cust_account_id -- maintain the contact at cust account level
            , p_status                     => 'A'
            );

            l_role_resp_obj :=
            hz_role_responsibility_obj.create_object
            ( p_responsibility_type      => 'SELF_SERVICE_USER'
            , p_primary_flag             => 'N'
            );

           l_cust_acct_cnt_bo.contact_role_objs.EXTEND;
           l_cust_acct_cnt_bo.contact_role_objs (1) := l_role_resp_obj;

           log_debug('API CALL FOR s/m');
           hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo
            ( p_init_msg_list              => fnd_api.g_true
             , p_validate_bo_flag           => fnd_api.g_false
             , p_cust_acct_contact_obj      => l_cust_acct_cnt_bo
             , p_created_by_module          => NULL
             , x_return_status              => l_return_status
             , x_msg_count                  => l_msg_count
             , x_msg_data                   => l_msg_data
             , x_cust_acct_contact_id       => l_cust_acct_cnt_id
             , x_cust_acct_contact_os       => l_cust_acct_cnt_os
             , x_cust_acct_contact_osr      => l_cust_acct_cnt_osr
             , px_parent_id                 => ln_parent_id
             , px_parent_os                 => lv_parent_os
             , px_parent_osr                => lv_parent_osr
             , px_parent_obj_type           => lv_parent_obj -- 'CUST_ACCT'
            );

           log_debug('Parent OSR '||lv_parent_osr);
           log_debug('Parent type '||lv_parent_obj);
           log_debug('Parent ID '||ln_parent_id);

          END IF;


           /*
           IF p_permission_flag in ('X', 'C', 'L')
           THEN
           log_debug('API CALL FOR x/c/L');
            hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo
            ( p_init_msg_list              => fnd_api.g_true
             , p_validate_bo_flag           => fnd_api.g_false
             , p_cust_acct_contact_obj      => l_cust_acct_cnt_bo
             , p_created_by_module          => NULL
             , x_return_status              => l_return_status
             , x_msg_count                  => l_msg_count
             , x_msg_data                   => l_msg_data
             , x_cust_acct_contact_id       => l_cust_acct_cnt_id
             , x_cust_acct_contact_os       => l_cust_acct_cnt_os
             , x_cust_acct_contact_osr      => l_cust_acct_cnt_osr
             , px_parent_id                 => ln_parent_id
             , px_parent_os                 => lv_parent_os
             , px_parent_osr                => lv_parent_osr
             , px_parent_obj_type           => lv_parent_obj
            );
           END IF;
           */

           --MOVE THE FOLLOWING PERMISSION FLAG FOR 'S'/'M' TO
          /* IF p_permission_flag in ('S', 'M')
           THEN
           log_debug('API CALL FOR s/m');
           hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo
            ( p_init_msg_list              => fnd_api.g_true
             , p_validate_bo_flag           => fnd_api.g_false
             , p_cust_acct_contact_obj      => l_cust_acct_cnt_bo
             , p_created_by_module          => NULL
             , x_return_status              => l_return_status
             , x_msg_count                  => l_msg_count
             , x_msg_data                   => l_msg_data
             , x_cust_acct_contact_id       => l_cust_acct_cnt_id
             , x_cust_acct_contact_os       => l_cust_acct_cnt_os
             , x_cust_acct_contact_osr      => l_cust_acct_cnt_osr
             , px_parent_id                 => ln_parent_id
             , px_parent_os                 => lv_parent_os
             , px_parent_osr                => lv_parent_osr
             , px_parent_obj_type           => lv_parent_obj -- 'CUST_ACCT'
            );
           END IF;
           */



           IF(l_msg_count > 1) THEN
           FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
             log_debug(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
           END LOOP;
           END IF;

           IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
             NULL;
           ELSE
             raise le_bo_api_error;
           END IF;
           x_retcode := 0;
           x_party_id := ln_relationship_party_id;
           COMMIT;
        ELSE
          log_debug('This is a delete');
          x_retcode := 0;
        END IF;
	  EXCEPTION
        when le_bo_api_error then
          x_retcode := 206;
          xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0004_BO_API_FAILED'
          , p_error_message           => 'In Procedure: XX_EXTERNAL_USER_PKG.create_role_resp: Call to hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo failed for Contact:'|| p_cust_acct_cnt_osr
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
          raise;
      END;

     -- Role Responsibility using BO API'S end
   EXCEPTION
     when le_role_api_error then
       x_retcode := 207;
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
     when le_resp_api_error then
       x_retcode := 208;
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
     when others then
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
       x_retcode := 209;
       log_debug ('retcode: '|| x_retcode );
       xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.CREATE_ROLE_RESP'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0009_ERROR_IN_CUSTOMAPI'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.create_role_resp: Contact OSR: '||p_cust_acct_cnt_osr|| ' and Ship to OSR: '|| p_cust_acct_site_osr
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
       --raise;
   END create_role_resp;


   -- +===================================================================+
   -- | Name             : UPDATE_FND_USER                                |
   -- | Description      : This procedure assigns/end dates iReceivables  |
   -- |                    responsibilites and  assigns a party id to the |
   -- |                    bsd web user                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_username                                      |
   -- |                   p_end_date                                      |
   -- |                   p_action                                        |
   -- |                   p_org_id                                        |
   -- |                   x_retcode                                       |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE update_fnd_user
   ( p_username            IN       VARCHAR2
   , p_end_date            IN       DATE     DEFAULT NULL
   , p_action              IN       VARCHAR2
   , p_org_id              IN       NUMBER   DEFAULT NULL
   , p_bsd_access_code     IN       NUMBER   DEFAULT NULL
   , x_retcode             OUT      VARCHAR2
   )
   AS
  /* ======================================================================== */
  --  update_fnd_user assigns or end dates the iReceivables responsibilties
  --  and assigns a party id to the bsd web user if the action is 'C'
  --
  --  #param 1 p_username   user name from fnd_user table
  --  #param 2 p_end_date   end date for the responsibility
  --  #param 3 p_action     Create or Update ( 'C' or 'U')
  --  #param 4 p_org_id     US or Canadian org id
  --  #param 5 x_retcode    return success or failure

     ln_party_id   hz_parties.party_id%TYPE;
     ln_org_id    NUMBER (10);
     ln_userid     NUMBER (10);
     ln_resp_id   NUMBER;
     ln_appl_id    NUMBER;
     lv_org_name   VARCHAR2(240);
     l_bsd_access_code     NUMBER;
   BEGIN
     ln_org_id := p_org_id;

     BEGIN
       SELECT user_id
       INTO ln_userid
       FROM fnd_user
       WHERE upper(user_name) = upper(p_username);
     EXCEPTION
       when no_data_found then
         x_retcode := 109;
         xx_com_error_log_pub.log_error
           ( p_application_name        => 'XXCRM'
           , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
           , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPDATE_FND_USER'
           , p_module_name             => 'CDH'
           , p_error_message_code      => 'XX_CDH_0007_USERID_NOT_FOUND'
           , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: Username is not in fnd user table for :'|| p_username
           , p_error_message_severity  => 'MINOR'
           , p_error_status            => 'ACTIVE'
           , p_notify_flag             => 'Y'
           , p_recipient               => NULL
           );
         raise;
     END;

     IF ln_org_id is not null
     THEN
       -- changes to handle CR 299
       select name
       into lv_org_name
       from hr_all_organization_units
       where organization_id = ln_org_id;
     END IF;

     IF ( p_action = 'C' )
     THEN
       BEGIN
         SELECT party_id, bsd_access_code
         INTO ln_party_id, l_bsd_access_code
         FROM xxcrm.xx_external_users
         WHERE userid = substr(p_username, 4, length(p_username) );
       EXCEPTION
         when no_data_found then
           log_debug (' Party id is null ');
           x_retcode := 110;
           xx_com_error_log_pub.log_error
           ( p_application_name        => 'XXCRM'
           , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
           , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPDATE_FND_USER'
           , p_module_name             => 'CDH'
           , p_error_message_code      => 'XX_CDH_0006_PARTY_ID_NULL'
           , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: Partyid is null for username :'|| p_username
           , p_error_message_severity  => 'MAJOR'
           , p_error_status            => 'ACTIVE'
           , p_notify_flag             => 'Y'
           , p_recipient               => NULL
           );
           raise;
         when others then
           log_debug (' SQLCODE '|| sqlcode);
           log_debug (' SQLERRM '|| sqlerrm);
           x_retcode := 111;
           raise;
       END;

       IF p_org_id is null
       THEN
         BEGIN
           SELECT org_id
	       INTO ln_org_id
           FROM hz_cust_acct_sites_all
           WHERE cust_acct_site_id in ( select cust_acct_site_id
                                        from hz_cust_account_roles
                                        where party_id = ln_party_id
                                      );
         EXCEPTION
           when no_data_found then
             BEGIN
               select org_id into ln_org_id
               from hz_cust_acct_sites_all
               where orig_system_reference =
               ( select acct_site_osr from xxcrm.xx_external_users
                 where userid = substr(p_username, 4, length(p_username) )
               );
             EXCEPTION
               when no_data_found then
                 x_retcode := 112;
                 xx_com_error_log_pub.log_error
                 ( p_application_name        => 'XXCRM'
                 , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                 , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPDATE_FND_USER'
                 , p_module_name             => 'CDH'
                 , p_error_message_code      => 'XX_CDH_0008_ORG_ID_NULL'
                 , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: ORG ID is null for partyid :'|| ln_party_id
                 , p_error_message_severity  => 'MAJOR'
                 , p_error_status            => 'ACTIVE'
                 , p_notify_flag             => 'Y'
                 , p_recipient               => NULL
                 );
                 raise;
              END;
           when others then
             x_retcode := 113;
             raise;
         END;
       END IF;

       -- changes to handle CR 299
       select name
       into lv_org_name
       from hr_all_organization_units
       where organization_id = ln_org_id;


       fnd_user_pkg.updateuser ( x_user_name   => p_username
                               , x_owner       => 'CUST'
                               , x_customer_id => ln_party_id
                               );

       get_resp_id ( p_org_name         => lv_org_name
                   , p_bsd_access_code  => NVL(p_bsd_access_code , l_bsd_access_code)
                   , x_resp_id          => ln_resp_id
                   , x_appl_id          => ln_appl_id
                   );

       fnd_user_resp_groups_api.upload_assignment
       ( user_id                       => ln_userid
       , responsibility_id             => ln_resp_id --gcn_us_resp
       , responsibility_application_id => ln_appl_id
       , start_date                    => SYSDATE
       , end_date                      => p_end_date
       , description                   => 'OD AR iReceivables Account Management'
       );
       x_retcode := 0;
     ELSIF ( p_action = 'U' )
     THEN
       log_debug (' In update in update_fnd_user ');

       BEGIN
         log_debug (' Before Party id: ' );
         SELECT party_id
         INTO ln_party_id
         FROM xxcrm.xx_external_users
         WHERE userid = substr(p_username, 4, length(p_username) );

         log_debug (' Party id: '|| ln_party_id );

       EXCEPTION
         when no_data_found then
           log_debug (' Party id is null ');
           x_retcode := 114;
           xx_com_error_log_pub.log_error
           ( p_application_name        => 'XXCRM'
           , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
           , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPDATE_FND_USER'
           , p_module_name             => 'CDH'
           , p_error_message_code      => 'XX_CDH_0006_PARTY_ID_NULL'
           , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: Partyid is null for username :'|| p_username
           , p_error_message_severity  => 'MAJOR'
           , p_error_status            => 'ACTIVE'
           , p_notify_flag             => 'Y'
           , p_recipient               => NULL
           );
           raise;
         when others then
           log_debug (' SQLCODE '|| sqlcode);
           log_debug (' SQLERRM '|| sqlerrm);
           x_retcode := 115;
           raise;
       END;

       log_debug (' Before get resp id in update_fnd_user' );

       get_resp_id ( p_org_name         => lv_org_name
                   , p_bsd_access_code  => p_bsd_access_code
                   , x_resp_id          => ln_resp_id
                   , x_appl_id          => ln_appl_id
                   );
       log_debug (' Resp id: '|| ln_resp_id );
       log_debug (' Appl id: '|| ln_appl_id );

       fnd_user_resp_groups_api.upload_assignment
       ( user_id                       => ln_userid
       , responsibility_id             => ln_resp_id --gcn_us_resp
       , responsibility_application_id => ln_appl_id -- 222
       , start_date                    => SYSDATE
       , end_date                      => p_end_date
       , description                   => 'OD AR iReceivables Account Management'
       );
       x_retcode := 0;
     ELSE
        get_resp_id ( p_org_name         => lv_org_name
                    , p_bsd_access_code  => p_bsd_access_code
                    , x_resp_id          => ln_resp_id
                    , x_appl_id          => ln_appl_id
                    );
        fnd_user_resp_groups_api.upload_assignment
         ( user_id                            => ln_userid
         , responsibility_id                  => ln_resp_id --gcn_us_resp
         , responsibility_application_id      => ln_appl_id
         , start_date                         => SYSDATE
         , end_date                           => p_end_date
         , description                        => 'OD AR iReceivables Account Management'
         );
     END IF;
     x_retcode := 0;
   EXCEPTION
     when others then
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
       x_retcode := 116;
       raise;
   END update_fnd_user;

   -- +===================================================================+
   -- | Name             : SAVE_EXT_USER                                  |
   -- | Description      : This procedure does a insert or update of      |
   -- |                    web user information into xx_external_users    |
   -- |                    table based on the information coming to       |
   -- |                    Oracle EBS from AOPS. This procedure is called |
   -- |                    from SaveiReceivables BPEL process             |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_userid                                        |
   -- |                   p_password                                      |
   -- |                   p_first_name                                    |
   -- |                   p_middle_initial                                |
   -- |                   p_last_name                                     |
   -- |                   p_email                                         |
   -- |                   p_status                                        |
   -- |                   p_contact_osr                                   |
   -- |                   p_acct_site_osr                                 |
   -- |                   p_site_key                                      |
   -- |                   p_avolent_code                                  |
   -- |                   p_bsd_access_code                               |
   -- |                   p_permission_flag                               |
   -- |                   p_resp_key                                      |
   -- |                   p_party_id                                      |
   -- |                   x_retcode                                       |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE save_ext_user
   ( p_userid            IN       VARCHAR2
   , p_password          IN       VARCHAR2
   , p_first_name        IN       VARCHAR2
   , p_middle_initial    IN       VARCHAR2
   , p_last_name         IN       VARCHAR2
   , p_email             IN       VARCHAR
   , p_status            IN       VARCHAR2 DEFAULT '0'
   , p_contact_osr       IN       VARCHAR2
   , p_acct_site_osr     IN       VARCHAR2 DEFAULT NULL
   , p_site_key          IN       VARCHAR2 DEFAULT NULL
   , p_avolent_code      IN       VARCHAR2 DEFAULT NULL
   , p_bsd_access_code   IN       NUMBER   DEFAULT NULL
   , p_permission_flag   IN       VARCHAR  DEFAULT NULL
   , p_resp_key          IN       NUMBER   DEFAULT NULL
   , p_party_id          IN       NUMBER   DEFAULT NULL
   , x_retcode           OUT      VARCHAR2
   )
   AS
  /* ======================================================================== */
  --  save_ext_user procedure does a insert or update of web user information
  --  into xx_external_users tables based on the information coming
  --  to Oracle EBS from AOPS. This procedue is called from SaveiReceivables
  --  BPEL process
  --
  --  #param 1  p_userid          BSD web user id from AOPS
  --  #param 2  p_password        BSD web password from AOPS
  --  #param 3  p_first_name      first name of BSD web user
  --  #param 4  p_middle_initial  middle initial of bsd web user
  --  #param 5  p_last_name       lastname of BSD web user
  --  #param 6  p_email           email of BSD web user
  --  #param 7  p_status          Active(0) or Inactive(1) status of web user
  --  #param 8  p_contact_osr     Unique ID of contact from AOPS
  --  #param 9  p_acct_site_osr   Unique ID of account site from AOPS
  --  #param 10 p_site_key        Site key to maintain uniqueness in OID
  --  #param 11 p_avolent_code    This will have a value of AV for Avolent
  --  #param 12 p_bsd_access_code Access code to control privileges
  --  #param 13 p_resp_key        Not used
  --  #param 14 p_party_id        Party id of the relationship of contact
  --                              with account site
  --  #param 15 p_action          Has not been updated with store proc signature,
  --                              need to pass in (Y.Ali 01/02/2008)
  --  #param 16 x_retcode         return success or failure


     ln_retcode                   NUMBER;
     ln_create_role_resp_retcode  NUMBER;
     ln_count                     NUMBER;
     ext_user_cur                 XXCRM.XX_EXTERNAL_USERS%ROWTYPE;
     ln_org_id                    HZ_CUST_ACCT_SITES_ALL.ORG_ID%TYPE;
     ln_party_id                  NUMBER;

     le_party_id_null     EXCEPTION;
     le_update_fnd_failed EXCEPTION;

   BEGIN

     log_debug (to_char(sysdate,'mm/dd/yyyy hh:mi:ss AM') ||' *** PROCEDURE save_ext_user **** ');
     FND_GLOBAL.APPS_INITIALIZE(58590, 50658, 20049);
     MO_GLOBAL.INIT;
     MO_GLOBAL.SET_POLICY_CONTEXT('S', 404);
      FND_MSG_PUB.INITIALIZE;



    /*
     ln_party_id := p_party_id;

     IF p_avolent_code = 'AV'
     THEN
        BEGIN
            create_role_resp('A0'
            , p_contact_osr
            , p_acct_site_osr  -- this parameter is used for account_osr when an AV message is being processed
            , 'C' --p_action
            , p_permission_flag
            , ln_party_id
            , ln_create_role_resp_retcode
            );

            log_debug ('Party id from CREATE_ROLE_RESP API call: ' || ln_party_id);
            --ln_party_id := p_party_id;
            log_debug ('Return code from CREATE_ROLE_RESP API call: ' || ln_create_role_resp_retcode);

        EXCEPTION
          when no_data_found then
            log_debug ('NO party ID FOUND from CREATE_ROLE_RESP API call');
          raise;

          when others then
            log_debug ('DO NOT KNOW ISSUE with CREATE_ROLE_RESP API call');
          raise;
        END;
     END IF;
     */
     ln_count := 0;
     SELECT count(*) into ln_count
     FROM xxcrm.xx_external_users
     WHERE userid = p_userid;

     log_debug ('Here is the PARTY ID: '||p_party_id);

     IF ln_count = 0
     THEN
       IF p_party_id is not null --ln_party_id
       THEN
         BEGIN
           log_debug ('BEFORE org id');
     /*
           select org_id into ln_org_id
           from hz_cust_acct_sites_all
           where cust_acct_site_id =
           ( select cust_acct_site_id from hz_cust_account_roles
             where party_id = p_party_id --ln_party_id
           );

     */

          select org_id into ln_org_id
           from hz_cust_acct_sites_all asa,hz_cust_account_roles car
           where asa.cust_acct_site_id = car.cust_acct_site_id
           and   car.party_id = p_party_id
           and   car.orig_system_reference = p_contact_osr;

          log_debug ('after org id');

         EXCEPTION
           when no_data_found then
             BEGIN
               select org_id into ln_org_id
               from hz_cust_acct_sites_all
               where orig_system_reference = p_acct_site_osr;
             EXCEPTION
               when no_data_found then
                 x_retcode := 100;
                 xx_com_error_log_pub.log_error
                 ( p_application_name        => 'XXCRM'
                 , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                 , p_program_name            => 'XX_EXTERNAL_USERS_PKG.SAVE_EXT_USER'
                 , p_module_name             => 'CDH'
                 , p_error_message_code      => 'XX_CDH_0008_ORG_ID_NULL'
                 , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.save_ext_user: ORG ID is null for partyid :'|| p_party_id --ln_party_id
                 , p_error_message_severity  => 'MAJOR'
                 , p_error_status            => 'ACTIVE'
                 , p_notify_flag             => 'Y'
                 , p_recipient               => NULL
                 );
                 raise;
             END;
           when too_many_rows then
             BEGIN
               select org_id into ln_org_id
               from hz_cust_acct_sites_all
               where orig_system_reference = p_acct_site_osr;
             EXCEPTION
               when no_data_found then
                 x_retcode := 1001;
                 xx_com_error_log_pub.log_error
                 ( p_application_name        => 'XXCRM'
                 , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                 , p_program_name            => 'XX_EXTERNAL_USERS_PKG.SAVE_EXT_USER'
                 , p_module_name             => 'CDH'
                 , p_error_message_code      => 'XX_CDH_0008_ORG_ID_NULL'
                 , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.save_ext_user: ORG ID is null for partyid :'|| p_party_id --ln_party_id
                 , p_error_message_severity  => 'MAJOR'
                 , p_error_status            => 'ACTIVE'
                 , p_notify_flag             => 'Y'
                 , p_recipient               => NULL
                 );
                 raise;
             END;
           when others then
             x_retcode := 101;
             raise;
         END;
          log_debug ('Before inserting user');
         insert_ext_user ( p_userid
                         , p_password
                         , p_first_name
                         , p_middle_initial
                         , p_last_name
                         , p_email
                         , p_party_id --ln_party_id
                         , p_status
                         , p_contact_osr
                         , p_acct_site_osr
                         , xx_external_users_pkg.gcn_site_key
                         , p_avolent_code
                         , p_bsd_access_code
                         , p_permission_flag
                         , ln_org_id
                         );
         COMMIT;
         log_debug ('After inserting user');
       ELSE
         raise le_party_id_null;
       END IF;
     ELSE
     /*
       00 -  No Reporting
       01 -  Usage Reporting Only
       02 -  Usage and Billing
       03 -  Billing Only
     */
       IF p_avolent_code = 'AV'
       THEN
         BEGIN
           select org_id
           into ln_org_id
           from hz_cust_acct_sites_all
           where cust_acct_site_id =
           ( select cust_acct_site_id
             from hz_cust_account_roles
             where party_id = ( select party_id from xxcrm.xx_external_users
                                where userid = p_userid )
             and cust_acct_site_id IS NOT NULL
           );
         EXCEPTION
           when no_data_found then
             BEGIN
               select org_id into ln_org_id
               from hz_cust_acct_sites_all
               where orig_system_reference =
               ( select acct_site_osr from xxcrm.xx_external_users
                 where userid = p_userid
               );
             EXCEPTION
               when no_data_found then
                 x_retcode := 102;
                 xx_com_error_log_pub.log_error
                 ( p_application_name        => 'XXCRM'
                 , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                 , p_program_name            => 'XX_EXTERNAL_USERS_PKG.SAVE_EXT_USER'
                 , p_module_name             => 'CDH'
                 , p_error_message_code      => 'XX_CDH_0008_ORG_ID_NULL'
                 , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.save_ext_user: ORG ID null for partyid of user :'|| p_userid
                 , p_error_message_severity  => 'MAJOR'
                 , p_error_status            => 'ACTIVE'
                 , p_notify_flag             => 'Y'
                 , p_recipient               => NULL
                 );
                 raise;
             END;
           when others then
             x_retcode := 103;
             raise;
         END;

         FOR cur_ext in ( select * from xxcrm.xx_external_users
                          where userid = p_userid )
         LOOP
           IF cur_ext.bsd_access_code IN ( 2, 3 )
           AND p_bsd_access_code NOT IN ( 2, 3 )
           THEN
             log_debug ( '2, 3');
             update_ext_user ( p_userid          => p_userid
                             , p_bsd_access_code => p_bsd_access_code
                             );
             log_debug ( 'FND USER: '||gcn_site_key||p_userid);
             update_fnd_user ( p_username        => gcn_site_key||p_userid
                             , p_end_date        => SYSDATE
                             , p_action          => 'D'
                             , p_org_id          => ln_org_id
                             , p_bsd_access_code => cur_ext.bsd_access_code
                             , x_retcode         => ln_retcode
                             );

             IF p_bsd_access_code in (5, 6)
             THEN
               update_fnd_user ( p_username        => gcn_site_key||p_userid
                               , p_end_date        => NULL
                               , p_action          => 'U'
                               , p_org_id          => ln_org_id
                               , p_bsd_access_code => p_bsd_access_code
                               , x_retcode         => ln_retcode
                               );
             END IF;



             IF ln_retcode = 1
             THEN
               log_debug ( 'Update fnd user failed');
               raise le_update_fnd_failed;
             END IF;
             COMMIT;
           -- Added to handle Change request CR 299 for access codes 5 and 6
           ELSIF cur_ext.bsd_access_code IN ( 5, 6 )
           AND p_bsd_access_code NOT IN ( 5, 6 )
           THEN
             log_debug ( '5,6');
             update_ext_user ( p_userid          => p_userid
                             , p_bsd_access_code => p_bsd_access_code
                             );
             log_debug ( 'FND USER: '||gcn_site_key||p_userid);
             update_fnd_user ( p_username        => gcn_site_key||p_userid
                             , p_end_date        => SYSDATE
                             , p_action          => 'D'
                             , p_org_id          => ln_org_id
                             , p_bsd_access_code => cur_ext.bsd_access_code
                             , x_retcode         => ln_retcode
                             );
             IF p_bsd_access_code in (2, 3)
             THEN
               update_fnd_user ( p_username        => gcn_site_key||p_userid
                               , p_end_date        => NULL
                               , p_action          => 'U'
                               , p_org_id          => ln_org_id
                               , p_bsd_access_code => p_bsd_access_code
                               , x_retcode         => ln_retcode
                               );
             END IF;

             IF ln_retcode = 1
             THEN
               log_debug ( 'Update fnd user failed');
               raise le_update_fnd_failed;
             END IF;
             COMMIT;
           ELSIF nvl(cur_ext.bsd_access_code,0) in (0, 4)
           AND p_bsd_access_code IN ( 2, 3, 5, 6 )
           THEN
             log_debug ( 'BSD Code 2, 3, 5, 6');
             update_ext_user ( p_userid          => p_userid
                             , p_bsd_access_code => p_bsd_access_code
                             );
             log_debug ( 'FND USER: '||gcn_site_key||p_userid);
             update_fnd_user ( p_username        => gcn_site_key||p_userid
                             , p_action          => 'U'
                             , p_org_id          => ln_org_id
                             , p_bsd_access_code => p_bsd_access_code
		                     , x_retcode         => ln_retcode
                             );
             IF ln_retcode = 1
             THEN
               log_debug ( 'Update fnd user failed');
               raise le_update_fnd_failed;
             END IF;

             COMMIT;
           END IF;
         END LOOP;
       END IF;
     END IF;
     x_retcode := 0;
   EXCEPTION
     when le_party_id_null then
       x_retcode := 130;
       --raise;
     when le_update_fnd_failed then
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
       x_retcode := 116;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.SAVE_EXT_USER'
       , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0005_UPDATE_FND_USER_FAILED'
       , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: Failed for username :'|| p_userid
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
       --raise;
     when others then
       log_debug ('sqlcode: '|| sqlcode );
       log_debug ('sqlerrm: '|| sqlerrm );
       x_retcode := 117;
       --raise;
   END save_ext_user;

   -- +===================================================================+
   -- | Name             : INSERT_EXT_USER                                |
   -- | Description      : This procedure inserts web user information    |
   -- |                    coming to Oracle EBS from AOPS into            |
   -- |                    xx_external_users tables                       |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters :      p_userid                                        |
   -- |                   p_password                                      |
   -- |                   p_first_name                                    |
   -- |                   p_middle_initial                                |
   -- |                   p_last_name                                     |
   -- |                   p_email                                         |
   -- |                   p_party_id                                      |
   -- |                   p_status                                        |
   -- |                   p_contact_osr                                   |
   -- |                   p_acct_site_osr                                 |
   -- |                   p_site_key                                      |
   -- |                   p_avolent_code                                  |
   -- |                   p_bsd_access_code                               |
   -- |                   p_permsion_flag                                 |
   -- |                   p_resp_key                                      |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE insert_ext_user
   ( p_userid            IN   VARCHAR2,
     p_password          IN   VARCHAR2,
     p_first_name        IN   VARCHAR2,
     p_middle_initial    IN   VARCHAR2,
     p_last_name         IN   VARCHAR2,
     p_email             IN   VARCHAR,
     p_party_id          IN   HZ_PARTIES.PARTY_ID%TYPE,
     p_status            IN   VARCHAR2,
     p_contact_osr       IN   VARCHAR2,
     p_acct_site_osr     IN   VARCHAR2,
     p_site_key          IN   VARCHAR2,
     p_avolent_code      IN   VARCHAR2,
     p_bsd_access_code   IN   NUMBER,
     p_permission_flag   IN   VARCHAR2,
     p_resp_key          IN   NUMBER
   )
   IS
  /* ======================================================================== */
  --  insert_ext_user procedure inserts web user information coming to Oracle
  --  EBS from AOPS into xx_external_users tables.
  --  This procedire is called from save_ext_user
  --
  --  #param 1  p_userid          BSD web user id from AOPS
  --  #param 2  p_password        BSD web password from AOPS
  --  #param 3  p_first_name      first name of BSD web user
  --  #param 4  p_middle_initial  middle initial of bsd web user
  --  #param 5  p_last_name       lastname of BSD web user
  --  #param 6  p_email           email of BSD web user
  --  #param 7  p_party_id        Party id of the relationship of contact
  --                              with account site
  --  #param 8  p_status          Active or Inactive status of web user
  --  #param 9  p_contact_osr     Unique ID of contact from AOPS
  --  #param 10  p_acct_site_osr   Unique ID of account site from AOPS
  --  #param 12 p_site_key        Site key to maintain uniqueness in OID
  --  #param 12 p_avolent_code    This will have a value of AV for Avolent
  --  #param 13 p_bsd_access_code Access code to control privileges
  --  #param 14 p_permission_flag Determines if contact relationship must
  --                              exist for bill to account site or account
  --  #param 15 p_resp_key        Not used

     ln_resp_key   NUMBER (30);
   BEGIN

     INSERT INTO xxcrm.xx_external_users
                        ( ext_user_id
                        , userid
                        , password
                        , person_first_name
                        , person_middle_name
                        , person_last_name
                        , email
                        , party_id
                        , status
                        , contact_osr
                        , acct_site_osr
                        , bsd_access_code
                        , permission_flag
                        , site_key
                        , irec_responsibility_id
                        , created_by
                        , creation_date
                        , last_update_date
                        , last_updated_by
                        , last_update_login
                        )
                 VALUES ( xxcrm.xx_external_users_s.NEXTVAL
                        , p_userid
                        , p_password
                        , p_first_name
                        , p_middle_initial
                        , p_last_name
                        , p_email
                        , p_party_id
                        , p_status
                        , p_contact_osr
                        , p_acct_site_osr
                        , p_bsd_access_code
                        , p_permission_flag
                        , p_site_key
                        , ln_resp_key
                        , uid
                        , SYSDATE
                        , SYSDATE
                        , uid
                        , uid
                        );
   EXCEPTION
     when others then
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.INSERT_EXT_USER'
       , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0010_INSERT_EXT_USER_FAILED'
       , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.insert_ext_user: Failed for username :'|| p_userid
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
       raise;
   END insert_ext_user;

  -- +===================================================================+
  -- | Name             : UPDATE_EXT_USER                                |
  -- | Description      : This procedure updates web user information    |
  -- |                    coming to Oracle EBS from AOPS into            |
  -- |                    xx_external_users tables                       |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters :      p_userid                                        |
  -- |                   p_bsd_access_code                               |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE update_ext_user
  ( p_userid            IN   VARCHAR2
  , p_bsd_access_code   IN   NUMBER
  )
  IS
  /* ======================================================================== */
  --  update_ext_user procedure updates web user information coming to Oracle
  --  EBS from AOPS into xx_external_users tables.
  --  This procedire is called from save_ext_user
  --
  --  #param 1  p_userid          BSD web user id from AOPS
  --  #param 2  p_bsd_access_code BSD access code to manage privileges

    ln_resp_key   NUMBER (30);
  BEGIN

    UPDATE xxcrm.xx_external_users
    SET bsd_access_code        = p_bsd_access_code
      , last_update_date       = SYSDATE
      , last_updated_by        = uid
      , last_update_login      = uid
    WHERE userid = p_userid;
  EXCEPTION
    when others then
      xx_com_error_log_pub.log_error
       ( p_application_name        => 'XXCRM'
       , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
       , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPDATE_EXT_USER'
       , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0011_UPDATE_EXT_USER_FAILED'
       , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_ext_user: Failed for username :'|| p_userid
       , p_error_message_severity  => 'MAJOR'
       , p_error_status            => 'ACTIVE'
       , p_notify_flag             => 'Y'
       , p_recipient               => NULL
       );
      raise;
  END update_ext_user;

/*
  PROCEDURE insert_shipto_map
  ( p_userid            IN   VARCHAR2
  , p_acct_site_osr     IN   VARCHAR2
  , p_end_date          IN   DATE default null
  )
  IS

  BEGIN

    INSERT INTO xxcrm.xx_ext_usr_shipto_map
    ( ext_usr_map_id
    , userid
    , shipto_osr
    , start_date
    , end_date
    , created_by
    , creation_date
    , last_update_date
    , last_updated_by
    , last_update_login
    )
    VALUES ( xxcrm.xx_ext_usr_shipto_map_s.NEXTVAL
           , p_userid
           , p_acct_site_osr
           , SYSDATE
           , nvl(p_end_date,NULL)
           , uid
           , SYSDATE
           , SYSDATE
           , uid
           , uid
           );
  EXCEPTION
    when others then
    raise;
  END insert_shipto_map;


  PROCEDURE update_shipto_map
  ( p_userid            IN   VARCHAR2
  , p_end_date          IN   DATE
  )
  IS
  BEGIN
    UPDATE xxcrm.xx_ext_usr_shipto_map
    SET end_date          = p_end_date
      , last_update_date  = SYSDATE
      , last_updated_by   = uid
      , last_update_login = uid
    WHERE userid = p_userid;
  EXCEPTION
    when others then
    raise;
  END update_shipto_map;
*/

  -- +===================================================================+
  -- | Name             : GET_FND_CREATE_EVENT                           |
  -- | Description      : This function is trigerred from a business     |
  -- |                    event oracle.apps.fnd.user.insert when a new   |
  -- |                    BSD web user is synchronized from OID into     |
  -- |                    fnd_user table. This function calls            |
  -- |                    update_fnd_user to grant the new user          |
  -- |                    iReceivables responsibilities and assign       |
  -- |                    the party id                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters :      p_subscription_guid                             |
  -- |                   p_event                                         |
  -- |                                                                   |
  -- +===================================================================+

  FUNCTION get_fnd_create_event
  ( p_subscription_guid IN RAW
  , p_event IN OUT NOCOPY WF_EVENT_T
  )
  RETURN VARCHAR2
  /* ======================================================================== */
  --  get_fnd_create_event calls update_fnd_user to grant the new user
  -- iReceivables responsibilities and assign the party id
  --
  --  #param 1  p_subscription_guid  GUID of the subscription to the
  --                                 business event
  --  #param 2  p_event              Event name oracle.apps.fnd.user.insert

  AS
    -- oracle.apps.fnd.user.insert
    --Declaring local variable
    ln_count             PLS_INTEGER;
    ln_org_id            NUMBER;
	ln_user_id           NUMBER;
	ln_resp_id           NUMBER;
    ln_resp_appl_id      NUMBER;
    ln_security_group_id NUMBER;
    lv_user_name         FND_USER.USER_NAME%TYPE;
    lv_retcode           VARCHAR2(10);
    lv_oid_retcode       VARCHAR2(10);

    l_param_name     VARCHAR2(2000);
    l_param_value    VARCHAR2(2000);
    l_event_name     VARCHAR2(2000);
    l_event_key      VARCHAR2(2000);
    l_parameter_list WF_PARAMETER_LIST_T := wf_parameter_list_t();

    le_update_fnd_user_failed  EXCEPTION;
    le_oid_pwd_update_failed   EXCEPTION;
  BEGIN

     log_debug ('*** BES Subscription get_fnd_create_event **** ');

    --Obtaining the event parameter values
    ln_org_id := p_event.GetValueForParameter('ORG_ID');
    ln_user_id := p_event.GetValueForParameter('USER_ID');
    ln_resp_id := p_event.GetValueForParameter('RESP_ID');
    ln_resp_appl_id := p_event.GetValueForParameter('RESP_APPL_ID');
    ln_security_group_id := p_event.GetValueForParameter('SECURITY_GROUP_ID');

    --Initializing the application environment
    --fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id, ln_security_group_id);

    l_event_name := p_event.geteventname();
    -- event key is the userid from fnd user table
    l_event_key  := p_event.geteventkey();
    l_parameter_list := p_event.getparameterlist;
    log_debug ('EVENTNAME: '||l_event_name );
    log_debug ('EVENTKEY: '|| l_event_key );
    log_debug ('ln_user_id: '|| ln_user_id );
    log_debug ('ln_org_id: '|| ln_org_id );
    log_debug ('ln_resp_id: '|| ln_resp_id );
    log_debug ('ln_resp_appl_id: '|| ln_resp_appl_id );
    log_debug ('ln_security_group_id: '|| ln_security_group_id );

/*
  IF l_parameter_list IS NOT NULL THEN
    log_debug ('count: '||l_parameter_list.count );
    for i in l_parameter_list.first..l_parameter_list.last
    loop
      -- log_debug ('list count: '||i );
      l_param_name  := l_parameter_list(i).getname;
      l_param_value := l_parameter_list(i).getvalue;
      log_debug ('EVENTNAME: '||l_param_name );
      log_debug ('EVENTKEY: '|| l_param_value );

      insert into fnd_user_event values( l_param_name, l_param_value );

      IF l_param_name = 'USER_ID' THEN
        insert into fnd_event_test(user_id) values ( ln_user_id );
      END IF;
    end loop;
  END IF;

    insert into xx_fnd_event_test
    values ( l_event_key, SYSDATE, 1);
    commit;
*/
    select user_name into lv_user_name
    from fnd_user
    where user_id = l_event_key;

    update_fnd_user ( p_username  => lv_user_name
                    , p_action    => 'C'
                    , x_retcode   => lv_retcode
                    );
    IF lv_retcode <> 0
    THEN
      raise le_update_fnd_user_failed;
    END IF;
    COMMIT;

/*
    process_oid ( p_username => lv_user_name
                , x_retcode  => lv_oid_retcode
                );

    IF lv_retcode <> 0
    THEN
      raise le_oid_pwd_update_failed;
    END IF;
*/
    RETURN 'SUCCESS';
  EXCEPTION
    when le_update_fnd_user_failed then
      log_debug('XX_CDH_0005_UPDATE_FND_USER_FAILED');
      xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.GET_FND_CREATE_EVENT'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0005_UPDATE_FND_USER_FAILED'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.update_fnd_user: Failed for username :'|| lv_user_name
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
      RETURN 'ERROR';
    when le_oid_pwd_update_failed then
      log_debug('XX_CDH_0005_UPDATE_FND_USER_FAILED');
      xx_com_error_log_pub.log_error
          ( p_application_name        => 'XXCRM'
          , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
          , p_program_name            => 'XX_EXTERNAL_USERS_PKG.GET_FND_CREATE_EVENT'
          , p_module_name             => 'CDH'
          , p_error_message_code      => 'XX_CDH_0005_UPDATE_FND_USER_FAILED'
          , p_error_message           => 'In Procedure:XX_EXTERNAL_USERS_PKG.process_oid: Failed for username :'|| lv_user_name
          , p_error_message_severity  => 'MAJOR'
          , p_error_status            => 'ACTIVE'
          , p_notify_flag             => 'Y'
          , p_recipient               => NULL
          );
      RETURN 'ERROR';
    when others then
      log_debug ('SQLCODE: '||sqlcode);
      log_debug ('SQLERRM: '||sqlerrm);
      log_debug (' Event insert failed');
      xx_com_error_log_pub.log_error
      ( p_application_name        => 'XXCRM'
      , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
      , p_program_name            => 'XX_EXTERNAL_USERS_PKG.GET_FND_CREATE_EVENT'
      , p_module_name             => 'CDH'
      , p_error_message_code      => 'XX_CDH_0015_UNKNOWN_ERROR'
      , p_error_message           => 'SQLCODE: '|| sqlcode || ' SQLERRM: '||sqlerrm
      , p_error_message_severity  => 'MAJOR'
      , p_error_status            => 'ACTIVE'
      , p_notify_flag             => 'Y'
      , p_recipient               => NULL
      );

      /*
	  WF_CORE.CONTEXT( 'XX_EXTERNAL_USER_PKG'
                     , 'get_fnd_create_event'
                     , p_event.getEventName()
                     , p_subscription_guid
                     );
      WF_EVENT.setErrorInfo(p_event, 'ERROR');

     insert into xx_fnd_event_test
     values ( l_event_key, SYSDATE, 2);
     commit;
    */
     RETURN 'ERROR';
  END  get_fnd_create_event;

  -- +===================================================================+
  -- | Name             : UPD_PWD                                        |
  -- | Description      : This procedure updates the bsd web user        |
  -- |                    password in xx_external_users table.           |
  -- |                    This procedure is called from UpdateExtUserPwd |
  -- |                    BPEL process                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters :      p_userid                                        |
  -- |                   p_pwd                                           |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE upd_pwd ( p_userid  IN   VARCHAR2
                    , p_pwd     IN   VARCHAR2
                    )
  IS
  /* ======================================================================== */
  --  upd_pwd updates the bsd web user password in xx_external_users
  --  table. This procedure is called from UpdateExtUserPwd BPEL process
  --
  --  #param 1  p_userid  BSD web user userid
  --  #param 2  p_pwd     BSD web user password

  BEGIN
    update xxcrm.xx_external_users
	set password = p_pwd
      , last_update_date  = SYSDATE
      , last_updated_by   = uid
      , last_update_login = uid
    where userid = p_userid;
  EXCEPTION
    when others then
      xx_com_error_log_pub.log_error
      ( p_application_name        => 'XXCRM'
      , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
      , p_program_name            => 'XX_EXTERNAL_USERS_PKG.UPD_PWD'
      , p_module_name             => 'CDH'
      , p_error_message_code      => 'XX_CDH_0015_UNKNOWN_ERROR'
      , p_error_message           => 'SQLCODE: '|| sqlcode || ' SQLERRM: '||sqlerrm
      , p_error_message_severity  => 'MAJOR'
      , p_error_status            => 'ACTIVE'
      , p_notify_flag             => 'Y'
      , p_recipient               => NULL
      );
  END upd_pwd;

  PROCEDURE get_resp_id ( p_org_name        IN VARCHAR2
                        , p_bsd_access_code IN NUMBER
                        , x_resp_id         OUT NUMBER
                        , x_appl_id         OUT NUMBER
                        )
  IS
    ln_application_id     NUMBER;
    ln_resp_id            NUMBER;
    lv_resp_key           VARCHAR2(50);
    lv_target_value2_out  VARCHAR2(50);
    lv_target_value3_out  VARCHAR2(50);
    lv_target_value4_out  VARCHAR2(50);
    lv_target_value5_out  VARCHAR2(50);
    lv_target_value6_out  VARCHAR2(50);
    lv_target_value7_out  VARCHAR2(50);
    lv_target_value8_out  VARCHAR2(50);
    lv_target_value9_out  VARCHAR2(50);
    lv_target_value10_out VARCHAR2(50);
    lv_target_value11_out VARCHAR2(50);
    lv_target_value12_out VARCHAR2(50);
    lv_target_value13_out VARCHAR2(50);
    lv_target_value14_out VARCHAR2(50);
    lv_target_value15_out VARCHAR2(50);
    lv_target_value16_out VARCHAR2(50);
    lv_target_value17_out VARCHAR2(50);
    lv_target_value18_out VARCHAR2(50);
    lv_target_value19_out VARCHAR2(50);
    lv_target_value20_out VARCHAR2(50);
    lv_error_message      VARCHAR2(50);
Begin


  APPS.XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
  ( p_translation_name =>  'XX_IREC_RESP_ACCESS_MAP'
  , p_source_value1    =>  p_org_name
  , p_source_value2    =>  p_bsd_access_code
  , x_target_value1    =>  lv_resp_key
  , x_target_value2    =>  lv_target_value2_out
  , x_target_value3    =>  lv_target_value3_out
  , x_target_value4    =>  lv_target_value4_out
  , x_target_value5    =>  lv_target_value5_out
  , x_target_value6    =>  lv_target_value6_out
  , x_target_value7    =>  lv_target_value7_out
  , x_target_value8    =>  lv_target_value8_out
  , x_target_value9    =>  lv_target_value9_out
  , x_target_value10   =>  lv_target_value10_out
  , x_target_value11   =>  lv_target_value11_out
  , x_target_value12   =>  lv_target_value12_out
  , x_target_value13   =>  lv_target_value13_out
  , x_target_value14   =>  lv_target_value14_out
  , x_target_value15   =>  lv_target_value15_out
  , x_target_value16   =>  lv_target_value16_out
  , x_target_value17   =>  lv_target_value17_out
  , x_target_value18   =>  lv_target_value18_out
  , x_target_value19   =>  lv_target_value19_out
  , x_target_value20   =>  lv_target_value20_out
  , x_error_message    =>  lv_error_message
  );
    log_debug( 'Resp'||lv_resp_key);
    select responsibility_id , application_id
    into ln_resp_id, ln_application_id
    from fnd_responsibility where responsibility_key = lv_resp_key;
    x_resp_id := ln_resp_id;
    x_appl_id := ln_application_id;
    log_debug( 'Resp ID '||ln_resp_id);
    log_debug( 'Appl ID '||ln_application_id);
  EXCEPTION
    when others then
      log_debug( 'Error in get_resp_id');
  END get_resp_id;

END XX_EXTERNAL_USERS_PKG;
/