create or replace PACKAGE BODY XX_EXTERNAL_USERS_BO_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_BO_PUB                                                             |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.                                           |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.                          |
-- |          31-Dec-2007 Yusuf Ali          Incorporated granular API for creating contact at account  |
-- |                                               site level and creating role for web user.                 |
-- |          02-Jan-2008 Yusuf Ali             Removed call to create_role_resp procedure from            |
-- |                                               save_ext_user procedure.                                   |
-- |          07-Jan-2008 Yusuf Ali             Created cursor to retrieve party id and cust account role  |
-- |                          Kathirvel Perumal  id from cust account roles table in create_role_resp       |
-- |                                                procedure and create equi-join query to get org id from    |
-- |                                                cust acct sites all table in save_ext_usr procedure.         |
-- |            07-Jan-2008 Yusuf Ali          Created cursor for fetching responsibility id and created  |
-- |                                         log_debug procedure to messages.                           |
-- |          08-Jan-2008 Narayan Bh.          Modified cursors to accept ln_acct_role_id parameter for   |
-- |                      Yusuf Ali             l_get_responsibility_id_cur, l_get_party_id_cur to accept  |
-- |                      Alok Sahay         OSR, and both cursors to select object version to pass     |
-- |                                         into appropriate granular API call, changed query in       |
-- |                                         save_ext_user to obtain org id for instance where          |
-- |                                         cust_acct_site_id IS NOT NULL.                                 |
-- |            08-Jan-2008 Narayan Bh          Created new query in create_role_resp to take              |
-- |                                               ln_bill_to_site_use_id to get cust_acct_site_id from          |
-- |                                              hz_cust_site_uses_all.                                           |
-- |          09-Jan-2008 Alok Sahay           Removed permission flag variable (not being used) for       |
-- |                                                condition where permission flag is S/M in create role resp |
-- |                                               procedure                                                         |
-- |          09-Jan-2008 Yusuf Ali          Created/moved get_site_use_id to beginning of                 |
-- |                           Alok Sahay          create_role_resp procedure.                                |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant Variables and Code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |          30-Sep-2008 Kathirvel.P        Changed the code to set the apps context for ODCRMBPEL if  |
-- |                                         the context is missing                                     |
-- |2.0       22-OCT-2015 Manikant Kasu      Webuser Password Sync Changes                              |
-- |2.1       17-SEP-2019 Sahithi Kunuru     NAIT-103309 Commented logic to update password regardless  |
-- |                                         of process_name UpdateExtUserPwd /SaveiReceivables         |
-- +====================================================================================================+
*/


  g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_EXTERNAL_USERS_BO_PUB';
  g_proc_name                    VARCHAR2(30)          := NULL;

  g_module                       CONSTANT VARCHAR2(30) := 'CRM';

  g_user_role                    CONSTANT VARCHAR2(60) := 'SELF_SERVICE_USER';
  g_revoked_user_role            CONSTANT VARCHAR2(60) := 'REVOKED_SELF_SERVICE_ROLE';

  g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();

 -- ===========================================================================
 -- Name             : log
 -- Description      : procedure to capture all the errors and debugs to custom
 --                    error log table, XX_COM_ERROR_LOG
 --
 -- Parameters :     : user_name
 --                  :
 --                  :
 -- ===========================================================================

  --Procedure for logging debug log
PROCEDURE log_debug ( p_error_pkg          IN  VARCHAR2
                     ,p_debug_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;

BEGIN

    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => 'DEBUG'
      ,p_attribute15             => g_pkg_name
      ,p_attribute16             => g_proc_name
      ,p_program_id              => 0
      ,p_module_name             => 'CDH'
      ,p_error_message           => p_debug_msg
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_debug_msg);

END log_debug;


