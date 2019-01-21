create or replace PACKAGE BODY XX_FIN_AR_INV_VPS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_AR_INV_VPS_PKG                                                     	        |
  -- |                                                                                            |
  -- |  Description:  This package body to validate and create VPS invoices                       | 
  -- |                through Auto Invoices.        		                                          |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         12-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- | 1.1         16-MAR-2017  Satheesh Suthari	 Defect# 44458  
  -- +============================================================================================+
  
procedure publish_invoice_status
( p_trx_number    in varchar2
, p_record_status in varchar2
, p_error_message in varchar2
, p_response_code out varchar2
) is

  req utl_http.req;
  res utl_http.resp;
  url varchar2(4000) ;--:= 'https://agerndev.na.odcorp.net/vpsservice/api/v2/XXFIN_INVOICE_RESPONSE/'; --create a profile and set the VPS invoice update REST service URL;
  name varchar2(4000);
  buffer varchar2(4000); 
  content varchar2(4000) := '{ "InputParameters": {  "INVOICE_NUM": "' || p_trx_number || '",  "RECORD_STATUS":"' || p_record_status || '",  "ERROR_MESSAGE": "' ||  p_error_message || '" }}';
  
      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL; 
      l_publish_debug       VARCHAR2(50)    := NULL;
      l_username            VARCHAR2(256)   := NULL;
      l_vps_password        VARCHAR2(256)   := NULL;
      l_enable_auth         VARCHAR2(256)   := NULL;
begin
      --url:=apps.fnd_profile.VALUE('XX_FIN_AR_VPS_INV_RESP');

      BEGIN
      
        SELECT 
            TARGET_VALUE1,TARGET_VALUE2
         INTO
            url,l_publish_debug
         FROM  XX_FIN_TRANSLATEVALUES VALS
              ,XX_FIN_TRANSLATEDEFINITION DEFN
         WHERE 1=1
         AND DEFN.TRANSLATE_ID=VALS.TRANSLATE_ID
         AND DEFN.TRANSLATION_NAME = 'OD_VPS_TRANSLATION'
         AND SOURCE_VALUE1 LIKE 'VPS_INV_PUBLISH_URL';        
        
      EXCEPTION 
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'VPS_INV_PUBLISH_URL Translation Not Found in OD_VPS_TRANSLATION' );
          url:=NULL;
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

        EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Wallet Location Not Found' );
          l_wallet_location := NULL;
          l_password := NULL;
        END;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_wallet_location: ' || l_wallet_location);
        BEGIN
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
   --Set wallet location    
  IF l_wallet_location IS NOT NULL THEN
    UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
  END IF;
 --Begin Request
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
    IF l_publish_debug='Y' THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Request URL: '||req.url);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Method: '||req.method);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Version: '||req.http_version);
    END IF;
  --Set headers
  utl_http.set_header(req, 'user-agent', 'mozilla/5.0'); 
  utl_http.set_header(req, 'content-type', 'application/json'); 
  utl_http.set_header(req, 'Content-Length', length(content));
  --utl_http.set_header(req, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw('NA\SVC_VPS_ISG:cw7?Rddk'))));
  IF UPPER(l_enable_auth) IN ('Y','YES') THEN 
  utl_http.set_header(req, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(l_username||':'||l_vps_password))));
  END IF;
  utl_http.write_text(req, content);
  res := utl_http.get_response(req);
  IF l_publish_debug='Y' THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Response Status Code: '||res.status_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Response Reason: '||res.reason_phrase);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Response Version: '||res.http_version);
  END IF;
  -- process the response from the HTTP call
  begin
    loop
   -- FND_FILE.PUT_LINE(FND_FILE.LOG,'process http call');
      utl_http.read_line(res, buffer);
      dbms_output.put_line(buffer);
    end loop;
    utl_http.end_response(res);
  exception
    when utl_http.end_of_body 
    then
      utl_http.end_response(res);
  end;
 p_response_code:=res.status_code;
end publish_invoice_status;
  
