create or replace 
PACKAGE BODY xx_om_item_wsh_assign_pkg
-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_ITEM_WSG_ASSIGN                                       |
-- | Rice ID     : Item Warehouse Assignment                                   |
-- | Description : Procedure to call RMS to insert the Item and Location to fix|
-- |               the Item errors from HVOP				                   |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                       Remarks                 |
-- |=======   ==========  =============    ====================================|
-- |DRAFT 1A 09-OCT-2008  Bala E		   Initial draft version               |
-- |V1.0     17-OCT-2008  Bala E		 			                           |
-- |V2.0     23-OCT-2008  Bala E		   Added DC Location Filter            |
-- |V3.0     20-OCT-2015  Havish Kasina	   Removed the schema references in the|
-- |                                       existing code as per R12.2 Retrofit |
-- |                                       Changes  
---| v4.0    24-APR-2018   Faiyaz Ahmad  removing dblink and calling webservices
-- +===========================================================================+
AS
-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------

PROCEDURE invoke_rms_items_webserv(
    p_content     IN CLOB)
IS
  req utl_http.req;
  res utl_http.resp;
  url                      VARCHAR2(4000);
  name                     VARCHAR2(4000);
  buffer                   CLOB;   
  p_user                   VARCHAR2(100); 
  lv_username              VARCHAR2(100);
  lv_subscription_password VARCHAR2(100);
  l_wallet_location        VARCHAR2(256) := NULL;
  l_password               VARCHAR2(256) := NULL;
  v_response_status_code   VARCHAR2(256);
  v_response_reason        VARCHAR2(256);
  content                     CLOB           := p_content;  
  l_req_length             binary_integer;
  l_buffer                 varchar2 (2000);
  l_amount                 pls_integer := 2000;
 
  l_offset NUMBER :=1;
   buff VARCHAR2(10000);
   clob_buff CLOB;

BEGIN

  BEGIN
    SELECT TARGET_VALUE1 ,
      TARGET_VALUE2
    INTO l_wallet_location ,
      l_password
    FROM XX_FIN_TRANSLATEVALUES VAL,
      XX_FIN_TRANSLATEDEFINITION DEF
    WHERE 1                 =1
    AND DEF.TRANSLATE_ID    = VAL.TRANSLATE_ID
    AND DEF.TRANSLATION_NAME='XX_INV_RMS_WEBSERVICE'
    AND VAL.SOURCE_VALUE1   = 'WALLET_LOCATION'
    AND VAL.ENABLED_FLAG    = 'Y'
    AND SYSDATE BETWEEN VAL.START_DATE_ACTIVE AND NVL(VAL.END_DATE_ACTIVE, SYSDATE+1);
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.LOG, 'Wallet Location Not Found' );
    l_wallet_location := NULL;
    l_password        := NULL;
  END;
  IF l_wallet_location IS NOT NULL THEN
    UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
  END IF;
 BEGIN
    SELECT target_value1,
      XX_ENCRYPT_DECRYPTION_TOOLKIT.DECRYPT(target_value2),
      XX_ENCRYPT_DECRYPTION_TOOLKIT.DECRYPT(target_value3)
    INTO url,
      lv_username ,
      lv_subscription_password
    FROM XX_FIN_TRANSLATEVALUES TV,
      XX_FIN_TRANSLATEDEFINITION TD
    WHERE TD.TRANSLATION_NAME = 'XX_INV_RMS_WEBSERVICE'
    AND TV.TRANSLATE_ID       = TD.TRANSLATE_ID
    AND TV.ENABLED_FLAG       = 'Y'
    AND sysdate BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,sysdate)
    AND tv.source_value1 = 'RMS_SERVICE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.LOG,'XX_INV_RMS_WEBSERVICE Translation Not Found' );
    url                      :=NULL;
    lv_username              :=NULL;
    lv_subscription_password := NULL;
  END;
  
  if url is not null and lv_username  is not null and lv_subscription_password is not null then
     
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
  fnd_file.put_line (fnd_file.LOG,'Request URL: '||req.url);
  utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
  fnd_file.put_line (fnd_file.LOG,'Request Version: '||req.http_version);
  utl_http.set_header(req, 'content-type', 'application/json');
  utl_http.set_header(req, 'Content-Length', LENGTH(content));
  utl_http.set_header(req, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lv_username||':'||lv_subscription_password))));
  LOOP
    EXIT
  WHEN l_offset > dbms_lob.getlength(content);
    utl_http.write_text(req, dbms_lob.substr(content, 10000, l_offset ));
    l_offset := l_offset + 10000;
  END LOOP;
  
  
  res                    := utl_http.get_response(req);
  v_response_status_code :=res.status_code;
  v_response_reason      := res.reason_phrase;
  fnd_file.put_line (fnd_file.LOG,'Response Status Code: '||res.status_code);
  fnd_file.put_line (fnd_file.LOG,'Response Reason: '||res.reason_phrase);
  fnd_file.put_line (fnd_file.LOG,'Response Version: '||res.http_version);
  -- process the response from the HTTP call
   BEGIN
         clob_buff := EMPTY_CLOB;
         LOOP
            UTL_HTTP.READ_TEXT(res, buff, LENGTH(buff));
            fnd_file.put_line (fnd_file.LOG,buff);
  		    clob_buff := clob_buff || buff;
         END LOOP;
  	     UTL_HTTP.END_RESPONSE(res);
      EXCEPTION
  	     WHEN UTL_HTTP.END_OF_BODY THEN
            UTL_HTTP.END_RESPONSE(res);
  	     WHEN OTHERS THEN
			  fnd_file.put_line (fnd_file.LOG,'Exception raised while reading text: '||SQLERRM);
              UTL_HTTP.END_RESPONSE(res);
      END;
 /* BEGIN
    LOOP
      utl_http.read_line(res, buffer);
      fnd_file.put_line (fnd_file.LOG,buffer);
    END LOOP;
    utl_http.end_response(res);
  EXCEPTION
  WHEN utl_http.end_of_body THEN
    utl_http.end_response(res);
  END;*/
  End if;
