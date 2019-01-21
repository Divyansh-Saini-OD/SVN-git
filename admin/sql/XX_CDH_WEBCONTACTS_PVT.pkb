create or replace
PACKAGE BODY XX_CDH_WEBCONTACTS_PVT
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_CDH_WEBCONTACTS_PVT                                                             |
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
-- |          31-Mar-2008 Kathirvel	     Changed Primary Flag to 'N'                                |
-- |          14-Sep-2008 Kathirvel.P        Changes made to web contact deletion , contact deletion and|
-- |                                         web contact status maintenance.                            |
-- |          24-Sep-2008 Kathirvel.P        Changes made in the procedure save_account_contact_role    |
-- |                                         to update the responsibility instead of creating new resp. |
-- |          23-Oct-2008 Kalyan             Modified created_by_module from 'AOPS SYNC' to 'BO_API'.   |
-- |          26-May-2009 Kalyan             Modified c_get_role_responsibility_cur to have ORDER BY    |
-- |                                         responsibility_type clause.                                |
-- |          08-Feb-2014 Avinash            Modified for R12 Upgrade Retrofit 				|
-- +====================================================================================================+
*/


  g_debug_type                   VARCHAR2(10)    := 'XXCOMN';
  g_debug_level                  NUMBER          := 3;
  g_debug_count                  NUMBER          := 0;
  g_debug                        BOOLEAN         := FALSE;

  g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_CDH_WEBCONTACTS_PVT';
  g_module                       CONSTANT VARCHAR2(30) := 'CRM';

  g_user_role                    CONSTANT VARCHAR2(60) := 'SELF_SERVICE_USER';
  g_revoked_user_role            CONSTANT VARCHAR2(60) := 'REVOKED_SELF_SERVICE_ROLE';

  g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();


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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In get_bill_to_site_id ');
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_cust_acct_id                   := ' || p_cust_acct_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'p_ship_to_cust_acct_site_id OSR  := ' || p_ship_to_cust_acct_site_id );
      $end

      SELECT orig_system_reference,
             bill_to_site_use_id
      INTO   lv_billto_orig_sys_ref,
             ln_bill_to_site_use_id
      FROM   hz_cust_site_uses_all
      WHERE  cust_acct_site_id = p_ship_to_cust_acct_site_id
      AND    site_use_code = 'SHIP_TO';

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' Bill to Site Use ID : ' || ln_bill_to_site_use_id);

      IF ln_bill_to_site_use_id IS NOT NULL
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Get Bill To Associated with Ship To Record' );

         SELECT cust_acct_site_id
         INTO   x_bill_to_cust_acct_site_id
         FROM   hz_cust_site_uses_all
         WHERE  site_use_id = ln_bill_to_site_use_id;

      ELSE
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Get Default Bill To Record' );

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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' Bill to Site ID : ' || x_bill_to_cust_acct_site_id);

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
      lc_responsibility_type         VARCHAR2(150);

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
         SELECT  responsibility_id, responsibility_type, object_version_number
         FROM    hz_role_responsibility
         WHERE   cust_account_role_id = p_acct_role_id
         AND     responsibility_type IN ( g_user_role, g_revoked_user_role)
         ORDER BY responsibility_type desc;

      le_api_error              EXCEPTION;
      le_bo_api_error           EXCEPTION;

   BEGIN
      x_msg_count := 0;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In XX_CDH_WEBCONTACTS_PVT.save_bill_to_contact_role');

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_ACTION                           : ' || p_action);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_ORIG_SYSTEM                      : ' || p_orig_system);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_CUST_ACCT_CNT_OSR                : ' || p_cust_acct_cnt_osr);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_CUST_ACCOUNT_ID                  : ' || p_cust_account_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_SHIP_TO_ACCT_SITE_ID             : ' || p_ship_to_acct_site_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_BILL_TO_ACCT_SITE_ID             : ' || p_bill_to_acct_site_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_PARTY_ID                         : ' || p_party_id);
      $end

      OPEN   c_get_cust_account_role_cur ( p_cust_account_id, p_bill_to_acct_site_id, p_cust_acct_cnt_osr);
      FETCH  c_get_cust_account_role_cur INTO ln_acct_role_id, ln_cust_acct_roles_party_id, ln_object_version_number;
      IF c_get_cust_account_role_cur%NOTFOUND
      THEN
          XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role does not Exists ');
          ln_acct_role_id              := NULL;
          ln_cust_acct_roles_party_id  := NULL;
          ln_object_version_number     := NULL;
      END IF; -- c_get_cust_account_role_cur%NOTFOUND
      CLOSE  c_get_cust_account_role_cur;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_acct_role_id              : ' || ln_acct_role_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_cust_acct_roles_party_id  : ' || ln_cust_acct_roles_party_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_object_version_number     : ' || ln_object_version_number);
      $end

      dbms_output.put_line('ln_cust_acct_roles_party_id '||ln_cust_acct_roles_party_id);

      IF ln_cust_acct_roles_party_id IS NOT NULL
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role Exists for Account Site');
         l_role_rec_type.cust_account_role_id  := ln_acct_role_id;
         l_role_rec_type.cust_account_id       := p_cust_account_id;
         l_role_rec_type.primary_flag          := 'N';
         l_role_rec_type.role_type             := 'CONTACT';
         l_role_rec_type.party_id              := p_party_id;

	 IF p_action = 'X'
	 THEN
             l_role_rec_type.status                := 'I';
         ELSE
             l_role_rec_type.status                := 'A';
         END IF;


         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before update account role for Account Site');
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_role_rec_type.status : ' || l_role_rec_type.status);
         $end

         hz_cust_account_role_v2pub.update_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_role_rec_type
                     , p_object_version_number          => ln_object_version_number
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );

         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After update account role for Account Site, here is the status: ' || x_return_status);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Role id: '|| ln_acct_role_id);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact OSR: ' || p_cust_acct_cnt_osr);
         $end

         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_bo_api_error;
         END IF;

         OPEN   c_get_role_responsibility_cur (ln_acct_role_id);
         FETCH  c_get_role_responsibility_cur INTO ln_get_responsibility_id, lc_responsibility_type, ln_object_version_number;
         IF c_get_role_responsibility_cur%NOTFOUND
         THEN
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role responsibility does not Exists ');
            ln_get_responsibility_id    := NULL;
            lc_responsibility_type      := NULL;
            ln_object_version_number    := NULL;
         END IF; -- c_get_role_responsibility_cur%NOTFOUND
         CLOSE  c_get_role_responsibility_cur;

         l_role_responsibility_rec                       := NULL;
         l_role_responsibility_rec.cust_account_role_id  := l_role_id;
         l_role_responsibility_rec.primary_flag          := 'N';

         -- --------------------------------------------------------------------------
         -- Since the HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility does not
         -- have capability to delete / end date a responsibility we are revoking this
         -- by updating the Role to REVOKED_SELF_SERVICE_ROLE.
         -- --------------------------------------------------------------------------

	       dbms_output.put_line('p_action '||p_action);

         IF p_action in ('D','X')
         THEN
             l_role_responsibility_rec.responsibility_type   := g_revoked_user_role;
         ELSE
             l_role_responsibility_rec.responsibility_type   := g_user_role;
         END IF; -- p_action ='D'

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before update role resp for Account Site');
         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_get_responsibility_id  : ' || ln_get_responsibility_id );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'lc_responsibility_type    : ' || lc_responsibility_type   );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_object_version_number  : ' || ln_object_version_number );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Setting Responsibility To : ' || l_role_responsibility_rec.responsibility_type);
         $end

         IF ln_get_responsibility_id IS NOT NULL
         THEN

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility role resp');

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
            IF p_action NOT IN ('D','X')
            THEN
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility role resp');

               l_role_responsibility_rec.created_by_module     := 'BO_API';

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
            ELSE
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'skipping Invocation of create_role_responsibility as Action ' || p_action);
            END IF; -- p_action <> 'D'
         END IF; -- ln_get_responsibility_id IS NOT NULL

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After update role resp for Account Site');
      ELSE
         IF p_action not in ('D','X')
         THEN
            l_role_rec_type.party_id              := p_party_id;
            l_role_rec_type.cust_account_id       := p_cust_account_id;
            l_role_rec_type.cust_acct_site_id     := p_bill_to_acct_site_id;
            l_role_rec_type.primary_flag          := 'N';
            l_role_rec_type.role_type             := 'CONTACT';
            l_role_rec_type.orig_system_reference := p_cust_acct_cnt_osr;
            l_role_rec_type.orig_system           := p_orig_system;
            l_role_rec_type.status                := 'A';
            l_role_rec_type.created_by_module     := 'BO_API';

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before create account role for Account Site');

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_role_rec_type
                     , x_cust_account_role_id           => l_role_id
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After create account role for Account Site');

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Role id : ' || l_role_id);

            l_role_responsibility_rec                       := NULL;
            l_role_responsibility_rec.cust_account_role_id  := l_role_id;
            l_role_responsibility_rec.responsibility_type   := g_user_role;
            --l_role_responsibility_rec.primary_flag          := 'Y'; -- Commented by Kathir
            l_role_responsibility_rec.primary_flag          := 'N';
            l_role_responsibility_rec.created_by_module     := 'BO_API';

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before create role resp for Account Site');

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

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After create role resp for Account Site');
         ELSE
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Skipping Invocation of create_cust_account_role as Action ' || p_action);
         END IF; -- p_action <> 'D'
      END IF; -- ln_cust_acct_roles_party_id IS NOT NULL

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN le_bo_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_bill_to_contact_role');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

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
      lc_responsibility_type         VARCHAR2(255);

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
         SELECT  responsibility_id, responsibility_type, object_version_number
         FROM    hz_role_responsibility
         WHERE   cust_account_role_id = p_acct_role_id
         AND     responsibility_type IN ( g_user_role, g_revoked_user_role);

      le_api_error              EXCEPTION;
      le_bo_api_error           EXCEPTION;

   BEGIN
      x_msg_count := 0;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In save_account_contact_role');

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_ACTION             : ' || p_action);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_ORIG_SYSTEM        : ' || p_orig_system);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_CUST_ACCT_CNT_OSR  : ' || p_cust_acct_cnt_osr);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_CUST_ACCOUNT_ID    : ' || p_cust_account_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'P_PARTY_ID           : ' || p_party_id);
      $end

      OPEN   c_get_cust_account_role_cur ( p_cust_account_id, p_cust_acct_cnt_osr);
      FETCH  c_get_cust_account_role_cur INTO ln_acct_role_id, ln_cust_acct_roles_party_id, ln_object_version_number;
      IF c_get_cust_account_role_cur%NOTFOUND
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role does not Exists ');
         ln_acct_role_id              := NULL;
         ln_cust_acct_roles_party_id  := NULL;
         ln_object_version_number     := NULL;
      END IF; -- c_get_cust_account_role_cur%NOTFOUND
      CLOSE  c_get_cust_account_role_cur;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_acct_role_id              : ' || ln_acct_role_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_cust_acct_roles_party_id  : ' || ln_cust_acct_roles_party_id);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_object_version_number     : ' || ln_object_version_number);
      $end

      IF ln_cust_acct_roles_party_id IS NOT NULL
      THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role Exists');
         l_role_rec_type.cust_account_role_id  := ln_acct_role_id;
         l_role_rec_type.cust_account_id       := p_cust_account_id;
         l_role_rec_type.primary_flag          := 'N';
         l_role_rec_type.role_type             := 'CONTACT';
         l_role_rec_type.party_id              := p_party_id;
         
	 IF p_action = 'X'
	 THEN
              l_role_rec_type.status                := 'I';
         ELSE
              l_role_rec_type.status                := 'A';
	 END IF;

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before update account role');
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'l_role_rec_type.status : ' || l_role_rec_type.status);

         hz_cust_account_role_v2pub.update_cust_account_role(
                       p_init_msg_list                  => FND_API.G_FALSE
                     , p_cust_account_role_rec          => l_role_rec_type
                     , p_object_version_number          => ln_object_version_number
                     , x_return_status                  => x_return_status
                     , x_msg_count                      => x_msg_count
                     , x_msg_data                       => x_msg_data
                     );

         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After update account role, status: ' || x_return_status);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Role id: '|| ln_acct_role_id);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Contact OSR: ' || p_cust_acct_cnt_osr);
         $end

         IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
         THEN
            raise le_bo_api_error;
         END IF;

         OPEN   c_get_role_responsibility_cur (ln_acct_role_id);
         FETCH  c_get_role_responsibility_cur INTO ln_get_responsibility_id, lc_responsibility_type, ln_object_version_number;
         IF c_get_role_responsibility_cur%NOTFOUND
         THEN
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Account role responsibility does not Exists ');
            ln_get_responsibility_id      := NULL;
            lc_responsibility_type        := NULL;
            ln_object_version_number      := NULL;
         END IF; -- c_get_role_responsibility_cur%NOTFOUND
         CLOSE  c_get_role_responsibility_cur;

         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_get_responsibility_id  : ' || ln_get_responsibility_id );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'lc_responsibility_type    : ' || lc_responsibility_type   );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_object_version_number  : ' || ln_object_version_number );
         $end

         l_role_responsibility_rec                       := NULL;
         l_role_responsibility_rec.cust_account_role_id  := ln_acct_role_id;
         l_role_responsibility_rec.primary_flag          := 'N';
         --l_role_responsibility_rec.primary_flag          := 'Y'; --Commented By Kathir

         IF p_action in ('D','X')
         THEN
             l_role_responsibility_rec.responsibility_type   := g_revoked_user_role;
         ELSE
             l_role_responsibility_rec.responsibility_type   := g_user_role;
         END IF; -- p_action ='D'

         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before update role resp');
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Setting responsibility_type : ' || l_role_responsibility_rec.responsibility_type);
         $end

         IF ln_get_responsibility_id IS NOT NULL
         THEN

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility role resp');

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
            IF p_action not in ('D','X')
            THEN
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility role resp');

               l_role_responsibility_rec.created_by_module     := 'BO_API';

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
            ELSE
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Skipping Invocation of create_role_responsibility with Action ' || p_action);
            END IF; -- p_action <> 'D'

         END IF; -- ln_get_responsibility_id IS NOT NULL

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After role resp');

      ELSE
         IF p_action not in ('D','X')
         THEN
            l_role_rec_type.party_id              := p_party_id;
            l_role_rec_type.cust_account_id       := p_cust_account_id;
            l_role_rec_type.primary_flag          := 'N';
            l_role_rec_type.role_type             := 'CONTACT';
            l_role_rec_type.orig_system_reference := p_cust_acct_cnt_osr;
            l_role_rec_type.orig_system           := p_orig_system;
            l_role_rec_type.status                := 'A';
            l_role_rec_type.created_by_module     := 'BO_API';

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before create account role');

            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role ( p_init_msg_list         => FND_API.G_FALSE
                                                                , p_cust_account_role_rec => l_ROLE_REC_TYPE
                                                                , x_cust_account_role_id  => l_role_id
                                                                , x_return_status         => x_return_status
                                                                , x_msg_count             => x_msg_count
                                                                , x_msg_data              => x_msg_data
                                                                );

            IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
            THEN
               raise le_bo_api_error;
            END IF;

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Role id : ' || l_role_id);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After create account role');

            l_role_responsibility_rec                       := NULL;
            l_role_responsibility_rec.cust_account_role_id  := l_role_id;
            l_role_responsibility_rec.responsibility_type   := g_user_role;
            --l_role_responsibility_rec.primary_flag          := 'Y'; --Commented by Kathir
            l_role_responsibility_rec.primary_flag          := 'N';
            l_role_responsibility_rec.created_by_module     := 'BO_API';

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before create role resp');

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

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'After create role resp');
         ELSE
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Skipping Invocation of create_cust_account_role with Action ' || p_action);
         END IF; -- p_action <> 'D'
      END IF; -- ln_cust_acct_roles_party_id IS NOT NULL

      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

      WHEN le_bo_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_account_contact_role');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In save_account_contact_role (2)');
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_action                      := ' || p_action                );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_parent_obj                  := ' || p_parent_obj            );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_orig_system                 := ' || p_orig_system           );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_cust_acct_osr               := ' || p_cust_acct_osr         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_cust_acct_cnt_osr           := ' || p_cust_acct_cnt_osr     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_cust_account_id             := ' || p_cust_account_id       );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_party_id                    := ' || p_party_id              );
      $end

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

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Add Self Service Role');

         l_role_resp_obj := hz_role_responsibility_obj.create_object
                                    ( p_responsibility_type      => g_user_role
                                    , p_primary_flag             => 'N'
                                    );

         l_cust_acct_cnt_bo.contact_role_objs.EXTEND;
         l_cust_acct_cnt_bo.contact_role_objs (1) := l_role_resp_obj;
      ELSE
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Remove Self Service Role');
      END IF; -- p_action IN ('C', 'U')

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Before Call of HZ_CUST_ACCT_CONTACT_BO_PUB.save_cust_acct_contact_bo');

      hz_cust_acct_contact_bo_pub.save_cust_acct_contact_bo
                                 ( p_init_msg_list              => fnd_api.g_true
                                 , p_validate_bo_flag           => fnd_api.g_false
                                 , p_cust_acct_contact_obj      => l_cust_acct_cnt_bo
                                 , p_created_by_module          => 'BO_API'
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

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parent OSR  : '||lv_parent_osr);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parent type : '||lv_parent_obj);
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Parent ID   : '||ln_parent_id);
      $end

      x_return_status := FND_API.G_RET_STS_SUCCESS;
      x_msg_count     := 0;
      x_msg_data      := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN le_bo_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
         -- x_return_status := FND_API.G_RET_STS_ERROR;

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_account_contact_role (2)');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

   END save_account_contact_role;

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

      lc_user_row_table           EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
      lc_user_data_table          EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
      --added new params for R12 Upgrade Retrofit
      lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ :=
                                  EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null,null,null,null);
      lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:=
                                  EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);

      ln_counter                  PLS_INTEGER   := 1;
      ln_counter1                 PLS_INTEGER   := 1;
      l_attr_group_id             NUMBER;
      l_attr_name                 VARCHAR2(50)  := 'XX_CDH_CUST_ACCT_SITE';
      l_attr_group_name           VARCHAR2(60)  := 'WEBCONTACTS';
      l_failed_row_id_list        VARCHAR2 (1000);
      l_errorcode                 VARCHAR2 (100);

      l_errors_tbl                ERROR_HANDLER.Error_Tbl_Type;
      le_api_error                EXCEPTION;

   BEGIN

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In save_acct_site_ext' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_orig_system                 := ' || p_orig_system                 );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_id        := ' || p_ship_to_acct_site_id        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_osr       := ' || p_ship_to_acct_site_osr       );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_id        := ' || p_bill_to_acct_site_id        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_osr       := ' || p_bill_to_acct_site_osr       );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_id            := ' || p_contact_party_id            );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_osr           := ' || p_contact_party_osr           );
      $end
      
      --YAA 08/27/2008
      --Ensure if operation = 'D' the appropriate descriptive_flexfield_name and descriptive_flex_context_code
      --are sent to retrieve the attribute group ID.
      
      IF p_operation = 'D'
      THEN
        OPEN   c_ego_attr_grp_id ('XX_CDH_CUST_ACCT_SITE', 'DELETED_WEBCONTACTS');
        FETCH  c_ego_attr_grp_id INTO l_attr_group_id;
        CLOSE  c_ego_attr_grp_id;
      ELSE
        OPEN   c_ego_attr_grp_id (l_attr_name,l_attr_group_name);
        FETCH  c_ego_attr_grp_id INTO l_attr_group_id;
        CLOSE  c_ego_attr_grp_id;
      END IF;

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


      --YAA 08/27/2008
      --Commented the following for deleting record to ensure data is sync not deleted.
      
      IF p_operation = 'D'
      THEN
         --lc_user_row_table(1).transaction_type   := EGO_USER_ATTRS_DATA_PVT.G_DELETE_MODE;
         --lc_user_row_table(1).transaction_type   := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;
         UPDATE XX_CDH_ACCT_SITE_EXT_B 
         SET attr_group_id    = l_attr_group_id,
	     last_update_date = SYSDATE
         WHERE CUST_ACCT_SITE_ID = p_ship_to_acct_site_id
         AND N_EXT_ATTR2         = p_bill_to_acct_site_id
	 AND attr_group_id       <> l_attr_group_id
	 AND C_EXT_ATTR20        = p_contact_party_osr;
         
      ELSE
         lc_user_row_table(1).transaction_type   := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;
  

      OPEN   c_ext_attr_name (l_attr_name,l_attr_group_name);
      FETCH  c_ext_attr_name bulk collect into lc_ext_attr_name;
      CLOSE  c_ext_attr_name;

      ln_counter1 := 0;

      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'lc_user_row_table(1).Row_identifier     := ' || lc_user_row_table(1).Row_identifier   );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'lc_user_row_table(1).Attr_group_id      := ' || lc_user_row_table(1).Attr_group_id    );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'lc_user_row_table(1).transaction_type   := ' || lc_user_row_table(1).transaction_type );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'lc_ext_attr_name size                   := ' || lc_ext_attr_name.COUNT);
      $end

      FOR ln_counter IN 1 .. lc_ext_attr_name.COUNT
      LOOP

         lc_user_data_table.extend;
         lc_user_data_table(ln_counter)                 := lc_data_temp_obj;
         lc_user_data_table(ln_counter).ROW_IDENTIFIER  := p_ship_to_acct_site_id;
         lc_user_data_table(ln_counter).ATTR_NAME       := lc_ext_attr_name(ln_counter).END_USER_COLUMN_NAME;

         IF lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME = 'C_EXT_ATTR19'
         THEN
            -- WEBCONTACTS_BILL_TO_OSR
            lc_user_data_table(ln_counter).ATTR_VALUE_STR := p_bill_to_acct_site_osr;
         ELSIF lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME = 'C_EXT_ATTR20'
         THEN
            -- WEBCONTACTS_CONTACT_PARTY_OSR
            lc_user_data_table(ln_counter).ATTR_VALUE_STR := p_contact_party_osr;
         ELSIF lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME = 'N_EXT_ATTR1'
         THEN
            -- WEBCONTACTS_CONTACT_PARTY_ID
            lc_user_data_table(ln_counter).ATTR_VALUE_NUM := p_contact_party_id;
         ELSIF lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME = 'N_EXT_ATTR2'
         THEN
            -- WEBCONTACTS_BILL_TO_SITE_ID
            lc_user_data_table(ln_counter).ATTR_VALUE_NUM := p_bill_to_acct_site_id;
         ELSIF lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME = 'N_EXT_ATTR20'
         THEN
            -- WEBCONTACTS_BILL_TO_SITE_ID
            lc_user_data_table(ln_counter).ATTR_VALUE_NUM := NULL;
         ELSE
            NULL;
         END IF;

         $if $$enable_debug
         $then
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ln_counter := ' || ln_counter);
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'END_USER_COLUMN_NAME    := ' || lc_ext_attr_name(ln_counter).END_USER_COLUMN_NAME    );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'APPLICATION_COLUMN_NAME := ' || lc_ext_attr_name(ln_counter).APPLICATION_COLUMN_NAME );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ROW_IDENTIFIER          := ' || lc_user_data_table(ln_counter).ROW_IDENTIFIER        );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ATTR_NAME               := ' || lc_user_data_table(ln_counter).ATTR_NAME             );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ATTR_VALUE_STR          := ' || lc_user_data_table(ln_counter).ATTR_VALUE_STR        );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'ATTR_VALUE_NUM          := ' || lc_user_data_table(ln_counter).ATTR_VALUE_NUM        );
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, ' ');
         $end

      END LOOP;  -- lc_ext_attr_name(i).APPLICATION_COLUMN_NAME

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Acct_site_Record ');
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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Acct_site_Record Status ' || x_return_status);
      IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
      THEN
         ERROR_HANDLER.Get_Message_List(l_errors_tbl);
         FOR ln_counter1 IN 1..l_errors_tbl.COUNT
         LOOP
            fnd_message.set_name('xxcom', l_errors_tbl(ln_counter1).message_text);
         END LOOP;
         raise le_api_error;
      END IF;
      
   END IF; -- p_operation = 'D'  
   
      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

  
   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_acct_site_ext');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In save_ship_to_contact' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_operation                 := ' || p_operation               );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_orig_system               := ' || p_orig_system             );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_id      := ' || p_ship_to_acct_site_id    );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_osr     := ' || p_ship_to_acct_site_osr   );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id    );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr   );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id        );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr       );
      $end

      x_msg_count         := 0;
      x_bill_to_operation := NULL;

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'p_bill_to_acct_site_id = ' || p_bill_to_acct_site_id || ' Operation = ' || p_operation);
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
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Bill To Association Should be added' );
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
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Insert Bill To for Contact' );

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

         END IF; -- NOT l_ship_record_exists

      ELSIF p_operation = 'D'
      THEN

         -- ---------------------------------------------------------
         -- Since BSD is sending delete for site that does not exist,
         -- Check if record exists in Acoount Site Extensible Table
         -- before calling the CDH Extensible functions for delete
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

	    IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
	    THEN
	       raise le_api_error;
	    END IF;

         IF l_bill_record_exists
         THEN

            -- ---------------------------------------------------------
            -- Delete Ship To Information from Acoount Site Extensible Table
            -- ---------------------------------------------------------
            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Delete Ship To and Bill To Association for contact' );
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
	       x_msg_data := 'No record exist in XX_CDH_AS_EXT_WEBCTS_V for the Site ID '||p_ship_to_acct_site_id;
               raise le_api_error;
            END IF;

            -- ---------------------------------------------------------
            -- Check if record exists in Acoount Site Extensible Table
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


	    IF(x_return_status <> FND_API.G_RET_STS_SUCCESS)
	    THEN
	       raise le_api_error;
	    END IF;

            IF NOT l_bill_record_exists
            THEN
                XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Bill To Association Should be deleted' );
                x_bill_to_operation := 'D';
            ELSE
               x_bill_to_operation := null;
            END IF; -- l_record_exists
         ELSE

            XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Bill To Association Does not exist. No Action Required' );
            --x_bill_to_operation := null;
	    x_bill_to_operation := 'D';
         END IF; -- l_bill_record_exists

      END IF; --  p_operation = 'C'

            dbms_output.put_line ('x_bill_to_operation '||x_bill_to_operation);


      x_return_status     := FND_API.G_RET_STS_SUCCESS;
      x_msg_count         := 0;
      x_msg_data          := NULL;

   EXCEPTION
      WHEN le_api_error THEN
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.save_ship_to_contact');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);
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
     CURSOR c_contact_bill_to (p_contact_party_id NUMBER, p_bill_to_acct_site_id NUMBER)
     IS
       SELECT *
       FROM   XX_CDH_AS_EXT_WEBCTS_V
       WHERE  webcontacts_contact_party_id = p_contact_party_id
       AND    webcontacts_bill_to_site_id  = p_bill_to_acct_site_id;

     lc_contact_bill_to            c_contact_bill_to%ROWTYPE;
   BEGIN

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In check_bill_to_contact' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_orig_system               := ' || p_orig_system               );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr     );
      $end

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
         fnd_message.set_token('ROUTINE', g_pkg_name || '.check_bill_to_contact');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(1,x_msg_data);

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

      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'In check_bill_to_contact (2)' );
      $if $$enable_debug
      $then
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_orig_system               := ' || p_orig_system               );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_id          := ' || p_contact_party_id          );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_contact_party_osr         := ' || p_contact_party_osr         );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_id      := ' || p_ship_to_acct_site_id      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_ship_to_acct_site_osr     := ' || p_ship_to_acct_site_osr     );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_id      := ' || p_bill_to_acct_site_id      );
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'In p_bill_to_acct_site_osr     := ' || p_bill_to_acct_site_osr     );
      $end

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
         fnd_message.set_token('ROUTINE', g_pkg_name || '.check_bill_to_contact (2)');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         -- x_msg_data := 'Unexpected Error while fetching id for OSR - ' || SQLERRM;

   END check_bill_to_contact;

END XX_CDH_WEBCONTACTS_PVT;
/
