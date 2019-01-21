create or replace
PACKAGE BODY XX_CDH_WEBCONTACTS_BO_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_CDH_WEBCONTACTS_BO_PUB                                                             |
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
-- |          14-Sep-2008 Kathirvel.P        Changes made to web contact deletion , contact deletion and|
-- |                                         web contact status maintenance.                            |
-- |          25-Sep-2008 Kathirvel.P        Changes made to revoke site level permissions when the user|
-- |                                         changes the permission from site level to account(S,M)level|
-- |                                         and set the apps context to ODCRMBPEL                      |
-- |          28-Jan-2009 Kalyan             Removed the check on status in hz_cust_accounts in cursor  |
-- |                                         l_contact_relation_cur.                                    |
-- |          20-Nov-2013 Avinash            Modified for R12 Upgrade Retrofit
-- +====================================================================================================+
*/


   g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_CDH_WEBCONTACTS_BO_PUB';
   g_module                       CONSTANT VARCHAR2(30) := 'CRM';

   g_user_role                    CONSTANT VARCHAR2(60) := 'SELF_SERVICE_USER';
   g_revoked_user_role            CONSTANT VARCHAR2(60) := 'REVOKED_SELF_SERVICE_ROLE';

   g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();


   -- ===========================================================================
   -- Name             : validate_role_resp
   -- Description      : This procedure validates the keys passed from
   --                    the legacy system (AOPS) and when a matching
   --                    account site and contact is found in Oracle
   --                    EBS will set the contact at bill to site for
   --                    the incoming ship to and inserts the user if it
   --                    is a create and updates the user when modify in
   --                    the xx_external_users tables. This procedue is
   --                    called from SaveiReceivables BPEL process
   --
   -- Parameters :      p_orig_system         : System Name for the source System
   --                   p_cust_acct_osr       : Unique Identifier for Account in the source System
   --                   p_cust_acct_cnt_osr   : Unique Identifier for Contact in the source System
   --                   p_cust_acct_site_osr  : Unique Identifier for Account Site in the source System
   --                   x_cust_account_id     : Account ID in CDH
   --                   x_acct_site_id        : Account Site in CDH
   --                   x_party_id            : Relationship Party for Contact in CDH
   --                   x_return_status       : Return Status
   --                   x_messages            : Error Message
   --
   -- ===========================================================================
   PROCEDURE validate_role_resp ( p_orig_system                 IN            VARCHAR2
                                , p_cust_acct_osr               IN            VARCHAR2
                                , p_cust_acct_cnt_osr           IN            VARCHAR2
                                , p_cust_acct_site_osr          IN            VARCHAR2
                                , x_cust_account_id             OUT           NUMBER
                                , x_acct_site_id                OUT           NUMBER
                                , x_party_id                    OUT           NUMBER
                                , x_return_status               OUT           VARCHAR2
                                , x_messages                    OUT NOCOPY    HZ_MESSAGE_OBJ_TBL
                                )
   IS
     l_msg_count            NUMBER;
     l_msg_data             VARCHAR2(4000);
   BEGIN

      validate_role_resp( p_orig_system           => p_orig_system
                        , p_cust_acct_osr         => p_cust_acct_osr
                        , p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
                        , p_cust_acct_site_osr    => p_cust_acct_site_osr
                        , x_cust_account_id       => x_cust_account_id
                        , x_acct_site_id          => x_acct_site_id
                        , x_party_id              => x_party_id
                        , x_return_status         => x_return_status
                        , x_msg_count             => l_msg_count
                        , x_msg_data              => l_msg_data );

      x_messages := XX_EXTERNAL_USERS_PVT.get_messages ( p_return_status   => x_return_status
                                                       , p_msg_count       => l_msg_count
                                                       , p_msg_data        => l_msg_data);

   END validate_role_resp;

   -- ===========================================================================
   -- Name             : validate_role_resp
   -- Description      : This procedure validates the keys passed from
   --                    the legacy system (AOPS) and when a matching
   --                    account site and contact is found in Oracle
   --                    EBS will set the contact at bill to site for
   --                    the incoming ship to and inserts the user if it
   --                    is a create and updates the user when modify in
   --                    the xx_external_users tables. This procedue is
   --                    called from SaveiReceivables BPEL process
   --
   -- Parameters :      p_orig_system          : System Name for the source System                        
   --                   p_cust_acct_osr        : Unique Identifier for Account in the source System       
   --                   p_cust_acct_cnt_osr    : Unique Identifier for Contact in the source System       
   --                   p_cust_acct_site_osr   : Unique Identifier for Account Site in the source System  
   --                   x_cust_account_id      : Account ID in CDH                                        
   --                   x_acct_site_id         : Account Site in CDH                                      
   --                   x_party_id             : Relationship Party for Contact in CDH                    
   --                   x_return_status        : Return Status
   --                   x_msg_count            : Number of Errors
   --                   x_msg_data             : Error Message
   --
   -- ===========================================================================
   PROCEDURE validate_role_resp ( p_orig_system                 IN             VARCHAR2
                                , p_cust_acct_osr               IN             VARCHAR2
                                , p_cust_acct_cnt_osr           IN             VARCHAR2
                                , p_cust_acct_site_osr          IN             VARCHAR2
                                , x_cust_account_id             OUT            NUMBER
                                , x_acct_site_id                OUT            NUMBER
                                , x_party_id                    OUT            NUMBER
                                , x_return_status               OUT NOCOPY     VARCHAR2
                                , x_msg_count                   OUT            NUMBER
                                , x_msg_data                    OUT NOCOPY     VARCHAR2
                                )
   IS
      --  --------------------------------------------------------------------------------------
      --  validate_role_resp validates the keys passed from the legacy system (AOPS)
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
      --  #param 6 px_party_id           return party id of the relationship
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

      -- l_contact_end_date          DATE;
      ln_apps_user_id                NUMBER;
      ln_resp_id                     NUMBER;
      ln_resp_appl_id                NUMBER;
      ln_security_group_id           NUMBER;
      ln_org_id                      NUMBER;

      -- Exceptions
      le_api_error                   EXCEPTION;
      le_role_api_error              EXCEPTION;
      le_resp_api_error              EXCEPTION;
      le_bo_api_error                EXCEPTION;
      le_contact_not_found           EXCEPTION;
      le_relationship_not_found      EXCEPTION;
      le_setup_error                 EXCEPTION;

   BEGIN

      IF NVL(fnd_global.user_name(), 'NO_USER') NOT IN ('ODCDH', 'ODCRMBPEL')
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Apps Context is not Set, Setting Apps Context using ODCDH and XX_US_CNV_CDH_CONVERSION ');
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

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After Setting Apps Context ' || x_return_status );
         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- NVL(fnd_global.user_name(), 'NO_USER') <> 'ODCDH'

      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, '***** In validate_role_resp procedure ***** ' );

      FND_MSG_PUB.initialize;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_orig_system                    := ' || p_orig_system                );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_osr                  := ' || p_cust_acct_osr              );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_cnt_osr              := ' || p_cust_acct_cnt_osr          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_site_osr             := ' || p_cust_acct_site_osr         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'User ID                          := ' || fnd_global.user_id()         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Resp Name                        := ' || fnd_global.resp_name()       );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Org Name                         := ' || fnd_global.org_name()        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Request ID                       := ' || fnd_global.conc_request_id() );
      $end

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

      IF p_cust_acct_osr IS NOT NULL
      THEN
         -- -------------------------------------------------------------------
         -- Get the Account ID
         -- -------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_entity_id ( p_orig_system        => p_orig_system
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

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Cust Account ID : ' || x_cust_account_id );
      END IF; -- p_cust_acct_osr IS NOT NULL

      IF p_cust_acct_cnt_osr IS NOT NULL
      THEN
         -- ----------------------------------------------------------------------
         -- Get the Party Id, Party relationShip ID for the Contact
         -- This function assumes that the Org Contact has been created earlier
         -- If Org Contact Does not exist then, return an error.
         -- ----------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => p_orig_system
                                              , p_cust_acct_cnt_osr    => p_cust_acct_cnt_osr
                                              , x_party_id             => x_party_id
                                              , x_return_status        => x_return_status
                                              , x_msg_count            => x_msg_count
                                              , x_msg_data             => x_msg_data
                                              );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Party ID : ' || x_party_id );
      END IF; -- p_cust_acct_cnt_osr IS NOT NULL

      IF p_cust_acct_site_osr IS NOT NULL
      THEN
         XX_EXTERNAL_USERS_PVT.get_entity_id ( p_orig_system        =>  p_orig_system
                                             , p_orig_sys_reference =>  p_cust_acct_site_osr
                                             , p_owner_table_name   =>  'HZ_CUST_ACCT_SITES_ALL'
                                             , x_owner_table_id     =>  x_acct_site_id
                                             , x_return_status      =>  x_return_status
                                             , x_msg_count          =>  x_msg_count
                                             , x_msg_data           =>  x_msg_data
                                             );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      END IF; -- p_cust_acct_site_osr IS NOT NULL

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,'le_api_error Error in ' || g_pkg_name || '.validate_role_resp ' || x_msg_data);

     WHEN le_bo_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,'le_bo_api_error Error in ' || g_pkg_name || '.validate_role_resp ' || x_msg_data);

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.validate_role_resp');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
   END validate_role_resp;

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
   -- Parameters :      p_orig_system                 : System Name for the source System
   --                   p_cust_acct_osr               : Unique Identifier for Account in the source System       
   --                   p_cust_acct_cnt_osr           : Unique Identifier for Contact in the source System
   --                   p_cust_acct_site_osr          : Unique Identifier for Account Site in the source System
   --                   p_record_type                 : Indicates is AV or ST Message was received
   --                   p_permission_flag             : Indicates association level for the contact
   --                   p_action                      : Operation on source system (C/U/D)
   --                   p_web_contact_id              :
   --                   px_cust_account_id            : Account ID in CDH
   --                   px_ship_to_acct_site_id       : Ship To Account Site in CDH
   --                   px_bill_to_acct_site_id       : Bill To Account Site in CDH
   --                   px_party_id                   : Relationship Party for Contact in CDH
   --                   x_web_user_status             : 
   --                   x_return_status               : Return Status
   --                   x_messages                    : Return Message
   --
   -- ===========================================================================
   PROCEDURE save_role_resp ( p_orig_system                 IN            VARCHAR2
                            , p_cust_acct_osr               IN            VARCHAR2
                            , p_cust_acct_cnt_osr           IN            VARCHAR2
                            , p_cust_acct_site_osr          IN            VARCHAR2
                            , p_record_type                 IN            VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN            VARCHAR2
                            , p_action                      IN            VARCHAR2
			    , p_web_contact_id              IN             VARCHAR2
                            , px_cust_account_id            IN OUT        NUMBER
                            , px_ship_to_acct_site_id       IN OUT        NUMBER
                            , px_bill_to_acct_site_id       IN OUT        NUMBER
                            , px_party_id                   IN  OUT       NUMBER
			    , x_web_user_status             OUT           VARCHAR2
                            , x_return_status               OUT           VARCHAR2
                            , x_messages                    OUT NOCOPY    HZ_MESSAGE_OBJ_TBL
                            )
   IS
     l_msg_count            NUMBER;
     l_msg_data             VARCHAR2(4000);

	l_return_status         VARCHAR2(5);
	l_error_message         VARCHAR2(500);
	l_party_relation_id     NUMBER;
	l_web_userid            VARCHAR2(50);
	l_cust_acct_id          NUMBER;
	l_acct_site_osr         VARCHAR2(50);
	l_web_user_status       VARCHAR2(5);
	l_error_count           NUMBER;
        l_cust_acct_site_id     NUMBER;
	l_cust_acct_bill_id     NUMBER;
	l_responsibility_id     NUMBER;

   CURSOR l_web_exten_attbt IS
   select * 
   from   XX_CDH_AS_EXT_WEBCTS_V
   where  WEBCONTACTS_CONTACT_PARTY_OSR  = p_cust_acct_cnt_osr;

   CURSOR l_acct_sites (cur_acct_site_id  NUMBER) IS
   select orig_system_reference
   from   hz_cust_acct_sites_all 
   where  cust_acct_site_id = cur_acct_site_id;


   CURSOR l_cust_acct_id_cur IS
   select cust_account_id
   from   hz_cust_accounts 
   where  orig_system_reference = p_cust_acct_osr;

    CURSOR l_contact_relation_cur IS
    SELECT par.party_id 
    FROM   --hz_party_relationships par --commented for R12 Upgrade retrofit
           hz_relationships par
    WHERE  par.subject_id = 
           (SELECT osr.owner_table_id 
            FROM   hz_orig_sys_references osr
            WHERE  osr.orig_system_reference = p_cust_acct_cnt_osr 
            AND    osr.owner_table_name      = 'HZ_PARTIES'
            AND    osr.orig_system           = p_orig_system
            AND    osr.status                = 'A')
    AND    par.object_id = 
           (SELECT cua.party_id 
            FROM   hz_cust_accounts cua
            WHERE  cua.orig_system_reference = p_cust_acct_osr
            --AND    cua.status                = 'A'
            )
    AND    par.relationship_code = 'CONTACT_OF';

      CURSOR c_get_role_responsibility_cur
      IS
         SELECT  hrr.responsibility_id
         FROM    hz_cust_account_roles car, hz_role_responsibility hrr
         WHERE   car.cust_account_role_id  = hrr.cust_account_role_id
         AND     car.cust_acct_site_id IS NULL
         AND     car.orig_system_reference = p_cust_acct_cnt_osr
         AND     hrr.responsibility_type   = 'SELF_SERVICE_USER';

   BEGIN

