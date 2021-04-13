CREATE OR REPLACE PROCEDURE XX_RPA_CUST_CONTACT_PRC ( P_CUSTOMER_NAME     IN hz_cust_accounts_all.account_name%TYPE,    -- MANDATORY PARAMETER
													   P_CUSTOMER_NUMBER   IN hz_cust_accounts_all.account_number%TYPE,  -- MANDATORY PARAMETER
													   P_CUSTOMER_DOC_ID   IN xx_cdh_ebl_contacts.cust_doc_id%TYPE,      -- MANDATORY PARAMETER
													   P_FIRST_NAME        IN hz_parties.person_first_name%TYPE,         -- MANDATORY PARAMETER
													   P_LAST_NAME         IN hz_parties.person_last_name%TYPE,          -- MANDATORY PARAMETER
													   P_EMAIL_ADDRESS     IN hz_contact_points.email_address%TYPE,      -- MANDATORY PARAMETER
													   P_AREA_CODE         IN hz_contact_points.phone_area_code%TYPE,    -- MANDATORY PARAMETER
													   P_PHONE_NUMBER      IN hz_contact_points.phone_number%TYPE,       -- MANDATORY PARAMETER
													   P_EXTENSION         IN hz_contact_points.phone_extension%TYPE     -- OPTIONAL PARAMETER
													   )
AS
 /* VARIABLES DEFINES */
 l_count              NUMBER := NULL;
 l_cust_acct_id       NUMBER := NULL;
 l_party_id           NUMBER := NULL;
 l_ebl_doc_contact_id NUMBER := NULL;
 
 /* PARTY CREATION VARIABLES */
 lv_return_status    VARCHAR2 (500);
 lv_msg_count        NUMBER;
 lv_msg_data         VARCHAR2 (500);
 lv_party_id         NUMBER := NULL;
 lv_party_number     NUMBER := NULL;
 lv_profile_id       NUMBER;
 lv_api_message      VARCHAR2 (4000);
 lv_msg_index_out    NUMBER;
 lv_api_name         VARCHAR2 (150);
 lv_table_name       VARCHAR (150);
 lv_party_c_status   VARCHAR2 (1);
 lv_person_rec       hz_party_v2pub.person_rec_type;
 
 /* Variables To Establish A Relation Between The Person Party And The Customer */
 v_return_status     VARCHAR2 (500);
 v_msg_count         NUMBER;
 v_msg_data          VARCHAR2 (500);
 v_api_message       VARCHAR2 (4000);
 v_msg_index_out     NUMBER;
 v_api_name          VARCHAR2 (150);
 v_table_name        VARCHAR2 (150);
 v_oc_c_status       VARCHAR2 (1);
 v_org_contact_id    NUMBER := NULL;
 v_party_rel_id      NUMBER := NULL;
 v_party_id          NUMBER := NULL;
 v_party_number      VARCHAR2 (150);
 v_org_contact_rec   hz_party_contact_v2pub.org_contact_rec_type;
 
 /* Variables to Create the Contact at Account level of the Customer */
 p_cr_cust_acc_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;
 x_api_message            VARCHAR2 (4000);
 x_msg_index_out          NUMBER;
 x_cust_account_role_id   NUMBER;
 x_return_status          VARCHAR2 (2000);
 x_msg_count              NUMBER;
 x_msg_data               VARCHAR2 (2000);
 
 /* Variables to Create a Contact Point for the contact person */
 kv_return_status       VARCHAR2 (500);
 kv_msg_count           NUMBER;
 kv_msg_data            VARCHAR2 (500);
 kv_api_message         VARCHAR2 (4000);
 kv_msg_index_out       NUMBER;
 kv_api_name            VARCHAR2 (150);
 kv_table_name          VARCHAR (150);
 kv_contact_point_id    NUMBER := NULL;
 kv_contact_point_rec   hz_contact_point_v2pub.contact_point_rec_type;
 kv_phone_rec           hz_contact_point_v2pub.phone_rec_type;
 kv_email_rec           hz_contact_point_v2pub.email_rec_type;

