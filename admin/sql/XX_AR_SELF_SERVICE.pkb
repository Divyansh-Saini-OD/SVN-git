create or replace package body XX_AR_SELF_SERVICE as

-- +================================================================================+
-- |                               Office Depot                                     |
-- +================================================================================+
-- | Name        :  XX_AR_SELF_SERVICE.pkb                                          |
-- |                                                                                |
-- | Subversion Info:                                                               |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- | Description :                                                                  |
-- |                                                                                |
-- | Table hanfler for xx_crm_sfdc_contacts.                                        |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author             Remarks                               |
-- |========  ===========  =================  ======================================|
-- |1.0       01-Oct-2020  Divyansh Saini     Initial version                       |
-- |1.1       26-Mar-2021  Divyansh Saini     Added logic for contact Tieback       |
-- +================================================================================+

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
Procedure purge_old_data(p_err_buf  OUT VARCHAR2,
                         p_ret_code OUT NUMBER  ,
                         p_type     IN  VARCHAR2) IS

n_days          NUMBER;
lv_null_value1  VARCHAR2(10);
lv_null_value2  VARCHAR2(10);
lv_del_str      VARCHAR2(500);
lv_del_str2     VARCHAR2(500);
lv_type         VARCHAR2(10);
ln_address_cnt  NUMBER;
ln_email_cnt    NUMBER;
ln_cont_cnt     NUMBER;
ln_file_cnt     NUMBER;
BEGIN
  set_global_variables;
  logs('Purge_old_data(+)',true);
  GET_TRANSLATION('XX_AR_SELF_SERVICE','N_PURGE_DAYS',n_days,lv_null_value1,lv_null_value2);
  logs('Number of days : '||n_days,true);
  lv_type := NVL(p_type,'ALL');
  logs('Type of data to delete : '||lv_type,true);
  --
  --Delete Address related data
  --
  IF lv_type IN ('ADDRESS','ALL') THEN
    lv_del_str2 := 'delete from xx_web_service_calls WHERE process_id IN (SELECT process_id FROM xx_ar_self_serv_bad_addr where creation_date < sysdate - :1)';
    lv_del_str := 'delete from xx_ar_self_serv_bad_addr where creation_date < sysdate - :1';
    logs('Deleting address data with sql : '||lv_del_str,true);
    logs('Deleting address data with sql : '||lv_del_str2,true);
    EXECUTE IMMEDIATE lv_del_str2 using n_days;
    EXECUTE IMMEDIATE lv_del_str using n_days;
    ln_address_cnt := SQL%ROWCOUNT;
  END IF;
  --
  --Delete email related data
  --
  IF lv_type IN ('EMAIL','ALL') THEN
    lv_del_str2 := 'delete from xx_web_service_calls WHERE process_id IN (SELECT process_id FROM xx_ar_self_serv_bad_email where creation_date < sysdate - :1)';
    lv_del_str := 'delete from xx_ar_self_serv_bad_email where creation_date < sysdate - :1';
    logs('Deleting email data with sql : '||lv_del_str,true);
    logs('Deleting email data with sql : '||lv_del_str2,true);
    EXECUTE IMMEDIATE lv_del_str2 using n_days;
    EXECUTE IMMEDIATE lv_del_str using n_days;
    ln_email_cnt := SQL%ROWCOUNT;
  END IF;
  --
  --Delete contact related data
  --
  IF lv_type IN ('CONTACT','ALL') THEN
    lv_del_str2 := 'delete from xx_web_service_calls WHERE process_id IN (SELECT process_id FROM xx_ar_self_serv_bad_contact where creation_date < sysdate - :1)';
    lv_del_str := 'delete from xx_ar_self_serv_bad_contact where creation_date < sysdate - :1';
    logs('Deleting contact data with sql : '||lv_del_str,true);
    logs('Deleting contact data with sql : '||lv_del_str2,true);
    EXECUTE IMMEDIATE lv_del_str2 using n_days;
    EXECUTE IMMEDIATE lv_del_str using n_days;
    ln_cont_cnt := SQL%ROWCOUNT;
  END IF;

  --
  --Delete file history
  --
  IF lv_type IN ('ALL') THEN
    lv_del_str := 'delete from xx_ar_ss_file_names_hist WHERE creation_date < sysdate - :1';
    logs('Deleting contact data with sql : '||lv_del_str,true);
    EXECUTE IMMEDIATE lv_del_str using n_days;
    ln_file_cnt := SQL%ROWCOUNT;
  END IF;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Stats ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'************************************************** ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of address records deleted '||ln_address_cnt);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of email records deleted '||ln_email_cnt);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of contact records deleted '||ln_cont_cnt);
  IF lv_type= 'ALL' THEN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of history table records deleted '||ln_file_cnt);
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'************************************************** ');
EXCEPTION WHEN OTHERS THEN
   p_err_buf :='Error in purge_old_data '||SQLERRM;
   p_ret_code := SQLCODE;
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
     WHERE SUBSTR(orig_system_reference,1,INSTR(orig_system_reference,'-')-1) = p_AOPS_account_number;
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
* Function to trim file values
*********************************************************************/
FUNCTION get_converted_text(p_value IN VARCHAR2)
  RETURN VARCHAR2 IS
  lv_value VARCHAR2(2000);
