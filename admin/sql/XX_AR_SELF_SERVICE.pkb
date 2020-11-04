create or replace package body XX_AR_SELF_SERVICE as

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AR_SELF_SERVICE.pkb                                    |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | Table hanfler for xx_crm_sfdc_contacts.                                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       01-Oct-2020  Divyansh Saini     Initial version                 |
-- |                                                                          |
-- +==========================================================================+

/*********************************************************************
* procedure to put logs
*********************************************************************/
Procedure logs(p_message IN VARCHAR2,p_def IN BOOLEAN DEFAULT FALSE) IS
  lc_message VARCHAR2(2000);
BEGIN
    --if debug is on (defaults to true)
    IF (g_debug_profile OR p_def)
    THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF')
                         || ' => ' || p_message, 1, g_max_log_size);

      -- if in concurrent program, print to log file
      IF (g_conc_req_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
      -- else print to DBMS_OUTPUT
      ELSE
        DBMS_OUTPUT.put_line(lc_message);
      END IF;
    END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
END;

/*********************************************************************
* procedure to write the number of errored and processed data
*********************************************************************/

procedure set_global_variables IS

  lv_debug_pro_val VARCHAR2(100) := FND_PROFILE.VALUE('XX_AR_SS_DEBUG');
BEGIN

    g_package_name   := 'XX_AR_SELF_SERVICE';
    IF lv_debug_pro_val in ('Yes','Y') THEN
       g_debug_profile  := True;
    ELSE
       g_debug_profile  := False;
    END IF;
    g_max_log_size  := 2000;
    g_conc_req_id   := fnd_global.conc_request_id;
    G_SMTP_SERVER   :=FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
    G_MAIL_FROM     := 'noreply@officedepot.com';

EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
END;
/*********************************************************************
* procedure to write the number of errored and processed data
*********************************************************************/
procedure write_output(p_process_type IN VARCHAR2,
                       p_process_id  IN NUMBER) IS

Cursor c_counts IS
   SELECT count(0) cnt,status
     FROM xx_ar_self_serv_bad_email
    WHERE process_id = p_process_id
      AND direct_bill_flag = 'Y'
    group by status
    UNION
   SELECT count(0),status
     FROM xx_ar_self_serv_bad_addr
    WHERE process_id = p_process_id
      AND direct_bill_flag = 'Y'
    group by status
   UNION
   SELECT count(0),status
     FROM xx_ar_self_serv_bad_contact
    WHERE process_id = p_process_id
      AND direct_bill_flag = 'Y'
    group by status;

CURSOR c_error_details IS
   SELECT   CUSTOMER_NAME,
            AOPS_ACCOUNT,
            account_number,
            'Email Address' info_type,
            EMAIL_ADDRESS detail
     FROM xx_ar_self_serv_bad_email
    WHERE process_id = p_process_id
      AND status = 'E'
    UNION
   SELECT CUSTOMER_NAME,
          AOPS_ACCOUNT,
          account_number,
          'Customer Address' info_type,
          ADDRESS1||','|| ADDRESS2||','||CITY||','||STATE||','||ZIP detail
     FROM xx_ar_self_serv_bad_addr
    WHERE process_id = p_process_id
      AND status = 'E';
CURSOR c_error_details_cont IS
   SELECT CUSTOMER_NAME,
          AOPS_ACCOUNT,
          account_number,
          'AP Contact' info_type,
          LAST_NAME, 
          FIRST_NAME, 
          PHONE_NUMBER, 
          FAX_NUMBER, 
          EMAIL_ADDRESS
     FROM xx_ar_self_serv_bad_contact
    WHERE process_id = p_process_id
      AND status = 'E';


  ln_count NUMBER:= 0;
BEGIN
   logs('write_output(+)',true); 
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records processed : ');
   FOR rec_counts IN c_counts LOOP
      IF rec_counts.status = 'E' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of errored records       : '||rec_counts.cnt);
      ELSIF rec_counts.status = 'I' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Inactive customer     : '||rec_counts.cnt);
      ELSIF rec_counts.status = 'N' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of not processed records : '||rec_counts.cnt);
      ELSIF rec_counts.status = 'S' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of processed records     : '||rec_counts.cnt);
      END IF;
   END LOOP;
   
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------------------ ');
   FOR rec_error_details IN c_error_details LOOP
      IF ln_count = 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Errored Records Details ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer Name           AOPS Number    Account Number  Info Type          Information');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------------------ ');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rec_error_details.CUSTOMER_NAME,24)||' '||
                                     RPAD(rec_error_details.AOPS_ACCOUNT,14) ||' '||
                                     RPAD(rec_error_details.account_number,15) ||' '||
                                     RPAD(rec_error_details.info_type,18) ||' '||
                                     rec_error_details.detail);
      ln_count := ln_count+1;
   END LOOP;

   FOR rec_error_details_cont IN c_error_details_cont LOOP
      IF ln_count = 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Errored Records Details ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer Name           AOPS Number    Account Number  Info Type          Last Name       First Name      Phone Number    Fax Number      Email       ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------------------ ');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rec_error_details_cont.CUSTOMER_NAME,24)||' '||
                                     RPAD(rec_error_details_cont.AOPS_ACCOUNT,14) ||' '||
                                     RPAD(rec_error_details_cont.account_number,15) ||' '||
                                     RPAD(rec_error_details_cont.info_type,18) ||' '||
                                     RPAD(rec_error_details_cont.LAST_NAME,15) ||' '||
                                     RPAD(rec_error_details_cont.FIRST_NAME,15) ||' '||
                                     RPAD(rec_error_details_cont.PHONE_NUMBER,15) ||' '||
                                     RPAD(rec_error_details_cont.FAX_NUMBER,15) ||' '||
                                     RPAD(rec_error_details_cont.EMAIL_ADDRESS,15) );
      ln_count := ln_count+1;
   END LOOP;
   logs('write_output(-)',true);
EXCEPTION WHEN OTHERS
  THEN
    NULL;
END;


/*********************************************************************
* procedure to get translation values
*********************************************************************/
PROCEDURE GET_TRANSLATION(
    p_translation_name IN VARCHAR2 ,
    p_source_value1    IN VARCHAR2 ,
    x_target_value1    IN OUT NOCOPY VARCHAR2 ,
    x_target_value2    IN OUT NOCOPY VARCHAR2 ,
    x_target_value3    IN OUT NOCOPY VARCHAR2 )