PROCEDURE pre_process_invoices(  errbuff OUT VARCHAR2,
                                 retcode OUT VARCHAR2,
                                 trans_source IN VARCHAR2 DEFAULT NULL
                                 )
  IS 
  
  lv_error_flag                             VARCHAR2(1);
  lv_org_id                                 hr_operating_units.organization_id%TYPE;
  lv_sob_id                                 hr_operating_units.set_of_books_id%TYPE;
  lv_batch_source_name                      ra_batch_sources_all.name%TYPE;      
  lv_batch_source_id                        ra_batch_sources_all.batch_source_id%TYPE;
  ln_cust_account_id                        hz_cust_accounts.cust_account_id%TYPE;   
  ln_cust_acct_site_id                      hz_cust_acct_sites_all.cust_acct_site_id%TYPE;   
  lv_term_id                                NUMBER;
  lv_term_name                              VARCHAR2(256);
  lv_trx_type_name                          VARCHAR2(256);
  lv_trx_type                               VARCHAR2(256);
  ln_trx_type_id                            NUMBER;
  ln_autoinv_req_id                         NUMBER;
  
  ln_min_interface_line_id                  NUMBER;
  
  CURSOR cur_vps_inv (p_min_interface_line_id number)
  IS
   SELECT *
     FROM ra_interface_lines_all
   WHERE 1=1
     AND interface_line_id > p_min_interface_line_id -1
     AND batch_source_name = NVL(trans_source,batch_source_name)
     AND header_attribute_category='US_VPS';
     
   CURSOR cur_auto_inv (p_org_id number)
    IS
     SELECT rbs.name batch_source_name,rbs.batch_source_id,rbs.org_id 
      FROM  ra_batch_sources_all rbs
      WHERE 1=1 
      AND rbs.name like '%VPS%'
      AND rbs.status='A'
      AND rbs.org_id=p_org_id;
    
  
  BEGIN
    --Get Min interface_line_id
    BEGIN
     SELECT min(interface_line_id)
       INTO ln_min_interface_line_id
      FROM ra_interface_lines_all;
    EXCEPTION
        WHEN OTHERS THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_mix_interface_line_id Error: ' ||SQLERRM);	
    END;  
  
    --ORG ID , SOB
    BEGIN
     SELECT organization_id, set_of_books_id
       INTO lv_org_id, lv_sob_id
      FROM hr_operating_units
      WHERE name = 'OU_US_VPS';
    EXCEPTION
        WHEN OTHERS THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating Unit Error: ' ||SQLERRM);	
    END;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id: ' ||lv_org_id);   
    FOR i IN cur_vps_inv (ln_min_interface_line_id) LOOP
      lv_error_flag               :='N';
      lv_batch_source_name        :=NULL;
      lv_batch_source_id          :=NULL;
      ln_cust_account_id          :=NULL;
      ln_cust_acct_site_id        :=NULL;
      lv_term_id                  :=NULL;
      lv_term_name                :=NULL;
      lv_trx_type_name            := NULL;
      ln_trx_type_id              := NULL;
      lv_trx_type                 :=NULL;
      
  ------------------------------Cust Trx Type-------------------------------------------------------------
      BEGIN
        SELECT rctt.name,rctt.cust_trx_type_id,rctt.type
          INTO lv_trx_type_name, ln_trx_type_id,lv_trx_type
          FROM ra_cust_trx_types_all rctt
              ,hr_operating_units hou
          WHERE 1=1
          AND rctt.name = i.cust_trx_type_name
          AND rctt.org_id=hou.organization_id
          AND hou.name= 'OU_US_VPS';
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Trx Type: '||lv_trx_type_name||', cust_trx_type_id:' ||ln_trx_type_id||', trx type:'||lv_trx_type);	
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Trx Type No Data Found: '||'lv_trx_type_name: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
          WHEN TOO_MANY_ROWS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Trx Type Too Many Rows: '||'lv_trx_type_name: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
          WHEN OTHERS THEN 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Trx Type Unexpected Error: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
      END;
  ------------------------------Validate Terms-------------------------------------------------------------
    IF lv_trx_type <>'CM' THEN 
      BEGIN  
         select rt.term_id,rt.name
            INTO lv_term_id, lv_term_name
            from   hz_cust_profile_classes cpc
                  ,ra_terms rt
            where  1=1  
              and    cpc.standard_terms = rt.term_id
              and    cpc.name = 'VPS_CUSTOMER';
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Terms: '||lv_term_id||', lv_term_name:' ||lv_term_name);	         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Terms No Data Found: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
          WHEN TOO_MANY_ROWS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Terms Too Many Rows: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
          WHEN OTHERS THEN 
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Terms Unexpected Error: '||i.cust_trx_type_name||' - ' ||SQLERRM);	
      END;
    ELSE
      lv_term_id:=NULL;
      lv_term_name:=NULL;
  END IF;
      ------------------------------Validate ORIG_SYSTEM_BILL_CUSTOMER_REF ---------------------------------------     
      BEGIN      
        BEGIN
          select owner_table_id
          into   ln_cust_account_id
          from   hz_orig_sys_references
          where  orig_system='VPS'
          and    orig_system_reference=trim(i.header_attribute1) ||'-VPS'
          and    owner_table_name='HZ_CUST_ACCOUNTS'
          and    status='A'
          ;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Acct OSR: ' || trim(i.header_attribute1) ||'-VPS' || '; ln_cust_account_id: '||ln_cust_account_id);	
        EXCEPTION    
          WHEN NO_DATA_FOUND THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Could not retrieve cust_account_id for Vendor Number:' || i.attribute1 || ', and frequence_code:' || i.attribute12);
        END;
        
        BEGIN
          select owner_table_id
          into   ln_cust_acct_site_id
          from   hz_orig_sys_references
          where  orig_system='VPS'
          and    orig_system_reference=trim(i.header_attribute1)|| '-01-VPS'
          and    owner_table_name='HZ_CUST_ACCT_SITES_ALL'
          and    status='A'
          ;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'site OSR: ' || trim(i.header_attribute1)||'-VPS' || '; ln_cust_acct_site_id: '||ln_cust_acct_site_id);	
        EXCEPTION    
          WHEN NO_DATA_FOUND THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Could not retrieve cust_acct_site_id for Vendor Number:' || i.header_attribute1 || ', and frequence_code:' || i.header_attribute13);
        END;
          
        update ra_interface_lines_all
        set    term_id = lv_term_id
              ,term_name = lv_term_name
             -- ,batch_source_name = lv_batch_source_name
              ,org_id = lv_org_id          
              ,orig_system_bill_customer_id = ln_cust_account_id
              ,orig_system_ship_customer_id = ln_cust_account_id
              ,orig_system_sold_customer_id = ln_cust_account_id
              ,orig_system_bill_address_id = ln_cust_acct_site_id
              ,orig_system_ship_address_id = ln_cust_acct_site_id
              ,quantity = 1
              ,unit_selling_price = amount
              ,unit_standard_price = amount
              ,memo_line_name = 'VPS_LINE' 
              ,cust_trx_type_name = lv_trx_type_name             
              ,cust_trx_type_id = ln_trx_type_id             
        where  interface_line_id = i.interface_line_id;  
        
        insert into XX_FIN_VPS_TRX_STG ( 
                     INTERFACE_LINE_ID
                    ,TRX_NUMBER      
                    ,RECORD_STATUS   
                    ,ERROR_MESSAGE   
                    ,CREATION_DATE   
                    ,CREATED_BY      
                    ,PROGRAM_ID      
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATED_BY 
                   ) VALUES (
                     i.INTERFACE_LINE_ID
                    ,i.TRX_NUMBER
                    ,'I'
                    ,null
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                    ,FND_GLOBAL.CONC_PROGRAM_ID
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                   );
      
      COMMIT;
    

    EXCEPTION    
      WHEN OTHERS THEN 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in validating invoices: ' ||SQLERRM);
    END;

  END LOOP; 
  
  -- Kick off Auto Invoice master program 
  FOR x in cur_auto_inv (lv_org_id)
  LOOP
    ln_autoinv_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                application => 'AR'
                               ,program     => 'RAXMTR'
                               ,description => ''
                               ,start_time  => ''
                             --  ,sub_request => TRUE
                               ,argument1   => 1
                               ,argument2   => x.org_id
                               ,argument3   => x.batch_source_id
                               ,argument4   => x.batch_source_name           
                               ,argument5   => TO_CHAR(TRUNC(SYSDATE),'RRRR/MM/DD HH24:MI:SS') 
                               ,argument6   => ''
                               ,argument7   => ''
                               ,argument8   => ''
                               ,argument9   => ''
                               ,argument10  => ''
                               ,argument11  => ''
                               ,argument12  => ''
                               ,argument13  => ''
                               ,argument14  => ''
                               ,argument15  => ''
                               ,argument16  => ''
                               ,argument17  => ''
                               ,argument18  => ''
                               ,argument19  => ''
                               ,argument20  => ''
                               ,argument21  => ''
                               ,argument22  => ''
                               ,argument23  => ''
                               ,argument24  => ''
                               ,argument25  => ''
                               ,argument26  => 'Y'
                               ,argument27  => ''
                               ,argument28  => CHR(0)
                               );
        COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Auto Invoice Master RAXMTR: '||'Batch Source Name: '||x.batch_source_name||' Request Id: '||ln_autoinv_req_id);
  
  END LOOP;
  
