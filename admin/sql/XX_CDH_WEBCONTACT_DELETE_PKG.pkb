create or replace
PACKAGE BODY XX_CDH_WEBCONTACT_DELETE_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_WEBCONTACT_DELETE_PKG.pkb                         |
-- | Description :  This package is used to delete the web contact and the   |
-- |                related dependent records.                               |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   10-Sep-2008 Kathirvel          Initial draft version           |
-- |1.1       28-Jan-2009 Kalyan             Modified the order of the calls |
-- |                                         to APIs. Removed the check on   |
-- |                                         status in l_contact_relation_cur|
-- |                                         in hz_cust_accounts.            |
-- |1.2       20-Nov-2013 Avinash            Modified for R12 upgrade retrofit|
-- +=========================================================================+
AS


-- +========================================================================+
-- | Name        :  Delete_Web_Contacts                                    |
-- | Description :  This Procedure is beeing called from BPEL to inactive  |
-- |                contact related all dependents                         |
-- +========================================================================+
PROCEDURE Delete_Web_Contacts(
p_orig_system                          IN VARCHAR2,
p_account_osr                          IN VARCHAR2,
p_contact_osr                          IN VARCHAR2,
x_message                              OUT NOCOPY  INACT_CP_RESULTS_OBJ_TBL,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2)
IS

l_msg_data              VARCHAR2(4000);
l_msg_count             NUMBER;
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
l_role_object_version   NUMBER;
l_resp_object_version   NUMBER;
l_role_rec_type                HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
l_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;


L_INACT_CP_RESULTS_OBJ_TBL      INACT_CP_RESULTS_OBJ_TBL := INACT_CP_RESULTS_OBJ_TBL();
L_HZ_MESSAGE_OBJ_TBL            HZ_MESSAGE_OBJ_TBL       := HZ_MESSAGE_OBJ_TBL();

   CURSOR l_web_exten_attbt IS
   select * 
   from   XX_CDH_AS_EXT_WEBCTS_V
   where  WEBCONTACTS_CONTACT_PARTY_OSR  = p_contact_osr;


   CURSOR l_web_contact IS
   select userid
   from   xx_external_users 
   where  contact_osr = p_contact_osr; 

   CURSOR l_cust_acct_id_cur IS
   select cust_account_id
   from   hz_cust_accounts 
   where  orig_system_reference = p_account_osr;

   CURSOR l_contact_relation_cur IS
   SELECT par.party_id 
   FROM   --hz_party_relationships par --commented for R12 upgrade retrofit
          hz_relationships par
   WHERE  par.subject_id = 
           (SELECT osr.owner_table_id 
            FROM   hz_orig_sys_references osr
            WHERE  osr.orig_system_reference = p_contact_osr 
            AND    osr.owner_table_name      = 'HZ_PARTIES'
            AND    osr.orig_system           = p_orig_system
            AND    osr.status                = 'A')
   AND    par.object_id = 
           (SELECT cua.party_id 
            FROM   hz_cust_accounts cua
            WHERE  cua.orig_system_reference = p_account_osr
            --AND    cua.status                = 'A'
            )
    AND    par.relationship_code = 'CONTACT_OF';


    CURSOR c_get_person_role_cur
    IS
    SELECT  car.cust_account_role_id,
	    hrr.responsibility_id,
	    car.object_version_number role_version, 
            hrr.object_version_number resp_version
    FROM    hz_cust_account_roles car, hz_role_responsibility hrr
    WHERE   car.cust_account_role_id  = hrr.cust_account_role_id
    AND     car.party_id = l_party_relation_id
    AND     (hrr.responsibility_type = 'SELF_SERVICE_USER' 
             OR
             (hrr.responsibility_type = 'REVOKED_SELF_SERVICE_ROLE'
	     AND car.status = 'A')
     );


FUNCTIONAL_ERROR           EXCEPTION;

