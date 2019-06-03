SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE body xx_ce_mrktplc_load_pkg
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_LOAD_PKG                                                             |
  -- |                                                                                            |
  -- |  Description: This package body is to Load MarketPlaces DataFiles                          |
  -- |  RICE ID   :  I3123_CM MarketPlaces Expansion                                              |
  -- |  Description:  Load Program for for all marketplaces                                       |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         05/23/2018   M K Pramod Kumar     Initial version                              |
  -- | 1.1         16-AUG-18   Priyam P              Request id parameter is added                |
  ---| 1.2        17-AUG-2018  Priyam P            Added logic for Archive and Purge process      |
  ---| 1.3        14-MAY-2019  sripal reddy mungi   NAIT-89187 -Added logic to discard            |
  -- |                                              Comma',' in amount column                     |
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%type := 'XX_CE_MRKTPLC_LOAD_PKG';
  gc_ret_success       CONSTANT VARCHAR2(20)                 := 'SUCCESS';
  gc_ret_no_data_found CONSTANT VARCHAR2(20)                 := 'NO_DATA_FOUND';
  gc_ret_too_many_rows CONSTANT VARCHAR2(20)                 := 'TOO_MANY_ROWS';
  gc_ret_api           CONSTANT VARCHAR2(20)                 := 'API';
  gc_ret_others        CONSTANT VARCHAR2(20)                 := 'OTHERS';
  gc_max_err_size      CONSTANT NUMBER                       := 2000;
  gc_max_sub_err_size  CONSTANT NUMBER                       := 256;
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_out_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;
  gb_debug             BOOLEAN                               := false;
type gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
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
  IF (gb_debug OR p_force) THEN
    lc_message                    := SUBSTR(TO_CHAR(systimestamp, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.log, lc_message);
    ELSE
      dbms_output.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
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
-- +============================================================================================+
-- |  Name  : parse                                                                 |
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse(
    p_delimstring IN VARCHAR2 ,
    p_table OUT varchar2_table ,
    p_nfields OUT INTEGER ,
    p_delim IN VARCHAR2 DEFAULT chr(
      9) ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_string VARCHAR2(32767) := p_delimstring;
  l_nfields pls_integer    := 1;
  l_table varchar2_table;
  l_delimpos pls_integer := instr(p_delimstring, p_delim);
  l_delimlen pls_integer := LENGTH(p_delim);
BEGIN
  WHILE l_delimpos > 0
  LOOP
    l_table(l_nfields) := SUBSTR(l_string,1,l_delimpos-1);
    l_string           := SUBSTR(l_string,l_delimpos  +l_delimlen);
    l_nfields          := l_nfields                   +1;
    l_delimpos         := instr(l_string, p_delim);
  END LOOP;
  l_table(l_nfields) := l_string;
  p_table            := l_table;
  p_nfields          := l_nfields;
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_CE_MRKTPLC_LOAD_PKG.parse - record:'||SUBSTR(p_delimstring,150)||SUBSTR(sqlerrm,1,150);
END parse;
/******************************************************************
* Archival procedure for Pre-Stage Tabe
* Pre-stage Table : xx_ce_ebay_trx_dtl_stg,xx_ce_ebay_ca_dtl_stg
* Archival Table : xx_ce_ebay_trx_dtl_stg_arch,xx_ce_ebay_ca_dtl_stg_arch
******************************************************************/
PROCEDURE archive_purge_process(
    p_days NUMBER )
AS
BEGIN
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Archival And Purge Process for last '||p_days||' days');
  INSERT INTO xx_ce_ebay_trx_dtl_stg_arch
  SELECT *
  FROM xx_ce_ebay_trx_dtl_stg
  WHERE report_date <= sysdate - p_days
  AND process_flag   = 'P';
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Archived for table xx_ce_ebay_trx_dtl_stg- '||sql%rowcount);
  INSERT INTO xx_ce_ebay_ca_dtl_stg_arch
  SELECT *
  FROM xx_ce_ebay_ca_dtl_stg
  WHERE report_date <= sysdate - p_days
  AND process_flag   = 'P';
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Archived for table xx_ce_ebay_ca_dtl_stg- '||sql%rowcount);
  DELETE
  FROM xx_ce_ebay_trx_dtl_stg
  WHERE report_date <= sysdate - p_days
  AND process_flag   = 'P';
  ---logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Purged for table xx_ce_ebay_trx_dtl_stg - '||sql%rowcount);
  DELETE
  FROM xx_ce_ebay_ca_dtl_stg
  WHERE report_date <= sysdate - p_days
  AND process_flag   = 'P';
  --- logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Purged for table xx_ce_ebay_ca_dtl_stg - '||sql%rowcount);
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Error - '||sqlerrm);
END ;
/******************************************************************
* file record creation for uplicate Check
* Table : XXCE_MKTPLC_FILE
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
END;
FUNCTION check_duplicate_file
  (
    p_file_name VARCHAR2
  )
  RETURN VARCHAR2
AS
  l_cnt NUMBER := 0;
BEGIN
  SELECT COUNT(file_name)
  INTO l_cnt
  FROM xx_ce_mpl_files
  WHERE file_name = p_file_name
  AND process_flag='P';
  IF l_cnt        > 0 THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message=> 'CHECK_DUPLICATE_FILE : Error - '||sqlerrm);
  RETURN 'Y';
END;
FUNCTION check_cuttoff_dt(
    p_file_type IN VARCHAR2,
    p_file_name IN VARCHAR2)
  RETURN VARCHAR2
AS
  --  v_tdr_file     VARCHAR2(100):='TRR-20180724.01.011.TAB';
  --  v_ca_file      VARCHAR2(100):='Finance_Report_eBay_07291880908.csv';
  lc_cutoff      VARCHAR2( 20);
  ld_cutoff_date DATE;
  ld_tdr_date    DATE;
  ld_ca_date     DATE;
  lc_ca          VARCHAR2(10);
  l_valid_file   VARCHAR2(1) := 'N';
BEGIN
  BEGIN
    SELECT xftv.target_value19
    INTO lc_cutoff
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = 'EBAY_MPL'
    AND xftd.translate_id       =xftv.translate_id;
  EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('When othres in trans :'||sqlerrm);
    lc_cutoff:=TO_CHAR(sysdate,'DD-MON-YYYY');
  END;
  ld_cutoff_date:=to_date(lc_cutoff);
  dbms_output.put_line('Cut off Date :'||TO_CHAR(ld_cutoff_date,'DD-MON-YYYY'));
  IF p_file_type = 'TDR' THEN
    --  LD_TDR_DATE :=TO_DATE(SUBSTR(V_TDR_FILE,5,8),'YYYYMMDD');
    ld_tdr_date :=to_date(SUBSTR(p_file_name,5,8),'YYYYMMDD');
    dbms_output.put_line('TDR File Date :'||TO_CHAR(ld_tdr_date,'DD-MON-YYYY'));
    IF ld_tdr_date>=ld_cutoff_date THEN
      dbms_output.put_line('TDR File will be processed');
      l_valid_file := 'Y';
    ELSE
      dbms_output.put_line('TDR File will not be processed');
      l_valid_file := 'N';
    END IF;
  END IF;
  IF p_file_type = 'CA' THEN
    --LC_CA       :=SUBSTR(V_CA_FILE,21,6);
    lc_ca :=SUBSTR(p_file_name,21,6);
    dbms_output.put_line('CA :'||lc_ca);
    --  LD_CA_DATE:=TO_DATE(SUBSTR(V_CA_FILE,21,6),'MMDDRR');
    ld_ca_date:=to_date(SUBSTR(p_file_name,21,6),'MMDDRR');
    dbms_output.put_line('CA File Date :'||TO_CHAR(ld_ca_date,'DD-MON-YYYY'));
    IF ld_ca_date>=ld_cutoff_date THEN
      dbms_output.put_line('CA File will be processed');
      l_valid_file := 'Y';
    ELSE
      dbms_output.put_line('CA File will not be processed');
      l_valid_file := 'N';
    END IF;
  END IF;
  RETURN l_valid_file;
END check_cuttoff_dt;
PROCEDURE insert_pre_stg_excpn(
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
    p_attribute100 VARCHAR2 DEFAULT NULL )
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
PROCEDURE load_ebay_files
  (
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_file_type    VARCHAR2,
    ---  p_conc_program VARCHAR2,
    p_debug_flag VARCHAR2,
    p_request_id NUMBER
  )
AS
  CURSOR dup_check_cur
    (
      p_transaction_id VARCHAR2
    )
  IS
    SELECT transaction_id
    FROM xx_ce_ebay_trx_dtl_stg
    WHERE transaction_id = p_transaction_id;
  CURSOR dup_check_cur_ca(p_transaction_id VARCHAR2,p_order_id VARCHAR2,p_sku VARCHAR2)
  IS
    SELECT merchant_reference_number
    FROM xx_ce_ebay_ca_dtl_stg
    WHERE merchant_reference_number = p_transaction_id
    AND channel_advisor_order_id    =p_order_id
    AND sku                         =p_sku;
  l_filehandle utl_file.file_type;
  l_filedir VARCHAR2(20) := 'XXFIN_INBOUND_MPL';
  l_dirpath VARCHAR2(500);
  l_newline VARCHAR2(4000); -- Input line
  l_max_linesize binary_integer := 32767;
  l_user_id    NUMBER              := fnd_global.user_id;
  l_login_id   NUMBER              := fnd_global.login_id;
  l_request_id NUMBER              := fnd_global.conc_request_id;
  l_rec_cnt    NUMBER              := 0;
  l_table varchar2_table;
  l_nfields            INTEGER;
  l_error_msg          VARCHAR2(1000) := NULL;
  l_error_loc          VARCHAR2(2000) := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_files';
  l_retcode            VARCHAR2(3)    := NULL;
  l_ajb_file_name      VARCHAR2(200);
  parse_exception      EXCEPTION;
  dup_exception        EXCEPTION;
  l_dup_transaction_id VARCHAR2(50);
  /*staging table columns*/
  l_recordtype                VARCHAR2(10 );
  l_transactionid             VARCHAR2(150 );
  l_invoiceid                 VARCHAR2(150 );
  l_paypalreferenceid         VARCHAR2(150 );
  l_paypalreferenceidtype     VARCHAR2(150 );
  l_transactioneventcode      VARCHAR2(150 );
  l_transactioninitiationdate VARCHAR2(50 );
  l_transactioncompletiondate VARCHAR2(50 );
  l_transactiondebitorcredit  VARCHAR2(150 );
  l_grosstransactionamount    NUMBER;
  l_grosstransactioncurrency  VARCHAR2(150 );
  l_feedebitorcredit          VARCHAR2(150 );
  l_feeamount                 NUMBER;
  l_feecurrency               VARCHAR2(150 );
  l_transactionalstatus       VARCHAR2(150 );
  l_insuranceamount           NUMBER;
  l_salestaxamount            NUMBER;
  l_shippingamount            NUMBER;
  l_transactionsubject        VARCHAR2(150 );
  l_transactionnote           VARCHAR2(150 );
  l_payersaccountid           VARCHAR2(150 );
  l_payeraddressstatus        VARCHAR2(150 );
  l_itemname                  VARCHAR2(150 );
  l_itemid                    VARCHAR2(150 );
  l_option1name               VARCHAR2(150 );
  l_option1value              VARCHAR2(150 );
  l_option2name               VARCHAR2(150 );
  l_option2value              VARCHAR2(150 );
  l_auctionsite               VARCHAR2(150 );
  l_auctionbuyerid            VARCHAR2(150 );
  l_auctionclosingdate        VARCHAR2(50 );
  l_shippingaddressline1      VARCHAR2(150 );
  l_shippingaddressline2      VARCHAR2(150 );
  l_shippingaddresscity       VARCHAR2(150 );
  l_shippingaddressstate      VARCHAR2(150 );
  l_shippingaddresszip        VARCHAR2(150 );
  l_shippingaddresscountry    VARCHAR2(150 );
  l_shippingmethod            VARCHAR2(150 );
  l_customfield               VARCHAR2(150 );
  l_billingaddressline1       VARCHAR2(150 );
  l_billingaddressline2       VARCHAR2(150 );
  l_billingaddresscity        VARCHAR2(150 );
  l_billingaddressstate       VARCHAR2(150 );
  l_billingaddresszip         VARCHAR2(150 );
  l_billingaddresscountry     VARCHAR2(150 );
  l_consumerid                VARCHAR2(150 );
  l_firstname                 VARCHAR2(150 );
  l_lastname                  VARCHAR2(150 );
  l_consumerbusinessname      VARCHAR2(150 );
  l_cardtype                  VARCHAR2(150 );
  l_paymentsource             VARCHAR2(150 );
  l_shippingname              VARCHAR2(150 );
  l_authorizationreviewstatus VARCHAR2(150 );
  l_protectioneligibility     VARCHAR2(150 );
  l_paymenttrackingid         VARCHAR2(150 );
  l_storeid                   VARCHAR2(150 );
  l_terminalid                VARCHAR2(150 );
  l_coupons                   VARCHAR2(150 );
  l_specialoffers             VARCHAR2(150 );
  l_loyaltycardnumber         VARCHAR2(150 );
  l_checkouttype              VARCHAR2(150 );
  l_secshippingaddressline1   VARCHAR2(150 );
  l_secshippingaddressline2   VARCHAR2(150 );
  l_secshippingaddresscity    VARCHAR2(150 );
  l_secshippingaddressstate   VARCHAR2(150 );
  l_secshippingaddresscntry   VARCHAR2(150 );
  l_secshippingaddresszip     VARCHAR2(150 );
  l_threeplreferenceid        VARCHAR2(150 );
  l_giftcardid                VARCHAR2(250);
  l_report_date               DATE;
  l_filename                  VARCHAR2(150 );
  l_attribute1                VARCHAR2(150 );
  l_attribute2                VARCHAR2(150 );
  l_attribute3                VARCHAR2(150 );
  l_attribute4                VARCHAR2(150 );
  l_attribute5                VARCHAR2(150 );
  l_process_flag_tdr          VARCHAR2(150 ):='N';
  -----For CA
  l_sitename                VARCHAR2(100);
  l_sellerorderid           VARCHAR2(100);
  l_channeladvisororderid   VARCHAR2(100);
  l_merchantreferencenumber VARCHAR2(100);
  l_buyeruserid             VARCHAR2(250);
  l_paymentstatus           VARCHAR2(50);
  l_shippingstatus          VARCHAR2(50);
  l_refundstatus            VARCHAR2(50);
  l_sku                     VARCHAR2(250);
  l_unitprice               NUMBER;
  l_quantity                NUMBER;
  l_itemtax                 NUMBER;
  l_itemshippingprice       NUMBER;
  l_itemshippingtax         NUMBER;
  l_totalshippingtaxprice   NUMBER;
  l_totaltaxprice           NUMBER;
  l_totalshippingprice      NUMBER;
  l_ordertotal              NUMBER;
  l_report_date             DATE;
  l_filename                VARCHAR2(50);
  l_attribute1              VARCHAR2(150);
  l_attribute2              VARCHAR2(150);
  l_attribute3              VARCHAR2(150);
  l_attribute4              VARCHAR2(150);
  l_attribute5              VARCHAR2(150);
  l_process_flag_ca         VARCHAR2(150 ):='N';
  l_err_msg                 VARCHAR2(500 );
  l_archive_days            NUMBER;
BEGIN
  p_retcode :=0;
  -- Cut-off Date check
  IF check_cuttoff_dt( p_file_type, p_file_name) = 'Y' THEN
    IF check_duplicate_file(p_file_name)         = 'N' THEN
      IF p_file_type                             ='TDR' THEN
        BEGIN
          logit(p_message=>'start load_staging from file:'||p_file_name);
          l_filehandle := utl_file.fopen(l_filedir,p_file_name,'r',l_max_linesize);
          logit(p_message=>'File Directory path' || l_filedir);
          logit(p_message=>'File open successfull');
          LOOP
            BEGIN
              l_retcode         := NULL;
              l_error_msg       :=NULL;
              l_process_flag_tdr:='N';
              utl_file.get_line(l_filehandle,l_newline);
              IF l_newline IS NULL THEN
                EXIT;
              ELSE
                l_newline := REPLACE(l_newline,'"','');
              END IF;
              /*skip parsing the header labels record*/
              CONTINUE
            WHEN SUBSTR(l_newline,1,2) <> 'SB';
              parse(l_newline,l_table,l_nfields,chr(9),l_error_msg,l_retcode);
              IF l_retcode = '2' THEN
                raise parse_exception;
              END IF;
              BEGIN
                l_recordtype   :=l_table(1);
                l_transactionid:=l_table(2);
                /* check for duplicate using the first data record*/
                IF l_rec_cnt            = 0 THEN
                  l_dup_transaction_id := NULL;
                  OPEN dup_check_cur(l_transactionid);
                  FETCH dup_check_cur INTO l_dup_transaction_id;
                  CLOSE dup_check_cur;
                  IF l_dup_transaction_id IS NOT NULL THEN
                    l_error_msg           := 'DUPLICATE ERROR - TransactionId:'||l_transactionid||') already exists in staging XX_CE_EBAY_TRX_DTL_STG table';
                    xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , p_request_id, sysdate, l_error_msg , p_file_name, 'F') ;
                    l_process_flag_tdr :='E';
                    logit(p_message=>l_error_msg);
                    ----  raise  dup_exception;
                  END IF;
                END IF;
                l_recordtype                :=l_table(1);
                l_transactionid             :=l_table(2);
                l_invoiceid                 :=l_table(3);
                l_paypalreferenceid         :=l_table(4);
                l_paypalreferenceidtype     :=l_table(5);
                l_transactioneventcode      :=l_table(6);
                l_transactioninitiationdate :=l_table(7);
                l_transactioncompletiondate :=l_table(8);
                l_transactiondebitorcredit  :=l_table(9);
                l_grosstransactionamount    :=l_table(10);
                l_grosstransactioncurrency  :=l_table(11);
                l_feedebitorcredit          :=l_table(12);
                l_feeamount                 :=l_table(13);
                l_feecurrency               :=l_table(14);
                l_transactionalstatus       :=l_table(15);
                l_insuranceamount           :=l_table(16);
                l_salestaxamount            :=l_table(17);
                l_shippingamount            :=l_table(18);
                l_transactionsubject        :=l_table(19);
                l_transactionnote           :=l_table(20);
                l_payersaccountid           :=l_table(21);
                l_payeraddressstatus        :=l_table(22);
                l_itemname                  :=l_table(23);
                l_itemid                    :=l_table(24);
                l_option1name               :=l_table(25);
                l_option1value              :=l_table(26);
                l_option2name               :=l_table(27);
                l_option2value              :=l_table(28);
                l_auctionsite               :=l_table(29);
                l_auctionbuyerid            :=l_table(30);
                l_auctionclosingdate        :=l_table(31);
                l_shippingaddressline1      :=l_table(32);
                l_shippingaddressline2      :=l_table(33);
                l_shippingaddresscity       :=l_table(34);
                l_shippingaddressstate      :=l_table(35);
                l_shippingaddresszip        :=l_table(36);
                l_shippingaddresscountry    :=l_table(37);
                l_shippingmethod            :=l_table(38);
                l_customfield               :=l_table(39);
                l_billingaddressline1       :=l_table(40);
                l_billingaddressline2       :=l_table(41);
                l_billingaddresscity        :=l_table(42);
                l_billingaddressstate       :=l_table(43);
                l_billingaddresszip         :=l_table(44);
                l_billingaddresscountry     :=l_table(45);
                l_consumerid                :=l_table(46);
                l_firstname                 :=l_table(47);
                l_lastname                  :=l_table(48);
                l_consumerbusinessname      :=l_table(49);
                l_cardtype                  :=l_table(50);
                l_paymentsource             :=l_table(51);
                l_shippingname              :=l_table(52);
                l_authorizationreviewstatus :=l_table(53);
                l_protectioneligibility     :=l_table(54);
                l_paymenttrackingid         :=l_table(55);
                l_storeid                   :=l_table(56);
                l_terminalid                :=l_table(57);
                l_coupons                   :=l_table(58);
                l_specialoffers             :=l_table(59);
                l_loyaltycardnumber         :=l_table(60);
                l_checkouttype              :=l_table(61);
                l_secshippingaddressline1   :=l_table(62);
                l_secshippingaddressline2   :=l_table(63);
                l_secshippingaddresscity    :=l_table(64);
                l_secshippingaddressstate   :=l_table(65);
                l_secshippingaddresscntry   :=l_table(66);
                l_secshippingaddresszip     :=l_table(67);
                l_threeplreferenceid        :=l_table(68);
                l_giftcardid                :=l_table(69);
                INSERT
                INTO xx_ce_ebay_trx_dtl_stg
                  (
                    record_type,
                    transaction_id,
                    invoice_id,
                    pay_pal_reference_id ,
                    pay_pal_reference_id_type ,
                    transaction_event_code,
                    transaction_initiation_date,
                    transaction_completion_date,
                    transaction_debitorcredit,
                    gross_transaction_amount,
                    gross_transaction_currency,
                    fee_debitorcredit,
                    fee_amount,
                    fee_currency,
                    transactional_status,
                    insurance_amount,
                    sales_tax_amount,
                    shipping_amount,
                    transaction_subject,
                    transaction_note,
                    payers_account_id,
                    payer_address_status,
                    item_name,
                    item_id,
                    option1_name,
                    option1_value,
                    option2_name,
                    option2_value,
                    auction_site,
                    auction_buyerid,
                    auction_closing_date,
                    shipping_address_line1,
                    shipping_address_line2,
                    shipping_address_city,
                    shipping_address_state,
                    shipping_address_zip,
                    shipping_address_country,
                    shipping_method,
                    custom_field,
                    billing_address_line1,
                    billing_address_line2,
                    billing_address_city,
                    billing_address_state,
                    billing_address_zip,
                    billing_address_country,
                    consumer_id,
                    first_name,
                    last_name,
                    consumer_business_name,
                    card_type,
                    payment_source,
                    shipping_name,
                    authorization_review_status,
                    protection_eligibility,
                    payment_tracking_id,
                    store_id,
                    terminal_id,
                    coupons,
                    special_offers,
                    loyalty_cardnumber,
                    checkout_type,
                    sec_shipping_address_line1,
                    sec_shipping_address_line2,
                    sec_shipping_address_city,
                    sec_shipping_address_state,
                    sec_shipping_address_cntry,
                    sec_shipping_address_zip,
                    threepl_reference_id,
                    giftcardid,
                    report_date,
                    filename,
                    attribute1,
                    attribute2,
                    attribute3,
                    attribute4,
                    attribute5,
                    process_flag,
                    err_msg
                  )
                  VALUES
                  (
                    l_recordtype,
                    l_transactionid,
                    l_invoiceid,
                    l_paypalreferenceid,
                    l_paypalreferenceidtype,
                    l_transactioneventcode,
                    l_transactioninitiationdate,
                    l_transactioncompletiondate,
                    l_transactiondebitorcredit,
                    l_grosstransactionamount,
                    l_grosstransactioncurrency,
                    l_feedebitorcredit,
                    l_feeamount,
                    l_feecurrency,
                    l_transactionalstatus,
                    l_insuranceamount,
                    l_salestaxamount,
                    l_shippingamount,
                    l_transactionsubject,
                    l_transactionnote,
                    l_payersaccountid,
                    l_payeraddressstatus,
                    l_itemname,
                    l_itemid,
                    l_option1name,
                    l_option1value,
                    l_option2name,
                    l_option2value,
                    l_auctionsite,
                    l_auctionbuyerid,
                    l_auctionclosingdate,
                    l_shippingaddressline1,
                    l_shippingaddressline2,
                    l_shippingaddresscity,
                    l_shippingaddressstate,
                    l_shippingaddresszip,
                    l_shippingaddresscountry,
                    l_shippingmethod,
                    l_customfield,
                    l_billingaddressline1,
                    l_billingaddressline2,
                    l_billingaddresscity,
                    l_billingaddressstate,
                    l_billingaddresszip,
                    l_billingaddresscountry,
                    l_consumerid,
                    l_firstname,
                    l_lastname,
                    l_consumerbusinessname,
                    l_cardtype,
                    l_paymentsource,
                    l_shippingname,
                    l_authorizationreviewstatus,
                    l_protectioneligibility,
                    l_paymenttrackingid,
                    l_storeid,
                    l_terminalid,
                    l_coupons,
                    l_specialoffers,
                    l_loyaltycardnumber,
                    l_checkouttype,
                    l_secshippingaddressline1,
                    l_secshippingaddressline2,
                    l_secshippingaddresscity,
                    l_secshippingaddressstate,
                    l_secshippingaddresscntry,
                    l_secshippingaddresszip,
                    l_threeplreferenceid,
                    l_giftcardid,
                    sysdate,             --REPORT_DATE,
                    p_file_name,        ---FILENAME,
                    p_request_id,        --ATTRIBUTE1,
                    NULL,                --ATTRIBUTE2,
                    NULL,                --ATTRIBUTE3,
                    NULL,                --ATTRIBUTE4,
                    NULL,                --ATTRIBUTE5,
                    l_process_flag_tdr, ---PROCESS_FLAG
                    l_error_msg
                  );
                l_rec_cnt := l_rec_cnt + 1;
              EXCEPTION
              WHEN OTHERS THEN
                xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn( p_process_name =>p_process_name, p_request_id =>p_request_id, p_report_date => sysdate, p_err_msg=>SUBSTR(sqlerrm,1,150),p_file_name=>p_file_name, p_record_type=>'D', p_attribute1=>SUBSTR(l_table(1),1,150), p_attribute2=>SUBSTR(l_table(2),1,150), p_attribute3=>SUBSTR(l_table(3),1,150), p_attribute4=>SUBSTR(l_table(4),1,150), p_attribute5=>SUBSTR(l_table(5),1,150), p_attribute6=>SUBSTR(l_table(6),1,150), p_attribute7=>SUBSTR(l_table(7),1,150), p_attribute8=>SUBSTR(l_table(8),1,150), p_attribute9=>SUBSTR(l_table(9),1,150), p_attribute10=>SUBSTR(l_table(10),1,150), p_attribute11=>SUBSTR(l_table(11),1,150), p_attribute12=>SUBSTR(l_table(12),1,150), p_attribute13=>SUBSTR(l_table(13),1,150), p_attribute14=>SUBSTR(l_table(14),1,150), p_attribute15=>SUBSTR(l_table(15),1,150), p_attribute16=>SUBSTR(l_table(16),1,150), p_attribute17=>SUBSTR(l_table(17),1,150), p_attribute18=>SUBSTR(l_table(18),1,150), p_attribute19=>SUBSTR(l_table(
                19),1,150), p_attribute20 => SUBSTR(l_table(20),1,150), p_attribute21=>SUBSTR(l_table(21),1,150), p_attribute22=>SUBSTR(l_table(22),1,150), p_attribute23=>SUBSTR(l_table(23),1,150), p_attribute24=>SUBSTR(l_table(24),1,150), p_attribute25=>SUBSTR(l_table(25),1,150), p_attribute26=>SUBSTR(l_table(26),1,150), p_attribute27=>SUBSTR(l_table(27),1,150), p_attribute28=>SUBSTR(l_table(28),1,150), p_attribute29=>SUBSTR(l_table(29),1,150), p_attribute30=>SUBSTR(l_table(30),1,150), p_attribute31=>SUBSTR(l_table(31),1,150), p_attribute32=>SUBSTR(l_table(32),1,150), p_attribute33=>SUBSTR(l_table(33),1,150), p_attribute34=>SUBSTR(l_table(34),1,150), p_attribute35=>SUBSTR(l_table(35),1,150), p_attribute36=>SUBSTR(l_table(36),1,150), p_attribute37=>SUBSTR(l_table(37),1,150), p_attribute38=>SUBSTR(l_table(38),1,150), p_attribute39=>SUBSTR(l_table(39),1,150), p_attribute40=>SUBSTR(l_table(40),1,150), p_attribute41=>SUBSTR(l_table(41),1,150), p_attribute42=>SUBSTR(l_table(42),1,150),
                p_attribute43 =>SUBSTR( l_table(43),1, 150), p_attribute44=>SUBSTR(l_table(44),1,150), p_attribute45=>SUBSTR(l_table(45),1,150), p_attribute46=>SUBSTR(l_table(46),1,150), p_attribute47=>SUBSTR(l_table(47),1,150), p_attribute48=>SUBSTR(l_table(48),1,150), p_attribute49=>SUBSTR(l_table(49),1,150), p_attribute50=>SUBSTR(l_table(50),1,150), p_attribute51=>SUBSTR(l_table(51),1,150), p_attribute52=>SUBSTR(l_table(52),1,150), p_attribute53=>SUBSTR(l_table(53),1,150), p_attribute54=>SUBSTR(l_table(54),1,150), p_attribute55=>SUBSTR(l_table(55),1,150), p_attribute56=>SUBSTR(l_table(56),1,150), p_attribute57=>SUBSTR(l_table(57),1,150), p_attribute58=>SUBSTR(l_table(58),1,150), p_attribute59=>SUBSTR(l_table(59),1,150), p_attribute60=>SUBSTR(l_table(60),1,150), p_attribute61=>SUBSTR(l_table(61),1,150), p_attribute62=>SUBSTR(l_table(62),1,150), p_attribute63=>SUBSTR(l_table(63),1,150), p_attribute64=>SUBSTR(l_table(64),1,150), p_attribute65=>SUBSTR(l_table(65),1,150), p_attribute66
                =>SUBSTR( l_table(66),1, 150), p_attribute67=> SUBSTR(l_table(67),1,150), p_attribute68=>SUBSTR(l_table(68),1,150), p_attribute69=>SUBSTR(l_table(69),1,150) );
                --- INSERT_FILE_REC( P_PROCESS_NAME => P_PROCESS_NAME, P_FILE_NAME => P_FILE_NAME,P_ERR_MSG => SUBSTR(sqlerrm,1,150),P_PROCESS_FLAG=>'E',P_REQUESTID=>P_REQUEST_ID);
              END;
            EXCEPTION
            WHEN no_data_found THEN
              EXIT;
            END;
          END LOOP;
          utl_file.fclose(l_filehandle);
          IF l_rec_cnt >0 THEN
            insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => NULL,p_process_flag=>'P',p_requestid=>p_request_id) ;
            logit(p_message=>TO_CHAR(l_rec_cnt)||' Records successfully loaded into staging for File '||p_file_name);
          ELSE
            logit(p_message=>'Error in Parsing file: '||p_file_name);
            insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => 'Error in Parsing file: '||p_file_name,p_process_flag=>'E',p_requestid=>p_request_id);
          END IF;
          COMMIT;
        EXCEPTION
        WHEN dup_exception THEN
          p_errbuf  := l_error_msg;
          p_retcode := '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
        WHEN parse_exception THEN
          ROLLBACK;
          p_errbuf  := l_error_msg;
          p_retcode := l_retcode;
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_operation THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Operation TDR';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_filehandle THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid File Handle';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , p_request_id, sysdate, p_errbuf , p_file_name, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.read_error THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Read Error';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_path THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Path';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_mode THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Mode';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.internal_error THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Internal Error';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN value_error THEN
          ROLLBACK;
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES'||SUBSTR(sqlerrm,1,250);
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          /* INSERT_PRE_STG_EXCPN( P_PROCESS_NAME =>P_PROCESS_NAME, P_REQUEST_ID =>P_REQUEST_ID, P_REPORT_DATE => SYSDATE, P_ERR_MSG=>P_ERRBUF,P_FILE_NAME=>P_FILE_NAME, P_RECORD_TYPE=>'F', P_ATTRIBUTE1=>SUBSTR(L_TABLE(1),1,150), P_ATTRIBUTE2=>SUBSTR(L_TABLE(2),1,150), P_ATTRIBUTE3=>SUBSTR(L_TABLE(3),1,150), P_ATTRIBUTE4=>SUBSTR(L_TABLE(4),1,150), P_ATTRIBUTE5=>SUBSTR(L_TABLE(5),1,150), P_ATTRIBUTE6=>SUBSTR(L_TABLE(6),1,150), P_ATTRIBUTE7=>SUBSTR(L_TABLE(7),1,150), P_ATTRIBUTE8=>SUBSTR(L_TABLE(8),1,150), P_ATTRIBUTE9=>SUBSTR(L_TABLE(9),1,150), P_ATTRIBUTE10=>SUBSTR(L_TABLE(10),1,150), P_ATTRIBUTE11=>SUBSTR(L_TABLE(11),1,150), P_ATTRIBUTE12=>SUBSTR(L_TABLE(12),1,150), P_ATTRIBUTE13=>SUBSTR(L_TABLE(13),1,150), P_ATTRIBUTE14=>SUBSTR(L_TABLE(14),1,150), P_ATTRIBUTE15=>SUBSTR(L_TABLE(15),1,150), P_ATTRIBUTE16=>SUBSTR(L_TABLE(16),1,150), P_ATTRIBUTE17=>SUBSTR(L_TABLE(17),1,150), P_ATTRIBUTE18=>SUBSTR(L_TABLE(18),1,150), P_ATTRIBUTE19=>SUBSTR(L_TABLE(19),1,150), P_ATTRIBUTE20=> SUBSTR(
          L_TABLE(
          20),1,150), P_ATTRIBUTE21=>SUBSTR(L_TABLE(21),1,150), P_ATTRIBUTE22=>SUBSTR(L_TABLE(22),1,150), P_ATTRIBUTE23=>SUBSTR(L_TABLE(23),1,150), P_ATTRIBUTE24=>SUBSTR(L_TABLE(24),1,150), P_ATTRIBUTE25=>SUBSTR(L_TABLE(25),1,150), P_ATTRIBUTE26=>SUBSTR(L_TABLE(26),1,150), P_ATTRIBUTE27=>SUBSTR(L_TABLE(27),1,150), P_ATTRIBUTE28=>SUBSTR(L_TABLE(28),1,150), P_ATTRIBUTE29=>SUBSTR(L_TABLE(29),1,150), P_ATTRIBUTE30=>SUBSTR(L_TABLE(30),1,150), P_ATTRIBUTE31=>SUBSTR(L_TABLE(31),1,150), P_ATTRIBUTE32=>SUBSTR(L_TABLE(32),1,150), P_ATTRIBUTE33=>SUBSTR(L_TABLE(33),1,150), P_ATTRIBUTE34=>SUBSTR(L_TABLE(34),1,150), P_ATTRIBUTE35=>SUBSTR(L_TABLE(35),1,150), P_ATTRIBUTE36=>SUBSTR(L_TABLE(36),1,150), P_ATTRIBUTE37=>SUBSTR(L_TABLE(37),1,150), P_ATTRIBUTE38=>SUBSTR(L_TABLE(38),1,150), P_ATTRIBUTE39=>SUBSTR(L_TABLE(39),1,150), P_ATTRIBUTE40=>SUBSTR(L_TABLE(40),1,150), P_ATTRIBUTE41=>SUBSTR(L_TABLE(41),1,150), P_ATTRIBUTE42=>SUBSTR(L_TABLE(42),1,150), P_ATTRIBUTE43 =>SUBSTR(L_TABLE(43),1, 150),
          P_ATTRIBUTE44=>SUBSTR(L_TABLE(44),1,150), P_ATTRIBUTE45=>SUBSTR(L_TABLE(45),1,150), P_ATTRIBUTE46=>SUBSTR(L_TABLE(46),1,150), P_ATTRIBUTE47=>SUBSTR(L_TABLE(47),1,150), P_ATTRIBUTE48=>SUBSTR(L_TABLE(48),1,150), P_ATTRIBUTE49=>SUBSTR(L_TABLE(49),1,150), P_ATTRIBUTE50=>SUBSTR(L_TABLE(50),1,150), P_ATTRIBUTE51=>SUBSTR(L_TABLE(51),1,150), P_ATTRIBUTE52=>SUBSTR(L_TABLE(52),1,150), P_ATTRIBUTE53=>SUBSTR(L_TABLE(53),1,150), P_ATTRIBUTE54=>SUBSTR(L_TABLE(54),1,150), P_ATTRIBUTE55=>SUBSTR(L_TABLE(55),1,150), P_ATTRIBUTE56=>SUBSTR(L_TABLE(56),1,150), P_ATTRIBUTE57=>SUBSTR(L_TABLE(57),1,150), P_ATTRIBUTE58=>SUBSTR(L_TABLE(58),1,150), P_ATTRIBUTE59=>SUBSTR(L_TABLE(59),1,150), P_ATTRIBUTE60=>SUBSTR(L_TABLE(60),1,150), P_ATTRIBUTE61=>SUBSTR(L_TABLE(61),1,150), P_ATTRIBUTE62=>SUBSTR(L_TABLE(62),1,150), P_ATTRIBUTE63=>SUBSTR(L_TABLE(63),1,150), P_ATTRIBUTE64=>SUBSTR(L_TABLE(64),1,150), P_ATTRIBUTE65=>SUBSTR(L_TABLE(65),1,150), P_ATTRIBUTE66=>SUBSTR( L_TABLE(66),1,150), P_ATTRIBUTE67=>
          SUBSTR(L_TABLE(67),1,150), P_ATTRIBUTE68=>SUBSTR(L_TABLE(68),1,150), P_ATTRIBUTE69=>SUBSTR(L_TABLE(69),1,150) );*/
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN OTHERS THEN
          ROLLBACK;
          utl_file.fclose(l_filehandle);
          p_retcode:= '1';
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES:'||SUBSTR(sqlerrm,1,250);
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ----  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        END;
      END IF;
    ELSE
      logit(p_message => p_file_name ||' : File processed in prior run');
    END IF;
    IF p_retcode=0 THEN
      p_retcode:=0;
    END IF;
    IF check_duplicate_file(p_file_name) = 'N' THEN
      IF p_file_type                     ='CA' THEN
        BEGIN
          logit(p_message=>'start load_staging from file:'||p_file_name);
          l_filehandle := utl_file.fopen(l_filedir,p_file_name,'r',l_max_linesize);
          logit(p_message=>'File open successfull');
          LOOP
            BEGIN
              utl_file.get_line(l_filehandle,l_newline);
              l_newline    :=REPLACE (l_newline,chr(34),'');
              IF l_newline IS NULL THEN
                EXIT;
              ELSE
                l_newline :=REPLACE(l_newline,'$','');
              END IF;
              /*skip parsing the header labels record*/
              CONTINUE
              ---    LOGIT(P_MESSAGE=>SUBSTR(l_newline,1,4));
            WHEN upper(SUBSTR(l_newline,1,4))!= upper('eBay') ;
              parse(l_newline,l_table,l_nfields,chr(124),l_error_msg,l_retcode);---chr(9)
              BEGIN
                l_channeladvisororderid  :=l_table(3);
                l_merchantreferencenumber:=l_table(4);
                l_sku                    :=l_table(8);
                l_dup_transaction_id     := NULL;
                OPEN dup_check_cur_ca(l_merchantreferencenumber,l_channeladvisororderid,l_sku);
                FETCH dup_check_cur_ca INTO l_dup_transaction_id;
                CLOSE dup_check_cur_ca;
                IF l_dup_transaction_id IS NOT NULL THEN
                  l_error_msg           := 'DUPLICATE ERROR - TransactionId:'||l_merchantreferencenumber||') already exists in staging XX_CE_EBAY_CA_DTL_STG table';
                  xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , p_request_id, sysdate, l_error_msg , p_file_name, 'F');
                  l_process_flag_ca :='E';
                  logit(p_message=>l_error_msg);
                END IF;
                ---   write_log('After Parse');
                IF l_retcode = '2' THEN
                  ----   write_log('Inside Parse Exception');
                  raise parse_exception;
                END IF;
                ----  IF l_rec_cnt                = 0 THEN
                l_retcode       := NULL;
                l_error_msg     := NULL;
                l_sitename      :=l_table(1);
                l_sellerorderid :=l_table(2);
                --  l_ChannelAdvisorOrderID  :=l_table(3);
                ---  l_MerchantReferenceNumber:=l_table(4);
                ---  l_BuyerUserID            :=l_table(5);
                l_paymentstatus  :=l_table(5);
                l_shippingstatus :=l_table(6);
                l_refundstatus   :=l_table(7);
                -- l_SKU                   :=l_table(8);
                l_unitprice             :=l_table(9);
                l_quantity              :=l_table(10);
                l_itemtax               :=l_table(11);
                l_itemshippingprice     :=l_table(12);
                l_itemshippingtax       :=l_table(13);
                l_totalshippingtaxprice :=l_table(14);
                l_totaltaxprice         :=l_table(15);
                l_totalshippingprice    :=l_table(16);
               -- l_ordertotal          :=REPLACE(REPLACE(l_table(17), chr(13), ''), chr(10), '');  --Commented for NAIT-89187
                   l_ordertotal         := to_number(REPLACE(REPLACE(REPLACE(l_table(17), chr(13), ''), chr(10), ''),chr(44), '')); --added for NAIT-89187
                ---l_ordertotal         :=l_table(17);
                ----to_number(replace(l_table(17),chr(10)||chr(13),''));
                INSERT
                INTO xx_ce_ebay_ca_dtl_stg
                  (
                    site_name,
                    seller_order_id,
                    channel_advisor_order_id,
                    merchant_reference_number,
                    ---   BuyerUserID,
                    payment_status,
                    shipping_status,
                    refund_status,
                    sku,
                    unit_price,
                    quantity,
                    item_tax,
                    item_shipping_price,
                    item_shipping_tax,
                    total_shipping_tax_price,
                    total_tax_price,
                    total_shipping_price,
                    order_total,
                    report_date,
                    filename,
                    attribute1,
                    attribute2,
                    attribute3,
                    attribute4,
                    attribute5,
                    process_flag,
                    err_msg
                  )
                  VALUES
                  (
                    l_sitename,
                    l_sellerorderid,
                    l_channeladvisororderid,
                    l_merchantreferencenumber,
                    ---- l_BuyerUserID,
                    l_paymentstatus,
                    l_shippingstatus,
                    l_refundstatus,
                    l_sku,
                    l_unitprice,
                    l_quantity,
                    l_itemtax,
                    l_itemshippingprice,
                    l_itemshippingtax,
                    l_totalshippingtaxprice,
                    l_totaltaxprice,
                    l_totalshippingprice,
                    l_ordertotal,
                    sysdate,             --REPORT_DATE,
                    p_file_name,        ---FILENAME,
                    p_request_id,        --ATTRIBUTE1,
                    NULL,                --ATTRIBUTE2,
                    NULL,                --ATTRIBUTE3,
                    NULL,                --ATTRIBUTE4,
                    NULL,                --ATTRIBUTE5,
                    l_process_flag_ca , ---PROCESS_FLAG
                    NULL
                  );
                l_rec_cnt := l_rec_cnt + 1;
              EXCEPTION
              WHEN OTHERS THEN
                insert_pre_stg_excpn( p_process_name =>p_process_name, p_request_id =>p_request_id, p_report_date => sysdate, p_err_msg=>SUBSTR(sqlerrm,1,150), p_file_name=>p_file_name, p_record_type=>'D', p_attribute1=>SUBSTR(l_table(1),1,150), p_attribute2=>SUBSTR(l_table(2),1,150), p_attribute3=>SUBSTR(l_table(3),1,150), p_attribute4=>SUBSTR(l_table(4),1,150), p_attribute5=>SUBSTR(l_table(5),1,150), p_attribute6=>SUBSTR(l_table(6),1,150), p_attribute7=>SUBSTR(l_table(7),1,150), p_attribute8=>SUBSTR(l_table(8),1,150), p_attribute9=>SUBSTR(l_table(9),1,150), p_attribute10=>SUBSTR(l_table(10),1,150), p_attribute11=>SUBSTR(l_table(11),1,150), p_attribute12=>SUBSTR(l_table(12),1,150), p_attribute13=>SUBSTR(l_table(13),1,150), p_attribute14=>SUBSTR(l_table(14),1,150), p_attribute15=>SUBSTR(l_table(15),1,150), p_attribute16=>SUBSTR(l_table(16),1,150), p_attribute17=>SUBSTR(l_table(17),1,150));
              END;
            EXCEPTION
            WHEN no_data_found THEN
              EXIT;
            END;
          END LOOP;
          utl_file.fclose(l_filehandle);
          IF l_rec_cnt >0 THEN
            insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => NULL,p_process_flag=>'P',p_requestid=>p_request_id) ;
            logit(p_message=>TO_CHAR(l_rec_cnt)||' Records successfully loaded into staging for File '||p_file_name);
          ELSE
            logit(p_message=>'Error in Parsing file: '||p_file_name);
            insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => 'Error in Parsing file: '||p_file_name,p_process_flag=>'E',p_requestid=>p_request_id);
          END IF;
          COMMIT;
        EXCEPTION
        WHEN dup_exception THEN
          p_errbuf  := l_error_msg;
          p_retcode := '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
        WHEN parse_exception THEN
          ROLLBACK;
          p_errbuf  := l_error_msg;
          p_retcode := l_retcode;
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_operation THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Operation CA';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_filehandle THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid File Handle';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.read_error THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Read Error';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_path THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Path';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.invalid_mode THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Invalid Mode';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN utl_file.internal_error THEN
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES: Internal Error';
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          ---  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        WHEN value_error THEN
          ROLLBACK;
          utl_file.fclose(l_filehandle);
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES'||SUBSTR(sqlerrm,1,250);
          p_retcode:= '1';
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_pre_stg_excpn( p_process_name =>p_process_name, p_request_id =>p_request_id, p_report_date => sysdate, p_err_msg=>p_errbuf, p_file_name=>p_file_name, p_record_type=>'F', p_attribute1=>SUBSTR(l_table(1),1,150), p_attribute2=>SUBSTR(l_table(2),1,150), p_attribute3=>SUBSTR(l_table(3),1,150), p_attribute4=>SUBSTR(l_table(4),1,150), p_attribute5=>SUBSTR(l_table(5),1,150), p_attribute6=>SUBSTR(l_table(6),1,150), p_attribute7=>SUBSTR(l_table(7),1,150), p_attribute8=>SUBSTR(l_table(8),1,150), p_attribute9=>SUBSTR(l_table(9),1,150), p_attribute10=>SUBSTR(l_table(10),1,150), p_attribute11=>SUBSTR(l_table(11),1,150), p_attribute12=>SUBSTR(l_table(12),1,150), p_attribute13=>SUBSTR(l_table(13),1,150), p_attribute14=>SUBSTR(l_table(14),1,150), p_attribute15=>SUBSTR(l_table(15),1,150), p_attribute16=>SUBSTR(l_table(16),1,150), p_attribute17=>SUBSTR(l_table(17),1,150));
        WHEN OTHERS THEN
          ROLLBACK;
          utl_file.fclose(l_filehandle);
          p_retcode:= '1';
          p_errbuf := 'XX_CE_MRKTPLC_LOAD_PKG.LOAD_EBAY_FILES:'||SUBSTR(sqlerrm,1,250);
          log_exception (p_program_name => 'XXCEMPLSTGEBAY' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf);
          --- XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG_EXCPN ( P_PROCESS_NAME , P_REQUEST_ID, SYSDATE, P_ERRBUF , P_FILE_NAME, 'F');
          insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_errbuf,p_process_flag=>'E',p_requestid=>p_request_id) ;
        END;
      END IF;
    ELSE
      logit(p_message => p_file_name ||' : File processed in prior run');
    END IF;
  ELSE
    logit(p_message => p_file_name ||' : File will not be processed, file date is earlier than cuttoff date ');
    insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_err_msg => p_file_name ||' : File will not be processed, file date is earlier than cuttoff date ',p_process_flag=>'E',p_requestid=>p_request_id) ;
  END IF; -- Cut-off Date check
  BEGIN
    SELECT to_number(xftv.target_value1)
    INTO l_archive_days
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_EXT_MARKETPLACE_SETUPS'
    AND xftd.translate_id       =xftv.translate_id
    AND xftd.enabled_flag       ='Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
    AND rownum < 2;
    
    logit(p_message => 'l_archive_days '||l_archive_days);
  EXCEPTION
  WHEN OTHERS THEN
    l_archive_days:=30;
    logit(p_message => 'l_archive_days '||l_archive_days);
  END;
  archive_purge_process( p_days => l_archive_days );
