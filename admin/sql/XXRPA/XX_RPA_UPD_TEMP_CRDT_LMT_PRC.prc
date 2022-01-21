create or replace PROCEDURE XX_RPA_UPD_TEMP_CRDT_LMT_PRC ( P_ACCOUNT_NUMBER  IN hz_cust_accounts_all.account_number%TYPE, -- MANDATORY PARAMETER
                                                                    P_TEMP_CREDIT_LMT    IN XX_CDH_CUST_ACCT_EXT_B.N_EXT_ATTR2%TYPE,  -- OPTIONAL PARAMETER
                                                                    P_STATUS          OUT VARCHAR2
                                                       )
AS
  l_cust_prof_amt_rec           hz_customer_profile_v2pub.cust_profile_amt_rec_type;
  l_START_DATE					XX_CDH_CUST_ACCT_EXT_B.D_EXT_ATTR1%TYPE;
  l_END_DATE					XX_CDH_CUST_ACCT_EXT_B.D_EXT_ATTR2%TYPE;
  l_EXTENSION_ID 				XX_CDH_CUST_ACCT_EXT_B.EXTENSION_ID%TYPE;
  l_ATTR_GROUP_ID				XX_CDH_CUST_ACCT_EXT_B.ATTR_GROUP_ID%TYPE;
  l_CREATED_BY					XX_CDH_CUST_ACCT_EXT_B.CREATED_BY%TYPE;
  l_CREATION_DATE				XX_CDH_CUST_ACCT_EXT_B.CREATION_DATE%TYPE;
  l_last_updated_by	 			XX_CDH_CUST_ACCT_EXT_B.last_updated_by%TYPE;
  l_last_update_date			XX_CDH_CUST_ACCT_EXT_B.last_update_date%TYPE;
  l_last_update_login           XX_CDH_CUST_ACCT_EXT_B.LAST_UPDATE_LOGIN%TYPE;
  l_C_EXT_ATTR1					XX_CDH_CUST_ACCT_EXT_B.C_EXT_ATTR1%TYPE;
  l_N_EXT_ATTR1					XX_CDH_CUST_ACCT_EXT_B.N_EXT_ATTR1%TYPE;
  l_N_EXT_ATTR3 				XX_CDH_CUST_ACCT_EXT_B.N_EXT_ATTR3%TYPE;
  l_version_num                 NUMBER;
  l_return_status               VARCHAR2 (500);
  l_msg_count                   NUMBER;
  l_msg_data                    VARCHAR2 (500);
  l_api_message                 VARCHAR2 (4000);
  l_msg_index_out               NUMBER;
  l_acct_profile_amt_id         NUMBER;
  l_ovn                         NUMBER;
  l_cust_account_profile_id     NUMBER;
  l_user_id                     NUMBER;
  l_responsibility_id           NUMBER;
  l_responsibility_appl_id      NUMBER;
  l_cust_acct_id				NUMBER;