-- When web user gets deleted in AOPS, the journal sends the The record type as WW.  If record type is WW
-- we need to revoke the site and account related persmissions those are related to the web user.
-- The record type CD is pushed by the parent API when contact gets deleted in AOPS.

     IF p_record_type IN ('WW','CD')
     THEN

	     OPEN  l_cust_acct_id_cur;
	     FETCH l_cust_acct_id_cur INTO l_cust_acct_id;
	     CLOSE l_cust_acct_id_cur ;

	    OPEN  l_contact_relation_cur;
	    FETCH l_contact_relation_cur INTO l_party_relation_id;
	    CLOSE l_contact_relation_cur ;

-- ----------------------------------------------------------------------
-- Get the sites details those were assigned to the web user , from the extensible table and loop thru to
-- call the child procedure
-- ----------------------------------------------------------------------

	     FOR I IN l_web_exten_attbt
	     LOOP
		 l_acct_site_osr := NULL;
		 l_cust_acct_site_id := I.CUST_ACCT_SITE_ID;
		 l_cust_acct_bill_id := I.WEBCONTACTS_BILL_TO_SITE_ID;


		 OPEN  l_acct_sites(I.CUST_ACCT_SITE_ID);
		 FETCH l_acct_sites INTO l_acct_site_osr;
		 CLOSE l_acct_sites;


		     XX_CDH_WEBCONTACTS_BO_PUB.save_role_resp ( 
					      p_orig_system                 => p_orig_system
					    , p_cust_acct_osr               => p_cust_acct_osr
					    , p_cust_acct_cnt_osr           => p_cust_acct_cnt_osr
					    , p_cust_acct_site_osr          => l_acct_site_osr
					    , p_record_type                 => p_record_type
					    , p_permission_flag             => p_permission_flag
					    , p_action                      => 'D'
					    , p_web_contact_id              =>  p_web_contact_id
					    , px_cust_account_id            => l_cust_acct_id
					    , px_ship_to_acct_site_id       => l_cust_acct_site_id 
					    , px_bill_to_acct_site_id       => l_cust_acct_bill_id
					    , px_party_id                   => l_party_relation_id
					    , x_web_user_status             => x_web_user_status
					    , x_return_status               => x_return_status
			                    , x_msg_count                   => l_msg_count
			                    , x_msg_data                    => l_msg_data );

                      px_cust_account_id       := l_cust_acct_id;
                      px_ship_to_acct_site_id  := l_cust_acct_site_id;
                      px_bill_to_acct_site_id  := l_cust_acct_bill_id;
                      px_party_id              := l_party_relation_id;


		      IF x_return_status <> 'S'
		      THEN
                          EXIT;
		      END IF;
	     END LOOP;
             
	     l_cust_acct_site_id   := NULL;
             l_cust_acct_bill_id   := NULL;

	     OPEN  l_cust_acct_id_cur;
	     FETCH l_cust_acct_id_cur INTO l_responsibility_id;
	     CLOSE l_cust_acct_id_cur ;

	     IF l_responsibility_id IS NOT NULL and NVL(x_return_status,'S') = 'S'
	     THEN