PROCEDURE log_error     ( p_error_pkg      IN  VARCHAR2
                         ,p_debug_msg      IN  VARCHAR2 )
  IS

    ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
    ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;

  BEGIN

     XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCOMN'
        ,p_program_type            => 'ERROR'
        ,p_attribute15             => g_pkg_name
        ,p_attribute16             => g_proc_name
        ,p_program_id              => 0
        ,p_module_name             => 'CDH'
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'MAJOR'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
      fnd_file.put_line(fnd_file.log, p_debug_msg);


  END log_error;

   -- ===========================================================================
   -- | Name             : SAVE_EXT_USER
   -- | Description      : This procedure does a insert or update of
   -- |                    web user information into xx_external_users
   -- |                    table based on the information coming to
   -- |                    Oracle EBS from AOPS. This procedure is called
   -- |                    from SaveiReceivables BPEL process
   -- |
   -- |
   -- | Parameters       : p_userid
   -- |                    p_password
   -- |                    p_first_name
   -- |                    p_middle_initial
   -- |                    p_last_name
   -- |                    p_email
   -- |                    p_ext_upd_time
   -- |                    p_status
   -- |                    p_contact_osr
   -- |                    p_acct_site_osr
   -- |                    p_site_key
   -- |                    p_record_type
   -- |                    p_access_code
   -- |                    p_permission_flag
   -- |                    p_resp_key
   -- |                    p_party_id
   -- |                    x_return_status
   -- |                    x_messages
   -- |
   -- ===========================================================================
   PROCEDURE save_ext_user( p_userid                 IN          VARCHAR2
                          , p_password               IN          VARCHAR2
                          , p_first_name             IN          VARCHAR2
                          , p_middle_initial         IN          VARCHAR2
                          , p_last_name              IN          VARCHAR2
                          , p_email                  IN          VARCHAR
                          , p_ext_upd_time           IN          TIMESTAMP
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_action_type            IN          VARCHAR2 DEFAULT 'U'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_webuser_osr            IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          VARCHAR2 DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT NOCOPY  VARCHAR2
                          , x_messages               OUT NOCOPY  HZ_MESSAGE_OBJ_TBL
                          )
   IS
     l_msg_count            NUMBER;
     l_msg_data             VARCHAR2(4000);
   BEGIN

      save_ext_user( p_userid                 => p_userid
                   , p_password               => p_password
                   , p_first_name             => p_first_name
                   , p_middle_initial         => p_middle_initial
                   , p_last_name              => p_last_name
                   , p_email                  => p_email
                   , p_ext_upd_time           => p_ext_upd_time
                   , p_status                 => p_status
                   , p_action_type            => p_action_type
                   , p_orig_system            => p_orig_system
                   , p_cust_acct_osr          => p_cust_acct_osr
                   , p_contact_osr            => p_contact_osr
                   , p_acct_site_osr          => p_acct_site_osr
                   , p_webuser_osr            => p_webuser_osr
                   , p_record_type            => p_record_type
                   , p_access_code            => p_access_code
                   , p_permission_flag        => p_permission_flag
                   , p_cust_account_id        => p_cust_account_id
                   , p_ship_to_acct_site_id   => p_ship_to_acct_site_id
                   , p_bill_to_acct_site_id   => p_bill_to_acct_site_id
                   , p_party_id               => p_party_id
                   , x_return_status          => x_return_status
                   , x_msg_count              => l_msg_count
                   , x_msg_data               => l_msg_data
                   );

      x_messages := XX_EXTERNAL_USERS_PVT.get_messages ( p_return_status   => x_return_status
                                                       , p_msg_count       => l_msg_count
                                                       , p_msg_data        => l_msg_data);
   END SAVE_EXT_USER;

   -- ===========================================================================
   -- | Name             : SAVE_EXT_USER
   -- | Description      : This procedure does a insert or update of
   -- |                    web user information into xx_external_users
   -- |                    table based on the information coming to
   -- |                    Oracle EBS from AOPS. This procedure is called
   -- |                    from SaveiReceivables BPEL process
   -- |
   -- |
   -- | Parameters       : p_userid
   -- |                    p_password
   -- |                    p_first_name
   -- |                    p_middle_initial
   -- |                    p_last_name
   -- |                    p_email
   -- |                    p_ext_upd_time
   -- |                    p_status
   -- |                    p_contact_osr
   -- |                    p_acct_site_osr
   -- |                    p_site_key
   -- |                    p_record_type
   -- |                    p_access_code
   -- |                    p_permission_flag
   -- |                    p_resp_key
   -- |                    p_party_id
   -- |                    x_return_status
   -- |                    x_messages
   -- |
   -- ===========================================================================
   PROCEDURE save_ext_user( p_userid                 IN          VARCHAR2
                          , p_password               IN          VARCHAR2
                          , p_first_name             IN          VARCHAR2
                          , p_middle_initial         IN          VARCHAR2
                          , p_last_name              IN          VARCHAR2
                          , p_email                  IN          VARCHAR
                          , p_ext_upd_time           IN          TIMESTAMP
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_action_type            IN          VARCHAR2 DEFAULT 'U'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_webuser_osr            IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          VARCHAR2 DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT NOCOPY  VARCHAR2
                          , x_msg_count              OUT         NUMBER
                          , x_msg_data               OUT NOCOPY  VARCHAR2
                          )
   AS

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
      --  #param 11 p_record_type    This will have a value of AV for Avolent
      --  #param 12 p_access_code Access code to control privileges
      --  #param 13 p_resp_key        Not used
      --  #param 14 p_party_id        Party id of the relationship of contact
      --                              with account site
      --  #param 15 x_retcode         return success or failure


      l_new_user                   BOOLEAN := FALSE;

      l_org_id                     HZ_CUST_ACCT_SITES_ALL.ORG_ID%TYPE;
      l_org_name                   HR_ALL_ORGANIZATION_UNITS.NAME%TYPE;
      l_party_id                   HZ_PARTIES.party_id%TYPE := p_party_id;
      l_site_key                   XX_EXTERNAL_USERS.site_key%TYPE;

      l_new_resp_id                FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_new_appl_id                FND_RESPONSIBILITY.application_id%TYPE;
      l_new_resp_desc              FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      l_cur_resp_id                FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_cur_appl_id                FND_RESPONSIBILITY.application_id%TYPE;
      l_cur_resp_desc              FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      ln_fnd_user_id               FND_USER.user_id%TYPE;
      ln_apps_user_id              NUMBER;
      ln_resp_id                   NUMBER;
      ln_resp_appl_id              NUMBER;
      ln_security_group_id         NUMBER;
      ln_org_id                    NUMBER;

      le_party_id_null             EXCEPTION;
      le_update_fnd_failed         EXCEPTION;
      le_api_error                 EXCEPTION;


     l_external_users_stg_id       xx_external_users_stg.external_users_stg_id%TYPE;
     l_batch_id                    xx_external_users_stg.batch_id%TYPE;
     l_stg_userid                  xx_external_users_stg.userid%TYPE;
     l_password                    xx_external_users_stg.password%TYPE;
     l_ext_upd_timestamp           xx_external_users_stg.ext_upd_timestamp%TYPE;
     l_process_name                xx_external_users_stg.process_name%TYPE;
     l_creation_date               xx_external_users_stg.creation_date%TYPE;
     l_last_update_date            xx_external_users_stg.last_update_date%TYPE;
     l_last_updated_by             xx_external_users_stg.last_updated_by%TYPE;
     l_last_update_login           xx_external_users_stg.last_update_login%TYPE;
     l_record_flag                 xx_external_users_stg.record_flag%TYPE;
     l_rank                        NUMBER;
     l_userid                  xx_external_users.userid%TYPE;
     l_fnd_user_name           fnd_user.user_name%type;
     l_fnd_user_rec            XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
     l_cur_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;
     l_new_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;

      CURSOR  c_fnd_user (p_user_name VARCHAR2)
      IS
        SELECT rowid,
               user_id,
               user_name,
               description,
               customer_id
        FROM   fnd_user
        WHERE  user_name = p_user_name;

     CURSOR c_ext_users_stg (p_userid VARCHAR2, p_webuser_osr VARCHAR2)
     IS
       select  external_users_stg_id
               ,batch_id
               ,userid
               ,password
               ,ext_upd_timestamp
               ,process_name
               ,record_flag
        from   xx_external_users_stg
        WHERE  userid       = p_userid
        and    webuser_osr  = p_webuser_osr
        and    process_name = 'SaveiReceivables'
        ;

   BEGIN
      g_proc_name := 'save_ext_user';
      log_debug(g_proc_name, 'p_userid := ' || p_userid );
      --Check whether record exist in XX_EXTERNAL_USERS_STG for saveiReceivables records
      BEGIN

         OPEN  c_ext_users_stg (p_userid, p_webuser_osr);
         FETCH c_ext_users_stg INTO   l_external_users_stg_id
                                     ,l_batch_id
                                     ,l_userid
                                     ,l_password
                                     ,l_ext_upd_timestamp
                                     ,l_process_name
                                     ,l_record_flag
                                     ;
         IF c_ext_users_stg%NOTFOUND
         THEN
            log_debug(g_proc_name,'UserID ' || l_userid || ' does not exist in XX_EXTERNAL_USERS_STG' );
            l_record_flag := 'N';
         ELSE
            log_debug(g_proc_name,'UserID ' || l_userid || ' exists in XX_EXTERNAL_USERS_STG' );
            l_record_flag := 'U'; -- 'U' means existing record as 'Update'
         END IF;

         CLOSE c_ext_users_stg;

      EXCEPTION
        WHEN OTHERS THEN
          l_record_flag := 'N'; --'N'  means NEW record.
      END;

      --insert into the xx_external_users_stg table
      INSERT INTO xx_external_users_stg
                  (
                      external_users_stg_id
                    , batch_id
                    , userid
                    , password
                    , person_first_name
                    , person_middle_name
                    , person_last_name
                    , email
                    , ext_upd_timestamp
                    , status
                    , action_type
                    , orig_system
                    , acct_osr
                    , contact_osr
                    , acct_site_osr
                    , webuser_osr
                    , record_type
                    , access_code
                    , permission_flag
                    , process_name
                    , record_flag
                    , created_by
                    , creation_date
                    , last_update_date
                    , last_updated_by
                    , last_update_login
                  )
      VALUES
                  (
                      XX_EXTERNAL_USERS_STG_S.nextval
                    , fnd_profile.value_wnps('XXCDH_EXT_USER_SOA_BATCH_ID')
                    , p_userid
                    , p_password
                    , p_first_name
                    , p_middle_initial
                    , p_last_name
                    , p_email
                    , p_ext_upd_time
                    , p_status
                    , p_action_type
                    , p_orig_system
                    , p_cust_acct_osr
                    , p_contact_osr
                    , p_acct_site_osr
                    , p_webuser_osr
                    , p_record_type
                    , p_access_code
                    , p_permission_flag
                    , 'SaveiReceivables'
                    , l_record_flag
                    , FND_GLOBAL.User_Id
                    , sysdate
                    , sysdate
                    , FND_GLOBAL.User_Id
                    , FND_GLOBAL.Login_Id
                  );
      COMMIT;

      -- Check if the record is NEW or UPDATED
      IF l_record_flag = 'N' THEN
          -- New user record

          --When only password has been changed, SaveiReceivables will NOT be
          --instantiated.
          --When User is created, but password is updated within 120 seconds
          --(AOPS near real-time polling time), SaveiReceivables will have
          --old password as 'UpdateExtUserPwd' has new password. In this scenario,
          --we need to check if there is a  record for this user, with record_flag
          --as 'E', and take only the password from that record.

          --Selecting highest record from XX_EXTERNAL_USERS_STG with 'E' records ('E' records would have come from MQ)
          BEGIN
            select  external_users_stg_id
                   ,batch_id
                   ,userid
                   ,password
                   ,ext_upd_timestamp
                   ,process_name
                   ,record_flag
                   ,rank_1
            into    l_external_users_stg_id
                   ,l_batch_id
                   ,l_userid
                   ,l_password
                   ,l_ext_upd_timestamp
                   ,l_process_name
                   ,l_record_flag
                   ,l_rank
            from (SELECT   x.external_users_stg_id
                          ,x.batch_id
                          ,x.userid
                          ,x.password
                          ,x.ext_upd_timestamp
                          ,x.process_name
                          ,x.record_flag
                          ,RANK() OVER
                                  (ORDER BY nvl(x.ext_upd_timestamp,sysdate-365) desc, x.last_update_date desc, x.EXTERNAL_USERS_STG_ID desc) as rank_1
                    FROM  xx_external_users_stg x
                   WHERE  1 = 1
                     and  x.userid = p_userid
                     --and  record_flag = 'E'  -- commented - we need to get latest password, when user updates multiple times, the record_flag will be U
                     --and  process_name='UpdateExtUserPwd' --commented as it should pick records of SaveiReceivables NAIT-103309
                  )
            where rank_1=1
            ;

            if (p_ext_upd_time < l_ext_upd_timestamp) then

              l_new_extuser_rec.userid                     := p_userid;
              l_new_extuser_rec.password                   := l_password; -- assign the latest password from 'UpdateExtUserPwd' that was errored earlier
              l_new_extuser_rec.person_first_name          := p_first_name;
              l_new_extuser_rec.person_middle_name         := p_middle_initial;
              l_new_extuser_rec.person_last_name           := p_last_name;
              l_new_extuser_rec.email                      := p_email;
              l_new_extuser_rec.status                     := p_status;
              l_new_extuser_rec.orig_system                := p_orig_system;
              l_new_extuser_rec.contact_osr                := p_contact_osr;
              l_new_extuser_rec.webuser_osr                := p_webuser_osr;
              l_new_extuser_rec.access_code                := p_access_code;
              l_new_extuser_rec.permission_flag            := p_permission_flag;
              l_new_extuser_rec.ext_upd_timestamp          := l_ext_upd_timestamp;
            else
              l_new_extuser_rec.userid                     := p_userid;
              l_new_extuser_rec.password                   := p_password;
              l_new_extuser_rec.person_first_name          := p_first_name;
              l_new_extuser_rec.person_middle_name         := p_middle_initial;
              l_new_extuser_rec.person_last_name           := p_last_name;
              l_new_extuser_rec.email                      := p_email;
              l_new_extuser_rec.status                     := p_status;
              l_new_extuser_rec.orig_system                := p_orig_system;
              l_new_extuser_rec.contact_osr                := p_contact_osr;
              l_new_extuser_rec.webuser_osr                := p_webuser_osr;
              l_new_extuser_rec.access_code                := p_access_code;
              l_new_extuser_rec.permission_flag            := p_permission_flag;
              l_new_extuser_rec.ext_upd_timestamp          := p_ext_upd_time;
            end if;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --No changes to password field for this saveiReceivables record
              l_new_extuser_rec.userid                     := p_userid;
              l_new_extuser_rec.password                   := p_password;
              l_new_extuser_rec.person_first_name          := p_first_name;
              l_new_extuser_rec.person_middle_name         := p_middle_initial;
              l_new_extuser_rec.person_last_name           := p_last_name;
              l_new_extuser_rec.email                      := p_email;
              l_new_extuser_rec.status                     := p_status;
              l_new_extuser_rec.orig_system                := p_orig_system;
              l_new_extuser_rec.contact_osr                := p_contact_osr;
              l_new_extuser_rec.webuser_osr                := p_webuser_osr;
              l_new_extuser_rec.access_code                := p_access_code;
              l_new_extuser_rec.permission_flag            := p_permission_flag;
              l_new_extuser_rec.ext_upd_timestamp          := p_ext_upd_time;
          END;

      ELSE
        -- Updated user record
        --Selecting highest record from UpdateExtUserPwd in XX_EXTERNAL_USERS_STG without looking for any record_flag for getting the latest password
        BEGIN
              select  external_users_stg_id
                     ,batch_id
                     ,userid
                     ,password
                     ,ext_upd_timestamp
                     ,process_name
                     ,record_flag
                     ,rank_1
              into    l_external_users_stg_id
                     ,l_batch_id
                     ,l_userid
                     ,l_password
                     ,l_ext_upd_timestamp
                     ,l_process_name
                     ,l_record_flag
                     ,l_rank
              from (SELECT   x.external_users_stg_id
                            ,x.batch_id
                            ,x.userid
                            ,x.password
                            ,x.ext_upd_timestamp
                            ,x.process_name
                            ,x.record_flag
                            ,RANK() OVER
                                    (ORDER BY nvl(x.ext_upd_timestamp,sysdate-365) desc, x.last_update_date desc, x.EXTERNAL_USERS_STG_ID desc) as rank_1
                      FROM  xx_external_users_stg x
                     WHERE  1 = 1
                       and  x.userid = p_userid
                      -- and  process_name='UpdateExtUserPwd'--commented as it should pick records of SaveiReceivables NAIT-103309
                    )
             where rank_1=1
            ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --Since this is an update scenario, assuming that the userid must be there in the staging table
            null;
        END;

        l_new_extuser_rec.userid                     := p_userid;
        l_new_extuser_rec.password                   := l_password;
        l_new_extuser_rec.person_first_name          := p_first_name;
        l_new_extuser_rec.person_middle_name         := p_middle_initial;
        l_new_extuser_rec.person_last_name           := p_last_name;
        l_new_extuser_rec.email                      := p_email;
        l_new_extuser_rec.status                     := p_status;
        l_new_extuser_rec.orig_system                := p_orig_system;
        l_new_extuser_rec.contact_osr                := p_contact_osr;
        l_new_extuser_rec.webuser_osr                := p_webuser_osr;
        l_new_extuser_rec.access_code                := p_access_code;
        l_new_extuser_rec.permission_flag            := p_permission_flag;
        l_new_extuser_rec.ext_upd_timestamp          := l_ext_upd_timestamp;

      END IF;

      IF NVL(fnd_global.user_name(), 'NO_USER') NOT IN ('ODCDH', 'ODCRMBPEL')
      THEN
          log_debug(g_proc_name,'Apps Context is not Set, Setting Apps Context using ODCDH and XX_US_CNV_CDH_CONVERSION ');
          XX_EXTERNAL_USERS_PVT.set_apps_context ( p_system_name               => p_orig_system
                                                 , p_user_name                 => 'ODCRMBPEL'
                                                 , p_responsibility_key        => 'OD_US_CDH_CUSTOM_RESP'
                                                 , p_organization_name         => NULL
                                                 , x_apps_user_id              => ln_apps_user_id
                                                 , x_resp_id                   => ln_resp_id
                                                 , x_resp_appl_id              => ln_resp_appl_id
                                                 , x_security_group_id         => ln_security_group_id
                                                 , x_org_id                    => ln_org_id
                                                 , x_return_status             => x_return_status
                                                 , x_msg_count                 => x_msg_count
                                                 , x_msg_data                  => x_msg_data
                                                 );

         log_debug(g_proc_name,'After Setting Apps Context ' || x_return_status);
         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- NVL(fnd_global.user_name(), 'NO_USER') <> 'ODCDH'

      FND_MSG_PUB.initialize;
      x_msg_count         := 0;

      log_debug(g_proc_name,'***** In save_ext_user procedure ***** ');
      log_debug(g_proc_name, 'p_userid                     := ' || p_userid                 );
      log_debug(g_proc_name, 'p_password                   := ' || p_password               );
      log_debug(g_proc_name, 'p_first_name                 := ' || p_first_name             );
      log_debug(g_proc_name, 'p_middle_initial             := ' || p_middle_initial         );
      log_debug(g_proc_name, 'p_last_name                  := ' || p_last_name              );
      log_debug(g_proc_name, 'p_email                      := ' || p_email                  );
      log_debug(g_proc_name, 'p_ext_upd_time               := ' || p_ext_upd_time           );
      log_debug(g_proc_name, 'p_status                     := ' || p_status                 );
      log_debug(g_proc_name, 'p_action_type                := ' || p_action_type            );
      log_debug(g_proc_name, 'p_orig_system                := ' || p_orig_system            );
      log_debug(g_proc_name, 'p_cust_acct_osr              := ' || p_cust_acct_osr          );
      log_debug(g_proc_name, 'p_contact_osr                := ' || p_contact_osr            );
      log_debug(g_proc_name, 'p_acct_site_osr              := ' || p_acct_site_osr          );
      log_debug(g_proc_name, 'p_webuser_osr                := ' || p_webuser_osr            );
      log_debug(g_proc_name, 'p_record_type                := ' || p_record_type            );
      log_debug(g_proc_name, 'p_access_code                := ' || p_access_code            );
      log_debug(g_proc_name, 'p_permission_flag            := ' || p_permission_flag        );
      log_debug(g_proc_name, 'p_cust_account_id            := ' || p_cust_account_id        );
      log_debug(g_proc_name, 'p_ship_to_acct_site_id       := ' || p_ship_to_acct_site_id   );
      log_debug(g_proc_name, 'p_bill_to_acct_site_id       := ' || p_bill_to_acct_site_id   );

      -- -------------------------------------------------------------------------
      -- Get the Site Prefix for the User
      -- -------------------------------------------------------------------------
      XX_EXTERNAL_USERS_PVT.get_user_prefix ( p_system_name     => p_orig_system
                                            , x_site_key        => l_site_key
                                            , x_return_status   => x_return_status
                                            , x_msg_count       => x_msg_count
                                            , x_msg_data        => x_msg_data
                                            );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_003_MISSING_SETUP');
         fnd_message.set_token ('SETUP_NAME', 'XX_ECOM_SITE_KEY');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         RAISE le_api_error;
      END IF;

      l_fnd_user_name := l_site_key || p_webuser_osr;
      log_debug(g_proc_name, 'l_fnd_user_name       := ' || l_fnd_user_name   );
      -- -------------------------------------------------------------------------
      -- Get the User Informarion from FND_USER Table
      -- -------------------------------------------------------------------------
      BEGIN -- Get the User Informarion from FND_USER Table
         log_debug(g_proc_name, 'Check if User exists in FND_USER ' || l_fnd_user_name);

         OPEN  c_fnd_user(l_fnd_user_name);
         FETCH c_fnd_user INTO  l_fnd_user_rec;
         IF c_fnd_user%NOTFOUND
         THEN
            log_debug(g_proc_name,'User ' || l_fnd_user_name || ' does not exist in FND_USER' );
            l_new_user := TRUE;
         ELSE
            log_debug(g_proc_name,'User ' || l_fnd_user_name || ' exists in FND_USER' );
            l_new_user := FALSE;
         END IF; -- c_fnd_user%NOTFOUND

         CLOSE c_fnd_user;
      EXCEPTION
         WHEN OTHERS THEN
              IF c_fnd_user%ISOPEN
              THEN
                  CLOSE c_fnd_user;
              END IF; -- c_fnd_user%ISOPEN
              RAISE;
      END; -- Get the User Informarion from FND_USER Table

      -- -------------------------------------------------------------------------
      -- Get the Party ID for the Contact
      -- -------------------------------------------------------------------------
      l_party_id := p_party_id;
      IF l_party_id IS NULL
      THEN
         -- ----------------------------------------------------------------------
         -- Get the Party Id, Party relationShip ID for the Contact
         -- This function assumes that the Org Contact has been created earlier
         -- If Org Contact Does not exist then, return an error.
         -- ----------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => p_orig_system
                                              , p_cust_acct_cnt_osr    => p_contact_osr
                                              , x_party_id             => l_party_id
                                              , x_return_status        => x_return_status
                                              , x_msg_count            => x_msg_count
                                              , x_msg_data             => x_msg_data
                                              );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- l_party_id IS NULL

      l_new_extuser_rec.fnd_user_name              := l_fnd_user_name;
      l_new_extuser_rec.site_key                   := l_site_key;
      l_new_extuser_rec.party_id                   := l_party_id;

      XX_EXTERNAL_USERS_PVT.save_external_user ( p_site_key                   => l_site_key
                                               , p_userid                     => p_userid
                                               , p_action_type                => p_action_type
                                               , p_new_extuser_rec            => l_new_extuser_rec
                                               , x_cur_extuser_rec            => l_cur_extuser_rec
                                               , x_return_status              => x_return_status
                                               , x_msg_count                  => x_msg_count
                                               , x_msg_data                   => x_msg_data
                                               );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         RAISE le_api_error;
      ELSE
         --If the XX_EXTERNAL_USERS_PVT.save_external_user API call is successful
         --Update the xx_external_users_stg record with status as S

         update xx_external_users_stg
         set    record_flag = 'S'
         where  external_users_stg_id = l_external_users_stg_id
         ;

         COMMIT;
      END IF;
      /*
      -- ----------------------------------------------------------------------------
      -- if AV record was passed and user exists in FND_USER table,
      -- update responsibility for the user
      -- If the user does not exist in FND_USER, the responsibility will be assigned when
      -- the oracle.apps.fnd.user.insert BES event is raised
      -- ----------------------------------------------------------------------------
      IF p_record_type = 'AV' AND NOT l_new_user
      THEN
          log_debug(g_proc_name,'Update FND_USER Record');
          XX_EXTERNAL_USERS_PVT.update_fnd_user ( p_cur_extuser_rec            => l_cur_extuser_rec
                                                , p_new_extuser_rec            => l_new_extuser_rec
                                                , p_fnd_user_rec               => l_fnd_user_rec
                                                , x_return_status              => x_return_status
                                                , x_msg_count                  => x_msg_count
                                                , x_msg_data                   => x_msg_data
                                                );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
            RAISE le_api_error;
         END IF;
      END IF; -- p_record_type = 'AV' AND NOT l_new_user

      x_return_status := FND_API.G_RET_STS_SUCCESS;
	  */
   EXCEPTION
     WHEN le_api_error THEN
         log_error(g_proc_name, x_msg_data);
         x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || g_proc_name);
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_error(g_proc_name, x_msg_data);
         --raise;
   END save_ext_user;

   -- ===========================================================================
   -- Name             : GET_FND_CREATE_EVENT
   -- Description      : This function is trigerred from a business
   --                    event when a new BSD web user is synchronized from OID into
   --                    fnd_user table. This function calls the procedures to
   --                    grant the new user iReceivables responsibilities and assign
   --                    the party id
   --
   -- Parameters :      p_subscription_guid
   --                   p_event
   --
   -- ===========================================================================

  FUNCTION get_fnd_create_event ( p_subscription_guid IN            RAW
                                , p_event             IN OUT NOCOPY WF_EVENT_T
                                )
  RETURN VARCHAR2
      --  get_fnd_create_event calls update_fnd_user to grant the new user
      -- iReceivables responsibilities and assign the party id
      --
      --  #param 1  p_subscription_guid  GUID of the subscription to the
      --                                 business event
      --  #param 2  p_event              Event Data
      -- oracle.apps.fnd.user.insert
      -- oracle.apps.fnd.identity.add

  AS
      ln_count             PLS_INTEGER;
      ln_org_id            NUMBER;
      ln_user_id           NUMBER;
      ln_resp_id           NUMBER;
      ln_resp_appl_id      NUMBER;
      ln_security_group_id NUMBER;
      lc_user_name         FND_USER.USER_NAME%TYPE;

      ln_apps_user_id              NUMBER;

      l_param_name         VARCHAR2(2000);
      l_param_value        VARCHAR2(2000);
      l_event_name         VARCHAR2(2000);
      l_event_key          VARCHAR2(2000);
      l_parameter_list     WF_PARAMETER_LIST_T := wf_parameter_list_t();

      l_return_status      VARCHAR2(30);
      l_msg_count          NUMBER;
      l_msg_data           VARCHAR2(2000);


      le_update_fnd_user_failed  EXCEPTION;
      le_oid_pwd_update_failed   EXCEPTION;
  BEGIN

      SAVEPOINT get_fnd_create_event_sv;

      g_proc_name := 'get_fnd_create_event';

      IF NVL(fnd_global.user_name(), 'NO_USER') NOT IN ('ODCDH', 'ODCRMBPEL')
      THEN
         log_debug(g_proc_name, 'Apps Context is not Set, Setting Apps Context using ODCDH and XX_US_CNV_CDH_CONVERSION ');
         XX_EXTERNAL_USERS_PVT.set_apps_context (  p_system_name               => NULL
                                                 , p_user_name                 => 'ODCDH'
                                                 , p_responsibility_key        => 'XX_US_CNV_CDH_CONVERSION'
                                                 , p_organization_name         => NULL
                                                 , x_apps_user_id              => ln_apps_user_id
                                                 , x_resp_id                   => ln_resp_id
                                                 , x_resp_appl_id              => ln_resp_appl_id
                                                 , x_security_group_id         => ln_security_group_id
                                                 , x_org_id                    => ln_org_id
                                                 , x_return_status             => l_return_status
                                                 , x_msg_count                 => l_msg_count
                                                 , x_msg_data                  => l_msg_data
                                                 );

         log_debug(g_proc_name,'After Setting Apps Context ' || l_return_status );
         IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_update_fnd_user_failed;
         END IF; -- l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- NVL(fnd_global.user_name(), 'NO_USER') <> 'ODCDH'

      FND_MSG_PUB.initialize;
      l_msg_count         := 0;

      log_debug(g_proc_name,'***** In get_fnd_create_event procedure ***** ' );

      -- --------------------------------------------------------------------
      -- Obtaining the event parameter values
      -- --------------------------------------------------------------------
      l_event_name          := p_event.geteventname();
      l_event_key           := p_event.geteventkey();
      l_parameter_list      := p_event.getparameterlist;
      ln_org_id             := p_event.GetValueForParameter('ORG_ID');
      ln_user_id            := p_event.GetValueForParameter('USER_ID');
      ln_resp_id            := p_event.GetValueForParameter('RESP_ID');
      ln_resp_appl_id       := p_event.GetValueForParameter('RESP_APPL_ID');
      ln_security_group_id  := p_event.GetValueForParameter('SECURITY_GROUP_ID');

      log_debug(g_proc_name, 'EVENTNAME            : ' || l_event_name );
      log_debug(g_proc_name, 'EVENTKEY             : ' || l_event_key );
      log_debug(g_proc_name, 'ln_user_id           : ' || ln_user_id );
      log_debug(g_proc_name, 'ln_org_id            : ' || ln_org_id );
      log_debug(g_proc_name, 'ln_resp_id           : ' || ln_resp_id );
      log_debug(g_proc_name, 'ln_resp_appl_id      : ' || ln_resp_appl_id );
      log_debug(g_proc_name, 'ln_security_group_id : ' || ln_security_group_id );

         IF l_parameter_list.count > 0
         THEN
            log_debug(g_proc_name, 'Parameter Count: '||l_parameter_list.count );
            FOR i IN l_parameter_list.first..l_parameter_list.last
            LOOP
               l_param_name  := l_parameter_list(i).getname;
               l_param_value := l_parameter_list(i).getvalue;
               log_debug(g_proc_name, 'Parameter (' || l_param_name || ') : ' ||l_param_value );
            END LOOP;
         END IF; -- l_parameter_list.count > 0

      IF l_event_name = 'oracle.apps.fnd.identity.add'
      THEN
         lc_user_name := l_event_key;

         -- New code to insert fnd_user preference Begins

         IF lc_user_name IS NOT NULL THEN
         BEGIN
            SELECT /*+ parallel(a,4)*/ fnd_user_name INTO lc_user_name
            FROM xx_external_users a
            WHERE fnd_user_name = lc_user_name
            AND ROWNUM = 1;

            FND_PREFERENCE.put(lc_user_name,'WF','MAILTYPE','MAILHTM2');

         EXCEPTION WHEN NO_DATA_FOUND THEN
            log_error(g_proc_name,'NO DATA FOUND in  1st SELECT for lc_user_name : '|| sqlerrm );
         END;
        END IF;

         -- New code to insert fnd_user preference Ends

         XX_EXTERNAL_USERS_PVT.update_new_fnd_user ( p_fnd_user_name       => lc_user_name
                                                   , x_return_status       => l_return_status
                                                   , x_msg_count           => l_msg_count
                                                   , x_msg_data            => l_msg_data
                                                   );
         IF l_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
            raise le_update_fnd_user_failed;
         END IF;
      ELSIF l_event_name = 'oracle.apps.fnd.user.insert'
      THEN
         ln_user_id := l_event_key;

        -- New code to insert fnd_user preference Begins

        IF ln_user_id IS NOT NULL THEN
         BEGIN
            SELECT f.user_name INTO lc_user_name
            FROM fnd_user f, xx_external_users x
            WHERE f.user_id = ln_user_id
            AND x.fnd_user_name=f.user_name
            AND ROWNUM = 1 ;

            FND_PREFERENCE.put(lc_user_name,'WF','MAILTYPE','MAILHTM2');

         EXCEPTION WHEN NO_DATA_FOUND THEN
            log_error(g_proc_name,'NO DATA FOUND in 2nd SELECT for lc_user_name : '|| sqlerrm );
         END;
        END IF;

         -- New code to insert fnd_user preference Ends

         XX_EXTERNAL_USERS_PVT.update_new_fnd_user ( p_fnd_user_id         => ln_user_id
                                                   , x_return_status       => l_return_status
                                                   , x_msg_count           => l_msg_count
                                                   , x_msg_data            => l_msg_data
                                                   );
         IF l_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
            raise le_update_fnd_user_failed;
         END IF;
      END IF; -- l_event_name = 'oracle.apps.fnd.identity.add'

      COMMIT;
      RETURN 'SUCCESS';

   EXCEPTION
      WHEN le_update_fnd_user_failed THEN
         ROLLBACK TO SAVEPOINT get_fnd_create_event_sv;
         log_error(g_proc_name, 'XX_CDH_0005_UPDATE_FND_USER_FAILED;'|| l_msg_data || ' In Procedure:XX_EXTERNAL_USERS_BO_PUB.update_fnd_user: Failed for username :'|| lc_user_name);
         -- RETURN 'ERROR';
         RETURN 'SUCCESS';

      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT get_fnd_create_event_sv;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_fnd_create_event');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         l_msg_count := l_msg_count + 1;
         l_msg_data := fnd_message.get();

         log_error(g_proc_name, ' Event insert failed. ' || l_msg_data);
         -- RETURN 'ERROR';
         RETURN 'SUCCESS';
  END  get_fnd_create_event;

   -- ===========================================================================
   -- Name             : Update_Ext_User_Password
   -- Description      : This procedure updates the bsd web user
   --                    password in xx_external_users table.
   --                    This procedure is called from UpdateExtUserPwd
   --                    BPEL process
   --
   -- Parameters       : p_userid  BSD web user userid
   --                    p_pwd     BSD web user password
   --
   -- ===========================================================================
  PROCEDURE update_ext_user_password ( p_userid          IN         VARCHAR2
                                     , p_password        IN         VARCHAR2
                                     , p_ext_upd_time    IN         TIMESTAMP
                                     , x_return_status   OUT NOCOPY VARCHAR2
                                     , x_msg_count       OUT        NUMBER
                                     , x_msg_data        OUT NOCOPY VARCHAR2
                                     )
   IS

     l_external_users_stg_id       xx_external_users_stg.external_users_stg_id%TYPE;
     l_batch_id                    xx_external_users_stg.batch_id%TYPE;
     l_userid                      xx_external_users_stg.userid%TYPE;
     l_password                    xx_external_users_stg.password%TYPE;
     l_ext_upd_timestamp           xx_external_users_stg.ext_upd_timestamp%TYPE;
     l_process_name                xx_external_users_stg.process_name%TYPE;
     l_creation_date               xx_external_users_stg.creation_date%TYPE;
     l_last_update_date            xx_external_users_stg.last_update_date%TYPE;
     l_last_updated_by             xx_external_users_stg.last_updated_by%TYPE;
     l_last_update_login           xx_external_users_stg.last_update_login%TYPE;
     l_record_flag                 xx_external_users_stg.record_flag%TYPE;
     l_count                       NUMBER;
     le_password_update_error      EXCEPTION;

     l_temp_external_users_stg_id  xx_external_users_stg.external_users_stg_id%TYPE := null;

   BEGIN

      g_proc_name := 'update_ext_user_password';
      log_debug(g_proc_name,'***** In update_ext_user_password procedure ***** ' );
      x_msg_count := 0;

       BEGIN
         select count(1)
         into   l_count
         from   xx_external_users_stg
         where  userid=p_userid
         ;
         if l_count = 0 then
           l_record_flag := 'E'; -- 'E' means password was changed immediately, and update password came before create user record
         else
           l_record_flag := 'U'; -- 'U' means password is coming as 'Update'
         end if;
      EXCEPTION
        WHEN OTHERS THEN
          l_record_flag := 'E'; --'E'  means Errored. Another polling process within EBS has to re-process all these errored files
      END;

       BEGIN
         l_temp_external_users_stg_id := XX_EXTERNAL_USERS_STG_S.nextval;
         INSERT INTO xx_external_users_stg
                     (
                         external_users_stg_id
                       , batch_id
                       , userid
                       , password
                       , ext_upd_timestamp
                       , process_name
                       , record_flag
                       , creation_date
                       , last_update_date
                       , last_updated_by
                       , last_update_login
                     )
         VALUES
                     (
                         l_temp_external_users_stg_id
                       , fnd_profile.value_wnps('XXCDH_EXT_USER_SOA_BATCH_ID')
                       , p_userid
                       , p_password
                       , p_ext_upd_time
                       , 'UpdateExtUserPwd'
                       , l_record_flag
                       , sysdate
                       , sysdate
                       , FND_GLOBAL.User_Id
                       , FND_GLOBAL.Login_Id
                     );

         COMMIT;

         l_record_flag := 'U'; -- 'U' means password is coming as 'Update'
      EXCEPTION
        WHEN OTHERS THEN
          l_record_flag := 'E'; --'E'  means Errored. Another polling process within EBS has to re-process all these errored files

      END;



      IF (p_password IS NULL) OR ( l_record_flag = 'E')
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCOMN', 'XX_COM_001_PWD_VALIDATION_ERR');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_error(g_proc_name, x_msg_data );
         log_error(g_proc_name, 'BSD UserID: ' || p_userid ||' does not exist');

         update xx_external_users_stg
         set    record_flag = 'E'
         where  userid = p_userid;

         COMMIT;

         RAISE le_password_update_error;
      END IF; -- p_password IS NULL

      BEGIN
        UPDATE xx_external_users
        SET    password = p_password
             , last_update_date  = SYSDATE
             , oid_update_date   = SYSDATE
             , ext_upd_timestamp = p_ext_upd_time
             , last_updated_by   = fnd_global.user_id()
             , last_update_login = fnd_global.login_id()
        WHERE userid = p_userid
        and   p_ext_upd_time > nvl(ext_upd_timestamp,'01-JAN-0001 01:01:01.000000000');

        IF SQL%ROWCOUNT = 0
        THEN
          log_error(g_proc_name,'UserID: ' || p_userid ||', Password: ' || p_password ||', ext_upd_timestamp: ' || p_ext_upd_time
                                           ||', is less than existing ext_upd_timestamp: ' || l_ext_upd_timestamp
                                           ||'. NOT UPDATING..');
        ELSE
          log_error(g_proc_name,'Updating UserID: ' || p_userid ||', Password: ' || p_password ||', ext_upd_timestamp: ' || l_ext_upd_timestamp || ' successfully due to higher timestamp recieved.');
          COMMIT;
        END IF; -- SQL%ROWCOUNT = 0
        x_return_status     := FND_API.G_RET_STS_SUCCESS;
        x_msg_data          := NULL;
      EXCEPTION
        WHEN OTHERS THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
           fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
           fnd_message.set_token('ROUTINE', g_pkg_name || '.update_ext_user_password');
           fnd_message.set_token('ERRNO', SQLCODE);
           fnd_message.set_token('REASON', SQLERRM);
           x_msg_count := x_msg_count + 1;
           x_msg_data := fnd_message.get();
           log_error(g_proc_name, x_msg_data);
      END;

   EXCEPTION
     WHEN le_password_update_error THEN
         log_error(g_proc_name, x_msg_data);

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.update_ext_user_password');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_error(g_proc_name, x_msg_data);
   END update_ext_user_password;
   
    --============================================================================
   -- Name             : UPDATE_ACCESS_CODE
   -- Description      : This procedure will update the access of fnd user.
   --
   -- Parameters :  p_userid       
   --               p_orig_system  
   --               p_contact_osr  
   --               p_record_type  
   --               p_access_code  
   --               p_party_id         
   --============================================================================
 PROCEDURE update_access_code( 
                            p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          VARCHAR2 DEFAULT NULL
                          , p_party_id               IN          NUMBER   DEFAULT NULL
						  , p_webuser_osr            IN          VARCHAR2 DEFAULT NULL
                          , x_return_status          OUT NOCOPY  VARCHAR2
                          , x_msg_count              OUT         NUMBER
                          , x_msg_data               OUT NOCOPY  VARCHAR2
                          )
   IS
      --  #param 1  p_userid          BSD web user id from AOPS
	  --  #param 2  p_orig_system     Unique OSR
      --  #param 3  p_contact_osr     Unique ID of contact from AOPS
      --  #param 4  p_record_type     This will have a value of AV for Avolent
      --  #param 5  p_access_code 	  Access code to control privileges
      --  #param 6  p_party_id        Party id of the relationship of contact
      --                              with account site
      --  #param  x_retcode         return success or failure

     l_new_user                   BOOLEAN := FALSE;
     l_party_id                   HZ_PARTIES.party_id%TYPE := p_party_id;
     ln_fnd_user_id               FND_USER.user_id%TYPE;
     ln_apps_user_id              NUMBER;
     le_party_id_null             EXCEPTION;
     le_update_fnd_failed         EXCEPTION;
     le_api_error                 EXCEPTION;
	 l_site_key				   VARCHAR2(100);
   
     l_fnd_user_name           fnd_user.user_name%type;
     l_fnd_user_rec            XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
     l_cur_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;
     l_new_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;
     
      CURSOR  c_fnd_user (p_user_name VARCHAR2)
      IS
        SELECT rowid,
               user_id,
               user_name,
               description,
               customer_id
        FROM   fnd_user
        WHERE  user_name = p_user_name;
        
   BEGIN
      g_proc_name := 'save_ext_user';
    
      FND_MSG_PUB.initialize;
      x_msg_count         := 0;
 	   
      -- -------------------------------------------------------------------------
      -- Get the Site Prefix for the User
      -- -------------------------------------------------------------------------
      XX_EXTERNAL_USERS_PVT.get_user_prefix ( p_system_name     => p_orig_system
                                            , x_site_key        => l_site_key
                                            , x_return_status   => x_return_status
                                            , x_msg_count       => x_msg_count
                                            , x_msg_data        => x_msg_data
                                            );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_003_MISSING_SETUP');
         fnd_message.set_token ('SETUP_NAME', 'XX_ECOM_SITE_KEY');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         RAISE le_api_error;
      END IF;
	  
      l_fnd_user_name := l_site_key || p_webuser_osr;
	  
      log_debug(g_proc_name, 'l_fnd_user_name       := ' || l_fnd_user_name   );
      -- -------------------------------------------------------------------------
      -- Get the User Informarion from FND_USER Table
      -- -------------------------------------------------------------------------
      BEGIN -- Get the User Informarion from FND_USER Table
         log_debug(g_proc_name, 'Check if User exists in FND_USER ' || l_fnd_user_name);

         OPEN  c_fnd_user(l_fnd_user_name);
         FETCH c_fnd_user INTO  l_fnd_user_rec;
         IF c_fnd_user%NOTFOUND
         THEN
            log_debug(g_proc_name,'User ' || l_fnd_user_name || ' does not exist in FND_USER' );
            l_new_user := TRUE;
         ELSE
            log_debug(g_proc_name,'User ' || l_fnd_user_name || ' exists in FND_USER' );
            l_new_user := FALSE;
         END IF; -- c_fnd_user%NOTFOUND

         CLOSE c_fnd_user;
      EXCEPTION
         WHEN OTHERS THEN
              IF c_fnd_user%ISOPEN
              THEN
                  CLOSE c_fnd_user;
              END IF; -- c_fnd_user%ISOPEN
              RAISE;
      END; -- Get the User Informarion from FND_USER Table

      -- -------------------------------------------------------------------------
      -- Get the Party ID for the Contact
      -- -------------------------------------------------------------------------
      l_party_id := p_party_id;
      IF l_party_id IS NULL
      THEN
         -- ----------------------------------------------------------------------
         -- Get the Party Id, Party relationShip ID for the Contact
         -- This function assumes that the Org Contact has been created earlier
         -- If Org Contact Does not exist then, return an error.
         -- ----------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => p_orig_system
                                              , p_cust_acct_cnt_osr    => p_contact_osr
                                              , x_party_id             => l_party_id
                                              , x_return_status        => x_return_status
                                              , x_msg_count            => x_msg_count
                                              , x_msg_data             => x_msg_data
                                              );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- l_party_id IS NULL
           
      l_new_extuser_rec.orig_system                := p_orig_system;
      l_new_extuser_rec.contact_osr                := p_contact_osr;
      l_new_extuser_rec.access_code                := p_access_code;
	  l_new_extuser_rec.party_id                   := l_party_id;
      
      log_debug(g_proc_name,'***** In update_access_code procedure ***** ');
      log_debug(g_proc_name, 'p_orig_system     := ' || p_orig_system );
	  log_debug(g_proc_name, 'p_contact_osr     := ' || p_contact_osr );
      log_debug(g_proc_name, 'p_record_type     := ' || p_record_type );
      log_debug(g_proc_name, 'p_access_code     := ' || p_access_code );

      -- ----------------------------------------------------------------------------
      -- if AV record was passed and user exists in FND_USER table,
      -- update responsibility for the user
      -- If the user does not exist in FND_USER, the responsibility will be assigned when
      -- the oracle.apps.fnd.user.insert BES event is raised
      -- ----------------------------------------------------------------------------
      IF p_record_type = 'AV' AND NOT l_new_user
      THEN
          log_debug(g_proc_name,'Update FND_USER Record');
          XX_EXTERNAL_USERS_PVT.update_fnd_user ( p_cur_extuser_rec            => l_cur_extuser_rec
                                                , p_new_extuser_rec            => l_new_extuser_rec
                                                , p_fnd_user_rec               => l_fnd_user_rec
                                                , x_return_status              => x_return_status
                                                , x_msg_count                  => x_msg_count
                                                , x_msg_data                   => x_msg_data
                                                );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
            RAISE le_api_error;
         END IF;
      END IF; -- p_record_type = 'AV' AND NOT l_new_user

      x_return_status := FND_API.G_RET_STS_SUCCESS;
   EXCEPTION
     WHEN le_api_error THEN
         log_error(g_proc_name, x_msg_data);
         x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || g_proc_name);
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_error(g_proc_name, x_msg_data);
         --raise;
   END update_access_code;

END XX_EXTERNAL_USERS_BO_PUB;