BEGIN
   /*Replace carriage return line break*/
   SELECT TRIM(REPLACE(REPLACE(REPLACE(p_value,CHR(10)),CHR(13)),CHR(9)))
     INTO lv_value
     FROM DUAL;

     SELECT REPLACE(lv_value,'|','')
       INTO lv_value
      FROM DUAl;
    /*Fix for colon*/
     SELECT REPLACE(lv_value,'''','''''')
       INTO lv_value
      FROM DUAl;
    /*Fix for ampersand*/
     SELECT REPLACE(lv_value,'&','''||'||'''&'''||'||''')
       INTO lv_value
      FROM DUAl;
   RETURN lv_value;
EXCEPTION
  WHEN OTHERS THEN
     RETURN p_value;
END;

/*********************************************************************
* PROCEDURE to get customer name
*********************************************************************/
PROCEDURE add_account_name(p_process_id IN NUMBER) IS
TYPE con_name IS RECORD (account_name VARCHAR2(240),
                         record_id NUMBER);

TYPE con_tab is TABLE of con_name;
contact_t con_tab := con_tab();

   CURSOR c_em_rec IS
     SELECT hz.account_name,hz.account_number,email.record_id
       FROM xx_ar_self_serv_bad_email email,hz_cust_accounts hz
      WHERE process_id = p_process_id
        AND SUBSTR(orig_system_reference,1,INSTR(orig_system_reference,'-')-1) = email.aops_account
        AND hz.status = 'A';

   CURSOR c_con_rec IS
     SELECT hz.account_name,con.record_id
       FROM xx_ar_self_serv_bad_contact con,hz_cust_accounts hz
      WHERE process_id = p_process_id
        AND hz.ACCOUNT_NUMBER = con.ACCOUNT_NUMBER
        AND hz.status = 'A';
BEGIN
  FOR rec IN c_em_rec LOOP
    UPDATE xx_ar_self_serv_bad_email
       SET customer_name = rec.account_name,
	       account_number = rec.account_number
     WHERE RECORD_ID = rec.RECORD_ID;
  END LOOP;

  OPEN c_con_rec;
  FETCH c_con_rec BULK COLLECT INTO contact_t;
  CLOSE c_con_rec;
  FORALL i in contact_t.FIRST..contact_t.LAST
    UPDATE xx_ar_self_serv_bad_contact
       SET customer_name = contact_t(i).account_name
     WHERE RECORD_ID = contact_t(i).RECORD_ID;

EXCEPTION
    WHEN OTHERS THEN
       null;
END;

/*********************************************************************
* Function to check the length of source AOPS Number
*********************************************************************/
FUNCTION check_aops_number(p_value IN VARCHAR2)
  RETURN VARCHAR2 IS
BEGIN
   IF length(p_value) >8 THEN
      RETURN p_value;
   ELSE
      RETURN lpad(p_value,8,'0');
   END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN p_value;
END check_aops_number;

/*********************************************************************
* Procedure to get Address reference
*********************************************************************/
Procedure get_address_reference(p_process_id IN NUMBER)  IS
lv_account_number VARCHAR2(100);
TYPE rec_type is RECORD  (address_reference VARCHAR2(1000),
                            record_id NUMBER,
                            address1 VARCHAR2(240),
                            address2 VARCHAR2(240),
                            city VARCHAR2(60),
                            state VARCHAR2(60),
                            country VARCHAR2(60),
                            zip VARCHAR2(60));
TYPE tab_type IS TABLE OF rec_type;
lt_tab_type tab_type:=tab_type();
  CURSOR c_reference IS
     SELECT hl.ORIG_SYSTEM_REFERENCE Add_reference,xx.record_id,hl.address1,hl.address2,hl.city,hl.state,hl.country,hl.postal_code
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
        AND hcsu.primary_flag = 'Y'
        AND hcsu.site_use_code = 'BILL_TO'
        AND hca.ACCOUNT_NUMBER = xx.ACCOUNT_NUMBER
        AND xx.process_id = p_process_id
        AND xx.DIRECT_BILL_FLAG = 'Y';

BEGIN

   OPEN c_reference;
   FETCH c_reference BULK COLLECT INTO lt_tab_type;
   CLOSE c_reference;
   FORALL i in lt_tab_type.FIRST ..lt_tab_type.LAST
     UPDATE xx_ar_self_serv_bad_addr
     SET address_reference = lt_tab_type(i).address_reference,
         ebs_address1      =lt_tab_type(i).address1,
         ebs_address2      =lt_tab_type(i).address2,
         ebs_city          =lt_tab_type(i).city,
         ebs_state         =lt_tab_type(i).state,
         ebs_country       =lt_tab_type(i).country,
         ebs_zip           =lt_tab_type(i).zip
     WHERE process_id = p_process_id AND record_id  = lt_tab_type(i).record_id;

EXCEPTION
    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in get_address_reference '||SQLERRM);
END;

/*********************************************************************
* Function to check if customer exists, and if direct billing or not.
* and update intrim table
*********************************************************************/
Procedure Check_If_Direct (p_process_id IN NUMBER) IS

ln_site_cnt        NUMBER :=0;
ln_cust_account_id NUMBER;
lv_flag_value      VARCHAR2(2);
TYPE rec_type is RECORD  (cust_account_id NUMBER,
                            AOPS_ACCOUNT VARCHAR2(100),
							account_number VARCHAR2(100));
TYPE tab_type IS TABLE OF rec_type;
lt_tab_type tab_type:=tab_type();


    cursor c_cust_data IS
       SELECT hca.cust_account_id,xx.column2,hca.account_number
         FROM hz_cust_accounts hca,
              xx_ar_ss_cmn_tbl xx
        WHERE SUBSTR(orig_system_reference,1,INSTR(orig_system_reference,'-')-1) = check_aops_number(xx.column2)
          AND hca.status = 'A'
          AND xx.process_id = p_process_id;