-- ----------------------------------------------------------------------
-- If the web user has permission at account level, call the child procedure with p_permission_flag = 'S' to 
-- revoke the account level permission
-- ----------------------------------------------------------------------

		     XX_CDH_WEBCONTACTS_BO_PUB.save_role_resp ( 
					      p_orig_system                 => p_orig_system
					    , p_cust_acct_osr               => p_cust_acct_osr
					    , p_cust_acct_cnt_osr           => p_cust_acct_cnt_osr
					    , p_cust_acct_site_osr          => NULL
					    , p_record_type                 => p_record_type
					    , p_permission_flag             => 'S'
					    , p_action                      => 'D'
					    , p_web_contact_id              =>  p_web_contact_id
					    , px_cust_account_id            => l_cust_acct_id
					    , px_ship_to_acct_site_id       => l_cust_acct_site_id 
					    , px_bill_to_acct_site_id       => l_cust_acct_bill_id
					    , px_party_id                   => l_party_relation_id
					    , x_web_user_status             => x_web_user_status
					    , x_return_status               => x_return_status
			                    , x_msg_count                   => l_msg_count
			                    , x_msg_data                    => l_msg_data );

                      px_cust_account_id       := l_cust_acct_id;
                      px_ship_to_acct_site_id  := l_cust_acct_site_id;
                      px_bill_to_acct_site_id  := l_cust_acct_bill_id;
                      px_party_id              := l_party_relation_id;

	     END IF;

      ELSE

	      save_role_resp( p_orig_system               => p_orig_system
			    , p_cust_acct_osr             => p_cust_acct_osr
			    , p_cust_acct_cnt_osr         => p_cust_acct_cnt_osr
			    , p_cust_acct_site_osr        => p_cust_acct_site_osr
			    , p_record_type               => p_record_type
			    , p_permission_flag           => p_permission_flag
			    , p_action                    => p_action
			    , p_web_contact_id            => p_web_contact_id
			    , px_cust_account_id          => px_cust_account_id
			    , px_ship_to_acct_site_id     => px_ship_to_acct_site_id
			    , px_bill_to_acct_site_id     => px_bill_to_acct_site_id
			    , px_party_id                 => px_party_id
			    , x_web_user_status           => x_web_user_status
			    , x_return_status             => x_return_status
			    , x_msg_count                 => l_msg_count
			    , x_msg_data                  => l_msg_data );
	END IF;

