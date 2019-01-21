CREATE OR REPLACE PACKAGE BODY XX_EXTERNAL_USERS_PVT
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PVT                                                                |
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
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.      			 	                    |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.          		        |
-- |          31-Dec-2007 Yusuf Ali          Incorporated granular API for creating contact at account  |
-- |					                           site level and creating role for web user.                 |
-- |          02-Jan-2008 Yusuf Ali	         Removed call to create_role_resp procedure from            |
-- |					                           save_ext_user procedure.                                   |
-- |          07-Jan-2008 Yusuf Ali	         Created cursor to retrieve party id and cust account role  |
-- |			              Kathirvel Perumal  id from cust account roles table in create_role_resp       |
-- |						                        procedure and create equi-join query to get org id from    |
-- |						                        cust acct sites all table in save_ext_usr procedure.	     |
-- |	        07-Jan-2008 Yusuf Ali          Created cursor for fetching responsibility id and created  |
-- |                                         log_debug procedure to messages.                           |
-- |          08-Jan-2008 Narayan Bh.	      Modified cursors to accept ln_acct_role_id parameter for   |
-- |                      Yusuf Ali	         l_get_responsibility_id_cur, l_get_party_id_cur to accept  |
-- |                      Alok Sahay         OSR, and both cursors to select object version to pass     |
-- |                                         into appropriate granular API call, changed query in       |
-- |                                         save_ext_user to obtain org id for instance where          |
-- |                                         cust_acct_site_id IS NOT NULL.				                 |
-- |	        08-Jan-2008 Narayan Bh	      Created new query in create_role_resp to take              |
-- |					                           ln_bill_to_site_use_id to get cust_acct_site_id from 	     |
-- |  					                        hz_cust_site_uses_all.					                       |
-- |          09-Jan-2008 Alok Sahay 	      Removed permission flag variable (not being used) for 	  |
-- | 					                           condition where permission flag is S/M in create role resp |
-- |					                           procedure							                             |
-- |          09-Jan-2008 Yusuf Ali          Created/moved get_site_use_id to beginning of 		        |
-- | 			              Alok Sahay	      create_role_resp procedure.                                |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant Variables and Code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |1.1       24-Sep_2015 Manikant Kasu      Added procedure to raise business event to check and update|
-- |                                         subscription of the user                                   |
-- +====================================================================================================+
*/

  g_pkg_name       CONSTANT VARCHAR2(30) := 'XX_EXTERNAL_USERS_PVT';
  g_module         CONSTANT VARCHAR2(30) := 'CRM';

  --Procedure for logging debug log
PROCEDURE log_debug ( p_debug_msg          IN  VARCHAR2 )
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
      ,p_attribute16             => 'save_external_user'
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


