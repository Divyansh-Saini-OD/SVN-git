SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body xx_ce_mrktplc_file_download
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_FILE_DOWNLOAD                                                           |
  -- |                                                                                            |
  -- |  Description: Download File for Marketplaces   |
  -- |  RICE ID   : I3123_CM MarketPlaces Expansion               |
  -- |  Description: Download File for Marketplaces          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         11-JAN-2019   Priyam S           Initial Version  added    Newegg API file donwnload UTL_HTTP Version                         |
  -- +============================================================================================|
  gc_package_name      CONSTANT all_objects.object_name%type := 'XX_CE_MRKTPLC_FILE_DOWNLOAD';
  gc_ret_success       CONSTANT VARCHAR2(20)                 := 'SUCCESS';
  gc_ret_no_data_found CONSTANT VARCHAR2(20)                 := 'NO_DATA_FOUND';
  gc_ret_too_many_rows CONSTANT VARCHAR2(20)                 := 'TOO_MANY_ROWS';
  gc_ret_api           CONSTANT VARCHAR2(20)                 := 'API';
  gc_ret_others        CONSTANT VARCHAR2(20)                 := 'OTHERS';
  gc_max_err_size      CONSTANT NUMBER                       := 2000;
  gc_max_sub_err_size  CONSTANT NUMBER                       := 256;
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;
  gb_debug             BOOLEAN                               := false;
  gb_url1              VARCHAR2(100);
  gb_accesskeyid       VARCHAR2(100);
  gb_secretaccesskey   VARCHAR2(100);
  gb_walletpath        VARCHAR2(100);
  gb_walletpwd         VARCHAR2(100);
  gb_merchantid        VARCHAR2(100);
  gb_url2              VARCHAR2(100);
  gb_url3              VARCHAR2(100);
  gb_inbound_path      VARCHAR2(100);
  gb_start_date        VARCHAR2(100);
  gb_end_date          VARCHAR2(100);
type gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
PROCEDURE get_http_details(
    p_process_name VARCHAR2)
AS
BEGIN
  SELECT xftv.target_value1
    ||xx_encrypt_decryption_toolkit.decrypt(xftv.target_value6) url1,
    xx_encrypt_decryption_toolkit.decrypt(NVL(xftv.target_value2,xx_encrypt_decryption_toolkit.encrypt('X'))) accesskeyid,
    xx_encrypt_decryption_toolkit.decrypt(NVL(xftv.target_value3,xx_encrypt_decryption_toolkit.encrypt('X'))) secretaccesskey,
    xftv.target_value4 walletpath,
    xx_encrypt_decryption_toolkit.decrypt(xftv.target_value5) walletpwd,
    TO_CHAR(xx_ce_mrktplc_prestg_pkg.get_start_date(P_process_name),'YYYY-MM-DD') start_date,
    TO_CHAR(sysdate,'YYYY-MM-DD') end_date,
    xx_encrypt_decryption_toolkit.encrypt(TO_CHAR(sysdate,'DDMMYYYYHH24MISS')) merchantid,
    xftv.target_value22
    ||xx_encrypt_decryption_toolkit.decrypt(xftv.target_value6) url2,
    xftv.target_value23
    ||xx_encrypt_decryption_toolkit.decrypt(xftv.target_value6)
    ||chr(38)
    ||'version=306' url3,
    xftv.target_value8 inbound_path
  INTO gb_url1,
    gb_accesskeyid,
    gb_secretaccesskey,
    gb_walletpath,
    gb_walletpwd,
    gb_start_date,
    gb_end_date,
    gb_merchantid,
    gb_url2,
    gb_url3,
    gb_inbound_path
  FROM xx_fin_translatedefinition xftd,
    xx_fin_translatevalues xftv
  WHERE xftd.translation_name ='OD_SETTLEMENT_PROCESSES'
  AND xftv.source_value1      =p_process_name
  AND xftd.translate_id       =xftv.translate_id
  AND xftd.enabled_flag       ='Y'
  AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);