--Applied commit explicitly since sometimes BPEL doesnot apply commit after invoking this API.

       IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
         COMMIT;
       END IF; 


      x_messages := XX_EXTERNAL_USERS_PVT.get_messages ( p_return_status   => x_return_status
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
   -- Parameters :      p_orig_system                 : System Name for the source System                             
   --                   p_cust_acct_osr               : Unique Identifier for Account in the source System            
   --                   p_cust_acct_cnt_osr           : Unique Identifier for Contact in the source System            
   --                   p_cust_acct_site_osr          : Unique Identifier for Account Site in the source System       
   --                   p_record_type                 : Indicates is AV or ST Message was received                    
   --                   p_permission_flag             : Indicates association level for the contact                   
   --                   p_action                      : Operation on source system (C/U/D)    
   --                   p_web_contact_id              :
   --                   px_cust_account_id            : Account ID in CDH                                             
   --                   px_ship_to_acct_site_id       : Ship To Account Site in CDH                                   
   --                   px_bill_to_acct_site_id       : Bill To Account Site in CDH                                   
   --                   px_party_id                   : Relationship Party for Contact in CDH                         
   --                   x_return_status               : Return Status                                                 
   --                   x_msg_count                   : Number of Errors
   --                   x_msg_data                    : Return Message
   --
   -- ===========================================================================
   PROCEDURE save_role_resp ( p_orig_system                 IN             VARCHAR2
                            , p_cust_acct_osr               IN             VARCHAR2
                            , p_cust_acct_cnt_osr           IN             VARCHAR2
                            , p_cust_acct_site_osr          IN             VARCHAR2
                            , p_record_type                 IN             VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN             VARCHAR2
                            , p_action                      IN             VARCHAR2
			    , p_web_contact_id              IN             VARCHAR2
                            , px_cust_account_id            IN OUT         NUMBER
                            , px_ship_to_acct_site_id       IN OUT         NUMBER
                            , px_bill_to_acct_site_id       IN OUT         NUMBER
                            , px_party_id                   IN OUT         NUMBER
			    , x_web_user_status             OUT            VARCHAR2
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
      --  #param 6 px_party_id           return party id of the relationship
      --  #param 7 x_retcode            return success or failure
      --  #param 8 x_msg_count          return the number of errors
      --  #param 9 x_msg_data           return the error messages
      --  --------------------------------------------------------------------------------------

     CURSOR l_acct_org_cur IS
     SELECT /* parallel (a,8) */ a.contact_osr 
     FROM   xx_external_users a
     WHERE  a.userid = p_web_contact_id;


      CURSOR  c_get_cust_account_role_cur (cur_cust_account_id      NUMBER
                                         , cur_cust_acct_cnt_osr    VARCHAR2) IS
      SELECT  /* parallel (a,8) */ a.cust_account_role_id
      FROM    hz_cust_account_roles a 
      WHERE   a.cust_account_id      = cur_cust_account_id
      AND     a.cust_acct_site_id IS NULL
      AND     a.orig_system_reference= cur_cust_acct_cnt_osr
      AND     a.cust_account_role_id = ( 
         SELECT  b.cust_account_role_id 
         FROM    hz_role_responsibility b
         WHERE   b.cust_account_role_id = a.cust_account_role_id 
         AND     b.responsibility_type  = 'SELF_SERVICE_USER');


      CURSOR  c_get_cust_site_role_cur (cur_cust_account_id      NUMBER
                                      , cur_cust_acct_cnt_osr    VARCHAR2) IS
      SELECT  /* parallel (a,8) */ a.cust_account_role_id
      FROM    hz_cust_account_roles a 
      WHERE   a.cust_account_id      = cur_cust_account_id
      AND     a.cust_acct_site_id IS NOT NULL
      AND     a.orig_system_reference= cur_cust_acct_cnt_osr
      AND     ROWNUM < 2
      AND     a.cust_account_role_id = ( 
         SELECT  b.cust_account_role_id 
         FROM    hz_role_responsibility b
         WHERE   b.cust_account_role_id = a.cust_account_role_id 
         AND     b.responsibility_type  = 'SELF_SERVICE_USER');


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
      l_contact_osr                  VARCHAR2(50);
      l_cust_account_id              NUMBER;
      l_cust_account_role_id         NUMBER;
      l_cust_site_role_id            NUMBER;

      -- l_contact_end_date          DATE;
      ln_apps_user_id                NUMBER;
      ln_resp_id                     NUMBER;
      ln_resp_appl_id                NUMBER;
      ln_security_group_id           NUMBER;
      ln_org_id                      NUMBER;

      l_acct_contact_status          VARCHAR2 (30);
      l_site_contact_status          VARCHAR2 (30);

      -- Exceptions
      le_api_error              EXCEPTION;
      le_role_api_error         EXCEPTION;
      le_resp_api_error         EXCEPTION;
      le_bo_api_error           EXCEPTION;
      le_contact_not_found      EXCEPTION;
      le_relationship_not_found EXCEPTION;
      le_setup_error            EXCEPTION;

   BEGIN

      IF NVL(fnd_global.user_name(), 'NO_USER') NOT IN ('ODCDH', 'ODCRMBPEL')
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Apps Context is not Set, Setting Apps Context using ODCDH and XX_US_CNV_CDH_CONVERSION ');
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

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After Setting Apps Context ' || x_return_status );
         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      END IF; -- NVL(fnd_global.user_name(), 'NO_USER') <> 'ODCDH'


      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, '***** In save_role_resp procedure ***** ' );
      FND_MSG_PUB.initialize;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_cnt_osr  := ' || p_cust_acct_cnt_osr);
      
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_orig_system                    := ' || p_orig_system                );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_osr                  := ' || p_cust_acct_osr              );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'px_cust_account_id               := ' || px_cust_account_id           );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_cnt_osr              := ' || p_cust_acct_cnt_osr          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'px_party_id                      := ' || px_party_id                  );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_site_osr             := ' || p_cust_acct_site_osr         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'px_ship_to_acct_site_id          := ' || px_ship_to_acct_site_id      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_record_type                    := ' || p_record_type                );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_permission_flag                := ' || p_permission_flag            );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_action                         := ' || p_action                     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'User ID                          := ' || fnd_global.user_id()         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Resp Name                        := ' || fnd_global.resp_name()       );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Org Name                         := ' || fnd_global.org_name()        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Request ID                       := ' || fnd_global.conc_request_id() );
      $end

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
      -- p_cust_acct_osr or px_cust_account_id should be passed.
      -- ----------------------------------------------------------------------
      IF p_cust_acct_osr IS NULL AND
         px_cust_account_id IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
         fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
         fnd_message.set_token ('PARAMETER_NAME', 'p_cust_acct_osr or px_cust_account_id');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; --  p_orig_system IS NULL

      -- ----------------------------------------------------------------------
      -- p_cust_acct_cnt_osr or px_party_id should be passed
      -- ----------------------------------------------------------------------
      IF p_cust_acct_cnt_osr IS NULL AND
         px_party_id IS NULL
      THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
         fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
         fnd_message.set_token ('PARAMETER_NAME', 'p_cust_acct_cnt_osr or px_party_id');
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
      END IF; --  p_orig_system IS NULL

      IF NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) = FND_API.G_RET_STS_ERROR
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Input Paramter Validation Failed' );
         x_return_status := FND_API.G_RET_STS_ERROR;
         RAISE le_api_error;
      END IF; -- NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) = FND_API.G_RET_STS_ERROR

      IF px_cust_account_id IS NULL
      THEN
         -- -------------------------------------------------------------------
         -- Get the Account ID
         -- -------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_entity_id ( p_orig_system        => p_orig_system
                                             , p_orig_sys_reference => p_cust_acct_osr
                                             , p_owner_table_name   => 'HZ_CUST_ACCOUNTS'
                                             , x_owner_table_id     => px_cust_account_id
                                             , x_return_status      => x_return_status
                                             , x_msg_count          => x_msg_count
                                             , x_msg_data           => x_msg_data
                                             );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Cust Account ID : ' || px_cust_account_id );
      END IF; -- px_cust_account_id IS NULL

      l_contact_osr      := p_cust_acct_cnt_osr;
      l_cust_account_id  := px_cust_account_id;  

      IF px_party_id IS NULL 
      THEN
          IF  p_cust_acct_cnt_osr IS NULL and p_web_contact_id IS NOT NULL
	  THEN
    		OPEN  l_acct_org_cur;
    		FETCH l_acct_org_cur INTO l_contact_osr;
    		CLOSE l_acct_org_cur;

		IF l_contact_osr IS NULL
		THEN
			x_return_status := 'E';
			x_msg_count     :=  x_msg_count + 1;
			x_msg_data      := 'No Record Exist in xx_external_users for the UserID '||p_web_contact_id;
			raise le_api_error;
		END IF;
          ELSIF  p_cust_acct_cnt_osr IS NULL and p_web_contact_id IS NULL
	  THEN
               x_return_status := 'E';
               x_msg_count     :=  x_msg_count + 1;
               x_msg_data      := 'Either Contact OSR or Web Contact ID must have a value';
               raise le_api_error;
         END IF;

         -- ----------------------------------------------------------------------
         -- Get the Party Id, Party relationShip ID for the Contact
         -- This function assumes that the Org Contact has been created earlier
         -- If Org Contact Does not exist then, return an error.
         -- ----------------------------------------------------------------------
         XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => p_orig_system
                                              , p_cust_acct_cnt_osr    => l_contact_osr
                                              , x_party_id             => px_party_id
                                              , x_return_status        => x_return_status
                                              , x_msg_count            => x_msg_count
                                              , x_msg_data             => x_msg_data
                                              );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            raise le_api_error;
         END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Party ID : ' || px_party_id );
      END IF; -- px_party_id IS NULL

      -- ----------------------------------------------------------------------
      -- Based on new Permission Level Check if Contact is associate at
      -- CUST_ACCT or CUST_ACCT_SITE Level
      -- ----------------------------------------------------------------------
      XX_EXTERNAL_USERS_PVT.get_contact_level ( p_system_name     => p_orig_system
                                              , p_permission_flag => p_permission_flag
                                              , x_contact_level   => lv_parent_obj
                                              , x_return_status   => x_return_status
                                              , x_msg_count       => x_msg_count
                                              , x_msg_data        => x_msg_data
                                              );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         raise le_api_error;
      END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact Level   : ' || lv_parent_obj     );

      x_web_user_status := '0';

