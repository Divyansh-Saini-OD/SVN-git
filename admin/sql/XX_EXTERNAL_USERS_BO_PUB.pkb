CREATE OR REPLACE PACKAGE BODY XX_EXTERNAL_USERS_BO_PUB
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
-- |                                                                                                    |
-- +====================================================================================================+
*/


  g_debug_type                   VARCHAR2(10)    := 'FND';
  g_debug_level                  NUMBER          := 3;
  g_debug_count                  NUMBER          := 0;
  g_debug                        BOOLEAN         := FALSE;

  g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_EXTERNAL_USERS_BO_PUB';
  g_module                       CONSTANT VARCHAR2(30) := 'CRM';

  g_user_role                    CONSTANT VARCHAR2(60) := 'SELF_SERVICE_USER';
  g_revoked_user_role            CONSTANT VARCHAR2(60) := 'REVOKED_SELF_SERVICE_ROLE';

  g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();

  FUNCTION get_messages( p_return_status  IN VARCHAR2
                       , p_msg_count      IN NUMBER
                       , p_msg_data       IN VARCHAR2
                       ) RETURN HZ_MESSAGE_OBJ_TBL;

  PROCEDURE get_contact_level ( p_system_name     IN  VARCHAR2
                              , p_permission_flag IN  VARCHAR2
                              , x_contact_level   OUT VARCHAR2
                              , x_return_status   OUT VARCHAR2
                              , x_msg_count       OUT NUMBER
                              , x_msg_data        OUT VARCHAR2
                        );

   PROCEDURE save_acct_site_ext ( p_operation                 IN         VARCHAR2
                                , p_orig_system               IN         VARCHAR2
                                , p_ship_to_acct_site_id      IN         NUMBER
                                , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_bill_to_acct_site_id      IN         NUMBER
                                , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_contact_party_id          IN         NUMBER
                                , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                , x_return_status             OUT NOCOPY VARCHAR2
                                , x_msg_count                 OUT        NUMBER
                                , x_msg_data                  OUT NOCOPY VARCHAR2
                                );

   PROCEDURE save_ship_to_contact ( p_operation                 IN         VARCHAR2
                                  , p_orig_system               IN         VARCHAR2
                                  , p_ship_to_acct_site_id      IN         NUMBER
                                  , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_bill_to_acct_site_id      IN         NUMBER
                                  , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_contact_party_id          IN         NUMBER
                                  , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                  , x_bill_to_operation         OUT NOCOPY VARCHAR2
                                  , x_return_status             OUT NOCOPY VARCHAR2
                                  , x_msg_count                 OUT        NUMBER
                                  , x_msg_data                  OUT NOCOPY VARCHAR2
                                  );

   PROCEDURE get_bill_to_site_id ( p_cust_acct_id                    IN            NUMBER
                                 , p_ship_to_cust_acct_site_id       IN            NUMBER
                                 , x_bill_to_cust_acct_site_id       OUT           NUMBER
                                 , x_bill_to_osr                     OUT NOCOPY    VARCHAR2
                                 , x_return_status                   OUT NOCOPY    VARCHAR2
                                 , x_msg_count                       OUT           NUMBER
                                 , x_msg_data                        OUT NOCOPY    VARCHAR2
                                 );

   PROCEDURE get_account_org ( p_cust_acct_id                    IN            NUMBER
                             , p_acct_site_id                    IN            NUMBER
                             , p_org_contact_id                  IN            NUMBER
                             , x_org_id                          OUT           NUMBER
                             , x_return_status                   OUT NOCOPY    VARCHAR2
                             , x_msg_count                       OUT           NUMBER
                             , x_msg_data                        OUT NOCOPY    VARCHAR2
                             );

   PROCEDURE get_account_org ( p_cust_acct_id                    IN            NUMBER
                             , p_acct_site_id                    IN            NUMBER
                             , p_org_contact_id                  IN            NUMBER
                             , px_org_id                         OUT           NUMBER
                             , x_org_name                        OUT NOCOPY    VARCHAR2
                             , x_return_status                   OUT NOCOPY    VARCHAR2
                             , x_msg_count                       OUT           NUMBER
                             , x_msg_data                        OUT NOCOPY    VARCHAR2
                             );


   PROCEDURE save_bill_to_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_ship_to_acct_site_id        IN             NUMBER
                                       , p_bill_to_acct_site_id        IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR2
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_parent_obj                  IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   );

   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_ship_to_acct_site_id    IN         NUMBER
                                   , p_ship_to_acct_site_osr   IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   );

  PROCEDURE get_resp_id ( p_orig_system            IN         VARCHAR2
                        , p_orig_system_access     IN         VARCHAR2
                        , p_org_name               IN         VARCHAR2
                        , x_resp_id                OUT        NUMBER
                        , x_appl_id                OUT        NUMBER
                        , x_responsibility_name    OUT NOCOPY VARCHAR2
                        , x_return_status          OUT NOCOPY VARCHAR2
                        , x_msg_count              OUT NUMBER
                        , x_msg_data               OUT NOCOPY VARCHAR2
                        );

  PROCEDURE get_user_prefix ( p_system_name     IN  VARCHAR2
                            , x_site_key        OUT VARCHAR2
                            , x_return_status   OUT VARCHAR2
                            , x_msg_count       OUT NUMBER
                            , x_msg_data        OUT VARCHAR2
                            );

   PROCEDURE save_external_user ( p_userid                     IN         VARCHAR2
                                , p_new_extuser_rec            IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                                , x_cur_extuser_rec            OUT NOCOPY XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                                , x_return_status              OUT NOCOPY VARCHAR2
                                , x_msg_count                  OUT        NUMBER
                                , x_msg_data                   OUT NOCOPY VARCHAR2
                                );


  -- ==========================================================================
  --  PROCEDURE NAME:   enable_debug
  --  DESCRIPTION:      Turn on debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE enable_debug;

  -- ==========================================================================
  --  PROCEDURE NAME:   enable_debug
  --  DESCRIPTION:      Turn Off debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE disable_debug;

  -- ==========================================================================
  --  PROCEDURE NAME:   log_debug_message
  --  DESCRIPTION:      This procedure parses and prints debugging messages.
  --  PARAMETERS:       p_debug_level            IN   NUMBER
  --                    p_message                IN   VARCHAR2
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE log_debug_message (
                    p_debug_level    IN    NUMBER
                   ,p_message        IN    VARCHAR2
                  );

  -- ==========================================================================
  --  PROCEDURE NAME:   enable_debug
  --  DESCRIPTION:      Turn on debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE enable_debug
  IS
  BEGIN
    g_debug_count := g_debug_count + 1;

    IF g_debug_count = 1 THEN
      IF fnd_profile.value('HZ_API_FILE_DEBUG_ON') = 'Y' OR
         fnd_profile.value('HZ_API_DBMS_DEBUG_ON') = 'Y'
      THEN
         hz_utility_v2pub.enable_debug;
         g_debug       := TRUE;
         g_debug_type  := 'HZ';
         g_debug_level := NVL(fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG_LEVEL'),3);
      ELSIF fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG') = 'Y'
      THEN
         g_debug       := TRUE;
         g_debug_type  := 'FND';
         g_debug_level := NVL(fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG_LEVEL'),3);
      ELSE
         g_debug       := FALSE;
         g_debug_type  := NULL;
         g_debug_level := NVL(fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG_LEVEL'),3);
      END IF;
    END IF;
    g_debug := TRUE;
  END enable_debug;

  -- ==========================================================================
  --  PROCEDURE NAME:   disable_debug
  --  DESCRIPTION:      Turn Off debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE disable_debug
  IS
  BEGIN

    IF g_debug THEN
      g_debug_count := g_debug_count - 1;

      IF g_debug_count = 0 THEN
        hz_utility_v2pub.disable_debug;
        g_debug := FALSE;
      END IF;
    END IF;

  END disable_debug;

  -- ===========================================================================
  --  PROCEDURE NAME:   log_debug_message
  --  DESCRIPTION:      This procedure parses and prints debugging messages.
  --  PARAMETERS:       p_debug_level            IN   NUMBER
  --                    p_message                IN   VARCHAR2
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE log_debug_message ( p_debug_level    IN    NUMBER
                              , p_message        IN    VARCHAR2
                              )
  IS
     PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

     INSERT INTO XX_IREC_DEBUG (MSG)
            VALUES ( to_char(SYSDATE, 'dd-mon-yyyy hh24:mi:ss') || ' - ' || p_message);

     IF g_debug = TRUE AND g_debug_level >= p_debug_level
     THEN
        IF NVL(g_request_id,0) <> 0
        THEN
           fnd_file.put_line (fnd_file.log, p_message);
        ELSIF g_debug_type  = 'HZ'
        THEN
           hz_utility_v2pub.debug(p_message);
        ELSE
           -- Call FND_DEBUG_MESSAGE
           NULL;
        END IF; -- NVL(g_request_id,0) <> 0
     END IF; -- g_debug = TRUE AND g_debug_level >= p_debug_level


     COMMIT;

  END log_debug_message;

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

      log_debug_message(2, 'In get_entity_id ');
      log_debug_message(3, 'p_orig_system        := ' || p_orig_system);
      log_debug_message(3, 'p_orig_sys_reference := ' || p_orig_sys_reference);
      log_debug_message(3, 'p_owner_table_name   := ' || p_owner_table_name);

      SELECT owner_table_id
        INTO ln_owner_table_id
        FROM hz_orig_sys_references
       WHERE orig_system = p_orig_system
         AND orig_system_reference = p_orig_sys_reference
         AND owner_table_name = p_owner_table_name
         AND status = 'A';

      IF ln_owner_table_id IS NULL
      THEN
          RAISE NO_DATA_FOUND;
      END IF; -- ln_owner_table_id IS NULL

      x_owner_table_id    := ln_owner_table_id;
      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_data          := NULL;
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
         log_debug_message(1, x_msg_data );

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
         log_debug_message(1, x_msg_data );

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
         log_debug_message(1, x_msg_data );
   END get_entity_id;

   -- ===========================================================================
   -- Name             : DECIPHER
   -- Description      : This function provides the clear text password
   --                    for an encryted password using the decoder key
   --
   -- Parameters :      p_encrypted_string
   -- ===========================================================================

   FUNCTION decipher (p_encrypted_string IN VARCHAR2)
   RETURN VARCHAR2
   IS
      --  This function provides the clear text password for an encryted password
      --  using the decoder key
      --
      --  #param 1 p_encrypted_string       Encrypted password string of web user

      lv_encrypted_string   VARCHAR2 (100); -- := '4QPI6SN';
      lv_decrypted_string   VARCHAR2 (100);
      lv_clear_text         VARCHAR2 (100);
      ln_i                  PLS_INTEGER    := 1;
      lv_length             PLS_INTEGER;
   BEGIN

      lv_clear_text := TRANSLATE ( p_encrypted_string
                                 , 'QGTZ5JO7PAF03RDUH84LVB9E2MXI6SNYKW1C'
                                 , 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      RETURN lv_clear_text;
   END decipher;

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

      log_debug_message(2, 'In get_contact_id ');
      log_debug_message(3, 'p_orig_system        := ' || p_orig_system);
      log_debug_message(3, 'Contact OSR          := ' || p_cust_acct_cnt_osr );

      get_entity_id ( p_orig_system        => p_orig_system
                    , p_orig_sys_reference => p_cust_acct_cnt_osr
                    , p_owner_table_name   => 'HZ_ORG_CONTACTS'
                    , x_owner_table_id     => ln_org_contact_id
                    , x_return_status      => x_return_status
                    , x_msg_count          => x_msg_count
                    , x_msg_data           => x_msg_data
                    );

      log_debug_message(3, 'Contact ID '|| ln_org_contact_id );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      FOR lc_fetch_rel_party_id_rec IN c_fetch_rel_party_id_cur (ln_org_contact_id)
      LOOP
         x_party_id := lc_fetch_rel_party_id_rec.party_id;
         EXIT;
      END LOOP;

      log_debug_message(3, 'Relationship Party ID: '|| x_party_id );

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
         log_debug_message(1,x_msg_data);

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
   -- Name             : get_bill_to_site_id
   -- Description      : Get the bill to site for a specified account
   --                    site
   --
   --
   -- Parameters :     p_cust_acct_id
   --                  p_ship_to_cust_acct_site_id
   --                  x_bill_to_cust_acct_site_id
   --                  x_bill_to_osr
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE get_bill_to_site_id(
      p_cust_acct_id                    IN            NUMBER
    , p_ship_to_cust_acct_site_id       IN            NUMBER
    , x_bill_to_cust_acct_site_id       OUT           NUMBER
    , x_bill_to_osr                     OUT NOCOPY    VARCHAR2
    , x_return_status                   OUT NOCOPY    VARCHAR2
    , x_msg_count                       OUT           NUMBER
    , x_msg_data                        OUT NOCOPY    VARCHAR2
   )
   IS
     lv_billto_orig_sys_ref   hz_cust_site_uses_all.orig_system_reference%TYPE;
     ln_bill_to_site_use_id   hz_cust_site_uses_all.bill_to_site_use_id%TYPE;
   BEGIN

      x_msg_count         := 0;

      log_debug_message(2, 'In get_bill_to_site_id ');
      log_debug_message(3, 'p_cust_acct_id                   := ' || p_cust_acct_id);
      log_debug_message(3, 'p_ship_to_cust_acct_site_id OSR  := ' || p_ship_to_cust_acct_site_id );

      SELECT orig_system_reference,
             bill_to_site_use_id
      INTO   lv_billto_orig_sys_ref,
             ln_bill_to_site_use_id
      FROM   hz_cust_site_uses_all
      WHERE  cust_acct_site_id = p_ship_to_cust_acct_site_id
      AND    site_use_code = 'SHIP_TO';

      log_debug_message(3, ' Bill to Site Use ID : ' || ln_bill_to_site_use_id);

      IF ln_bill_to_site_use_id IS NOT NULL
      THEN
         log_debug_message(2, 'Get Bill To Associated with Ship To Record' );

         SELECT cust_acct_site_id
         INTO   x_bill_to_cust_acct_site_id
         FROM   hz_cust_site_uses_all
         WHERE  site_use_id = ln_bill_to_site_use_id;

      ELSE
         log_debug_message(2, 'Get Default Bill To Record' );

         SELECT hcas.cust_acct_site_id,
                hcas.orig_system_reference
         INTO   x_bill_to_cust_acct_site_id,
                x_bill_to_osr
         FROM   hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcasu
         WHERE  hcas.cust_account_id = p_cust_acct_id
         AND    hcas.cust_acct_site_id = hcasu.cust_acct_site_id
         AND    hcasu.primary_flag = 'Y'
         AND    hcasu.site_use_code = 'BILL_TO';

      END IF; -- ln_bill_to_site_use_id IS NOT NULL

      log_debug_message(3, ' Bill to Site ID : ' || x_bill_to_cust_acct_site_id);

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_bill_to_site_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
   END get_bill_to_site_id;


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

      log_debug_message(3, ' In get_account_org (1)' );
      log_debug_message(3, ' p_cust_acct_id   : ' || p_cust_acct_id );
      log_debug_message(3, ' p_acct_site_id   : ' || p_acct_site_id );
      log_debug_message(3, ' p_org_contact_id : ' || p_org_contact_id );

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
         fnd_message.set_token ('FUNCTION_NAME', 'get_account_org (1)');
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
      log_debug_message(3, ' In get_account_org (2)' );
      log_debug_message(3, ' px_org_id   : ' || px_org_id );

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
   PROCEDURE save_bill_to_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_ship_to_acct_site_id        IN             NUMBER
                                       , p_bill_to_acct_site_id        IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                               )
   AS

      l_role_resp_obj                hz_role_responsibility_obj;
      l_role_rec_type                HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
      l_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;

      ln_cust_acct_roles_party_id    NUMBER;
      ln_get_responsibility_id       NUMBER;
      ln_object_version_number       NUMBER := 1;
      ln_acct_role_id                NUMBER;
      l_role_id                      NUMBER;
      ln_responsibility_id           NUMBER;
      ln_role_id                     NUMBER;

      CURSOR  c_get_cust_account_role_cur ( p_cust_account_id      NUMBER
                                          , p_bill_to_acct_site_id NUMBER
                                          , p_cust_acct_cnt_osr    VARCHAR2)
      IS
         SELECT  cust_account_role_id, party_id, object_version_number
         FROM    hz_cust_account_roles
         WHERE   cust_acct_site_id = p_bill_to_acct_site_id
         AND     orig_system_reference=p_cust_acct_cnt_osr;

      CURSOR c_get_role_responsibility_cur(p_acct_role_id in NUMBER)
      IS
         SELECT  responsibility_id, object_version_number
         FROM    hz_role_responsibility
         WHERE   cust_account_role_id = p_acct_role_id
         AND     responsibility_type IN ( g_user_role, g_revoked_user_role);

      le_api_error              EXCEPTION;
      le_bo_api_error           EXCEPTION;

   BEGIN
      x_msg_count := 0;

      log_debug_message(2, 'In save_bill_to_contact_role');

      log_debug_message(3, 'P_ACTION                           : ' || p_action);
      log_debug_message(3, 'P_ORIG_SYSTEM                      : ' || p_orig_system);
      log_debug_message(3, 'P_CUST_ACCT_CNT_OSR                : ' || p_cust_acct_cnt_osr);
      log_debug_message(3, 'P_CUST_ACCOUNT_ID                  : ' || p_cust_account_id);
      log_debug_message(3, 'P_SHIP_TO_ACCT_SITE_ID             : ' || p_ship_to_acct_site_id);
      log_debug_message(3, 'P_BILL_TO_ACCT_SITE_ID             : ' || p_bill_to_acct_site_id);
      log_debug_message(3, 'P_PARTY_ID                         : ' || p_party_id);

      OPEN   c_get_cust_account_role_cur ( p_cust_account_id
                                         , p_bill_to_acct_site_id
                                         , p_cust_acct_cnt_osr);
      FETCH  c_get_cust_account_role_cur INTO ln_acct_role_id, ln_cust_acct_roles_party_id, ln_object_version_number;
      CLOSE  c_get_cust_account_role_cur;

      IF ln_cust_acct_roles_party_id IS NOT NULL
      THEN
         log_debug_message(2, 'Account role Exists');
         l_role_rec_type.cust_account_role_id  := ln_acct_role_id;
         l_role_rec_type.cust_account_id       := p_cust_account_id;
         l_role_rec_type.primary_flag          := 'N';
         l_role_rec_type.role_type             := 'CONTACT';
         -- l_role_rec_type.created_by_module     := 'AOPS SYNC';

         /*
         IF p_action ='D'
         THEN
             l_role_rec_type.status                := 'I';
         ELSE
             l_role_rec_type.party_id              := p_party_id;
             l_role_rec_type.status                := 'A';
         END IF; -- p_action ='D'
         */
             l_role_rec_type.party_id              := p_party_id;
             l_role_rec_type.status                := 'A';

         log_debug_message(2, 'Before update account role');
         log_debug_message(3, 'l_role_rec_type.status : ' || l_role_rec_type.status);

         hz_cust_account_role_v2pub.update_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_role_rec_type
                     , p_object_version_number          => ln_object_version_number
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );

         log_debug_message(2, 'After update account role, here is the status: ' || x_return_status);
         log_debug_message(3, 'Role id: '|| ln_acct_role_id);
         log_debug_message(3, 'Contact OSR: ' || p_cust_acct_cnt_osr);

         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_bo_api_error;
         END IF;

         OPEN   c_get_role_responsibility_cur (ln_acct_role_id);
         FETCH  c_get_role_responsibility_cur INTO ln_get_responsibility_id, ln_object_version_number;
         CLOSE  c_get_role_responsibility_cur;

         log_debug_message(3, 'Responsibility id: ' || ln_get_responsibility_id);

         l_role_responsibility_rec                       := NULL;
         l_role_responsibility_rec.cust_account_role_id  := l_role_id;
         -- l_role_responsibility_rec.responsibility_id     := ln_get_responsibility_id;
         l_role_responsibility_rec.primary_flag          := 'Y';
         -- l_role_responsibility_rec.created_by_module     := 'AOPS SYNC';

         IF p_action ='D'
         THEN
             l_role_responsibility_rec.responsibility_type   := g_revoked_user_role;
         ELSE
             l_role_responsibility_rec.responsibility_type   := g_user_role;
         END IF; -- p_action ='D'

         log_debug_message(2, 'Before update role resp');
         log_debug_message(3, 'Role Responsibility - Type : ' || l_role_responsibility_rec.responsibility_type);

         IF ln_get_responsibility_id IS NOT NULL
         THEN

            log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility role resp');

            l_role_responsibility_rec.responsibility_id     := ln_get_responsibility_id;

            HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  p_object_version_number    => ln_object_version_number
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;

         ELSE
            log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility role resp');

            l_role_responsibility_rec.created_by_module     := 'AOPS SYNC';

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  x_responsibility_id        => ln_get_responsibility_id
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;
         END IF; -- ln_get_responsibility_id IS NOT NULL


         log_debug_message(2, 'After update role resp');
      ELSE
         IF p_action <> 'D'
         THEN
            l_role_rec_type.party_id              := p_party_id;
            l_role_rec_type.cust_account_id       := p_cust_account_id;
            l_role_rec_type.cust_acct_site_id     := p_ship_to_acct_site_id;
            l_role_rec_type.primary_flag          := 'N';
            l_role_rec_type.role_type             := 'CONTACT';
            l_role_rec_type.orig_system_reference := p_cust_acct_cnt_osr;
            l_role_rec_type.orig_system           := p_orig_system;
            l_role_rec_type.status                := 'A';
            l_role_rec_type.created_by_module     := 'AOPS SYNC';
   
            log_debug_message(2, 'Before create account role');
   
            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_ROLE_REC_TYPE
                     , x_cust_account_role_id           => l_role_id
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );
   
            log_debug_message(3, 'Role id : ' || l_role_id);
            log_debug_message(2, 'After create account role');
   
            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;
   
            log_debug_message(3, 'Role id : ' || l_role_id);
            log_debug_message(2, 'After create account role');
   
            l_role_responsibility_rec                       := NULL;
            l_role_responsibility_rec.cust_account_role_id  := l_role_id;
            l_role_responsibility_rec.responsibility_type   := g_user_role;
            l_role_responsibility_rec.primary_flag          := 'Y';
            l_role_responsibility_rec.created_by_module     := 'AOPS SYNC';
   
            log_debug_message(2, 'Before create role resp');

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  x_responsibility_id        => ln_responsibility_id
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_api_error;
            END IF;

            log_debug_message(2, 'After create role resp');
         END IF; -- p_action <> 'D'
      END IF; -- ln_cust_acct_roles_party_id IS NOT NULL

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN le_bo_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_bill_to_contact_role');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);

   END save_bill_to_contact_role;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR2
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       )
   AS

      l_role_resp_obj                hz_role_responsibility_obj;
      l_role_rec_type                HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
      l_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;

      ln_cust_acct_roles_party_id    NUMBER;
      ln_get_responsibility_id       NUMBER;
      ln_object_version_number       NUMBER := 1;
      ln_acct_role_id                NUMBER;
      l_role_id                      NUMBER;
      ln_responsibility_id           NUMBER;
      ln_role_id                     NUMBER;

      CURSOR  c_get_cust_account_role_cur ( p_cust_account_id      NUMBER
                                          , p_cust_acct_cnt_osr    VARCHAR2)
      IS
         SELECT  cust_account_role_id, party_id, object_version_number
         FROM    hz_cust_account_roles
         WHERE   cust_account_id = p_cust_account_id
         AND     cust_acct_site_id IS NULL
         AND     orig_system_reference=p_cust_acct_cnt_osr;

      CURSOR c_get_role_responsibility_cur(p_acct_role_id in NUMBER)
      IS
         SELECT  responsibility_id, object_version_number
         FROM    hz_role_responsibility
         WHERE   cust_account_role_id = p_acct_role_id
         AND     responsibility_type = g_user_role;

      le_api_error              EXCEPTION;
      le_bo_api_error           EXCEPTION;

   BEGIN
      x_msg_count := 0;

      log_debug_message(2, 'In save_account_contact_role');

      log_debug_message(3, 'P_ACTION                           : ' || p_action);
      log_debug_message(3, 'P_ORIG_SYSTEM                      : ' || p_orig_system);
      log_debug_message(3, 'P_CUST_ACCT_CNT_OSR                : ' || p_cust_acct_cnt_osr);
      log_debug_message(3, 'P_CUST_ACCOUNT_ID                  : ' || p_cust_account_id);
      log_debug_message(3, 'P_PARTY_ID                         : ' || p_party_id);

      OPEN   c_get_cust_account_role_cur ( p_cust_account_id, p_cust_acct_cnt_osr);
      FETCH  c_get_cust_account_role_cur INTO ln_acct_role_id, ln_cust_acct_roles_party_id, ln_object_version_number;
      CLOSE  c_get_cust_account_role_cur;

      IF ln_cust_acct_roles_party_id IS NOT NULL
      THEN
         log_debug_message(2, 'Account role Exists');
         l_role_rec_type.cust_account_role_id  := ln_acct_role_id;
         l_role_rec_type.cust_account_id       := p_cust_account_id;
         l_role_rec_type.primary_flag          := 'N';
         l_role_rec_type.role_type             := 'CONTACT';
         -- l_role_rec_type.created_by_module     := 'AOPS SYNC';

         /*
         IF p_action ='D'
         THEN
             l_role_rec_type.status                := 'I';
         ELSE
             l_role_rec_type.party_id              := p_party_id;
             l_role_rec_type.status                := 'A';
         END IF; -- p_action ='D'
         */

         l_role_rec_type.party_id              := p_party_id;
         l_role_rec_type.status                := 'A';

         log_debug_message(2, 'Before update account role');
         log_debug_message(3, 'l_role_rec_type.status : ' || l_role_rec_type.status);

         hz_cust_account_role_v2pub.update_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_role_rec_type
                     , p_object_version_number          => ln_object_version_number
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );

         log_debug_message(2, 'After update account role, here is the status: ' || x_return_status);
         log_debug_message(3, 'Role id: '|| ln_acct_role_id);
         log_debug_message(3, 'Contact OSR: ' || p_cust_acct_cnt_osr);

         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_bo_api_error;
         END IF;

         OPEN   c_get_role_responsibility_cur (ln_acct_role_id);
         FETCH  c_get_role_responsibility_cur INTO ln_get_responsibility_id, ln_object_version_number;
         CLOSE  c_get_role_responsibility_cur;

         log_debug_message(3, 'Responsibility id: ' || ln_get_responsibility_id);

         l_role_responsibility_rec                       := NULL;
         l_role_responsibility_rec.cust_account_role_id  := ln_acct_role_id;
         l_role_responsibility_rec.primary_flag          := 'Y';

         IF p_action ='D'
         THEN
             l_role_responsibility_rec.responsibility_type   := g_revoked_user_role;
         ELSE
             l_role_responsibility_rec.responsibility_type   := g_user_role;
         END IF; -- p_action ='D'

         log_debug_message(2, 'Before update role resp');
         log_debug_message(3, 'l_role_rec_type.status : ' || l_role_responsibility_rec.responsibility_type);

         IF ln_get_responsibility_id IS NOT NULL
         THEN

            log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility role resp');

            l_role_responsibility_rec.responsibility_id     := ln_get_responsibility_id;

            HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  p_object_version_number    => ln_object_version_number
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;

         ELSE
            log_debug_message(2, 'HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility role resp');

            l_role_responsibility_rec.created_by_module     := 'AOPS SYNC';

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  x_responsibility_id        => ln_get_responsibility_id
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;

         END IF; -- ln_get_responsibility_id IS NOT NULL

         log_debug_message(2, 'After role resp');

      ELSE
         IF p_action <> 'D'
         THEN
            l_role_rec_type.party_id              := p_party_id;
            l_role_rec_type.cust_account_id       := p_cust_account_id;
            l_role_rec_type.primary_flag          := 'N';
            l_role_rec_type.role_type             := 'CONTACT';
            l_role_rec_type.orig_system_reference := p_cust_acct_cnt_osr;
            l_role_rec_type.orig_system           := p_orig_system;
            l_role_rec_type.status                := 'A';
            l_role_rec_type.created_by_module     := 'AOPS SYNC';
   
            log_debug_message(2, 'Before create account role');
   
            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_ROLE_REC_TYPE
                     , x_cust_account_role_id           => l_role_id
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );
   
            log_debug_message(3, 'Role id : ' || l_role_id);
            log_debug_message(2, 'After create account role');
   
            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;
   
            log_debug_message(3, 'Role id : ' || l_role_id);
            log_debug_message(2, 'After create account role');
   
            l_role_responsibility_rec                       := NULL;
            l_role_responsibility_rec.cust_account_role_id  := l_role_id;
            l_role_responsibility_rec.responsibility_type   := g_user_role;
            l_role_responsibility_rec.primary_flag          := 'Y';
            l_role_responsibility_rec.created_by_module     := 'AOPS SYNC';
   
            log_debug_message(2, 'Before create role resp');
   
            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_responsibility_rec
                     ,  x_responsibility_id        => ln_responsibility_id
                     ,  x_return_status            => x_return_status
                     ,  x_msg_count                => x_msg_count
                     ,  x_msg_data                 => x_msg_data
                     );
   
            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_api_error;
            END IF;

            log_debug_message(2, 'After create role resp');
         END IF; -- p_action <> 'D'
      END IF; -- ln_cust_acct_roles_party_id IS NOT NULL

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN le_bo_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_account_contact_role');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);

   END save_account_contact_role;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_parent_obj                  IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                               )
   AS

      l_cust_acct_cnt_bo             hz_cust_acct_contact_bo;

      l_role_resp_obj                hz_role_responsibility_obj;

      l_cust_acct_cnt_id             NUMBER (10);
      l_cust_acct_cnt_os             VARCHAR2 (50);
      l_cust_acct_cnt_osr            VARCHAR2 (50);
      ln_parent_id                   NUMBER        := p_cust_account_id;
      lv_parent_obj                  VARCHAR2 (50) := p_parent_obj;
      lv_parent_os                   VARCHAR2 (50) := p_orig_system;
      lv_parent_osr                  VARCHAR2 (50) := p_cust_acct_osr;

      le_api_error              EXCEPTION;
      le_bo_api_error           EXCEPTION;

   BEGIN
      x_msg_count := 0;

      log_debug_message(2, 'In save_account_contact_role');
      log_debug_message(3, 'In p_action                      := ' || p_action                );
      log_debug_message(3, 'In p_parent_obj                  := ' || p_parent_obj            );
      log_debug_message(3, 'In p_orig_system                 := ' || p_orig_system           );
      log_debug_message(3, 'In p_cust_acct_osr               := ' || p_cust_acct_osr         );
      log_debug_message(3, 'In p_cust_acct_cnt_osr           := ' || p_cust_acct_cnt_osr     );
      log_debug_message(3, 'In p_cust_account_id             := ' || p_cust_account_id       );
      log_debug_message(3, 'In p_party_id                    := ' || p_party_id              );

      l_cust_acct_cnt_bo := HZ_CUST_ACCT_CONTACT_BO.create_object
                                 ( p_orig_system                => p_orig_system
                                 , p_orig_system_reference      => p_cust_acct_cnt_osr
                                 , p_contact_person_id          => p_party_id
                                 , p_relationship_code          => 'CONTACT_OF'
                                 , p_relationship_type          => 'CONTACT'
                                 , p_role_type                  => 'CONTACT'
                                 , p_status                     => 'A'
                                 );

      IF p_action IN ('C', 'U')
      THEN

         log_debug_message(2, 'Add Self Service Role');

         l_role_resp_obj := hz_role_responsibility_obj.create_object
                                    ( p_responsibility_type      => g_user_role
                                    , p_primary_flag             => 'N'
                                    );

         l_cust_acct_cnt_bo.contact_role_objs.EXTEND;
         l_cust_acct_cnt_bo.contact_role_objs (1) := l_role_resp_obj;
      ELSE
         log_debug_message(2, 'Remove Self Service Role');
      END IF; -- p_action IN ('C', 'U')

      log_debug_message(2, 'Before Call of HZ_CUST_ACCT_CONTACT_BO_PUB.save_cust_acct_contact_bo');

      hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo
                                 ( p_init_msg_list              => fnd_api.g_true
                                 , p_validate_bo_flag           => fnd_api.g_false
                                 , p_cust_acct_contact_obj      => l_cust_acct_cnt_bo
                                 , p_created_by_module          => 'AOPS SYNC'
                                 , x_return_status              => x_return_status
                                 , x_msg_count                  => x_msg_count
                                 , x_msg_data                   => x_msg_data
                                 , x_cust_acct_contact_id       => l_cust_acct_cnt_id
                                 , x_cust_acct_contact_os       => l_cust_acct_cnt_os
                                 , x_cust_acct_contact_osr      => l_cust_acct_cnt_osr
                                 , px_parent_id                 => ln_parent_id
                                 , px_parent_os                 => lv_parent_os
                                 , px_parent_osr                => lv_parent_osr
                                 , px_parent_obj_type           => lv_parent_obj -- 'CUST_ACCT'
                                 );

      IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
      THEN
         raise le_api_error;
      END IF;

      log_debug_message(3, 'Parent OSR  : '||lv_parent_osr);
      log_debug_message(3, 'Parent type : '||lv_parent_obj);
      log_debug_message(3, 'Parent ID   : '||ln_parent_id);

      x_return_status := FND_API.G_RET_STS_SUCCESS;
      x_msg_count     := 0;
      x_msg_data      := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN le_bo_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_account_contact_role');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);

   END save_account_contact_role;

   -- ===========================================================================
   -- Name             : SAVE_ROLE_RESP
   -- Description      : This procedure validates the keys passed from
   --                    the legacy system (AOPS) and when a matching
   --                    account site and contact is found in Oracle
   --                    EBS will set the contact at bill to site for
   --                    the incoming ship to and inserts the user if it
   --                    is a create and updates the user when modify in
   --                    the xx_external_users tables. This procedue is
   --                    called from SaveiReceivables BPEL process
   --
   -- Parameters :      p_orig_system
   --                   p_cust_acct_cnt_osr
   --                   p_cust_acct_site_osr
   --                   p_action
   --                   p_permission_flag
   --                   x_party_id
   --                   x_return_status
   --                   x_msg_count
   --                   x_msg_data
   --
   -- ===========================================================================
   PROCEDURE save_role_resp ( p_orig_system                 IN            VARCHAR2
                            , p_cust_acct_osr               IN            VARCHAR2
                            , p_cust_acct_cnt_osr           IN            VARCHAR2
                            , p_cust_acct_site_osr          IN            VARCHAR2
                            , p_record_type                 IN            VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN            VARCHAR2
                            , p_action                      IN            VARCHAR2
                            , x_cust_account_id             OUT           NUMBER
                            , x_ship_to_acct_site_id        OUT           NUMBER
                            , x_bill_to_acct_site_id        OUT           NUMBER
                            , x_party_id                    OUT           NUMBER
                            , x_return_status               OUT           VARCHAR2
                            , x_messages                    OUT NOCOPY    HZ_MESSAGE_OBJ_TBL
                            )
   IS
     l_msg_count            NUMBER;
     l_msg_data             VARCHAR2(4000);
   BEGIN

      save_role_resp( p_orig_system           => p_orig_system
                    , p_cust_acct_osr         => p_cust_acct_osr
                    , p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
                    , p_cust_acct_site_osr    => p_cust_acct_site_osr
                    , p_record_type           => p_record_type
                    , p_permission_flag       => p_permission_flag
                    , p_action                => p_action
                    , x_cust_account_id       => x_cust_account_id
                    , x_ship_to_acct_site_id  => x_ship_to_acct_site_id
                    , x_bill_to_acct_site_id  => x_bill_to_acct_site_id
                    , x_party_id              => x_party_id
                    , x_return_status         => x_return_status
                    , x_msg_count             => l_msg_count
                    , x_msg_data              => l_msg_data );

      x_messages := get_messages ( p_return_status   => x_return_status
                                 , p_msg_count       => l_msg_count
                                 , p_msg_data        => l_msg_data);

   END save_role_resp;

   -- ===========================================================================
   -- Name             : SAVE_ROLE_RESP
   -- Description      : This procedure validates the keys passed from
   --                    the legacy system (AOPS) and when a matching
   --                    account site and contact is found in Oracle
   --                    EBS will set the contact at bill to site for
   --                    the incoming ship to and inserts the user if it
   --                    is a create and updates the user when modify in
   --                    the xx_external_users tables. This procedue is
   --                    called from SaveiReceivables BPEL process
   --
   -- Parameters :      p_orig_system
   --                   p_cust_acct_cnt_osr
   --                   p_cust_acct_site_osr
   --                   p_action
   --                   p_permission_flag
   --                   x_party_id
   --                   x_return_status
   --                   x_msg_count
   --                   x_msg_data
   --
   -- ===========================================================================
   PROCEDURE save_role_resp ( p_orig_system                 IN             VARCHAR2
                            , p_cust_acct_osr               IN             VARCHAR2
                            , p_cust_acct_cnt_osr           IN             VARCHAR2
                            , p_cust_acct_site_osr          IN             VARCHAR2
                            , p_record_type                 IN             VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN             VARCHAR2
                            , p_action                      IN             VARCHAR2
                            , x_cust_account_id             OUT            NUMBER
                            , x_ship_to_acct_site_id        OUT            NUMBER
                            , x_bill_to_acct_site_id        OUT            NUMBER
                            , x_party_id                    OUT            NUMBER
                            , x_return_status               OUT NOCOPY     VARCHAR2
                            , x_msg_count                   OUT            NUMBER
                            , x_msg_data                    OUT NOCOPY     VARCHAR2
                            )
   IS
      --  --------------------------------------------------------------------------------------
      --  save_role_resp validates the keys passed from the legacy system (AOPS)
      --  and when a matching account site and contact is found in Oracle EBS will
      --  set the contact at bill to site for the incoming ship to and inserts the
      --  user if it is a create and updates the user when modify in the
      --  xx_external_users tables. This procedure is called from SaveiReceivables
      --  BPEL process
      --
      --  #param 1 p_orig_system   Legacy system identifier
      --  #param 2 p_cust_acct_cnt_osr  AOPS unique ID of bsd web contact
      --  #param 3 p_cust_acct_site_osr AOPS unique ID of account site
      --  #param 4 p_permission_flag    Flag to ID if contact relationship
      --                                should tie to account/account site
      --  #param 5 p_action             CREATE ( 'C' )
      --  #param 6 x_party_id           return party id of the relationship
      --  #param 7 x_retcode            return success or failure
      --  #param 8 x_msg_count          return the number of errors
      --  #param 9 x_msg_data           return the error messages
      --  --------------------------------------------------------------------------------------

      l_cust_acct_cnt_bo             hz_cust_acct_contact_bo;
      l_role_resp_obj                hz_role_responsibility_obj;
      l_role_rec_type                HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
      l_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;

      l_cust_acct_cnt_id             NUMBER (10);
      l_cust_acct_cnt_os             VARCHAR2 (50);
      l_cust_acct_cnt_osr            VARCHAR2 (50);
      l_cust_acct_role_rec           HZ_CUST_ACCOUNT_ROLE_V2PUB.cust_account_role_rec_type;
      l_cust_acct_site_osr           VARCHAR2 (50);
      lc_permission_flag             VARCHAR2(1);
      ln_acct_role_id                NUMBER;
      ln_parent_id                   NUMBER;
      lv_billto_orig_sys_ref         VARCHAR2 (30);
      lv_parent_obj                  VARCHAR2 (50);
      lv_parent_os                   VARCHAR2 (50) := p_orig_system;
      lv_parent_osr                  VARCHAR2 (50) := p_cust_acct_osr;

      l_bill_to_action               VARCHAR(30);

      -- l_contact_end_date             DATE;

      -- Exceptions
      le_api_error              EXCEPTION;
      le_role_api_error         EXCEPTION;
      le_resp_api_error         EXCEPTION;
      le_bo_api_error           EXCEPTION;
      le_contact_not_found      EXCEPTION;
      le_relationship_not_found EXCEPTION;
      le_setup_error            EXCEPTION;

   BEGIN

      enable_debug;

      FND_MSG_PUB.initialize;

      log_debug_message(2, '***** In save_role_resp procedure ***** ' );
      log_debug_message(3, 'In p_orig_system                    := ' || p_orig_system                );
      log_debug_message(3, 'In p_cust_acct_osr                  := ' || p_cust_acct_osr              );
      log_debug_message(3, 'In p_cust_acct_cnt_osr              := ' || p_cust_acct_cnt_osr          );
      log_debug_message(3, 'In p_cust_acct_site_osr             := ' || p_cust_acct_site_osr         );
      log_debug_message(3, 'In p_record_type                    := ' || p_record_type                );
      log_debug_message(3, 'In p_permission_flag                := ' || p_permission_flag            );
      log_debug_message(3, 'In p_action                         := ' || p_action                     );

      -- ----------------------------------------------------------------------
      -- Validate the p_orig_system code
      -- ----------------------------------------------------------------------
      IF p_orig_system IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
         fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
         fnd_message.set_token ('PARAMETER_NAME', 'p_orig_system');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; --  p_orig_system IS NULL

      -- ----------------------------------------------------------------------
      -- Validate the p_cust_acct_cnt_osr
      -- ----------------------------------------------------------------------
      IF p_cust_acct_cnt_osr IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
         fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
         fnd_message.set_token ('PARAMETER_NAME', 'p_cust_acct_cnt_osr');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; --  p_orig_system IS NULL

      -- ----------------------------------------------------------------------
      -- Validate the p_cust_acct_osr
      -- ----------------------------------------------------------------------
      IF p_cust_acct_osr IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
         fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
         fnd_message.set_token ('PARAMETER_NAME', 'p_cust_acct_osr');
         -- fnd_message.add;
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; --  p_orig_system IS NULL


      IF NVL(x_return_status,FND_API.G_RET_STS_ERROR) <> FND_API.G_RET_STS_ERROR
      THEN
         RAISE le_api_error;
      END IF; -- NVL(x_return_status,FND_API.G_RET_STS_ERROR) <> FND_API.G_RET_STS_ERROR

      -- ----------------------------------------------------------------------
      -- Get the Party Id, Party relationShip ID for the Contact
      -- This function assumes that the Org Contact has been created earlier
      -- If Org Contact Does not exist then, return an error.
      -- ----------------------------------------------------------------------
      get_contact_id ( p_orig_system          => p_orig_system
                     , p_cust_acct_cnt_osr    => p_cust_acct_cnt_osr
                     , x_party_id             => x_party_id
                     , x_return_status        => x_return_status
                     , x_msg_count            => x_msg_count
                     , x_msg_data             => x_msg_data
                     );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      -- -------------------------------------------------------------------
      -- Get the Account ID
      -- -------------------------------------------------------------------
      get_entity_id ( p_orig_system        => p_orig_system
                    , p_orig_sys_reference => p_cust_acct_osr
                    , p_owner_table_name   => 'HZ_CUST_ACCOUNTS'
                    , x_owner_table_id     => x_cust_account_id
                    , x_return_status      => x_return_status
                    , x_msg_count          => x_msg_count
                    , x_msg_data           => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      log_debug_message(3, 'Cust Account ID : ' || x_cust_account_id );

      -- ----------------------------------------------------------------------
      -- Based on new Permission Level Check if Contact is associate at
      -- CUST_ACCT or CUST_ACCT_SITE Level
      -- ----------------------------------------------------------------------
      get_contact_level ( p_system_name     => p_orig_system
                        , p_permission_flag => p_permission_flag
                        , x_contact_level   => lv_parent_obj
                        , x_return_status   => x_return_status
                        , x_msg_count       => x_msg_count
                        , x_msg_data        => x_msg_data
                        );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      log_debug_message(3, 'Permission flag : ' || p_permission_flag);
      log_debug_message(3, 'Action          : ' || p_action );
      log_debug_message(3, 'Contact Level   : ' || lv_parent_obj );


      IF (lv_parent_obj = 'CUST_ACCT_SITE')
      THEN
         IF p_record_type = 'ST'
         THEN
            -- lv_parent_obj := 'CUST_ACCT_SITE';
            -- lv_cust_acct_cnt_os    := NVL(p_orig_system, 'A0');
            -- lv_parent_os           := NULL;
            -- lv_parent_osr          := NULL;

            -- -------------------------------------------------------------------
            -- Get the Cust_Account_Site Information
            -- -------------------------------------------------------------------
            get_entity_id ( p_orig_system        =>  p_orig_system
                          , p_orig_sys_reference =>  p_cust_acct_site_osr
                          , p_owner_table_name   =>  'HZ_CUST_ACCT_SITES_ALL'
                          , x_owner_table_id     =>  x_ship_to_acct_site_id
                          , x_return_status      =>  x_return_status
                          , x_msg_count          =>  x_msg_count
                          , x_msg_data           =>  x_msg_data
                          );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               raise le_api_error;
            END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            log_debug_message(3, 'Ship To Account Site ID: ' || x_ship_to_acct_site_id );


            get_bill_to_site_id( p_cust_acct_id                =>  x_cust_account_id
                               , p_ship_to_cust_acct_site_id   =>  x_ship_to_acct_site_id
                               , x_bill_to_cust_acct_site_id   =>  x_bill_to_acct_site_id
                               , x_bill_to_osr                 =>  lv_billto_orig_sys_ref
                               , x_return_status               =>  x_return_status
                               , x_msg_count                   =>  x_msg_count
                               , x_msg_data                    =>  x_msg_data
                               );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               raise le_api_error;
            END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            log_debug_message(3, 'Bill To Account Site ID = ' || x_bill_to_acct_site_id );

            -- ----------------------------------------------------
            -- Insert / Delete the Ship to and Bill TO Information
            -- ----------------------------------------------------
            save_ship_to_contact ( p_operation                 => p_action
                                 , p_orig_system               => p_orig_system
                                 , p_ship_to_acct_site_id      => x_ship_to_acct_site_id
                                 , p_ship_to_acct_site_osr     => p_cust_acct_site_osr
                                 , p_bill_to_acct_site_id      => x_bill_to_acct_site_id
                                 , p_bill_to_acct_site_osr     => lv_billto_orig_sys_ref
                                 , p_contact_party_id          => x_party_id
                                 , p_contact_party_osr         => p_cust_acct_cnt_osr
                                 , x_bill_to_operation         => l_bill_to_action
                                 , x_return_status             => x_return_status
                                 , x_msg_count                 => x_msg_count
                                 , x_msg_data                  => x_msg_data
                                 );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               raise le_api_error;
            END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            log_debug_message(3, 'l_bill_to_action: ' || l_bill_to_action );

            IF l_bill_to_action IS NOT NULL
            THEN

               save_bill_to_contact_role ( p_action                      => l_bill_to_action
                                         , p_orig_system                 => p_orig_system
                                         , p_cust_acct_cnt_osr           => p_cust_acct_cnt_osr
                                         , p_cust_account_id             => x_cust_account_id
                                         , p_ship_to_acct_site_id        => x_ship_to_acct_site_id
                                         , p_bill_to_acct_site_id        => x_bill_to_acct_site_id
                                         , p_party_id                    => x_party_id
                                         , x_return_status               => x_return_status
                                         , x_msg_count                   => x_msg_count
                                         , x_msg_data                    => x_msg_data
                                         );

               IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
               THEN
                  raise le_api_error;
               END IF;

               -- -------------------------------------------------------------------------
               -- if a ST Record with Permission of C/X/L is received, the contact role
               -- at the account level should be deleted
               -- AKS: Should check if role exsists at account level before calling this function
               -- --------------------------------------------------------------------------
               save_account_contact_role ( p_action                => 'D'
                                         , p_orig_system           => p_orig_system
                                         , p_cust_acct_osr         => p_cust_acct_osr
                                         , p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
                                         , p_cust_account_id       => x_cust_account_id
                                         , p_party_id              => x_party_id
                                         , x_return_status         => x_return_status
                                         , x_msg_count             => x_msg_count
                                         , x_msg_data              => x_msg_data
                                         );

               IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
               THEN
                  raise le_api_error;
               END IF;

            END IF;-- l_bill_to_action IS NOT NULL
         END IF; -- p_record_type = 'ST'

      ELSIF (lv_parent_obj = 'CUST_ACCT')
      THEN
         save_account_contact_role ( p_action                => p_action
                                   , p_orig_system           => p_orig_system
                                   , p_cust_acct_osr         => p_cust_acct_osr
                                   , p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
                                   , p_cust_account_id       => x_cust_account_id
                                   , p_party_id              => x_party_id
                                   , x_return_status         => x_return_status
                                   , x_msg_count             => x_msg_count
                                   , x_msg_data              => x_msg_data
                                   );

         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_api_error;
         END IF;
      ELSE
         raise le_api_error;
      END IF; -- (lv_parent_obj = 'CUST_ACCT_SITE')

      x_return_status := FND_API.G_RET_STS_SUCCESS;
      x_msg_count     := 0;
      x_msg_data      := NULL;

      disable_debug;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN le_bo_api_error THEN
         log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);
   END save_role_resp;

   -- +===================================================================+
   -- | Name        :  save_acct_site_ext                             |
   -- | Description :  This procedure is used to construct the table      |
   -- |                Structure used by the extensiable api's.           |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters  :                                                     |
   -- | Returns     :                                                     |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE save_acct_site_ext ( p_operation                 IN         VARCHAR2
                                , p_orig_system               IN         VARCHAR2
                                , p_ship_to_acct_site_id      IN         NUMBER
                                , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_bill_to_acct_site_id      IN         NUMBER
                                , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_contact_party_id          IN         NUMBER
                                , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                , x_return_status             OUT NOCOPY VARCHAR2
                                , x_msg_count                 OUT        NUMBER
                                , x_msg_data                  OUT NOCOPY VARCHAR2
                                )
   IS

      --Retrieve Attribute Group id based on the Attribute Group code and
      CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
      IS
         SELECT  attr_group_id
         FROM    ego_fnd_dsc_flx_ctx_ext
         WHERE   descriptive_flexfield_name = p_flexfleid_name
         AND     descriptive_flex_context_code = p_context_code;


      CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
      IS
         SELECT *
         FROM   FND_DESCR_FLEX_COLUMN_USAGES
         WHERE  DESCRIPTIVE_FLEXFIELD_NAME=p_flexfleid_name
         AND    DESCRIPTIVE_FLEX_CONTEXT_CODE=p_context_code
         AND    ENABLED_FLAG ='Y';

      TYPE ext_attr_name_typ IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
      lc_ext_attr_name        ext_attr_name_typ;

      lc_user_row_table           EGO_USER_ATTR_ROW_TABLE := EGO_USER_ATTR_ROW_TABLE();
      lc_user_data_table          EGO_USER_ATTR_DATA_TABLE :=EGO_USER_ATTR_DATA_TABLE();

      lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ :=
                                  EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
      lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:=
                                  EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);

      ln_counter                  PLS_INTEGER   := 1;
      l_attr_group_id             NUMBER;
      l_attr_name                 VARCHAR2(50)  := 'XX_CDH_CUST_ACCT_SITE';
      l_attr_group_name           VARCHAR2(60)  := 'WEBCONTACTS';
      l_failed_row_id_list        VARCHAR2 (1000);
      l_errorcode                 VARCHAR2 (100);
      le_api_error                EXCEPTION;




   BEGIN

      log_debug_message(2, 'In save_acct_site_ext' );
      log_debug_message(3, 'In p_orig_system                 := ' || p_orig_system                 );
      log_debug_message(3, 'In p_ship_to_acct_site_id        := ' || p_ship_to_acct_site_id        );
      log_debug_message(3, 'In p_ship_to_acct_site_osr       := ' || p_ship_to_acct_site_osr       );
      log_debug_message(3, 'In p_bill_to_acct_site_id        := ' || p_bill_to_acct_site_id        );
      log_debug_message(3, 'In p_bill_to_acct_site_osr       := ' || p_bill_to_acct_site_osr       );
      log_debug_message(3, 'In p_contact_party_id            := ' || p_contact_party_id            );
      log_debug_message(3, 'In p_contact_party_osr           := ' || p_contact_party_osr           );

      OPEN   c_ego_attr_grp_id (l_attr_name,l_attr_group_name);
      FETCH  c_ego_attr_grp_id INTO l_attr_group_id;
      CLOSE  c_ego_attr_grp_id;

      IF l_attr_group_id IS NULL
      THEN
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_003_MISSING_SETUP');
         fnd_message.set_token ('SETUP_NAME', 'CDH Attribute Group XX_CDH_CUST_ACCT_SITE');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         RAISE le_api_error;
      END IF; -- l_attr_group_id IS NULL THEN

      lc_user_row_table.extend;
      lc_user_row_table(1)                    := lc_row_temp_obj;
      lc_user_row_table(1).Row_identifier     := p_ship_to_acct_site_id;
      lc_user_row_table(1).Attr_group_id      := l_attr_group_id;

      IF p_operation = 'D'
      THEN
         lc_user_row_table(1).transaction_type   := EGO_USER_ATTRS_DATA_PVT.G_DELETE_MODE;
      ELSE
         lc_user_row_table(1).transaction_type   := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;
      END IF; -- p_operation = 'D'

      OPEN   c_ext_attr_name (l_attr_name,l_attr_group_name);
      FETCH  c_ext_attr_name bulk collect into lc_ext_attr_name;
      CLOSE  c_ext_attr_name;


      -- Bill To Orig System Reference       -------- C_EXT_ATTR19
      -- Contact Party Orig System Reference -------- C_EXT_ATTR20
      -- Contact Party ID                    -------- N_EXT_ATTR1
      -- Bill To Account Site ID             -------- N_EXT_ATTR2

      FOR ln_counter IN 1 .. lc_ext_attr_name.COUNT
      LOOP

         lc_user_data_table.extend;
         lc_user_data_table(ln_counter)                 := lc_data_temp_obj;
         lc_user_data_table(ln_counter).ROW_IDENTIFIER  := p_ship_to_acct_site_id;
         lc_user_data_table(ln_counter).ATTR_NAME       := lc_ext_attr_name(ln_counter).END_USER_COLUMN_NAME;

         CASE lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME
              WHEN 'C_EXT_ATTR19'
              THEN
                  -- WEBCONTACTS_BILL_TO_OSR
                  lc_user_data_table(ln_counter).ATTR_VALUE_STR := p_bill_to_acct_site_osr;
              WHEN 'C_EXT_ATTR20'
              THEN
                  -- WEBCONTACTS_CONTACT_PARTY_OSR
                  lc_user_data_table(ln_counter).ATTR_VALUE_STR := p_contact_party_osr;
              WHEN 'N_EXT_ATTR1'
              THEN
                  -- WEBCONTACTS_CONTACT_PARTY_ID
                  lc_user_data_table(ln_counter).ATTR_VALUE_NUM := p_bill_to_acct_site_id;
              WHEN 'N_EXT_ATTR2'
              THEN
                  -- WEBCONTACTS_BILL_TO_SITE_ID
                  lc_user_data_table(ln_counter).ATTR_VALUE_NUM := p_contact_party_id;
         END CASE;

      END LOOP;  -- lc_ext_attr_name(i).APPLICATION_COLUMN_NAME

      XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Acct_site_Record ( p_api_version           => XX_CDH_CUST_EXTEN_ATTRI_PKG.G_API_VERSION
                                                           , p_cust_acct_site_id     => p_ship_to_acct_site_id
                                                           , p_attributes_row_table  => lc_user_row_table
                                                           , p_attributes_data_table => lc_user_data_table
                                                           , p_log_errors            => FND_API.G_FALSE
                                                           , x_failed_row_id_list    => l_failed_row_id_list
                                                           , x_return_status         => x_return_status
                                                           , x_errorcode             => l_errorcode
                                                           , x_msg_count             => x_msg_count
                                                           , x_msg_data              => x_msg_data
                                                           );

      IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
      THEN
         raise le_api_error;
      END IF;

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_acct_site_ext');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);
   END save_acct_site_ext;


   -- ===========================================================================
   -- Name             : save_ship_to_contact
   -- Description      : Save the Ship To and Bill TO Permissions
   --                    for the contact
   --
   -- Parameters :     p_operation
   --                  p_contact_party_id
   --                  p_contact_osr
   --                  p_ship_to_acct_site_id
   --                  p_bill_to_acct_site_id
   --                  x_bill_to_operation
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE save_ship_to_contact ( p_operation                 IN         VARCHAR2
                                  , p_orig_system               IN         VARCHAR2
                                  , p_ship_to_acct_site_id      IN         NUMBER
                                  , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_bill_to_acct_site_id      IN         NUMBER
                                  , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_contact_party_id          IN         NUMBER
                                  , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                  , x_bill_to_operation         OUT NOCOPY VARCHAR2
                                  , x_return_status             OUT NOCOPY VARCHAR2
                                  , x_msg_count                 OUT        NUMBER
                                  , x_msg_data                  OUT NOCOPY VARCHAR2
                                  )
   IS



      l_bill_record_exists                   BOOLEAN := FALSE;
      l_ship_record_exists                   BOOLEAN := FALSE;

      le_api_error                           EXCEPTION;

   BEGIN

      log_debug_message(2, 'In save_ship_to_contact' );
      log_debug_message(3, 'In p_operation                 := ' || p_operation               );
      log_debug_message(3, 'In p_orig_system               := ' || p_orig_system             );
      log_debug_message(3, 'In p_ship_to_acct_site_id      := ' || p_ship_to_acct_site_id    );
      log_debug_message(3, 'In p_ship_to_acct_site_osr     := ' || p_ship_to_acct_site_osr   );
      log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id    );
      log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr   );
      log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id        );
      log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr       );

      x_msg_count         := 0;
      x_bill_to_operation := NULL;

      log_debug_message(2, 'p_bill_to_acct_site_id = ' || p_bill_to_acct_site_id || ' Operation = ' || p_operation);
      IF  p_operation = 'C'
      THEN
         -- ---------------------------------------------------------
         -- Check if record exists in custom table
         -- ---------------------------------------------------------
         check_bill_to_contact ( p_orig_system             => p_orig_system
                               , p_contact_party_id        => p_contact_party_id
                               , p_contact_party_osr       => p_contact_party_osr
                               , p_bill_to_acct_site_id    => p_bill_to_acct_site_id
                               , p_bill_to_acct_site_osr   => p_bill_to_acct_site_osr
                               , x_contact_bill_to_exists  => l_bill_record_exists
                               , x_return_status           => x_return_status
                               , x_msg_count               => x_msg_count
                               , x_msg_data                => x_msg_data
                               );

         IF NOT l_bill_record_exists
         THEN
            log_debug_message(3, 'Bill To Association Should be added' );
            x_bill_to_operation   := 'C';
            l_ship_record_exists  := FALSE;
         ELSE
            -- ---------------------------------------------------------
            -- Since we could get multiple records with same ship to and
            -- bill to combination, we need to check before inserting the record.
            -- ---------------------------------------------------------
            check_bill_to_contact ( p_orig_system             => p_orig_system
                                  , p_contact_party_id        => p_contact_party_id
                                  , p_contact_party_osr       => p_contact_party_osr
                                  , p_ship_to_acct_site_id    => p_ship_to_acct_site_id
                                  , p_ship_to_acct_site_osr   => p_ship_to_acct_site_osr
                                  , p_bill_to_acct_site_id    => p_bill_to_acct_site_id
                                  , p_bill_to_acct_site_osr   => p_bill_to_acct_site_osr
                                  , x_contact_bill_to_exists  => l_ship_record_exists
                                  , x_return_status           => x_return_status
                                  , x_msg_count               => x_msg_count
                                  , x_msg_data                => x_msg_data
                                  );
         END IF; -- l_bill_record_exists

         IF NOT l_ship_record_exists
         THEN
            -- ---------------------------------------------------------
            -- Insert Ship To Information Into Custom Table
            -- ---------------------------------------------------------
            log_debug_message(3, 'Insert Bill To for Contact' );

            save_acct_site_ext ( p_operation                  => 'C'
                               , p_orig_system                => p_orig_system
                               , p_ship_to_acct_site_id       => p_ship_to_acct_site_id
                               , p_ship_to_acct_site_osr      => p_ship_to_acct_site_osr
                               , p_bill_to_acct_site_id       => p_bill_to_acct_site_id
                               , p_bill_to_acct_site_osr      => p_bill_to_acct_site_osr
                               , p_contact_party_id           => p_contact_party_id
                               , p_contact_party_osr          => p_contact_party_osr
                               , x_return_status              => x_return_status
                               , x_msg_count                  => x_msg_count
                               , x_msg_data                   => x_msg_data
                               );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_api_error;
            END IF; -- (x_return_status <> FND_API.G_RET_STS_SUCCESS)

            /*
            INSERT INTO XX_CRM_CONTACT_SHIP_TO_REL
                  ( contact_ship_to_rel_id
                  , party_id
                  , orig_system
                  , orig_system_reference
                  , ship_to_acct_site_id
                  , bill_to_acct_site_id
                  , creation_date
                  , created_by
                  , last_update_date
                  , last_updated_by
                  , last_update_login
                  )
            VALUES
                  ( XX_CRM_CONTACT_SHIP_TO_REL_S.nextval
                  , p_contact_party_id
                  , p_orig_system
                  , p_contact_party_osr
                  , p_ship_to_acct_site_id
                  , p_bill_to_acct_site_id
                  , SYSDATE
                  , fnd_global.user_id()
                  , SYSDATE
                  , fnd_global.user_id()
                  , fnd_global.login_id()
                 );
            */
         END IF; -- NOT l_ship_record_exists

      ELSIF p_operation = 'D'
      THEN
         -- ---------------------------------------------------------
         -- Delete Ship To Information Into Custom Table
         -- ---------------------------------------------------------
         log_debug_message(2, 'Delete Ship To and Bill To Association for contact' );
         save_acct_site_ext ( p_operation                  => 'D'
                            , p_orig_system                => p_orig_system
                            , p_ship_to_acct_site_id       => p_ship_to_acct_site_id
                            , p_ship_to_acct_site_osr      => p_ship_to_acct_site_osr
                            , p_bill_to_acct_site_id       => p_bill_to_acct_site_id
                            , p_bill_to_acct_site_osr      => p_bill_to_acct_site_osr
                            , p_contact_party_id           => p_contact_party_id
                            , p_contact_party_osr          => p_contact_party_osr
                            , x_return_status              => x_return_status
                            , x_msg_count                  => x_msg_count
                            , x_msg_data                   => x_msg_data
                            );


         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_api_error;
         END IF;

         /*
         DELETE
         FROM   XX_CRM_CONTACT_SHIP_TO_REL
         WHERE  party_id = p_contact_party_id
         AND    bill_to_acct_site_id = p_bill_to_acct_site_id;
         */
         -- ---------------------------------------------------------
         -- Check if record exists in custom table
         -- ---------------------------------------------------------
         check_bill_to_contact ( p_orig_system             => p_orig_system
                               , p_contact_party_id        => p_contact_party_id
                               , p_contact_party_osr       => p_contact_party_osr
                               , p_bill_to_acct_site_id    => p_bill_to_acct_site_id
                               , p_bill_to_acct_site_osr   => p_bill_to_acct_site_osr
                               , x_contact_bill_to_exists  => l_bill_record_exists
                               , x_return_status           => x_return_status
                               , x_msg_count               => x_msg_count
                               , x_msg_data                => x_msg_data
                               );

         IF NOT l_bill_record_exists
         THEN
             log_debug_message(3, 'Bill To Association Should be end dated' );
             x_bill_to_operation := 'D';
         END IF; -- l_record_exists

      END IF; --  p_operation = 'C'

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1,x_msg_data);

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_ship_to_contact');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);
   END save_ship_to_contact;

   -- ===========================================================================
   -- Name             : check_bill_to_contact
   -- Description      : Check if contact has permission for Bill to
   --                    Site
   --
   -- Parameters :     p_contact_party_id
   --                  p_bill_to_acct_site_id
   --                  x_contact_bill_to_exists
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   )
   AS
     /*
     CURSOR c_contact_bill_to (p_contact_party_id NUMBER, p_bill_to_acct_site_id NUMBER)
     IS
       SELECT *
       FROM   XX_CRM_CONTACT_SHIP_TO_REL
       WHERE  party_id = p_contact_party_id
       AND    bill_to_acct_site_id = p_bill_to_acct_site_id;
     */

     CURSOR c_contact_bill_to (p_contact_party_id NUMBER, p_bill_to_acct_site_id NUMBER)
     IS
       SELECT *
       FROM   XX_CDH_AS_EXT_WEBCTS_V
       WHERE  webcontacts_contact_party_id = p_contact_party_id
       AND    webcontacts_bill_to_site_id  = p_bill_to_acct_site_id;

     lc_contact_bill_to            c_contact_bill_to%ROWTYPE;
   BEGIN

      log_debug_message(2, 'In check_bill_to_contact' );
      log_debug_message(3, 'In p_orig_system               := ' || p_orig_system               );
      log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id          );
      log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr         );
      log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id      );
      log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr     );

      x_msg_count         := 0;

      OPEN  c_contact_bill_to(p_contact_party_id, p_bill_to_acct_site_id );
      FETCH c_contact_bill_to INTO  lc_contact_bill_to;
      IF c_contact_bill_to%NOTFOUND
      THEN
         x_contact_bill_to_exists := FALSE;
      ELSE
         x_contact_bill_to_exists := TRUE;
      END IF; -- c_contact_bill_to%NOTFOUND
      CLOSE c_contact_bill_to;

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         IF c_contact_bill_to%ISOPEN
         THEN
            CLOSE c_contact_bill_to;
         END IF; -- c_contact_bill_to%ISOPEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_ship_to_contact');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);
         -- x_msg_data := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;

   END check_bill_to_contact;

   -- ===========================================================================
   -- Name             : check_bill_to_contact
   -- Description      : Check if contact has permission for Bill to
   --                    Site
   --
   -- Parameters :     p_contact_party_id
   --                  p_bill_to_acct_site_id
   --                  x_contact_bill_to_exists
   --                  x_return_status
   --                  x_msg_count
   --                  x_msg_data
   --
   -- ===========================================================================
   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_ship_to_acct_site_id    IN         NUMBER
                                   , p_ship_to_acct_site_osr   IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   )
   AS
     /*
     CURSOR c_contact_bill_to ( p_contact_party_id     NUMBER
                              , p_ship_to_acct_site_id NUMBER
                              , p_bill_to_acct_site_id NUMBER)
     IS
       SELECT *
       FROM   XX_CRM_CONTACT_SHIP_TO_REL
       WHERE  party_id = p_contact_party_id
       AND    ship_to_acct_site_id = p_ship_to_acct_site_id
       AND    bill_to_acct_site_id = p_bill_to_acct_site_id;
     */

     CURSOR c_contact_bill_to ( p_contact_party_id     NUMBER
                              , p_ship_to_acct_site_id NUMBER
                              , p_bill_to_acct_site_id NUMBER)
     IS
       SELECT *
       FROM   XX_CDH_AS_EXT_WEBCTS_V
       WHERE  webcontacts_contact_party_id = p_contact_party_id
       AND    cust_acct_site_id            = p_ship_to_acct_site_id
       AND    webcontacts_bill_to_site_id  = p_bill_to_acct_site_id;

     lc_contact_bill_to            c_contact_bill_to%ROWTYPE;
   BEGIN

      log_debug_message(2, 'In check_bill_to_contact (2)' );
      log_debug_message(3, 'In p_orig_system               := ' || p_orig_system               );
      log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id          );
      log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr         );
      log_debug_message(3, 'In p_ship_to_acct_site_id      := ' || p_ship_to_acct_site_id      );
      log_debug_message(3, 'In p_ship_to_acct_site_osr     := ' || p_ship_to_acct_site_osr     );
      log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id      );
      log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr     );

      x_msg_count         := 0;

      OPEN  c_contact_bill_to(p_contact_party_id, p_ship_to_acct_site_id, p_bill_to_acct_site_id);
      FETCH c_contact_bill_to INTO  lc_contact_bill_to;
      IF c_contact_bill_to%NOTFOUND
      THEN
         x_contact_bill_to_exists := FALSE;
      ELSE
         x_contact_bill_to_exists := TRUE;
      END IF; -- c_contact_bill_to%NOTFOUND
      CLOSE c_contact_bill_to;

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         IF c_contact_bill_to%ISOPEN
         THEN
            CLOSE c_contact_bill_to;
         END IF; -- c_contact_bill_to%ISOPEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_ship_to_contact');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         -- x_msg_data := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;

   END check_bill_to_contact;

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
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          NUMBER   DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT         VARCHAR2
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
                   , p_status                 => p_status
                   , p_orig_system            => p_orig_system
                   , p_cust_acct_osr          => p_cust_acct_osr
                   , p_contact_osr            => p_contact_osr
                   , p_acct_site_osr          => p_acct_site_osr
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

      x_messages := get_messages ( p_return_status   => x_return_status
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
   PROCEDURE save_ext_user( p_userid                 IN       VARCHAR2
                          , p_password               IN       VARCHAR2
                          , p_first_name             IN       VARCHAR2
                          , p_middle_initial         IN       VARCHAR2
                          , p_last_name              IN       VARCHAR2
                          , p_email                  IN       VARCHAR
                          , p_status                 IN       VARCHAR2 DEFAULT '0'
                          , p_orig_system            IN       VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN       VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN       VARCHAR2
                          , p_acct_site_osr          IN       VARCHAR2 DEFAULT NULL
                          , p_record_type            IN       VARCHAR2 DEFAULT NULL
                          , p_access_code            IN       NUMBER   DEFAULT NULL
                          , p_permission_flag        IN       VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN       NUMBER
                          , p_ship_to_acct_site_id   IN       NUMBER
                          , p_bill_to_acct_site_id   IN       NUMBER
                          , p_party_id               IN       NUMBER   DEFAULT NULL
                          , x_return_status          OUT      VARCHAR2
                          , x_msg_count              OUT      NUMBER
                          , x_msg_data               OUT      VARCHAR2
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


      l_new_user        BOOLEAN := FALSE;

      l_org_id          HZ_CUST_ACCT_SITES_ALL.ORG_ID%TYPE;
      l_org_name        HR_ALL_ORGANIZATION_UNITS.NAME%TYPE;
      l_party_id        HZ_PARTIES.party_id%TYPE := p_party_id;
      l_site_key        XX_EXTERNAL_USERS.site_key%TYPE;

      l_new_resp_id     FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_new_appl_id     FND_RESPONSIBILITY.application_id%TYPE;
      l_new_resp_desc   FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      l_cur_resp_id     FND_RESPONSIBILITY.responsibility_id%TYPE;
      l_cur_appl_id     FND_RESPONSIBILITY.application_id%TYPE;
      l_cur_resp_desc   FND_RESPONSIBILITY_TL.responsibility_name%TYPE;

      ln_fnd_user_id    FND_USER.user_id%TYPE;

      le_party_id_null           EXCEPTION;
      le_update_fnd_failed       EXCEPTION;
      le_api_error               EXCEPTION;

      CURSOR  c_fnd_user (p_user_name VARCHAR2)
      IS
        SELECT rowid,
               user_id,
               user_name,
               description,
               customer_id
        FROM   fnd_user
        WHERE  user_name = p_user_name;

      l_userid                  xx_external_users.userid%TYPE;
      l_fnd_user_name           fnd_user.user_name%type;
      l_fnd_user_rec            XX_EXTERNAL_USERS_BO_PUB.fnd_user_rec_type;
      l_cur_extuser_rec         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type;
      l_new_extuser_rec         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type;


   BEGIN

      FND_MSG_PUB.initialize;
      x_msg_count         := 0;

      log_debug_message(2, '***** In save_ext_user procedure ***** ' );
      log_debug_message(3, 'p_userid                     := ' || p_userid                 );
      log_debug_message(3, 'p_password                   := ' || p_password               );
      log_debug_message(3, 'p_first_name                 := ' || p_first_name             );
      log_debug_message(3, 'p_middle_initial             := ' || p_middle_initial         );
      log_debug_message(3, 'p_last_name                  := ' || p_last_name              );
      log_debug_message(3, 'p_email                      := ' || p_email                  );
      log_debug_message(3, 'p_status                     := ' || p_status                 );
      log_debug_message(3, 'p_orig_system                := ' || p_orig_system            );
      log_debug_message(3, 'p_cust_acct_osr              := ' || p_cust_acct_osr          );
      log_debug_message(3, 'p_contact_osr                := ' || p_contact_osr            );
      log_debug_message(3, 'p_acct_site_osr              := ' || p_acct_site_osr          );
      log_debug_message(3, 'p_record_type                := ' || p_record_type            );
      log_debug_message(3, 'p_access_code                := ' || p_access_code            );
      log_debug_message(3, 'p_permission_flag            := ' || p_permission_flag        );
      log_debug_message(3, 'p_cust_account_id            := ' || p_cust_account_id        );
      log_debug_message(3, 'p_ship_to_acct_site_id       := ' || p_ship_to_acct_site_id   );
      log_debug_message(3, 'p_bill_to_acct_site_id       := ' || p_bill_to_acct_site_id   );

      -- -------------------------------------------------------------------------
      -- Get the Site Prefix for the User
      -- -------------------------------------------------------------------------
      get_user_prefix ( p_system_name     => p_orig_system
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

      l_fnd_user_name := l_site_key || p_userid;

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from FND_USER Table
      -- -------------------------------------------------------------------------
      BEGIN -- Get the User Informarion from FND_USER Table
         log_debug_message(2, 'Check if User exists in FND_USER ' || p_userid);
         OPEN  c_fnd_user(l_fnd_user_name);
         FETCH c_fnd_user INTO  l_fnd_user_rec;
         IF c_fnd_user%NOTFOUND
         THEN
            log_debug_message(2, 'User does not exist in FND_USER' );
            l_new_user := TRUE;
         ELSE
            log_debug_message(2, 'User exists in FND_USER' );
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
         get_contact_id ( p_orig_system          => p_orig_system
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

      l_new_extuser_rec.userid                     := p_userid;
      l_new_extuser_rec.password                   := p_password;
      l_new_extuser_rec.person_first_name          := p_first_name;
      l_new_extuser_rec.person_middle_name         := p_middle_initial;
      l_new_extuser_rec.person_last_name           := p_last_name;
      l_new_extuser_rec.email                      := p_email;
      l_new_extuser_rec.status                     := p_status;
      l_new_extuser_rec.orig_system                := p_orig_system;
      l_new_extuser_rec.contact_osr                := p_contact_osr;
      l_new_extuser_rec.access_code                := p_access_code;
      l_new_extuser_rec.permission_flag            := p_permission_flag;
      l_new_extuser_rec.site_key                   := l_site_key;
      l_new_extuser_rec.party_id                   := l_party_id;

      save_external_user( p_userid                     => p_userid
                        , p_new_extuser_rec            => l_new_extuser_rec
                        , x_cur_extuser_rec            => l_cur_extuser_rec
                        , x_return_status              => x_return_status
                        , x_msg_count                  => x_msg_count
                        , x_msg_data                   => x_msg_data
                        );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         RAISE le_api_error;
      END IF;

      -- ----------------------------------------------------------------------------
      -- if AV record was passed and user exists in FND_USER table,
      -- update responsibility for the user
      -- If the user does not exist in FND_USER, the responsibility will be assigned when
      -- the oracle.apps.fnd.user.insert BES event is raised
      -- ----------------------------------------------------------------------------
      IF p_record_type = 'AV' AND NOT l_new_user
      THEN
          log_debug_message(2, 'Update FND_USER Record');

          update_fnd_user( p_cur_extuser_rec            => l_cur_extuser_rec
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
         log_debug_message(1, x_msg_data);
         x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_ext_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, x_msg_data);
         --raise;
   END save_ext_user;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE save_external_user ( p_userid             IN         VARCHAR2
                                , p_new_extuser_rec    IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                                , x_cur_extuser_rec    OUT NOCOPY XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
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
        FROM   xx_external_users
        WHERE  userid = p_userid;

        l_new_user    BOOLEAN;

   BEGIN

      x_msg_count         := 0;
      log_debug_message(2, 'userid                      : ' || p_new_extuser_rec.userid);
      log_debug_message(3, 'password                    : ' || p_new_extuser_rec.password);
      log_debug_message(3, 'person_first_name           : ' || p_new_extuser_rec.person_first_name);
      log_debug_message(3, 'person_middle_name          : ' || p_new_extuser_rec.person_middle_name);
      log_debug_message(3, 'person_last_name            : ' || p_new_extuser_rec.person_last_name);
      log_debug_message(3, 'email                       : ' || p_new_extuser_rec.email);
      log_debug_message(3, 'party_id                    : ' || p_new_extuser_rec.party_id);
      log_debug_message(3, 'status                      : ' || 'A');
      log_debug_message(3, 'contact_osr                 : ' || p_new_extuser_rec.contact_osr);
      log_debug_message(3, 'acct_site_osr               : ' || p_new_extuser_rec.acct_site_osr);
      log_debug_message(3, 'access_code                 : ' || p_new_extuser_rec.access_code);
      log_debug_message(3, 'permission_flag             : ' || p_new_extuser_rec.permission_flag);
      log_debug_message(3, 'site_key                    : ' || p_new_extuser_rec.site_key);
      log_debug_message(3, 'fnd_user_name               : ' || p_new_extuser_rec.site_key || p_new_extuser_rec.userid);

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
        log_debug_message(2, 'Inserting User Info Into xx_external_users Table');
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
                           , access_code
                           , permission_flag
                           , site_key
                           , fnd_user_name
                           , created_by
                           , creation_date
                           , last_update_date
                           , last_updated_by
                           , last_update_login
                           )
                    VALUES ( xx_external_users_s.NEXTVAL
                           , p_new_extuser_rec.userid
                           , p_new_extuser_rec.password
                           , p_new_extuser_rec.person_first_name
                           , p_new_extuser_rec.person_middle_name
                           , p_new_extuser_rec.person_last_name
                           , p_new_extuser_rec.email
                           , p_new_extuser_rec.party_id
                           , 'A'
                           , p_new_extuser_rec.orig_system
                           , p_new_extuser_rec.contact_osr
                           , p_new_extuser_rec.acct_site_osr
                           , p_new_extuser_rec.access_code
                           , p_new_extuser_rec.permission_flag
                           , p_new_extuser_rec.site_key
                           , p_new_extuser_rec.site_key || p_new_extuser_rec.userid
                           , fnd_global.user_id()
                           , SYSDATE
                           , SYSDATE
                           , fnd_global.user_id()
                           , fnd_global.login_id()
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
            x_cur_extuser_rec.access_code                   =    p_new_extuser_rec.access_code                  AND
            x_cur_extuser_rec.permission_flag               =    p_new_extuser_rec.permission_flag
         THEN
             log_debug_message(2, 'No Update');
         ELSE
            log_debug_message(2, 'Updating User Info xx_external_users Table');
            UPDATE xx_external_users
            SET    password                       = p_new_extuser_rec.password
                 , person_first_name              = p_new_extuser_rec.person_first_name
                 , person_middle_name             = p_new_extuser_rec.person_middle_name
                 , person_last_name               = p_new_extuser_rec.person_last_name
                 , email                          = p_new_extuser_rec.email
                 , party_id                       = p_new_extuser_rec.party_id
                 , status                         = p_new_extuser_rec.status
                 , contact_osr                    = p_new_extuser_rec.contact_osr
                 , acct_site_osr                  = p_new_extuser_rec.acct_site_osr
                 , access_code                = p_new_extuser_rec.access_code
                 , permission_flag                = p_new_extuser_rec.permission_flag
                 , site_key                       = p_new_extuser_rec.site_key
                 , last_update_date               = SYSDATE
                 , last_updated_by                = fnd_global.user_id()
                 , last_update_login              = fnd_global.login_id()
            WHERE  rowid = x_cur_extuser_rec.ext_user_rowid;
         END IF; -- x_cur_extuser_rec.userid                        =    p_new_extuser_rec.userid
      END IF; -- l_new_user

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
         log_debug_message(1, x_msg_data);
   END save_external_user;

   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE update_new_fnd_user ( p_fnd_user_id             IN         NUMBER
                                 , x_return_status           OUT NOCOPY VARCHAR2
                                 , x_msg_count               OUT        NUMBER
                                 , x_msg_data                OUT NOCOPY NUMBER
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

      CURSOR  c_fnd_user (p_user_id VARCHAR2)
      IS
        SELECT rowid,
               user_id,
               user_name,
               description,
               customer_id
        FROM   fnd_user
        WHERE  user_id = p_user_id;


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
               , responsibility_id
               , status
               , contact_osr
               , acct_site_osr
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
        FROM   xx_external_users
        WHERE  fnd_user_name = p_fnd_user_name;

      l_fnd_user_rec            XX_EXTERNAL_USERS_BO_PUB.fnd_user_rec_type;
      l_cur_extuser_rec         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type;
      l_new_extuser_rec         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type;


      l_fnd_user_found          BOOLEAN;
      l_cur_extuser_found       BOOLEAN;

      le_update_fnd_user_failed  EXCEPTION;
      le_oid_pwd_update_failed   EXCEPTION;
   BEGIN

      log_debug_message(2, 'In update_new_fnd_user ' );
      log_debug_message(3, 'p_fnd_user_id  := ' || p_fnd_user_id );

      x_msg_count := 0;

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from FND_USER Table
      -- -------------------------------------------------------------------------
      log_debug_message(1, 'Get User information from FND_USER'  );
      BEGIN -- Get the User Informarion from FND_USER Table
         l_fnd_user_found := TRUE;
         OPEN  c_fnd_user(p_fnd_user_id);
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
         fnd_message.set_token ('USER_NAME', p_fnd_user_id);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, x_msg_data );
         RAISE le_update_fnd_user_failed;
      END IF; -- l_fnd_user_found

      -- -------------------------------------------------------------------------
      -- Get the User Informarion from XX_EXTERNAL_USERS Table
      -- -------------------------------------------------------------------------
      log_debug_message(1, 'Get User information from XX_EXTERNAL_USERS'  );
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

      IF l_cur_extuser_found
      THEN

         log_debug_message(1, 'Execute update_fnd_user'  );
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
         log_debug_message(1,x_msg_data);

      WHEN OTHERS
      THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.update_new_fnd_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, x_msg_data );
   END update_new_fnd_user;


   -- ===========================================================================
   -- ===========================================================================
   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_BO_PUB.fnd_user_rec_type
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

      log_debug_message(2, 'In update_fnd_user ' );

      x_msg_count         := 0;

      log_debug_message(3, 'In update_fnd_user' );

      -- -------------------------------------------------------------------------
      -- If the FND_USER Record does not have the Customer ID,
      -- Update the user with the Customer ID Information
      -- -------------------------------------------------------------------------
      l_party_id := p_new_extuser_rec.party_id;

      -- ** AKS: Check Where party_id is coming from
      IF p_fnd_user_rec.customer_id IS NULL OR
         NVL(p_fnd_user_rec.customer_id, -1) <> NVL(p_new_extuser_rec.party_id,-1)

      THEN
         log_debug_message(3, 'Update FND_USER ' || p_fnd_user_rec.user_name ||  ' with Customer ID ' || l_party_id );
         fnd_user_pkg.updateuser ( x_user_name   => p_fnd_user_rec.user_name
                                 , x_owner       => 'CUST'
                                 , x_customer_id => l_party_id
                                 );
      END IF; -- l_party_id IS NULL

      log_debug_message(3, 'Getting Org Name ');

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

      log_debug_message(3, 'Org Name ' || l_org_name );

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

      log_debug_message(3, 'New Responsibility Id   : ' || l_new_resp_id );
      log_debug_message(3, 'New Responsibility App  : ' || l_new_appl_id );
      log_debug_message(3, 'New Responsibility Name : ' || l_new_resp_desc );

      log_debug_message(3, 'Current Responsibility Id   : ' || l_cur_resp_id );
      log_debug_message(3, 'Current Responsibility App  : ' || l_cur_appl_id );
      log_debug_message(3, 'Current Responsibility Name : ' || l_cur_resp_desc );

      IF ( NVL(l_cur_resp_id, -1) <> NVL(l_new_resp_id, -1) )
      THEN
         IF l_cur_resp_id IS NOT NULL
         THEN
            -- -----------------------------------------------------------------------------
            -- Revoke the responsibility from the user
            -- AKS: Might have to get the Activation date for the responsibility
            -- -----------------------------------------------------------------------------
            log_debug_message(3, 'Remove Responsibility : ' || l_cur_resp_desc );
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
            log_debug_message(3, 'Add Responsibility : ' || l_new_resp_desc );
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

      x_return_status := FND_API.G_RET_STS_SUCCESS;
   EXCEPTION

     WHEN le_api_error THEN
       log_debug_message(1, x_msg_data);
       -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_external_user');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, x_msg_data);
         --raise;
   END update_fnd_user;

   -- ===========================================================================
   -- Name             : GET_FND_CREATE_EVENT
   -- Description      : This function is trigerred from a business
   --                    event oracle.apps.fnd.user.insert when a new
   --                    BSD web user is synchronized from OID into
   --                    fnd_user table. This function calls
   --                    update_fnd_user to grant the new user
   --                    iReceivables responsibilities and assign
   --                    the party id
   --
   --
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

      log_debug_message(2, '***** In get_fnd_create_event procedure ***** ' );

      --Obtaining the event parameter values
      ln_org_id             := p_event.GetValueForParameter('ORG_ID');
      ln_user_id            := p_event.GetValueForParameter('USER_ID');
      ln_resp_id            := p_event.GetValueForParameter('RESP_ID');
      ln_resp_appl_id       := p_event.GetValueForParameter('RESP_APPL_ID');
      ln_security_group_id  := p_event.GetValueForParameter('SECURITY_GROUP_ID');


      -- event key is the userid from fnd user table
      l_event_name := p_event.geteventname();
      l_event_key  := p_event.geteventkey();
      l_parameter_list := p_event.getparameterlist;

      log_debug_message(3, 'EVENTNAME: '||l_event_name );
      log_debug_message(3, 'EVENTKEY: '|| l_event_key );

      log_debug_message(3, 'ln_user_id:           ' || ln_user_id );
      log_debug_message(3, 'ln_org_id:            ' || ln_org_id );
      log_debug_message(3, 'ln_resp_id:           ' || ln_resp_id );
      log_debug_message(3, 'ln_resp_appl_id:      ' || ln_resp_appl_id );
      log_debug_message(3, 'ln_security_group_id: ' || ln_security_group_id );


      ln_user_id := l_event_key;

      update_new_fnd_user ( p_fnd_user_id         => ln_user_id
                          , x_return_status       => l_return_status
                          , x_msg_count           => l_msg_count
                          , x_msg_data            => l_msg_data
                          );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         raise le_update_fnd_user_failed;
      END IF;

      COMMIT;
      RETURN 'SUCCESS';

   EXCEPTION
      WHEN le_update_fnd_user_failed THEN
         ROLLBACK TO SAVEPOINT get_fnd_create_event_sv;
         xx_com_error_log_pub.log_error
                  ( p_application_name        => 'XXCRM'
                  , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                  , p_program_name            => 'XX_EXTERNAL_USERS_BO_PUB.GET_FND_CREATE_EVENT'
                  , p_module_name             => 'CDH'
                  , p_error_message_code      => 'XX_CDH_0005_UPDATE_FND_USER_FAILED'
                  , p_error_message           => NVL(l_msg_data, 'In Procedure:XX_EXTERNAL_USERS_BO_PUB.update_fnd_user: Failed for username :'|| lv_user_name)
                  , p_error_message_severity  => 'MAJOR'
                  , p_error_status            => 'ACTIVE'
                  , p_notify_flag             => 'Y'
                  , p_recipient               => NULL
                  );
         log_debug_message(1, 'In Procedure:XX_EXTERNAL_USERS_BO_PUB.update_fnd_user: Failed for username :'|| lv_user_name );
         -- RETURN 'ERROR';
         RETURN 'SUCCESS';

      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT get_fnd_create_event_sv;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         l_msg_count := l_msg_count + 1;
         l_msg_data := fnd_message.get();

         log_debug_message(1, ' Event insert failed. ' || l_msg_data);
         xx_com_error_log_pub.log_error
                  ( p_application_name        => 'XXCRM'
                  , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                  , p_program_name            => 'XX_EXTERNAL_USERS_BO_PUB.GET_FND_CREATE_EVENT'
                  , p_module_name             => 'CDH'
                  , p_error_message_code      => 'XX_CDH_0015_UNKNOWN_ERROR'
                  , p_error_message           => l_msg_data
                  , p_error_message_severity  => 'MAJOR'
                  , p_error_status            => 'ACTIVE'
                  , p_notify_flag             => 'Y'
                  , p_recipient               => NULL
                  );

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
                                      , x_return_status   OUT NOCOPY VARCHAR2
                                      , x_msg_count       OUT        NUMBER
                                      , x_msg_data        OUT NOCOPY VARCHAR2
                                      )
   IS
   BEGIN

      log_debug_message(2, '***** In update_ext_user_password procedure ***** ' );
      x_msg_count := 0;

      UPDATE xx_external_users
      SET    password = p_password
           , last_update_date  = SYSDATE
           , last_updated_by   = fnd_global.user_id()
           , last_update_login = fnd_global.login_id()
      WHERE userid = p_userid;

      IF SQL%ROWCOUNT = 0
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_007_USER_NOT_FOUND');
         fnd_message.set_token ('USER_NAME', p_userid);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, x_msg_data );
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
         log_debug_message(1, x_msg_data);
   END update_ext_user_password;


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

      log_debug_message(3, 'Getting Value for : XX_IREC_RESP_MAP ' || p_orig_system || ' , ' || p_orig_system_access);

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

       log_debug_message(3, 'Resp'||lv_resp_key);

      SELECT responsibility_id,
             application_id,
             responsibility_name
      INTO   x_resp_id,
             x_appl_id,
             x_responsibility_name
      FROM   fnd_responsibility_vl
      WHERE  responsibility_key = lv_resp_key;


      log_debug_message(3, 'Resp ID      ' || x_resp_id);
      log_debug_message(3, 'Appl ID:     ' || x_appl_id);
      log_debug_message(3, 'Description: ' || x_responsibility_name);

      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1,x_msg_data);
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

      log_debug_message(3, 'Getting Value for : XX_CDH_CONTACT_LEVEL ' || p_system_name || ' , ' || p_permission_flag);

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
         log_debug_message(1,x_msg_data);
         RAISE le_api_error;
      END IF;

      log_debug_message(3, 'Contact Level ' ||x_contact_level);
      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN le_api_error THEN
         log_debug_message(1, x_msg_data);

      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, 'Error in contact level. ' || x_msg_data);
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


      log_debug_message(3, 'Getting Value for : XX_ECOM_SITE_KEY ' || p_system_name || ' , ' || x_site_key);

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

      log_debug_message(3, 'Site Key ' ||x_site_key);
      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_entity_id');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         log_debug_message(1, 'Error in contact level. ' || x_msg_data);
  END get_user_prefix;


END XX_EXTERNAL_USERS_BO_PUB;
/

SHOW ERRORS;