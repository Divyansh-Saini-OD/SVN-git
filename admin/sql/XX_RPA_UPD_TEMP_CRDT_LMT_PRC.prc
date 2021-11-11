CREATE OR REPLACE PROCEDURE XX_RPA_UPD_TEMP_CRDT_LMT_PRC ( p_account_number     IN hz_cust_accounts_all.account_number%TYPE, -- MANDATORY PARAMETER
                                                           p_temp_credit_lmt    IN xx_cdh_cust_acct_ext_b.n_ext_attr2%TYPE,  -- OPTIONAL PARAMETER
                                                           p_status             OUT VARCHAR2
                                                         )
AS
    l_cust_prof_amt_rec          hz_customer_profile_v2pub.cust_profile_amt_rec_type;
    l_start_date                 xx_cdh_cust_acct_ext_b.D_EXT_ATTR1%TYPE;
    l_end_date                   xx_cdh_cust_acct_ext_b.D_EXT_ATTR2%TYPE;
    l_extension_id 		         xx_cdh_cust_acct_ext_b.extension_id%TYPE;
    l_attr_group_id		         xx_cdh_cust_acct_ext_b.attr_group_id%TYPE;
    l_created_by                 xx_cdh_cust_acct_ext_b.created_by%TYPE;
    l_creation_date              xx_cdh_cust_acct_ext_b.creation_date%TYPE;
    l_last_updated_by            xx_cdh_cust_acct_ext_b.last_updated_by%TYPE;
    l_last_update_date           xx_cdh_cust_acct_ext_b.last_update_date%TYPE;
    l_last_update_login          xx_cdh_cust_acct_ext_b.last_update_login%TYPE;
    l_c_ext_attr1                xx_cdh_cust_acct_ext_b.c_ext_attr1%TYPE;
    l_n_ext_attr1                xx_cdh_cust_acct_ext_b.n_ext_attr1%TYPE;
    l_n_ext_attr3                xx_cdh_cust_acct_ext_b.n_ext_attr3%TYPE;
    l_version_num                NUMBER;
    l_return_status              VARCHAR2 (500);
    l_msg_count                  NUMBER;
    l_msg_data                   VARCHAR2 (500);
    l_api_message                VARCHAR2 (4000);
    lv_d_ext_attr1               xx_cdh_cust_acct_ext_b.d_ext_attr1%TYPE;
    lv_d_ext_attr2               xx_cdh_cust_acct_ext_b.d_ext_attr2%TYPE;
    l_msg_index_out              NUMBER;
    l_acct_profile_amt_id        NUMBER;
    l_ovn                        NUMBER;
    l_cust_account_profile_id    NUMBER;
    l_user_id                    NUMBER;
    l_responsibility_id          NUMBER;
    l_responsibility_appl_id     NUMBER;
    l_cust_acct_id               NUMBER;
  
    CURSOR cur_date_details(p_cust_id varchar) 
	IS  
	SELECT c_ext_attr1,
	    n_ext_attr1,
	    n_ext_attr3,
	    d_ext_attr1,
	    d_ext_attr2
    FROM xx_cdh_cust_acct_ext_b 
    WHERE cust_account_id = p_cust_id
    AND attr_group_id =
        (SELECT grp.attr_group_id
        FROM ego_attr_groups_v grp
        WHERE grp.application_id = 222
        AND grp.attr_group_name  = 'TEMPORARY_CREDITLIMIT'
        AND grp.attr_group_type  = 'XX_CDH_CUST_ACCOUNT'
        )
	AND extension_id = (SELECT MAX(extension_id) 
	                    FROM xx_cdh_cust_acct_ext_b 
						WHERE cust_account_id = p_cust_id
                        AND attr_group_id =
                            (SELECT grp.attr_group_id
                            FROM ego_attr_groups_v grp
                            WHERE grp.application_id = 222
                            AND grp.attr_group_name  = 'TEMPORARY_CREDITLIMIT'
                            AND grp.attr_group_type  = 'XX_CDH_CUST_ACCOUNT'
                            ) 	
						);
	-- AND sysdate between D_EXT_ATTR1 and nvl(D_EXT_ATTR2,sysdate+1);