-- ----------------------------------------------------------------------
-- If the permission level is at Site level , we need to create permision for the given site.
-- When user changes the permision from Site to Account Level , journal sends the Site deletion details
-- with account level permision flag(S,M). We need to revoke the site level access in this case also.
-- ----------------------------------------------------------------------

      IF (lv_parent_obj = 'CUST_ACCT_SITE') or (p_record_type = 'ST' and p_action = 'D' and lv_parent_obj = 'CUST_ACCT')
      THEN

         IF p_record_type in ('ST','WW','CD')
         THEN
            -- lv_parent_obj := 'CUST_ACCT_SITE';
            -- lv_cust_acct_cnt_os    := NVL(p_orig_system, 'A0');
            -- lv_parent_os           := NULL;
            -- lv_parent_osr          := NULL;

            -- ----------------------------------------------------------------------
            -- p_cust_acct_site_osr or px_ship_to_acct_site_id should be passed
            -- ----------------------------------------------------------------------
            IF p_cust_acct_site_osr IS NULL AND
               px_ship_to_acct_site_id IS NULL
            THEN
               x_return_status := FND_API.G_RET_STS_ERROR;
               fnd_message.set_name ('XXCRM', 'XX_CDH_IREC_002_MISSING_PARAM');
               fnd_message.set_token ('ROUTIME', g_pkg_name || '.save_role_resp');
               fnd_message.set_token ('PARAMETER_NAME', 'p_cust_acct_site_osr or px_ship_to_acct_site_id');
               x_msg_count := x_msg_count + 1;
               x_msg_data := fnd_message.get();
            END IF; --  p_orig_system IS NULL

            IF NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) = FND_API.G_RET_STS_ERROR
            THEN
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Input Paramter Validation Failed' );
               x_return_status := FND_API.G_RET_STS_ERROR;
               RAISE le_api_error;
            END IF; -- NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) = FND_API.G_RET_STS_ERROR

            IF px_ship_to_acct_site_id IS NULL
            THEN
               -- -------------------------------------------------------------------
               -- Get the Cust_Account_Site Information
               -- -------------------------------------------------------------------
               XX_EXTERNAL_USERS_PVT.get_entity_id ( p_orig_system        =>  p_orig_system
                                                   , p_orig_sys_reference =>  p_cust_acct_site_osr
                                                   , p_owner_table_name   =>  'HZ_CUST_ACCT_SITES_ALL'
                                                   , x_owner_table_id     =>  px_ship_to_acct_site_id
                                                   , x_return_status      =>  x_return_status
                                                   , x_msg_count          =>  x_msg_count
                                                   , x_msg_data           =>  x_msg_data
                                                   );

               IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                  raise le_api_error;
               END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            END IF; -- px_ship_to_acct_site_id IS NOT NULL

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Ship To Account Site ID: ' || px_ship_to_acct_site_id );


            XX_CDH_WEBCONTACTS_PVT.get_bill_to_site_id ( p_cust_acct_id                =>  px_cust_account_id
                                                       , p_ship_to_cust_acct_site_id   =>  px_ship_to_acct_site_id
                                                       , x_bill_to_cust_acct_site_id   =>  px_bill_to_acct_site_id
                                                       , x_bill_to_osr                 =>  lv_billto_orig_sys_ref
                                                       , x_return_status               =>  x_return_status
                                                       , x_msg_count                   =>  x_msg_count
                                                       , x_msg_data                    =>  x_msg_data
                                                       );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               raise le_api_error;
            END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Bill To Account Site ID = ' || px_bill_to_acct_site_id );

            -- ----------------------------------------------------
            -- Insert / Delete the Ship to and Bill TO Information
            -- ----------------------------------------------------
            XX_CDH_WEBCONTACTS_PVT.save_ship_to_contact ( p_operation                 => p_action
                                                        , p_orig_system               => p_orig_system
                                                        , p_ship_to_acct_site_id      => px_ship_to_acct_site_id
                                                        , p_ship_to_acct_site_osr     => p_cust_acct_site_osr
                                                        , p_bill_to_acct_site_id      => px_bill_to_acct_site_id
                                                        , p_bill_to_acct_site_osr     => lv_billto_orig_sys_ref
                                                        , p_contact_party_id          => px_party_id
                                                        , p_contact_party_osr         => p_cust_acct_cnt_osr
                                                        , x_bill_to_operation         => l_bill_to_action
                                                        , x_return_status             => x_return_status
                                                        , x_msg_count                 => x_msg_count
                                                        , x_msg_data                  => x_msg_data
                                                        );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               raise le_api_error;
            END IF; -- x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_bill_to_action: ' || l_bill_to_action );

