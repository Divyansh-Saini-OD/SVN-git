	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_STG_PHASE_3_1.sql                            |
	-- | Description : Script to insert data in ORDT staging table XX_C2T_CC_TOKEN_STG_ORDT|
	-- |               for updating IBY History Credit Card Code information       |
	-- |Change Record:                                                             |
	-- |===============                                                            |
	-- |Version  Date         Author                Remarks                        |
	-- |=======  ===========  ==================    ===============================|	
	-- |v1.0     13-OCT-2015  Harvinder Rakhra      Initial version                |  
	-- +===========================================================================+
 DECLARE
 l_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := NVL ( FND_GLOBAL.USER_ID, -1);
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := NVL ( FND_GLOBAL.LOGIN_ID , -1);
 BEGIN

    l_location := 'TRUNCATE  TABLE XX_C2T_CC_TOKEN_STG_ORDT ';
    DBMS_OUTPUT.PUT_LINE( l_location );
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_CC_TOKEN_STG_ORDT';
			
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	
    l_location := 'INSERTING Values in table XX_C2T_CC_TOKEN_STG_ORDT';
    DBMS_OUTPUT.PUT_LINE( l_location );			
    INSERT INTO xx_c2t_cc_token_stg_ordt  (
                                            order_payment_id
                                          , payment_type_code
                                          , od_payment_type
                                          , credit_card_code
                                          , token_flag
                                          , credit_card_number_orig
                                          , cc_key_label_orig
                                          , credit_card_number_new
                                          , cc_key_label_new
                                          , cc_mask_number
                                          , re_encrypt_status
                                          , error_action
                                          , error_message
                                          , convert_status
                                          , created_by
                                          , creation_date
                                          , last_updated_by
                                          , last_update_date
                                          , last_update_login
                                         )	
    SELECT /*+parallel(x) full(x) */
              order_payment_id
            , payment_type_code     --payment_type_code
            , od_payment_type       --od_payment_type
            , credit_card_code      --credit_card_code
            , token_flag            --token_flag
            , credit_card_number    --credit_card_number_orig
            , identifier            --cc_key_label_orig
            , NULL                  --credit_card_number_new
            , NULL                  --cc_key_label_new
            , cc_mask_number        --cc_mask_number
            , 'N'                   --re_encrypt_status
            , NULL                  --error_action
            , NULL                  --error_message
            , NULL                  --convert_status
            , gn_user_id            --created_by
            , SYSDATE               --creation_date
            , gn_user_id            --last_updated_by
            , SYSDATE               --last_update_date
            , gn_login_id           --last_update_login
    FROM xx_ar_order_receipt_dtl x
    WHERE payment_type_code =  'CREDIT_CARD';
			
    EXECUTE IMMEDIATE 'ALTER TABLE xxfin.xx_c2t_cc_token_stg_ordt noparallel';
			
    l_location := 'Execute FND gather table stats';
    DBMS_OUTPUT.PUT_LINE( l_location );
    FND_STATS.GATHER_TABLE_STATS (ownname => 'XXFIN', tabname 	=> 'XX_C2T_CC_TOKEN_STG_ORDT');

 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||l_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/