END load_ebay_files;
/**********************************************************************
* Main Procedure to Load MarketPlaces Transactions.
* this procedure calls individual MarketPlace procedures to Load them.
***********************************************************************/
PROCEDURE main_mpl_load_proc(
    p_market_place IN VARCHAR2,
    p_file_name    IN VARCHAR2,
    p_debug_flag   IN VARCHAR2 DEFAULT 'N',
    p_request_id   IN NUMBER )
IS
  v_errbuff   VARCHAR2(1000);
  v_retcode   NUMBER ;
  v_file_type VARCHAR2(10);
BEGIN
  set_debug(p_debug_flag => p_debug_flag);
  logit(p_message=> 'Load Process started for '|| p_market_place);
  IF p_market_place IN ('EBAY_MPL') THEN
    IF p_file_name LIKE 'TRR%' THEN
      v_file_type:='TDR';
    elsif p_file_name LIKE 'Finance%' THEN
      v_file_type:='CA';
    END IF;
    logit(p_message=> 'Calling Load_ebay_files');
    xx_ce_mrktplc_load_pkg.load_ebay_files (v_errbuff,v_retcode,p_market_place,p_file_name,v_file_type,p_debug_flag,p_request_id);
  ELSE
    xx_ce_mrktplc_prestg_pkg.load_mktplc_files(p_market_place,p_file_name,p_debug_flag,p_request_id);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message=>'Error encountered in File Name '|| p_file_name );
  logit(p_message=>'Error encountered. Please check logs'|| sqlerrm );
  v_retcode := 2;
  v_errbuff := 'Error encountered. Please check logs'|| sqlerrm;