END pre_process_invoices;  

PROCEDURE post_process_invoices(errbuff OUT VARCHAR2,
                                retcode OUT VARCHAR2)
IS
  lv_record_status varchar2(1);
  lv_error_message varchar2(256);
  lv_response_code varchar2(256);
 
  CURSOR c1 
  IS
  select *
    from   XX_FIN_VPS_TRX_STG
  where 1=1
    --and record_status in ('I', 'E','S')
    and NVL(response_code,'X') <> '200';
  
BEGIN

  for i_rec in c1
  loop
   lv_record_status := null;
   lv_error_message  := null;
   lv_response_code:=null;
   
   begin
     --commented for defect# 44458
     /*select 'S' 
      into  lv_record_status
      from  ra_customer_trx_all
     where  trx_number=i_rec.trx_number
     and attribute_category='US_VPS';*/
	 --Start changes for defect# 44458
	  select 'S'
      into lv_record_status
      from ra_customer_trx_all rcta,
	       ra_customer_trx_lines_all rctl
     where rcta.trx_number = i_rec.trx_number
	   and rctl.customer_trx_line_id = i_rec.interface_line_id
	   and rcta.customer_trx_id = rctl.customer_trx_id
       and rcta.attribute_category = 'US_VPS';
	 --End changes for defect# 44458
   exception
     when no_data_found then
       lv_record_status := 'E';
       begin 
         select message_text
         into   lv_error_message
         from   ra_interface_errors_all
         where  interface_line_id = i_rec.interface_line_id
         and rownum=1;
       exception
         when no_data_found then
           lv_error_message := 'Unknown Error in Creating the VPS Invoice';
       when too_many_rows then
           lv_error_message := 'Too Many Rows in ra_interface_errors_all ';
       when others then
        lv_error_message := 'Unexpected error in ra_interface_errors_all ';
      end;
	 when others then                                      --defect# 44458
        lv_error_message := 'Unknown Error in Creating the VPS Invoice - '||sqlerrm; --defect# 44458
   end;
   
   IF lv_record_status='S' THEN
        BEGIN
            UPDATE ar_payment_schedules_all aps
              SET aps.due_date=NVL((SELECT TRUNC(TO_DATE(rct.attribute12,'DD-MON-YYYY HH:MI:SS'))
                                  FROM ra_customer_trx_all rct
                                  WHERE 1=1
                                    AND rct.trx_number=i_rec.trx_number
                                    AND rct.customer_trx_id=aps.customer_trx_id
                                    AND rct.attribute_category='US_VPS'),aps.due_date)
                  ,aps.last_update_date = SYSDATE
                  ,aps.last_updated_by = fnd_global.user_id
                  ,aps.last_update_login = fnd_global.login_id	
            WHERE EXISTS (SELECT customer_trx_id
                            FROM ra_customer_trx_all rct
                           WHERE 1=1
                             AND rct.trx_number=i_rec.trx_number
                             AND rct.customer_trx_id=aps.customer_trx_id
                             AND rct.attribute_category='US_VPS')
              AND aps.status='OP';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date No Data Found:'||SQLERRM);
            NULL;
          WHEN TOO_MANY_ROWS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date TOO Many Rows:'||i_rec.trx_number||SQLERRM);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date '||SQLERRM);
            NULL;
        END;
      COMMIT;
    END IF;
   
    publish_invoice_status
    ( p_trx_number    => i_rec.trx_number
    , p_record_status => lv_record_status
    , p_error_message => lv_error_message
    , p_response_code => lv_response_code
    ); 
    UPDATE XX_FIN_VPS_TRX_STG
       SET record_status = lv_record_status,
           error_message = substrb(lv_error_message,256),
           response_code =lv_response_code
    WHERE  trx_number = i_rec.trx_number;
    COMMIT; 
  end loop;