BEGIN
   logs('Check_If_Direct(+)');
   OPEN c_cust_data;
   FETCH c_cust_data BULK COLLECT INTO lt_tab_type;

   FOR i in lt_tab_type.FIRST ..lt_tab_type.LAST LOOP

     BEGIN
        SELECT 'Y'
          INTO lv_flag_value
          FROM xx_cdh_cust_acct_ext_b ext
         WHERE ext.C_EXT_ATTR7 = 'Y' --Direct Document
           AND ext.C_EXT_ATTR2 = 'Y' --payDoc
           AND ext.d_ext_attr2 is null  -- Effective end date
           AND ext.CUST_ACCOUNT_ID =lt_tab_type(i).cust_account_id
           and attr_group_id=(SELECT attr_group_id FROM ego_fnd_dsc_flx_ctx_ext WHERE descriptive_flexfield_name = 'XX_CDH_CUST_ACCOUNT' AND descriptive_flex_context_code = 'BILLDOCS')
           AND NOT EXISTS (
                     SELECT 1
                       FROM hz_cust_acct_sites_all asites,
                            hz_cust_site_uses_all uses,
                            hz_cust_site_uses_all uses1
                      WHERE asites.cust_acct_site_id =  uses.cust_acct_site_id
                        and uses.bill_to_site_use_id is not null
                        and uses.bill_to_site_use_id = uses1.site_use_id
                        and uses.site_use_code = 'SHIP_TO'
                        and uses1.site_use_code = 'BILL_TO'
                        and uses1.PRIMARY_FLAG <> 'Y'
                        and uses.status='A'
                        and uses1.status='A'
                        and asites.cust_account_id=ext.cust_account_id
                        and NOT ( uses.cust_acct_site_id = uses1.cust_acct_site_id)
           )
           AND Rownum = 1;

     EXCEPTION WHEN OTHERS THEN
        lv_flag_value := 'N';
     END;

     UPDATE xx_ar_ss_cmn_tbl SET direct_cust_flag = lv_flag_value,column14=lt_tab_type(i).account_number WHERE process_id = p_process_id AND column2 = lt_tab_type(i).AOPS_ACCOUNT;

   END LOOP;

   logs('Check_If_Direct(-)');
EXCEPTION
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Check_If_Direct '||SQLERRM);
END Check_If_Direct;