END main_mpl_load_proc;
/**********************************************************************
* Before Report call to exception report for all marketplaces.
***********************************************************************/
FUNCTION beforereport
  RETURN BOOLEAN
IS
  lb_result     BOOLEAN;
  lc_phase      VARCHAR2 (100);
  lc_status     VARCHAR2 (100);
  lc_dev_phase  VARCHAR2 (100) := NULL;
  lc_dev_status VARCHAR2 (100);
  lc_message    VARCHAR2 (100);
  conn utl_smtp.connection;
  lc_email_id      VARCHAR2(100);
  lc_email_subject VARCHAR2(250)  := '';
  lc_email_content VARCHAR2(1000) := '';
  l_err_cnt        NUMBER;
  l_request_id     NUMBER;
BEGIN
  fnd_file.put_line(fnd_file.log, lc_message);
  l_request_id:=fnd_global.conc_request_id;
  fnd_file.put_line(fnd_file.log,p_from_date);
  fnd_file.put_line(fnd_file.log, p_to_date);
  BEGIN
    SELECT xftv.target_value1
      || ' '
      || p_from_date
      ||' '
      || 'To'
      ||' '
      ||p_to_date,
      xftv.target_value2
      ||chr(13)
      ||xftv.target_value3
      ||' ('
      ||l_request_id
      ||') '
      || xftv.target_value4
      || chr(13)
      || chr(13),
      xftv.target_value5
    INTO lc_email_subject,
      lc_email_content,
      lc_email_id
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftd.translation_name = 'OD_CE_MKTPLC_DL'
    AND xftv.source_value1    ='EXCEPTION'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
    logit(p_message=> 'lc_email_subject- '||lc_email_subject);
    logit(p_message=> 'lc_email_content- '||lc_email_content);
    logit(p_message=> 'lc_email_id- '||lc_email_id);
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
    logit(p_message=> 'Exception while getting email details ');
  END;
  BEGIN
    logit(p_message=> 'p_report_dt_from - '||p_from_date);
    logit(p_message=> 'p_report_dt_to - '||p_from_date);
    BEGIN
      SELECT COUNT(1)
      INTO l_err_cnt
      FROM xx_ce_mktplc_pre_stg_excpn
      WHERE record_type ='D'
      AND TRUNC(report_date) BETWEEN p_from_date AND p_to_date;
      logit(p_message=> 'l_err_cnt - '||l_err_cnt);
    END;
    IF l_err_cnt >0 THEN
      conn      := xx_pa_pb_mail.begin_mail( sender => 'CashManagement@officedepot.com', recipients => lc_email_id, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
      xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
      xx_pa_pb_mail.end_mail( conn => conn );
      COMMIT;
    END IF;
    RETURN true;
  EXCEPTION
  WHEN OTHERS THEN
    logit(p_message=> 'Exception in beforeReport: '||SUBSTR(sqlerrm,1,150));
  END;
END beforereport;
/**********************************************************************
* After Report call to Send email program to AMS team for all marketplaces.
This program will update xx_ce_mpl_files flag from E to N  once email is sent to AMS team
***********************************************************************/
FUNCTION afterreport
  RETURN BOOLEAN
IS
  l_request_id NUMBER;
  l_rec_cnt    NUMBER:=0;
BEGIN
  p_conc_request_id := fnd_global.conc_request_id;
  BEGIN
    SELECT COUNT(1) INTO l_rec_cnt FROM xx_ce_mpl_files WHERE process_flag='E';
  EXCEPTION
  WHEN OTHERS THEN
    l_rec_cnt:=0;
  END ;
  IF l_rec_cnt > 0 THEN
    fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
    l_request_id := fnd_request.submit_request('XDO', 'XDOBURSTREP', NULL, NULL, false, 'Y', p_conc_request_id, 'Y');
    fnd_file.put_line(fnd_file.log,'Request Id '||l_request_id);
    fnd_file.put_line(fnd_file.log, 'After submitting bursting ');
    UPDATE xx_ce_mpl_files SET process_flag ='N' WHERE process_flag='E';
    DELETE
    FROM xx_ce_mpl_files
    WHERE process_flag      ='N'
    AND TRUNC(creation_date)=sysdate-30;
  ELSE
    fnd_file.put_line(fnd_file.log,'Email not sent as no Errored records for today' );
  END IF;
  COMMIT;
  RETURN (true);
EXCEPTION
WHEN OTHERS THEN
  ---logit(p_message=> 'Exception in afterReport: '||SUBSTR(SQLERRM,1,150));
  fnd_file.put_line(fnd_file.log,'In Exception with error '||SUBSTR(sqlerrm,1,150));
  RETURN (true);
END afterreport;
END xx_ce_mrktplc_load_pkg;
/
SHOW ERRORS;