BEGIN

  SAVEPOINT Process_Delete_Main;

    x_return_status 	:= 'S';

    IF p_account_osr IS NULL OR p_contact_osr IS NULL
    THEN
       l_return_status := 'E';
       l_error_message := 'Account OSR and Contact OSR mush have a value';
       RAISE FUNCTIONAL_ERROR;
    END IF;

     XX_CDH_ORG_CP_INACT_PUB.inactivate_contact_point(
                                  P_ACCOUNT_OSR          =>  p_account_osr
	                        , P_ORG_CONTACT_OSR      =>  p_contact_osr
				, P_OS                   =>  p_orig_system
				, X_MESSAGES             =>  L_INACT_CP_RESULTS_OBJ_TBL
				, X_MSG_DATA		 =>  l_msg_data
				, X_RETURN_STATUS        =>  l_return_status);
				
    IF l_return_status <> 'S'
    THEN
       RAISE FUNCTIONAL_ERROR;
    END IF;

    OPEN  l_cust_acct_id_cur;
    FETCH l_cust_acct_id_cur INTO l_cust_acct_id;
    CLOSE l_cust_acct_id_cur ;

    OPEN  l_contact_relation_cur;
    FETCH l_contact_relation_cur INTO l_party_relation_id;
    CLOSE l_contact_relation_cur ;

    OPEN  l_web_contact;
    FETCH l_web_contact INTO l_web_userid;
    CLOSE l_web_contact;
     
     FOR I IN c_get_person_role_cur
	LOOP

		 l_role_rec_type.cust_account_role_id  := I.cust_account_role_id;
		 l_role_rec_type.cust_account_id       := l_cust_acct_id;
		 l_role_rec_type.primary_flag          := 'N';
		 l_role_rec_type.status                := 'I';
		 l_role_object_version                 := I.role_version;

		 hz_cust_account_role_v2pub.update_cust_account_role(
			       p_init_msg_list                  => FND_API.G_FALSE
			     , p_cust_account_role_rec          => l_role_rec_type
			     , p_object_version_number          => l_role_object_version
			     , x_return_status                  => l_return_status
			     , x_msg_count                      => l_msg_count
			     , x_msg_data                       => l_msg_data
			     );

		  IF l_return_status <> 'S'
		  THEN
			    l_error_count := L_INACT_CP_RESULTS_OBJ_TBL.COUNT;
			    
			    l_return_status := 'E';
			    l_error_message := l_msg_data;

			    L_HZ_MESSAGE_OBJ_TBL.extend; 
			    L_HZ_MESSAGE_OBJ_TBL(1) := HZ_MESSAGE_OBJ(l_msg_data);

			     L_INACT_CP_RESULTS_OBJ_TBL.extend;
			     L_INACT_CP_RESULTS_OBJ_TBL(l_error_count+1) := INACT_CP_RESULTS_OBJ('E' 
									  , L_HZ_MESSAGE_OBJ_TBL
									  , NULL
									  , I.cust_account_role_id
									  );

			    RAISE FUNCTIONAL_ERROR;

			    EXIT;
		  END IF;

                 l_role_responsibility_rec.responsibility_id     := I.responsibility_id;
		 l_role_responsibility_rec.cust_account_role_id  := I.cust_account_role_id;
		 l_role_responsibility_rec.primary_flag          := 'N';
		 l_role_responsibility_rec.responsibility_type   := 'REVOKED_SELF_SERVICE_ROLE';
		 l_resp_object_version                           := I.resp_version;


		    HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
			     (  p_init_msg_list            => FND_API.G_FALSE
			     ,  p_role_responsibility_rec  => l_role_responsibility_rec
			     ,  p_object_version_number    => l_resp_object_version 
			     ,  x_return_status            => l_return_status
			     ,  x_msg_count                => l_msg_count
			     ,  x_msg_data                 => l_msg_data
			     );

		  IF l_return_status <> 'S'
		  THEN
			    l_error_count := L_INACT_CP_RESULTS_OBJ_TBL.COUNT;
			    
			    l_return_status := 'E';
			    l_error_message := l_msg_data;

			    L_HZ_MESSAGE_OBJ_TBL.extend; 
			    L_HZ_MESSAGE_OBJ_TBL(1) := HZ_MESSAGE_OBJ(l_msg_data);

			     L_INACT_CP_RESULTS_OBJ_TBL.extend;
			     L_INACT_CP_RESULTS_OBJ_TBL(l_error_count+1) := INACT_CP_RESULTS_OBJ('E' 
									  , L_HZ_MESSAGE_OBJ_TBL
									  , NULL
									  , I.cust_account_role_id
									  );

			    RAISE FUNCTIONAL_ERROR;

			    EXIT;
		  END IF;
		  
	END LOOP;

     IF l_web_userid IS NOT NULL 
     THEN

		     XX_CDH_WEBCONTACTS_BO_PUB.save_role_resp ( 
					      p_orig_system                 => p_orig_system
					    , p_cust_acct_osr               => p_account_osr
					    , p_cust_acct_cnt_osr           => p_contact_osr
					    , p_cust_acct_site_osr          => NULL
					    , p_record_type                 => 'CD'
					    , p_permission_flag             => 'L'
					    , p_action                      => 'D'
					    , p_web_contact_id              => l_web_userid
					    , px_cust_account_id            => l_cust_acct_id
					    , px_ship_to_acct_site_id       => l_cust_acct_site_id
					    , px_bill_to_acct_site_id       => l_cust_acct_bill_id
					    , px_party_id                   => l_party_relation_id
					    , x_web_user_status             => l_web_user_status
					    , x_return_status               => l_return_status
					    , x_messages                    => L_HZ_MESSAGE_OBJ_TBL
					    );


		     IF l_return_status <> 'S'
		     THEN
			    l_error_count := L_INACT_CP_RESULTS_OBJ_TBL.COUNT;

			    FOR j IN 1 .. L_HZ_MESSAGE_OBJ_TBL.COUNT
			    LOOP      

			       L_INACT_CP_RESULTS_OBJ_TBL.extend;
			       L_INACT_CP_RESULTS_OBJ_TBL(j+l_error_count) := INACT_CP_RESULTS_OBJ('E' 
								  , L_HZ_MESSAGE_OBJ_TBL
								  , NULL
								  , l_acct_site_osr
								  );

			    END LOOP;
				RAISE FUNCTIONAL_ERROR;
		     END IF;

		UPDATE xx_external_users
		SET    status = '2'
		WHERE  contact_osr = p_contact_osr; 

		L_HZ_MESSAGE_OBJ_TBL := HZ_MESSAGE_OBJ_TBL();

		IF SQL%ROWCOUNT = 0 
		THEN
		    l_error_count := L_INACT_CP_RESULTS_OBJ_TBL.COUNT;
		    
		    l_return_status := 'E';
		    l_error_message := 'Failed to update the status in xx_external_users for the contact OSR '||p_contact_osr;

		    L_HZ_MESSAGE_OBJ_TBL.extend; 
		    L_HZ_MESSAGE_OBJ_TBL(1) := HZ_MESSAGE_OBJ('Failed to update the status in xx_external_users for the contact OSR '||p_contact_osr);

		     L_INACT_CP_RESULTS_OBJ_TBL.extend;
		     L_INACT_CP_RESULTS_OBJ_TBL(l_error_count+1) := INACT_CP_RESULTS_OBJ('E' 
								  , L_HZ_MESSAGE_OBJ_TBL
								  , NULL
								  , l_web_userid
								  );

		    RAISE FUNCTIONAL_ERROR;
		END IF;

	END IF;
        
EXCEPTION
   WHEN FUNCTIONAL_ERROR 
   THEN
      ROLLBACK TO Process_Delete_Main;
      x_message       := L_INACT_CP_RESULTS_OBJ_TBL;
      x_return_status := NVL(l_return_status,'E');
      x_error_message := l_error_message; 

   WHEN OTHERS 
   THEN
      ROLLBACK TO Process_Delete_Main;
      x_return_status := 'E';
      x_error_message := SQLERRM; 
END Delete_Web_Contacts;

END XX_CDH_WEBCONTACT_DELETE_PKG;
/

Show Errors;