-- ----------------------------------------------------------------------
-- If web user deletion or contact deletion comes, set the status as 2 for xx_enternal_users and
-- revoke the permission at site level. 
-- Program sets 'C' to l_bill_to_action for creating permission (self service role) at site level,
-- sets 'D' to revoke (Revoked self service role) the permission
-- If the contact gets deleted, the permissions (account and site level) have to be revoked and
-- roles have to inactivated, whereas , for webuser gets deleted,the permissions (account and site level) 
-- have to be revoked but roles will remain active.
-- So, when cotact gets deleted (Record Type = 'CD'), set 'X' to action when call the child procedure.
-- ----------------------------------------------------------------------


     dbms_output.put_line ('l_bill_to_action '||l_bill_to_action);

	    IF p_record_type IN ('WW','CD')
	    THEN
                 l_bill_to_action  := 'D';
		 x_web_user_status := '2';
	    END IF;

-- ----------------------------------------------------------------------
-- If web user does not have permission for any of the site, set the status as 1 for xx_enternal_users and
-- ----------------------------------------------------------------------


	    IF p_record_type = 'ST' and l_bill_to_action = 'D' and lv_parent_obj = 'CUST_ACCT_SITE'
	    THEN
	         x_web_user_status := '1';
	    END IF;

            IF l_bill_to_action IS NOT NULL
            THEN

	      IF p_record_type = 'CD' 
	      THEN

	          l_site_contact_status := 'X';

              ELSE
	          l_site_contact_status := l_bill_to_action;

              END IF;

               XX_CDH_WEBCONTACTS_PVT.save_bill_to_contact_role ( p_action                      => l_site_contact_status
                                                                , p_orig_system                 => p_orig_system
                                                                , p_cust_acct_cnt_osr           => p_cust_acct_cnt_osr
                                                                , p_cust_account_id             => px_cust_account_id
                                                                , p_ship_to_acct_site_id        => px_ship_to_acct_site_id
                                                                , p_bill_to_acct_site_id        => px_bill_to_acct_site_id
                                                                , p_party_id                    => px_party_id
                                                                , x_return_status               => x_return_status
                                                                , x_msg_count                   => x_msg_count
                                                                , x_msg_data                    => x_msg_data
                                                                );

               IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
               THEN
                  raise le_api_error;
               END IF;

               -- -------------------------------------------------------------------------
               -- if a ST Record with Permission of C/X/L is received(Site Level), the contact role
               -- at the account level should be deleted
               -- AKS: Should check if role exsists at account level before calling this function
               -- --------------------------------------------------------------------------
	      IF lv_parent_obj = 'CUST_ACCT_SITE'
	      THEN
		      IF p_record_type = 'CD' 
		      THEN

			  l_acct_contact_status := 'X';

		      ELSE
			  l_acct_contact_status := 'D';

		      END IF;
		       
		       XX_CDH_WEBCONTACTS_PVT.save_account_contact_role ( p_action                => l_acct_contact_status
									, p_orig_system           => p_orig_system
									, p_cust_acct_osr         => p_cust_acct_osr
									, p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
									, p_cust_account_id       => px_cust_account_id
									, p_party_id              => px_party_id
									, x_return_status         => x_return_status
									, x_msg_count             => x_msg_count
									, x_msg_data              => x_msg_data
									);

		       IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
		       THEN
			  raise le_api_error;
		       END IF;
              END IF;
           END IF;-- l_bill_to_action IS NOT NULL
         ELSE
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'AV record, no action required' );
         END IF; -- p_record_type = 'ST'

      ELSIF (lv_parent_obj = 'CUST_ACCT')
      THEN

	      IF p_record_type = 'CD' 
	      THEN
	          l_acct_contact_status := 'X';
                  x_web_user_status     := '2';
              ELSE
	          l_acct_contact_status := p_action;

		  IF p_action = 'D'
		  THEN

