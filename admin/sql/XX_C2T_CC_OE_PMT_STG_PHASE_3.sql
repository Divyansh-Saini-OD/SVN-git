-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_OE_PMT_STG_PHASE_3.sql                         |
-- | Description :    OE Payments - Staging Credit Cards Convert Phase         |
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
-- | 1.4     15-Mar-2017  Havish Kasina         Code changes for Unconverted   |
-- |                                            Non-Amex Records (Credit Card  | 
-- |                                            conversion)                    |     
-- +===========================================================================+
DECLARE
  ln_user_id             NUMBER         := NVL ( FND_GLOBAL.USER_ID, -1);
  ln_login_id            NUMBER         := NVL ( FND_GLOBAL.LOGIN_ID , -1);
  lc_truncate_table      VARCHAR2 (100) := 'TRUNCATE TABLE XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT'; 
  lc_location            VARCHAR2(500);
BEGIN                                
      lc_location := 'Truncating Table XX_C2T_CC_TOKEN_STG_OE_PMT';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE lc_truncate_table;
      
      lc_location := 'Enable Parallel DML';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
      
      lc_location := 'Inserting records into XX_C2T_CC_TOKEN_STG_OE_PMT Table';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      INSERT INTO xx_c2t_cc_token_stg_oe_pmt
          (        oe_payment_id,
                   header_id ,
                   line_id   ,
                   payment_number ,
                   credit_card_number_orig ,
                   key_label_orig ,
                   od_payment_type,
                   payment_type_code,
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
                   xx_c2t_cc_token_stg_oe_pmt_s.NEXTVAL,
                   header_id,
                   line_id,
                   payment_number,			   
                   credit_card_number || attribute4 credit_card_number_orig,
                   nvl(attribute5, CASE 
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
                   attribute11,
                   payment_type_code,
                   credit_card_code,
                   NULL,                -- cc_mask_number
                   NVL(attribute3,'N'), -- token_flag
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
          FROM     oe_payments x
         WHERE     1 = 1
		   AND    (attribute3 = 'N' OR attribute3 IS NULL)
           AND     payment_type_code    =     'CREDIT_CARD'
           AND     NVL(credit_card_code,'1')    NOT IN  ('AMEX')	
           AND     attribute11        NOT IN  ('22','27','26')   
		   AND    ((NVL(credit_card_number,'-1') <> '-1') OR (NVL (attribute4, '-1') <> '-1'))
           AND    header_id IN (1300578712,
								1301958838,
								1287817210,
								1287827238,
								1286113493,
								1267238906,
								1286209416,
								1285185644,
								1316001327,
								1316001250,
								1315986247,
								1266724493,
								1266685507,
								1264106149,
								1220381139,
								1278927329,
								1278927338,
								1278977275,
								1278977415,
								1278977428,
								1278970891,
								1278894528,
								1228102521,
								1316374774,
								1316726379,
								1316379394,
								1256995631,
								1281647294,
								1295296973,
								1270527818,
								1296676494,
								1296563325,
								1296562618,
								1296714738,
								1289532135,
								1317325871,
								1289626207,
								1317340151,
								1200955176,
								1278295012,
								1278262910,
								1278263177,
								1278263179,
								1278263181,
								1278293885,
								1278293968,
								1278294011,
								1278294149,
								1278294155,
								1278294204,
								1278294290,
								1278290123,
								1278294853,
								1278294900,
								1277942586,
								1276524453,
								1290824011,
								1303539685,
								1289082697,
								1303319231,
								1287242099,
								1217637073,
								1217639014,
								1283596278,
								1278295207,
								1278295263,
								1278295286,
								1278293459,
								1278293514,
								1278293697,
								1278293709,
								1278293721,
								1278293745,
								1278293805,
								1278295383,
								1278184265,
								1278295516,
								1278295522,
								1278380493,
								1278346916,
								1278294459,
								1278294619,
								1278263174,
								1278263190,
								1278295724,
								1278295750,
								1278296353,
								1278296470,
								1278296572,
								1278262863,
								1289052599,
								1289066114,
								1305234668,
								1287436146,
								1286208343,
								1271904114,
								1271904113,
								1280805287,
								1280878059,
								1299232052,
								1277118616,
								1277118624,
								1262994028,
								1262994057,
								1262994085,
								1262994136,
								1262994151,
								1262379518,
								1262379644,
								1262379650,
								1262379654,
								1262379656,
								1262379658,
								1262379674,
								1262379686,
								1262379691,
								1261971316,
								1280089302,
								1297299761,
								1288359660,
								1288361184,
								1288365858,
								1288419687,
								1288419688,
								1288363371,
								1288419689,
								1269919925,
								1300359307,
								1300376714,
								1269946789,
								1274192618,
								1275039170,
								1276592422,
								1276592423,
								1273496593,
								1252119194,
								1300526887,
								1285549097,
								1274656255,
								1291683365,
								1281263477,
								1295716612,
								1295903889,
								1294741509,
								1292797415,
								1289019557,
								1261461839,
								1299233257,
								1197547044,
								1274677766,
								1267670914,
								1267670910,
								1255455242,
								1255449643,
								1288349570,
								1279369999,
								1279042587,
								1278975923,
								1278976152,
								1278976191,
								1278976391,
								1278976490,
								1278976640,
								1278976793,
								1293266436,
								1296758038,
								1279072585,
								1279676070,
								1279682191,
								1279682205,
								1279682254,
								1279466636,
								1279682179,
								1293778502,
								1297372775,
								1292890688,
								1234181994,
								1226157714,
								1227323288,
								1258606355,
								1261935241,
								1261935244,
								1261869160,
								1279655704,
								1302794604,
								1271491210,
								1303601496,
								1270889720,
								1282643997,
								1257655253,
								1284727177,
								1284254085,
								1298140503,
								1279990096,
								1294592676,
								1274679639,
								1302929300,
								1267823521,
								1267809589,
								1263565030,
								1300887511,
								1314987736,
								1277550774,
								1277584366,
								1277643120,
								1277583572,
								1277584855,
								1277584920,
								1277642421,
								1277561690,
								1277560323,
								1277558497,
								1277558539,
								1277558542,
								1277560425,
								1277560429,
								1277558572,
								1277558605,
								1277558632,
								1277558667,
								1277558701,
								1277563237,
								1277557256,
								1277558998,
								1277560558,
								1277559051,
								1277559080,
								1277559134,
								1277559153,
								1277559189,
								1277559224,
								1277561953,
								1277560592,
								1277560046,
								1277559770,
								1277557924,
								1277557965,
								1277560077,
								1277560088,
								1277560093,
								1277560141,
								1277560190,
								1277560229,
								1277559840,
								1277559939,
								1277559963,
								1277561256,
								1277561268,
								1277561059,
								1277561092,
								1277558816,
								1277558822,
								1277558892,
								1277534161,
								1277561403,
								1277562244,
								1277560935,
								1277560964,
								1277559229,
								1277559306,
								1277559367,
								1277558394,
								1277558424,
								1300522927,
								1287715741,
								1260792483,
								1300551284,
								1300372467,
								1300522951,
								1258074952,
								1287255314,
								1232774015,
								1299040256,
								1288412144,
								1237183692,
								1277559465,
								1277559514,
								1277559537,
								1277559544,
								1277559605,
								1277559615,
								1277559666,
								1277559697,
								1277559723,
								1277601301,
								1277545914,
								1277604845,
								1277529107,
								1255940010,
								1276167187,
								1276193473,
								1285586474,
								1286097150,
								1301158496,
								1305989119,
								1306475458,
								1306599821,
								1307138654,
								1307326087,
								1308346974,
								1307828770,
								1308263651,
								1308939236,
								1308915710,
								1309671775,
								1310285805,
								1310913175,
								1310913185,
								1310967452,
								1312155980,
								1312155966,
								1313814402,
								1313926604,
								1313933160,
								1313926602,
								1314320105)
      ;
	  
	  COMMIT;
      
      lc_location := 'Alter Table XX_C2T_CC_TOKEN_STG_OE_PMT';
      DBMS_OUTPUT.PUT_LINE( lc_location );      
      EXECUTE IMMEDIATE 'ALTER TABLE XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT NOPARALLEL';
      
      lc_location := 'Execute FND gather table stats';
      DBMS_OUTPUT.PUT_LINE( lc_location );
      FND_STATS.GATHER_TABLE_STATS (ownname => 'XXOM', tabname => 'XX_C2T_CC_TOKEN_STG_OE_PMT');
      
 EXCEPTION
 WHEN OTHERS 
 THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
      DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;      
      
      
      
                                
            
                                
        