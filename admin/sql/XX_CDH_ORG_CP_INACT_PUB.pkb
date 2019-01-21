create or replace
PACKAGE BODY XX_CDH_ORG_CP_INACT_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_CDH_ORG_CP_INACT_PUB                                              		|
-- | Description : Package body for inactivating contact points when a request is sent to inactivate    |
-- |               a contact.  Procedure inactivate_contact_point will be called from SaveContactMaster |
-- |               BPEL process.									|
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       04-Aug-2008 Yusuf Ali          Initial draft version.      			 	|
-- |1.1       23-Oct-2013 Deepak V           I0024 - Changes done for R12 Upgrade retrofit.             |
-- |1.2       19-Aug-2016 Havish K           Removed the schema references as per R12.2 Retrofit changes|                                                                                                   |
-- +====================================================================================================+
*/


  g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_CDH_ORG_CP_INACT_PUB';
  g_module                       CONSTANT VARCHAR2(30) := 'CRM';
  g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();

   -- ===========================================================================
   -- | Name             : inactivate_contact_point
   -- | Description      : 
   -- |
   -- |
   -- | Parameters :                   
   -- |
   -- ===========================================================================
   
    PROCEDURE inactivate_contact_point(P_ACCOUNT_OSR          IN               HZ_CUST_ACCOUNTS.ORIG_SYSTEM_REFERENCE%TYPE
	                        , P_ORG_CONTACT_OSR          IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				, P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE 
				, X_MESSAGES                 OUT NOCOPY       INACT_CP_RESULTS_OBJ_TBL
				, X_MSG_DATA		     OUT NOCOPY       VARCHAR2
				, X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                 )
   AS
     
    
      --  #param 1  P_ACCOUNT_OSR   	        Account OSR in hz_cust_accounts table
      --  #param 2  P_ORG_CONTACT_OSR        	Contact OSR in hz_orig_sys_references table
      --  #param 3  P_OS      			Orig system 
      --  #param 4  X_RETURN_OBJECT  		return contact point OSR, message, and status
      



	CURSOR  c_get_contact_points      ( ACCOUNT_OSR         VARCHAR2
					  , OS                  VARCHAR2
					  , ORG_CONTACT_OSR     VARCHAR2)
	IS
         SELECT   HPR.PARTY_ID 
		, HCP.ORIG_SYSTEM_REFERENCE
		, HCP.CONTACT_POINT_TYPE
		, HCP.CONTACT_POINT_ID
    	 --FROM   HZ_PARTY_RELATIONSHIPS HPR, -- Commented for R12 Upgrade retrofit
         FROM HZ_RELATIONSHIPS hpr, --Added for R12 Upgrade retrofit
		       HZ_CONTACT_POINTS HCP
         WHERE  HPR.PARTY_ID = HCP.OWNER_TABLE_ID
         AND  HCP.STATUS = 'A'
         AND  HPR.subject_id = 
		   (SELECT osr.owner_table_id 
		    FROM   hz_orig_sys_references osr
		    WHERE  osr.orig_system_reference = ORG_CONTACT_OSR 
		    AND    osr.owner_table_name      = 'HZ_PARTIES'
		    AND    osr.orig_system           = OS
		    AND    osr.status                = 'A')
         AND   HPR.object_id = 
		   (SELECT cua.party_id 
		    FROM   hz_cust_accounts cua
		    WHERE  cua.orig_system_reference = ACCOUNT_OSR
		    AND    cua.status                = 'A')
         --AND   HPR.party_relationship_type = 'CONTACT_OF'; -- Commented for R12 Upgrade retrofit
         AND  HPR.relationship_code = 'CONTACT_OF'; --Added for R12 Upgrade retrofit

    

	
	le_api_error                    EXCEPTION;

	--VARIABLES FOR HOLDING API RETURN VALUES
	lc_account_osr			HZ_CUST_ACCOUNTS.ORIG_SYSTEM_REFERENCE%TYPE;
	lc_org_contact_osr      HZ_ORIG_SYS_REFERENCES.OWNER_TABLE_NAME%TYPE;
	lc_os                   HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE;
	lb_log_error			VARCHAR2(5) DEFAULT fnd_api.g_false;--FND_API.G_FALSE;
	lc_msg_data			VARCHAR2(2000);
        l_message                       HZ_MESSAGE_OBJ_TBL; --VARCHAR2(2000);
        l_status                        VARCHAR2(1);
        l_count                         NUMBER;
        l_counter                       NUMBER := 1;
        L_INACT_CP_RESULTS_OBJ_TBL      INACT_CP_RESULTS_OBJ_TBL := INACT_CP_RESULTS_OBJ_TBL();


      
   BEGIN
       --dbms_output.put_line('before for loop');
       FOR i IN c_get_contact_points(P_ACCOUNT_OSR, P_OS, P_ORG_CONTACT_OSR)
       LOOP
           --dbms_output.put_line('come :'||i.ORIG_SYSTEM_REFERENCE);
           if i.CONTACT_POINT_TYPE = 'PHONE'
           THEN
		-- call update_phone API
                inactivate_phone(i.PARTY_ID    
	                              , i.ORIG_SYSTEM_REFERENCE
				      , P_OS                          
				      , l_message
                                      , lc_msg_data
				      , l_status
                                      );
      --dbms_output.put_line('Phone: ' || l_status);
      
          elsif i.CONTACT_POINT_TYPE = 'EMAIL'
          then
		-- call update_email API
              inactivate_email( i.PARTY_ID    
	                              , i.ORIG_SYSTEM_REFERENCE
				      , P_OS                          
				      , l_message
                                      , lc_msg_data
				      , l_status
                                      );
         
          elsif i.CONTACT_POINT_TYPE = 'WEB'
          then
		-- call update_web API
              inactivate_web( i.PARTY_ID    
	                              , i.ORIG_SYSTEM_REFERENCE
				      , P_OS                          
				      , l_message
                                      , lc_msg_data
				      , l_status
                                      );    
                                      
          elsif  i.CONTACT_POINT_TYPE is not null
          then
          lc_msg_data := 'Different contact point identified that API does not inactivate: '|| i.CONTACT_POINT_TYPE;
          l_status := FND_API.G_RET_STS_ERROR;
          
          
      --dbms_output.put_line('Email: ' || l_status);                                      
	   END IF;
        
	L_INACT_CP_RESULTS_OBJ_TBL.extend;
       
	L_INACT_CP_RESULTS_OBJ_TBL(l_counter) := INACT_CP_RESULTS_OBJ(l_status  	--'S' or 'E' STATUS FROM API CALL
							  , l_message                     -- Error message FROM API CALL
                                                          , lc_msg_data
							  , i.ORIG_SYSTEM_REFERENCE      			 -- Contact Point OSR
							  );
        l_counter :=  l_counter + 1;
       END LOOP;	
        l_count := L_INACT_CP_RESULTS_OBJ_TBL.count;
        
	IF (l_count < 1)
	THEN
		lc_msg_data := lc_msg_data || 'No contact points to inactivate for this contact, '|| P_ORG_CONTACT_OSR;
                --dbms_output.put_line(lc_msg_data);
		x_return_status := FND_API.G_RET_STS_SUCCESS;		

	END IF;

      	x_return_status := FND_API.G_RET_STS_SUCCESS;
        x_msg_data := lc_msg_data;
        x_messages := L_INACT_CP_RESULTS_OBJ_TBL;

   EXCEPTION
     
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.inactivate_contact_point');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         X_MSG_DATA := fnd_message.get();
         x_messages := L_INACT_CP_RESULTS_OBJ_TBL;
        
   END inactivate_contact_point;