BEGIN
  DBMS_OUTPUT.put_line ('****PROCESS START****');
  
  BEGIN
    SELECT cust_account_id
    INTO L_CUST_ACCT_ID
    FROM hz_cust_accounts_all
    WHERE account_number = P_CUSTOMER_NUMBER
    AND UPPER(account_name) = UPPER(P_CUSTOMER_NAME);
  
  EXCEPTION 
  WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('CUST_ACCOUNT_ID NOT EXISTS');
  END;
  
  BEGIN
    SELECT COUNT(*)
    INTO L_COUNT
    FROM XX_CDH_EBL_CONTACTS XCEC,
         HZ_ORG_CONTACTS HOC,
         HZ_RELATIONSHIPS HR,
         HZ_PARTIES HP
    WHERE 1=1
    AND HOC.org_contact_id = XCEC.org_contact_id
    AND HOC.party_relationship_id = HR.relationship_id
    AND HR.relationship_code = 'CONTACT_OF'
    AND HR.subject_id = HP.party_id
    AND XCEC.cust_doc_id = P_CUSTOMER_DOC_ID --162784618
    AND XCEC.attribute1 = L_CUST_ACCT_ID  --47474858
    AND UPPER(HP.person_first_name) = UPPER(P_FIRST_NAME)
    AND UPPER(HP.person_last_name) = UPPER(P_LAST_NAME);

  EXCEPTION
  WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('L_COUNT VALUE NOT EXISTS');
  L_COUNT := NULL;
  END;
  DBMS_OUTPUT.put_line ('L_COUNT: '|| L_COUNT);
  
  IF L_COUNT = 0
  THEN
    DBMS_OUTPUT.put_line ('Creating Contact as a Party of type PERSON');
    
    BEGIN
     SELECT max(party_id)
     INTO lv_party_id
     FROM hz_parties 
     WHERE upper(person_first_name) = upper(P_FIRST_NAME)
     AND upper(person_last_name) = upper(P_LAST_NAME)
     AND status = 'A';
     
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lv_party_id := NULL;
	 
    WHEN OTHERS THEN
	 DBMS_OUTPUT.PUT_LINE ('Execution Failed for lv_party_id '|| SQLERRM);
	 lv_party_id := 0;
	END;
    
    IF lv_party_id IS NULL
    THEN
     lv_person_rec.person_first_name := P_FIRST_NAME;
     lv_person_rec.person_last_name := P_LAST_NAME;
     --lv_person_rec.party_rec.orig_system := 'USER_ENTERED';
     --lv_person_rec.party_rec.orig_system_reference := '12345671'; --<<Must be unique>>
     lv_person_rec.party_rec.status := 'A';
     lv_person_rec.created_by_module := 'HZ_CPUI';
    
     --
     hz_party_v2pub.create_person (p_init_msg_list      => fnd_api.g_false,
                                   p_person_rec         => lv_person_rec,
                                   x_party_id           => lv_party_id,
                                   x_party_number       => lv_party_number,
                                   x_profile_id         => lv_profile_id,
                                   x_return_status      => lv_return_status,
                                   x_msg_count          => lv_msg_count,
                                   x_msg_data           => lv_msg_data
                                   );
     --	
     IF lv_return_status <> fnd_api.g_ret_sts_success
     THEN
       FOR i IN 1 .. fnd_msg_pub.count_msg
       LOOP
          fnd_msg_pub.get (p_msg_index          => i,
                           p_encoded            => fnd_api.g_false,
                           p_data               => lv_msg_data,
                           p_msg_index_out      => lv_msg_index_out
                           );
          lv_api_message := lv_api_message || ' ~ ' || lv_msg_data;
          DBMS_OUTPUT.put_line ('Error: ' || lv_api_message);
       END LOOP;
     ELSIF (lv_return_status = fnd_api.g_ret_sts_success)
     THEN
       DBMS_OUTPUT.put_line ('********Success***********');
       DBMS_OUTPUT.put_line ('lv_party_id: ' || lv_party_id);     
     END IF;
   
     COMMIT; 
    END IF;
    DBMS_OUTPUT.put_line ('Exits lv_party_id: ' || lv_party_id);
    
       IF lv_party_id > 0
       THEN
        DBMS_OUTPUT.put_line ('Establish a relation between the Person Party and the Customer (main party)');
        
        BEGIN
          SELECT party_id
          INTO l_party_id
          FROM hz_cust_accounts_all
          WHERE account_number = P_CUSTOMER_NUMBER
          AND upper(account_name) = upper(P_CUSTOMER_NAME);
        
        EXCEPTION 
        WHEN OTHERS THEN
         DBMS_OUTPUT.put_line ('CUST_ACCOUNT_ID NOT EXISTS');
        END;
        DBMS_OUTPUT.put_line ('l_party_id: '|| l_party_id);
        
        BEGIN
         SELECT HOC.org_contact_id, HR.party_id
         INTO v_org_contact_id, v_party_id
         FROM 
              HZ_ORG_CONTACTS HOC,
              HZ_RELATIONSHIPS HR
         WHERE 1=1
         AND HOC.party_relationship_id = HR.relationship_id
         AND HR.relationship_code = 'CONTACT_OF'
         AND HR.relationship_type = 'CONTACT'
         AND HR.subject_id = lv_party_id
         AND HR.subject_type = 'PERSON'
		 AND HR.subject_table_name = 'HZ_PARTIES'
         AND HR.object_id = l_party_id
		 AND HR.object_table_name = 'HZ_PARTIES';
        
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
         v_org_contact_id := NULL;
		 v_party_id := NULL;
		 
		WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE ('Execution Failed for v_org_contact_id: ' || SQLERRM);
		 v_org_contact_id := 0;
		 v_party_id := 0;
        END;
        
        IF v_org_contact_id IS NULL
        THEN
         mo_global.init('AR');
         fnd_global.apps_initialize ( user_id      => fnd_global.user_id --4153007
                                     ,resp_id      => fnd_global.resp_id --50896
                                     ,resp_appl_id => fnd_global.resp_appl_id --222
									 );
		
         v_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
         v_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT'; 
         v_org_contact_rec.party_rel_rec.subject_id := lv_party_id;
         v_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
         v_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
         v_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
         v_org_contact_rec.party_rel_rec.object_id := l_party_id; 
         v_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
         v_org_contact_rec.party_rel_rec.start_date := SYSDATE;
         v_org_contact_rec.created_by_module := 'TCA_V1_API';
     
         hz_party_contact_v2pub.create_org_contact
                                      (p_init_msg_list        => fnd_api.g_true,
                                       p_org_contact_rec      => v_org_contact_rec,
                                       x_org_contact_id       => v_org_contact_id,
                                       x_party_rel_id         => v_party_rel_id,
                                       x_party_id             => v_party_id,
                                       x_party_number         => v_party_number,
                                       x_return_status        => v_return_status,
                                       x_msg_count            => v_msg_count,
                                       x_msg_data             => v_msg_data
                                       );
         --
          IF v_return_status <> fnd_api.g_ret_sts_success
          THEN
             FOR i IN 1 .. fnd_msg_pub.count_msg
             LOOP
                fnd_msg_pub.get (p_msg_index          => i,
                                 p_encoded            => fnd_api.g_false,
                                 p_data               => v_msg_data,
                                 p_msg_index_out      => v_msg_index_out
                                );
                v_api_message := v_api_message || ' ~ ' || v_msg_data;
             END LOOP;
               DBMS_OUTPUT.put_line('Error: '||v_api_message);
          ELSIF (v_return_status = fnd_api.g_ret_sts_success)
            THEN
            DBMS_OUTPUT.put_line ('*******Success*********');  
            DBMS_OUTPUT.put_line ('v_org_contact_id: '||v_org_contact_id);
            DBMS_OUTPUT.put_line ('v_party_id: '||v_party_id);
            DBMS_OUTPUT.put_line ('v_party_rel_id: '||v_party_rel_id);
          END IF;
		  
          COMMIT;
        END IF;
        DBMS_OUTPUT.put_line ('v_org_contact_id: ' || v_org_contact_id);
        DBMS_OUTPUT.put_line ('v_party_id: ' || v_party_id);
        
           IF v_party_id > 0
           THEN
            DBMS_OUTPUT.put_line ('Create the Contact at Account level of the Customer');
           
            p_cr_cust_acc_role_rec.party_id := v_party_id;
            p_cr_cust_acc_role_rec.cust_account_id := l_cust_acct_id;
            p_cr_cust_acc_role_rec.role_type := 'CONTACT';
            p_cr_cust_acc_role_rec.created_by_module := 'HZ_CPUI';
            mo_global.init ('AR');
            --
            hz_cust_account_role_v2pub.create_cust_account_role
                                                             ('T',
                                                              p_cr_cust_acc_role_rec,
                                                              x_cust_account_role_id,
                                                              x_return_status,
                                                              x_msg_count,
                                                              x_msg_data
                                                             );
            DBMS_OUTPUT.put_line ('***************************');
            DBMS_OUTPUT.put_line ('Output information ....');
        
            IF x_return_status <> fnd_api.g_ret_sts_success
            THEN
              FOR i IN 1 .. fnd_msg_pub.count_msg
              LOOP
                 fnd_msg_pub.get (p_msg_index          => i,
                                  p_encoded            => fnd_api.g_false,
                                  p_data               => x_msg_data,
                                  p_msg_index_out      => x_msg_index_out
                                 );
                 x_api_message := x_api_message || ' ~ ' || x_msg_data;
              END LOOP;
         
              DBMS_OUTPUT.put_line ('Error: ' || x_api_message);
            ELSIF (x_return_status = fnd_api.g_ret_sts_success)
            THEN
              DBMS_OUTPUT.put_line ('Success');
              DBMS_OUTPUT.put_line ( 'x_cust_account_role_id: '
                                    || x_cust_account_role_id
                                   );
            END IF;         
            DBMS_OUTPUT.put_line ('***************************');
            COMMIT;
           
               IF x_return_status = fnd_api.g_ret_sts_success
               THEN
                DBMS_OUTPUT.put_line ('Create a Contact Point for the contact person');
               
                BEGIN
                 SELECT max(contact_point_id)
                 INTO kv_contact_point_id
                 FROM hz_contact_points
                 WHERE owner_table_id = v_party_id
                 AND owner_table_name = 'HZ_PARTIES'
                 AND status = 'A'
                 AND phone_number = P_PHONE_NUMBER;
                
                EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                 kv_contact_point_id := NULL;
				
                WHEN OTHERS THEN
                 DBMS_OUTPUT.put_line ('Execution Failed for kv_contact_point_id: '|| SQLERRM); 
                 kv_contact_point_id := 0;
                END;
                
                IF kv_contact_point_id IS NULL
                THEN
                 kv_contact_point_rec.contact_point_type := 'PHONE';
                 kv_contact_point_rec.contact_point_purpose := 'BUSINESS';
                 kv_contact_point_rec.created_by_module := 'TCA_V1_API';
                 kv_contact_point_rec.status := 'A';
                 kv_email_rec.email_format := 'HTML';
                 kv_email_rec.email_address := P_EMAIL_ADDRESS;
                 kv_phone_rec.phone_area_code := P_AREA_CODE;
                 kv_phone_rec.phone_number := P_PHONE_NUMBER;
                 kv_phone_rec.phone_extension := P_EXTENSION;
                 kv_contact_point_rec.owner_table_name := 'HZ_PARTIES';
                 kv_contact_point_rec.owner_table_id := v_party_id;
                 kv_phone_rec.phone_line_type := 'MOBILE';
                 mo_global.init ('AR');
                
                 hz_contact_point_v2pub.create_contact_point
                                            (p_init_msg_list          => fnd_api.g_true,
                                             p_contact_point_rec      => kv_contact_point_rec,
                                             p_email_rec              => kv_email_rec,
                                             p_phone_rec              => kv_phone_rec,
                                             x_contact_point_id       => kv_contact_point_id,
                                             x_return_status          => kv_return_status,
                                             x_msg_count              => kv_msg_count,
                                             x_msg_data               => kv_msg_data
                                            );
                 --
                 IF kv_return_status <> fnd_api.g_ret_sts_success
                 THEN
                  FOR i IN 1 .. fnd_msg_pub.count_msg
                  LOOP
                     fnd_msg_pub.get (p_msg_index          => i,
                                      p_encoded            => fnd_api.g_false,
                                      p_data               => kv_msg_data,
                                      p_msg_index_out      => kv_msg_index_out
                                     );
                     kv_api_message := kv_api_message || ' ~ ' || kv_msg_data;
                     DBMS_OUTPUT.put_line ('Error:' || kv_api_message);
                  END LOOP;
                 ELSIF (kv_return_status = fnd_api.g_ret_sts_success)
                 THEN
                  DBMS_OUTPUT.put_line ('***************************');
                  DBMS_OUTPUT.put_line ('Output information ....');
                  DBMS_OUTPUT.put_line ('Success');
                  DBMS_OUTPUT.put_line ('kv_contact_point_id: ' || kv_contact_point_id);
                  DBMS_OUTPUT.put_line ('***************************');
                 END IF;
             
                 COMMIT;
               END IF;
               DBMS_OUTPUT.put_line ('kv_contact_point_id: '|| kv_contact_point_id);
               
                  IF kv_contact_point_id > 0
                  THEN
                    DBMS_OUTPUT.put_line ('Inserting the value in XX_CDH_EBL_CONTACTS Table');
                    BEGIN
                      SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
                      INTO l_ebl_doc_contact_id
                      FROM DUAL;
                    END;
                    
                    XX_CDH_EBL_CONTACTS_PKG.insert_row(
                                                        p_ebl_doc_contact_id => l_ebl_doc_contact_id
                                                       ,p_cust_doc_id        => P_CUSTOMER_DOC_ID
                                                       ,p_org_contact_id     => v_org_contact_id
                                                       ,p_cust_acct_site_id  => NULL
                                                       ,p_attribute1         => l_cust_acct_id
                                                       ,p_last_update_date   => SYSDATE
                                                       ,p_last_updated_by    => FND_GLOBAL.USER_ID
                                                       ,p_creation_date      => SYSDATE
                                                       ,p_created_by         => FND_GLOBAL.USER_ID
                                                       ,p_last_update_login  => FND_GLOBAL.USER_ID
                                                       );
                     COMMIT;
                     DBMS_OUTPUT.put_line ('Values Inserted Successfully');
                  END IF;
               END IF;
           END IF;     
       END IF;
  END IF;
  DBMS_OUTPUT.put_line ('****PROCESS END****');
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE ('ADD LOC PROCESS GOT FAILED DUE TO: ' || SQLERRM);
END;
/ 