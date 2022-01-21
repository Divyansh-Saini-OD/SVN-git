 DECLARE
 l_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := NVL ( FND_GLOBAL.USER_ID, -1);
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := NVL ( FND_GLOBAL.LOGIN_ID, -1);
 BEGIN

    l_location := 'TRUNCATE  TABLE xx_c2t_cc_token_crypto_vault ';
    DBMS_OUTPUT.PUT_LINE( l_location );
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.xx_c2t_cc_token_crypto_vault';
		
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	
    l_location := 'INSERTING Values in table xx_c2t_cc_token_crypto_vault';
    DBMS_OUTPUT.PUT_LINE( l_location );			
		  INSERT INTO xx_c2t_cc_token_crypto_vault
			(  card_id
             , credit_card_number_orig
             , cc_key_label_orig
             , first_six
             , last_four
             , credit_card_number_new
             , cc_key_label_new
             , token_number_orig
             , token_key_label_orig
             , token_number_new
             , token_key_label_new
             , re_encrypt_status
             , error_action
             , error_message
             , created_by
             , creation_date
             , last_updated_by
             , last_update_date
             , last_update_login
			)
          SELECT /*+parallel(a) full(a) */
               a.card_id                   --card_id
             , a.credit_card_number_orig   --credit_card_number_orig
             , a.cc_key_label_orig         --cc_key_label_orig
             , SUBSTR ( a.masked, 1, 6)    --first_six
             , SUBSTR ( a.masked, -4, 4)   --last_four
             , NULL                        --credit_card_number_new
             , NULL                        --cc_key_label_new
             , a.token_number              --token_number_orig
             , a.token_key_label           --token_key_label_orig
             , NULL                        --token_number_new
             , NULL                        --token_key_label_new
             , 'N'                         --re_encrypt_status
             , NULL                        --error_action
             , NULL                        --error_message
             , gn_user_id                  --created_by
             , SYSDATE                     --creation_date
             , gn_user_id                  --last_updated_by
             , SYSDATE                     --last_update_date
             , gn_login_id                 --last_update_login
          FROM xx_c2t_cc_token_crypto_ext a;
          
    COMMIT;
    
    EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.xx_c2t_cc_token_crypto_vault noparallel';
			
    l_location := 'Execute FND gather table stats';
    DBMS_OUTPUT.PUT_LINE( l_location );
    FND_STATS.GATHER_TABLE_STATS (ownname => 'XXFIN', tabname => 'xx_c2t_cc_token_crypto_vault');

 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||l_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/