BEGIN
  DBMS_OUTPUT.put_line ('********START THE PROCESS***********');

  l_acct_profile_amt_id := NULL;
  l_cust_account_profile_id := NULL;
  l_ovn := NULL;
  P_STATUS := NULL;

  BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
      INTO l_user_id,
           l_responsibility_id,
           l_responsibility_appl_id
      FROM fnd_user_resp_groups
     WHERE user_id=(SELECT user_id
                      FROM fnd_user
                     WHERE user_name='ODCDH')
       AND responsibility_id=(SELECT responsibility_id
                                FROM FND_RESPONSIBILITY
                               WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');

    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
  EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.put_line ('Exception in initializing : ' || SQLERRM);
    P_STATUS := 'ERROR: Not initializing';
  END;

  BEGIN
    SELECT hcpa.object_version_number,
           hcpa.cust_account_profile_id,
           hcpa.cust_acct_profile_amt_id,
	   hca.cust_account_id
    INTO l_ovn,
         l_cust_account_profile_id,
         l_acct_profile_amt_id,
	 l_cust_acct_id
    FROM hz_customer_profiles hcp,
         hz_cust_accounts hca,
         hz_cust_profile_amts hcpa,
		 XX_CDH_CUST_ACCT_EXT_B xcae
    WHERE hcp.cust_account_id = hca.cust_account_id
	  AND xcae.cust_account_id = hca.cust_account_id
      AND xcae.ATTR_GROUP_ID =
    (SELECT grp.ATTR_GROUP_ID
    FROM EGO_ATTR_GROUPS_V grp
    WHERE grp.APPLICATION_ID = 222
    AND grp.ATTR_GROUP_NAME  = 'TEMPORARY_CREDITLIMIT'
    AND grp.ATTR_GROUP_TYPE  = 'XX_CDH_CUST_ACCOUNT'
    )
      AND hcp.site_use_id IS NULL
      AND hcpa.cust_account_profile_id = hcp.cust_account_profile_id
      AND hcpa.currency_code           = 'USD'
      AND hcp.status = 'A'
      AND hca.account_number = P_ACCOUNT_NUMBER;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line ('Data Not Found: Customer Account Profile AM' || SQLERRM);
    P_STATUS := 'ERROR: No Data';
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line ('Data not exists: '|| SQLERRM);
    P_STATUS := 'ERROR: Data not exists';
  END;

  DBMS_OUTPUT.put_line ('cust_acct_profile_amt_id: ' || l_acct_profile_amt_id);
  DBMS_OUTPUT.put_line ('object_version_number: ' || l_ovn);

  l_cust_prof_amt_rec := NULL;
  l_version_num       := l_ovn;
  l_cust_prof_amt_rec.cust_account_profile_id := l_cust_account_profile_id;
  l_cust_prof_amt_rec.cust_acct_profile_amt_id := l_acct_profile_amt_id;
  ----------------------------------------------------------------------
 DBMS_OUTPUT.put_line ('********UPDATE START********');

 IF P_TEMP_CREDIT_LMT IS NOT NULL 
  THEN
  UPDATE XX_CDH_CUST_ACCT_EXT_B
  set N_EXT_ATTR2 = P_TEMP_CREDIT_LMT
  WHERE cust_account_id = l_cust_acct_id
  AND ATTR_GROUP_ID =
    (SELECT grp.ATTR_GROUP_ID
    FROM EGO_ATTR_GROUPS_V grp
    WHERE grp.APPLICATION_ID = 222
    AND grp.ATTR_GROUP_NAME  = 'TEMPORARY_CREDITLIMIT'
    AND grp.ATTR_GROUP_TYPE  = 'XX_CDH_CUST_ACCOUNT'
    )
 AND sysdate between D_EXT_ATTR1 and nvl(D_EXT_ATTR2,sysdate+1);
  DBMS_OUTPUT.put_line ('********UPDATE END********');
COMMIT;
END IF;

--DBMS_OUTPUT.put_line ('********INSERT START*******');
   SELECT ATTR_GROUP_ID  into l_ATTR_GROUP_ID 
   FROM EGO_ATTR_GROUPS_V 
   WHERE APPLICATION_ID = 222
   AND ATTR_GROUP_NAME  = 'TEMPORARY_CREDITLIMIT'
   AND ATTR_GROUP_TYPE  = 'XX_CDH_CUST_ACCOUNT';
   
SELECT C_EXT_ATTR1,
	N_EXT_ATTR1,
	N_EXT_ATTR3	
	into l_C_EXT_ATTR1 , 
	l_N_EXT_ATTR1,
	l_N_EXT_ATTR3
   FROM XX_CDH_CUST_ACCT_EXT_B 
   WHERE cust_account_id = l_cust_acct_id
  AND ATTR_GROUP_ID =
    (SELECT grp.ATTR_GROUP_ID
    FROM EGO_ATTR_GROUPS_V grp
    WHERE grp.APPLICATION_ID = 222
    AND grp.ATTR_GROUP_NAME  = 'TEMPORARY_CREDITLIMIT'
    AND grp.ATTR_GROUP_TYPE  = 'XX_CDH_CUST_ACCOUNT'
    );
  

l_EXTENSION_ID 				:= 			ego_extfwk_s.NEXTVAL;
l_CREATED_BY				:=			fnd_global.user_id;
l_CREATION_DATE				:=			sysdate;
l_last_updated_by 			:= 			fnd_global.user_id;
l_last_update_date			:= 			sysdate;
l_last_update_login	 :=fnd_global.user_id;
   DBMS_OUTPUT.put_line ('********INSERT START*******');
IF sysdate not between l_start_date and nvl(l_end_date ,sysdate+1) then
  INSERT into    
  XX_CDH_CUST_ACCT_EXT_B
  (EXTENSION_ID,
  CUST_ACCOUNT_ID,
  ATTR_GROUP_ID,
  CREATED_BY,
  CREATION_DATE,
  LAST_UPDATED_BY,
  LAST_UPDATE_DATE,
  LAST_UPDATE_LOGIN,
  C_EXT_ATTR1,
  C_EXT_ATTR2,
  C_EXT_ATTR3,
  C_EXT_ATTR4,
  C_EXT_ATTR5,
  C_EXT_ATTR6,
  C_EXT_ATTR7,
  C_EXT_ATTR8,
  C_EXT_ATTR9,
  C_EXT_ATTR10,
  C_EXT_ATTR11,
  C_EXT_ATTR12,
  C_EXT_ATTR13,
  C_EXT_ATTR14,
  C_EXT_ATTR15,
  C_EXT_ATTR16,
  C_EXT_ATTR17,
  C_EXT_ATTR18,
  C_EXT_ATTR19,
  C_EXT_ATTR20,
  N_EXT_ATTR1,
  N_EXT_ATTR2,
  N_EXT_ATTR3,
  N_EXT_ATTR4,
  N_EXT_ATTR5,
  N_EXT_ATTR6,
  N_EXT_ATTR7,
  N_EXT_ATTR8,
  N_EXT_ATTR9,
  N_EXT_ATTR10,
  N_EXT_ATTR11,
  N_EXT_ATTR12,
  N_EXT_ATTR13,
  N_EXT_ATTR14,
  N_EXT_ATTR15,
  N_EXT_ATTR16,
  N_EXT_ATTR17,
  N_EXT_ATTR18,
  N_EXT_ATTR19,
  N_EXT_ATTR20,
  D_EXT_ATTR1,
  D_EXT_ATTR2,
  D_EXT_ATTR3,
  D_EXT_ATTR4,
  D_EXT_ATTR5,
  D_EXT_ATTR6,
  D_EXT_ATTR7,
  D_EXT_ATTR8,
  D_EXT_ATTR9,
  D_EXT_ATTR10,
  BC_POD_FLAG,
  FEE_OPTION)
  
  VALUES
  
  (l_EXTENSION_ID,
  l_cust_acct_id,
  l_ATTR_GROUP_ID,
  l_CREATED_BY,
  l_CREATION_DATE,
  l_last_updated_by,
  l_last_update_date,
  l_last_update_login,
  l_C_EXT_ATTR1,
  '',
  'N',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  l_N_EXT_ATTR1,
  P_TEMP_CREDIT_LMT,
  l_N_EXT_ATTR3,
  l_cust_acct_id,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  sysdate,
  sysdate+30,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  '',
  NULL);
  
  
    COMMIT;
  END IF;
  
   DBMS_OUTPUT.put_line ('********INSERT END PROCESS****');
  ----------------------------------------------------------------------
  l_cust_prof_amt_rec.attribute1               := 'N';
  ----------------------------------------------------------------------

  DBMS_OUTPUT.put_line ('EXECUTING THE UPDATE API');

  hz_customer_profile_v2pub.update_cust_profile_amt
                            (FND_API.G_TRUE,
                             l_cust_prof_amt_rec,
                             l_version_num,
                             l_return_status,
                             l_msg_count,
                             l_msg_data
                             );
  IF l_return_status <> fnd_api.g_ret_sts_success
   THEN
      FOR i IN 1 .. fnd_msg_pub.count_msg
      LOOP
         fnd_msg_pub.get (p_msg_index          => i,
                          p_encoded            => fnd_api.g_false,
                          p_data               => l_msg_data,
                          p_msg_index_out      => l_msg_index_out
                         );
         l_api_message := l_api_message || ' ~ ' || l_msg_data;
         DBMS_OUTPUT.put_line ('Error:' || l_api_message);
      END LOOP;
      P_STATUS := 'ERROR: '||l_api_message;
   ELSIF (l_return_status = fnd_api.g_ret_sts_success)
   THEN
      DBMS_OUTPUT.put_line ('Success');
      P_STATUS := 'SUCCESS';
   END IF;
   COMMIT;
   DBMS_OUTPUT.put_line ('********END PROCESS***********');
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.put_line ('Exception in updating the Credit Limit.' || SQLERRM);
P_STATUS := 'ERROR: Record Failed';
END;
/