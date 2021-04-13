CREATE OR REPLACE PROCEDURE XX_RPA_UPD_CREDIT_LMT_PRC ( P_CUSTOMER_NUMBER IN hz_cust_accounts_all.account_number%TYPE, -- MANDATORY PARAMETER
                                                        P_CUSTOMER_NAME   IN hz_cust_accounts_all.account_name%TYPE,    -- MANDATORY PARAMETER
                                                        P_OVERALL_CRE_LMT IN hz_cust_profile_amts.overall_credit_limit%TYPE  -- MANDATORY PARAMETER
                                                       )
AS
l_cust_prof_amt_rec     hz_customer_profile_v2pub.cust_profile_amt_rec_type;
l_version_num           NUMBER;
l_return_status         VARCHAR2 (500);
l_msg_count             NUMBER;
l_msg_data              VARCHAR2 (500);
l_api_message           VARCHAR2 (4000);
l_msg_index_out         NUMBER;
l_acct_profile_amt_id   NUMBER;
l_ovn                   NUMBER;
   
BEGIN         
DBMS_OUTPUT.put_line ('********START THE PROCESS***********');

  l_acct_profile_amt_id := NULL;
  l_ovn := NULL;

  BEGIN
    SELECT
         cust_acct_profile_amt_id, 
         hcpa.object_version_number
    INTO l_acct_profile_amt_id, 
         l_ovn
    FROM ar_credit_histories h,
         hz_cust_accounts_all hca,
         hz_cust_profile_amts hcpa
    WHERE h.customer_id = hca.cust_account_id
    AND h.customer_id = hcpa.cust_account_id
    AND h.currency_code = hcpa.currency_code
    AND nvl(h.site_use_id,1) = nvl(hcpa.site_use_id,1)
    AND hca.account_number = P_CUSTOMER_NUMBER   		--hardcoded for now, can change at run time
    AND hca.account_name = P_CUSTOMER_NAME 	--hardcoded for now, can change at run time
    AND hcpa.currency_code = 'USD'; 			--hardcoded for now, can change at run time
  
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
  DBMS_OUTPUT.put_line ('Data Not Found: Customer Account Profile AM'); 
  END;

  DBMS_OUTPUT.put_line ('cust_acct_profile_amt_id: ' || l_acct_profile_amt_id);
  DBMS_OUTPUT.put_line ('object_version_number: ' || l_ovn);

  l_cust_prof_amt_rec.cust_acct_profile_amt_id := l_acct_profile_amt_id;
  --l_cust_prof_amt_rec.trx_credit_limit := 1000;                                                 
  l_cust_prof_amt_rec.overall_credit_limit := P_OVERALL_CRE_LMT;
  l_version_num := l_ovn;                       
     
  DBMS_OUTPUT.put_line ('EXECUTING THE UPDATE API');   
     
  hz_customer_profile_v2pub.update_cust_profile_amt
                            ('T',
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
   ELSIF (l_return_status = fnd_api.g_ret_sts_success)
   THEN
      DBMS_OUTPUT.put_line ('Success');
   END IF;
 
   COMMIT;
  
EXCEPTION 
WHEN OTHERS THEN
DBMS_OUTPUT.put_line ('Records comes in Exception....');
END;
/