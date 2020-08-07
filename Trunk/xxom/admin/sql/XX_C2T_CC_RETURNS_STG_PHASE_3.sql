DECLARE

-- +=========================================================================+
-- |                        Office Depot Inc.                                |
-- +=========================================================================+
-- | Script Name :  XX_C2T_CC_RETURNS_STG_PHASE_3.sql                        |
-- | Description :  Script to insert records into staging table              |
-- |                XX_C2T_CC_TOKEN_STG_RETURNS for Returns                  |
-- | Rice Id     :  C0705                                                    |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date         Author             Remarks                        |
-- |=======   ===========  =================  ===============================|
-- |1.0       16-Sep-2015  Manikant Kasu      Initial draft version          |
-- |1.1       05-Feb-2016  Manikant Kasu      Added logic to insert          |
-- |                                          correct key label for          |
-- |                                          records with NULL value        |
-- |1.2       17-Feb-2016  Manikant Kasu      Code changes to include        |
-- |                                          debit card records             |
-- | 1.3      29-Nov-2016  Havish Kasina      Code changes for AMEX          |
-- |                                          Credit card conversion         |
-- | 1.4      01-Mar-2017  Havish Kasina      Code changes for Unconverted   |
-- |                                          Non-Amex Records (Credit Card  | 
-- |                                          conversion)                    |    
-- +=========================================================================+
  
  ln_user_id             NUMBER         := NVL ( FND_GLOBAL.USER_ID, -1);
  ln_login_id            NUMBER         := NVL ( FND_GLOBAL.LOGIN_ID, -1);
  lc_truncate_table      VARCHAR2(100)  := 'TRUNCATE TABLE XXOM.XX_C2T_CC_TOKEN_STG_RETURNS'; 
  lc_location            VARCHAR2(500);
BEGIN
      lc_location := 'Truncating Table XX_C2T_CC_TOKEN_STG_RETURNS';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE lc_truncate_table;
      
      lc_location := 'Enable Parallel DML';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
      
      lc_location := 'Inserting records into XX_C2T_CC_TOKEN_STG_RETURNS Table';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      INSERT INTO XX_C2T_CC_TOKEN_STG_RETURNS
          (       RETURN_ID,
                  ORIG_SYS_DOCUMENT_REF,         
                  PAYMENT_NUMBER,                  
                  PAYMENT_TYPE_CODE,              
                  CREDIT_CARD_NUMBER_ORIG,       
                  KEY_LABEL_ORIG,                  
                  OD_PAYMENT_TYPE,            
                  CREDIT_CARD_CODE,                
                  CC_MASK_NUMBER,               
                  CREDIT_CARD_NUMBER_NEW,          
                  KEY_LABEL_NEW,                  
                  TOKEN_FLAG,                     
                  RE_ENCRYPT_STATUS,               
                  ERROR_ACTION,                     
                  ERROR_MESSAGE,             
                  CONVERT_STATUS,             
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATE_LOGIN,
                  LAST_UPDATED_BY
          )
          SELECT   /*+parallel(x) full(x) */
                   XX_C2T_CC_TOKEN_RETURNS_s.NEXTVAL,
                   orig_sys_document_ref,
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
                   NULL,                --credit_card_number_new
                   NULL,                --cc_key_label_new   
                   NVL(token_flag,'N'), -- token_flag
                   'N',                 --re_encrypt_status
                   NULL,                --error_action
                   NULL,                --error_message
                   'N',                 --convert_status
                   SYSDATE,             --creation_date
                   ln_user_id,          --created_by 
                   SYSDATE,             --last_update_date
                   ln_login_id,         --last_update_login
                   ln_user_id           --last_updated_by             
          FROM     xx_om_return_tenders_all x
         WHERE     1 = 1
           AND     payment_type_code   = 'CREDIT_CARD'
           AND     od_payment_type     NOT IN  ('22','26','27')   -- Commented for the AMEX Credit card conversion
           AND     credit_card_code    NOT IN  ('AMEX')           -- Commented for the AMEX Credit card conversion
           AND     (token_flag = 'N'   OR token_flag IS NULL)
           AND     credit_card_number  IS NOT NULL
		   AND     header_id IN (   1233717062,
									1233715615,
									1233719127,
									1238266757,
									1237953589,
									1284187257,
									1284191346,
									1284742342,
									1285925366,
									1287256644,
									1285925372,
									1285925373,
									1285925367,
									1288655468,
									1238266758,
									1290627479,
									1301203542,
									1302708514,
									1317903728,
									1300592314,
									1302707558,
									1303642474,
									1305860055,
									1304878222,
									1305564246,
									1305565036,
									1305851131,
									1306055839,
									1306710002,
									1309572609,
									1308567350,
									1314818329,
									1314807896,
									1308858984,
									1314819903,
									1314819941,
									1314819942,
									1314823287,
									1314819915,
									1309582461,
									1310098606,
									1314809945,
									1314819904,
									1314819919,
									1314819947,
									1201337271,
									1309582462,
									1250377487,
									1248201645,
									1259056579,
									1262042867,
									1263666080,
									1291698169,
									1227230443,
									1232986537,
									1232983691,
									1232987318,
									1264718435,
									1237632806,
									1237641361,
									1237641375,
									1243564134,
									1264449894,
									1264445126,
									1244468763,
									1244470140,
									1264997614,
									1293201468,
									1293273103,
									1296102812,
									1293192049,
									1310410294,
									1293273667,
									1292746072,
									1296795594,
									1313935943,
									1312898434,
									1313934729,
									1312488157,
									1297712024,
									1296104072,
									1296567579,
									1295135262,
									1298591173,
									1298423092,
									1296794249,
									1314222701,
									1247037015
									)
      ;
      
      COMMIT;
      
      lc_location := 'Alter Table XX_C2T_CC_TOKEN_STG_RETURNS';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER TABLE XXOM.XX_C2T_CC_TOKEN_STG_RETURNS NOPARALLEL';
      
      lc_location := 'Execute FND gather table stats';
      DBMS_OUTPUT.PUT_LINE( lc_location );
      FND_STATS.GATHER_TABLE_STATS (ownname => 'XXOM', tabname => 'XX_C2T_CC_TOKEN_STG_RETURNS');
      
 EXCEPTION
 WHEN OTHERS 
 THEN
      DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
      DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;      
/
        