PROCEDURE inactivate_phone(
                                      --P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE -- Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Addded for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      )
AS

   l_phone_bo              HZ_PHONE_CP_BO;
   l_return_phone_bo       HZ_PHONE_CP_BO;
   l_contact_pref_objs     HZ_CONTACT_PREF_OBJ;
   l_dummy                 NUMBER;
   l_return_status         VARCHAR2(30);
   l_msg_count             NUMBER;
   l_msg_data              VARCHAR2(2000);
   l_message               HZ_MESSAGE_OBJ_TBL;--VARCHAR2(2000); 
   l_phone_id              NUMBER;
   l_phone_os              VARCHAR2(50);
   l_phone_osr             VARCHAR2(50);
   l_action                VARCHAR2(1);
   l_parent_id             NUMBER;
   l_parent_os             VARCHAR2(50);
   l_parent_osr            VARCHAR2(50);
   l_parent_obj            VARCHAR2(50);
   x_phone_obj             HZ_PHONE_CP_BO;
   tot_count              NUMBER;
   l_relationship_party_id number;--P_RELATIONSHIP_PARTY_ID;
   l_parent_type           VARCHAR2(50);



BEGIN

l_phone_bo := HZ_PHONE_CP_BO.create_object(
                 p_orig_system => P_OS,
                 p_orig_system_reference => P_CONTACT_POINT_OSR,
                 p_status => 'I');