END get_http_details;
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT false)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF (gb_debug OR p_force) THEN
    lc_message := SUBSTR(TO_CHAR(systimestamp, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.log, lc_message);
      -- else print to DBMS_OUTPUT
    ELSE
      dbms_output.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
/****************************************************************
* Helper procedure to log the exiting of a subprocedure.
* This is useful for debugging and for tracking how long a given
* procedure is taking.
****************************************************************/
PROCEDURE exiting_sub(
    p_procedure_name IN VARCHAR2,
    p_exception_flag IN BOOLEAN DEFAULT false)
AS
BEGIN
  IF gb_debug THEN
    IF p_exception_flag THEN
      logit(p_message => 'Exiting Exception: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    ELSE
      logit(p_message => 'Exiting: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    END IF;
    logit(p_message => '-----------------------------------------------');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END exiting_sub;
/***********************************************
*  Setter procedure for gb_debug global variable
*  used for controlling debugging
***********************************************/
PROCEDURE set_debug(
    p_debug_flag IN VARCHAR2)
IS
BEGIN
  IF (upper(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE')) THEN
    gb_debug := true;
  END IF;
END set_debug;
/**********************************************************************
* Helper procedure to log the sub procedure/function name that has been
* called and logs the input parameters passed to it.
***********************************************************************/
PROCEDURE entering_sub(
    p_procedure_name IN VARCHAR2,
    p_parameters     IN gt_input_parameters)
AS
  ln_counter           NUMBER          := 0;
  lc_current_parameter VARCHAR2(32000) := NULL;
BEGIN
  IF gb_debug THEN
    logit(p_message => '-----------------------------------------------');
    logit(p_message => 'Entering: ' || p_procedure_name);
    logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    lc_current_parameter := p_parameters.first;
    IF p_parameters.count > 0 THEN
      logit(p_message => 'Input parameters:');
      LOOP
        EXIT
      WHEN lc_current_parameter IS NULL;
        ln_counter              := ln_counter + 1;
        logit(p_message => ln_counter || '. ' || lc_current_parameter || ' => ' || p_parameters(lc_current_parameter));
        lc_current_parameter := p_parameters.next(lc_current_parameter);
      END LOOP;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_sub;
-- +============================================================================================+
-- |  Name  : Log Exception                                                                     |
-- |  Description: The log_exception procedure logs all exceptions                              |
-- =============================================================================================|
PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := fnd_global.login_id;
  ln_user_id NUMBER := fnd_global.user_id;
BEGIN
  logit(p_message=>p_error_msg);
  xx_com_error_log_pub.log_error( p_return_code => fnd_api.g_ret_sts_error ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'AR' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| sqlerrm);
END log_exception;
/******************************************************************
* file record creation for uplicate Check
* Table : XXCE_MKTPLC_FILE
Added column  ERR_MSG,Process_Flag,request_id
******************************************************************/
PROCEDURE insert_file_rec(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_err_msg      VARCHAR2 DEFAULT NULL,
    p_process_flag VARCHAR2,
    p_requestid    NUMBER)
IS
BEGIN
  INSERT
  INTO xx_ce_mpl_files
    (
      mpl_name,
      file_name,
      creation_date,
      created_by,
      last_updated_by,
      last_update_date,
      err_msg,
      process_flag,
      request_id
    )
    VALUES
    (
      p_process_name,
      p_file_name,
      sysdate,
      fnd_global.user_id,
      fnd_global.user_id,
      sysdate,
      p_err_msg,
      p_process_flag,
      p_requestid
    );
EXCEPTION
WHEN OTHERS THEN
  logit(p_message=> 'INSERT_FILE_REC : Error - '||sqlerrm);
end;

-- +============================================================================================+
-- |  Name  : INSERT_PRE_STG_EXCPN                                                                 |
-- |  Description: Procedure to insert bad records to exception table                |
-- =============================================================================================|
PROCEDURE insert_pre_stg_excpn
  (
    p_process_name VARCHAR2,
    p_request_id   NUMBER,
    p_report_date  DATE,
    p_err_msg      VARCHAR2 DEFAULT NULL,
    p_file_name    VARCHAR2,
    p_record_type  VARCHAR2,
    p_attribute1   VARCHAR2 DEFAULT NULL,
    p_attribute2   VARCHAR2 DEFAULT NULL,
    p_attribute3   VARCHAR2 DEFAULT NULL,
    p_attribute4   VARCHAR2 DEFAULT NULL,
    p_attribute5   VARCHAR2 DEFAULT NULL,
    p_attribute6   VARCHAR2 DEFAULT NULL,
    p_attribute7   VARCHAR2 DEFAULT NULL,
    p_attribute8   VARCHAR2 DEFAULT NULL,
    p_attribute9   VARCHAR2 DEFAULT NULL,
    p_attribute10  VARCHAR2 DEFAULT NULL,
    p_attribute11  VARCHAR2 DEFAULT NULL,
    p_attribute12  VARCHAR2 DEFAULT NULL,
    p_attribute13  VARCHAR2 DEFAULT NULL,
    p_attribute14  VARCHAR2 DEFAULT NULL,
    p_attribute15  VARCHAR2 DEFAULT NULL,
    p_attribute16  VARCHAR2 DEFAULT NULL,
    p_attribute17  VARCHAR2 DEFAULT NULL,
    p_attribute18  VARCHAR2 DEFAULT NULL,
    p_attribute19  VARCHAR2 DEFAULT NULL,
    p_attribute20  VARCHAR2 DEFAULT NULL,
    p_attribute21  VARCHAR2 DEFAULT NULL,
    p_attribute22  VARCHAR2 DEFAULT NULL,
    p_attribute23  VARCHAR2 DEFAULT NULL,
    p_attribute24  VARCHAR2 DEFAULT NULL,
    p_attribute25  VARCHAR2 DEFAULT NULL,
    p_attribute26  VARCHAR2 DEFAULT NULL,
    p_attribute27  VARCHAR2 DEFAULT NULL,
    p_attribute28  VARCHAR2 DEFAULT NULL,
    p_attribute29  VARCHAR2 DEFAULT NULL,
    p_attribute30  VARCHAR2 DEFAULT NULL,
    p_attribute31  VARCHAR2 DEFAULT NULL,
    p_attribute32  VARCHAR2 DEFAULT NULL,
    p_attribute33  VARCHAR2 DEFAULT NULL,
    p_attribute34  VARCHAR2 DEFAULT NULL,
    p_attribute35  VARCHAR2 DEFAULT NULL,
    p_attribute36  VARCHAR2 DEFAULT NULL,
    p_attribute37  VARCHAR2 DEFAULT NULL,
    p_attribute38  VARCHAR2 DEFAULT NULL,
    p_attribute39  VARCHAR2 DEFAULT NULL,
    p_attribute40  VARCHAR2 DEFAULT NULL,
    p_attribute41  VARCHAR2 DEFAULT NULL,
    p_attribute42  VARCHAR2 DEFAULT NULL,
    p_attribute43  VARCHAR2 DEFAULT NULL,
    p_attribute44  VARCHAR2 DEFAULT NULL,
    p_attribute45  VARCHAR2 DEFAULT NULL,
    p_attribute46  VARCHAR2 DEFAULT NULL,
    p_attribute47  VARCHAR2 DEFAULT NULL,
    p_attribute48  VARCHAR2 DEFAULT NULL,
    p_attribute49  VARCHAR2 DEFAULT NULL,
    p_attribute50  VARCHAR2 DEFAULT NULL,
    p_attribute51  VARCHAR2 DEFAULT NULL,
    p_attribute52  VARCHAR2 DEFAULT NULL,
    p_attribute53  VARCHAR2 DEFAULT NULL,
    p_attribute54  VARCHAR2 DEFAULT NULL,
    p_attribute55  VARCHAR2 DEFAULT NULL,
    p_attribute56  VARCHAR2 DEFAULT NULL,
    p_attribute57  VARCHAR2 DEFAULT NULL,
    p_attribute58  VARCHAR2 DEFAULT NULL,
    p_attribute59  VARCHAR2 DEFAULT NULL,
    p_attribute60  VARCHAR2 DEFAULT NULL,
    p_attribute61  VARCHAR2 DEFAULT NULL,
    p_attribute62  VARCHAR2 DEFAULT NULL,
    p_attribute63  VARCHAR2 DEFAULT NULL,
    p_attribute64  VARCHAR2 DEFAULT NULL,
    p_attribute65  VARCHAR2 DEFAULT NULL,
    p_attribute66  VARCHAR2 DEFAULT NULL,
    p_attribute67  VARCHAR2 DEFAULT NULL,
    p_attribute68  VARCHAR2 DEFAULT NULL,
    p_attribute69  VARCHAR2 DEFAULT NULL,
    p_attribute70  VARCHAR2 DEFAULT NULL,
    p_attribute71  VARCHAR2 DEFAULT NULL,
    p_attribute72  VARCHAR2 DEFAULT NULL,
    p_attribute73  VARCHAR2 DEFAULT NULL,
    p_attribute74  VARCHAR2 DEFAULT NULL,
    p_attribute75  VARCHAR2 DEFAULT NULL,
    p_attribute76  VARCHAR2 DEFAULT NULL,
    p_attribute77  VARCHAR2 DEFAULT NULL,
    p_attribute78  VARCHAR2 DEFAULT NULL,
    p_attribute79  VARCHAR2 DEFAULT NULL,
    p_attribute80  VARCHAR2 DEFAULT NULL,
    p_attribute81  VARCHAR2 DEFAULT NULL,
    p_attribute82  VARCHAR2 DEFAULT NULL,
    p_attribute83  VARCHAR2 DEFAULT NULL,
    p_attribute84  VARCHAR2 DEFAULT NULL,
    p_attribute85  VARCHAR2 DEFAULT NULL,
    p_attribute86  VARCHAR2 DEFAULT NULL,
    p_attribute87  VARCHAR2 DEFAULT NULL,
    p_attribute88  VARCHAR2 DEFAULT NULL,
    p_attribute89  VARCHAR2 DEFAULT NULL,
    p_attribute90  VARCHAR2 DEFAULT NULL,
    p_attribute91  VARCHAR2 DEFAULT NULL,
    p_attribute92  VARCHAR2 DEFAULT NULL,
    p_attribute93  VARCHAR2 DEFAULT NULL,
    p_attribute94  VARCHAR2 DEFAULT NULL,
    p_attribute95  VARCHAR2 DEFAULT NULL,
    p_attribute96  VARCHAR2 DEFAULT NULL,
    p_attribute97  VARCHAR2 DEFAULT NULL,
    p_attribute98  VARCHAR2 DEFAULT NULL,
    p_attribute99  VARCHAR2 DEFAULT NULL,
    p_attribute100 VARCHAR2 DEFAULT NULL
  )
AS
  pragma autonomous_transaction;
BEGIN
  --select XX_CE_MKT_PRE_STG_S.nextval from dual
  INSERT
  INTO xx_ce_mktplc_pre_stg_excpn
    (
      process_name ,
      request_id ,
      report_date,
      err_msg,
      file_name ,
      record_type,
      attribute1 ,
      attribute2 ,
      attribute3 ,
      attribute4 ,
      attribute5 ,
      attribute6 ,
      attribute7 ,
      attribute8 ,
      attribute9 ,
      attribute10 ,
      attribute11 ,
      attribute12 ,
      attribute13 ,
      attribute14 ,
      attribute15 ,
      attribute16 ,
      attribute17 ,
      attribute18 ,
      attribute19 ,
      attribute20 ,
      attribute21 ,
      attribute22 ,
      attribute23 ,
      attribute24 ,
      attribute25 ,
      attribute26 ,
      attribute27 ,
      attribute28 ,
      attribute29 ,
      attribute30 ,
      attribute31 ,
      attribute32 ,
      attribute33 ,
      attribute34 ,
      attribute35 ,
      attribute36 ,
      attribute37 ,
      attribute38 ,
      attribute39 ,
      attribute40 ,
      attribute41 ,
      attribute42 ,
      attribute43 ,
      attribute44 ,
      attribute45 ,
      attribute46 ,
      attribute47 ,
      attribute48 ,
      attribute49 ,
      attribute50 ,
      attribute51 ,
      attribute52 ,
      attribute53 ,
      attribute54 ,
      attribute55 ,
      attribute56 ,
      attribute57 ,
      attribute58 ,
      attribute59 ,
      attribute60 ,
      attribute61 ,
      attribute62 ,
      attribute63 ,
      attribute64 ,
      attribute65 ,
      attribute66 ,
      attribute67 ,
      attribute68 ,
      attribute69 ,
      attribute70 ,
      attribute71 ,
      attribute72 ,
      attribute73 ,
      attribute74 ,
      attribute75 ,
      attribute76 ,
      attribute77 ,
      attribute78 ,
      attribute79 ,
      attribute80 ,
      attribute81 ,
      attribute82 ,
      attribute83 ,
      attribute84 ,
      attribute85 ,
      attribute86 ,
      attribute87 ,
      attribute88 ,
      attribute89 ,
      attribute90 ,
      attribute91 ,
      attribute92 ,
      attribute93 ,
      attribute94 ,
      attribute95 ,
      attribute96 ,
      attribute97 ,
      attribute98 ,
      attribute99 ,
      attribute100
    )
    VALUES
    (
      p_process_name ,
      p_request_id ,
      p_report_date,
      p_err_msg ,
      p_file_name ,
      p_record_type,
      p_attribute1 ,
      p_attribute2 ,
      p_attribute3 ,
      p_attribute4 ,
      p_attribute5 ,
      p_attribute6 ,
      p_attribute7 ,
      p_attribute8 ,
      p_attribute9 ,
      p_attribute10 ,
      p_attribute11 ,
      p_attribute12 ,
      p_attribute13 ,
      p_attribute14 ,
      p_attribute15 ,
      p_attribute16 ,
      p_attribute17 ,
      p_attribute18 ,
      p_attribute19 ,
      p_attribute20 ,
      p_attribute21 ,
      p_attribute22 ,
      p_attribute23 ,
      p_attribute24 ,
      p_attribute25 ,
      p_attribute26 ,
      p_attribute27 ,
      p_attribute28 ,
      p_attribute29 ,
      p_attribute30 ,
      p_attribute31 ,
      p_attribute32 ,
      p_attribute33 ,
      p_attribute34 ,
      p_attribute35 ,
      p_attribute36 ,
      p_attribute37 ,
      p_attribute38 ,
      p_attribute39 ,
      p_attribute40 ,
      p_attribute41 ,
      p_attribute42 ,
      p_attribute43 ,
      p_attribute44 ,
      p_attribute45 ,
      p_attribute46 ,
      p_attribute47 ,
      p_attribute48 ,
      p_attribute49 ,
      p_attribute50 ,
      p_attribute51 ,
      p_attribute52 ,
      p_attribute53 ,
      p_attribute54 ,
      p_attribute55 ,
      p_attribute56 ,
      p_attribute57 ,
      p_attribute58 ,
      p_attribute59 ,
      p_attribute60 ,
      p_attribute61 ,
      p_attribute62 ,
      p_attribute63 ,
      p_attribute64 ,
      p_attribute65 ,
      p_attribute66 ,
      p_attribute67 ,
      p_attribute68 ,
      p_attribute69 ,
      p_attribute70 ,
      p_attribute71 ,
      p_attribute72 ,
      p_attribute73 ,
      p_attribute74 ,
      p_attribute75 ,
      p_attribute76 ,
      p_attribute77 ,
      p_attribute78 ,
      p_attribute79 ,
      p_attribute80 ,
      p_attribute81 ,
      p_attribute82 ,
      p_attribute83 ,
      p_attribute84 ,
      p_attribute85 ,
      p_attribute86 ,
      p_attribute87 ,
      p_attribute88 ,
      p_attribute89 ,
      p_attribute90 ,
      p_attribute91 ,
      p_attribute92 ,
      p_attribute93 ,
      p_attribute94 ,
      p_attribute95 ,
      p_attribute96 ,
      p_attribute97 ,
      p_attribute98 ,
      p_attribute99 ,
      p_attribute100
    ) ;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error '||SQLERRM);
  logit(p_message =>'INSERT_PRE_STG: Error :'||sqlerrm);
END insert_pre_stg_excpn;
/**********************************************************************
* This procedure will get the  Newegg Transaction and Summary request id
**********************************************************************/
PROCEDURE newegg_get_request_id
  (
    p_api_request_id OUT VARCHAR2,
    p_file_flag       VARCHAR2,
    p_process_name    VARCHAR2,
    p_start_date_from VARCHAR2,
    p_start_date_to   VARCHAR2,
    p_settlement_id   VARCHAR2
  )
AS
  l_request utl_http.req;
  l_response utl_http.resp;
  lc_auth_payload VARCHAR2(32000);
  value           VARCHAR2(32000);
  v_xml_value xmltype;
  v_request_id            VARCHAR2(50);
  v_requeststatus         VARCHAR2(50);
  gb_settlement_date_from VARCHAR2(100);
  gb_settlement_date_to   VARCHAR2(100);
BEGIN
  BEGIN
    get_http_details(p_process_name);
    /*  gb_start_date:='2018-12-01';
    gb_end_date:='2018-12-22';
    gb_settlement_date_from:='2019-01-02';
    gb_settlement_date_to:='2019-01-10';*/
    ---<SettlementDate>'||gb_end_date||'</SettlementDate>
    ----<TransactionType>1</TransactionType>
    --   <settlementdatefrom>'||p_start_date_from||'</settlementdatefrom>
    ---<SettlementDateTo>'||p_start_date_to||'</SettlementDateTo>
    --- gb_start_date:='2019-01-09';
    ---- gb_end_date:='2019-01-09';
    IF p_file_flag    ='T' THEN
      lc_auth_payload:='<NeweggAPIRequest>
<OperationType>SettlementTransactionReportRequest</OperationType>
<RequestBody>
<SettlementTransactionReportCriteria>
<RequestType>SETTLEMENT_TRANSACTION_REPORT</RequestType>
<SettlementID>'||P_SETTLEMENT_ID||'</SettlementID>
</SettlementTransactionReportCriteria>
</RequestBody>
</NeweggAPIRequest>';
    ELSE
      lc_auth_payload:='<NeweggAPIRequest >
<OperationType>SettlementSummaryReportRequest</OperationType>
<RequestBody>
<SettlementSummaryReportCriteria>
<RequestType>SETTLEMENT_SUMMARY_REPORT</RequestType>
<DateFrom>'||gb_start_date||'</DateFrom>
<DateTo>'||gb_end_date||'</DateTo>
</SettlementSummaryReportCriteria>
</RequestBody>
</NeweggAPIRequest>';
    END IF;
    utl_http.set_wallet(gb_walletpath, gb_walletpwd);
    utl_http.set_response_error_check ( enable => true );
    utl_http.set_detailed_excp_support ( enable => true );
    l_request := utl_http.begin_request(gb_url1, 'POST', 'HTTP/1.1');
    utl_http.set_header(l_request, 'accept', 'application/xml');
    utl_http.set_header(l_request, 'authorization', gb_accesskeyid);
    utl_http.set_header(l_request, 'secretkey', gb_secretaccesskey);
    utl_http.set_header(l_request, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(l_request, 'content-type', 'application/xml');
    utl_http.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
    utl_http.write_text(l_request, lc_auth_payload);
    l_response := utl_http.get_response(l_request);
    COMMIT;
    utl_http.read_line(l_response, value, true);
    v_xml_value:= xmltype(value);
    --------Reading XML Values---------------------------
    SELECT extractvalue(value(b),'*/RequestId/text()') ,
      extractvalue(value(b),'*/RequestStatus/text()')
    INTO v_request_id,
      v_requeststatus
    FROM
      (SELECT v_xml_value xml_tag FROM dual
      ) a,
      TABLE(xmlsequence(extract(a.xml_tag,'NeweggAPIResponse//ResponseInfo'))) b;
    --------------------------------------------------
    logit(p_message => 'Request_id for Newegg  file is : '|| v_request_id);
    logit(p_message => 'RequestStatus for Newegg file is : '|| v_requeststatus);
    utl_http.end_response(l_response);
    logit(p_message => 'Response received from Newegg First URL '||l_response.status_code);
    p_api_request_id:=v_request_id;
  EXCEPTION
  WHEN utl_http.too_many_requests THEN
    utl_http.end_response(l_response);
    v_request_id:='XXX';
    logit(p_message => 'In exception in procedure newegg_get_request_id utl_http.too_many_requests'|| SUBSTR(sqlerrm,1,150));
  WHEN utl_http.end_of_body THEN
    utl_http.end_response(l_response);
    logit(p_message => 'In exception in procedure newegg_get_request_id UTL_HTTP.end_of_body'|| SUBSTR(sqlerrm,1,150));
  END;
END newegg_get_request_id;
/**********************************************************************
* This procedure will submit the  Newegg Transaction and Summary request and wait for its completion
**********************************************************************/
PROCEDURE newegg_get_request_status(
    p_api_request_id IN VARCHAR2,
    p_request_status OUT VARCHAR2,
    p_process_name VARCHAR2)
AS
  l_request utl_http.req;
  l_response utl_http.resp;
  lc_auth_payload VARCHAR2(32000);
  value           VARCHAR2(32000);
  v_xml_value xmltype;
  v_request_id        VARCHAR2(50);
  v_requeststatus     VARCHAR2(50);
  v_requeststatustrxn VARCHAR2(100);
BEGIN
  BEGIN
    v_request_id :=p_api_request_id;
    ----<MaxCount>10</MaxCount>
    lc_auth_payload     :='<NeweggAPIRequest>
<OperationType>GetReportStatusRequest</OperationType>
<RequestBody>
<GetRequestStatus>
<RequestIDList>
<RequestID>'||v_request_id||'</RequestID>
</RequestIDList>
</GetRequestStatus>
</RequestBody>
</NeweggAPIRequest>';
    v_requeststatustrxn :='IN_PROGRESS';
    LOOP
      get_http_details(p_process_name);
      utl_http.set_wallet(gb_Walletpath, gb_walletpwd);
      utl_http.set_response_error_check ( enable => true );
      utl_http.set_detailed_excp_support ( enable => true );
      l_request := utl_http.begin_request(gb_url2, 'PUT', 'HTTP/1.1');
      utl_http.set_header(l_request, 'accept', 'application/xml');
      utl_http.set_header(l_request, 'authorization', gb_accesskeyid);
      utl_http.set_header(l_request, 'secretkey', gb_secretaccesskey);
      utl_http.set_header(l_request, 'user-agent', 'mozilla/4.0');
      utl_http.set_header(l_request, 'content-type', 'application/xml');
      utl_http.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
      utl_http.write_text(l_request, lc_auth_payload);
      l_response := utl_http.get_response(l_request);
      COMMIT;
      utl_http.read_line(l_response, value, true);
      v_xml_value:= xmltype(value);
      --------Reading XML Values for URL2---------------------------
      SELECT extractvalue(value(b),'*/RequestStatus/text()')
      INTO v_requeststatustrxn
      FROM
        (SELECT v_xml_value xml_tag FROM dual
        ) a,
        TABLE(xmlsequence(extract(a.xml_tag,'NeweggAPIResponse//ResponseInfo'))) b;
      utl_http.end_response(l_response);
      dbms_lock.sleep(10);
      ---   fnd_file.put_line(fnd_file.log,'Time '||TO_CHAR(sysdate,'hh24:mi:ss'));
      EXIT
    WHEN (v_requeststatustrxn ='FINISHED' OR v_requeststatustrxn='FAILED');
    END LOOP;
    logit(p_message =>'Transaction request status '|| v_requeststatustrxn);
    utl_http.end_response(l_response);
    logit(p_message => 'Response received from Newegg second URL '||l_response.status_code);
    p_request_status:=v_requeststatustrxn;
  EXCEPTION
  WHEN utl_http.too_many_requests THEN
    utl_http.end_response(l_response);
    p_request_status:='FAILED';
    logit(p_message =>'In exception in procedure newegg_get_request_status utl_http.too_many_requests'|| SUBSTR(sqlerrm,1,150));
  WHEN utl_http.end_of_body THEN
    utl_http.end_response(l_response);
    p_request_status:='ERROR';
    logit(p_message =>'In exception in procedure newegg_get_request_status UTL_HTTP.end_of_body'|| SUBSTR(sqlerrm,1,150));
  END;
END newegg_get_request_status;
/**********************************************************************
* This procedure will created Newegg Transaction and Summary file into MPL folder
**********************************************************************/
PROCEDURE create_newegg_trx_file(
    p_file_name    VARCHAR2,
    p_process_name VARCHAR2,
    p_request_id   NUMBER )
AS
  lc_xmltype xmltype;
  lclob_buffer CLOB;
  l_filehandle utl_file.file_type;
  l_error_loc VARCHAR2(2000) := 'XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file';
  v_error     VARCHAR2(1000);
BEGIN
  logit(p_message =>'Process started for create_newegg_trx_file for file name  '|| p_file_name);
  SELECT file_data
  INTO lc_xmltype
  FROM xx_ce_mktplc_pre_stg_files
  WHERE file_name=p_file_name;
  l_filehandle  := utl_file.fopen('XXFIN_INBOUND_MPL', p_file_name, 'w',32767);
  lclob_buffer  := lc_xmltype.getclobval ();
  utl_file.put(l_filehandle , lclob_buffer);
  utl_file.fclose(l_filehandle);
EXCEPTION
WHEN utl_file.invalid_operation THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: Invalid Operation '||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, v_error , P_FILE_NAME, 'F');
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN utl_file.invalid_filehandle THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: invalid_filehandle'||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  INSERT_PRE_STG_EXCPN ( p_process_name , p_request_id, sysdate, v_error , p_file_name, 'F');
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN utl_file.read_error THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: read_error '||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  INSERT_PRE_STG_EXCPN ( p_process_name , p_request_id, sysdate, v_error , p_file_name, 'F');
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN utl_file.invalid_path THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: invalid_path'||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  INSERT_PRE_STG_EXCPN ( p_process_name , p_request_id, sysdate, v_error , p_file_name, 'F');
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN utl_file.invalid_mode THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: invalid_mode '||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  INSERT_PRE_STG_EXCPN ( p_process_name , p_request_id, sysdate, v_error , p_file_name, 'F');
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN utl_file.internal_error THEN
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: internal_error'||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN value_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  v_error:='XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: value_error '||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg => v_error);
  ----insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => 'XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: Invalid Operation ',p_process_flag=>'E',p_requestid=>p_request_id) ;
WHEN OTHERS THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  v_error:= 'XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file: when others '||SUBSTR(sqlerrm,1,200);
  log_exception (p_program_name => 'create_newegg_trx_file' ,p_error_location => l_error_loc ,p_error_msg =>v_error);
  insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => v_error,p_process_flag=>'E',p_requestid=>p_request_id) ;
END create_newegg_trx_file;
/**********************************************************************
* This procedure will download the file using p_api_request_id
***********************************************************************/
PROCEDURE newegg_download_file_trxn(
    p_process_name   VARCHAR2,
    p_api_request_id VARCHAR2,
    p_request_id     NUMBER,
    p_file_flag      VARCHAR2,
    p_file_name      VARCHAR2,
    p_settlement_id  VARCHAR2)
AS
  l_request utl_http.req;
  l_response utl_http.resp;
  lc_auth_payload VARCHAR2(32000);
  value           VARCHAR2(32000);
  v_xml_value xmltype;
  v_request_id        VARCHAR2(50);
  v_requeststatus     VARCHAR2(50);
  v_requeststatustrxn VARCHAR2(100);
  lclob_buffer CLOB;
  lc_buffer VARCHAR2(32767);
  --- lc_buffer raw(512);
  lc_xmltype xmltype;
  l_insert_cnt     NUMBER;
  v_file_name      VARCHAR2(100);
  v_page_index_cnt NUMBER:=0;
BEGIN
  v_request_id :=p_api_request_id;
  /*
  <PageInfo>
  <PageIndex>1</PageIndex>
  <PageSize>10</PageSize>
  </PageInfo>
  */
  ---------------------------This tag will bring count of records------------------------
  lc_auth_payload:='<NeweggAPIRequest>
<OperationType>SettlementTransactionReportRequest</OperationType>
<RequestBody>
<RequestID>'||v_request_id||'</RequestID> 
<PageInfo>
<PageIndex>1</PageIndex>
<PageSize>10</PageSize>
</PageInfo>
</RequestBody>
</NeweggAPIRequest>';
  get_http_details(p_process_name);
  utl_http.set_wallet(gb_Walletpath, gb_walletpwd);
  utl_http.set_response_error_check ( enable => true );
  utl_http.set_detailed_excp_support ( enable => true );
  l_request := utl_http.begin_request(gb_url3, 'PUT', 'HTTP/1.1');
  utl_http.set_header(l_request, 'accept', 'application/xml');
  utl_http.set_header(l_request, 'authorization', gb_accesskeyid);
  utl_http.set_header(l_request, 'secretkey', gb_secretaccesskey);
  utl_http.set_header(l_request, 'user-agent', 'mozilla/4.0');
  UTL_HTTP.set_header(l_request, 'content-type', 'application/xml');
  utl_http.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
  utl_http.write_text(l_request, lc_auth_payload);
  l_response := utl_http.get_response(l_request);
  COMMIT;
  utl_http.read_line(l_response, value, true);
  v_xml_value:= xmltype(value);
  --------Reading XML Values---------------------------
  SELECT NVL(extractvalue(value(b),'*/TotalCount/text()'),0)--- NVL(TRUNC(extractvalue(value(b),'*/TotalCount/text()')/100),0)
  INTO v_page_index_cnt
  FROM
    (SELECT v_xml_value xml_tag FROM dual
    ) a,
    TABLE(xmlsequence(extract(a.xml_tag,'NeweggAPIResponse//PageInfo'))) b;
  v_page_index_cnt :=ceil(v_page_index_cnt/50);
  FOR i                                  IN 1..v_page_index_cnt
  LOOP
    BEGIN
      lc_auth_payload:='<NeweggAPIRequest>
<OperationType>SettlementTransactionReportRequest</OperationType>
<RequestBody>
<RequestID>'||v_request_id||'</RequestID> 
<PageInfo>
<PageIndex>'||i||'</PageIndex>
<PageSize>50</PageSize>
</PageInfo>
</RequestBody>
</NeweggAPIRequest>';
       get_http_details(p_process_name);
  utl_http.set_wallet(gb_Walletpath, gb_walletpwd);
  utl_http.set_response_error_check ( enable => true );
  utl_http.set_detailed_excp_support ( enable => true );
  l_request := utl_http.begin_request(gb_url3, 'PUT', 'HTTP/1.1');
  utl_http.set_header(l_request, 'accept', 'application/xml');
  utl_http.set_header(l_request, 'authorization', gb_accesskeyid);
  utl_http.set_header(l_request, 'secretkey', gb_secretaccesskey);
  utl_http.set_header(l_request, 'user-agent', 'mozilla/4.0');
  UTL_HTTP.set_header(l_request, 'content-type', 'application/xml');
  utl_http.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
  utl_http.write_text(l_request, lc_auth_payload);
  l_response := utl_http.get_response(l_request);
      COMMIT;
      --lclob_buffer := empty_clob;
      --*********************************
      dbms_lob.createtemporary(lob_loc => lclob_buffer, cache => true, dur => dbms_lob.call);
      -- -----------------------------------
      -- OPEN TEMPORARY LOB FOR READ / WRITE
      -- -----------------------------------
      dbms_lob.open(lob_loc => lclob_buffer, open_mode => dbms_lob.lob_readwrite);
      BEGIN
        LOOP
          utl_http.read_text(r => l_response, data => lc_buffer, LEN => 2000);
          dbms_lob.writeappend(lob_loc => lclob_buffer, amount => LENGTH(lc_buffer), buffer => lc_buffer);
        END LOOP;
      EXCEPTION
      WHEN utl_http.end_of_body THEN
        NULL;
      WHEN OTHERS THEN
        raise;
      END;
      lc_xmltype := xmltype(lclob_buffer);
      utl_http.end_response(l_response);
      logit(p_message=>'Response received from Newegg Third URL '||l_response.status_code);
    EXCEPTION
    WHEN utl_http.too_many_requests THEN
      utl_http.end_response(l_response);
      logit(p_message=>'In exception in procedure newegg_get_request_id utl_http.too_many_requests'|| SUBSTR(SQLERRM,1,150));
    WHEN UTL_HTTP.end_of_body THEN
      utl_http.end_response(l_response);
      logit(p_message=>'In exception in procedure newegg_get_request_id UTL_HTTP.end_of_body'|| SUBSTR(SQLERRM,1,150));
    END;
    BEGIN
      INSERT
      INTO xx_ce_mktplc_pre_stg_files
        (
          rec_id ,
          file_name ,
          file_data ,
          status ,
          sqlldr_request_id ,
          creation_date ,
          created_by ,
          last_update_date ,
          last_update_login ,
          last_updated_by
        )
        VALUES
        (
          xx_ce_mkt_pre_stg_rec_s.nextval,
          DECODE(p_file_flag,'T',REPLACE(p_file_name,'.xml','_')
          ||p_settlement_id
          ||'_'
          ||i
          ||'.xml',p_file_name),
          lc_xmltype,
          'N',
          p_request_id,
          sysdate,
          fnd_global.user_id,
          sysdate,
          fnd_global.user_id,
          fnd_global.user_id
        );
      ----  l_insert_cnt:=sql%rowcount;
      COMMIT;
    EXCEPTION
    when others then
      logit(p_message=>'In exception for insert into xx_ce_mktplc_pre_stg_files '||sqlerrm);
    END;
    BEGIN
      SELECT COUNT(1),
        file_name
      INTO l_insert_cnt,
        v_file_name
      FROM xx_ce_mktplc_pre_stg_files
      WHERE TRUNC(creation_date)=TRUNC(sysdate)
      AND file_name LIKE '%'
        ||'_'
        ||p_settlement_id
        ||'_'
        ||i
        ||'.xml'
      AND file_name LIKE 'NEGGT%'
      AND status='N'
      GROUP BY file_name ;
    EXCEPTION
    WHEN OTHERS THEN
      l_insert_cnt:=0;
      logit(p_message=>'No file downloaded'||substr(SQLERRM,1,150));
    END;
    IF l_insert_cnt > 0 THEN
      logit(p_message=>'File '''||v_file_name||''' loaded successfully to xx_ce_mktplc_pre_stg_files table ');
      insert_file_rec( p_process_name => p_process_name, p_file_name => v_file_name,p_err_msg => NULL,p_process_flag=>'P',p_requestid=>p_request_id);
      XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file( p_file_name=>v_file_name, p_process_name=>p_process_name, p_request_id=>p_request_id );
    ELSE
      logit(p_message=>'File '''||v_file_name||''' load failed');
      insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => 'Error while parsing the file '||p_file_name,p_process_flag=>'E',p_requestid=>p_request_id);
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'In exception in procedure newegg_download_file_trxn '|| SUBSTR(sqlerrm,1,150));
END newegg_download_file_trxn;
PROCEDURE newegg_download_file_sum(
    p_process_name   VARCHAR2,
    p_api_request_id VARCHAR2,
    p_request_id     NUMBER,
    p_file_flag      VARCHAR2,
    p_file_name      VARCHAR2,
    p_settlement_id  VARCHAR2)
AS
  l_request utl_http.req;
  l_response utl_http.resp;
  lc_auth_payload VARCHAR2(32000);
  value           VARCHAR2(32000);
  v_xml_value xmltype;
  v_request_id        VARCHAR2(50);
  v_requeststatus     VARCHAR2(50);
  v_requeststatustrxn VARCHAR2(100);
  lclob_buffer CLOB;
  lc_buffer VARCHAR2(32767);
  --- lc_buffer raw(512);
  lc_xmltype xmltype;
  l_insert_cnt NUMBER;
  v_file_name  VARCHAR2(100);
  v_pade_index NUMBER:=0;
BEGIN
  BEGIN
    v_request_id   :=p_api_request_id;
    lc_auth_payload:='<NeweggAPIRequest>
<OperationType>SettlementSummaryReportRequest</OperationType>
<RequestBody>
<RequestID>'||v_request_id||'</RequestID>
</RequestBody>
</NeweggAPIRequest>';
    get_http_details(p_process_name);
    utl_http.set_wallet(gb_Walletpath, gb_walletpwd);
    utl_http.set_response_error_check ( enable => true );
    utl_http.set_detailed_excp_support ( enable => true );
    l_request := utl_http.begin_request(gb_url3, 'PUT', 'HTTP/1.1');
    utl_http.set_header(l_request, 'accept', 'application/xml');
    utl_http.set_header(l_request, 'authorization', gb_accesskeyid);
    utl_http.set_header(l_request, 'secretkey', gb_secretaccesskey);
    utl_http.set_header(l_request, 'user-agent', 'mozilla/4.0');
    UTL_HTTP.set_header(l_request, 'content-type', 'application/xml');
    utl_http.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
    utl_http.write_text(l_request, lc_auth_payload);
    l_response := utl_http.get_response(l_request);
    COMMIT;
    dbms_output.put_line( 'Response received from Newegg third URL '||l_response.status_code);
    --lclob_buffer := empty_clob;
    --*********************************
    dbms_lob.createtemporary(lob_loc => lclob_buffer, cache => true, dur => dbms_lob.call);
    -- -----------------------------------
    -- OPEN TEMPORARY LOB FOR READ / WRITE
    -- -----------------------------------
    dbms_lob.open(lob_loc => lclob_buffer, open_mode => dbms_lob.lob_readwrite);
    BEGIN
      LOOP
        utl_http.read_text(r => l_response, data => lc_buffer, LEN => 2000);
        dbms_lob.writeappend(lob_loc => lclob_buffer, amount => LENGTH(lc_buffer), buffer => lc_buffer);
      END LOOP;
    EXCEPTION
    WHEN utl_http.end_of_body THEN
      NULL;
    WHEN OTHERS THEN
      raise;
    END;
    lc_xmltype := xmltype(lclob_buffer);
    utl_http.end_response(l_response);
    logit(p_message => 'Response received from Newegg Third URL '||l_response.status_code);
  EXCEPTION
  WHEN utl_http.too_many_requests THEN
    utl_http.end_response(l_response);
    logit(p_message =>'In exception in procedure newegg_get_request_id utl_http.too_many_requests'|| SUBSTR(SQLERRM,1,150));
  WHEN UTL_HTTP.end_of_body THEN
    utl_http.end_response(l_response);
    logit(p_message =>'In exception in procedure newegg_get_request_id UTL_HTTP.end_of_body'|| SUBSTR(SQLERRM,1,150));
  END;
  BEGIN
    INSERT
    INTO xx_ce_mktplc_pre_stg_files
      (
        rec_id ,
        file_name ,
        file_data ,
        status ,
        sqlldr_request_id ,
        creation_date ,
        created_by ,
        last_update_date ,
        last_update_login ,
        last_updated_by
      )
      VALUES
      (
        xx_ce_mkt_pre_stg_rec_s.nextval,
        p_file_name,
        lc_xmltype,
        'N',
        p_request_id,
        sysdate,
        fnd_global.user_id,
        sysdate,
        fnd_global.user_id,
        fnd_global.user_id
      );
    ----  l_insert_cnt:=sql%rowcount;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    logit(p_message =>'In exception for insert  '||SQLERRM);
  END;
  BEGIN
    SELECT COUNT(1),
      file_name
    INTO l_insert_cnt,
      v_file_name
    FROM xx_ce_mktplc_pre_stg_files
    WHERE TRUNC(creation_date)=TRUNC(sysdate)
    AND file_name LIKE 'NEGGS%'
    AND status='N'
    GROUP BY file_name ;
  EXCEPTION
  WHEN OTHERS THEN
    l_insert_cnt:=0;
    logit(p_message =>'No file downloaded count '||l_insert_cnt);
  END;
  IF l_insert_cnt > 0 THEN
    logit(p_message =>'File '''||v_file_name||''' loaded successfully to xx_ce_mktplc_pre_stg_files table ');
    insert_file_rec( p_process_name => p_process_name, p_file_name => v_file_name,p_err_msg => NULL,p_process_flag=>'P',p_requestid=>p_request_id);
    XX_CE_MRKTPLC_FILE_DOWNLOAD.create_newegg_trx_file( p_file_name=>v_file_name, p_process_name=>p_process_name, p_request_id=>p_request_id );
  ELSE
    logit(p_message =>'File '''||v_file_name||''' load failed');
    insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => 'Error while parsing the file '||p_file_name,p_process_flag=>'E',p_requestid=>p_request_id);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'In exception in procedure newegg_download_file_sum '|| SUBSTR(sqlerrm,1,150));
END newegg_download_file_sum;
/**********************************************************************
* MAin procedure to download New Egg files using API
***********************************************************************/
PROCEDURE xx_ce_newegg_utl_https(
    p_process_name VARCHAR2,
    p_request_id   NUMBER,
    p_debug_flag   VARCHAR2,
    p_file_name    VARCHAR2 )
AS
  v_request_id        VARCHAR2 ( 50 ) ;
  v_requeststatustrxn VARCHAR2(50);
  CURSOR c_newegg_summary
  IS
    SELECT request_id,
      TO_CHAR(to_date(settlement_date_to,'MM/DD/YYYY HH24:MI:SS'),'YYYY-MM-DD') settlement_date_to,
      TO_CHAR(to_date(settlement_date_from,'MM/DD/YYYY HH24:MI:SS'),'YYYY-MM-DD') settlement_date_from,
      settlement_id_NEGGS settlement_id
    FROM xx_ce_newegg_sum_pre_stg_v
    WHERE REPORT_DATE=TRUNC(sysdate);
BEGIN
  set_debug( p_debug_flag );
  IF p_file_name LIKE 'NEGGS%' THEN
    ------Call to URL 1
    newegg_get_request_id(v_request_id,'S',p_process_name,NULL,NULL,NULL);
    ----Call to URL2
    IF v_request_id <>'XXX' THEN
      newegg_get_request_status(v_request_id,v_requeststatustrxn,p_process_name);
      IF v_requeststatustrxn='FINISHED' THEN
        -----Call to URL 3---
        newegg_download_file_sum(p_process_name,v_request_id,p_request_id,'S',p_file_name,NULL);
      END IF;
    END IF;
  END IF;
  IF p_file_name LIKE 'NEGGT%' THEN
    FOR i IN c_newegg_summary
    LOOP
      newegg_get_request_id(v_request_id,'T',p_process_name,i.settlement_date_from,i.settlement_date_to,i.settlement_id);
      ----Call to URL2
      IF v_request_id <>'XXX' THEN
        newegg_get_request_status(v_request_id,v_requeststatustrxn,p_process_name);
        IF v_requeststatustrxn='FINISHED' THEN
          -----Call to URL 3---
          newegg_download_file_trxn(p_process_name,v_request_id,p_request_id,'T',p_file_name,i.settlement_id);
        END IF;
      END IF;
    END LOOP;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'In Exception in procedure xx_ce_newegg_utl_https '|| SUBSTR(sqlerrm,1,150));
END xx_ce_newegg_utl_https;
END xx_ce_mrktplc_file_download;
/

SHOW ERRORS;