PROCEDURE log_error     ( p_debug_msg      IN  VARCHAR2 )
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
        ,p_attribute16             => 'save_external_user'
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

  PROCEDURE log_oid (  p_program_type   IN  VARCHAR2
                      ,p_error_message_severity  IN  VARCHAR2
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
        ,p_program_type            => p_program_type              --------index exists on program_type
        ,p_attribute15             => 'XX_EXTERNAL_USER_PVT'          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'OID'                --------index exists on module_name
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => p_error_message_severity 
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
      fnd_file.put_line(fnd_file.log, p_debug_msg);


  END log_oid;

   -- ===========================================================================
   -- Name             : xx_oid_raise_be
   -- Description      : raising business event to kick off subscription check 
   --                    and update procedure
   --
   -- Parameters :     : user_name
   --                  : 
   --                  : 
   -- ===========================================================================
   PROCEDURE xx_oid_raise_be  ( p_user_name   IN VARCHAR2 )
   IS
   
    l_list                                  WF_PARAMETER_LIST_T;
    l_event_name                            VARCHAR2(240);
    l_event_enabled                         VARCHAR2(2) := NULL;
    
    BEGIN
       log_oid('DEBUG','DEBUG', ' Begin xx_oid_raise_be procedure');
       l_event_name := 'od.xxcomn.oid.subscription.check';    -- create profile_option to control the event name
              
       log_oid('DEBUG','DEBUG','Assembling parameters into wf_parameters_lit');
       l_list := wf_parameter_list_t (
                 wf_parameter_t ('p_user_name', p_user_name)
                 );

       BEGIN
            -- Raise Event
            log_oid('DEBUG','DEBUG',' Raising Business Event : ' || l_event_name);
            Wf_EVENT.raise ( p_event_name   =>  l_event_name, 
                             p_event_key    =>  SYS_GUID(),
                             p_parameters   =>  l_list
                           );
            COMMIT;  
        EXCEPTION
          WHEN OTHERS
             THEN
                 log_oid('ERROR','ERROR',' EXCEPTION in WHEN OTHERS when raising business event xx_oid_raise_be : ' || SQLERRM);
       END;
    
       l_list.DELETE;
        
       log_oid('DEBUG','DEBUG', ' Business Event '||l_event_name ||', Successfully Triggered');
       log_oid('DEBUG','DEBUG', ' End of xx_oid_raise_be procedure');
     EXCEPTION 
        WHEN OTHERS 
           THEN
               log_oid('ERROR','ERROR',' EXCEPTION in WHEN OTHERS in xx_oid_raise_be proc, ERROR : ' || SQLERRM);
    
    END xx_oid_raise_be;
      
   PROCEDURE set_apps_context ( p_system_name               IN           VARCHAR2
                              , p_user_name                 IN           VARCHAR2
                              , p_responsibility_key        IN           VARCHAR2
                              , p_organization_name         IN           VARCHAR2    DEFAULT NULL
                              , x_apps_user_id              OUT NOCOPY   NUMBER
                              , x_resp_id                   OUT NOCOPY   NUMBER
                              , x_resp_appl_id              OUT NOCOPY   NUMBER
                              , x_security_group_id         OUT NOCOPY   NUMBER
                              , x_org_id                    OUT NOCOPY   NUMBER
                              , x_return_status             OUT NOCOPY   VARCHAR2
                              , x_msg_count                 OUT NOCOPY   NUMBER
                              , x_msg_data                  OUT NOCOPY   VARCHAR2
                              )

   IS

      l_progress      VARCHAR2(20);

      ln_user_id              NUMBER;
      ln_responsibility_id    NUMBER;
      ln_resp_app_id          NUMBER;
      ln_security_group_id    NUMBER;
      ln_org_id               NUMBER;

      EX_API_ERROR               EXCEPTION;


   BEGIN

      IF p_user_name IS NOT NULL
      THEN
         BEGIN
            SELECT   user_id
            INTO     ln_user_id
            FROM     FND_USER
            WHERE    user_name=p_user_name;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               x_return_status := FND_API.G_RET_STS_ERROR;
               fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_007_USER_NOT_FOUND');
               fnd_message.set_token ('USER_NAME', p_user_name);
               x_msg_count := x_msg_count + 1;
               x_msg_data := fnd_message.get();
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
               RAISE EX_API_ERROR;
         END;

         IF p_responsibility_key IS NOT NULL
         THEN
            BEGIN
               SELECT  responsibility_id
               INTO    ln_responsibility_id
               FROM    FND_RESPONSIBILITY_VL
               WHERE   responsibility_key=p_responsibility_key;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  x_return_status := FND_API.G_RET_STS_ERROR;
                  fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_008_RESP_NOT_FOUND');
                  fnd_message.set_token ('RESPONSIBILITY_NAME', p_responsibility_key);
                  x_msg_count := x_msg_count + 1;
                  x_msg_data := fnd_message.get();
                  XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
                  RAISE EX_API_ERROR;
            END;

            BEGIN
               SELECT responsibility_application_id,
                      security_group_id
               INTO   ln_resp_app_id,
                      ln_security_group_id
               FROM   FND_USER_RESP_GROUPS
               WHERE  user_id = ln_user_id
               AND    responsibility_id = ln_responsibility_id;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  x_return_status := FND_API.G_RET_STS_ERROR;
                  fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_009_NO_ACCESS');
                  fnd_message.set_token ('USER_NAME', p_user_name);
                  fnd_message.set_token ('RESPONSIBILITY_NAME', p_responsibility_key);
                  x_msg_count := x_msg_count + 1;
                  x_msg_data := fnd_message.get();
                  XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
                  RAISE EX_API_ERROR;
            END;
         ELSE
            ln_responsibility_id := -1;
            ln_resp_app_id       := -1;
            ln_security_group_id := -1;
         END IF; -- p_responsibility_key IS NOT NULL

         x_apps_user_id          := ln_user_id;
         x_resp_id               := ln_responsibility_id;
         x_resp_appl_id          := ln_resp_app_id;
         x_security_group_id     := ln_security_group_id;

         FND_GLOBAL.apps_initialize ( user_id            => NVL(x_apps_user_id, -1)
                                    , resp_id            => NVL(x_resp_id, -1)
                                    , resp_appl_id       => NVL(x_resp_appl_id, -1)
                                    , security_group_id  => NVL(x_security_group_id, -1)
                                    );

      ELSE
         x_apps_user_id          := ln_user_id;
         x_resp_id               := ln_responsibility_id;
         x_resp_appl_id          := ln_resp_app_id;
         x_security_group_id     := ln_security_group_id;

      END IF; -- p_user_name IS NOT NULL

      IF p_organization_name IS NOT NULL
      THEN
         BEGIN
            SELECT organization_id
            INTO   x_org_id
            FROM   hr_operating_units
            WHERE  name=p_organization_name;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               x_return_status := FND_API.G_RET_STS_ERROR;
               fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_010_ORG_NOT_FOUND');
               fnd_message.set_token ('ORGANIZATION_NAME', p_organization_name);
               x_msg_count := x_msg_count + 1;
               x_msg_data := fnd_message.get();
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
               RAISE EX_API_ERROR;
         END;
      END IF; -- p_organization_name is not NULL

      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN EX_API_ERROR THEN
           x_return_status := FND_API.G_RET_STS_ERROR;
      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.set_apps_context');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'Error in contact level. ' || x_msg_data);

   END set_apps_context;

  -- ==========================================================================
  --  PROCEDURE NAME:   get_messages
  --  DESCRIPTION:      Returns the error messages
  --  PARAMETERS:       p_return_status  IN VARCHAR2
  --                    p_msg_count      IN NUMBER
  --                    p_msg_data       IN VARCHAR2
  --
  --  NOTES:
  -- ===========================================================================
  FUNCTION get_messages( p_return_status  IN VARCHAR2
                       , p_msg_count      IN NUMBER
                       , p_msg_data       IN VARCHAR2
                       ) RETURN HZ_MESSAGE_OBJ_TBL
  IS
    l_msg_data    HZ_MESSAGE_OBJ_TBL;
  BEGIN

    l_msg_data := HZ_MESSAGE_OBJ_TBL();

    IF( p_msg_count > 1 AND p_return_status <> FND_API.G_RET_STS_SUCCESS )
    THEN
      FOR I IN 1..FND_MSG_PUB.Count_Msg
      LOOP
        l_msg_data.EXTEND;
        l_msg_data(I) := HZ_MESSAGE_OBJ(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE));
      END LOOP;
    ELSE
      l_msg_data.EXTEND;
      l_msg_data(1) := HZ_MESSAGE_OBJ(p_msg_data);
    END IF;

    RETURN l_msg_data;
  END get_messages;


   -- ===========================================================================
   --  Name             : get_entity_id
   --  Description      : This procedure returns the Oracle unique ID
   --                     based on the values from AOPS
   --
   --  Parameters :      p_orig_system
   --                    p_orig_sys_reference
   --                    p_owner_table_name
   --                    x_owner_table_id
   -- ===========================================================================
   PROCEDURE get_entity_id (
      p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE
    , p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE
    , p_owner_table_name   IN  hz_orig_sys_references.owner_table_name%TYPE
    , x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
    , x_return_status      OUT VARCHAR2
    , x_msg_count          OUT NUMBER
    , x_msg_data           OUT VARCHAR2
   )
   IS
      -- The get_entity_id returns the Oracle unique ID based on the values
      -- from the legacy system (AOPS)
      --
      --  #param 1 p_orig_system            Legacy system identfier
      --  #param 2 p_orig_system_reference  Unique ID from legacy system
      --  #param 3 p_owner_table_name       table_name from Oracle EBS
      --  #param 4 x_owner_table_id         return Oracle unique ID

      ln_owner_table_id   hz_orig_sys_references.owner_table_id%TYPE;

   BEGIN
      x_owner_table_id    := NULL;
      x_msg_count         := 0;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In get_entity_id ');

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_orig_system        := ' || p_orig_system);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_orig_sys_reference := ' || p_orig_sys_reference);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_owner_table_name   := ' || p_owner_table_name);
      $end

      SELECT owner_table_id
        INTO ln_owner_table_id
        FROM hz_orig_sys_references
       WHERE orig_system = p_orig_system
         AND orig_system_reference = p_orig_sys_reference
         AND owner_table_name = p_owner_table_name
         AND status = 'A';

      IF ln_owner_table_id IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;

         fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_004_OSR_NOT_FOUND');
         fnd_message.set_token ('ONWER_TABLE_NAME', p_owner_table_name);
         fnd_message.set_token ('ORIG_SYSTEM', p_orig_system);
         fnd_message.set_token ('ORIG_SYSTEM_REF', p_orig_sys_reference);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
      ELSE
         x_owner_table_id    := ln_owner_table_id;
         x_return_status     := FND_API.G_RET_STS_SUCCESS;
         x_msg_data          := NULL;
      END IF; -- ln_owner_table_id IS NULL

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_owner_table_id := NULL;
         x_return_status := FND_API.G_RET_STS_ERROR;

         fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_004_OSR_NOT_FOUND');
         fnd_message.set_token ('ONWER_TABLE_NAME', p_owner_table_name);
         fnd_message.set_token ('ORIG_SYSTEM', p_orig_system);
         fnd_message.set_token ('ORIG_SYSTEM_REF', p_orig_sys_reference);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );

      WHEN TOO_MANY_ROWS
      THEN
         x_owner_table_id := NULL;
         x_return_status := FND_API.G_RET_STS_ERROR;

         fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_005_DUPL_OSR');
         fnd_message.set_token ('ONWER_TABLE_NAME', p_owner_table_name);
         fnd_message.set_token ('ORIG_SYSTEM', p_orig_system);
         fnd_message.set_token ('ORIG_SYSTEM_REF', p_orig_sys_reference);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );

      WHEN OTHERS
      THEN
         x_owner_table_id := NULL;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
   END get_entity_id;

   -- ===========================================================================
   -- ===========================================================================
  PROCEDURE get_contact_id ( p_orig_system          IN            VARCHAR2
                           , p_cust_acct_cnt_osr    IN            VARCHAR2
                           , x_party_id             OUT           NUMBER
                           , x_return_status        OUT NOCOPY    VARCHAR2
                           , x_msg_count            OUT           NUMBER
                           , x_msg_data             OUT NOCOPY    VARCHAR2
                           )
  AS

      ln_org_contact_id      HZ_ORG_CONTACTS.org_contact_id%TYPE;

      CURSOR c_fetch_rel_party_id_cur ( p_org_contact_id IN NUMBER )
      IS
         SELECT hr.party_id
         FROM   hz_relationships hr,
                hz_org_contacts  hoc
         WHERE  hoc.org_contact_id = p_org_contact_id
         AND    hr.relationship_id = hoc.party_relationship_id
         AND    hr.status = 'A';

      le_api_error              EXCEPTION;

  BEGIN

      x_msg_count         := 0;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In get_contact_id ');
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_orig_system        := ' || p_orig_system);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact OSR          := ' || p_cust_acct_cnt_osr );
      $end

      get_entity_id ( p_orig_system        => p_orig_system
                    , p_orig_sys_reference => p_cust_acct_cnt_osr
                    , p_owner_table_name   => 'HZ_ORG_CONTACTS'
                    , x_owner_table_id     => ln_org_contact_id
                    , x_return_status      => x_return_status
                    , x_msg_count          => x_msg_count
                    , x_msg_data           => x_msg_data
                    );

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact ID '|| ln_org_contact_id );
      $end

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      FOR lc_fetch_rel_party_id_rec IN c_fetch_rel_party_id_cur (ln_org_contact_id)
      LOOP
         x_party_id := lc_fetch_rel_party_id_rec.party_id;
         EXIT;
      END LOOP;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Relationship Party ID: '|| x_party_id );

      IF x_party_id IS NULL
      THEN
         fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_006_INV_RELATION');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         raise le_api_error;
      END IF;

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

  EXCEPTION
      WHEN le_api_error THEN
	 x_return_status := FND_API.G_RET_STS_ERROR;--Added by Y. ALI x81620 on 07/09/2009
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

      WHEN OTHERS
      THEN
         x_party_id := NULL;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_contact_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
  END get_contact_id;

   -- ===========================================================================
   -- Name             : get_account_org
   -- Description      : Get the Org ID for the Customer Account
   --
   -- Parameters :     p_cust_acct_id
   --                  p_acct_site_id
   --                  x_org_id
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_account_org ( p_cust_acct_id                    IN            NUMBER
                             , p_acct_site_id                    IN            NUMBER
                             , p_org_contact_id                  IN            NUMBER
                             , x_org_id                          OUT           NUMBER
                             , x_return_status                   OUT NOCOPY    VARCHAR2
                             , x_msg_count                       OUT           NUMBER
                             , x_msg_data                        OUT NOCOPY    VARCHAR2
                             )
   IS
   BEGIN

      x_msg_count         := 0;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' In get_account_org (1)' );

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' p_cust_acct_id   : ' || p_cust_acct_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' p_acct_site_id   : ' || p_acct_site_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' p_org_contact_id : ' || p_org_contact_id );
      $end

      IF p_acct_site_id IS NOT NULL
      THEN
         SELECT org_id
         INTO   x_org_id
         FROM   hz_cust_acct_sites_all
         WHERE  cust_acct_site_id=p_acct_site_id
         AND    ROWNUM=1;
      ELSIF p_cust_acct_id IS NOT NULL
      THEN
         SELECT org_id
         INTO   x_org_id
         FROM   hz_cust_acct_sites_all
         WHERE  cust_account_id=p_cust_acct_id
         AND    ROWNUM=1;
      ELSIF p_org_contact_id IS NOT NULL
      THEN
         SELECT org_id
         INTO   x_org_id
         FROM   hz_cust_acct_sites_all
         WHERE  cust_account_id IN ( SELECT cust_account_id
                                     FROM   hz_cust_account_roles
                                     WHERE  party_id = p_org_contact_id)
         AND    org_id IS NOT NULL
         AND    ROWNUM = 1;
      ELSE
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_001_INVALID_PARAM');
         fnd_message.set_token ('FUNCTION_NAME', g_pkg_name || '.get_account_org (1)');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; -- p_acct_site_id IS NOT NULL

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_account_org (1)');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         -- x_msg_data := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;
   END get_account_org;


   -- ===========================================================================
   -- Name             : get_account_org
   -- Description      : Get the Org Name for the Customer Account
   --
   -- Parameters :     p_cust_acct_id
   --                  p_acct_site_id
   --                  x_org_id
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_account_org(
      p_cust_acct_id                    IN            NUMBER
    , p_acct_site_id                    IN            NUMBER
    , p_org_contact_id                  IN            NUMBER
    , px_org_id                         OUT           NUMBER
    , x_org_name                        OUT NOCOPY    VARCHAR2
    , x_return_status                   OUT NOCOPY    VARCHAR2
    , x_msg_count                       OUT           NUMBER
    , x_msg_data                        OUT NOCOPY    VARCHAR2
   )
   IS
   BEGIN

      x_msg_count         := 0;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' In get_account_org (2)' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' px_org_id   : ' || px_org_id );
      $end

      IF px_org_id IS NULL
      THEN
         get_account_org ( p_cust_acct_id      => p_cust_acct_id
                         , p_acct_site_id      => p_acct_site_id
                         , p_org_contact_id    => p_org_contact_id
                         , x_org_id            => px_org_id
                         , x_return_status     => x_return_status
                         , x_msg_count         => x_msg_count
                         , x_msg_data          => x_msg_data
                        );

      END IF; -- p_acct_site_id IS NOT NULL

      IF x_return_status = FND_API.G_RET_STS_SUCCESS
      THEN

         SELECT name
         INTO   x_org_name
         FROM   hr_all_organization_units
         WHERE  organization_id = px_org_id;

         x_return_status     := FND_API.G_RET_STS_SUCCESS;
         x_msg_count         := 0;
         x_msg_data          := NULL;
      END IF; -- l_return_status = FND_API.G_RET_STS_SUCCESS THEN


   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_account_org (2)');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         -- x_msg_data := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;
   END get_account_org;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE save_external_user ( p_site_key           IN         VARCHAR2
                                , p_userid             IN         VARCHAR2
                                , p_action_type        IN         VARCHAR2
                                , p_new_extuser_rec    IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                                , x_cur_extuser_rec    OUT NOCOPY XX_EXTERNAL_USERS_PVT.external_user_rec_type
                                , x_return_status      OUT NOCOPY VARCHAR2
                                , x_msg_count          OUT        NUMBER
                                , x_msg_data           OUT NOCOPY VARCHAR2
                                )
   AS

      CURSOR  c_get_external_user (p_userid VARCHAR2)
      IS
        SELECT ROWID
               , ext_user_id
               , userid
               , password
               , person_first_name
               , person_middle_name
               , person_last_name
               , email
               , party_id
               , status
               , orig_system
               , contact_osr
               , acct_site_osr
               , webuser_osr
               , fnd_user_name
               , access_code
               , permission_flag
               , site_key
               , end_date
               , load_status
               , user_locked
               , created_by
               , creation_date
               , last_update_date
               , last_updated_by
               , last_update_login
               , ext_upd_timestamp
        FROM   xx_external_users
        WHERE  userid = p_userid
        and    webuser_osr = p_new_extuser_rec.webuser_osr;

        l_new_user         BOOLEAN;
        l_oid_update_date  DATE;

   BEGIN
      x_msg_count         := 0;

      log_debug('XX_EXTERNAL_USERS_PVT.' || '***** In save_ext_user procedure ***** ');
      
      log_debug('userid                      : ' || p_new_extuser_rec.userid);
      log_debug('password                    : ' || p_new_extuser_rec.password);
      log_debug('person_first_name           : ' || p_new_extuser_rec.person_first_name);
      log_debug('person_middle_name          : ' || p_new_extuser_rec.person_middle_name);
      log_debug('person_last_name            : ' || p_new_extuser_rec.person_last_name);
      log_debug('email                       : ' || p_new_extuser_rec.email);
      log_debug('party_id                    : ' || p_new_extuser_rec.party_id);
      log_debug('status                      : ' || p_new_extuser_rec.status);
      log_debug('action_type                 : ' || p_action_type);
      log_debug('contact_osr                 : ' || p_new_extuser_rec.contact_osr);
      log_debug('acct_site_osr               : ' || p_new_extuser_rec.acct_site_osr);
      log_debug('webuser_osr                 : ' || p_new_extuser_rec.webuser_osr);
      log_debug('access_code                 : ' || p_new_extuser_rec.access_code);
      log_debug('permission_flag             : ' || p_new_extuser_rec.permission_flag);
      log_debug('site_key                    : ' || p_new_extuser_rec.site_key);
      log_debug('fnd_user_name               : ' || p_new_extuser_rec.fnd_user_name);

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from XX_EXTERNAL_USERS Table
      -- -------------------------------------------------------------------------
      BEGIN -- Get External User Information
         OPEN  c_get_external_user(p_userid);
         FETCH c_get_external_user INTO  x_cur_extuser_rec;
         IF c_get_external_user%NOTFOUND
         THEN
            l_new_user := TRUE;
         ELSE
            l_new_user := FALSE;
         END IF; -- c_get_external_user%NOTFOUND

         CLOSE c_get_external_user;
      EXCEPTION
         WHEN OTHERS THEN
              IF c_get_external_user%ISOPEN
              THEN
                  CLOSE c_get_external_user;
              END IF; -- c_getexternal_users%ISOPEN
              RAISE;
      END; -- Get External User Information

      IF l_new_user
      THEN
        XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Inserting User Info Into xx_external_users Table');
        INSERT INTO xx_external_users
                           ( ext_user_id
                           , userid
                           , password
                           , person_first_name
                           , person_middle_name
                           , person_last_name
                           , email
                           , party_id
                           , status
                           , orig_system
                           , contact_osr
                           , acct_site_osr
                           , webuser_osr
                           , access_code
                           , permission_flag
                           , site_key
                           , fnd_user_name
                           , load_status
                           , created_by
                           , creation_date
                           , last_update_date
                           , last_updated_by
                           , last_update_login
                           , ext_upd_timestamp
                           )
                    VALUES ( xx_external_users_s.NEXTVAL
                           , p_new_extuser_rec.userid
                           , p_new_extuser_rec.password
                           , p_new_extuser_rec.person_first_name
                           , p_new_extuser_rec.person_middle_name
                           , p_new_extuser_rec.person_last_name
                           , p_new_extuser_rec.email
                           , p_new_extuser_rec.party_id
                           , NVL(p_new_extuser_rec.status,0)
                           , p_new_extuser_rec.orig_system
                           , p_new_extuser_rec.contact_osr
                           , p_new_extuser_rec.acct_site_osr
                           , p_new_extuser_rec.webuser_osr
                           , p_new_extuser_rec.access_code
                           , p_new_extuser_rec.permission_flag
                           , p_new_extuser_rec.site_key
                           , p_new_extuser_rec.fnd_user_name
                           , 'P'
                           , fnd_global.user_id()
                           , SYSDATE
                           , SYSDATE
                           , fnd_global.user_id()
                           , fnd_global.login_id()
                           , p_new_extuser_rec.ext_upd_timestamp
                           );
      ELSE
         IF x_cur_extuser_rec.userid                        =    p_new_extuser_rec.userid                       AND
            x_cur_extuser_rec.password                      =    p_new_extuser_rec.password                     AND
            NVL(x_cur_extuser_rec.person_first_name, '')    =    NVL(p_new_extuser_rec.person_first_name, '')   AND
            NVL(x_cur_extuser_rec.person_middle_name, '')   =    NVL(p_new_extuser_rec.person_middle_name, '')  AND
            x_cur_extuser_rec.person_last_name              =    p_new_extuser_rec.person_last_name             AND
            NVL(x_cur_extuser_rec.email, '')                =    NVL(p_new_extuser_rec.email, '')               AND
            NVL(x_cur_extuser_rec.party_id, -1)             =    NVL(p_new_extuser_rec.party_id, -1)            AND
            x_cur_extuser_rec.contact_osr                   =    p_new_extuser_rec.contact_osr                  AND
            x_cur_extuser_rec.acct_site_osr                 =    p_new_extuser_rec.acct_site_osr                AND
            x_cur_extuser_rec.webuser_osr                   =    p_new_extuser_rec.webuser_osr                  AND
            x_cur_extuser_rec.access_code                   =    p_new_extuser_rec.access_code                  AND
            x_cur_extuser_rec.permission_flag               =    p_new_extuser_rec.permission_flag              AND
            p_action_type                                   !=   'C'

         THEN
             XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'No Update');
         ELSE
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Updating User Info xx_external_users Table');
            
            IF   x_cur_extuser_rec.password            !=    p_new_extuser_rec.password
              OR x_cur_extuser_rec.person_first_name   !=    p_new_extuser_rec.person_first_name
              OR x_cur_extuser_rec.person_middle_name  !=    p_new_extuser_rec.person_middle_name
              OR x_cur_extuser_rec.person_last_name    !=    p_new_extuser_rec.person_last_name
              OR x_cur_extuser_rec.email               !=    p_new_extuser_rec.email
              OR x_cur_extuser_rec.access_code         !=    p_new_extuser_rec.access_code
              OR p_action_type                          =    'C'
            THEN 
                l_oid_update_date := SYSDATE;
            END IF;    

            UPDATE xx_external_users
            SET    userid                         = NVL(p_new_extuser_rec.userid,userid)
                 , password                       = p_new_extuser_rec.password
                 , person_first_name              = p_new_extuser_rec.person_first_name
                 , person_middle_name             = p_new_extuser_rec.person_middle_name
                 , person_last_name               = p_new_extuser_rec.person_last_name
                 , email                          = p_new_extuser_rec.email
                 , party_id                       = p_new_extuser_rec.party_id
                 , status                         = p_new_extuser_rec.status
                 , contact_osr                    = p_new_extuser_rec.contact_osr
                 , acct_site_osr                  = p_new_extuser_rec.acct_site_osr
                 , webuser_osr                    = p_new_extuser_rec.webuser_osr
                 , access_code                    = NVL(p_new_extuser_rec.access_code, access_code)
                 , permission_flag                = p_new_extuser_rec.permission_flag
                 , site_key                       = p_new_extuser_rec.site_key
                 , last_update_date               = SYSDATE
                 , oid_update_date                = NVL(l_oid_update_date,oid_update_date)
                 , last_updated_by                = fnd_global.user_id()
                 , last_update_login              = fnd_global.login_id()
                 , ext_upd_timestamp              = p_new_extuser_rec.ext_upd_timestamp
            WHERE  rowid = x_cur_extuser_rec.ext_user_rowid;
         END IF; -- x_cur_extuser_rec.userid                        =    p_new_extuser_rec.userid
      END IF; -- l_new_user

      -- Raising business event to check subscription of the user
      -- and update if subscription does not exist