IS
  ls_target_value1  VARCHAR2(240);
  ls_target_value2  VARCHAR2(240);
  ls_target_value3  VARCHAR2(240);
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
  ls_target_value7  VARCHAR2(240);
  ls_target_value8  VARCHAR2(240);
  ls_target_value9  VARCHAR2(240);
  ls_target_value10 VARCHAR2(240);
  ls_target_value11 VARCHAR2(240);
  ls_target_value12 VARCHAR2(240);
  ls_target_value13 VARCHAR2(240);
  ls_target_value14 VARCHAR2(240);
  ls_target_value15 VARCHAR2(240);
  ls_target_value16 VARCHAR2(240);
  ls_target_value17 VARCHAR2(240);
  ls_target_value18 VARCHAR2(240);
  ls_target_value19 VARCHAR2(240);
  ls_target_value20 VARCHAR2(240);
  ls_error_message  VARCHAR2(240);
  l_module_name     VARCHAR2(240) := 'GET_TRANSLATION';
BEGIN
--  logs(l_module_name,'RESPONSE','INFO','GET_TRANSLATION (+)');
  XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC( p_translation_name => p_translation_name ,
                                                   p_source_value1 => p_source_value1 ,
                                                   x_target_value1 => x_target_value1 ,
                                                   x_target_value2 => x_target_value2 ,
                                                   x_target_value3 => x_target_value3 ,
                                                   x_target_value4 => ls_target_value4 ,
                                                   x_target_value5 => ls_target_value5 ,
                                                   x_target_value6 => ls_target_value6 ,
                                                   x_target_value7 => ls_target_value7 ,
                                                   x_target_value8 => ls_target_value8 ,
                                                   x_target_value9 => ls_target_value9 ,
                                                   x_target_value10 => ls_target_value10 ,
                                                   x_target_value11 => ls_target_value11 ,
                                                   x_target_value12 => ls_target_value12 ,
                                                   x_target_value13 => ls_target_value13 ,
                                                   x_target_value14 => ls_target_value14 ,
                                                   x_target_value15 => ls_target_value15 ,
                                                   x_target_value16 => ls_target_value16 ,
                                                   x_target_value17 => ls_target_value17 ,
                                                   x_target_value18 => ls_target_value18 ,
                                                   x_target_value19 => ls_target_value19 ,
                                                   x_target_value20 => ls_target_value20 ,
                                                   x_error_message => ls_error_message );
--  logs(l_module_name,'RESPONSE','INFO','ls_error_message '||ls_error_message);
--  logs(l_module_name,'RESPONSE','INFO','GET_TRANSLATION (-)');
END GET_TRANSLATION;

/*********************************************************************
* procedure to purge data
*********************************************************************/
Procedure purge_old_data IS

n_days          NUMBER;
lv_null_value1  VARCHAR2(10);
lv_null_value2  VARCHAR2(10);
lv_del_str      VARCHAR2(500);
BEGIN
  GET_TRANSLATION('XX_AR_SELF_SERVICE','N_PURGE_DAYS',n_days,lv_null_value1,lv_null_value2);
  lv_del_str := 'delete from xx_ar_self_serv_bad_addr where creation_date < sysdate - :1';
  execute immediate lv_del_str using n_days;

END purge_old_data;

/*********************************************************************
* Function to get customer account number
*********************************************************************/
FUNCTION get_account_number(p_AOPS_account_number IN VARCHAR2) return VARCHAR2 IS
lv_account_number VARCHAR2(100);
BEGIN
    SELECT account_number 
      INTO lv_account_number
      FROM hz_cust_accounts hca
     WHERE SUBSTR(hca.orig_system_reference,1,8) = p_AOPS_account_number;
   return lv_account_number;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
       return '0';
    WHEN TOO_MANY_ROWS THEN
       return '-1';
    WHEN OTHERS THEN
       return null;
END;

/*********************************************************************
* Procedure to get Address reference
*********************************************************************/
Procedure get_address_reference(p_process_id IN NUMBER)  IS
lv_account_number VARCHAR2(100);
TYPE rec_type is RECORD  (address_reference VARCHAR2(1000),
                            record_id NUMBER);
TYPE tab_type IS TABLE OF rec_type;
lt_tab_type tab_type:=tab_type();
  CURSOR c_reference IS 
     SELECT hl.ORIG_SYSTEM_REFERENCE Add_reference,xx.record_id
       FROM hz_cust_accounts hca,
             hz_parties hp,
             hz_party_sites hps,
             hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all hcsu,
             hz_locations hl,
             xx_ar_self_serv_bad_addr   xx
      WHERE hca.party_id = hp.party_id
        AND hps.party_id = hp.party_id
        AND hps.party_site_id = hcas.party_site_id
        and hca.cust_account_id = hcas.cust_account_id
        AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND hps.location_id = hl.location_id
        AND hp.status = 'A'
        AND hca.status = 'A'
        AND hps.status = 'A'
        AND hcas.status = 'A'
        AND hcsu.status = 'A'
        AND hcsu.site_use_code = 'BILL_TO'
        AND hca.ACCOUNT_NUMBER = xx.ACCOUNT_NUMBER
        AND xx.process_id = p_process_id
        AND xx.DIRECT_BILL_FLAG = 'Y';

BEGIN

   OPEN c_reference;
   FETCH c_reference BULK COLLECT INTO lt_tab_type;
   
   FORALL i in lt_tab_type.FIRST ..lt_tab_type.LAST
     UPDATE xx_ar_self_serv_bad_addr SET address_reference = lt_tab_type(i).address_reference WHERE process_id = p_process_id AND record_id  = lt_tab_type(i).record_id;

EXCEPTION 
    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Check_If_Direct '||SQLERRM);
END;

/*********************************************************************
* Function to check if customer exists, and if direct billing or not.
* and update intrim table
*********************************************************************/
Procedure Check_If_Direct (p_process_id IN NUMBER) IS

ln_site_cnt        NUMBER :=0;
ln_cust_account_id NUMBER;
lv_flag_value      VARCHAR2(2);
TYPE rec_type is RECORD  (flag VARCHAR2(10),
                            AOPS_ACCOUNT VARCHAR2(100));
