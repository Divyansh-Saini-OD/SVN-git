CREATE OR REPLACE PACKAGE xx_od_hz_ui_util_pkg IS

  -- Author  : Sunildev
  -- Created : 01-Jun-11 1:51:37 PM
  -- Purpose : 

  -- Public type declarations
  FUNCTION check_row_deleteable
  (
    p_entity_name   IN VARCHAR2
   , -- table name
    p_data_source   IN VARCHAR2 DEFAULT NULL
   , -- if applicable
    p_entity_pk1    IN VARCHAR2
   , -- primary key
    p_entity_pk2    IN VARCHAR2 DEFAULT NULL
   , -- primary key pt. 2
    p_party_id      IN NUMBER DEFAULT NULL
   , -- only pass if available
    p_function_name IN VARCHAR2 DEFAULT NULL -- function name
  ) RETURN VARCHAR2;

END xx_od_hz_ui_util_pkg;
/
CREATE OR REPLACE PACKAGE BODY xx_od_hz_ui_util_pkg IS

  FUNCTION check_row_deleteable
  (
    p_entity_name   IN VARCHAR2 -- table name
   ,p_data_source   IN VARCHAR2 -- if applicable
   ,p_entity_pk1    IN VARCHAR2 -- primary key
   ,p_entity_pk2    IN VARCHAR2 -- primary key pt. 2
   ,p_party_id      IN NUMBER -- only pass if available
   ,p_function_name IN VARCHAR2 -- FND function name
  ) RETURN VARCHAR2 -- "Y" or "N" if we can delete the row
   IS
    l_deleteable_flag VARCHAR2(1) := 'N';
    l_return_status   VARCHAR2(1);
    l_msg_count       NUMBER;
    l_msg_data        VARCHAR2(2000);
    l_cust_acct_id    hz_cust_account_roles.party_id%TYPE;
    l_primary_flag    VARCHAR2(1);
		l_count           INTEGER :=0;
  BEGIN
    /*
    *  Special code added to support MOSR update functionality BASED ON PROFILE
    */
    IF p_entity_name = 'HZ_ORIG_SYS_REFERENCES'
    THEN
      IF nvl(fnd_profile.VALUE('HZ_SSM_VIEW_UPDATE_STATE'),
             'VIEW_ONLY') = 'CREATE_AND_UPDATE'
      THEN
        l_deleteable_flag := 'Y';
      END IF;
      RETURN l_deleteable_flag;
    END IF;
  
    /*
    *  Call the Data Sharing and Security API to check DSS security rules.
    *  The DSS function returns "T" or "F".
    */
  
    l_deleteable_flag := hz_dss_util_pub.test_instance(p_operation_code     => 'DELETE',
                                                       p_db_object_name     => p_entity_name,
                                                       p_instance_pk1_value => p_entity_pk1,
                                                       p_instance_pk2_value => p_entity_pk2,
                                                       p_user_name          => fnd_global.user_name,
                                                       x_return_status      => l_return_status,
                                                       x_msg_count          => l_msg_count,
                                                       x_msg_data           => l_msg_data);
  
    -- Default security to N if API fails
    IF l_return_status <> fnd_api.g_ret_sts_success
    THEN
      l_deleteable_flag := 'N';
    ELSIF l_deleteable_flag = 'T'
    THEN
      -- Will return FND_API.G_TRUE from HZ_DSS_UTIL_PUB
      l_deleteable_flag := 'Y';
    ELSE
      l_deleteable_flag := 'N';
    END IF;
  
    IF l_deleteable_flag = 'Y'
    THEN
      BEGIN 
			                                   
			  SELECT COUNT(1)
 				 INTO  l_count
				 FROM  hz_contact_points
         WHERE owner_table_id=p_party_id
				   AND status='A'
				   AND CONTACT_POINT_TYPE = 'EMAIL';
				 
				 IF l_count = 1 THEN
				    l_deleteable_flag := 'N';
				 END IF;
				         
      EXCEPTION
        WHEN OTHERS THEN
          l_deleteable_flag := 'Y';
      END;
    END IF;
  
    RETURN l_deleteable_flag;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
  END check_row_deleteable;
END xx_od_hz_ui_util_pkg;
/
