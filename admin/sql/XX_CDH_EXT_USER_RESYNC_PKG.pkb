SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_EXT_USER_RESYNC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_CDH_EXT_USER_RESYNC_PKG.pkb                     |
-- | Description :  CDH External User Re-sync Package Body             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  23-Jul-2014 Sreedhar Mohan     Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
  --Procedure for out
  PROCEDURE out ( 
                  p_msg          IN  VARCHAR2 
                )
  IS
  BEGIN
      fnd_file.put_line(fnd_file.output, p_msg);
  END out;
  --Procedure for logging debug log
  PROCEDURE log ( 
                  p_debug              IN  VARCHAR2 DEFAULT 'N'
                 ,p_debug_msg          IN  VARCHAR2 
                )
  IS
  
    ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
    ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  
  BEGIN
    if( p_debug = 'Y') then
      XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'DEBUG'              --------index exists on program_type
        ,p_attribute15             => 'XX_CDH_EXT_USER_RESYNC'          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'                --------index exists on module_name
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
      fnd_file.put_line(fnd_file.log, p_debug_msg);
    end if;
  END log;

   PROCEDURE get_cust_account_role_id (
    p_orig_sys_reference       IN   hz_orig_sys_references.orig_system_reference%TYPE,
    x_cust_account_role_id     OUT  hz_cust_account_roles.cust_account_role_id%TYPE
   )
   IS

      ln_cust_account_role_id   hz_cust_account_roles.cust_account_role_id%TYPE;
      x_retcode                 VARCHAR2 (100);
      x_errbuf                  VARCHAR2 (100);
   BEGIN
      ln_cust_account_role_id := null;   
      x_cust_account_role_id := NULL;
      x_retcode := 0;
      x_errbuf := NULL;

      SELECT cust_account_role_id
        INTO ln_cust_account_role_id
        FROM hz_cust_account_roles
       WHERE role_type='CONTACT'
         AND orig_system_reference = p_orig_sys_reference
         AND status = 'A';

      x_cust_account_role_id := ln_cust_account_role_id;
      x_retcode := 0;
      x_errbuf := NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_retcode := 104;
         x_cust_account_role_id := NULL;
         x_errbuf := 'OSR entered does not exist.';
      WHEN TOO_MANY_ROWS
      THEN
         x_retcode := 2;
         x_cust_account_role_id := NULL;
         x_errbuf := 'OSR entered returns multiple rows.';
      WHEN OTHERS
      THEN
         x_retcode := 3;
         x_cust_account_role_id := NULL;
         x_errbuf := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;
   END get_cust_account_role_id;
   
   PROCEDURE get_role_responsibility (
    p_cust_account_role_id     IN   hz_cust_account_roles.cust_account_role_id%TYPE,
    x_responsibility_type      OUT  HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE
   )
   IS

      lv_responsibility_type    HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE;
      x_retcode                 VARCHAR2 (100);
      x_errbuf                  VARCHAR2 (100);
   BEGIN
      lv_responsibility_type := null;
      x_responsibility_type := NULL;
      x_retcode := 0;
      x_errbuf := NULL;

      SELECT responsibility_type 
        INTO lv_responsibility_type
        FROM HZ_ROLE_RESPONSIBILITY
       WHERE cust_account_role_id = p_cust_account_role_id
         AND responsibility_type  ='SELF_SERVICE_USER';

      x_responsibility_type := lv_responsibility_type;
      x_retcode := 0;
      x_errbuf := NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_retcode := 104;
         x_responsibility_type := NULL;
         x_errbuf := 'OSR entered does not exist.';
      WHEN TOO_MANY_ROWS
      THEN
         x_retcode := 2;
         x_responsibility_type := NULL;
         x_errbuf := 'OSR entered returns multiple rows.';
      WHEN OTHERS
      THEN
         x_retcode := 3;
         x_responsibility_type := NULL;
         x_errbuf := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;
   END get_role_responsibility;   
  
   PROCEDURE get_owner_table_id (
    p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE,
    p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE,
    p_owner_table_name   IN  hz_orig_sys_references.owner_table_name%TYPE,
    x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
   )
   IS

      ln_owner_table_id   hz_orig_sys_references.owner_table_id%TYPE;
      x_retcode           VARCHAR2 (100);
      x_errbuf            VARCHAR2 (100);
   BEGIN
      ln_owner_table_id := null;
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
   END get_owner_table_id;
  
  
   PROCEDURE get_site_use_id (
    p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE,
    p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE,
    p_site_use_code      IN  VARCHAR2,
    x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
   )
   IS

      ln_owner_table_id   hz_orig_sys_references.owner_table_id%TYPE;
      x_retcode           VARCHAR2 (100);
      x_errbuf            VARCHAR2 (100);
   BEGIN
      ln_owner_table_id := null;
      x_owner_table_id := NULL;
      x_retcode := 0;
      x_errbuf := NULL;

      SELECT owner_table_id
        INTO ln_owner_table_id
        FROM hz_orig_sys_references
       WHERE orig_system = p_orig_system
         AND orig_system_reference = p_orig_sys_reference || '-' || p_site_use_code
         AND owner_table_name = 'HZ_CUST_SITE_USES_ALL'
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

  PROCEDURE get_resp_id ( p_bsd_access_code IN  NUMBER
                        , p_debug           IN  VARCHAR2
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
  , p_source_value1    =>  fnd_global.org_name
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
    log(p_debug, 'Resp'||lv_resp_key);
    select responsibility_id , application_id
    into ln_resp_id, ln_application_id
    from fnd_responsibility where responsibility_key = lv_resp_key;
    x_resp_id := ln_resp_id;
    x_appl_id := ln_application_id;
    log(p_debug,  'Resp ID '||ln_resp_id);
    log(p_debug,  'Appl ID '||ln_application_id);
  EXCEPTION
    when others then
      log('Y', 'Error in get_resp_id');
  END get_resp_id;

   PROCEDURE update_fnd_resp_assignment
   ( p_fnd_user_id         IN       NUMBER
   , p_end_date            IN       DATE     DEFAULT NULL
   , p_action              IN       VARCHAR2
   , p_bsd_access_code     IN       NUMBER   DEFAULT NULL
   , p_debug               IN  VARCHAR2
   , x_retcode             OUT      VARCHAR2
   )
   AS
    ln_application_id     NUMBER;
    ln_resp_id            NUMBER;
   BEGIN
      log(p_debug, 'update_fnd_resp_assignment(+)');
        get_resp_id ( p_bsd_access_code  => p_bsd_access_code
                    , p_debug            => p_debug
                    , x_resp_id          => ln_resp_id
                    , x_appl_id          => ln_application_id
                    );   
        log(p_debug, 'ln_resp_id: ' || ln_resp_id || 'ln_application_id: ' || ln_application_id);
        FND_USER_RESP_GROUPS_API.upload_assignment
         ( user_id                            => p_fnd_user_id
         , responsibility_id                  => ln_resp_id 
         , responsibility_application_id      => ln_application_id
         , start_date                         => SYSDATE
         , end_date                           => p_end_date
         , description                        => 'OD AR iReceivables Account Management'
         );   
      x_retcode := 1; -- Success
      log(p_debug, 'update_fnd_resp_assignment(-)');
   EXCEPTION
     when others then
       log('Y', 'Error in update_fnd_resp_assignment' || sqlerrm);
       --x_retcode := 116;
       --raise;
   END update_fnd_resp_assignment;
   
   PROCEDURE check_responsibility (
       p_cust_acct_cnt_os     IN       VARCHAR2
     , p_cust_acct_cnt_osr    IN       VARCHAR2
     , p_cust_acct_site_osr   IN       VARCHAR2
     , p_cust_acct_osr        IN       VARCHAR2
     , p_action               IN       VARCHAR2
     , p_permission_flag      IN       VARCHAR2
	 , p_debug                IN       VARCHAR2
     , x_cust_acct_site_id    OUT      NUMBER
     , x_org_contact_id       OUT      NUMBER
	 , x_cust_account_role_id OUT      NUMBER
     , x_responsibility_type  OUT      HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE
     , x_retcode              OUT      VARCHAR2
   )
   IS
    ln_bill_to_site_id       number(15);
    ln_ship_to_site_id       number(15);
    ln_cust_acct_site_id     number(15);
    ln_org_contact_id        number(15);
    ln_cust_account_role_id  number(15);
    lv_responsibility_type   HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE;
	 
   BEGIN
      log(p_debug, 'check_responsibility(+)');
     
      log(p_debug, 'p_cust_acct_cnt_os: '   || p_cust_acct_cnt_os);
      log(p_debug, 'p_cust_acct_cnt_osr: '  || p_cust_acct_cnt_osr);
      log(p_debug, 'p_cust_acct_site_osr: ' || p_cust_acct_site_osr);
      log(p_debug, 'p_cust_acct_osr: '      || p_cust_acct_osr);
      log(p_debug, 'p_permission_flag: '    || p_permission_flag);
	  /*
      x_bill_to_site_id       := 0;   
      x_ship_to_site_id       := 0;   
      x_cust_acct_site_id     := 0;   
      x_org_contact_id        := 0;   
      x_cust_account_role_id  := 0;
	   
      get_site_use_id ( p_cust_acct_cnt_os
                      , p_cust_acct_site_osr
                      , 'BILL_TO'
                      , ln_bill_to_site_id  
                      );

      log(p_debug, 'ln_bill_to_site_id: ' || ln_bill_to_site_id);
	  x_bill_to_site_id := ln_bill_to_site_id;
	  
      get_site_use_id ( p_cust_acct_cnt_os
                      , p_cust_acct_site_osr
                      , 'SHIP_TO'
                      , ln_ship_to_site_id  
                      );      
      log(p_debug, 'ln_ship_to_site_id: ' || ln_ship_to_site_id);
	  x_ship_to_site_id := ln_ship_to_site_id;
	  */
      get_owner_table_id ( p_cust_acct_cnt_os
                      , p_cust_acct_site_osr
                      , 'HZ_CUST_ACCT_SITES_ALL'
                      , ln_cust_acct_site_id  
                      ); 	  
      
      log(p_debug, 'ln_cust_acct_site_id: ' || ln_cust_acct_site_id);
      x_cust_acct_site_id := ln_cust_acct_site_id;
	  
      get_owner_table_id ( p_cust_acct_cnt_os
                         , p_cust_acct_cnt_osr
                         , 'HZ_ORG_CONTACTS'
                         , ln_org_contact_id
                         );
      log(p_debug, 'ln_org_contact_id: ' || ln_org_contact_id);
	  
      get_cust_account_role_id (
                                 p_cust_acct_cnt_osr
								 , ln_cust_account_role_id 
      );						 
      log(p_debug, 'ln_cust_account_role_id: ' || ln_cust_account_role_id);
      x_cust_account_role_id := ln_cust_account_role_id;
	  
      get_role_responsibility (
                                 ln_cust_account_role_id
                               , lv_responsibility_type 
      );
      	  
      log(p_debug, 'lv_responsibility_type: ' || lv_responsibility_type);
      x_responsibility_type := lv_responsibility_type;

      log(p_debug, 'check_responsibility(-)');
	 
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         log('Y', 'Exception in resync pkg check_responsibility, when NO_DATA_FOUND: ' || SQLERRM);
      WHEN TOO_MANY_ROWS
      THEN
         log('Y', 'Exception in resync pkg check_responsibility, when TOO_MANY_ROWS: ' || SQLERRM);
      WHEN OTHERS
      THEN
         log('Y', 'Exception in resync pkg check_responsibility, when OTHERS: ' || SQLERRM);
   END check_responsibility;   
   
  procedure re_sync_user (
                           x_errbuf              OUT VARCHAR2
                          ,x_retcode             OUT VARCHAR2
				          ,p_userid              IN  VARCHAR2   
                          ,p_debug               IN  VARCHAR2 DEFAULT 'N'  
                         )
  IS
    ln_cust_acct_site_id     NUMBER := 0;
    ln_org_contact_id        NUMBER := 0;
    ln_cust_account_role_id  NUMBER := 0;
    lv_responsibility_type   HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE := null;
    ln_retcode               NUMBER := 0;

    CURSOR C1
	IS
    SELECT 
    	     USRS.USERID 
           , fnd_ldap_wrapper.user_exists(USRS.FND_USER_NAME) as exists_in_oid
           , FUSR.USER_ID
           , FUSR.USER_NAME
           , USRS.FND_USER_NAME 
           , USRS.PARTY_ID
           , USRS.CONTACT_OSR
           , USRS.ACCT_SITE_OSR
		   , XX_DECIPHER(USRS.PASSWORD) AS BSD_PASSWORD
           , USRS.OID_UPDATE_DATE 
           , USRS.LAST_UPDATE_DATE 
           , USRS.LOAD_STATUS 
           , USRS.ACCESS_CODE
           , USRS.PERMISSION_FLAG
           , RESP.RESPONSIBILITY_ID 
           , SUBSTRB(PRTY.ORIG_SYSTEM_REFERENCE,1,8) AS AOPS_CUSTOMER_ID
           , PRTY.PARTY_NAME AS CUSTOMER_NAME
           , CPTY.PARTY_NAME AS CONTACT_NAME
           , ACCT.ACCOUNT_NUMBER 
    FROM     XX_EXTERNAL_USERS   USRS
           , HZ_RELATIONSHIPS     RELS
           , HZ_CUST_ACCOUNTS     ACCT
           , HZ_PARTIES           PRTY
           , HZ_PARTIES           CPTY
           , FND_USER_RESP_GROUPS RESP
           , FND_USER             FUSR
    WHERE  1=1
    AND    USRS.PARTY_ID = RELS.PARTY_ID
    AND    RELS.SUBJECT_TYPE='ORGANIZATION'
    AND    RELS.SUBJECT_ID = PRTY.PARTY_ID
    AND    PRTY.PARTY_ID = ACCT.PARTY_ID
    AND    RELS.OBJECT_ID =  CPTY.PARTY_ID
    AND    USRS.FND_USER_NAME = FUSR.USER_NAME (+)
    AND    FUSR.USER_ID = RESP.USER_ID (+)
    AND    USRS.USERID = p_userid;
  
  begin
    log(p_debug, 'XX_CDH_EXT_USER_RESYNC_PKG.re_sync_user(+)');
    out ('BSD_USER_ID, EXISTS_IN_OID, FND_USER_ID, FND_USER_NAME, PARTY_ID, BSD_PASSWORD, OID_UPDATE_DATE, LAST_UPDATE_DATE, LOAD_STATUS, ACCESS_CODE, RESPONSIBILITY_ID, AOPS_CUSTOMER_ID, CUSTOMER_NAME, CONTACT_NAME, ACCOUNT_NUMBER, CUST_ACCT_SITE_ID, ORG_CONTACT_ID, CUST_ACCOUNT_ROLE_ID, ROLE_RESPONSIBILITY_TYPE');
    log (p_debug,'BSD_USER_ID, EXISTS_IN_OID, FND_USER_ID, FND_USER_NAME, PARTY_ID, BSD_PASSWORD, OID_UPDATE_DATE, LAST_UPDATE_DATE, LOAD_STATUS, ACCESS_CODE, RESPONSIBILITY_ID, AOPS_CUSTOMER_ID, CUSTOMER_NAME, CONTACT_NAME, ACCOUNT_NUMBER, CUST_ACCT_SITE_ID, ORG_CONTACT_ID, CUST_ACCOUNT_ROLE_ID, ROLE_RESPONSIBILITY_TYPE');
    for i_rec in C1
    loop
     IF (i_rec.USER_ID is NULL) THEN
       update XX_EXTERNAL_USERS
       set    load_status = 'P'
             ,OID_UPDATE_DATE   =  sysdate
             ,last_update_date  =  sysdate 
             ,last_updated_by   =  fnd_global.user_id()
             ,last_update_login =  fnd_global.login_id()
       where  userid            =  i_rec.USERID;
	   commit;
     END IF;

     IF (i_rec.USER_ID is NOT NULL AND i_rec.RESPONSIBILITY_ID is NULL) THEN

       check_responsibility (
              p_cust_acct_cnt_os     => 'A0'
            , p_cust_acct_cnt_osr    => i_rec.CONTACT_OSR
            , p_cust_acct_site_osr   => i_rec.ACCT_SITE_OSR
            , p_cust_acct_osr        => SUBSTRB(i_rec.ACCT_SITE_OSR,1,8) || '-00001-A0'
            , p_action               => 'C'
            , p_permission_flag      => i_rec.permission_flag
            , p_debug                => p_debug
            , x_cust_acct_site_id    => ln_cust_acct_site_id   
            , x_org_contact_id       => ln_org_contact_id      
            , x_cust_account_role_id => ln_cust_account_role_id
            , x_responsibility_type  => lv_responsibility_type 
            , x_retcode              => ln_retcode             
          );
       IF (lv_responsibility_type != null) THEN
         update_fnd_resp_assignment
                                   ( p_fnd_user_id         => i_rec.USER_ID
                                   , p_end_date            => NULL --Check how do we get end_date
                                   , p_action              => 'C'
                                   , p_bsd_access_code     => i_rec.ACCESS_CODE
                                   , p_debug               => p_debug
                                   , x_retcode             => ln_retcode
                                   );
         log(p_debug, ' After calling update_fnd_resp_assignment: ' || ln_retcode);
       ELSE
         log (p_debug, 'Error in getting CDH Role_responsibility - ln_cust_acct_site_id: '    || ln_cust_acct_site_id
                                                               || 'ln_org_contact_id: '       || ln_org_contact_id
                                                               || 'ln_cust_account_role_id: ' || ln_cust_account_role_id
                                                               || 'lv_responsibility_type: '  || lv_responsibility_type
             );
       END IF;
     END IF;


	out (i_rec.USERID || ',' || i_rec.EXISTS_IN_OID || ',' || i_rec.USER_ID || ',' || i_rec.FND_USER_NAME || ',' || i_rec.PARTY_ID || ',' || i_rec.BSD_PASSWORD || ',' || to_char(i_rec.OID_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' ||  to_char(i_rec.LAST_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' || i_rec.LOAD_STATUS || ',' || i_rec.ACCESS_CODE || ',' || i_rec.RESPONSIBILITY_ID || ',' || i_rec.AOPS_CUSTOMER_ID || ',' || i_rec.CUSTOMER_NAME || ',' || i_rec.CONTACT_NAME || ',' ||  i_rec.ACCOUNT_NUMBER || ', ' || ln_cust_acct_site_id || ', ' || ln_org_contact_id || ', ' || ln_cust_account_role_id || ', ' || lv_responsibility_type);
	log (p_debug,
         i_rec.USERID || ',' || i_rec.EXISTS_IN_OID || ',' || i_rec.USER_ID || ',' || i_rec.FND_USER_NAME || ',' || i_rec.PARTY_ID || ',' || i_rec.BSD_PASSWORD || ',' || to_char(i_rec.OID_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' ||  to_char(i_rec.LAST_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' || i_rec.LOAD_STATUS || ',' || i_rec.ACCESS_CODE || ',' || i_rec.RESPONSIBILITY_ID || ',' || i_rec.AOPS_CUSTOMER_ID || ',' || i_rec.CUSTOMER_NAME || ',' || i_rec.CONTACT_NAME || ',' ||  i_rec.ACCOUNT_NUMBER || ', ' || ln_cust_acct_site_id || ', ' || ln_org_contact_id || ', ' || ln_cust_account_role_id || ', ' || lv_responsibility_type);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    end loop;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  log(p_debug, 'XX_CDH_EXT_USER_RESYNC_PKG.re_sync_user(-)');
  exception
    when others then
	  log('Y', 'Exception in XX_CDH_EXT_USER_RESYNC_PKG.re_sync_user: ' || SQLERRM);
      x_errbuf := 'Error when submitting request - '||fnd_message.get;
      x_retcode := 2;	  
  end re_sync_user;   
  
  procedure main (
                    x_errbuf              OUT VARCHAR2
                   ,x_retcode             OUT VARCHAR2
				   ,p_last_upd_date_from  IN  VARCHAR2     
				   ,p_last_upd_date_to    IN  VARCHAR2 DEFAULT TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')      
				   ,p_creation_date_from  IN  VARCHAR2 
				   ,p_creation_date_to    IN  VARCHAR2 
				   ,p_commit_size         IN  NUMBER   DEFAULT 40
                   ,p_sleep_time          IN  NUMBER   DEFAULT 60
				   ,p_debug               IN  VARCHAR2 DEFAULT 'N'
            )
  IS
    l_count                  NUMBER := 0;
	l_last_upd_date_from     DATE := null;
	
	PX_CUST_ACCOUNT_ID       NUMBER;        
	PX_SHIP_TO_ACCT_SITE_ID  NUMBER;
	PX_BILL_TO_ACCT_SITE_ID  NUMBER;
	PX_PARTY_ID              NUMBER;
	X_WEB_USER_STATUS        VARCHAR2(1);
	X_RETURN_STATUS          VARCHAR2(1);
	X_MSG_COUNT              NUMBER;
	X_MSG_DATA               VARCHAR2(2000);
    ln_cust_acct_site_id     NUMBER := 0;
    ln_org_contact_id        NUMBER := 0;
    ln_cust_account_role_id  NUMBER := 0;
    lv_responsibility_type   HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE := null;
    ln_retcode               NUMBER := 0;
	
    CURSOR C1 (  p_last_update_date_from IN  DATE 
	            ,p_last_update_date_to   IN  DATE 
				,p_creation_date_from    IN  DATE 
				,p_creation_date_to      IN  DATE 
              )	
	IS
    SELECT 
    	     USRS.USERID 
           , fnd_ldap_wrapper.user_exists(USRS.FND_USER_NAME) as exists_in_oid
           , FUSR.USER_ID
           , FUSR.USER_NAME
           , USRS.FND_USER_NAME 
           , USRS.PARTY_ID
           , USRS.CONTACT_OSR
           , USRS.ACCT_SITE_OSR
		   , XX_DECIPHER(USRS.PASSWORD) AS BSD_PASSWORD
           , USRS.OID_UPDATE_DATE 
           , USRS.LAST_UPDATE_DATE 
           , USRS.LOAD_STATUS 
           , USRS.ACCESS_CODE
           , RESP.RESPONSIBILITY_ID 
           , SUBSTRB(PRTY.ORIG_SYSTEM_REFERENCE,1,8) AS AOPS_CUSTOMER_ID
           , PRTY.PARTY_NAME AS CUSTOMER_NAME
           , CPTY.PARTY_NAME AS CONTACT_NAME
           , ACCT.ACCOUNT_NUMBER 
    FROM     XX_EXTERNAL_USERS   USRS
           , HZ_RELATIONSHIPS     RELS
           , HZ_CUST_ACCOUNTS     ACCT
           , HZ_PARTIES           PRTY
           , HZ_PARTIES           CPTY
           , FND_USER_RESP_GROUPS RESP
           , FND_USER             FUSR
    WHERE  1=1
    AND    USRS.PARTY_ID = RELS.PARTY_ID
    AND    RELS.SUBJECT_TYPE='ORGANIZATION'
    AND    RELS.SUBJECT_ID = PRTY.PARTY_ID
    AND    PRTY.PARTY_ID = ACCT.PARTY_ID
    AND    RELS.OBJECT_ID =  CPTY.PARTY_ID
    AND    USRS.FND_USER_NAME = FUSR.USER_NAME (+)
    AND    FUSR.USER_ID = RESP.USER_ID (+)
    AND    FUSR.USER_ID IS NULL
    AND    USRS.LAST_UPDATE_DATE between p_last_update_date_from and p_last_update_date_to
    ORDER BY USRS.LAST_UPDATE_DATE DESC;

    CURSOR C2 (  p_last_update_date_from IN  DATE 
	            ,p_last_update_date_to   IN  DATE 
				,p_creation_date_from    IN  DATE 
				,p_creation_date_to      IN  DATE 
              )	
	IS
    SELECT 
    	     USRS.USERID 
           , fnd_ldap_wrapper.user_exists(USRS.FND_USER_NAME) as exists_in_oid
           , USRS.FND_USER_NAME 
           , USRS.PARTY_ID
           , USRS.ORIG_SYSTEM		   
           , USRS.ACCT_SITE_OSR
           , USRS.CONTACT_OSR
           , USRS.PERMISSION_FLAG
           , USRS.OID_UPDATE_DATE 
           , USRS.LAST_UPDATE_DATE 
           , USRS.LOAD_STATUS 
           , USRS.ACCESS_CODE
           , FUSR.USER_ID
           , FUSR.USER_NAME
		   , XX_DECIPHER(USRS.PASSWORD) AS BSD_PASSWORD
           , RESP.RESPONSIBILITY_ID 
           , SUBSTRB(PRTY.ORIG_SYSTEM_REFERENCE,1,8) AS AOPS_CUSTOMER_ID
           , PRTY.PARTY_NAME AS CUSTOMER_NAME
           , CPTY.PARTY_NAME AS CONTACT_NAME
           , ACCT.ACCOUNT_NUMBER 
           , ACCT.CUST_ACCOUNT_ID 
           , ACCT.ORIG_SYSTEM_REFERENCE as CUST_ACCT_OSR
    FROM     XX_EXTERNAL_USERS   USRS
           , HZ_RELATIONSHIPS     RELS
           , HZ_CUST_ACCOUNTS     ACCT
           , HZ_PARTIES           PRTY
           , HZ_PARTIES           CPTY
           , FND_USER_RESP_GROUPS RESP
           , FND_USER             FUSR
    WHERE  1=1
    AND    USRS.PARTY_ID = RELS.PARTY_ID
	AND    USRS.access_code in ('01', '02', '03', '05', '06')
    AND    RELS.SUBJECT_TYPE='ORGANIZATION'
    AND    RELS.SUBJECT_ID = PRTY.PARTY_ID
    AND    PRTY.PARTY_ID = ACCT.PARTY_ID
    AND    RELS.OBJECT_ID =  CPTY.PARTY_ID
    AND    USRS.FND_USER_NAME = FUSR.USER_NAME (+)
    AND    FUSR.USER_ID = RESP.USER_ID (+)
    AND    RESP.RESPONSIBILITY_ID IS NULL
    AND    USRS.LAST_UPDATE_DATE between p_last_update_date_from and p_last_update_date_to
    ORDER BY USRS.LAST_UPDATE_DATE DESC;

  BEGIN
    log(p_debug, 'XX_CDH_EXT_USER_RESYNC_PKG.main(+)');
    log(p_debug, 'p_last_upd_date_from:' || p_last_upd_date_from);
    log(p_debug, 'p_last_upd_date_to:' || p_last_upd_date_to);
	
	if ( (to_date(p_last_upd_date_to,   'DD-MON-YYYY HH24:MI:SS')  - 
	      to_date(p_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS')) > 
		  nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3)
       ) then
	   log('Y', 'From Date and To Date duration is higher than ' || nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3) || ' days! Exiting!!');
	   return;
    end if;

	if ( (to_date(p_creation_date_to,   'DD-MON-YYYY HH24:MI:SS')  - 
	      to_date(p_creation_date_from, 'DD-MON-YYYY HH24:MI:SS')) > 
		  nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3)
       ) then
	   log('Y', 'From Date and To Date duration is higher than ' || nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3) || ' days! Exiting!!');
	   return;
    end if;
	
    if ( (p_creation_date_to is not null and p_creation_date_from is not null) and (p_last_upd_date_to is not null or p_last_upd_date_from is not null)) then
	  log('Y', 'Either combination of last_update_date and creation_dates must be given! Exiting!!');
	   return;
    end if;
    if( (p_last_upd_date_to is not null and p_last_upd_date_from is not null) and (p_creation_date_to is not null or p_creation_date_from is not null)) then
	  log('Y', '2Either combination of last_update_date and creation_dates must be given! Exiting!!');
	   return;
    end if;
	
    BEGIN
	
    select b.actual_start_date 
    into   l_last_upd_date_from
    from (
    select rownum as rn, cp.actual_start_date from (
      select actual_start_date
      from   fnd_concurrent_requests
      where  concurrent_program_id = (select concurrent_program_id
                                      from   fnd_concurrent_programs_vl
                                      where  user_concurrent_program_name = 'OD: XXCOMN Re-sync External Users Program'
                                     )
    order by actual_start_date desc) cp) b
    where  rn = 2;
								   
    log(p_debug, 'l_last_upd_date_from:' || to_char(l_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS'));
    EXCEPTION
      when no_data_found then
       	l_last_upd_date_from := sysdate - 1/24;
        log(p_debug, 'no data found; hence, l_last_upd_date_from:' || to_char(l_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS'));
    END;

    log(p_debug, ' last_upd_date_from:' || nvl(p_last_upd_date_from, to_char(l_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS')));
    log(p_debug, 'p_last_upd_date_to:' || nvl(p_last_upd_date_to,TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')));

    --First check if FND_USER_ID is null and update the OID_UPDATE_DATE, so that OID's  Provisioning SYNC re-syncs the FND USER
	--start of C1 loop
    for i_rec in C1 ( nvl(to_date(p_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(l_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS')), to_date(p_last_upd_date_to, 'DD-MON-YYYY HH24:MI:SS'), 
                      to_date(p_creation_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(p_creation_date_to, 'DD-MON-YYYY HH24:MI:SS')
                    )
	loop
	    
	  log(p_debug, 'userid:' || i_rec.userid  || ', exists_in_oid: ' ||  i_rec.exists_in_oid || ', count:' || l_count);
	  
	  if ((i_rec.access_code is null or i_rec.access_code = '00') and i_rec.load_status <> 'C') then
	    
        log(p_debug, 'Reset the status to C for userid:' || i_rec.userid);
        update XX_EXTERNAL_USERS
        set    load_status = 'C'
              ,last_update_date  =  sysdate
              ,last_updated_by   =  fnd_global.user_id()
              ,last_update_login =  fnd_global.login_id()
        where  userid            =  i_rec.USERID;		
          
        commit;
		  
	  end if;
	    
      if ( i_rec.access_code in ('01', '02', '03', '05', '06') and i_rec.USER_ID IS NULL) then
          	 
        log(p_debug, 'Retouched the record for userid:' || i_rec.userid);
        update XX_EXTERNAL_USERS
        set    load_status = 'P'
              ,OID_UPDATE_DATE   =  sysdate
              ,last_update_date  =  sysdate 
              ,last_updated_by   =  fnd_global.user_id()
              ,last_update_login =  fnd_global.login_id()
        where  userid            =  i_rec.USERID;	          
	    commit;
               
        l_count := l_count + 1;
        
      end if;
	    
      if (i_rec.access_code in ('01', '02', '03', '05', '06') and i_rec.RESPONSIBILITY_ID IS NULL and i_rec.USER_ID IS NOT NULL) then
          	 
        log(p_debug, 'Reset the status to P for userid:' || i_rec.userid);
	      
        update XX_EXTERNAL_USERS
        set    load_status = 'P'
              ,last_update_date  =  sysdate
              ,last_updated_by   =  fnd_global.user_id()
              ,last_update_login =  fnd_global.login_id()
        where  userid            =  i_rec.USERID;	          
               
        l_count := l_count + 1;
        
      end if;	  
        
      if (l_count = p_commit_size) then
          
	    dbms_lock.sleep( p_sleep_time ); -- sleep for some seconds provided by parameter
	    l_count := 0;
          
      end if;
        
	end loop;
	--End of C1 Loop
	
    --Second check if RESPONSIBILITY_ID is null and invoke XX_CDH_WEBCONTACTS_BO_PUB.SAVE_ROLE_RESP
	--Start if C2 loop
    for j_rec in C2 ( nvl(to_date(p_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(l_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS')), to_date(p_last_upd_date_to, 'DD-MON-YYYY HH24:MI:SS'), 
                      to_date(p_creation_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(p_creation_date_to, 'DD-MON-YYYY HH24:MI:SS')
                    )
	loop
	    
	  log(p_debug, 'userid:' || j_rec.userid  || ', exists_in_oid: ' ||  j_rec.exists_in_oid || ', FND_USER_NAME:' || j_rec.FND_USER_NAME || ', RESPONSIBILITY_ID: ' || j_rec.RESPONSIBILITY_ID);
	  

      if ( j_rec.access_code in ('01', '02', '03', '05', '06') and j_rec.USER_ID IS NOT NULL and j_rec.RESPONSIBILITY_ID IS NULL) then
          	 
        log(p_debug, 'Invoking XX_CDH_WEBCONTACTS_PVT.SAVE_ACCOUNT_CONTACT_ROLE for userid:' || j_rec.userid);

          check_responsibility (
              p_cust_acct_cnt_os     => 'A0'
            , p_cust_acct_cnt_osr    => j_rec.CONTACT_OSR
            , p_cust_acct_site_osr   => j_rec.ACCT_SITE_OSR
            , p_cust_acct_osr        => j_rec.CUST_ACCT_OSR
            , p_action               => 'C'
            , p_permission_flag      => j_rec.permission_flag
            , p_debug                => p_debug
            , x_cust_acct_site_id    => ln_cust_acct_site_id   
            , x_org_contact_id       => ln_org_contact_id      
            , x_cust_account_role_id => ln_cust_account_role_id
            , x_responsibility_type  => lv_responsibility_type 
            , x_retcode              => ln_retcode             
          );
          IF (lv_responsibility_type != null) THEN
            update_fnd_resp_assignment
                                      ( p_fnd_user_id         => j_rec.USER_ID
                                      , p_end_date            => NULL --Check how do we get end_date
                                      , p_action              => ''
                                      , p_bsd_access_code     => j_rec.ACCESS_CODE
                                      , p_debug               => p_debug
                                      , x_retcode             => ln_retcode
                                      );
            log(p_debug, ' After calling update_fnd_resp_assignment: ' || ln_retcode);
          ELSE
            log (p_debug, 'Error in getting CDH Role_responsibility - ln_cust_acct_site_id: '    || ln_cust_acct_site_id
                                                                  || 'ln_org_contact_id: '       || ln_org_contact_id
                                                                  || 'ln_cust_account_role_id: ' || ln_cust_account_role_id
                                                                  || 'lv_responsibility_type: '  || lv_responsibility_type
                );
          END IF;

		end if;
	            
	end loop;
    --End of C2 loop
    log(p_debug, 'XX_CDH_EXT_USER_RESYNC_PKG.main(-)');
	
  exception
    when others then
	  log('Y', 'Exception in XX_CDH_EXT_USER_RESYNC_PKG.main: ' || SQLERRM);
      x_errbuf := 'Error when submitting request - '||fnd_message.get;
      x_retcode := 2;	  
  end main;  
  
  procedure show_report (
                    x_errbuf              OUT VARCHAR2
                   ,x_retcode             OUT VARCHAR2
				   ,p_last_upd_date_from  IN  VARCHAR2     
				   ,p_last_upd_date_to    IN  VARCHAR2 DEFAULT TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')
				   ,p_creation_date_from  IN  VARCHAR2 
				   ,p_creation_date_to    IN  VARCHAR2 
            ) 
  is
    ln_cust_acct_site_id     NUMBER := 0;
    ln_org_contact_id        NUMBER := 0;
    ln_cust_account_role_id  NUMBER := 0;
    lv_responsibility_type   HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE := null;
    ln_retcode               NUMBER := 0;

    CURSOR C1 (  p_last_update_date_from IN  DATE 
	            ,p_last_update_date_to   IN  DATE 
				,p_creation_date_from    IN  DATE 
				,p_creation_date_to      IN  DATE 
              )	
	IS  
      SELECT 
    	     USRS.USERID 
           , fnd_ldap_wrapper.user_exists(USRS.FND_USER_NAME) as exists_in_oid
           , USRS.FND_USER_NAME 
           , USRS.PARTY_ID
           , USRS.ORIG_SYSTEM		   
           , USRS.ACCT_SITE_OSR
           , USRS.CONTACT_OSR
           , USRS.PERMISSION_FLAG
           , USRS.OID_UPDATE_DATE 
           , USRS.LAST_UPDATE_DATE 
           , USRS.LOAD_STATUS 
           , USRS.ACCESS_CODE
           , FUSR.USER_ID
           , FUSR.USER_NAME
		   , XX_DECIPHER(USRS.PASSWORD) AS BSD_PASSWORD
           , RESP.RESPONSIBILITY_ID 
           , SUBSTRB(PRTY.ORIG_SYSTEM_REFERENCE,1,8) AS AOPS_CUSTOMER_ID
           , PRTY.PARTY_NAME AS CUSTOMER_NAME
           , CPTY.PARTY_NAME AS CONTACT_NAME
           , ACCT.ACCOUNT_NUMBER 
           , ACCT.CUST_ACCOUNT_ID 
           , ACCT.ORIG_SYSTEM_REFERENCE as CUST_ACCT_OSR
    FROM     XX_EXTERNAL_USERS   USRS
           , HZ_RELATIONSHIPS     RELS
           , HZ_CUST_ACCOUNTS     ACCT
           , HZ_PARTIES           PRTY
           , HZ_PARTIES           CPTY
           , FND_USER_RESP_GROUPS RESP
           , FND_USER             FUSR
    WHERE  1=1
    AND    USRS.PARTY_ID = RELS.PARTY_ID
    AND    RELS.SUBJECT_TYPE='ORGANIZATION'
    AND    RELS.SUBJECT_ID = PRTY.PARTY_ID
    AND    PRTY.PARTY_ID = ACCT.PARTY_ID
    AND    RELS.OBJECT_ID =  CPTY.PARTY_ID
    AND    USRS.FND_USER_NAME = FUSR.USER_NAME (+)
    AND    FUSR.USER_ID = RESP.USER_ID (+)
    AND    ((USRS.LAST_UPDATE_DATE between p_last_update_date_from and p_last_update_date_to ) or
            (USRS.CREATION_DATE between p_creation_date_from and p_creation_date_to )
           )
    ORDER BY USRS.LAST_UPDATE_DATE DESC;
	
  begin
    log('Y', 'p_last_upd_date_to: ' || p_last_upd_date_to);
    log('Y', 'p_last_upd_date_from: ' || p_last_upd_date_from);
    log('Y', 'p_creation_date_to: ' || p_creation_date_to || ', length: ' || length(p_creation_date_to));
    log('Y', 'p_creation_date_from: ' || p_creation_date_from || ', length: ' || length(p_creation_date_from));
	
	if ( (to_date(p_last_upd_date_to,   'DD-MON-YYYY HH24:MI:SS')  - 
	      to_date(p_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS')) > 
		  nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3)
       ) then
	   log('Y', 'From Date and To Date duration is higher than ' || nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3) || ' days! Exiting!!');
	   return;
    end if;

	if ( (to_date(p_creation_date_to,   'DD-MON-YYYY HH24:MI:SS')  - 
	      to_date(p_creation_date_from, 'DD-MON-YYYY HH24:MI:SS')) > 
		  nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3)
       ) then
	   log('Y', 'From Date and To Date duration is higher than ' || nvl(fnd_profile.value('XX_COMN_BSD_USER_RESYNC_DATERANGE'),3) || ' days! Exiting!!');
	   return;
    end if;
	
    if ( (p_creation_date_to is not null and p_creation_date_from is not null) and (p_last_upd_date_to is not null or p_last_upd_date_from is not null)) then
	  log('Y', '1Either combination of last_update_date and creation_dates must be given! Exiting!!');
	   return;
    end if;
    if( (p_last_upd_date_to is not null and p_last_upd_date_from is not null) and (p_creation_date_to is not null or p_creation_date_from is not null)) then
	  log('Y', '2Either combination of last_update_date and creation_dates must be given! Exiting!!');
	   return;
    end if;
	
	
    out ('BSD_USER_ID, EXISTS_IN_OID, FND_USER_ID, FND_USER_NAME, PARTY_ID, BSD_PASSWORD, OID_UPDATE_DATE, LAST_UPDATE_DATE, LOAD_STATUS, ACCESS_CODE, RESPONSIBILITY_ID, AOPS_CUSTOMER_ID, CUSTOMER_NAME, CONTACT_NAME, ACCOUNT_NUMBER, CUST_ACCT_SITE_ID, ORG_CONTACT_ID, CUST_ACCOUNT_ROLE_ID, ROLE_RESPONSIBILITY_TYPE');
    log ('Y','BSD_USER_ID, EXISTS_IN_OID, FND_USER_ID, FND_USER_NAME, PARTY_ID, BSD_PASSWORD, OID_UPDATE_DATE, LAST_UPDATE_DATE, LOAD_STATUS, ACCESS_CODE, RESPONSIBILITY_ID, AOPS_CUSTOMER_ID, CUSTOMER_NAME, CONTACT_NAME, ACCOUNT_NUMBER, CUST_ACCT_SITE_ID, ORG_CONTACT_ID, CUST_ACCOUNT_ROLE_ID, ROLE_RESPONSIBILITY_TYPE');

    for i_rec in C1 ( to_date(p_last_upd_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(p_last_upd_date_to, 'DD-MON-YYYY HH24:MI:SS'), 
                      to_date(p_creation_date_from, 'DD-MON-YYYY HH24:MI:SS'), to_date(p_creation_date_to, 'DD-MON-YYYY HH24:MI:SS')
                    )
	loop
      if (i_rec.RESPONSIBILITY_ID IS NULL) then
          check_responsibility (
              p_cust_acct_cnt_os     => 'A0'
            , p_cust_acct_cnt_osr    => i_rec.CONTACT_OSR
            , p_cust_acct_site_osr   => i_rec.ACCT_SITE_OSR
            , p_cust_acct_osr        => i_rec.CUST_ACCT_OSR
            , p_action               => 'C'
            , p_permission_flag      => i_rec.permission_flag
            , p_debug                => 'N'
            , x_cust_acct_site_id    => ln_cust_acct_site_id   
            , x_org_contact_id       => ln_org_contact_id      
            , x_cust_account_role_id => ln_cust_account_role_id
            , x_responsibility_type  => lv_responsibility_type 
            , x_retcode              => ln_retcode             
          );

      end if;

	  out (i_rec.USERID || ',' || i_rec.EXISTS_IN_OID || ',' || i_rec.USER_ID || ',' || i_rec.FND_USER_NAME || ',' || i_rec.PARTY_ID || ',' || i_rec.BSD_PASSWORD || ',' || to_char(i_rec.OID_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' ||  to_char(i_rec.LAST_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' || i_rec.LOAD_STATUS || ',' || i_rec.ACCESS_CODE || ',' || i_rec.RESPONSIBILITY_ID || ',' || i_rec.AOPS_CUSTOMER_ID || ',' || i_rec.CUSTOMER_NAME || ',' || i_rec.CONTACT_NAME || ',' ||  i_rec.ACCOUNT_NUMBER || ', ' || ln_cust_acct_site_id || ', ' || ln_org_contact_id || ', ' || ln_cust_account_role_id || ', ' || lv_responsibility_type);
	  log ('Y',
           i_rec.USERID || ',' || i_rec.EXISTS_IN_OID || ',' || i_rec.USER_ID || ',' || i_rec.FND_USER_NAME || ',' || i_rec.PARTY_ID || ',' || i_rec.BSD_PASSWORD || ',' || to_char(i_rec.OID_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' ||  to_char(i_rec.LAST_UPDATE_DATE,'DD-MON-YYYY HH24:MI:SS') || ',' || i_rec.LOAD_STATUS || ',' || i_rec.ACCESS_CODE || ',' || i_rec.RESPONSIBILITY_ID || ',' || i_rec.AOPS_CUSTOMER_ID || ',' || i_rec.CUSTOMER_NAME || ',' || i_rec.CONTACT_NAME || ',' ||  i_rec.ACCOUNT_NUMBER || ', ' || ln_cust_acct_site_id || ', ' || ln_org_contact_id || ', ' || ln_cust_account_role_id || ', ' || lv_responsibility_type);
	  	  
    end loop;
	
  exception
    when others then
	  log('Y', 'Exception in XX_CDH_EXT_USER_RESYNC_PKG.show_report: ' || SQLERRM);
      x_errbuf := 'Error when submitting request - '||fnd_message.get;
      x_retcode := 2;	  
  end show_report; 
  
END XX_CDH_EXT_USER_RESYNC_PKG;
/
