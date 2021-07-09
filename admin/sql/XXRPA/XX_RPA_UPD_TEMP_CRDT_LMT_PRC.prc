create or replace PROCEDURE XX_RPA_UPD_TEMP_CRDT_LMT_PRC ( P_ACCOUNT_NUMBER  IN hz_cust_accounts_all.account_number%TYPE, -- MANDATORY PARAMETER
                                                                    P_TEMP_CREDIT_LMT    IN XX_CDH_CUST_ACCT_EXT_B.N_EXT_ATTR2%TYPE,  -- OPTIONAL PARAMETER
                                                                    P_STATUS          OUT VARCHAR2
                                                       )
AS
  l_cust_prof_amt_rec           hz_customer_profile_v2pub.cust_profile_amt_rec_type;
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
           hcpa.cust_acct_profile_amt_id
    INTO l_ovn,
         l_cust_account_profile_id,
         l_acct_profile_amt_id
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
  IF P_TEMP_CREDIT_LMT IS NOT NULL THEN
  UPDATE XX_CDH_CUST_ACCT_EXT_B
  set N_EXT_ATTR2 = P_TEMP_CREDIT_LMT
  WHERE cust_account_id in (select cust_account_id FROM hz_cust_accounts)
  AND ATTR_GROUP_ID =
    (SELECT grp.ATTR_GROUP_ID
    FROM EGO_ATTR_GROUPS_V grp
    WHERE grp.APPLICATION_ID = 222
    AND grp.ATTR_GROUP_NAME  = 'TEMPORARY_CREDITLIMIT'
    AND grp.ATTR_GROUP_TYPE  = 'XX_CDH_CUST_ACCOUNT'
    );
  COMMIT;
  END IF;
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