TYPE tab_type IS TABLE OF rec_type;
lt_tab_type tab_type:=tab_type();
                            

    cursor c_cust_data IS
       SELECT DECODE(count(0),0,'I',1,'Y','N'),xx.column2
       FROM hz_cust_accounts hca,
             hz_parties hp,
             hz_party_sites hps,
             hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all hcsu,
             xx_ar_ss_cmn_tbl   xx
      WHERE hca.party_id = hp.party_id
        AND hps.party_id = hp.party_id
        AND hps.party_site_id = hcas.party_site_id
        and hca.cust_account_id = hcas.cust_account_id
        AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND hp.status = 'A'
        AND hca.status = 'A'
        AND hps.status = 'A'
        AND hcas.status = 'A'
        AND hcsu.status = 'A'
        AND hcsu.site_use_code = 'BILL_TO'
        AND SUBSTR(hca.orig_system_reference,1,8) = xx.column2
        AND xx.process_id = p_process_id
        GROUP BY xx.process_id,xx.column2;

BEGIN
   logs('Check_If_Direct(+)');
   OPEN c_cust_data;
   FETCH c_cust_data BULK COLLECT INTO lt_tab_type;
   
   FORALL i in lt_tab_type.FIRST ..lt_tab_type.LAST
     UPDATE xx_ar_ss_cmn_tbl SET direct_cust_flag = lt_tab_type(i).flag WHERE process_id = p_process_id AND column2 = lt_tab_type(i).AOPS_ACCOUNT;
   logs('Check_If_Direct(-)');
EXCEPTION 
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Check_If_Direct '||SQLERRM);
END Check_If_Direct;

/*********************************************************************
* procedure to insert data into intrim table
*********************************************************************/
Procedure insert_data(p_directory    IN VARCHAR2,
                      p_file_name    IN VARCHAR2,
                      p_process_id   IN NUMBER,
                      p_delimeter    IN VARCHAR2,
                      x_error_status OUT VARCHAR2,
                      x_error_msg    OUT VARCHAR2) IS
                      