END post_process_invoices; 

PROCEDURE post_proc_validate_process(errbuff OUT VARCHAR2,
                                     retcode OUT VARCHAR2)
IS
  lv_record_status varchar2(1);
  lv_error_message varchar2(256);
  lv_response_code varchar2(256);
 
  CURSOR c1 
  IS
  select aps.due_date, rct.attribute12, stg.*
    from   XX_FIN_VPS_TRX_STG stg
           ,AR_PAYMENT_SCHEDULES_ALL APS
           ,RA_CUSTOMER_TRX_ALL      RCT
  where 1=1
    and stg.trx_number = rct.trx_number
    and aps.customer_trx_id = rct.customer_trx_id
    and stg.record_status='S'
    and trunc(aps.due_date) <> NVL(TRUNC(TO_DATE(rct.attribute12,'DD-MON-YYYY')), trunc(aps.due_date))
    and trunc(stg.creation_date) >= trunc(sysdate)-1
    ;
  
BEGIN

  for i_rec in c1
  loop
   
   BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Mismatch found for Trx_Number: ' || i_rec.trx_number || ', Due_Date: ' || i_rec.due_date || ', DFF Date: ' || i_Rec.attribute12);
     
     UPDATE ar_payment_schedules_all aps
       SET aps.due_date=NVL((SELECT TRUNC(TO_DATE(rct.attribute12,'DD-MON-YYYY HH:MI:SS'))
                           FROM ra_customer_trx_all rct
                           WHERE 1=1
                             AND rct.trx_number=i_rec.trx_number
                             AND rct.customer_trx_id=aps.customer_trx_id
                             AND rct.attribute_category='US_VPS'),aps.due_date)
           ,aps.last_update_date = SYSDATE
           ,aps.last_updated_by = fnd_global.user_id
           ,aps.last_update_login = fnd_global.login_id	
     WHERE EXISTS (SELECT customer_trx_id
                     FROM ra_customer_trx_all rct
                    WHERE 1=1
                      AND rct.trx_number=i_rec.trx_number
                      AND rct.customer_trx_id=aps.customer_trx_id
                      AND rct.attribute_category='US_VPS')
       AND aps.status='OP';
           
       IF(SQL%ROWCOUNT > 0) THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Successfully update Due_Date for Trx_Number: ' || i_rec.trx_number);
       END IF;         
       
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in post_proc_validate_process: Update Due Date No Data Found:'||SQLERRM);
         NULL;
       WHEN TOO_MANY_ROWS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in post_proc_validate_process: Update Due Date TOO Many Rows:'||i_rec.trx_number||SQLERRM);
         NULL;
       WHEN OTHERS THEN 
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in post_proc_validate_process: Update Due Date '||SQLERRM);
         NULL;
     END;
   COMMIT;   
   
  end loop;

  EXCEPTION
    when others then
       lv_error_message := 'Unexpected error in post_proc_validate_process ';
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in post_proc_validate_process:'||SQLERRM);
  
END post_proc_validate_process; 


END XX_FIN_AR_INV_VPS_PKG ;
/