l_relationship_party_id := P_RELATIONSHIP_PARTY_ID;
l_parent_type := 'ORG_CONTACT';

   HZ_CONTACT_POINT_BO_PUB.save_phone_bo(
    p_validate_bo_flag      => fnd_api.g_false,
    p_phone_obj          => l_phone_bo,
    p_created_by_module   => 'BO_API',
    p_obj_source          =>            null,
    p_return_obj_flag         => null,
    x_return_status       => l_return_status,
    x_messages            => l_message,
    x_return_obj          =>   l_return_phone_bo,
     x_phone_id         => l_phone_id,
     x_phone_os         => l_phone_os,
     x_phone_osr       => l_phone_osr,
     px_parent_id      => l_relationship_party_id,
     px_parent_os       => l_parent_os,
     px_parent_osr     => l_parent_osr,
     px_parent_obj_type  => l_parent_type
  );
 
X_RETURN_STATUS := l_return_status;
X_MESSAGES := l_message;
/*
dbms_output.put_line('Return Status: '||l_return_status);
 dbms_output.put_line('Msg Count    : '||l_msg_count);
 IF(l_msg_count > 1) THEN
   FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
     dbms_output.put_line('*****'||FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
   END LOOP;
 ELSE
   dbms_output.put_line('Msg Data     : '||l_msg_data);
 END IF;
 dbms_output.put_line('Phone ID        : '||l_phone_id);
 dbms_output.put_line('Phone OS/OSR    : '||l_phone_os||','||l_phone_osr);
*/
 EXCEPTION
     
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.inactivate_phone');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         X_MSG_DATA := fnd_message.get();
         x_messages := l_message;

END inactivate_phone;


PROCEDURE inactivate_email(
                                      --P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE -- Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Added for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      )
AS

 l_email_bo              HZ_EMAIL_CP_BO;
 l_return_email_bo              HZ_EMAIL_CP_BO;
   l_contact_pref_objs     HZ_CONTACT_PREF_OBJ;
   l_orig_sys_objs         HZ_ORIG_SYS_REF_OBJ;
   l_dummy                 NUMBER;
   l_return_status         VARCHAR2(30);
   l_msg_count             NUMBER;
   l_msg_data              VARCHAR2(2000);
   l_message               HZ_MESSAGE_OBJ_TBL;--VARCHAR2(2000); 
   l_email_id              NUMBER;
   l_email_os              VARCHAR2(50);
   l_email_osr             VARCHAR2(50);
   l_action                VARCHAR2(1);
   l_parent_id             NUMBER;
   l_parent_os             VARCHAR2(50);
   l_parent_osr            VARCHAR2(50);
   l_parent_obj            VARCHAR2(50);
   x_email_obj              HZ_EMAIL_CP_BO;
   l_relationship_party_id number;--P_RELATIONSHIP_PARTY_ID;
   l_parent_type           VARCHAR2(50);

BEGIN

l_parent_obj := 'ORG_CONTACT';
 l_action := 'S';
 IF(l_action = 'S') THEN
   
   l_email_bo := HZ_EMAIL_CP_BO.create_object(
                 p_orig_system => P_OS,
                 p_orig_system_reference => P_CONTACT_POINT_OSR,
                 --p_email_format => 'MAILTEXT',
                 --p_email_address => 'ALI7@OD.COM',
               -- p_PRIMARY_BY_PURPOSE => 'Y',
               -- p_CONTACT_POINT_PURPOSE => 'BUSINESS',
                 p_STATUS => 'I'
                 );
                 
l_relationship_party_id := P_RELATIONSHIP_PARTY_ID;
l_parent_type := 'ORG_CONTACT';                 
 
 HZ_CONTACT_POINT_BO_PUB.save_email_bo(
    p_validate_bo_flag    => fnd_api.g_false,
    p_email_obj          => l_email_bo,
    p_created_by_module   => 'BO_API',
    p_obj_source          => null,
    p_return_obj_flag     => NULL,--               VARCHAR2 := fnd_api.g_true,
    x_return_status       => l_return_status,
     x_messages            => l_message,
     x_return_obj         => l_return_email_bo,
    x_email_id         => l_email_id,
     x_email_os         => l_email_os,
     x_email_osr       => l_email_osr,
     px_parent_id      => l_relationship_party_id,
     px_parent_os       => l_parent_os,
     px_parent_osr     => l_parent_osr,
     px_parent_obj_type  => l_parent_type
  );
  
  
 END IF;

  X_RETURN_STATUS := l_return_status;
  X_MESSAGES := l_message;