BEGIN
    DBMS_OUTPUT.put_line ('********START THE PROCESS***********');
    l_acct_profile_amt_id := NULL;
    l_cust_account_profile_id := NULL;
    l_ovn := NULL;
    p_status := NULL;

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
                                  FROM fnd_responsibility
                                 WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
    
      FND_GLOBAL.apps_initialize(
                           l_user_id,
                           l_responsibility_id,
                           l_responsibility_appl_id
                         );
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.put_line ('Exception in initializing : ' || SQLERRM);
        p_status := 'ERROR: Not initializing';
    END;

    BEGIN
        SELECT DISTINCT hcpa.object_version_number,
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
		 xx_cdh_cust_acct_ext_b xcae
    WHERE hcp.cust_account_id = hca.cust_account_id
        AND xcae.cust_account_id = hca.cust_account_id
        AND xcae.attr_group_id =
            (SELECT grp.attr_group_id
            FROM ego_attr_groups_v grp
            WHERE grp.application_id = 222
            AND grp.attr_group_name  = 'TEMPORARY_CREDITLIMIT'
            AND grp.attr_group_type  = 'XX_CDH_CUST_ACCOUNT')
      AND hcp.site_use_id IS NULL
      AND hcpa.cust_account_profile_id = hcp.cust_account_profile_id
      AND hcpa.currency_code           = 'USD'
      AND hcp.status = 'A'
      AND hca.account_number = p_account_number;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.put_line ('Data Not Found: Customer Account Profile AM' || SQLERRM);
        p_status := 'ERROR: No Data';
    WHEN OTHERS THEN
        DBMS_OUTPUT.put_line ('Data not exists: '|| SQLERRM);
        p_status := 'ERROR: Data not exists';
    END;
  
    l_cust_prof_amt_rec                             := NULL;
    l_version_num                                   := l_ovn;
    l_cust_prof_amt_rec.cust_account_profile_id     := l_cust_account_profile_id;
    l_cust_prof_amt_rec.cust_acct_profile_amt_id    := l_acct_profile_amt_id;
  ----------------------------------------------------------------------
    IF p_temp_credit_lmt IS NOT NULL THEN
	    DBMS_OUTPUT.put_line ('********UPDATE START********');
        UPDATE xx_cdh_cust_acct_ext_b
        SET n_ext_attr2 = p_temp_credit_lmt
        WHERE cust_account_id = l_cust_acct_id
        AND attr_group_id =
          (SELECT grp.attr_group_id
          FROM ego_attr_groups_v grp
          WHERE grp.application_id = 222
          AND grp.attr_group_name  = 'TEMPORARY_CREDITLIMIT'
          AND grp.attr_group_type  = 'XX_CDH_CUST_ACCOUNT'
          )
        AND SYSDATE BETWEEN d_ext_attr1 AND NVL(d_ext_attr2,SYSDATE+1);
        DBMS_OUTPUT.put_line ('********UPDATE END********');
        COMMIT;
    END IF;

    SELECT attr_group_id  
	INTO l_attr_group_id 
    FROM ego_attr_groups_v 
    WHERE application_id = 222
    AND attr_group_name  = 'TEMPORARY_CREDITLIMIT'
    AND attr_group_type  = 'XX_CDH_CUST_ACCOUNT';
   
    FOR cur_date_details_rec IN cur_date_details(l_cust_acct_id) 
	LOOP
    l_extension_id         := ego_extfwk_s.NEXTVAL;
    l_created_by           := fnd_global.user_id;
    l_creation_date        := SYSDATE;
    l_last_updated_by      := fnd_global.user_id;
    l_last_update_date     := SYSDATE;
    l_last_update_login    :=fnd_global.user_id;
    l_start_date           :=cur_date_details_rec.d_ext_attr1;
    l_end_date             :=cur_date_details_rec.d_ext_attr2;
        IF TRUNC(SYSDATE) NOT BETWEEN TRUNC(l_start_date) AND NVL(TRUNC(l_end_date) ,SYSDATE+1) THEN
            INSERT INTO xx_cdh_cust_acct_ext_b
            (extension_id,
            cust_account_id,
            attr_group_id,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            c_ext_attr1,
            c_ext_attr2,
            c_ext_attr3,
            c_ext_attr4,
            c_ext_attr5,
            c_ext_attr6,
            c_ext_attr7,
            c_ext_attr8,
            c_ext_attr9,
            c_ext_attr10,
            c_ext_attr11,
            c_ext_attr12,
            c_ext_attr13,
            c_ext_attr14,
            c_ext_attr15,
            c_ext_attr16,
            c_ext_attr17,
            c_ext_attr18,
            c_ext_attr19,
            c_ext_attr20,
            n_ext_attr1,
            n_ext_attr2,
            n_ext_attr3,
            n_ext_attr4,
            n_ext_attr5,
            n_ext_attr6,
            n_ext_attr7,
            n_ext_attr8,
            n_ext_attr9,
            n_ext_attr10,
            n_ext_attr11,
            n_ext_attr12,
            n_ext_attr13,
            n_ext_attr14,
            n_ext_attr15,
            n_ext_attr16,
            n_ext_attr17,
            n_ext_attr18,
            n_ext_attr19,
            n_ext_attr20,
            d_ext_attr1,
            d_ext_attr2,
            d_ext_attr3,
            d_ext_attr4,
            d_ext_attr5,
            d_ext_attr6,
            d_ext_attr7,
            d_ext_attr8,
            d_ext_attr9,
            d_ext_attr10,
            bc_pod_flag,
            fee_option)
        VALUES
            (l_extension_id,
            l_cust_acct_id,
            l_attr_group_id,
            l_created_by,
            l_creation_date,
            l_last_updated_by,
            l_last_update_date,
            l_last_update_login,
            cur_date_details_rec.c_ext_attr1,
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
            cur_date_details_rec.n_ext_attr1,
            p_temp_credit_lmt,
            cur_date_details_rec.n_ext_attr3,
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
    DBMS_OUTPUT.put_line ('********INSERT END PROCESS****');
        END IF;
    END LOOP;
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
          p_status := 'ERROR: '||l_api_message;
    ELSIF (l_return_status = fnd_api.g_ret_sts_success)
    THEN
        DBMS_OUTPUT.put_line ('Success');
        p_status := 'SUCCESS';
    END IF;
    COMMIT;
DBMS_OUTPUT.put_line ('********END PROCESS***********');
EXCEPTION
WHEN OTHERS THEN
    DBMS_OUTPUT.put_line ('Exception in updating the Credit Limit.' || SQLERRM);
    p_status := 'ERROR: Record Failed';
END;
/