END invoke_rms_items_webserv;

    -- +===================================================================+
    -- | Name  : Exec_rms_wsh_assign                                       |
    -- | Description : Procedure to call RMS to insert the Item and Loc    |
    -- |               to fix the item Errors from HVOP                    |
    -- |                                                                   |
    -- | Parameters :       p_request_id                                   |
    -- |                    p_process_date  				               |
    -- |		            retcode                                        |
    -- |                    Errbuf                                         |
    -- +===================================================================+
    PROCEDURE Exec_item_rms_wsh_assign
                                  (  retcode OUT NOCOPY  NUMBER
                                  , errbuf OUT NOCOPY VARCHAR2
                                  , p_sch_flag IN VARCHAR2
			                            , p_request_id IN NUMBER
			                            , p_process_Date IN VARCHAR2
                                  ) IS
    x_ln_retcode INTEGER;
    x_lc_retmsg VARCHAR2(300);
    p_lc_user VARCHAR2(30) := 'EBS';
    
    TYPE item_rec IS TABLE OF hr_all_organization_units.attribute1%TYPE INDEX BY BINARY_INTEGER;
    TYPE loc_rec IS TABLE OF oe_processing_msgs_vl.message_text%TYPE INDEX BY BINARY_INTEGER;
    n BINARY_INTEGER := 0;
    ln_counter NUMBER;
    p_item_rec item_rec;
    p_loc_rec loc_rec;
    p_user      VARCHAR2(100):= 'EBS2RMS_REST_SRV';
    l_content   CLOB;

    CURSOR item_all_cur
        IS
        SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
            and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and SUBSTR(M.MESSAGE_TEXT,1,8) = '10000018'
            --and rownum <850
            and NVL(H.ERROR_FLAG,'N') = 'Y';
            ---ffor test
          --  and hr.attribute1='1127';

    CURSOR item_processdate_cur(p_process_date IN VARCHAR2)
    IS
    SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
        from  oe_headers_iface_all h
            , xx_om_headers_attr_iface_all xh
            , oe_processing_msgs_vl m
            , xx_om_sacct_file_history s
            , hr_all_organization_units hr
            , hr_locations l
            , xx_inv_org_loc_rms_attribute xi
        where h.orig_sys_document_ref = xh.orig_sys_document_ref
        and   h.order_source_id = xh.order_source_id
        and  xh.imp_file_name = s.file_name
        and s.file_type = 'ORDER'
        and to_char(s.process_date,'YYYY/MM/DD') = substr(p_process_date,1,10)
        and  h.orig_sys_document_ref = m.original_sys_document_ref
        and h.order_source_id = m.order_source_id
        and h.ship_from_org_id = hr.organization_id
        and hr.location_id = l.location_id
        and hr.attribute1 = xi.location_number_sw
	and xi.org_type = 'WH'
        and xi.od_type_sw = 'CS'
        and substr(m.message_text,1,8) = '10000018'
        and nvl(h.error_flag,'N') = 'Y';

      CURSOR item_processid_cur(p_request_id IN NUMBER)
        IS
        SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and s.master_request_id = p_request_id
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
	    and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and substr(m.message_text,1,8) = '10000018'
            and nvl(h.error_flag,'N') = 'Y';

      CURSOR item_sch_cur
           IS
           SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
	    and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and substr(m.message_text,1,8) = '10000018'
            and nvl(h.error_flag,'N') = 'Y'
            and s.request_id in (select request_id from fnd_concurrent_requests where parent_request_id in(select max(request_id) parent_request_id
                                from fnd_concurrent_requests r,fnd_concurrent_programs_tl P
                                where r.concurrent_program_id = p.concurrent_program_id
                                and   p.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
                                group by substr(r.argument1,4,2)));
    BEGIN

    If p_sch_flag = 'N' then
    FND_FILE.put_line(FND_FILE.log,'Manually submitted the program to update the Items in RMS');
              if p_process_date is null and p_request_id is null then
                     Open item_all_cur;
                     fetch item_all_cur bulk collect into p_item_rec,p_loc_rec;
                     Close item_all_cur;
              End if;
              if p_process_date is not null and p_request_id is null then
                     Open item_processdate_cur(p_process_date);
                     Fetch item_processdate_cur bulk collect into p_item_rec,p_loc_rec;
                     Close item_processdate_cur;
              End if;
              If p_request_id is not null and p_process_date is null then
                      Open item_processid_cur(p_request_id);
                      fetch item_processid_cur bulk collect into p_item_rec,p_loc_rec;
                      close item_processid_cur;
              End if;

      Else
      FND_FILE.put_line(FND_FILE.log,'Schduled job to update the Items in RMS');
                    Open item_sch_cur;
                    Fetch item_sch_cur bulk collect into p_item_rec, p_loc_rec;
                    Close item_sch_cur;

      End if;

    -- Creating payload-----
     FND_FILE.put_line(FND_FILE.log,'Items Idetified: ' ||p_item_rec.count);
     if p_item_rec.count >0  then
         FND_FILE.put_line(FND_FILE.log,'Called the RMS procedure at: '|| to_char(sysdate,'DD-MON-YYYY HH24:MM:SS'));
         l_content := EMPTY_CLOB();
         dbms_lob.createtemporary(l_content,true);
         l_content := l_content 
                 || '{'
                 || CHR(13)
                 || '"USER": "'
                 || p_user
                 || '",'
                 || CHR(13)
                 || '"ITEM_LOCATIONS": ['
                 || CHR(13);
      
      IF p_item_rec.count > 1 THEN
        for i in 1..p_item_rec.count-1 LOOP
          l_content := l_content 
                    || '{ "ITEM": "'
                    || P_ITEM_REC(i)
                    || '", "LOCATION": '
                    || P_LOC_REC(i)
                    || '},'
                    || CHR(13);
        end loop;
      END IF;
      
      l_content := l_content 
                    || '{ "ITEM": "'
                    || P_ITEM_REC(p_item_rec.count)
                    || '", "LOCATION": '
                    || P_LOC_REC(p_item_rec.count)
                    || '}'
                    || CHR(13);
      
      l_content := l_content 
                || ']'
                || CHR(13)
                || '}'
                || CHR(13);
				
				---- calling webservices---
      
      invoke_rms_items_webserv(l_content);
      
      dbms_lob.freetemporary(l_content);
      FND_FILE.put_line(FND_FILE.log,'RMS procedure call ended at: ' || to_char(sysdate,'DD-MON-YYYY HH24:MM:SS'));
       
     Else
        retcode := 01;
        errbuf := 'The RMS procedure has not been called as there are no items Identified';
      	FND_FILE.put_line(FND_FILE.log,errbuf);
     End if;


   commit;
    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          retcode := 10;
          errbuf := 'Time Out Error when executing the procedure' ;
        WHEN LOGIN_DENIED THEN
          retcode := 11;
          errbuf := 'Login Failed Error';
        WHEN NO_DATA_FOUND THEN
          retcode := 04; -- No Data found error
          errbuf := 'No Data found Error' ;
        WHEN OTHERS THEN
          retcode := 05; -- No Data found error
          errbuf := 'Unexpecter Error from the procedure' ;
          FND_FILE.put_line(FND_FILE.log,errbuf || SQLERRM);
      END Exec_item_rms_wsh_assign;
    END xx_om_item_wsh_Assign_pkg;
/