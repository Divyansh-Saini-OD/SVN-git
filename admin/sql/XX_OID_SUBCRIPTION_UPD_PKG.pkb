create or replace PACKAGE BODY XX_OID_SUBSCRIPTION_UPD_PKG
AS
    -- +===================================================================================+
    -- |                              Office Depot Inc.                                    |
    -- +===================================================================================+
    -- | Name             :  XX_OID_SUBSCRIPTION_UPD_PKG  E1328(Defect # 35947)            |
    -- | Description      :  This process handles validating if a external user            |
    -- |                     subscription exists and if user subscription does not exist   |
    -- |                     then we create subscription for the user using LDAP APIs      |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date         Author           Remarks                                    |
    -- |=======   ==========   =============    ======================                     |
    -- | 1.0     10-SEP-2015  Manikant Kasu     Initial version                            |
	-- | 1.1     30-JUN-2016  Vasu Raparla      Added Procedure to purge table             |
    -- |                                         XX_COM_OID_ERROR_LOG                      |
	-- | 1.2     20-Jul-2016  Vasu Raparla      Code changes to write into log file when   |
	-- |                                        log_debug_msg is called                    |
    -- +===================================================================================+
    
    --Global Variables
    G_INTERNAL          CONSTANT VARCHAR2(9)  := '#INTERNAL';
    G_LDAP_SYNCH        CONSTANT VARCHAR2(10) := 'LDAP_SYNCH';
    G_HOST              CONSTANT VARCHAR2(4)  := 'HOST';
    G_PORT              CONSTANT VARCHAR2(4)  := 'PORT';
    G_USERNAME          CONSTANT VARCHAR2(8)  := 'USERNAME';
    G_EPWD              CONSTANT VARCHAR2(4)  := 'EPWD';
    G_LDAP_PWD          CONSTANT VARCHAR2(8)  := 'LDAP_PWD';
    G_DBLDAPAUTHLEVEL   CONSTANT VARCHAR2(15) := 'dbldapauthlevel';
    G_DBWALLETDIR       CONSTANT VARCHAR2(11) := 'dbwalletdir';
    G_DBWALLETPASS      CONSTANT VARCHAR2(12) := 'dbwalletpass';
    
    G_SUBSCRIBED        CONSTANT VARCHAR2(10) := 'SUBSCRIBED';
    G_NOT_SUBSCRIBED    CONSTANT VARCHAR2(14) := 'NOT_SUBSCRIBED';
    G_CORRUPT_OWNERGUID CONSTANT VARCHAR2(17) := 'CORRUPT_OWNERGUID';
    G_CORRUPT_UNIQUE    CONSTANT VARCHAR2(14) := 'CORRUPT_UNIQUE';
    
    g_proc              VARCHAR2(80) := NULL;
    g_debug             VARCHAR2(1)  := 'N';
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : log_debug_msg                                     |
    -- | Description      :                                                   |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    PROCEDURE log_debug_msg ( p_proc               IN  VARCHAR2
                             ,p_debug_msg          IN  VARCHAR2 )
    IS
     ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
     ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
     lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
    
    BEGIN
      
      IF (fnd_profile.value_wnps('XX_OID_SUBSCRIPTION_DEBUG_MODE') = 'Y' OR g_debug = 'Y') THEN
        XX_COM_OID_ERROR_LOG_PKG.log_error
          (
           p_module_name             => 'XXOID'    
          ,p_attribute15             => 'XX_OID_SUBSCRIPTION_UPD_PKG'
          ,p_attribute16             => p_proc
          ,p_error_message           => p_debug_msg
          ,p_fnd_user_name           => lc_user_name
          ,p_creation_date           => sysdate
          ,p_created_by              => ln_user_id
          ,p_last_update_date        => sysdate
          ,p_last_updated_by         => ln_user_id
          ,p_last_update_login       => ln_login
          );
      FND_FILE.PUT_LINE(FND_FILE.LOG, p_debug_msg);
      END IF;
    END log_debug_msg;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : log_error                                         |
    -- | Description      :                                                   |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    PROCEDURE log_error ( p_proc               IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
    IS
     ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
     ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
     lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
     
    BEGIN
      
      XX_COM_OID_ERROR_LOG_PKG.log_error
          (
           p_module_name             => 'XXOID'
          ,p_attribute15             => 'XX_OID_SUBSCRIPTION_UPD_PKG'         
          ,p_attribute16             => p_proc
          ,p_error_message           => p_error_msg
          ,p_fnd_user_name           => lc_user_name
          ,p_creation_date           => sysdate
          ,p_created_by              => ln_user_id
          ,p_last_update_date        => sysdate
          ,p_last_updated_by         => ln_user_id
          ,p_last_update_login       => ln_login
          );
      FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    
    
    END log_error;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : delete_orcl_owner_guid                            |
    -- | Description      : This procedure will delete the user's one part of |
    -- |                    subscription  - orclOwnerGUID                     |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    PROCEDURE delete_orcl_owner_guid ( p_orclguid   IN  VARCHAR2 )
    IS
      
       lc_subsNode        VARCHAR2(1000);
       ln_returnval_auth   pls_integer         := -1;
       ln_returnval_ssl    pls_integer         := -1;
       ln_returnval_unbind pls_integer         := -1;
    
       l_session          dbms_ldap.session;
    
       lc_ldap_base       VARCHAR2(256);
       lc_ldap_port       VARCHAR2(256);
       lc_ldap_host       VARCHAR2(256);
       lc_ldap_user       VARCHAR2(256);
       lc_ldap_passwd     VARCHAR2(256);
       lc_ldap_auth       VARCHAR2(256);
       lc_db_wlt_url      VARCHAR2(256);
       lc_db_wlt_pwd      VARCHAR2(256);
    
       l_attrs            dbms_ldap.string_collection;
       l_message          dbms_ldap.message := null;
       ln_result          pls_integer;
       l_entry            dbms_ldap.message := null;
       
       ssl_connect_fail       EXCEPTION;
       ldap_auth_fail         EXCEPTION;
    
    BEGIN
       
       g_proc := 'delete_orcl_owner_guid';

       ----------------------------------
       -- Retrieve LDAP Information
       ----------------------------------
       log_debug_msg(g_proc,'***** Retrieve LDAP Information *****');
    
       lc_ldap_host   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_HOST);
       lc_ldap_port   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_PORT);
       lc_ldap_user   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_USERNAME);
       lc_ldap_passwd := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_EPWD, G_LDAP_PWD);
       lc_ldap_auth   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBLDAPAUTHLEVEL);
       lc_db_wlt_url  := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETDIR);
       lc_db_wlt_pwd  := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETPASS, G_LDAP_PWD);
    
       log_debug_msg(g_proc,rpad('LDAP Host ',30,' ') || ': ' || lc_ldap_host);
       log_debug_msg(g_proc,rpad('LDAP Port ',30,' ') || ': ' || lc_ldap_port);
       log_debug_msg(g_proc,rpad('LDAP User ',30,' ') || ': ' || lc_ldap_user);
       log_debug_msg(g_proc,rpad('LDAP Pwd  ',30,' ') || ': ' || '***********');
       log_debug_msg(g_proc,rpad('LDAP Auth ',30,' ') || ': ' || lc_ldap_auth);
       log_debug_msg(g_proc,rpad('Wallet URL',30,' ') || ': ' || lc_db_wlt_url);
       log_debug_msg(g_proc,rpad('Wallet Pwd',30,' ') || ': ' || '***********');   
    
       dbms_ldap.use_exception := TRUE;
    
       --------------------------------------------------
       -- Establish a connection with the LDAP server.
       --------------------------------------------------
       log_debug_msg(g_proc,'***** Establish a connection with the LDAP server *****');   
       l_session := dbms_ldap.init(hostname => lc_ldap_host
                                  ,portnum  => lc_ldap_port);
    
       log_debug_msg(g_proc,rpad('Ldap session rawtohex',30,' ')  || ': ' || rawtohex(substr(l_session,1,8)));
       log_debug_msg(g_proc,rpad('Ldap session raw     ',30,' ')  || ': ' || l_session);
    
       --------------------------------------------------
       -- Establish SSL connection if required
       --------------------------------------------------
       log_debug_msg(g_proc,'***** SSL Connection Verification *****');   
    
       IF lc_ldap_auth > 0 THEN
          log_debug_msg(g_proc,'SSL Connection Required');
          ln_returnval_ssl := dbms_ldap.open_ssl(l_session
                                                ,'file:'||lc_db_wlt_url
                                                ,lc_db_wlt_pwd
                                                ,lc_ldap_auth);
    
          log_debug_msg(g_proc,rpad('dbms_ldap.open_ssl Returns ',30,' ') || ': '|| to_char(ln_returnval_ssl));
          
          IF ln_returnval_ssl = 0 THEN 
             log_debug_msg(g_proc,'SSL Connection Established');
          ELSE
             log_debug_msg(g_proc,'SSL Connection Failed');
             -- Raise exeception
             raise ssl_connect_fail;
          END IF;   
       ELSE
          log_debug_msg(g_proc,'SSL Connection Not Required');
       END IF;
    
       --------------------------------------------------
       -- Authentication to LDAP directory server.
       --------------------------------------------------
       log_debug_msg(g_proc,'***** Authentication to LDAP directory server. *****'); 
       ln_returnval_auth := dbms_ldap.simple_bind_s(ld     => l_session
                                                   ,dn     => lc_ldap_user
                                                   ,passwd => lc_ldap_passwd);
     
       log_debug_msg(g_proc,rpad('simple_bind_s Returns ',30,' ') || ': '|| to_char(ln_returnval_auth));
     
       IF ln_returnval_auth = 0 THEN 
          log_debug_msg(g_proc,'Authentication Successful');
       ELSE
          log_debug_msg(g_proc,'Authentication Failed');
          -- Raise exeception
          raise ldap_auth_fail;
       END IF;   
    
       --------------------------------------------------
       -- Delete orclOwnerGUID Initialization
       --------------------------------------------------
       log_debug_msg(g_proc,'*****  Delete orclOwnerGUID Initialization *****'); 
    
       lc_subsNode := 'cn=ACCOUNTS,cn=subscription_data,cn=subscriptions,' || fnd_ldap_util.get_orclappname;
       log_debug_msg(g_proc,rpad('lc_subsNode ',30,' ') || ': '|| lc_subsNode);
       
       --------------------------------------------------
       -- Delete orclOwnerGUID Subscription
       --------------------------------------------------
       log_debug_msg(g_proc,'***** Delete orclOwnerGUID Subscription *****'); 
    
       ln_result := dbms_ldap.delete_s(ld      => l_session
                                      ,entrydn => 'orclOwnerGUID=' || p_orclguid ||','||lc_subsNode);
       
       --------------------------------------------------
       -- Validate Deletion of Subscription (orclOwnerGUID)
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Validate Deletion of Subscription (orclOwnerGUID) *****'); 

       IF (ln_result = dbms_ldap.SUCCESS) 
       THEN
           log_debug_msg(g_proc,'SUBSCRIPTION (ORCLOWNERGUID) DELETED');   
       ELSE
           log_debug_msg(g_proc,'SUBSCRIPTION (ORCLOWNERGUID) NOT DELETED');  
           --send notification email to support teams
           XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
                p_email_identifier  => 'XX_OID_SUBSCRIPTION_UPD_PKG'
               ,p_body              => 'Failed to execute dbms_ldap.delete_s to delete_orcl_owner_guid, for orclOwnerGUID: ' || p_orclguid || '. Please check and rectify the record in OID.'
             );            
       END IF;
       
       IF l_session IS NOT NULL THEN
             ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
       END IF;
    
    EXCEPTION
       WHEN ssl_connect_fail THEN
          log_error(g_proc,'Failure to establish SSL Connection in delete_unique_member : ' || sqlerrm); 
       WHEN ldap_auth_fail THEN
          log_error(g_proc,'Failure to Authenticate LDAP Server in delete_unique_member : ' || sqlerrm); 
       WHEN OTHERS THEN
          log_error(g_proc,'Exception in when others in delete_orcl_owner_guid : ' || sqlerrm); 
          
      IF l_session IS NOT NULL THEN
         ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
      END IF;

    END delete_orcl_owner_guid; 
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : delete_unique_member                              |
    -- | Description      : This procedure will delete the user's one part of |
    -- |                    subscription  - uniquemember                      |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    PROCEDURE delete_unique_member   ( p_user_name  IN  VARCHAR2 )
    IS
    
       lc_subsNode        VARCHAR2(1000);
       ln_returnval_mod    pls_integer         := -1;
       ln_returnval_auth   pls_integer         := -1;
       ln_returnval_ssl    pls_integer         := -1;
       ln_returnval_unbind pls_integer         := -1;
    
       l_modArray         dbms_ldap.mod_array;
       l_modmultivalues   dbms_ldap.string_collection;
      
       l_session          dbms_ldap.session;
    
       lc_ldap_base       VARCHAR2(256);
       lc_ldap_port       VARCHAR2(256);
       lc_ldap_host       VARCHAR2(256);
       lc_ldap_user       VARCHAR2(256);
       lc_ldap_passwd     VARCHAR2(256);
       lc_ldap_auth       VARCHAR2(256);
       lc_db_wlt_url      VARCHAR2(256);
       lc_db_wlt_pwd      VARCHAR2(256);
      
       ssl_connect_fail       EXCEPTION;
       ldap_auth_fail         EXCEPTION;
    BEGIN
       
       g_proc := 'delete_unique_member';
       
       ----------------------------------
       -- Retrieve LDAP Information
       ----------------------------------
       log_debug_msg(g_proc,'***** Retrieve LDAP Information *****');
    
       lc_ldap_host   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_HOST);
       lc_ldap_port   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_PORT);
       lc_ldap_user   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_USERNAME);
       lc_ldap_passwd := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_EPWD, G_LDAP_PWD);
       lc_ldap_auth   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBLDAPAUTHLEVEL);
       lc_db_wlt_url  := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETDIR);
       lc_db_wlt_pwd  := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETPASS, G_LDAP_PWD);
    
       log_debug_msg(g_proc,rpad('LDAP Host ',25,' ') || ': ' || lc_ldap_host);
       log_debug_msg(g_proc,rpad('LDAP Port ',25,' ') || ': ' || lc_ldap_port);
       log_debug_msg(g_proc,rpad('LDAP User ',25,' ') || ': ' || lc_ldap_user);
       log_debug_msg(g_proc,rpad('LDAP Pwd  ',25,' ') || ': ' || '***********');
       log_debug_msg(g_proc,rpad('LDAP Auth ',25,' ') || ': ' || lc_ldap_auth);
       log_debug_msg(g_proc,rpad('Wallet URL',25,' ') || ': ' || lc_db_wlt_url);
       log_debug_msg(g_proc,rpad('Wallet Pwd',25,' ') || ': ' || '***********');   
    
       dbms_ldap.use_exception := TRUE;
    
       --------------------------------------------------
       -- Establish a connection with the LDAP server.
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Establish a connection with the LDAP server *****');   
       l_session := dbms_ldap.init(hostname => lc_ldap_host
                                  ,portnum  => lc_ldap_port);
    
       log_debug_msg(g_proc,rpad('Ldap session rawtohex',25,' ')  || ': ' || rawtohex(substr(l_session,1,8)));
       log_debug_msg(g_proc,rpad('Ldap session raw     ',25,' ')  || ': ' || l_session);
    
       --------------------------------------------------
       -- Establish SSL connection if required
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** SSL Connection Verification *****');   
    
       IF lc_ldap_auth > 0 THEN
          log_debug_msg(g_proc,'SSL Connection Required');
          ln_returnval_ssl := dbms_ldap.open_ssl(l_session
                                                ,'file:'||lc_db_wlt_url
                                                ,lc_db_wlt_pwd
                                                ,lc_ldap_auth);
    
          log_debug_msg(g_proc,rpad('dbms_ldap.open_ssl Returns ',30,' ') || ': '|| to_char(ln_returnval_ssl));
          
          IF ln_returnval_ssl = 0 THEN 
             log_debug_msg(g_proc,'SSL Connection Established');
          ELSE
             log_debug_msg(g_proc,'SSL Connection Failed');
             -- Raise exeception
             raise ssl_connect_fail;
          END IF;   
       ELSE
          log_debug_msg(g_proc,'SSL Connection Not Required');
       END IF;
    
       --------------------------------------------------
       -- Authentication to LDAP directory server.
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Authentication to LDAP directory server. *****'); 
       ln_returnval_auth := dbms_ldap.simple_bind_s(ld     => l_session
                                                   ,dn     => lc_ldap_user
                                                   ,passwd => lc_ldap_passwd);
     
       log_debug_msg(g_proc,rpad('simple_bind_s Returns ',25,' ') || ': '|| to_char(ln_returnval_auth));
     
       IF ln_returnval_auth = 0 THEN 
          log_debug_msg(g_proc,'Authentication Successful');
       ELSE
          log_debug_msg(g_proc,'Authentication Failed');
          -- Raise exeception
          raise ldap_auth_fail;
       END IF;   
    
       --------------------------------------------------
       -- Delete Unique Member Initialization
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Delete Unique Member Initialization. *****'); 
       lc_subsNode := 'cn=ACCOUNTS,cn=subscription_data,cn=subscriptions,' || fnd_ldap_util.get_orclappname;
       log_debug_msg(g_proc,rpad('lc_subsNode ',25,' ') || ': '|| lc_subsNode);
    
       l_modArray := dbms_ldap.create_mod_array(num => 1);
       log_debug_msg(g_proc,rpad('l_modArray ',25,' ') || ': '|| l_modArray);
    
       l_modmultivalues(0) := 'cn='||p_user_name||',ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net';
                              -- cn=10010000000000000000,ou=na,cn=odcustomer,cn=odexternal,cn=users,dc=odcorp,dc=net
       log_debug_msg(g_proc,rpad('l_modmultivalues(0) ',25,' ') || ': '|| l_modmultivalues(0));
    
       --------------------------------------------------
       -- Delete Unique Member Corrupt Subcription
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Delete Unique Member Corrupt Subcription *****'); 
    
       log_debug_msg(g_proc,'Execute dbms_ldap.populate_mod_array'); 
       dbms_ldap.populate_mod_array(modptr   => l_modArray
                                   ,mod_op   => dbms_ldap.mod_delete
                                   ,mod_type => 'uniquemember'
                                   ,modval   => l_modmultivalues);
     
       log_debug_msg(g_proc,'Execute dbms_ldap.modify_s'); 
       ln_returnval_mod := dbms_ldap.modify_s(ld      => l_session
                                             ,entrydn => lc_subsNode
                                             ,modptr  => l_modArray);
    
       --------------------------------------------------
       -- Validate Deletion of Unique Member
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Validate Deletion of Unique Member *****'); 
    
       IF (ln_returnval_mod = dbms_ldap.SUCCESS) THEN
          log_debug_msg(g_proc,'UNIQUE MEMBER DELETED');   
       ELSE
          log_debug_msg(g_proc,'UNIQUE MEMBER NOT DELETED');  
          --send notification email to support teams
          XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
               p_email_identifier  => 'XX_OID_SUBSCRIPTION_UPD_PKG'
              ,p_body              => 'Failed to execute bms_ldap.modify_s to delete_unique_member, for fnd_user_name: ' || p_user_name || '. Please check and rectify the record in OID.'
            );           
       END IF;
    
       dbms_ldap.free_mod_array(modptr => l_modArray);
       
       IF l_session IS NOT NULL THEN
           ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
       END IF;
    
    
     EXCEPTION
       WHEN ssl_connect_fail THEN
          log_error(g_proc,'Failure to establish SSL Connection in delete_unique_member : ' || sqlerrm); 
       WHEN ldap_auth_fail THEN
          log_error(g_proc,'Failure to Authenticate LDAP Server in delete_unique_member : ' || sqlerrm); 
       WHEN OTHERS THEN
          log_error(g_proc,'EXCEPTION WHEN OTHERS in delete_unique_member : ' || sqlerrm); 
    
          dbms_ldap.free_mod_array(modptr => l_modArray);
    
          IF l_session IS NOT NULL THEN
             ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
          END IF;
    
    END delete_unique_member;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : link_user                                         |
    -- | Description      : This procedure is to fix the user's subscription  |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    PROCEDURE link_user (p_user_name IN varchar2)
    IS
    
      ln_link_result      pls_integer;
      lc_orclguid_link    fnd_user.user_guid%type;
      lc_password_link    fnd_user.encrypted_user_password%type;
    
    BEGIN
          g_proc := 'link_user';
          
          fnd_ldap_user.link_user(p_user_name => p_user_name
                                 ,x_user_guid => lc_orclguid_link
                                 ,x_password  => lc_password_link
                                 ,x_result    => ln_link_result);
    
          log_debug_msg(g_proc,'lc_orclguid_link: '||lc_orclguid_link);
          log_debug_msg(g_proc,'lc_password_link: '||lc_password_link);
          log_debug_msg(g_proc,'ln_link_result  : '||ln_link_result);   
    
          IF ln_link_result = 1 THEN
             log_debug_msg(g_proc,'User Link Successful -> Subscription Created.');     
          ELSE
             log_debug_msg(g_proc,'User Link Not Completed -> Subcription Not Created.');    
             --send notification email to support teams
             XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
                  p_email_identifier  => 'XX_OID_SUBSCRIPTION_UPD_PKG'
                 ,p_body              => 'fnd_ldap_user.link_user for user ' || p_user_name || ' was unsuccessful. Subcription Not Created. Please check and rectify the record in OID.'
               );             
          END IF;
      
    EXCEPTION
       WHEN OTHERS THEN
          log_error(g_proc,'Error at when others in link_user : ' || sqlerrm); 
          
    END link_user;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : check_subscription                                |
    -- | Description      : This function is to check subscription status of  |
    -- |                    the user                                          |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    FUNCTION check_subscription (  p_user_name     IN  VARCHAR2
                                 , p_orclguid      IN  VARCHAR2 )
    RETURN VARCHAR2
    IS
   
       l_attrs             dbms_ldap.string_collection;
       lc_usersDN          VARCHAR2(1000);
    
       lc_subsNode         VARCHAR2(1000);
       l_message1          dbms_ldap.message := null;
       l_message2          dbms_ldap.message := null;
       ln_result1          pls_integer;
       ln_result2          pls_integer;
       lb_guid_result      BOOLEAN := FALSE;
       lb_uniq_result      BOOLEAN := FALSE;
       
       lc_oid_sub_status   VARCHAR2(80);
       
       ln_returnval_auth   pls_integer       := -1;
       ln_returnval_ssl    pls_integer       := -1;
       ln_returnval_unbind pls_integer       := -1;
    
       l_modmultivalues    dbms_ldap.string_collection;
      
       l_session           dbms_ldap.session;
    
       lc_ldap_base        VARCHAR2(256);
       lc_ldap_port        VARCHAR2(256);
       lc_ldap_host        VARCHAR2(256);
       lc_ldap_user        VARCHAR2(256);
       lc_ldap_passwd      VARCHAR2(256);
       lc_ldap_auth        VARCHAR2(256);
       lc_db_wlt_url       VARCHAR2(256);
       lc_db_wlt_pwd       VARCHAR2(256);
    
       ssl_connect_fail       EXCEPTION;
       ldap_auth_fail         EXCEPTION;
    
    BEGIN
       g_proc := 'check_subscription';
       lc_oid_sub_status := NULL;
   
       ----------------------------------
       -- Retrieve LDAP Information
       ----------------------------------
       log_debug_msg(g_proc,'***** Retrieve LDAP Information *****');
    
       lc_ldap_host   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_HOST);
       lc_ldap_port   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_PORT);
       lc_ldap_user   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_USERNAME);
       lc_ldap_passwd := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_EPWD, G_LDAP_PWD);
       lc_ldap_auth   := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBLDAPAUTHLEVEL);
       lc_db_wlt_url  := fnd_preference.get (G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETDIR);
       lc_db_wlt_pwd  := fnd_preference.eget(G_INTERNAL, G_LDAP_SYNCH, G_DBWALLETPASS, G_LDAP_PWD);
    
       log_debug_msg(g_proc,rpad('LDAP Host ',30,' ') || ': ' || lc_ldap_host);
       log_debug_msg(g_proc,rpad('LDAP Port ',30,' ') || ': ' || lc_ldap_port);
       log_debug_msg(g_proc,rpad('LDAP User ',30,' ') || ': ' || lc_ldap_user);
       log_debug_msg(g_proc,rpad('LDAP Pwd  ',30,' ') || ': ' || '***********');
       log_debug_msg(g_proc,rpad('LDAP Auth ',30,' ') || ': ' || lc_ldap_auth);
       log_debug_msg(g_proc,rpad('Wallet URL',30,' ') || ': ' || lc_db_wlt_url);
       log_debug_msg(g_proc,rpad('Wallet Pwd',30,' ') || ': ' || '***********');   
    
       dbms_ldap.use_exception := TRUE;
    
       --------------------------------------------------
       -- Establish a connection with the LDAP server.
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Establish a connection with the LDAP server *****');   
       l_session := dbms_ldap.init(hostname => lc_ldap_host
                                  ,portnum  => lc_ldap_port);
    
       log_debug_msg(g_proc,rpad('Ldap session rawtohex',30,' ')  || ': ' || rawtohex(substr(l_session,1,8)));
       log_debug_msg(g_proc,rpad('Ldap session raw     ',30,' ')  || ': ' || l_session);
    
       --------------------------------------------------
       -- Establish SSL connection if required
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** SSL Connection Verification *****');   
    
       IF lc_ldap_auth > 0 THEN
          log_debug_msg(g_proc,'SSL Connection Required');
          ln_returnval_ssl := dbms_ldap.open_ssl (l_session
                                                 ,'file:'||lc_db_wlt_url
                                                 ,lc_db_wlt_pwd
                                                 ,lc_ldap_auth);
    
          log_debug_msg(g_proc,rpad('dbms_ldap.open_ssl Returns ',30,' ') || ': '|| to_char(ln_returnval_ssl));
          
          IF ln_returnval_ssl = 0 THEN 
             log_debug_msg(g_proc,'SSL Connection Established');
          ELSE
             log_debug_msg(g_proc,'SSL Connection Failed');
             -- Raise exeception
             raise ssl_connect_fail;
          END IF;   
       ELSE
          log_debug_msg(g_proc,'SSL Connection Not Required');
       END IF;
    
       --------------------------------------------------
       -- Authentication to LDAP directory server.
       --------------------------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'***** Authentication to LDAP directory server *****'); 
       ln_returnval_auth := dbms_ldap.simple_bind_s(ld     => l_session
                                                   ,dn     => lc_ldap_user
                                                   ,passwd => lc_ldap_passwd);
     
       log_debug_msg(g_proc,rpad('simple_bind_s Returns ',30,' ') || ': '|| to_char(ln_returnval_auth));
       
       IF ln_returnval_auth = 0 THEN 
          log_debug_msg(g_proc,'Authentication Successful');
       ELSE
          log_debug_msg(g_proc,'Authentication Failed');
          -- Raise exeception
          raise ldap_auth_fail;
       END IF;   
    
       ----------------------------------
       -- Derive subsNode and userDN
       ----------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'****** Derive subsNode and userDN *******');
       
       lc_subsNode := 'cn=ACCOUNTS,cn=subscription_data,cn=subscriptions,' || fnd_ldap_util.get_orclappname;
       log_debug_msg(g_proc,'subsNode: '||lc_subsNode);
    
       lc_usersDN := fnd_ldap_util.get_dn_for_guid(p_orclguid => p_orclguid);
       log_debug_msg(g_proc,'usersDN: '||lc_usersDN);
    
       ----------------------------------
       -- Search for orclOwnerGUID
       ----------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'****** Search the ldap with orclOwnerGUID attribute filter *******');
       log_debug_msg(g_proc,rpad('session ',30,' ') || ': '|| l_session);
       log_debug_msg(g_proc,rpad('scope   ',30,' ') || ': '|| dbms_ldap.SCOPE_SUBTREE);
       log_debug_msg(g_proc,rpad('filter  ',30,' ') || ': '|| 'orclOwnerGUID=' || p_orclguid);
       log_debug_msg(g_proc,rpad('attronly',30,' ') || ': '|| '0');
    
       ln_result1 := dbms_ldap.search_s(ld       => l_session
                                       ,base     => lc_subsNode
                                       ,scope    => dbms_ldap.SCOPE_SUBTREE
                                       ,filter   => 'orclOwnerGUID=' || p_orclguid
                                       ,attrs    => l_attrs
                                       ,attronly => 0
                                       ,res      => l_message1);
    
       log_debug_msg(g_proc,rpad('dbms_ldap.search_s RESULT',30,' ') || ': '|| ln_result1);
       log_debug_msg(g_proc,rpad('dbms_ldap.search_s res   ',30,' ') || ': '|| l_message1);   
    
       IF DBMS_LDAP.count_entries(ld => l_session, msg => l_message1) > 0 THEN
          lb_guid_result := TRUE;
          log_debug_msg(g_proc,rpad('orclOwnerGUID search result',30,' ') || ': '|| 'TRUE');   
       ELSE
          lb_guid_result := FALSE;
          log_debug_msg(g_proc,rpad('orclOwnerGUID search result',30,' ') || ': '|| 'FALSE');   
       END IF;
    
       ----------------------------------
       -- Search for uniquemember
       ----------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'****** Search the ldap with uniquemember filter *******');
       log_debug_msg(g_proc,rpad('session ',30,' ') || ': '|| l_session);
       log_debug_msg(g_proc,rpad('scope   ',30,' ') || ': '|| dbms_ldap.SCOPE_SUBTREE);
       log_debug_msg(g_proc,rpad('filter  ',30,' ') || ': '|| 'uniquemember=' || lc_usersDN);
       log_debug_msg(g_proc,rpad('attronly',30,' ') || ': '|| '0');
    
       ln_result2 := dbms_ldap.search_s(ld       => l_session
                                       ,base     => lc_subsNode
                                       ,scope    => dbms_ldap.SCOPE_SUBTREE
                                       ,filter   => 'uniquemember=' || lc_usersDN
                                       ,attrs    => l_attrs
                                       ,attronly => 0
                                       ,res      => l_message2);
    
       log_debug_msg(g_proc,rpad('dbms_ldap.search_s RESULT',30,' ') || ': '|| ln_result2);
       log_debug_msg(g_proc,rpad('dbms_ldap.search_s res   ',30,' ') || ': '|| l_message2);   
    
       IF DBMS_LDAP.count_entries(ld => l_session, msg => l_message2) > 0 THEN
          lb_uniq_result := TRUE;
          log_debug_msg(g_proc,rpad('uniquemember search result',30,' ') || ': '|| 'TRUE');   
       ELSE
          lb_uniq_result := FALSE;
          log_debug_msg(g_proc,rpad('uniquemember search result',30,' ') || ': '|| 'FALSE');   
       END IF;
    
       ----------------------------------
       -- Validate Search Results
       ----------------------------------
       log_debug_msg(g_proc,' ');
       log_debug_msg(g_proc,'****** Validate Search Results *******');
       
        IF( lb_guid_result AND lb_uniq_result ) THEN
              log_debug_msg(g_proc,rpad('USER SUBSCRIBED',30,' '));   
              lc_oid_sub_status := G_SUBSCRIBED;
        ELSIF( (NOT lb_guid_result) AND (NOT lb_uniq_result) ) THEN
              log_debug_msg(g_proc,rpad('USER NOT SUBSCRIBED',30,' '));   
              lc_oid_sub_status := G_NOT_SUBSCRIBED;
        ELSIF( (NOT lb_guid_result) AND (lb_uniq_result) ) THEN
              log_debug_msg(g_proc,rpad('SUBSCRIPTION - OWNERGUID CORRUPT',30,' '));  
              lc_oid_sub_status := G_CORRUPT_OWNERGUID;
        ELSIF ( (lb_guid_result) AND (NOT lb_uniq_result) ) THEN
              log_debug_msg(g_proc,rpad('SUBSCRIPTION - UNIQUEMEMER CORRUPT',30,' '));
              lc_oid_sub_status := G_CORRUPT_UNIQUE;
        ELSE 
              log_debug_msg(g_proc,'SUBSCRIPTION status Determination of user FAILED'); 
        END IF;
        
       Return  lc_oid_sub_status;
       
       IF l_session IS NOT NULL THEN
             ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
       END IF;
    
    EXCEPTION
       WHEN ssl_connect_fail THEN
          log_error(g_proc,'Failure to establish SSL Connection in check_subscription : ' || sqlerrm); 
		   Return  NULL;
       WHEN ldap_auth_fail THEN
          log_error(g_proc,'Failure to Authenticate LDAP Server in check_subscription : ' || sqlerrm);
          Return  NULL;		  
       WHEN OTHERS THEN
          log_error(g_proc,'Error at when others in check_subscription : ' || sqlerrm); 
          --send notification email to support teams
          XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
               p_email_identifier  => 'XX_OID_SUBSCRIPTION_UPD_PKG'
              ,p_body              => 'Exceptions encountered in executing XX_OID_SUBSCRIPTION_UPD_PKG.check_subscription for user ' || p_user_name || ' with exception as - ' || SQLERRM || '. Please check and rectify the record in OID.'
            );    
          IF l_session IS NOT NULL THEN
             ln_returnval_unbind := DBMS_LDAP.unbind_s(ld => l_session);
          END IF;
          Return  NULL;
    END check_subscription;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : get_fnd_user_exists                               |
    -- | Description      : This function is to check if user exists in FND   |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    FUNCTION get_fnd_user_exists ( p_user_name    IN  VARCHAR2
                                  ,p_user_guid    OUT NOCOPY VARCHAR2)
    return varchar2
    IS
    
    lb_fnd_user_exists   VARCHAR2(1);  
    
    BEGIN
      g_proc := 'get_fnd_user_exists';
      lb_fnd_user_exists := 'N';  

      --  Determine if user exists in FND_USER
      BEGIN 
           select 'Y', user_guid 
           INTO   lb_fnd_user_exists, p_user_guid
           from   fnd_user 
           where  user_name = p_user_name;
      EXCEPTION
           WHEN OTHERS THEN 
           log_error(g_proc,'User '|| p_user_name ||' does not exist in FND');
      END;
      
       RETURN lb_fnd_user_exists;    
      
       EXCEPTION 
       WHEN OTHERS THEN
              log_error(g_proc,'Exception in WHEN OTHERS get_fnd_user_exists, Error code: '||to_char(sqlcode) ||', Error Message: '|| sqlerrm ); 
       Return 'N';
    end get_fnd_user_exists;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : get_oid_user_exists                               |
    -- | Description      : This function is to check if the user exits in OID|
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    FUNCTION get_oid_user_exists (p_user_name    IN  VARCHAR2, p_orclguid OUT NOCOPY VARCHAR2)
    return varchar2
    IS
    
    ln                  NUMBER;
    
    BEGIN
      g_proc := 'get_oid_user_exists';
      ln             := 0;
      --==============================================================================
      -- fnd_ldap_user.get_user_guid_and_count example (Retrieves GUID from OID) 
      --==============================================================================
      p_orclguid := fnd_ldap_user.get_user_guid_and_count(p_user_name,ln) ;
          
      IF ln = 1 THEN
        RETURN 'Y';
      ELSE
        RETURN 'N';      
      END IF;
    
      EXCEPTION 
       WHEN OTHERS THEN
              log_error(g_proc,'Exception in WHEN OTHERS get_oid_user_exists, Error code: '||to_char(sqlcode) ||', Error Message: '|| sqlerrm );
       Return 'N'; 
    
    end get_oid_user_exists; 
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : update_subscription                               |
    -- | Description      : This procedure is to check subscription flag and  |
    -- |                    when did the user last logged in                  |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    procedure update_subscription ( p_user_name  IN  VARCHAR2 )
    IS
    
    ln_user_name                fnd_user.user_name%type;
    lc_orclguid                 fnd_user.user_guid%type;   
    lc_user_guid                fnd_user.user_guid%type;   
    lb_fnd_user_exists          VARCHAR2(1);  
    lb_oid_user_exists          VARCHAR2(1);  
    lc_oid_sub_status           VARCHAR2(80);
    
    BEGIN
          g_proc := 'update_subscription';      
          ln_user_name       := NULL;
          lc_orclguid        := NULL;   
          lc_user_guid       := NULL;   
          lb_fnd_user_exists := NULL;  
          lb_oid_user_exists := NULL;  
          lc_oid_sub_status  := NULL;
          
          IF (get_update_subscription_flag(p_user_name) = 'Y')
          THEN
              lb_fnd_user_exists := get_fnd_user_exists(p_user_name,lc_user_guid);
              log_debug_msg(g_proc,'***** User exists in FND and Retrieve user user_guid Information *****: '|| lb_fnd_user_exists);
              lb_oid_user_exists := get_oid_user_exists(p_user_name,lc_orclguid);
              log_debug_msg(g_proc,'***** User exists in OID and Retrieve user ORCLGUID Information ***** : '|| lb_oid_user_exists);
              
              IF( lb_oid_user_exists = 'Y' AND lb_fnd_user_exists = 'Y' )
              THEN
                   --Calling check_subscription function to check user subscription status
                   lc_oid_sub_status := check_subscription(p_user_name,lc_orclguid);
                   log_debug_msg(g_proc,'SUBSCRIPTION of user '||p_user_name||' is '||lc_oid_sub_status); 
                   
                   IF    lc_oid_sub_status = G_SUBSCRIBED THEN
                         log_debug_msg(g_proc,'USER SUBSCRIBED');   
                   ELSIF lc_oid_sub_status = G_NOT_SUBSCRIBED THEN
                         link_user(p_user_name);
                   ELSIF lc_oid_sub_status = G_CORRUPT_OWNERGUID THEN
                         delete_unique_member(p_user_name);
                         link_user(p_user_name);
                   ELSIF lc_oid_sub_status = G_CORRUPT_UNIQUE THEN
                         delete_orcl_owner_guid(lc_orclguid);
                         link_user(p_user_name);
                   END IF;
                  
                  --check if user guid is NULL
                  log_debug_msg(g_proc,'Checking if '||p_user_name ||' GUID is NULL :'||lc_user_guid);
                  IF( lc_user_guid IS NULL )
                  THEN
                      UPDATE fnd_user
                      SET    user_guid = lc_orclguid
                            ,last_update_date = SYSDATE
                            ,last_updated_by  = FND_GLOBAL.User_Id
                      WHERE  user_name = p_user_name
                      ; 
                  END IF;
                  
                  -- update xx_external_user
                  log_debug_msg(g_proc,'Updating xx_external_user subscription flag for user '||p_user_name);
                  update xx_external_users
                  set    subscription_exists = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by  = FND_GLOBAL.User_Id
                  where  1 = 1  
                  and    fnd_user_name = p_user_name
                  ;
                  
              ELSIF ( lb_oid_user_exists = 'N' AND lb_fnd_user_exists = 'Y' )
              THEN
                  log_debug_msg(g_proc,'User does not exist in OID '||lb_oid_user_exists);
                  log_debug_msg(g_proc,'Updating OID_UPDATE_DATE to sysdate to force sync subscription validation during next update');
                  UPDATE xx_external_users
                  SET    oid_update_date = sysdate
                        ,subscription_exists = 'N'
                        ,last_update_date = SYSDATE
                        ,last_updated_by  = FND_GLOBAL.User_Id
                  WHERE  fnd_user_name   = p_user_name;
              ELSIF ( lb_oid_user_exists = 'Y' AND lb_fnd_user_exists = 'N' )
              THEN
                  log_debug_msg(g_proc,'User does not exist in FND '||lb_fnd_user_exists);
                  log_debug_msg(g_proc,'Updating OID_UPDATE_DATE to sysdate to force sync subscription validation during next update');
                  UPDATE xx_external_users
                  SET    oid_update_date = sysdate
                        ,subscription_exists = 'N'
                        ,last_update_date = SYSDATE
                        ,last_updated_by  = FND_GLOBAL.User_Id
                  WHERE  fnd_user_name   = p_user_name;
              ELSIF ( lb_oid_user_exists = 'N' AND lb_fnd_user_exists = 'N' )
              THEN
                  log_debug_msg(g_proc,'User does not exist in FND '||lb_fnd_user_exists ||' and user does not exist in OID ' ||lb_oid_user_exists);
                  log_debug_msg(g_proc,'Updating OID_UPDATE_DATE to sysdate to force sync subscription validation during next update');
                  UPDATE xx_external_users
                  SET    oid_update_date = sysdate
                        ,subscription_exists = 'N'
                        ,last_update_date = SYSDATE
                        ,last_updated_by  = FND_GLOBAL.User_Id
                  WHERE  fnd_user_name   = p_user_name;
              END IF;
        
              COMMIT;
          ELSE
              log_error(g_proc,'User '||p_user_name||' Subscription Already Exists');
          END IF;
           
       EXCEPTION 
          WHEN OTHERS THEN 
            log_error(g_proc,'Exception '|| SQLERRM ||' in WHEN OTHERS in update_subscription for user '||p_user_name);
            --send notification email to support teams
            XX_COM_EMAIL_NOTIFICATION_PKG.SEND_NOTIFICATIONS(
                 p_email_identifier  => 'XX_OID_SUBSCRIPTION_UPD_PKG'
                ,p_body              => 'Exceptions encountered in executing XX_OID_SUBSCRIPTION_UPD_PKG.update_subscription for user ' || p_user_name || ' with Exception as - ' || SQLERRM || '. Please check and rectify the record in OID.'
              );
    END update_subscription;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : get_update_subscription_flag                      |
    -- | Description      : This function is to check subscription flag and   |
    -- |                    when did the user last logged in                  |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    FUNCTION get_update_subscription_flag (p_user_name    IN  VARCHAR2)
    return varchar2
    IS
    
    lc_subscription_flag        VARCHAR2(1);  
    ln_user_last_login          NUMBER     ; 
    ln_last_login_days          NUMBER     ;
    ln_user_name                fnd_user.user_name%type;
    l_return_val                VARCHAR2(1):='Y';
    
    BEGIN
          
          lc_subscription_flag  := NULL;  
          ln_user_last_login    := 0; 
          ln_last_login_days    := 0;
          ln_user_name          := NULL;
          
          -- Profile option to check against number of days since user last logged in 
          log_debug_msg(g_proc,'Getting Profile option value for User '||p_user_name );
          ln_user_last_login := fnd_profile.value_wnps('XX_USER_LAST_LOGIN'); 
          
          -- Check subscription flag for the user
          BEGIN
              SELECT subscription_exists
              into   lc_subscription_flag
              from   xx_external_users
              where  1 = 1 
              and    fnd_user_name = p_user_name;
          EXCEPTION
            WHEN OTHERS THEN 
               log_error(g_proc,'Exception ' || SQLERRM || ' ,in WHEN OTHERS in SELECT xx_external_users for User : ' || p_user_name);  
          END;
          
          -- Check how long since the user last logged in
          BEGIN
              SELECT (trunc(sysdate) - trunc(last_logon_date))
              into   ln_last_login_days
              from   fnd_user
              where  1 = 1 
              and    user_name = p_user_name;
          EXCEPTION
            WHEN OTHERS THEN 
               log_error(g_proc,'Exception ' || SQLERRM || ' ,in WHEN OTHERS in SELECT fnd_user for User : ' || p_user_name);  
          END;
          
          IF ( lc_subscription_flag = 'N' )
          THEN
              log_debug_msg(g_proc,'User '||p_user_name ||'  Subscription is not updated or does not exists or users subscription will be validated for the first time');
              l_return_val:= 'Y';
          ELSIF ( lc_subscription_flag = 'Y' and ln_last_login_days > ln_user_last_login )
          THEN 
              log_debug_msg(g_proc,'User '||p_user_name ||'  Subscription updated more than '||ln_user_last_login ||' days ago');
              l_return_val:= 'Y';
          ELSIF ( lc_subscription_flag = 'Y' and ln_last_login_days < ln_user_last_login )
          THEN
              log_debug_msg(g_proc,'User '||p_user_name ||' Subscribed');
              l_return_val:= 'N';
          END IF;
          Return l_return_val;
     EXCEPTION 
       WHEN OTHERS THEN
           log_error(g_proc,'Exception in WHEN OTHERS get_update_subscription_flag, Error code: '||to_char(sqlcode) ||', Error Message: '|| sqlerrm ); 
       Return 'N';
    
    end get_update_subscription_flag;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : update_subscription_conc_call                     |
    -- | Description      : This procedure is called from concurrent job      |
    -- |                    to run subscription update manually               |
    -- |                                                                      |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    procedure update_subscription_conc_call ( x_errbuf     out varchar2
                                             ,x_retcode    out number 
                                             ,p_user_name  IN  VARCHAR2
                                             ,p_debug      IN  VARCHAR2 
                                            )
    IS 
    
    BEGIN
       g_debug := p_debug;
       
       log_debug_msg(g_proc,'Beginning of update_subscription_conc_call');
       FOR get_user_rec in (  select xes.* 
                              from   xx_external_users  xes
                              where  1 = 1
                              and    xes.fnd_user_name       =  p_user_name
                            )
       LOOP
            update_subscription(get_user_rec.fnd_user_name);
       END loop;
       log_debug_msg(g_proc,'End of update_subscription_conc_call');
    
     EXCEPTION 
        WHEN OTHERS THEN
        log_error(g_proc,'Exception in WHEN OTHERS update_subscription_conc_call, Error code: '||to_char(sqlcode) ||', Error Message: '|| sqlerrm );
        
    END update_subscription_conc_call;
    
    -- +======================================================================+
    -- |                          Office Depot Inc.                           |
    -- +======================================================================+
    -- | Name             : update_subscription_func                          |
    -- | Description      : Function is raised by business event              |
    -- |                    od.xxcomn.oid.subscription.check to call the      |
    -- |                    main proc  update_subscription                    |
    -- |Change Record:                                                        |
    -- |===============                                                       |
    -- |Version   Date         Author           Remarks                       |
    -- |=======   ==========   =============    ======================        |
    -- | 1.0      10-Sep-2015  Manikant Kasu    Initial Version               |
    -- +======================================================================+
    
    function update_subscription_func    ( p_subscription_guid   IN     RAW,
                                           p_event               IN OUT wf_event_t )
    return varchar2
    IS
    
    l_list   wf_parameter_list_t := p_event.getparameterlist ();
    
    BEGIN
           log_debug_msg(g_proc,'Beginning of update_subscription_func');
           IF p_event.geteventname () = 'od.xxcomn.oid.subscription.check'
           THEN
               update_subscription(wf_event.getvalueforparameter (
                                      'p_user_name',
                                      l_list));
           END IF;
           log_debug_msg(g_proc,'END of update_subscription_func');
    
     EXCEPTION 
         WHEN OTHERS THEN
             log_error(g_proc,'Exception in WHEN OTHERS update_subscription_func, Error code: '||to_char(sqlcode) ||', Error Message: '|| sqlerrm );
             wf_core.context (
                    'xxcomn',
                    'update_subscription',
                    p_event.geteventname (),
                    p_subscription_guid
                 );
                 wf_event.seterrorinfo (p_event, 'ERROR');
            RETURN NULL;
    
    END update_subscription_func;
	
