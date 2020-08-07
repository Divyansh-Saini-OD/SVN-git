create or replace package body XX_FIN_VPS_BACKUP_INVSKU
as
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Package to get backup data  ON XX_FIN_VPSbBACKUP_INVSKU.pkb  |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author              Remarks                    |
-- |=======    ==========     =============         ========================== |
-- | 1.0       09-JUL-17      Sreedhar Mohan        Initial draft version      |
-- | 1.1       22-SEP-17      Thejaswini Rajula     Redesign Backup and stmt   |
-- | 1.2       09-AUG-18      Havish Kasina         Added new argument to the  |
-- |                                                XXARVPSINVSKUBKUP program  |          
-- +===========================================================================+

  PROCEDURE HTTP_GET_BACKUP(P_PROGRAM_ID          IN   NUMBER
                           ,P_VENDOR_NUMBER       IN   VARCHAR2
                           ,P_BACKUP_TYPE         IN   VARCHAR2
                          )
  IS
      request UTL_HTTP.REQ;
      response UTL_HTTP.RESP;
      n NUMBER;
      buff VARCHAR2(10000);
      clob_buff CLOB;

      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL;   
      l_url                 VARCHAR2(4000);
      
      VPS_BACKUP_SERVICE_URL varchar2(1000) := null; --'https://agerndev.na.odcorp.net/vpsservice/api/v2/PGM_DETAILS';
      l_enable_auth         VARCHAR2(256):=NULL; 
      l_username            VARCHAR2(256):=NULL;
      l_vps_password        VARCHAR2(256):=NULL;
      l_year                VARCHAR2(4):=NULL;
      
  BEGIN
    
    select to_char(sysdate, 'YYYY') into l_year  from dual;
  
      BEGIN
      
        SELECT 
            TARGET_VALUE1
         INTO
            VPS_BACKUP_SERVICE_URL
         FROM  XX_FIN_TRANSLATEVALUES VALS
              ,XX_FIN_TRANSLATEDEFINITION DEFN
         WHERE 1=1
         AND DEFN.TRANSLATE_ID=VALS.TRANSLATE_ID
         AND DEFN.TRANSLATION_NAME = 'OD_VPS_TRANSLATION'
         AND SOURCE_VALUE1 LIKE 'BKUP_INT_URL'
         ;        
        
      EXCEPTION 
        WHEN OTHERS THEN
        --RETCODE:=2;
        --ERRBUF:='Error in getting Backup interface Service URL from Translation';
        fnd_file.put_line (fnd_file.LOG,SQLERRM);
        RETURN;
      END;
  
      BEGIN
      
        SELECT 
           TARGET_VALUE1
          ,TARGET_VALUE2
        into
          l_wallet_location
         ,l_password
        FROM XX_FIN_TRANSLATEVALUES     VAL,
             XX_FIN_TRANSLATEDEFINITION DEF
        WHERE 1=1
        and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
        and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
        and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
        and   VAL.ENABLED_FLAG = 'Y'
        and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
        
      EXCEPTION 
        WHEN OTHERS THEN
        l_wallet_location := NULL;
        l_password := NULL;
        --RETCODE:=2;
        --ERRBUF:='Error in getting Wallet Location from Translation';
        fnd_file.put_line (fnd_file.LOG,SQLERRM);
        RETURN;        
      END;
      
                  BEGIN
            --Get Authentication username and password
          SELECT  target_value1, target_value2
            INTO  l_username,l_vps_password
            FROM  XX_FIN_TRANSLATEVALUES VALS
                ,XX_FIN_TRANSLATEDEFINITION DEFN
           WHERE 1=1
             AND DEFN.TRANSLATE_ID=VALS.TRANSLATE_ID
             AND DEFN.TRANSLATION_NAME = 'OD_VPS_TRANSLATION'
             AND SOURCE_VALUE1 = 'VPS_INV_PUBLISH_AUTH'
             AND VALS.ENABLED_FLAG = 'Y'
             AND SYSDATE between VALS.START_DATE_ACTIVE and nvl(VALS.END_DATE_ACTIVE, SYSDATE+1); 
        EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'l_username Not Found' );
          l_username:=NULL;
          l_vps_password := NULL;
        END;
      
            BEGIN
             --Get Authentication Method
          SELECT  target_value1
            INTO  l_enable_auth
            FROM  XX_FIN_TRANSLATEVALUES VALS
                ,XX_FIN_TRANSLATEDEFINITION DEFN
           WHERE 1=1
             AND DEFN.TRANSLATE_ID=VALS.TRANSLATE_ID
             AND DEFN.TRANSLATION_NAME = 'OD_VPS_TRANSLATION'
             AND SOURCE_VALUE1 = 'VPS_INV_PUB_ENABLE_AUTH'
             AND VALS.ENABLED_FLAG = 'Y'
             AND SYSDATE between VALS.START_DATE_ACTIVE and nvl(VALS.END_DATE_ACTIVE, SYSDATE+1); 
        EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'l_enable_auth Not Found' );
          l_enable_auth:=NULL;
        END;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_enable_auth: ' || l_enable_auth);
      
      IF l_wallet_location IS NOT NULL THEN
        UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
      END IF;
           
      UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);

      
    request := UTL_HTTP.BEGIN_REQUEST(VPS_BACKUP_SERVICE_URL || '/' || P_PROGRAM_ID || '/' || P_VENDOR_NUMBER || '/'||l_year||'/' || P_BACKUP_TYPE, 'GET');
    
      UTL_HTTP.SET_HEADER(request, 'User-Agent', 'Mozilla/4.0');
      IF UPPER(l_enable_auth) IN ('Y','YES') THEN 
        utl_http.set_header(request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(l_username||':'||l_vps_password))));
      END IF;
      response := UTL_HTTP.GET_RESPONSE(request);
      --insert into a(log_msg) values ('HTTP response status code: ' || response.status_code); 
      commit; 
      --DBMS_OUTPUT.PUT_LINE('HTTP response status code: ' || response.status_code);
      l_url:= VPS_BACKUP_SERVICE_URL || '/' || P_PROGRAM_ID || '/' || P_VENDOR_NUMBER || '/'||l_year||'/' || P_BACKUP_TYPE;
      fnd_file.put_line (fnd_file.LOG,'l_url:'||l_url);
      fnd_file.put_line (fnd_file.LOG,'HTTP response status code: ' || response.status_code);
      IF response.status_code = 200 THEN
          BEGIN
              clob_buff := EMPTY_CLOB;
              LOOP
                UTL_HTTP.READ_TEXT(response, buff, LENGTH(buff));
  		        clob_buff := clob_buff || buff;
              END LOOP;
  	          UTL_HTTP.END_RESPONSE(response);
          EXCEPTION
  	          WHEN UTL_HTTP.END_OF_BODY THEN
                  UTL_HTTP.END_RESPONSE(response);
  	          WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE(SQLERRM);
                  DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                  UTL_HTTP.END_RESPONSE(response);
          END;
  
          BEGIN
            fnd_file.put_line (fnd_file.LOG,'Before inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ');
            INSERT INTO XX_FIN_VPS_STMT_BACKUP_DATA VALUES (XX_FIN_VPS_STMT_BACKUP_S.nextval, p_program_id, p_vendor_number, clob_buff, P_BACKUP_TYPE, sysdate, 0, sysdate, 0);
            fnd_file.put_line (fnd_file.LOG,'After inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQL%ROWCOUNT);
            COMMIT;
          EXCEPTION
      	    WHEN OTHERS THEN
                 -- ERRBUF := 'Exception in inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQLERRM;
                  DBMS_OUTPUT.PUT_LINE('Exception in inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQLERRM);
                  fnd_file.put_line (fnd_file.LOG,'Exception in inserting into XX_FIN_VPS_STMT_BACKUP_DATA: ' || SQLERRM);
          END;
      ELSE
          DBMS_OUTPUT.PUT_LINE('ERROR');
          --ERRBUF := 'ERROR';
          fnd_file.put_line (fnd_file.LOG,'ERROR');
          UTL_HTTP.END_RESPONSE(response);
      END IF;
  EXCEPTION
      	    WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE('Exception: ' || SQLERRM);
                  commit;  
  END HTTP_GET_BACKUP;


PROCEDURE VPS_BACKUP_GET( ERRBUF                OUT  VARCHAR2
                           ,RETCODE               OUT  NUMBER
                           ,P_STMT_DATE           IN   VARCHAR2
                          )  IS
      lv_stmt_date                  DATE;
      lv_inv_cnt						        NUMBER;
      lv_sku_cnt						        NUMBER;
      v_inv_sku_req					        NUMBER;
      lv_email_address              VARCHAR2(256);
      l_req_return_status           BOOLEAN;
      lc_phase                      VARCHAR2(50);
      lc_status                     VARCHAR2(50);
      lc_dev_phase                  VARCHAR2(50);
      lc_dev_status                 VARCHAR2(50);
      lc_message                    VARCHAR2(50);
      lv_invoices_row_cnt           NUMBER;
      lv_sku_row_count              NUMBER;
      lv_inv_bkup_row_cnt           NUMBER;
      lv_sku_bkup_row_cnt           NUMBER;
      lc_conn                       UTL_SMTP.connection;
      lc_attach_text                VARCHAR2 (32320);
      lc_request_id                 NUMBER := fnd_global.conc_request_id;
      lc_mail_from                  VARCHAR2(100); -- := 'ebs_test_notifications@officedepot.com';
      lc_mail_to                    VARCHAR2(100); --:= fnd_profile.value('XX_VPS_SEND_MAIL_TO');
     
      

CURSOR cur_stmt_backup(lv_stmt_date DATE,
                       p_vendor_num VARCHAR2)
	IS
	SELECT DISTINCT rct.attribute14 program_id,
        SUBSTR(orig_system_reference,1,INSTR(orig_system_reference, '-',1)-1) vendor_number
    FROM hz_cust_accounts_all hca ,
         xx_cdh_cust_acct_ext_b extb,
         Ego_Attr_Groups_V eagv ,
         ra_customer_trx_all rct
  WHERE 1                      =1
  AND hca.orig_system_reference = p_vendor_num||'-VPS'  -- Added by Havish Kasina as per Version 1.2
  AND hca.cust_account_id  =extb.cust_account_id
  AND extb.attr_group_id   =eagv.attr_group_id
  AND eagv.attr_group_type ='XX_CDH_CUST_ACCOUNT'
  AND eagv.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
  AND UPPER(c_ext_attr4)  IN ('YES','Y')
  AND UPPER(c_ext_attr8)  IN ('YES','Y')
  AND hca.cust_account_id  =rct.bill_to_customer_id
  AND rct.attribute14     IS NOT NULL
  AND TRUNC(rct.trx_date) BETWEEN TRUNC(lv_stmt_date,'YEAR') AND TRUNC(lv_stmt_date);

/* Added by Havish Kasina as per Version 1.2 */  
CURSOR cur_core_invoices(P_STMT_DATE VARCHAR2)
IS
  SELECT SUBSTR(hca.orig_system_reference,1,INSTR(hca.orig_system_reference, '-',1)-1) SUPPLIER_NUM 
            FROM hz_cust_accounts_all hca ,
                 xx_cdh_cust_acct_ext_b extb,
                 Ego_Attr_Groups_V eagv ,
                 ra_customer_trx_all rct,
                 ra_batch_sources_all rbs ,
                 ra_cust_trx_types_all ract ,
                 ar_payment_schedules_all aps
           WHERE 1 = 1
             AND hca.cust_account_id  =extb.cust_account_id
             AND extb.attr_group_id   =eagv.attr_group_id
             AND eagv.attr_group_type ='XX_CDH_CUST_ACCOUNT'
             AND eagv.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
             AND UPPER(c_ext_attr4) IN ('YES','Y')
             AND hca.cust_account_id  =rct.bill_to_customer_id
             AND rct.batch_source_id  =rbs.batch_source_id
			 AND UPPER(ract.name) LIKE '%CORE%'
             AND rct.cust_trx_type_id =ract.cust_trx_type_id
             AND rct.customer_trx_id  =aps.customer_trx_id
			 AND TRUNC(aps.due_date) = TRUNC(TO_DATE(P_STMT_DATE,'YYYY/MM/DD HH24:MI:SS'))
           GROUP BY SUBSTR(hca.orig_system_reference,1,INSTR(hca.orig_system_reference, '-',1)-1);
      
  BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Input Parameters ');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'P_STMT_DATE :'|| P_STMT_DATE);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Start VPS_BACKUP_GET ');
  lv_stmt_date := FND_DATE.CANONICAL_TO_DATE (P_STMT_DATE);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Statement Date: '||lv_stmt_date);
      BEGIN
          SELECT target_value1,target_value2 
            INTO  lc_mail_from,lc_mail_to
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='CORE_BACKUP_EXCEPTION'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';       
         EXCEPTION 
         WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM); 
          NULL;
        END;

        BEGIN
          SELECT TO_NUMBER(target_value1),TO_NUMBER(target_value2) 
            INTO  lv_inv_bkup_row_cnt,lv_sku_bkup_row_cnt
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='CORE_BACKUP_ROWCOUNT'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';       
         EXCEPTION 
         WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM); 
          NULL;
        END;
		