/*
 dbms_output.put_line('Return Status: '||l_return_status);
 dbms_output.put_line('Msg Count    : '||l_msg_count);
 IF(l_msg_count > 1) THEN
   FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
     dbms_output.put_line('#######'||FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
   END LOOP;
 ELSE
   dbms_output.put_line('Msg Data     : '||l_msg_data);
 END IF;
 dbms_output.put_line('email ID        : '||l_email_id);
 dbms_output.put_line('email OS/OSR    : '||l_email_os||','||l_email_osr);
*/
 EXCEPTION
     
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.inactivate_email');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         X_MSG_DATA := fnd_message.get();
         x_messages := l_message;



END inactivate_email;
   
   
PROCEDURE inactivate_web(
                                      --P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE -- Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Added for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      )
AS

   l_web_bo                HZ_WEB_CP_BO;
   l_return_web_bo         HZ_WEB_CP_BO;
   l_contact_pref_objs     HZ_CONTACT_PREF_OBJ;
   l_orig_sys_objs         HZ_ORIG_SYS_REF_OBJ;
   l_dummy                 NUMBER;
   l_return_status         VARCHAR2(30);
   l_msg_count             NUMBER;
   l_msg_data              VARCHAR2(2000);
   l_message               HZ_MESSAGE_OBJ_TBL;
   l_web_id              NUMBER;
   l_web_os              VARCHAR2(50);
   l_web_osr             VARCHAR2(50);
   l_action                VARCHAR2(1);
   l_parent_id             NUMBER;
   l_parent_os             VARCHAR2(50);
   l_parent_osr            VARCHAR2(50);
   l_parent_obj            VARCHAR2(50);
   x_web_obj               HZ_WEB_CP_BO;
   l_relationship_party_id number;            --P_RELATIONSHIP_PARTY_ID;
   l_parent_type           VARCHAR2(50);

BEGIN

 l_parent_obj := 'ORG_CONTACT';
 l_action := 'S';
 IF(l_action = 'S') THEN
   
   l_web_bo := HZ_WEB_CP_BO.create_object(
                 p_orig_system => P_OS,
                 p_orig_system_reference => P_CONTACT_POINT_OSR,
                 p_STATUS => 'I'
                 );
                 
l_relationship_party_id := P_RELATIONSHIP_PARTY_ID;
l_parent_type := 'ORG_CONTACT';                 
 
 HZ_CONTACT_POINT_BO_PUB.save_web_bo(
    p_validate_bo_flag    => fnd_api.g_false,
    p_web_obj             => l_web_bo,
    p_created_by_module   => 'BO_API',
    p_obj_source          => null,
    p_return_obj_flag     => NULL,--               VARCHAR2 := fnd_api.g_true,
    x_return_status       => l_return_status,
    x_messages            => l_message,
    x_return_obj          => l_return_web_bo,
    x_web_id              => l_web_id,
    x_web_os         => l_web_os,
     x_web_osr       => l_web_osr,
     px_parent_id      => l_relationship_party_id,
     px_parent_os       => l_parent_os,
     px_parent_osr     => l_parent_osr,
     px_parent_obj_type  => l_parent_type
  );
  
 END IF;

  X_RETURN_STATUS := l_return_status;
  X_MESSAGES := l_message;
/*
 dbms_output.put_line('Return Status: '||l_return_status);
 dbms_output.put_line('Msg Count    : '||l_msg_count);
 IF(l_msg_count > 1) THEN
   FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
     dbms_output.put_line('#######'||FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
   END LOOP;
 ELSE
   dbms_output.put_line('Msg Data     : '||l_msg_data);
 END IF;
 dbms_output.put_line('email ID        : '||l_email_id);
 dbms_output.put_line('email OS/OSR    : '||l_email_os||','||l_email_osr);
*/
 EXCEPTION
     
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.inactivate_email');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         X_MSG_DATA := fnd_message.get();
         x_messages := l_message;

END inactivate_web;   
   
   
END XX_CDH_ORG_CP_INACT_PUB;


/

SHOW ERRORS;