-- +===================================================================+
-- | Name             : purge_com_oid_error_log                        |
-- | Description      : Procedure to purge the data from               |
-- |                    xx_com_oid_error_log based on parameters       |
-- | Parameters :       p_age                                          |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE purge_com_oid_error_log ( x_errbuf               OUT NOCOPY VARCHAR2
                                   ,x_retcode              OUT NOCOPY VARCHAR2
                                   ,p_age                  IN         NUMBER
                                 )
IS
------------------------------------------------
--Declaring local Exceptions and local Variables
------------------------------------------------
ln_error_log_count      PLS_INTEGER;
lc_error_message        VARCHAR2(4000);
EX_DELETE_LOG           EXCEPTION;
BEGIN

   fnd_file.put_line (fnd_file.output, RPAD('Age               :',30,' ') || p_age);
   fnd_file.put_line (fnd_file.output, ' ');
    -------------------------------------------
    --Deleting data from xx_com_oid_error_log table
    -------------------------------------------
    BEGIN
        DELETE FROM XX_COM_OID_ERROR_LOG XOID
        WHERE  trunc(XOID.creation_date) <= trunc(SYSDATE - p_age);
        ln_error_log_count := SQL%ROWCOUNT;
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_message := 'Unexpected error while deleting records from the table XX_COM_OID_ERROR_LOG. Error : '||SQLERRM;
            RAISE EX_DELETE_LOG;
    END;
    fnd_file.put_line(fnd_file.output, 'Number of Records deleted from XX_COM_OID_ERROR_LOG table  : '||ln_error_log_count);

COMMIT;
EXCEPTION
WHEN EX_DELETE_LOG THEN
    ROLLBACK;
    fnd_file.put_line(fnd_file.log, lc_error_message);
    x_retcode:=2;
WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Unexpected error in Procedure PURGE_COM_OID_ERROR_LOG Error: '||SQLERRM);
    x_retcode:=2;
END purge_com_oid_error_log;

END XX_OID_SUBSCRIPTION_UPD_PKG;
/