--Delete old data
	DELETE FROM xx_fin_vps_stmt_backup_data; -- Added by Havish Kasina as per Version 1.2

FOR j in cur_core_invoices(P_STMT_DATE)
LOOP
  FOR i in cur_stmt_backup(lv_stmt_date, j.SUPPLIER_NUM) LOOP
    
    --Delete old data
	/*
	 	   DELETE FROM xx_fin_vps_stmt_backup_data 
	 	   				WHERE program_id=i.program_id 
	 	   					AND vendor_number=i.vendor_number;
    */
	-- Commented by Havish Kasina as per Version 1.2
	
    --Call to insert Backup Data into stg table from VPS
        --INVOICES
        BEGIN
        HTTP_GET_BACKUP(i.program_id 
                        ,i.vendor_number 
                        ,'INVOICES'
                          );
        EXCEPTION
          WHEN NO_DATA_FOUND THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in HTTP_GET_BACKUP NO DATA FOUND INVOICES '||i.program_id||i.vendor_number);
            NULL;
          WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in HTTP_GET_BACKUP INVOICES '||i.program_id||i.vendor_number);
            NULL;
        END;
        --SKUS
        BEGIN
        HTTP_GET_BACKUP(i.program_id 
                        ,i.vendor_number 
                        ,'SKUS'
                          );
        EXCEPTION
          WHEN NO_DATA_FOUND THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in HTTP_GET_BACKUP NO DATA FOUND SKUS '||i.program_id||i.vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in HTTP_GET_BACKUP SKUS '||i.program_id||i.vendor_number);
            NULL;
        END;
      
      --Check INVOICES Backup DATA
  							SELECT count(1) 
									INTO lv_inv_cnt
								  FROM xx_fin_vps_stmt_backup_data 
								  WHERE dbms_lob.substr(VPS_data,4000) NOT LIKE '%{"INVOICES":[]}%' 
								  	AND backup_type='INVOICES'
								  	AND program_id=i.program_id
								  	AND vendor_number=i.vendor_number;
								  --SKUS BACKUP Data
								  SELECT count(1) 
									INTO lv_sku_cnt
								  FROM xx_fin_vps_stmt_backup_data
								 WHERE dbms_lob.substr(VPS_data,4000) NOT LIKE '%{"SKUS":[]}%' 
								   AND backup_type='SKUS'
								   AND program_id=i.program_id
								   AND vendor_number=i.vendor_number;
            --Check Email Address for Backup 
                BEGIN
                  SELECT hcp.email_address
                    INTO lv_email_address
                    FROM hz_cust_accounts_all hca ,
                      hz_parties obj ,
                      hz_relationships rel ,
                      hz_org_contacts hoc ,
                      hz_contact_points hcp ,
                      hz_parties sub
                    WHERE 1                   =1
                      AND hca.orig_system_reference =i.vendor_number||'-VPS'
                      AND hca.party_id          = rel.object_id
                      AND hca.party_id          = obj.party_id
                      AND rel.subject_id        = sub.party_id
                      AND rel.relationship_type = 'CONTACT'
                      --AND rel.directional_flag  = 'F'
                      AND rel.relationship_id   =hoc.party_relationship_id
                      AND UPPER(hoc.job_title) like 'CORE%NON%BACKUP%BILLING%'
                      AND rel.party_id          = hcp.owner_table_id
                      AND hcp.owner_table_name  = 'HZ_PARTIES'
                      AND rownum=1;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN 
                          lv_email_address:=NULL;
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address for Backup '||i.program_id||i.vendor_number);
                          NULL;
                      WHEN TOO_MANY_ROWS THEN
                          lv_email_address:=NULL;
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address for Backup '||i.program_id||i.vendor_number);
                            NULL;
                      WHEN OTHERS THEN 
                          lv_email_address:=NULL;
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address for Backup '||i.program_id||i.vendor_number);
                          NULL;
                      END;
								 IF ((lv_inv_cnt>0 OR lv_sku_cnt>0) AND lv_email_address IS NOT NULL) THEN
                 
                  -- Check for no of records for INVOICES and SKUS . If more than 63K records DONOT kick INVOICE and SKU program 
                    --  BEGIN
                      SELECT Count(JT.INVOICE)
                        INTO lv_invoices_row_cnt
                        FROM XXFIN.XX_FIN_VPS_STMT_BACKUP_DATA bkdata
                                   ,JSON_TABLE ( bkdata.vps_data, '$' COLUMNS ( 
                                       nested path '$.INVOICES[*]' columns (
                                         "INVOICE"  varchar2(20) path '$.INVOICE' null on error,
                                         "INVOICE_DT"  varchar2(20) path '$.INVOICE_DT' null on error,
                                         "INV_AMT_T"  NUMBER path '$.AMT_T' null on error,
                                         "INV_AMT_R"  NUMBER path '$.AMT_R' null on error,
                                         "INV_AMT_N"  NUMBER path '$.AMT_N' null on error
                                       )
                                   )) "JT"
                        WHERE  bkdata.program_id=i.program_id
                          AND  bkdata.vendor_number = i.vendor_number
                          AND  bkdata.backup_type='INVOICES';
                   --  END;
                   --   BEGIN    
                      SELECT COUNT(jt.SKU)
                        INTO lv_sku_row_count
                        FROM   XXFIN.XX_FIN_VPS_STMT_BACKUP_DATA bkdata
                               ,JSON_TABLE ( bkdata.vps_data, '$' COLUMNS ( 
                                   nested path '$.SKUS[*]' columns (
                                     "SKU"  varchar2(50) path '$.SKU' null on error
                                     ,"SKUN"  varchar2(250) path '$.SKUN' null on error
                                     ,"DPT"  varchar2(20) path '$.DPT' null on error
                                     ,"DPTN"  varchar2(40) path '$.DPTN' null on error
                                     ,"CLS"  varchar2(20) path '$.CLS' null on error
                                     ,"CLSN"  varchar2(40) path '$.CLSN' null on error
                                     ,"SBC"  varchar2(20) path '$.SBC' null on error
                                     ,"SBCN"  varchar2(250) path '$.SBCN' null on error
                                     ,"AMT_T"  varchar2(20) path '$.AMT_T' null on error
                                     ,"QTY_T"  NUMBER path '$.QTY_T' null on error
                                     ,"AMT_R"  varchar2(20) path '$.AMT_R' null on error
                                     ,"QTY_R"  NUMBER path '$.QTY_R' null on error
                               ,"QTY_N"  NUMBER path '$.QTY_N' null on error
                                     ,"AMT_N"  varchar2(20) path '$.AMT_N' null on error
                                   )
                               )) "JT"
                        where  bkdata.program_id=i.program_id
                        and    bkdata.vendor_number = i.vendor_number
                        and    bkdata.backup_type='SKUS';
                  IF lv_invoices_row_cnt>=lv_inv_bkup_row_cnt OR lv_sku_row_count>=lv_inv_bkup_row_cnt THEN --INVOICES SKUS ROWCOUNT
                    
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Row Count for INVOICES OR SKUS  '||lv_invoices_row_cnt||'--'||lv_sku_row_count);
                  -- Send mail to vendor programs email 
                          BEGIN
                          lc_attach_text:='The backup email could not be delivered for the VN-'||i.vendor_number||' Program ID-'||i.program_id;
                          lc_conn := xx_pa_pb_mail.begin_mail (sender          =>  lc_mail_from,
                                                              recipients      =>  lc_mail_to,
                                                              cc_recipients   => NULL,
                                                              subject         => 'Core Backup email exception VN-'||i.vendor_number||' Program ID-'||i.program_id
                                                              ); 
                                
                         --Attach text in the mail                                              
                         xx_pa_pb_mail.write_text (conn   => lc_conn,
                                                   message   => lc_attach_text);
                         --End of mail                                    
                         xx_pa_pb_mail.end_mail (conn => lc_conn);
                        EXCEPTION
                          WHEN OTHERS THEN 
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in sending email to vendorprogram '||i.program_id||i.vendor_number||'--'||SQLERRM); -- Error in sending email
                            NULL;
                        END;
                                    
                  ELSE
									-- Call AR VPS Invoice SKU Statement Backup Program	
											  BEGIN
											     v_inv_sku_req :=  fnd_request.submit_request(application => 'XXFIN',
												                                                program => 'XXARVPSINVSKUBKUP',
												                                            description =>  'OD US AR VPS Invoice Statement Backup',
                                                                  --  start_time => to_char(sysdate + 4/86400,'DD-MON-YYYY HH24:MI:SS'), --4 Secs
												                                              argument1 => i.program_id ,
												                                              argument2 => i.vendor_number												                                              );
												COMMIT;
												 	EXCEPTION
												 			WHEN OTHERS THEN 
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in calling OD: US AR VPS Invoice SKU Statement Backup Program'||i.program_id||i.vendor_number);
												 				NULL;
												 	END;
                          -- Added by uday
                          l_req_return_status := fnd_concurrent.wait_for_request (request_id      => v_inv_sku_req
                                            ,INTERVAL        => 5 --interval Number of seconds to wait between checks
                                            ,max_wait        => 60 --Maximum number of seconds to wait for the request completion
                                             -- out arguments
                                            ,phase           => lc_phase
                                            ,STATUS          => lc_status
                                            ,dev_phase       => lc_dev_phase
                                            ,dev_status      => lc_dev_status
                                            ,message         => lc_message
                                            );	
                  END IF; --INVOICES SKUS Row Count                          
								 END IF;
  END LOOP; -- 
  END LOOP; -- cur_core_invoices
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'End VPS_BACKUP_GET ');
  EXCEPTION
      	    WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE('Exception: ' || SQLERRM);
                  commit;  
  END VPS_BACKUP_GET; 
END XX_FIN_VPS_BACKUP_INVSKU;
/