-- ----------------------------------------------------------------------
-- If web user does not have permission for any of the site, set the status as 1 for xx_enternal_users and
-- ----------------------------------------------------------------------

			OPEN   c_get_cust_site_role_cur(l_cust_account_id , l_contact_osr);
			FETCH  c_get_cust_site_role_cur INTO l_cust_site_role_id;
			CLOSE  c_get_cust_site_role_cur;

			IF l_cust_site_role_id IS NULL
			THEN
			    x_web_user_status := '1';
			END IF;
		  END IF;
              END IF;


         XX_CDH_WEBCONTACTS_PVT.save_account_contact_role ( p_action                => l_acct_contact_status
                                                          , p_orig_system           => p_orig_system
                                                          , p_cust_acct_osr         => p_cust_acct_osr
                                                          , p_cust_acct_cnt_osr     => p_cust_acct_cnt_osr
                                                          , p_cust_account_id       => px_cust_account_id
                                                          , p_party_id              => px_party_id
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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'SAVE_ROLE_RESP Status: ' || x_return_status );
      XX_EXTERNAL_USERS_DEBUG.disable_debug;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,'le_api_error Error in ' || g_pkg_name || '.save_role_resp ' || x_msg_data);

     WHEN le_bo_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,'le_bo_api_error Error in ' || g_pkg_name || '.save_role_resp ' || x_msg_data);

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_role_resp');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
   END save_role_resp;

   -- ===========================================================================
   -- Name             : bill_to_change_event
   -- Description      : This procedure will be registered as the subscription
   --                    function for BES Event Cust Account Site Change
   --                    This will submit a concurrent request to process the change
   --
   -- Parameters :      p_subscription_guid : GUID For the Business Event
   --                   p_event             : Business Event Data
   -- ===========================================================================
   FUNCTION bill_to_change_event ( p_subscription_guid IN            RAW
                                 , p_event             IN OUT NOCOPY WF_EVENT_T
                                 )
   RETURN VARCHAR2
   AS
      ln_count                         PLS_INTEGER;
      ln_org_id                        NUMBER;
      ln_user_id                       NUMBER;
      ln_resp_id                       NUMBER;
      ln_resp_appl_id                  NUMBER;
      ln_security_group_id             NUMBER;
      ln_request_id                    NUMBER;
      lc_user_name                     FND_USER.USER_NAME%TYPE;

      l_param_name                     VARCHAR2(2000);
      l_param_value                    VARCHAR2(2000);
      l_event_name                     VARCHAR2(2000);
      l_event_key                      VARCHAR2(2000);
      l_parameter_list                 WF_PARAMETER_LIST_T := wf_parameter_list_t();

      l_return_status                  VARCHAR2(30);
      l_msg_count                      NUMBER;
      l_msg_data                       VARCHAR2(2000);

      l_cust_acct_site_id               NUMBER;

      bill_to_change_event_error       EXCEPTION;

   BEGIN

      SAVEPOINT bill_to_change_event_sv;

      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, '***** In bill_to_change_event procedure ***** ' );

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
      -- l_cust_acct_site_id   := p_event.GetValueForParameter('CUST_ACCT_SITE_ID');

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Event Name           : '||l_event_name );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Event Key            : '|| l_event_key );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_user_id           : ' || ln_user_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_org_id            : ' || ln_org_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_resp_id           : ' || ln_resp_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_resp_appl_id      : ' || ln_resp_appl_id );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_security_group_id : ' || ln_security_group_id );

         IF l_parameter_list IS NOT NULL
         THEN
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parameter Count      : '||l_parameter_list.count );
            FOR i IN l_parameter_list.first..l_parameter_list.last
            LOOP
               l_param_name  := l_parameter_list(i).getname;
               l_param_value := l_parameter_list(i).getvalue;
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parameter (' || l_param_name || ') : ' ||l_param_value );
            END LOOP;
         END IF; -- l_parameter_list IS NOT NULL
      $end

      IF l_cust_acct_site_id IS NOT NULL
      THEN
         -- --------------------------------------------------------------------
         -- Submit Concurrent Request to Process the Bill To Change Event
         -- Concurrent Request Parameter - account_site_id
         -- --------------------------------------------------------------------
         ln_request_id := Fnd_Request.submit_request ( 'XXCRM'                        --application
                                                     , 'XXCDH_CUST_ACCT_SITE_CHG'     --program
                                                     , NULL                           --description
                                                     , NULL                           --start_time
                                                     , FALSE                          --sub_request
                                                     , l_cust_acct_site_id            --argument1
                                                     );


      END IF; -- l_cust_acct_site_id IS NOT NULL

      XX_EXTERNAL_USERS_DEBUG.disable_debug;
      COMMIT;
      RETURN 'SUCCESS';

   EXCEPTION
      WHEN bill_to_change_event_error THEN
         ROLLBACK TO SAVEPOINT bill_to_change_event_sv;
         xx_com_error_log_pub.log_error
                  ( p_application_name        => 'XXCRM'
                  , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                  , p_program_name            => 'XX_CDH_WEBCONTACTS_BO_PUB.bill_to_change_event'
                  , p_module_name             => 'CDH'
                  , p_error_message_code      => 'XX_CDH_0005_UPDATE_FND_USER_FAILED'
                  , p_error_message           => NVL(l_msg_data, 'In Procedure:XX_CDH_WEBCONTACTS_BO_PUB.update_fnd_user: Failed for event :'|| lc_user_name)
                  , p_error_message_severity  => 'MAJOR'
                  , p_error_status            => 'ACTIVE'
                  , p_notify_flag             => 'Y'
                  , p_recipient               => NULL
                  );

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'In Procedure:XX_CDH_WEBCONTACTS_BO_PUB.bill_to_change_event: Failed for username :'|| lc_user_name );
         RETURN 'ERROR';

      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT bill_to_change_event_sv;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.bill_to_change_event');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         l_msg_count := l_msg_count + 1;
         l_msg_data := fnd_message.get();

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, ' Event insert failed. ' || l_msg_data);
         xx_com_error_log_pub.log_error
                  ( p_application_name        => 'XXCRM'
                  , p_program_type            => 'E1328_BSDNET_IRECEIVABLES'
                  , p_program_name            => 'XX_CDH_WEBCONTACTS_BO_PUB.bill_to_change_event'
                  , p_module_name             => 'CDH'
                  , p_error_message_code      => 'XX_CDH_0015_UNKNOWN_ERROR'
                  , p_error_message           => l_msg_data
                  , p_error_message_severity  => 'MAJOR'
                  , p_error_status            => 'ACTIVE'
                  , p_notify_flag             => 'Y'
                  , p_recipient               => NULL
                  );

         RETURN 'ERROR';
   END bill_to_change_event;

END XX_CDH_WEBCONTACTS_BO_PUB;

/

Show Errors;