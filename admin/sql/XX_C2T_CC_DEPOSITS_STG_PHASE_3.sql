-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_DEPOSITS_STG_PHASE_3.sql                       |
-- | Description :    Deposits - Staging Credit Cards Convert Phase            |
-- | Rice ID     :    C0705                                                    |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-21-2015   Havish Kasina         Initial Version                |
-- | 1.1     05-Feb-2016  Manikant Kasu         Added logic to insert correct  |
-- |                                            key label for records with NULL|
-- |                                            value                          |
-- | 1.2     17-Feb-2016  Manikant Kasu         Code changes to include debit  |
-- |                                            card records                   |
-- | 1.3     29-Nov-2016  Havish Kasina         Code changes for AMEX Credit   |
-- |                                            card conversion                |
-- | 1.4     01-Mar-2017  Havish Kasina         Code changes for Unconverted   |
-- |                                            Non-Amex Records (Credit Card  | 
-- |                                            conversion)                    |    
-- +===========================================================================+
DECLARE
  ln_user_id             NUMBER         := NVL ( FND_GLOBAL.USER_ID, -1);
  ln_login_id            NUMBER         := NVL ( FND_GLOBAL.LOGIN_ID , -1);
  lc_truncate_table      VARCHAR2 (100) := 'TRUNCATE TABLE XXOM.XX_C2T_CC_TOKEN_STG_DEPOSITS'; 
  lc_location            VARCHAR2(500);
BEGIN                                
      lc_location := 'Truncating Table XX_C2T_CC_TOKEN_STG_DEPOSITS';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE lc_truncate_table;
      
      lc_location := 'Enable Parallel DML';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
      
      lc_location := 'Inserting records into XX_C2T_CC_TOKEN_STG_DEPOSITS Table';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      INSERT INTO xx_c2t_cc_token_stg_deposits
          (        deposit_id,
                   transaction_number ,
                   order_source_id   ,
                   payment_number ,
				           payment_type_code,
                   credit_card_number_orig ,
                   key_label_orig ,
                   od_payment_type,                   
                   credit_card_code ,
                   cc_mask_number ,
                   token_flag ,
                   credit_card_number_new ,
                   key_label_new ,
                   re_encrypt_status ,
                   error_action ,
                   error_message ,
                   convert_status ,
                   creation_date ,
                   created_by ,
                   last_update_date ,
                   last_updated_by ,
                   last_update_login 
          )
          SELECT   /*+parallel(x) full(x) */
                   xx_c2t_cc_token_stg_deps_s.NEXTVAL,
                   transaction_number,
                   order_source_id,
                   payment_number,			   
                   payment_type_code,
                   credit_card_number,
                   nvl(identifier, CASE 
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20081006A',4,8) AND substr('AJB20081215A',4,8) THEN 'AJB20081006A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20081216A',4,8) AND substr('AJB20090325A',4,8) THEN 'AJB20081216A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20090326A',4,8) AND substr('AJB20090722A',4,8) THEN 'AJB20090326A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20090723A',4,8) AND substr('AJB20091013A',4,8) THEN 'AJB20090723A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20091014A',4,8) AND substr('AJB20100217A',4,8) THEN 'AJB20091014A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20100218A',4,8) AND substr('AJB20100628A',4,8) THEN 'AJB20100218A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20100629A',4,8) AND substr('AJB20100927A',4,8) THEN 'AJB20100629A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20100928A',4,8) AND substr('AJB20101213A',4,8) THEN 'AJB20100928A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20101214A',4,8) AND substr('AJB20110927A',4,8) THEN 'AJB20101214A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20110928A',4,8) AND substr('AJB20120917A',4,8) THEN 'AJB20110928A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20120918A',4,8) AND substr('AJB20130916A',4,8) THEN 'AJB20120918A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20130917A',4,8) AND substr('AJB20141015A',4,8) THEN 'AJB20130917A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20141016A',4,8) AND substr('AJB20151028A',4,8) THEN 'AJB20141016A'
								   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20151029A',4,8) AND substr('AJB20161003A',4,8) THEN 'AJB20151029A'
                                   WHEN TO_CHAR(CREATION_DATE,'RRRRMMDD') between substr('AJB20161004A',4,8) AND TO_CHAR(SYSDATE,'RRRRMMDD') THEN 'AJB20161004A'
                                   ELSE NULL
                                   END
                       ) key_label_orig,
                   od_payment_type,
                   credit_card_code,
                   cc_mask_number,      -- cc_mask_number
                   NVL(token_flag,'N'), -- token_flag
                   NULL,                --credit_card_number_new
                   NULL,                --cc_key_label_new
                   'N',                 --re_encrypt_status
                   NULL,                --error_action
                   NULL,                --error_message
                   'N',                 --convert_status
                   SYSDATE,             --creation_date
                   ln_user_id,          --created_by 
                   SYSDATE,             --last_update_date
                   ln_user_id,          --last_updated_by             
                   ln_login_id          --last_update_login
          FROM     xx_om_legacy_deposits x
         WHERE     1 = 1
		   AND    (token_flag = 'N' OR token_flag IS NULL)
           AND     payment_type_code    =     'CREDIT_CARD'
           AND     NVL(credit_card_code,'1')   NOT IN  ('AMEX')   	   
           AND     od_payment_type    NOT IN  ('22','27','26')	
           AND     NVL(credit_card_number,'-1') <> '-1'
           AND     transaction_number IN ('22522015092109900001',
		                                  '64472016031000404320',
										  '63952016031809900001',
										  '05892016121300105485')
      ;
      
      COMMIT;
      
      lc_location := 'Alter Table XX_C2T_CC_TOKEN_STG_DEPOSITS';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER TABLE XXOM.XX_C2T_CC_TOKEN_STG_DEPOSITS NOPARALLEL';
      
      lc_location := 'Execute FND gather table stats';
      DBMS_OUTPUT.PUT_LINE( lc_location );
      FND_STATS.GATHER_TABLE_STATS (ownname => 'XXOM', tabname => 'XX_C2T_CC_TOKEN_STG_DEPOSITS');
      
 EXCEPTION
 WHEN OTHERS 
 THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
      DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;      
      
      
      
                                
            
                                
        