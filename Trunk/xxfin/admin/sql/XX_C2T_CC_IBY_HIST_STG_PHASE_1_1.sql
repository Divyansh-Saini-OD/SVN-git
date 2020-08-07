	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_UPD_CCCODE_PHASE_1_3.sql                     |
	-- | Description : Script to Insert data in IBY History Staging table from     |
	-- |               from    XX_IBY_BATCH_TRXNS_HISTORY                          |
	-- |                                                                           |
	-- |Change Record:                                                             |
	-- |===============                                                            |
	-- |Version  Date         Author                Remarks                        |
	-- |=======  ===========  ==================    ===============================|
	-- |v1.0     13-OCT-2015  Harvinder Rakhra      Initial version                |
	-- |v1.1     21-OCT-2015  Harvinder Rakhra      Alter session commands modified| 
	-- |v1.2     06-NOV-2015  Harvinder Rakhra      Removed Column Credit Card Code| 
	-- |v1.3     06-NOV-2016  Avinash Baddam        Defect#40315 Amex Conv Changes |
	-- |v1.4     16-MAR-2017  Avinash Baddam        Outstanding Cleanup Records (Post-Amex)|
	-- +===========================================================================+

 DECLARE
 l_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := NVL ( FND_GLOBAL.USER_ID, -1);
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := NVL ( FND_GLOBAL.LOGIN_ID , -1);
 BEGIN

    l_location := 'TRUNCATE  TABLE XX_C2T_CC_TOKEN_STG_IBY_HIST ';
    DBMS_OUTPUT.PUT_LINE( l_location );
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_CC_TOKEN_STG_IBY_HIST';
			
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	
    l_location := 'INSERTING Values in table XX_C2T_CC_TOKEN_STG_IBY_HIST';
    DBMS_OUTPUT.PUT_LINE( l_location );			
    INSERT INTO xx_c2t_cc_token_stg_iby_hist (
                                               hist_id
                                             , order_payment_id
                                             , ixaccount
                                             , ixswipe
                                             , ixreceiptnumber
                                             , ixipaymentbatchnumber
                                             , is_amex
                                             , ixcreditcardcode
                                             , ixtokenflag
                                             , attribute8
                                             , credit_card_number_new
                                             , key_label_new
                                            -- , credit_card_code
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
                                               xx_c2t_cc_stg_iby_hist_seq.NEXTVAL   --hist_id
                                             , x.order_payment_id                   --order_payment_id
                                             , x.ixaccount                          --ixaccount
                                             , x.ixswipe                            --ixswipe
                                             , x.ixreceiptnumber                    --ixreceiptnumber
                                             , x.ixipaymentbatchnumber              --ixipaymentbatchnumber
                                             , x.is_amex                            --is_amex
                                             , x.ixcreditcardcode                   --ixcreditcardcode
                                             , x.ixtokenflag                        --ixtokenflag
                                             , x.attribute8                         --attribute8
                                             , NULL                                 --credit_card_number_new
                                             , NULL                                 --key_label_new
                                            -- , x.ixinstrsubtype                     --credit_card_code
                                             , 'N'                                  --re_encrypt_status
                                             , NULL                                 --error_action
                                             , NULL                                 --error_message
                                             , NULL                                 --convert_status
                                             , gn_user_id                           --created_by
                                             , SYSDATE                              --creation_date
                                             , gn_user_id                           --last_updated_by
                                             , SYSDATE                              --last_update_date
                                             , gn_login_id                          --last_update_login
				     FROM xx_iby_batch_trxns_history x	
				    WHERE NVL(ixtokenflag ,'N') = 'N';
				    
				  /*  ixtokenflag <> 'Y'
				      AND ixcreditcardcode not in ('AMEX', 'CITI_Com', 'CITI_Con');*/
			/*	    (NVL(ixcreditcardcode,'AMEX') = 'AMEX' --v1.3 Amex Conv Changes
			                    or is_amex = 'Y')
                                      AND NVL(ixtokenflag ,'N') = 'N';
			--v1.3 Amex Conv Changes
			NVL (ixcreditcardcode , '-1')  NOT IN ('CITI_Com', 'CITI_Con', 'AMEX' )
                                       AND  NVL(is_amex ,'N')     <> 'Y'*/
			
    EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.XX_C2T_CC_TOKEN_STG_IBY_HIST noparallel';
				
    l_location := 'Execute FND gather table stats';
    DBMS_OUTPUT.PUT_LINE( l_location );
    FND_STATS.GATHER_TABLE_STATS (ownname => 'XXFIN', tabname => 'XX_C2T_CC_TOKEN_STG_IBY_HIST');

 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||l_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/