--      BEGIN
--
--        --Check if Business event is enabled
--        IF (fnd_profile.value_wnps('XX_OID_SUBSCRIPTION_BE_ENABLE') = 'Y' and p_new_extuser_rec.access_code in ('02', '03', '05', '06'))
--        THEN
--            log_oid('DEBUG','DEBUG',' Raising Business Event');
--            --xx_oid_raise_be(p_new_extuser_rec.fnd_user_name);
--        ELSE
--            log_oid('DEBUG','DEBUG',' OID Subscription Business Event profile option is Disabled');
--        END IF;
--
--        EXCEPTION
--           WHEN OTHERS THEN
--             log_oid('ERROR','ERROR',' EXCEPTION in WHEN OTHERS calling xx_oid_raise_be, ERROR : ' || SQLERRM);
--      END;
      
      BEGIN

        -- Check if External User falls under access codes '02', '03', '05', '06' 
        -- to update subscrption for the external user
        IF (fnd_profile.value_wnps('XX_OID_SUBSCRIPTION_BE_ENABLE') = 'Y' and p_new_extuser_rec.access_code in ('02', '03', '05', '06'))
        THEN
            log_oid('DEBUG','DEBUG',' Calling OID Subscription process for external user : ' ||p_new_extuser_rec.fnd_user_name);
            XX_OID_SUBSCRIPTION_UPD_PKG.update_subscription(p_new_extuser_rec.fnd_user_name);
        ELSE
            log_oid('DEBUG','DEBUG',' External User '||p_new_extuser_rec.fnd_user_name||' does not have either of access codes 02,03,05 or 06');
        END IF;

        EXCEPTION
           WHEN OTHERS THEN
             log_oid('ERROR','ERROR',' EXCEPTION in WHEN OTHERS calling OID Subscription process in xx_external_users_pvt, ERROR : ' || SQLERRM);
      END;
      
      x_return_status := FND_API.G_RET_STS_SUCCESS;
   EXCEPTION
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_external_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data);
   END save_external_user;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE update_new_fnd_user ( p_fnd_user_id             IN         NUMBER   DEFAULT NULL
                                 , p_fnd_user_name           IN         VARCHAR2 DEFAULT NULL
                                 , x_return_status           OUT NOCOPY VARCHAR2
                                 , x_msg_count               OUT        NUMBER
                                 , x_msg_data                OUT NOCOPY VARCHAR2
                                 )
   AS
      ln_count             PLS_INTEGER;
      ln_org_id            NUMBER;
      ln_resp_id           NUMBER;
      ln_resp_appl_id      NUMBER;
      ln_security_group_id NUMBER;
      lv_user_name         FND_USER.USER_NAME%TYPE;
      lv_retcode           VARCHAR2(10);
      lv_oid_retcode       VARCHAR2(10);

      l_param_name         VARCHAR2(2000);
      l_param_value        VARCHAR2(2000);
      l_event_name         VARCHAR2(2000);
      l_event_key          VARCHAR2(2000);
      l_parameter_list     WF_PARAMETER_LIST_T := wf_parameter_list_t();

      l_return_status      VARCHAR2(30);
      l_msg_count          NUMBER;
      l_msg_data           VARCHAR2(2000);

      TYPE c_fnd_user_cur_type IS REF CURSOR;

      c_fnd_user           c_fnd_user_cur_type;

      CURSOR  c_get_external_user (p_fnd_user_name VARCHAR2)
      IS
        SELECT ROWID
               , ext_user_id
               , userid
               , password
               , person_first_name
               , person_middle_name
               , person_last_name
               , email
               , party_id
               , status
               , orig_system
               , contact_osr
               , acct_site_osr
               , webuser_osr
               , fnd_user_name
               , access_code
               , permission_flag
               , site_key
               , end_date
               , load_status
               , user_locked
               , created_by
               , creation_date
               , last_update_date
               , last_updated_by
               , last_update_login
               , ext_upd_timestamp
        FROM   xx_external_users
        WHERE  fnd_user_name = p_fnd_user_name;

      l_fnd_user_rec            XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
      l_cur_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;
      l_new_extuser_rec         XX_EXTERNAL_USERS_PVT.external_user_rec_type;


      l_fnd_user_found          BOOLEAN;
      l_cur_extuser_found       BOOLEAN;

      le_update_fnd_user_failed  EXCEPTION;
      le_oid_pwd_update_failed   EXCEPTION;
   BEGIN

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In update_new_fnd_user ' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_fnd_user_id    := ' || p_fnd_user_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_fnd_user_name  := ' || p_fnd_user_name );
      $end

      x_msg_count := 0;

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from FND_USER Table
      -- -------------------------------------------------------------------------
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Get User information from FND_USER'  );
      BEGIN -- Get the User Informarion from FND_USER Table
         l_fnd_user_found := TRUE;
         -- OPEN  c_fnd_user(p_fnd_user_id);

         IF p_fnd_user_id IS NOT NULL
         THEN
            OPEN c_fnd_user FOR SELECT rowid,
                                       user_id,
                                       user_name,
                                       description,
                                       customer_id
                                FROM   fnd_user
                                WHERE  user_id = p_fnd_user_id;
         ELSIF p_fnd_user_name IS NOT NULL
         THEN
            OPEN c_fnd_user FOR SELECT rowid,
                                       user_id,
                                       user_name,
                                       description,
                                       customer_id
                                FROM   fnd_user
                                WHERE  user_name = p_fnd_user_name;
         ELSE
            x_return_status := FND_API.G_RET_STS_ERROR;
            fnd_message.set_name ('xxcrm', 'XX_CDH_IREC_001_INVALID_PARAM');
            fnd_message.set_token ('FUNCTION_NAME', g_pkg_name || '.update_new_fnd_user');
            x_msg_count := x_msg_count + 1;
            x_msg_data := fnd_message.get();
            RAISE le_update_fnd_user_failed;
         END IF; -- p_user_id IS NOT NULL

         FETCH c_fnd_user INTO  l_fnd_user_rec;
         IF c_fnd_user%NOTFOUND
         THEN
            l_fnd_user_found := FALSE;
         END IF; -- c_getexternal_users%NOTFOUND
         CLOSE c_fnd_user;
      EXCEPTION
         WHEN OTHERS THEN
              IF c_fnd_user%ISOPEN
              THEN
                  CLOSE c_fnd_user;
              END IF; -- c_fnd_user%ISOPEN
              RAISE;
      END; -- Get the User Informarion from FND_USER Table

      IF not l_fnd_user_found
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;

         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_007_USER_NOT_FOUND');
         fnd_message.set_token ('USER_NAME', NVL(p_fnd_user_id, p_fnd_user_name) );
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
         RAISE le_update_fnd_user_failed;
      END IF; -- l_fnd_user_found

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_fnd_user_rec.user_id        :=  ' || l_fnd_user_rec.user_id     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_fnd_user_rec.user_name      :=  ' || l_fnd_user_rec.user_name   );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_fnd_user_rec.description    :=  ' || l_fnd_user_rec.description );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_fnd_user_rec.customer_id    :=  ' || l_fnd_user_rec.customer_id );
      $end

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from XX_EXTERNAL_USERS Table
      -- -------------------------------------------------------------------------
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Get User information from XX_EXTERNAL_USERS'  );
      l_cur_extuser_found := FALSE;
      BEGIN -- Get External User Information
         OPEN  c_get_external_user(l_fnd_user_rec.user_name);
         FETCH c_get_external_user INTO  l_new_extuser_rec;
         IF c_get_external_user%NOTFOUND
         THEN
            l_cur_extuser_found := FALSE;
         ELSE
            l_cur_extuser_found := TRUE;
         END IF; -- c_get_external_user%NOTFOUND

         CLOSE c_get_external_user;
      EXCEPTION
         WHEN OTHERS THEN
              IF c_get_external_user%ISOPEN
              THEN
                  CLOSE c_get_external_user;
              END IF; -- c_getexternal_users%ISOPEN
              RAISE;
      END; -- Get External User Information

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.ext_user_id            := ' || l_new_extuser_rec.ext_user_id          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.userid                 := ' || l_new_extuser_rec.userid               );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.password               := ' || l_new_extuser_rec.password             );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.person_first_name      := ' || l_new_extuser_rec.person_first_name    );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.person_middle_name     := ' || l_new_extuser_rec.person_middle_name   );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.person_last_name       := ' || l_new_extuser_rec.person_last_name     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.email                  := ' || l_new_extuser_rec.email                );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.party_id               := ' || l_new_extuser_rec.party_id             );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.status                 := ' || l_new_extuser_rec.status               );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.orig_system            := ' || l_new_extuser_rec.orig_system          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.contact_osr            := ' || l_new_extuser_rec.contact_osr          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.acct_site_osr          := ' || l_new_extuser_rec.acct_site_osr        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.webuser_osr            := ' || l_new_extuser_rec.webuser_osr          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.access_code            := ' || l_new_extuser_rec.access_code          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.permission_flag        := ' || l_new_extuser_rec.permission_flag      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.site_key               := ' || l_new_extuser_rec.site_key             );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.end_date               := ' || l_new_extuser_rec.end_date             );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.load_status            := ' || l_new_extuser_rec.load_status          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.user_locked            := ' || l_new_extuser_rec.user_locked          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.created_by             := ' || l_new_extuser_rec.created_by           );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.creation_date          := ' || l_new_extuser_rec.creation_date        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.last_update_date       := ' || l_new_extuser_rec.last_update_date     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.last_updated_by        := ' || l_new_extuser_rec.last_updated_by      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.last_update_login      := ' || l_new_extuser_rec.last_update_login    );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_new_extuser_rec.ext_upd_timestamp      := ' || l_new_extuser_rec.ext_upd_timestamp    );
      $end

      IF l_cur_extuser_found
      THEN

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'Execute update_fnd_user'  );
         update_fnd_user( p_cur_extuser_rec            => l_cur_extuser_rec
                        , p_new_extuser_rec            => l_new_extuser_rec
                        , p_fnd_user_rec               => l_fnd_user_rec
                        , x_return_status              => l_return_status
                        , x_msg_count                  => l_msg_count
                        , x_msg_data                   => l_msg_data
                        );

         IF l_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
            raise le_update_fnd_user_failed;
         END IF;
      END IF; -- l_cur_extuser_found

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_update_fnd_user_failed
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

      WHEN OTHERS
      THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.update_new_fnd_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data );
   END update_new_fnd_user;


   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         )
   AS

      l_new_user                 BOOLEAN := FALSE;

      l_org_id                   HZ_CUST_ACCT_SITES_ALL.ORG_ID%TYPE;
      l_org_name                 HR_ALL_ORGANIZATION_UNITS.NAME%TYPE;
      l_party_id                 HZ_PARTIES.party_id%TYPE;
      l_site_key                 XX_EXTERNAL_USERS.site_key%TYPE;

      l_new_resp_id              FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_new_appl_id              FND_RESPONSIBILITY.application_id%TYPE;
      l_new_resp_desc            FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      l_cur_resp_id              FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_cur_appl_id              FND_RESPONSIBILITY.application_id%TYPE;
      l_cur_resp_desc            FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      ln_fnd_user_id             FND_USER.user_id%TYPE;

      le_party_id_null           EXCEPTION;
      le_update_fnd_failed       EXCEPTION;
      le_api_error               EXCEPTION;

   BEGIN

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In update_fnd_user ' );

      x_msg_count         := 0;

      -- -------------------------------------------------------------------------
      -- If the FND_USER Record does not have the Customer ID,
      -- Update the user with the Customer ID Information
      -- -------------------------------------------------------------------------
      l_party_id := p_new_extuser_rec.party_id;

      -- ** AKS: Check Where party_id is coming from
      IF p_fnd_user_rec.customer_id IS NULL OR
         NVL(p_fnd_user_rec.customer_id, -1) <> NVL(p_new_extuser_rec.party_id,-1)

      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Update FND_USER ' || p_fnd_user_rec.user_name ||  ' with Customer ID ' || l_party_id );
         fnd_user_pkg.updateuser ( x_user_name   => p_fnd_user_rec.user_name
                                 , x_owner       => 'CUST'
                                 , x_customer_id => l_party_id
                                 );
      END IF; -- l_party_id IS NULL

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Getting Org Name ');

      get_account_org( p_cust_acct_id      => NULL
                     , p_acct_site_id      => NULL
                     , p_org_contact_id    => l_party_id
                     , px_org_id           => l_org_id
                     , x_org_name          => l_org_name
                     , x_return_status     => x_return_status
                     , x_msg_count         => x_msg_count
                     , x_msg_data          => x_msg_data
                     );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         raise le_api_error;
      END IF;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Org Name ' || l_org_name );

      -- -----------------------------------------------------------------
      -- Check If user Has access to iRec or iRec with Credit
      -- -----------------------------------------------------------------
      get_resp_id ( p_orig_system            => p_new_extuser_rec.orig_system
                  , p_orig_system_access     => p_new_extuser_rec.access_code
                  , p_org_name               => l_org_name
                  , x_resp_id                => l_new_resp_id
                  , x_appl_id                => l_new_appl_id
                  , x_responsibility_name    => l_new_resp_desc
                  , x_return_status          => x_return_status
                  , x_msg_count              => x_msg_count
                  , x_msg_data               => x_msg_data
                  );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         raise le_api_error;
      END IF;


      IF p_cur_extuser_rec.access_code IS NOT NULL
      THEN

            -- ------------------------------------------------------------
            -- Get the Responsibility associated with the current access Code
            -- ------------------------------------------------------------
            get_resp_id ( p_orig_system            => p_cur_extuser_rec.orig_system
                        , p_orig_system_access     => p_cur_extuser_rec.access_code
                        , p_org_name               => l_org_name
                        , x_resp_id                => l_cur_resp_id
                        , x_appl_id                => l_cur_appl_id
                        , x_responsibility_name    => l_cur_resp_desc
                        , x_return_status          => x_return_status
                        , x_msg_count              => x_msg_count
                        , x_msg_data               => x_msg_data
                        );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS
            THEN
               raise le_api_error;
            END IF;


      END IF; -- p_cur_extuser_rec.access_code IS NOT NULL

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'New Responsibility Id   : ' || l_new_resp_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'New Responsibility App  : ' || l_new_appl_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'New Responsibility Name : ' || l_new_resp_desc );

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Current Responsibility Id   : ' || l_cur_resp_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Current Responsibility App  : ' || l_cur_appl_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Current Responsibility Name : ' || l_cur_resp_desc );
      $end

      IF ( NVL(l_cur_resp_id, -1) <> NVL(l_new_resp_id, -1) )
      THEN
         IF l_cur_resp_id IS NOT NULL
         THEN
            -- -----------------------------------------------------------------------------
            -- Revoke the responsibility from the user
            -- AKS: Might have to get the Activation date for the responsibility
            -- -----------------------------------------------------------------------------
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Remove Responsibility : ' || l_cur_resp_desc );
            fnd_user_resp_groups_api.upload_assignment
                        ( user_id                       => p_fnd_user_rec.user_id
                        , responsibility_id             => l_cur_resp_id
                        , responsibility_application_id => l_cur_appl_id
                        , start_date                    => SYSDATE
                        , end_date                      => SYSDATE
                        , description                   => l_cur_resp_desc
                        );

         END IF; -- l_cur_resp_id IS NOT NULL THEN

         IF l_new_resp_id IS NOT NULL
         THEN
            -- -----------------------------------------------------------------------------
            -- Grant the responsibility from the user
            -- -----------------------------------------------------------------------------
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Add Responsibility : ' || l_new_resp_desc );
            fnd_user_resp_groups_api.upload_assignment
                        ( user_id                       => p_fnd_user_rec.user_id
                        , responsibility_id             => l_new_resp_id
                        , responsibility_application_id => l_new_appl_id
                        , start_date                    => SYSDATE
                        , end_date                      => NULL
                        , description                   => l_cur_resp_desc
                        );

         END IF; -- l_cur_resp_id IS NOT NULL THEN

      END IF; -- ( NVL(l_cur_resp_id, -1) <> NVL(l_new_resp_id, -1) )

      -- -----------------------------------------------------------------------------
      -- Grant the responsibility from the user
      -- -----------------------------------------------------------------------------
      UPDATE xx_external_users
      SET    load_status='C'
      WHERE  ROWID=p_new_extuser_rec.ext_user_rowid;

      x_return_status := FND_API.G_RET_STS_SUCCESS;
   EXCEPTION

     WHEN le_api_error THEN
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data);
       -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.update_fnd_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data);
         --raise;
   END update_fnd_user;

   -- ===========================================================================
   -- Name             : get_resp_id
   -- Description      :
   --
   --
   --
   --
   -- Parameters       : p_orig_system
   --                    p_orig_system_access
   --                    p_org_name
   --                    x_resp_id
   --                    x_appl_id
   --                    x_responsibility_name
   --                    x_return_status
   --                    x_msg_count
   --                    x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_resp_id ( p_orig_system            IN         VARCHAR2
                         , p_orig_system_access     IN         VARCHAR2
                         , p_org_name               IN         VARCHAR2
                         , x_resp_id                OUT        NUMBER
                         , x_appl_id                OUT        NUMBER
                         , x_responsibility_name    OUT NOCOPY VARCHAR2
                         , x_return_status          OUT NOCOPY VARCHAR2
                         , x_msg_count              OUT NUMBER
                         , x_msg_data               OUT NOCOPY VARCHAR2
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

      x_msg_count := 0;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Getting Value for : XX_IREC_RESP_MAP ' || p_orig_system || ' , ' || p_orig_system_access);
      $end

      XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC ( p_translation_name =>  'XX_IREC_RESP_MAP'
                                                      , p_source_value1    =>  p_orig_system
                                                      , p_source_value2    =>  LPAD(p_orig_system_access,2, '0')
                                                      , p_source_value3    =>  p_org_name
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
                                                      , x_error_message    =>  x_msg_data
                                                      );

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Resp'||lv_resp_key);
      $end

      IF lv_resp_key IS NOT NULL
      THEN
         SELECT responsibility_id,
                application_id,
                responsibility_name
         INTO   x_resp_id,
                x_appl_id,
                x_responsibility_name
         FROM   fnd_responsibility_vl
         WHERE  responsibility_key = lv_resp_key;

      END IF; -- lv_resp_key IS NOT NULL

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Responsibility ID   : ' || x_resp_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Application ID      : ' || x_appl_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Responsibility Name : ' || x_responsibility_name);
      $end

      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_resp_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
   END get_resp_id;


   -- ===========================================================================
   -- Name             : get_resp_id
   -- Description      :
   --
   --
   --
   --
   -- Parameters       : p_system_name
   --                    p_permission_flag
   --                    x_contact_level
   --                    x_return_status
   --                    x_msg_count
   --                    x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_contact_level ( p_system_name     IN  VARCHAR2
                               , p_permission_flag IN  VARCHAR2
                               , x_contact_level   OUT VARCHAR2
                               , x_return_status   OUT VARCHAR2
                               , x_msg_count       OUT NUMBER
                               , x_msg_data        OUT VARCHAR2
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

      le_api_error          EXCEPTION;

   BEGIN

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Getting Value for : XX_CDH_CONTACT_LEVEL ' || p_system_name || ' , ' || p_permission_flag);
      $end

      XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC ( p_translation_name =>  'XX_CDH_CONTACT_LEVEL'
                                                      , p_source_value1    =>  p_system_name
                                                      , p_source_value2    =>  p_permission_flag
                                                      , x_target_value1    =>  x_contact_level
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
                                                      , x_error_message    =>  x_msg_data
                                                      );

      IF (x_contact_level IS NULL)
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_003_MISSING_SETUP');
         fnd_message.set_token ('SETUP_NAME', 'XX_CDH_CONTACT_LEVEL');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
         RAISE le_api_error;
      END IF;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact Level ' ||x_contact_level);
      $end
      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, x_msg_data);

      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_contact_level');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'Error in contact level. ' || x_msg_data);
   END get_contact_level;

   -- ===========================================================================
   -- Name             : get_user_prefix
   -- Description      :
   --
   --
   --
   --
   -- Parameters       : p_system_name
   --                    x_site_key
   --                    x_return_status
   --                    x_msg_count
   --                    x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_user_prefix ( p_system_name     IN  VARCHAR2
                             , x_site_key        OUT VARCHAR2
                             , x_return_status   OUT VARCHAR2
                             , x_msg_count       OUT NUMBER
                             , x_msg_data        OUT VARCHAR2
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

   BEGIN


      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Getting Value for : XX_ECOM_SITE_KEY ' || p_system_name);
      $end

      XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC ( p_translation_name   =>  'XX_ECOM_SITE_KEY'
                                                      , p_source_value1      =>  p_system_name
                                                      , x_target_value1      =>  x_site_key
                                                      , x_target_value2      =>  lv_target_value2_out
                                                      , x_target_value3      =>  lv_target_value3_out
                                                      , x_target_value4      =>  lv_target_value4_out
                                                      , x_target_value5      =>  lv_target_value5_out
                                                      , x_target_value6      =>  lv_target_value6_out
                                                      , x_target_value7      =>  lv_target_value7_out
                                                      , x_target_value8      =>  lv_target_value8_out
                                                      , x_target_value9      =>  lv_target_value9_out
                                                      , x_target_value10     =>  lv_target_value10_out
                                                      , x_target_value11     =>  lv_target_value11_out
                                                      , x_target_value12     =>  lv_target_value12_out
                                                      , x_target_value13     =>  lv_target_value13_out
                                                      , x_target_value14     =>  lv_target_value14_out
                                                      , x_target_value15     =>  lv_target_value15_out
                                                      , x_target_value16     =>  lv_target_value16_out
                                                      , x_target_value17     =>  lv_target_value17_out
                                                      , x_target_value18     =>  lv_target_value18_out
                                                      , x_target_value19     =>  lv_target_value19_out
                                                      , x_target_value20     =>  lv_target_value20_out
                                                      , x_error_message      =>  x_msg_data
                                                      );

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Site Key ' ||x_site_key);
      $end
      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_user_prefix');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'Error in contact level. ' || x_msg_data);
  END get_user_prefix;


END XX_EXTERNAL_USERS_PVT;
/

SHOW ERRORS;