/*********************************************************************
* procedure to insert data into intrim table
*********************************************************************/
Procedure insert_data(p_directory    IN  VARCHAR2,
                      p_file_name    IN  VARCHAR2,
                      p_process_id   IN  NUMBER,
                      p_delimeter    IN  VARCHAR2,
                      p_enclosed_by  IN  VARCHAR2 DEFAULT NULL,
                      p_skip_rows    IN  NUMBER DEFAULT 2,
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
       lv_line_data := convert(lv_line_data,'utf8','us7ascii');
       ln_rows := ln_rows+1;
       IF ln_rows <=p_skip_rows THEN
         Continue;
       END IF;
       lv_insert_str :='INSERT INTO xx_ar_ss_cmn_tbl(process_id';
       lv_select_str := '('||p_process_id;
       IF lv_line_data like 'Trailer%' THEN
          raise le_end_line;
       END IF;
       logs('Line Data '||lv_line_data);
       logs('Looping with Data '||regexp_count(lv_line_data,p_delimeter));
       For i in 0..regexp_count(lv_line_data,p_delimeter)+1 LOOP
             IF lv_line_data IS NULL THEN
             exit;
             end if;
           IF lv_line_data like p_enclosed_by||'%' and regexp_count(lv_line_data,p_enclosed_by) !=0 THEN
              lv_col_value := TRIM(SUBSTR(lv_line_data,2,INSTR(lv_line_data,p_enclosed_by||p_delimeter,1,1)-2));
              lv_line_data := SUBSTR(lv_line_data,INSTR(lv_line_data,p_enclosed_by||p_delimeter,1,1)+2);
           ELSIF regexp_count(lv_line_data,p_delimeter) != 0 THEN
              lv_col_value := TRIM(SUBSTR(lv_line_data,1,INSTR(lv_line_data,p_delimeter,1,1)-1));
              lv_line_data := SUBSTR(lv_line_data,INSTR(lv_line_data,p_delimeter,1,1)+1);
           ELSIF regexp_count(lv_line_data,p_delimeter) = 0 THEN
              lv_col_value:= lv_line_data;
              lv_line_data := NULL;
           END IF;
            lv_col_value:=get_converted_text(lv_col_value);
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
      WHEN OTHERS THEN
       logs('Error while insert into common table' ||SQLERRM);
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
  l_request := UTL_HTTP.begin_request(lv_url, 'POST', 'HTTP/1.1');
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
procedure update_record_status(p_response IN VARCHAR2,
                               p_rec_id   IN NUMBER,
                               p_type     IN VARCHAR2,
                               p_message  IN VARCHAR2 DEFAULT NULL )IS
lv_status    VARCHAR2(10);
lv_upd_query VARCHAR2(2000);
l_module_name VARCHAR2(100) := 'UPDATE_RECORD_STATUS';
BEGIN
  IF p_message IS NULL THEN
      BEGIN
        SELECT DECODE(upper(MESSAGE),'SUCCESS','S','ERROR','E',MESSAGE)
          INTO lv_status
          FROM json_table(p_response ,'$' COLUMNS ( MESSAGE VARCHAR2(2000 CHAR) PATH '$.customerInfoResponse.status'));
      EXCEPTION WHEN OTHERS THEN
        lv_status := 'E';
      END;
   ELSE
      lv_status := p_message;
   END IF;
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
        FOR rec_address IN (select * from xx_ar_self_serv_bad_addr where (Direct_bill_flag = 'Y' AND process_id = p_process_id AND status is null)  OR (NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' ))
        LOOP
          lv_payload := '{
                          "customerInfoRequest": {
                              "contactType": "ADDRESS",
                              "accountNumber": "'||rec_address.aops_account||'",
                              "ebsAccountNumber": "'||rec_address.account_number||'",
                              "address": {
                                  "addressReference": "'||rec_address.address_reference||'",
                                  "address1": "'||rec_address.ebs_address1||'",
                                  "address2": "'||rec_address.ebs_address2||'",
                                  "city": "'||rec_address.ebs_city||'",
                                  "countrycd": "'||rec_address.ebs_country||'",
                                  "zip": "'||rec_address.ebs_zip||'",
                                  "state": "'||rec_address.ebs_state||'"
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
        FOR rec_email IN (select * from xx_ar_self_serv_bad_email where (Direct_bill_flag = 'Y' AND process_id = p_process_id AND status is null)  OR (NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' ))
        LOOP
          lv_payload := '{
           "customerInfoRequest": {
              "contactType": "EMAIL",
              "accountNumber": "'||rec_email.aops_account||'",
              "ebsAccountNumber": "'||rec_email.account_number||'",
              "contact": {
                 "emailAddress": "'||rec_email.EMAIL_ADDRESS||'"
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
        FOR rec_cont IN (select * from xx_ar_self_serv_bad_contact where (Direct_bill_flag = 'Y' AND process_id = p_process_id AND status is null)  OR (NVL(status,'E') = 'E' AND Direct_bill_flag = 'Y' ))
        LOOP
          lv_payload := '{
           "customerInfoRequest": {
              "contactType": "CONTACT",
              "accountNumber": "'||rec_cont.aops_account||'",
              "ebsAccountNumber": "'||rec_cont.account_number||'",
              "contact": {
                 "lastName": "'||rec_cont.LAST_NAME||'",
				 "firstName": "'||rec_cont.FIRST_NAME||'",
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
                              check_aops_number(column2),
                              column14,
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
                        EMAIL_ADDRESS,
                        AOPS_ACCOUNT,
                        account_number,

--                        CUSTOMER_NAME,
--                        AOPS_ACCOUNT,
--                        account_number,
--                        invoice_date,
--                        EMAIL_ADDRESS,

                        CREATION_DATE,
                        REQUEST_ID,
                        DIRECT_BILL_FLAG,
                        record_id,
                        process_id
                        )
                      (SELECT column1,
                              check_aops_number(column2),
                              column14,
                              --column3,
                              --column4,

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
--                              lpad(column2,8,'0'),
                              check_aops_number(column2),
                              column14,
--                              column1,
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
  lv_send_to      VARCHAR2(200);
  lv_source_folder  VARCHAR2(100);
  lv_destination_folder  VARCHAR2(100);
  lc_req_data     VARCHAR2(500);
  ln_rep_req_id   NUMBER;
  ln_arc_req_id   NUMBER;
  lv_enclosed_by  VARCHAR2(10);
  ln_skip_rows    NUMBER;

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
    BEGIN
        SELECT TARGET_VALUE7,TARGET_VALUE8
          INTO lv_enclosed_by,ln_skip_rows
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting email receiptient';
       p_ret_code := 2;
       lv_enclosed_by := NULL;
       ln_skip_rows:= 2;
    END;

    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_enclosed_by,
                ln_skip_rows,
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
--  PRAGMA AUTONOMOUS_TRANSACTION;
  l_module_name          VARCHAR2(2000) := g_package_name||'.'||'XX_BAD_ADDR_UPD';
  lv_event               VARCHAR2(500);
  ln_process_id          NUMBER;
  ln_req_id              NUMBER;
  lc_wait_flag           BOOLEAN;
  lc_phase               VARCHAR2(100);
  lc_status              VARCHAR2(100);
  lc_dev_phase           VARCHAR2(100);
  lc_dev_status          VARCHAR2(100);
  lc_message             VARCHAR2(100);
  lv_file_name           VARCHAR2(100);
  lv_directory           VARCHAR2(100);
  lv_err_message         VARCHAR2(2000);
  lv_err_code            VARCHAR2(20);
  lv_delimeter           VARCHAR2(20);
  lv_p_err               VARCHAR2(2000);
  lv_p_code              NUMBER;
  lv_process_type        VARCHAR2(20) := 'EMAIL';
  lv_send_to             VARCHAR2(50);
  lv_source_folder       VARCHAR2(100);
  lv_destination_folder  VARCHAR2(100);
  ln_rep_req_id          NUMBER;
  ln_arc_req_id          NUMBER;
  lv_enclosed_by         VARCHAR2(10);
  ln_skip_rows           NUMBER;
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
    BEGIN
        SELECT TARGET_VALUE7,TARGET_VALUE8
          INTO lv_enclosed_by,ln_skip_rows
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting enclosing';
       p_ret_code := 2;
       lv_enclosed_by := NULL;
       ln_skip_rows   :=1;
    END;
    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    logs('lv_enclosed_by '||lv_enclosed_by);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_enclosed_by,
                ln_skip_rows,
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
                add_account_name(ln_process_id);
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
  ln_skip_rows    NUMBER;
  lv_enclosed_by         VARCHAR2(10);
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
	BEGIN
        SELECT TARGET_VALUE7,TARGET_VALUE8
          INTO lv_enclosed_by,ln_skip_rows
          FROM XX_FIN_TRANSLATEDEFINITION XFTD,
               XX_FIN_TRANSLATEVALUES XFTV
         WHERE XFTD.TRANSLATION_NAME ='XX_AR_SELF_SERVICE'
           AND XFTV.SOURCE_VALUE1      =lv_process_type
           AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
    EXCEPTION WHEN OTHERS THEN
       p_err_buf := 'Error while getting enclosing';
       p_ret_code := 2;
       lv_enclosed_by := NULL;
       ln_skip_rows   :=1;
    END;
	logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    logs('lv_enclosed_by '||lv_enclosed_by);
    logs('lv_directory '||lv_directory);
    logs('lv_delimeter '||lv_delimeter);
    FOR rec_process_files IN c_process_files(ln_process_id) LOOP
       insert_data(lv_directory,
                rec_process_files.file_name,
                ln_process_id,
                lv_delimeter,
                lv_enclosed_by,
                ln_skip_rows,--ln_skip_rows
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
				add_account_name(ln_process_id);
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

/*********************************************
* Function to get Message details for report *
**********************************************/

FUNCTION get_std_message(p_req_type IN  VARCHAR2,
                         p_msg_type IN  VARCHAR2) RETURN VARCHAR2 IS
   p_msg_name VARCHAR2(100);
BEGIN
  p_msg_name :='XX_AR_SS_'||p_req_type||'_'||p_msg_type;
  fnd_message.set_name('XXFIN', p_msg_name);
  return fnd_message.get;

EXCEPTION WHEN OTHERS THEN
   RETURN null;
END;

/*********************************************************************
* Procedure for bad contact tieback
*********************************************************************/
procedure bad_contact_tieback(p_aops_number   IN  VARCHAR2,
                              p_last_name     IN  VARCHAR2,
							  p_first_name    IN VARCHAR2,
							  p_phone_number  IN VARCHAR2,
							  p_fax_number    IN VARCHAR2,
							  p_email_addr    IN VARCHAR2,
							  p_status        OUT VARCHAR2,
							  p_message       OUT VARCHAR2) IS

BEGIN
   INSERT INTO xx_ar_ss_bad_cont_tieback( record_id,
                                          AOPS_ACCOUNT,
										  ACCOUNT_NUMBER,
										  LAST_NAME,
                                          FIRST_NAME,
                                          PHONE_NUMBER,
                                          FAX_NUMBER,
                                          EMAIL_ADDRESS,
                                          runtime,
                                          export_status) VALUES
										  ( XX_AR_SS_BAD_CON_T_S.nextval,
										    p_aops_number,
											get_account_number(p_aops_number),
											p_last_name,
											p_first_name,
											p_phone_number,
											p_fax_number,
											p_email_addr,
											to_char(sysdate,'DD-MM-RRRR HH24:MI:SS'),
											'N'
										  );
    commit;
    p_status := 'S';
    p_message := 'Successfully Inserted';
EXCEPTION WHEN OTHERS THEN
   p_status := 'E';
   p_message := 'Error in insert '||SQLERRM;

END bad_contact_tieback;

PROCEDURE generate_table_export (
      x_errbuf       OUT NOCOPY      VARCHAR2,
      x_retcode      OUT NOCOPY      NUMBER
   )
   IS
----------------------------------------------------------------------
---                Variable Declaration                            ---
----------------------------------------------------------------------
      v_file                UTL_FILE.file_type;
      ln_total_cnt          NUMBER             := 0;
      ln_file_record_cnt    NUMBER             := 0;
      lc_file_name          VARCHAR2 (60);
      lc_file_name_env      VARCHAR2 (60);
      lc_table_name         VARCHAR2 (30);
      lc_file_loc           VARCHAR2 (60)      := 'XXCRM_OUTBOUND';
      lc_sourcefieldname    VARCHAR2 (240);
      lc_token              VARCHAR2 (4000);
      ln_request_id         NUMBER             DEFAULT 0;
      ln_program_name	    VARCHAR2 (60);
      ln_program_short_name VARCHAR2 (60);
      lc_message            VARCHAR2 (3000);
      lc_message1           VARCHAR2 (3000);
      lc_heading            VARCHAR2 (2000);
      lc_stmt_str           VARCHAR2 (32000);
      lc_stmt_exp_str       VARCHAR2 (4000);
      lc_exp_record         LONG;
      lc_sourcepath         VARCHAR2 (2000);
      lc_destpath           VARCHAR2 (2000);
      lc_exp_cursor         sys_refcursor;
      lc_date_time          VARCHAR2 (60);
      lc_low                VARCHAR2 (50);
      lc_high               VARCHAR2 (50);
      l_file_number         NUMBER             := 0;
      l_file_record_limit   NUMBER;
      lc_exp_account_id     xx_crm_wcelg_cust.cust_account_id%TYPE;
      lc_archpath           VARCHAR2(2000) ;
      lc_nextval	          NUMBER;
      lc_instance_name      VARCHAR2 (100);    -- -- Added by Havish Kasina as per defect#1191
	  lv_table_name         VARCHAR2 (100) := 'XX_AR_SS_BAD_CONT_TIEBACK';
	  lv_delimiter          VARCHAR2 (2) := '|~';
	  lv_directory          VARCHAR2 (100);


      CURSOR c1 (p_table_name VARCHAR2)
      IS
         SELECT   a.column_name exportfieldname,
                  DECODE (a.data_type,
                          'DATE', 'TO_CHAR('
                           || a.column_name
                           || ',''yyyy/mm/dd hh24:mm:ss '')',
                          a.column_name
                         ) sourcefieldname,
                  a.data_length
             FROM all_tab_columns a,
                  xx_fin_translatedefinition b,
                  xx_fin_translatevalues c
            WHERE a.table_name = p_table_name
	      AND a.table_name = c.source_value1
	      AND a.column_name = c.source_value2
              AND b.translate_id = c.translate_id
              AND b.translation_name = 'XXCRM_SCRAMBL_FILE_FORMAT'
              AND c.enabled_flag = 'Y'
              AND SYSDATE BETWEEN c.start_date_active
                              AND NVL (c.end_date_active, SYSDATE + 1)
         ORDER BY to_number(c.source_value3);

      CURSOR c2 (p_table_name VARCHAR2)
      IS
         SELECT UPPER (b.source_value2) column_name,
                UPPER (b.source_value3) data_type,
                UPPER (b.source_value4) data_length
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XX_CRM_SCRAMBLER_FORMAT'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = p_table_name;

   BEGIN


      -- Initialize the out Parameters
      x_errbuf := NULL;
      x_retcode := 0;
----------------------------------------------------------------------
---                File Creation Setup                             ---
----------------------------------------------------------------------
      lc_date_time := TO_CHAR (SYSDATE, 'yyyymmdd_hh24miss');
      l_file_number := l_file_number + 1;

		--Replaced from v$instance to USERENV DB_NAME --Added for LNS
		SELECT LOWER(SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8))
		INTO lc_instance_name
		FROM dual;

       fnd_file.put_line(fnd_file.log,'Instance Name :'||lc_instance_name);

         SELECT b.target_value3,UPPER (b.target_value4),b.target_value11,b.target_value12
		   INTO lv_directory,lc_file_name_env,lc_destpath,lc_archpath
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = 'XX_AR_SS_BAD_CONT_TIEBACK';

      lc_file_name :=
         lc_file_name_env || '_' || lc_date_time || '-' || l_file_number||'.dat';

      lc_message1 := lv_table_name || ' Feed Generate Init.';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, ' ');
     fnd_file.put_line(fnd_file.log,' File Name is :'||lc_file_name);
     fnd_file.put_line(fnd_file.log,' Message is :'||lc_message1);

      BEGIN
         SELECT TRIM (' ' FROM directory_path || '/' || lc_file_name)
           INTO lc_sourcepath
           FROM all_directories
          WHERE directory_name = lv_directory;
		  
		  lc_destpath := lc_destpath||'/'||lc_file_name;

         lc_message1 := ' File creating is ' || lc_sourcepath;
         fnd_file.put_line (fnd_file.LOG, lc_message1);
         fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.log,' Message is :'||lc_message1);
        fnd_file.put_line(fnd_file.log,' Source Path is :'||lc_sourcepath);
        fnd_file.put_line(fnd_file.log,' Destination Path is :'||lc_destpath);
        fnd_file.put_line(fnd_file.log,' Archive Path is :'||lc_archpath);

      EXCEPTION
         WHEN OTHERS
         THEN
         lc_message1 := ' Invalid File Path. Files will not create. ';
         fnd_file.put_line (fnd_file.LOG, lc_message1);
         fnd_file.put_line (fnd_file.LOG, ' ');
      END;

      BEGIN
         SELECT UPPER (b.source_value2) file_record_limit
           INTO l_file_record_limit
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XX_CRM_SCRAM_FILE_REC_LIM'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = lv_table_name;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_file_record_limit := 10000;
      END;

      lc_message1 := ' File record limit is ' || l_file_record_limit;
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, ' ');
      lc_stmt_str := '''';
      lc_heading := '';

     fnd_file.put_line(fnd_file.log,'Message is :'||lc_message1);

      FOR tabcol IN c1 (lv_table_name)
      LOOP
         lc_heading := lc_heading || tabcol.exportfieldname || lv_delimiter;
         lc_sourcefieldname := '';

         FOR scrambcol IN c2 (lv_table_name)
         LOOP
            IF UPPER (tabcol.exportfieldname) = scrambcol.column_name
            THEN
               IF scrambcol.data_type = 'NUMBER'
               THEN
--                  lc_low :=  rpad('1',NVL(scrambcol.data_length,tabcol.data_length),'0');
--                  lc_high := rpad('9',NVL(scrambcol.data_length,tabcol.data_length),'9');
                  lc_sourcefieldname :=
                        'trunc(dbms_random.value('
                     || 'rpad(''1'',NVL(LENGTH('
                     || tabcol.exportfieldname
                     || '),''0''),''0'')'
                     || ','
                     || 'rpad(''9'',NVL(LENGTH('
                     || tabcol.exportfieldname
                     || '),''0''),''9'')))';
               ELSIF scrambcol.data_type = 'VARCHAR2'
               THEN
                  lc_sourcefieldname :=
                        'dbms_random.string(''a'',NVL(LENGTH('
                     || tabcol.exportfieldname
                     || '),''0''))';
               END IF;
            --fnd_file.put_line(fnd_file.log,' Source Field Name1 is :'||lc_sourcefieldname);
               EXIT;
            END IF;
         END LOOP;

         IF lc_sourcefieldname IS NULL
         THEN
            lc_sourcefieldname := tabcol.sourcefieldname;
            --DBMS_OUTPUT.PUT_LINE(' Source Field Name2 is :'||lc_sourcefieldname);
         END IF;

         lc_stmt_str :=
            lc_stmt_str || '''||' || lc_sourcefieldname || '||'''
            || lv_delimiter;

           --fnd_file.put_line(fnd_file.log,' lc_stmt_str is :'||lc_stmt_str);
      END LOOP;

      lc_stmt_str := TRIM (SUBSTR(lv_delimiter,2,1) FROM lc_stmt_str);
      lc_stmt_str := TRIM ('|' FROM lc_stmt_str);
      lc_stmt_str := TRIM ('''' FROM lc_stmt_str);
      lc_stmt_str := TRIM ('|' FROM lc_stmt_str);
      lc_stmt_str := 'SELECT distinct ' || lc_stmt_str || ' FROM APPS.' || lv_table_name || ' WHERE EXPORT_STATUS = ''N''';
      fnd_file.put_line (fnd_file.LOG, lc_stmt_str);

      v_file := UTL_FILE.fopen (LOCATION          => lc_file_loc,
                         filename          => lc_file_name,
                         open_mode         => 'w',
                         max_linesize      => 32767
                        );
      ln_total_cnt := 0;
      ln_file_record_cnt :=0;

         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO lc_nextval
           FROM DUAL;

----------------------------------------------------------------------
---                UTL File Generation                             ---
----------------------------------------------------------------------
      OPEN lc_exp_cursor FOR lc_stmt_str;

      -- Fetch rows from result set one at a time:
      LOOP
         BEGIN
            FETCH lc_exp_cursor
             INTO lc_exp_record;

            EXIT WHEN lc_exp_cursor%NOTFOUND;
            UTL_FILE.put_line (v_file, lc_exp_record);
            ln_total_cnt := ln_total_cnt + 1;
	    ln_file_record_cnt := ln_file_record_cnt+1;

          BEGIN

            UPDATE XX_AR_SS_BAD_CONT_TIEBACK
               SET EXPORT_STATUS = 'Y'
             WHERE EXPORT_STATUS ='N';

            COMMIT;

          EXCEPTION
          WHEN OTHERS THEN
          NULL;--DBMS_OUTPUT.PUT_LINE('EXCEPTION:'||SQLERRM);
          END;

--------------------------------------------------------------
---                Split File                              ---
--------------------------------------------------------------
            IF MOD (ln_total_cnt, l_file_record_limit) = 0
            THEN
               lc_message1:= '';
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'Total number of Records Fetched on '||SYSDATE||' is: '||ln_file_record_cnt;
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'File name '||lc_file_name ||' have total number of Records '||ln_file_record_cnt ||' as of '||SYSDATE||' .';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
	       ln_file_record_cnt :=0;
	       UTL_FILE.fclose (v_file);
	       lc_message1 := lc_file_name || ' File Copy Init';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
               INSERT INTO xx_crmar_file_log
                           (program_id
                           ,program_name
                           ,program_run_date
                           ,filename
                           ,total_records
                           ,status
                           ,request_id -- V1.1, Added request_id
                           )
                    VALUES (lc_nextval
                           ,ln_program_name
                           ,SYSDATE
                           ,lc_file_name
                           ,ln_file_record_cnt
                           ,'SUCCESS'
                           ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                           );

             fnd_file.put_line(fnd_file.log,'After inserting into xx_crmar_file_log table');
             fnd_file.put_line(fnd_file.log,'Before Creating zip file to archieve folder');

              -- Creating zip file to archieve folder
               xxcrm_table_scrambler_pkg.Zip_File(p_sourcepath    => lc_sourcepath ,
                        p_destpath      => lc_archpath
                        );
             fnd_file.put_line(fnd_file.log,'After Creating zip file to archieve folder');
             fnd_file.put_line(fnd_file.log,'Before Creating Source file to Destination');
              -- Creating Source file to Destination
               xxcrm_table_scrambler_pkg.copy_file (p_sourcepath      => lc_sourcepath,
                          p_destpath        => lc_destpath
                         );
             fnd_file.put_line(fnd_file.log,'After Creating Source file to Destination');
               COMMIT;

               lc_message1 := lc_file_name || ' File Copy Complete';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
               l_file_number := l_file_number + 1;
               lc_file_name :=
                     lc_file_name_env
                  || '_'
                  || lc_date_time
                  || '-'
                  || l_file_number
                  || '.dat';

              fnd_file.put_line(fnd_file.log,'Message is :'||lc_message1);
              fnd_file.put_line(fnd_file.log,'File Name is :'||lc_file_name);
               BEGIN
                  SELECT TRIM (' ' FROM directory_path || '/' || lc_file_name)
                    INTO lc_sourcepath
                    FROM all_directories
                   WHERE directory_name = 'XXCRM_OUTBOUND';

                  lc_message1 := ' File creating is ' || lc_sourcepath;
                  fnd_file.put_line (fnd_file.LOG, lc_message1);
                  fnd_file.put_line (fnd_file.LOG, ' ');
                 fnd_file.put_line(fnd_file.log,' Source Path is :'||lc_sourcepath);
                 fnd_file.put_line(fnd_file.log,' Destination Path is :'||lc_destpath);
                 fnd_file.put_line(fnd_file.log,' Archive Path is :'||lc_archpath);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               v_file :=
                  UTL_FILE.fopen (LOCATION          => lc_file_loc,
                                  filename          => lc_file_name,
                                  open_mode         => 'w',
                                  max_linesize      => 32767
                                 );
            END IF;
-------------------------------------------------------------------
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_token :=
                     ' Error -' || SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
               fnd_message.set_token ('MESSAGE', lc_token);
               lc_message := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, ' ');
               fnd_file.put_line (fnd_file.LOG,
                                  'An error occured. Details : ' || lc_token
                                 );
               fnd_file.put_line (fnd_file.LOG, ' ');
         END;
      END LOOP;

      -- Close cursor:
      CLOSE lc_exp_cursor;

	       lc_message1:= '';
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'Total number of Records Fetched on '||SYSDATE||' is: '||ln_file_record_cnt;
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'File name '||lc_file_name ||' have total number of Records '||ln_file_record_cnt ||' as of '||SYSDATE||' .';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
      UTL_FILE.fclose (v_file);
      lc_message1 := lv_table_name || ' Feed Generate Complete.';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, ' ');

               INSERT INTO xx_crmar_file_log
                           (program_id
                           ,program_name
                           ,program_run_date
                           ,filename
                           ,total_records
                           ,status
                           ,request_id -- V1.1, Added request_id
                           )
                    VALUES (lc_nextval
                           ,ln_program_name
                           ,SYSDATE
                           ,lc_file_name
                           ,ln_file_record_cnt
                           ,'SUCCESS'
                           ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                           );

      --Summary data inserting into log table
      INSERT INTO xx_crmar_int_log
                  (Program_Run_Id
                  ,program_name
                  ,program_short_name
                  ,module_name
                  ,program_run_date
                  ,filename
                  ,total_files
                  ,total_records
                  ,status
                  ,MESSAGE
                  ,request_id -- V1.1, Added request_id
                  )
           VALUES (lc_nextval
                  ,ln_program_name
                  ,ln_program_short_name
                  ,'XXCRM'
                  ,SYSDATE
                  ,lc_file_name
                  ,'1'
                  ,ln_file_record_cnt
                  ,'SUCCESS'
                  ,'File generated'
                  ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                  );


---                Copying File                                    ---
---  File is generated in $XXCRM/outbound directory. The file has  ---
---  to be moved to $XXCRM/FTP/Out directory. As per OD standard   ---
---  any external process should not poll any EBS directory.       ---
----------------------------------------------------------------------
      lc_message1 := lc_file_name || ' File Copy Init';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, '');
     fnd_file.put_line(fnd_file.log,'Creating zip file to archieve folder');
     fnd_file.put_line(fnd_file.log,'Creating Source file to Destination');
    -- Creating zip file to archieve folder
               xxcrm_table_scrambler_pkg.Zip_File(p_sourcepath    => lc_sourcepath ,
                        p_destpath      => lc_archpath
                        );

     fnd_file.put_line(fnd_file.log,lc_message1);
                xxcrm_table_scrambler_pkg.copy_file (p_sourcepath => lc_sourcepath,
                          p_destpath => lc_destpath
                          );

      COMMIT;
      lc_message1 := lc_file_name || ' File Copy Complete';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, '');
     fnd_file.put_line(fnd_file.log,lc_message1);
----------------------------------------------------------------------
---         Printing summary report in the LOG file                ---
----------------------------------------------------------------------
      lc_message1 := 'Total number of ' || lv_table_name || ' Records : ';
      fnd_file.put_line (fnd_file.LOG, lc_message1 || TO_CHAR (ln_total_cnt));
      fnd_file.put_line (fnd_file.LOG, ' ');
     fnd_file.put_line(fnd_file.log,lc_message1);
      COMMIT;
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         UTL_FILE.fclose (v_file);
         lc_token := lc_file_loc;
         fnd_message.set_token ('MESSAGE', lc_token);
         lc_message := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG,
                            'An error occured. Details : ' || lc_message
                           );
         fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.log,'EXCEPTION :'||SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.write_error
      THEN
         UTL_FILE.fclose (v_file);
         lc_token := lc_file_loc;
         fnd_message.set_token ('MESSAGE1', lc_token);
         lc_token := lc_file_name;
         fnd_message.set_token ('MESSAGE2', lc_token);
         lc_message := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG,
                            'An error occured. Details : ' || lc_token
                           );
         fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.log,'EXCEPTION :'||SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.access_denied
      THEN
         UTL_FILE.fclose (v_file);
         lc_token := lc_file_loc;
         fnd_message.set_token ('MESSAGE1', lc_token);
         lc_token := lc_file_name;
         fnd_message.set_token ('MESSAGE2', lc_token);
         lc_message := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG,
                            'An error occured. Details : ' || lc_token
                           );
         fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.log,'EXCEPTION :'||SQLERRM);
         x_retcode := 2;
      WHEN OTHERS
      THEN
         UTL_FILE.fclose (v_file);
         lc_token := SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
--       fnd_file.put_line(fnd_file.log,lc_token);
         fnd_message.set_token ('MESSAGE', lc_token);
         lc_message := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG,
                            'An error occured. Details : ' || lc_token
                           );
         fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line(fnd_file.log,'EXCEPTION :'||SQLERRM);
         x_retcode := 2;
   END generate_table_export;

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