lf_file UTL_FILE.FILE_TYPE;
lv_line_data  VARCHAR2(4000);
lv_col_value VARCHAR2(200);
ln_rows NUMBER :=0;
lv_insert_str VARCHAR2(2000) := 'INSERT INTO xx_ar_ss_cmn_tbl(process_id';
lv_select_str VARCHAR2(2000) := '('||p_process_id;
lv_query      VARCHAR2(4000);
lv_status     VARCHAR2(1) := 'S';
l_module_name VARCHAR2(2000) := 'INSERT_DATA';
le_end_line   EXCEPTION;
begin
  logs('  insert_data(+)');
  lf_file := utl_file.fopen(p_directory,p_file_name,'r');
  logs('  p_directory '||p_directory);
  logs('  p_file_name '||p_file_name);
  logs('  p_delimeter '||p_delimeter);
  LOOP
    logs('  Looping through file');
     BEGIN
       utl_file.get_line(lf_file,lv_line_data);
       ln_rows := ln_rows+1;
       IF ln_rows = 1 THEN
         Continue;
       END IF;
       lv_insert_str :='INSERT INTO xx_ar_ss_cmn_tbl(process_id';
       lv_select_str := '('||p_process_id;
       IF lv_line_data like 'Trailer%' THEN
          raise le_end_line;
       END IF;
       logs('Line Data '||lv_line_data);
       logs('Looping with Data '||regexp_count(lv_line_data,p_delimeter));
       For i in 0..regexp_count(lv_line_data,p_delimeter)-1 LOOP
           IF i=0 THEN
              lv_col_value := TRIM(SUBSTR(lv_line_data,1,INSTR(lv_line_data,p_delimeter,1,i+1)-1));
            ELSE
               lv_col_value := TRIM(SUBSTR(lv_line_data,INSTR(lv_line_data,p_delimeter,1,i)+length(p_delimeter),INSTR(lv_line_data,p_delimeter,1,i+1)-INSTR(lv_line_data,p_delimeter,1,i)-length(p_delimeter)));
            END IF;
            lv_insert_str := lv_insert_str||',column'||(i+1);
            lv_select_str := lv_select_str||','''||lv_col_value||'''';
       END LOOP;
       lv_query := lv_insert_str||') VALUES '||lv_select_str||')';
       logs('  p_file_name '||p_file_name);
       logs('  lv_query '||lv_query);
       execute immediate lv_query;
       logs('  lv_query executed'||SQLERRM);
    EXCEPTION 
      WHEN le_end_line THEN
        logs('  end found in file');
        utl_file.fclose(lf_file);
        EXIT;
      WHEN NO_DATA_FOUND THEN
        logs('  No data found in file');
        utl_file.fclose(lf_file);
        EXIT;
    END;
    logs('  Loop end');
  END LOOP;
  x_error_status :=lv_status;
  logs('  insert_data(+)');
EXCEPTION WHEN OTHERS THEN
  logs('  Error in insert_data '||SQLERRM,true);
  utl_file.fclose(lf_file);
  x_error_status  :='E';
  x_error_msg  :='Error in insert_data '||SQLERRM;
END;

/*********************************************************************
* Common procedure to call EAI webservice
*********************************************************************/
procedure xx_eai_call (p_payload      IN  VARCHAR2,
                       p_response     OUT VARCHAR2,
                       x_error_status OUT VARCHAR2,
                       x_error_msg    OUT VARCHAR2) IS

  l_module_name        VARCHAR2(30):= 'XX_EAI_CALL';
  lv_status            VARCHAR2(1) := 'S';
  --Translation Data
  lv_url               VARCHAR2(500);
  lv_user              VARCHAR2(50);
  lv_pass              VARCHAR2(50);
  lv_wallet_loc        VARCHAR2(100);
  lv_wallet_pass       VARCHAR2(50);
  ln_null_value        VARCHAR2(1);
  --http variables
  l_request            UTL_HTTP.req;
  l_response           UTL_HTTP.resp;
  lc_buffer            VARCHAR2(2000);
  lclob_buffer         CLOB;
  
BEGIN
  logs('   Start XX_EAI_CALL (+)');
  GET_TRANSLATION('XX_AR_SELF_SERVICE','AUTH_SERVICE',lv_url,lv_user,lv_pass);
  logs('   Translation values ');
  logs('   URL :'||lv_url);
  logs('   User :'||lv_user);
  GET_TRANSLATION('XX_AR_SELF_SERVICE','WALLET_LOCATION',lv_wallet_loc,lv_wallet_pass,ln_null_value);
  logs('   lv_wallet_loc :'||lv_wallet_loc);
  logs('   lv_wallet_pass :'||lv_wallet_pass);
  IF lv_wallet_loc IS NOT NULL THEN
    UTL_HTTP.SET_WALLET(lv_wallet_loc, lv_wallet_pass);
  END IF;
  l_request := UTL_HTTP.begin_request(lv_url, 'POST', ' HTTP/1.1');
  UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
  UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
  UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(p_payload));
  UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lv_user|| ':' ||lv_pass))));
  UTL_HTTP.write_text(l_request, p_payload);
  l_response := UTL_HTTP.get_response(l_request);
  COMMIT;
  BEGIN
    lclob_buffer := EMPTY_CLOB;
    LOOP
      UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
      lclob_buffer := lclob_buffer || lc_buffer;
    END LOOP;
    UTL_HTTP.end_response(l_response);
  EXCEPTION
  WHEN UTL_HTTP.end_of_body THEN
    UTL_HTTP.end_response(l_response);
  END;
  
  p_response := lclob_buffer;
  x_error_status := lv_status;
  logs('   End XX_EAI_CALL (-)');
EXCEPTION WHEN OTHERS THEN
  logs('   Error in XX_EAI_CALL '||SQLERRM);
  x_error_status  :='E';
  x_error_msg  :='Error in XX_EAI_CALL '||SQLERRM;
  logs('   ERR'||x_error_msg);
END xx_eai_call;

/*********************************************************************
* Update status of transaction
*********************************************************************/
procedure update_record_status(p_response IN VARCHAR2,p_rec_id NUMBER,p_type IN VARCHAR2) IS
lv_status    VARCHAR2(10);
lv_upd_query VARCHAR2(2000);
l_module_name VARCHAR2(100) := 'UPDATE_RECORD_STATUS';
BEGIN
  BEGIN
    SELECT DECODE(upper(MESSAGE),'SUCCESS','S','ERROR','E',MESSAGE)
      INTO lv_status
      FROM json_table(p_response ,'$' COLUMNS ( MESSAGE VARCHAR2(2000 CHAR) PATH '$.customerInfoResponse.status'));
  EXCEPTION WHEN OTHERS THEN
    lv_status := 'E';
  END;  
--  logs(l_module_name,'RESPONSE','INFO','p_rec_id '||p_rec_id);
--  logs(l_module_name,'RESPONSE','INFO','lv_status '||lv_status);
  IF p_type = 'ADDRESS' THEN
    lv_upd_query := 'UPDATE xx_ar_self_serv_bad_addr SET status = '''||lv_status ||''' WHERE record_id = '||p_rec_id;
    logs('   lv_upd_query '||lv_upd_query);
    execute immediate lv_upd_query;
    commit;
   ELSIF p_type = 'EMAIL' THEN
    lv_upd_query := 'UPDATE xx_ar_self_serv_bad_email SET status = '''||lv_status ||''' WHERE record_id = '||p_rec_id;
    logs('   lv_upd_query '||lv_upd_query);
    execute immediate lv_upd_query;
    commit;
   ELSIF p_type = 'CONTACT' THEN
    lv_upd_query := 'UPDATE xx_ar_self_serv_bad_contact SET status = '''||lv_status ||''' WHERE record_id = '||p_rec_id;
    logs('   lv_upd_query '||lv_upd_query);
    execute immediate lv_upd_query;
    commit;
  END IF;
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in update_record_status '||SQLERRM);
END update_record_status;

/*********************************************************************
* Process the base data as per type
*********************************************************************/
Procedure Process_data (p_type       IN VARCHAR2,
                        p_process_id IN NUMBER,
                        x_error_status OUT VARCHAR2,
                        x_error_msg    OUT VARCHAR2
                        ) IS
  l_module_name   VARCHAR2(200):= 'PROCESS_DATA';
  lv_cursor_query VARCHAR2(2000);
  lv_payload      VARCHAR2(2000);
  CURSOR c_payloads IS
    SELECT * 
      FROM xx_web_service_calls
     WHERE process_id = p_process_id;
  
  x_response      VARCHAR2(2000);
  x_status_code   VARCHAR2(1);
  x_message       VARCHAR2(2000);
BEGIN
    logs('  Start Process_data (+)');
    IF p_type = 'ADDRESS' THEN
        logs('  Address Start');
        FOR rec_address IN (select * from xx_ar_self_serv_bad_addr where NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' AND process_id = p_process_id)
        LOOP
          lv_payload := '{
                          "customerInfoRequest": {
                              "contactType": "ADDRESS",
                              "accountNumber": "'||rec_address.aops_account||'",
                              "ebsAccountNumber": "'||rec_address.account_number||'",
                              "address": {
                                  "addressReference": "'||rec_address.address_reference||'",
                                  "address1": "'||rec_address.address1||'",
                                  "address2": "'||rec_address.address2||'",
                                  "city": "'||rec_address.city||'",
                                  "countrycd": "'||rec_address.country||'",
                                  "zip": "'||rec_address.zip||'",
                                  "state": "'||rec_address.state||'"
                              },
                              "reason": "Bad Address",
                              "directFlag": ""
                          }
                      }';
          INSERT INTO xx_web_service_calls VALUES (rec_address.record_id,p_process_id,lv_payload,null,p_type);
          logs('  Payload inserted for record '||rec_address.record_id);
        END LOOP;
    ELSIF p_type = 'EMAIL' THEN
        logs('  Email Start');
        FOR rec_email IN (select * from xx_ar_self_serv_bad_email where NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' AND process_id = p_process_id)
        LOOP
          lv_payload := '{
           "customerInfoRequest": {
              "contactType": "EMAIL",
              "accountNumber": "'||rec_email.aops_account||'",
              "ebsAccountNumber": "'||rec_email.account_number||'",
              "contact": {
                 "emailAddress": "'||rec_email.EMAIL_ADDRESS||'",
                          },
                          "reason": "Bad email",
                          "directFlag": ""
                      }
                  }';
          INSERT INTO xx_web_service_calls VALUES (rec_email.record_id,p_process_id,lv_payload,null,p_type);
          logs('  Payload inserted for record '||rec_email.record_id);
        END LOOP;
    ELSIF p_type = 'CONTACT' THEN
        logs('  contact Start');
        FOR rec_cont IN (select * from xx_ar_self_serv_bad_contact where NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' AND process_id = p_process_id)
        LOOP
          lv_payload := '{
           "customerInfoRequest": {
              "contactType": "CONTACT",
              "accountNumber": "'||rec_cont.aops_account||'",
              "ebsAccountNumber": "'||rec_cont.account_number||'",
              "contact": {
                 "emailAddress": "'||rec_cont.EMAIL_ADDRESS||'",
                 "phone": "'||rec_cont.phone_number||'",
                 "fax": "'||rec_cont.fax_number||'"
                          },
                          "reason": "Bad contact",
                          "directFlag": ""
                      }
                  }';
          INSERT INTO xx_web_service_calls VALUES (rec_cont.record_id,p_process_id,lv_payload,null,p_type);
          logs('  Payload inserted for record '||rec_cont.record_id);
        END LOOP;
    END IF;
      
      
      
    FOR rec_payloads in c_payloads LOOP  
      logs('  Calling XX_EAI_CALL');
      xx_eai_call(rec_payloads.PAYLOAD,
                  x_response,
                  x_status_code,
                  x_message);

      update xx_web_service_calls
      SET RESPONSE = x_response
      WHERE record_id = rec_payloads.record_id;
      -- update staging table with status
      update_record_status(x_response,rec_payloads.record_id,p_type);
    END LOOP;
    logs('   End Process_data (-)');
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in process_data '||SQLERRM);
  x_error_status  :=2;
  x_error_status  :='Error in process_data '||SQLERRM;
END;

/*********************************************************************
* Procedure to populate data from common table to staging tables
*********************************************************************/
PROCEDURE populate_staging_table(p_process_id IN  NUMBER 
                                ,p_type       IN  VARCHAR2
                                ,x_error      OUT VARCHAR2
                                ,x_err_code   OUT NUMBER) IS
BEGIN
    logs('  Start populate_staging_table (+)');
    IF p_type = 'ADDRESS' THEN
        logs('  Inserting for address');
        INSERT INTO xx_ar_self_serv_bad_addr(
                        CUSTOMER_NAME,
                        AOPS_ACCOUNT,
                        account_number,
                        invoice_date,
                        ADDRESS1,
                        ADDRESS2,
                        CITY,
                        STATE,
                        ZIP,
                        CREATION_DATE,
                        REQUEST_ID,
                        DIRECT_BILL_FLAG,
                        record_id,
                        process_id
                        ) 
                      (SELECT column1,
                              column2,
                              get_account_number(column2),
                              column3,
                              column4,
                              column5,
                              column6,
                              column7,
                              column8,
                              sysdate,
                              g_conc_req_id,
                              direct_cust_flag,
                              xx_ar_ss_bad_addr_s.nextval,
                              p_process_id
                         FROM xx_ar_ss_cmn_tbl 
                        WHERE process_id = p_process_id);
                        
        get_address_reference(p_process_id);
                        
    ELSIF p_type = 'EMAIL' THEN
        logs('  Inserting for email');
        INSERT INTO xx_ar_self_serv_bad_email(
                        CUSTOMER_NAME,
                        AOPS_ACCOUNT,
                        account_number,
                        invoice_date,
                        EMAIL_ADDRESS,
                        CREATION_DATE,
                        REQUEST_ID,
                        DIRECT_BILL_FLAG,
                        record_id,
                        process_id
                        ) 
                      (SELECT column1,
                              column2,
                              get_account_number(column2),
                              column3,
                              column4,
                              sysdate,
                              g_conc_req_id,
                              direct_cust_flag,
                              xx_ar_ss_bad_email_s.nextval,
                              p_process_id
                         FROM xx_ar_ss_cmn_tbl 
                        WHERE process_id = p_process_id);
    ELSIF p_type = 'CONTACT' THEN
        logs('  Inserting for contact');
        INSERT INTO xx_ar_self_serv_bad_contact(
                        CUSTOMER_NAME,
                        AOPS_ACCOUNT,
                        account_number,
                        last_name,
                        first_name,
                        phone_number,
                        fax_number,
                        EMAIL_ADDRESS,
                        CREATION_DATE,
                        REQUEST_ID,
                        DIRECT_BILL_FLAG,
                        record_id,
                        process_id
                        ) 
                      (SELECT null,
                              column2,
                              column1,
                              column3,
                              column4,
                              column5,
                              column6,
                              column7,
                              sysdate,
                              g_conc_req_id,
                              direct_cust_flag,
                              xx_ar_ss_bad_cont_s.nextval,
                              p_process_id
                         FROM xx_ar_ss_cmn_tbl 
                        WHERE process_id = p_process_id);
    
    END IF;
    logs('  Start populate_staging_table (-)');
EXCEPTION WHEN OTHERS THEN
   x_error := 'Error in populate_staging_table '||SQLERRM;
   x_err_code := 2;
END populate_staging_table;
                              
PROCEDURE purge_file_data(p_file_id NUMBER) IS

BEGIN

   INSERT INTO xx_ar_ss_file_names_hist SELECT * FROM xx_ar_ss_file_names WHERE file_id = p_file_id;
   
   execute IMMEDIATE 'DELETE FROM xx_ar_ss_file_names WHERE file_id = :1' USING p_file_id;
   
EXCEPTION WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in purge_file_data '||SQLERRM);
END;


/*********************************************************************
* Procedure to process bad address data
*********************************************************************/
procedure process_bad_address(p_err_buf OUT VARCHAR2,
                          p_ret_code OUT VARCHAR2) IS
  ln_request_id   NUMBER := fnd_global.conc_request_id;
  l_module_name   VARCHAR2(2000) := g_package_name||'.'||'XX_BAD_ADDR_UPD';
  lv_event        VARCHAR2(500);
  ln_process_id   NUMBER;
  ln_req_id       NUMBER;
  lc_wait_flag    BOOLEAN;
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_dev_phase    VARCHAR2(100);
  lc_dev_status   VARCHAR2(100);
  lc_message      VARCHAR2(100);
  lv_file_name    VARCHAR2(100);
  lv_directory    VARCHAR2(100);
  lv_err_message  VARCHAR2(2000);
  lv_err_code     VARCHAR2(20);
  lv_delimeter    VARCHAR2(20);
  lv_p_err        VARCHAR2(2000);
  lv_p_code       NUMBER;
  lv_process_type VARCHAR2(20) := 'ADDRESS';
  lv_send_to      VARCHAR2(50);
  lv_source_folder  VARCHAR2(100);
  lv_destination_folder  VARCHAR2(100);
  lc_req_data     VARCHAR2(500);
  ln_rep_req_id   NUMBER;
  ln_arc_req_id   NUMBER;
  CURSOR c_process_files(p_process_id NUMBER) IS
     SELECT file_name,file_id
       FROM xx_ar_ss_file_names
      WHERE process_id = p_process_id;

BEGIN
   logs('Start Bad address process (+)',True);
   set_global_variables;
-- Fetching process id
    SELECT xx_ar_ss_process_s.nextval
      INTO ln_process_id
      FROM dual;
    logs('process started for id '||ln_process_id,True);
    --Calling insert file names program
    ln_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARBSDLOADFILES' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>ln_process_id);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id); 
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => ln_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logs('Program completed successful for the Request Id: ' || ln_req_id );
      ELSE
        logs('Program did not complete normally. ');
      END IF;
    END IF;
    GET_TRANSLATION('XX_AR_SELF_SERVICE',lv_process_type,lv_directory,lv_file_name,lv_delimeter);
    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_err_code,
                lv_err_message);
        --Checking if direct customer.
        logs('Checking for direct customer',True);
        Check_If_Direct(ln_process_id);
        IF lv_err_code = 'S' THEN
            -- Insert_data into staging table
            logs('calling populate_staging_table',True);
            populate_staging_table(ln_process_id,lv_process_type,lv_p_err,lv_p_code);
            logs('cleaning common table',True);
            DELETE FROM xx_ar_ss_cmn_tbl WHERE process_id = ln_process_id;   
            commit;
            IF NVL(lv_p_code,0) = 0 THEN
                --
                --Process data as per the reqest type
                --
                logs('calling Process_data',True);
                Process_data(lv_process_type,ln_process_id,lv_err_code,lv_err_message);
                --
                -- Purging the old data
                --
                write_output(lv_process_type,ln_process_id);
                logs('Checking if data needs to be purged',True);
            ELSE
                logs('Error in populate_staging_table '||lv_p_err,True);
                p_ret_code  :=1;
                p_err_buf  :=lv_p_err;
            END IF;
        ELSE
            logs('Error in insert data '||lv_err_message,True);
            p_ret_code  :=1;
            p_err_buf  :='Error in insert data '||lv_err_message;
        END IF;
        logs('Move the files to history');
        purge_file_data(rec_process_files.file_id);
        
    END LOOP;
    BEGIN
        SELECT TARGET_VALUE4,DB.DIRECTORY_PATH,DB1.DIRECTORY_PATH
          INTO lv_send_to,lv_source_folder,lv_destination_folder
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV,
               DBA_DIRECTORIES DB,
               DBA_DIRECTORIES DB1
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
           AND DB.directory_name = XFTV.TARGET_VALUE1
           AND DB1.directory_name = XFTV.TARGET_VALUE5;
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting email receiptient';
       p_ret_code := 2;
       lv_send_to := NULL;
    END;
    IF lv_send_to IS NOT NULL THEN
       ln_rep_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARSELFSERVICE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>sysdate,argument3=>lv_send_to,argument4=>g_SMTP_SERVER,argument5=>g_MAIL_FROM);
    END IF;
    
    ln_arc_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARMOVEFILE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_source_folder, argument2=>ln_process_id,argument3=>lv_destination_folder);
    
    logs('Start Bad address process (-)',True);
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in process_bad_address '||SQLERRM);
  p_ret_code  :=2;
  p_err_buf  :='Error in process_bad_address '||SQLERRM;
END process_bad_address;


/*********************************************************************
* Procedure to process bad Email data
*********************************************************************/
procedure process_bad_email(p_err_buf OUT VARCHAR2,
                          p_ret_code OUT VARCHAR2) IS
  l_module_name   VARCHAR2(2000) := g_package_name||'.'||'XX_BAD_ADDR_UPD';
  lv_event        VARCHAR2(500);
  ln_process_id   NUMBER;
  ln_req_id       NUMBER;
  lc_wait_flag    BOOLEAN;
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_dev_phase    VARCHAR2(100);
  lc_dev_status   VARCHAR2(100);
  lc_message      VARCHAR2(100);
  lv_file_name    VARCHAR2(100);
  lv_directory    VARCHAR2(100);
  lv_err_message  VARCHAR2(2000);
  lv_err_code     VARCHAR2(20);
  lv_delimeter    VARCHAR2(20);
  lv_p_err        VARCHAR2(2000);
  lv_p_code       NUMBER;
  lv_process_type VARCHAR2(20) := 'EMAIL';
  lv_send_to      VARCHAR2(50);
  lv_source_folder  VARCHAR2(100);
  lv_destination_folder  VARCHAR2(100);
  ln_rep_req_id   NUMBER;
  ln_arc_req_id   NUMBER;
  CURSOR c_process_files(p_process_id NUMBER) IS
     SELECT file_name,file_id
       FROM xx_ar_ss_file_names
      WHERE process_id = p_process_id;

BEGIN
   logs('Start Bad email process (+)',True);
   set_global_variables;
-- Fetching process id
    SELECT xx_ar_ss_process_s.nextval
      INTO ln_process_id
      FROM dual;
    logs('process started for id '||ln_process_id,True);
    --Calling insert file names program
    ln_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARBSDLOADFILES' , description => NULL , start_time => sysdate , sub_request => true , argument1=>lv_process_type, argument2=>ln_process_id);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id); 
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => ln_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logs('Program completed successful for the Request Id: ' || ln_req_id );
      ELSE
        logs('Program did not complete normally. ');
      END IF;
    END IF;
    GET_TRANSLATION('XX_AR_SELF_SERVICE',lv_process_type,lv_directory,lv_file_name,lv_delimeter);
    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_err_code,
                lv_err_message);
        --Checking if direct customer.
        logs('Checking for direct customer',True);
        Check_If_Direct(ln_process_id);
        IF lv_err_code = 'S' THEN
            -- Insert_data into staging table
            logs('calling populate_staging_table',True);
            populate_staging_table(ln_process_id,lv_process_type,lv_p_err,lv_p_code);
            logs('cleaning common table',True);
            DELETE FROM xx_ar_ss_cmn_tbl WHERE process_id = ln_process_id;   
            commit;
            IF NVL(lv_p_code,0) = 0 THEN
                --
                --Process data as per the reqest type
                --
                logs('calling Process_data',True);
                Process_data(lv_process_type,ln_process_id,lv_err_code,lv_err_message);
                --
                -- Purging the old data
                --
                write_output(lv_process_type,ln_process_id);
                logs('Checking if data needs to be purged',True);
            ELSE
                logs('Error in populate_staging_table '||lv_p_err,True);
                p_ret_code  :=1;
                p_err_buf  :=lv_p_err;
            END IF;
        ELSE
            logs('Error in insert data '||lv_err_message,True);
            p_ret_code  :=1;
            p_err_buf  :='Error in insert data '||lv_err_message;
        END IF;
        logs('Move the files to history');
        purge_file_data(rec_process_files.file_id);
    END LOOP;
    BEGIN
        SELECT TARGET_VALUE4,DB.DIRECTORY_PATH,DB1.DIRECTORY_PATH
          INTO lv_send_to,lv_source_folder,lv_destination_folder
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV,
               DBA_DIRECTORIES DB,
               DBA_DIRECTORIES DB1
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
           AND DB.directory_name = XFTV.TARGET_VALUE1
           AND DB1.directory_name = XFTV.TARGET_VALUE5;
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting email receiptient';
       p_ret_code := 2;
       lv_send_to := NULL;
    END;
    IF lv_send_to IS NOT NULL THEN
       ln_rep_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARSELFSERVICE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>sysdate,argument3=>lv_send_to,argument4=>g_SMTP_SERVER,argument5=>g_MAIL_FROM);
    END IF;
    
    ln_arc_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARMOVEFILE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_source_folder, argument2=>ln_process_id,argument3=>lv_destination_folder);
    logs('Start Bad email process (-)',True);
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in process_bad_email '||SQLERRM);
  p_ret_code  :=2;
  p_err_buf  :='Error in process_bad_email '||SQLERRM;
END process_bad_email;


/*********************************************************************
* Procedure to process bad contact data
*********************************************************************/
procedure process_bad_contact(p_err_buf OUT VARCHAR2,
                              p_ret_code OUT VARCHAR2) IS
  ln_request_id   NUMBER := fnd_global.conc_request_id;
  l_module_name   VARCHAR2(2000) := g_package_name||'.'||'XX_BAD_CONT_UPD';
  lv_event        VARCHAR2(500);
  ln_process_id   NUMBER;
  ln_req_id       NUMBER;
  lc_wait_flag    BOOLEAN;
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_dev_phase    VARCHAR2(100);
  lc_dev_status   VARCHAR2(100);
  lc_message      VARCHAR2(100);
  lv_file_name    VARCHAR2(100);
  lv_directory    VARCHAR2(100);
  lv_err_message  VARCHAR2(2000);
  lv_err_code     VARCHAR2(20);
  lv_delimeter    VARCHAR2(20);
  lv_p_err        VARCHAR2(2000);
  lv_p_code       NUMBER;
  lv_process_type VARCHAR2(20) := 'CONTACT';
  lv_send_to      VARCHAR2(50);
  lv_source_folder  VARCHAR2(100);
  lv_destination_folder  VARCHAR2(100);
  lc_req_data     VARCHAR2(500);
  ln_rep_req_id   NUMBER;
  ln_arc_req_id   NUMBER;
  CURSOR c_process_files(p_process_id NUMBER) IS
     SELECT file_name,file_id
       FROM xx_ar_ss_file_names
      WHERE process_id = p_process_id;

BEGIN
   set_global_variables;
   logs('Start Bad contact process (+)',True);
-- Fetching process id
    SELECT xx_ar_ss_process_s.nextval
      INTO ln_process_id
      FROM dual;
    logs('process started for id '||ln_process_id,True);
    --Calling insert file names program
    ln_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARBSDLOADFILES' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>ln_process_id);
    COMMIT;
    logs('Conc. Program submitted '||ln_req_id); 
    IF ln_req_id = 0 THEN
      logs('Conc. Program  failed to submit Program',True);
    ELSE
      logs('Waiting for concurrent request to complete');
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => ln_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logs('Program completed successful for the Request Id: ' || ln_req_id );
      ELSE
        logs('Program did not complete normally. ');
      END IF;
    END IF;
    GET_TRANSLATION('XX_AR_SELF_SERVICE',lv_process_type,lv_directory,lv_file_name,lv_delimeter);
    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_err_code,
                lv_err_message);
        --Checking if direct customer.
        logs('Checking for direct customer',True);
        Check_If_Direct(ln_process_id);
        IF lv_err_code = 'S' THEN
            -- Insert_data into staging table
            logs('calling populate_staging_table',True);
            populate_staging_table(ln_process_id,lv_process_type,lv_p_err,lv_p_code);
            logs('cleaning common table',True);
            DELETE FROM xx_ar_ss_cmn_tbl WHERE process_id = ln_process_id;   
            commit;
            IF NVL(lv_p_code,0) = 0 THEN
                --
                --Process data as per the reqest type
                --
                logs('calling Process_data',True);
                Process_data(lv_process_type,ln_process_id,lv_err_code,lv_err_message);
                --
                -- Purging the old data
                --
                write_output(lv_process_type,ln_process_id);
                logs('Checking if data needs to be purged',True);
            ELSE
                logs('Error in populate_staging_table '||lv_p_err,True);
                p_ret_code  :=1;
                p_err_buf  :=lv_p_err;
            END IF;
        ELSE
            logs('Error in insert data '||lv_err_message,True);
            p_ret_code  :=1;
            p_err_buf  :='Error in insert data '||lv_err_message;
        END IF;
        logs('Move the files to history');
        purge_file_data(rec_process_files.file_id);
        
    END LOOP;
    BEGIN
        SELECT TARGET_VALUE4,DB.DIRECTORY_PATH,DB1.DIRECTORY_PATH
          INTO lv_send_to,lv_source_folder,lv_destination_folder
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV,
               DBA_DIRECTORIES DB,
               DBA_DIRECTORIES DB1
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
           AND DB.directory_name = XFTV.TARGET_VALUE1
           AND DB1.directory_name = XFTV.TARGET_VALUE5;
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting email receiptient';
       p_ret_code := 2;
       lv_send_to := NULL;
    END;
    IF lv_send_to IS NOT NULL THEN
       ln_rep_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARSELFSERVICE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_process_type, argument2=>sysdate,argument3=>lv_send_to,argument4=>g_SMTP_SERVER,argument5=>g_MAIL_FROM);
    END IF;
    
    ln_arc_req_id:= fnd_request.submit_request ( application => 'XXFIN' , program => 'XXARMOVEFILE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lv_source_folder, argument2=>ln_process_id,argument3=>lv_destination_folder);
    
    logs('Start Bad contact process (-)',True);
EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in process_bad_contact '||SQLERRM);
  p_ret_code  :=2;
  p_err_buf  :='Error in process_bad_contact '||SQLERRM;
END process_bad_contact;

/*********************************************************************
* procedure to update email address, for external applications
*********************************************************************/
 PROCEDURE update_email_address(p_aops_number   IN  VARCHAR2
                               ,p_email_address IN  VARCHAR2
                               ,p_ret_status    OUT VARCHAR2
                               ,p_ret_msg       OUT VARCHAR2) IS
           
     l_contact_point_rec HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
     l_email_rec         HZ_CONTACT_POINT_V2PUB.email_rec_type;
     ln_contact_point_id  NUMBER;
     ln_object_version    NUMBER;
     ln_party_id          NUMBER;
     ln_account_id        NUMBER;
     lv_error_msg         VARCHAR2(2000);
     x_return_status      VARCHAR2(2000);
     x_msg_count          NUMBER;
     x_msg_data           VARCHAR2(2000);
     e_contact_error      EXCEPTION;
BEGIN
    --
    --Fetch required details for update
    --
    BEGIN
        SELECT cust_account_id 
          INTO ln_account_id 
          FROM hz_cust_accounts hca
         WHERE SUBSTR(hca.orig_system_reference,1,8) = p_aops_number;
        
        SELECT hp.party_id,contact_point_id,hcp.object_version_number
          INTO ln_party_id,ln_contact_point_id,ln_object_version
          FROM hz_cust_accounts hca,
               hz_parties hp,
               hz_contact_points hcp
         WHERE hp.party_id = hca.party_id
           AND hp.party_id = hcp.owner_table_id
           AND hcp.owner_table_name  = 'HZ_PARTIES'
           AND hcp.contact_point_type = 'EMAIL'
           AND hcp.status = 'A'
           AND hp.status = 'A'
           AND hca.status = 'A'
           AND hca.cust_account_id = ln_account_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
          lv_error_msg := 'Contact point details not found for '||p_aops_number;
          raise e_contact_error;
      WHEN TOO_MANY_ROWS THEN
          lv_error_msg := 'Multiple active emails for party for '||p_aops_number;
          raise e_contact_error;
      WHEN OTHERS THEN
          lv_error_msg := 'Error while fetching contact details '||SQLERRM;
          raise e_contact_error;
    END;
--    fnd_global.apps_initialize(0,52300,222);
    --
    -- Creating record types for API
    --
    l_contact_point_rec.owner_table_id     := ln_party_id;
    l_contact_point_rec.contact_point_id   := ln_contact_point_id;
    l_contact_point_rec.contact_point_type := 'EMAIL';
    l_contact_point_rec.owner_table_name   := 'HZ_PARTIES';
    l_email_rec.email_address              := p_email_address;
 --
 -- Calling update email API
 --
    HZ_CONTACT_POINT_V2PUB.update_email_contact_point
       (
        p_contact_point_rec      =>  l_contact_point_rec,  
        p_email_rec              =>  l_email_rec, 
        p_object_version_number  =>  ln_object_version,        
        x_return_status          =>  x_return_status,
        x_msg_count              =>  x_msg_count,
        x_msg_data               =>  x_msg_data
      );
    --
    -- validating API results
    --
    IF (x_return_status <> 'S') then
        IF x_msg_count > 1 THEN
            FOR i IN 1..x_msg_count LOOP
                lv_error_msg := SUBSTR(lv_error_msg||substr(FND_MSG_PUB.Get( p_encoded => FND_API.G_FALSE ),1,255),1,4000);
            END LOOP;
        END IF;
        raise e_contact_error;
    ELSE
        p_ret_msg := 'Contact updated for '||p_aops_number;
        p_ret_status :=x_return_status;
    END IF; 
EXCEPTION 
    WHEN e_contact_error THEN
        p_ret_status  :='E';
        p_ret_msg     := lv_error_msg;    
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in update_email_address '||SQLERRM);
        p_ret_status  :='E';
        p_ret_msg  :='Error in update_email_address '||SQLERRM;
END update_email_address;


/*********************************************************************
* After report trigger for self service
*********************************************************************/
FUNCTION afterreport RETURN BOOLEAN IS
   P_CONC_REQUEST_ID NUMBER;
   l_request_id NUMBER;
BEGIN

--   P_SMTP_SERVER:= FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
--   P_MAIL_FROM:='noreply@officedepot.com';
   Fnd_File.PUT_LINE (Fnd_File.LOG,'In parameter : P_SMTP_SERVER = '||P_SMTP_SERVER||chr(13)||'P_MAIL_FROM = '||P_MAIL_FROM||chr(13));

      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      Fnd_File.PUT_LINE (Fnd_File.LOG,'Submitting : XML Publisher Report Bursting Program');
      l_request_id := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                 'XDOBURSTREP',
                                 NULL,
                                 NULL,
                                 FALSE,
                                 'Y',
                                 P_CONC_REQUEST_ID,
                                 'Y');

   RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Unexpected error while submitting bursting program '||SQLERRM);
   RETURN FALSE;
END ;

END XX_AR_SELF_SERVICE;
/