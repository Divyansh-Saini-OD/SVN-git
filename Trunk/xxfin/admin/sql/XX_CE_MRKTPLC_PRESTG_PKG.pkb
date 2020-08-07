SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;

CREATE OR REPLACE
PACKAGE BODY xx_ce_mrktplc_prestg_pkg
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_PRESTG_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: This package body is for uploading files into MarketPlaces Pre-staging Area  |
  -- |  RICE ID   :  I3123_CM MarketPlaces Expansion               |
  -- |  Description: Insert file Data  into Pre-staging Table XX_CE_MARKETPLACE_PRE_STG           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         06/27/2018   Digamber S           Initial Version  
--   |
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_CE_MRKTPLC_PRESTG_PKG';
  gc_ret_success       CONSTANT VARCHAR2(20)                 := 'SUCCESS';
  gc_ret_no_data_found CONSTANT VARCHAR2(20)                 := 'NO_DATA_FOUND';
  gc_ret_too_many_rows CONSTANT VARCHAR2(20)                 := 'TOO_MANY_ROWS';
  gc_ret_api           CONSTANT VARCHAR2(20)                 := 'API';
  gc_ret_others        CONSTANT VARCHAR2(20)                 := 'OTHERS';
  gc_max_err_size      CONSTANT NUMBER                       := 2000;
  gc_max_sub_err_size  CONSTANT NUMBER                       := 256;
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;
  gb_debug             BOOLEAN                               := FALSE;
TYPE gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
TYPE gt_translation_values
IS
  TABLE OF xx_fin_translatevalues%rowtype INDEX BY VARCHAR2(30);
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF (gb_debug OR p_force) THEN
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
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
    p_exception_flag IN BOOLEAN DEFAULT FALSE)
AS
BEGIN
  IF gb_debug THEN
    IF p_exception_flag THEN
      logit(p_message => 'Exiting Exception: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
    ELSE
      logit(p_message => 'Exiting: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
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
    gb_debug := TRUE;
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
    logit(p_message => 'Date Time Stamp: '||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
    lc_current_parameter := p_parameters.FIRST;
    IF p_parameters.count > 0 THEN
      logit(p_message => 'Input parameters:');
      LOOP
        EXIT
      WHEN lc_current_parameter IS NULL;
        ln_counter              := ln_counter + 1;
        logit(p_message => ln_counter || '. ' || lc_current_parameter || ' => ' || p_parameters(lc_current_parameter));
        lc_current_parameter := p_parameters.NEXT(lc_current_parameter);
      END LOOP;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_sub;
/******************************************************************
* file record creation for uplicate Check
* Table : XXCE_MKTPLC_FILE
******************************************************************/
PROCEDURE insert_file_rec(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2)
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
      last_update_date
    )
    VALUES
    (
      p_process_name,
      p_file_name,
      SYSDATE,
      fnd_global.user_id,
      fnd_global.user_id,
      SYSDATE
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
  WHERE file_name = p_file_name;
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
/******************************************************************
* Archival procedure for Pre-Stage Tabe
* Pre-stage Table : XX_CE_MARKETPLACE_PRE_STG
* Archival Table : XX_CE_MARKETPLACE_STG_ARCH
******************************************************************/
PROCEDURE archive_purge_process(
    p_days NUMBER )
AS
BEGIN
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Archival And Purge Process for last '||p_days||' days');
  INSERT INTO xx_ce_marketplace_stg_arch
  SELECT *
  FROM xx_ce_marketplace_pre_stg
  WHERE report_date <= SYSDATE - p_days
  AND process_flag   = 'Y';
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Archived  - '||SQL%rowcount);
  DELETE
  FROM xx_ce_marketplace_pre_stg
  WHERE report_date <= SYSDATE - p_days
  AND process_flag   = 'Y';
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Record Purged  - '||SQL%rowcount);
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'ARCHIVE_PURGE_PROCESS : Error - '||sqlerrm);
END ;
/******************************************************************
* Function to get File type
******************************************************************/
FUNCTION Get_file_type(
    p_file_name  VARCHAR2,
    p_short_name VARCHAR2,
    p_file_type  VARCHAR2,
    p_flag       VARCHAR2)
  RETURN VARCHAR2
AS
  CURSOR c_file_type (l_file_type VARCHAR2)
  IS
    SELECT upper(A.file_type) file_type
    FROM
      (SELECT regexp_substr(l_file_type,'[^~]+', 1, LEVEL) file_type
      FROM dual
        CONNECT BY regexp_substr(l_file_type, '[^~]+', 1, LEVEL) IS NOT NULL
      ) A;
type ce_pre_stg_files
IS
  record
  (
    file_short_name VARCHAR2(25),
    file_type       VARCHAR2(25) );
type ce_pre_stg_files_ctt
IS
  TABLE OF ce_pre_stg_files INDEX BY pls_integer;
  l_ce_pre_stg_files_ctt ce_pre_stg_files_ctt;
  n NUMBER := 0;
BEGIN
  N := 0;
  FOR j IN c_file_type(p_short_name)---NEGGT~NEGGS
  LOOP
    l_ce_pre_stg_files_ctt(n).file_short_name := j.file_type;
    n                                         := n+1;
  END LOOP;
  N := 0;
  FOR j IN c_file_type(p_file_type) --XML~XML
  LOOP
    l_ce_pre_stg_files_ctt(n).file_type := j.file_type;
    n                                   := n+1;
  END LOOP;
  IF l_ce_pre_stg_files_ctt.count > 0 THEN
    FOR i IN l_ce_pre_stg_files_ctt.FIRST .. l_ce_pre_stg_files_ctt.LAST
    LOOP
      /*  LOGIT(P_MESSAGE =>'p_flag '||p_flag);
      LOGIT(P_MESSAGE =>'p_file_name'||UPPER(P_FILE_NAME));
      LOGIT(P_MESSAGE =>'file_short_name '||UPPER(L_CE_PRE_STG_FILES_CTT(I).FILE_SHORT_NAME ));
      LOGIT(P_MESSAGE =>'Return file_type)'||L_CE_PRE_STG_FILES_CTT(I).FILE_TYPE);
      logit(p_message =>'------------------------------------------');*/
      IF Upper(p_file_name) LIKE Upper(l_ce_pre_stg_files_ctt(i).file_short_name )||'%' THEN
        IF p_flag='T' THEN
          RETURN l_ce_pre_stg_files_ctt(i).file_type;
        ELSE
          RETURN l_ce_pre_stg_files_ctt(i).file_short_name;
        END IF;
      END IF;
    END LOOP;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'Error in getting File Type '||sqlerrm);
  RETURN NULL;
END Get_file_type;
/******************************************************************
* Helper procedure to log that the main procedure/function has been
* called. Sets the debug flag and calls entering_sub so that
* it logs the procedure name and the input parameters passed in.
******************************************************************/
PROCEDURE entering_main(
    p_procedure_name  IN VARCHAR2,
    p_rice_identifier IN VARCHAR2,
    p_debug_flag      IN VARCHAR2,
    p_parameters      IN gt_input_parameters)
AS
BEGIN
  set_debug(p_debug_flag => p_debug_flag);
  IF gb_debug THEN
    IF p_rice_identifier IS NOT NULL THEN
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
      logit(p_message => 'RICE ID: ' || p_rice_identifier);
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
    END IF;
    entering_sub(p_procedure_name => p_procedure_name, p_parameters => p_parameters);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_main;
/**********************************************************************
* Procedure to Insert common Pre-Stage table
* XX_CE_MARKETPLACE_PRE_STG
***********************************************************************/
PROCEDURE insert_pre_stg(
    p_process_name VARCHAR2,
    p_filename     VARCHAR2,
    p_file_type    VARCHAR2,
    p_request_id   NUMBER,
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
    p_attribute100 VARCHAR2 DEFAULT NULL)
AS
  ---pragma autonomous_transaction;
BEGIN
  INSERT
  INTO xx_ce_marketplace_pre_stg
    (
      rec_id,
      settlement_id,
      process_name,
      filename,
      file_type,
      request_id,
      report_date,
      process_flag,
      err_msg,
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
      xx_ce_mkt_pre_stg_rec_s.nextval,
      NULL ,
      p_process_name ,
      p_filename ,
      p_file_type ,
      p_request_id,
      SYSDATE,
      'N',
      NULL,
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
EXCEPTION
WHEN OTHERS THEN
  logit(p_message =>'INSERT_PRE_STG: Error :'||sqlerrm);
  xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , p_request_id, SYSDATE, sqlerrm , p_filename, 'D',SUBSTR(p_attribute1,1,249), SUBSTR(p_attribute2,1,249), SUBSTR(p_attribute3,1,249), SUBSTR(p_attribute4,1,249), SUBSTR(p_attribute5,1,249), SUBSTR(p_attribute6,1,249), SUBSTR(p_attribute7,1,249), SUBSTR(p_attribute8,1,249), SUBSTR(p_attribute9,1,249), SUBSTR(p_attribute10,1,249), SUBSTR(p_attribute11,1,249), SUBSTR(p_attribute12,1,249), SUBSTR(p_attribute13,1,249), SUBSTR(p_attribute14,1,249), SUBSTR(p_attribute15,1,249), SUBSTR(p_attribute16,1,249), SUBSTR(p_attribute17,1,249), SUBSTR(p_attribute18,1,249), SUBSTR(p_attribute19,1,249), SUBSTR(p_attribute20,1,249), SUBSTR(p_attribute21,1,249), SUBSTR(p_attribute22,1,249), SUBSTR(p_attribute23,1,249), SUBSTR(p_attribute24,1,249), SUBSTR(p_attribute25,1,249), SUBSTR(p_attribute26,1,249), SUBSTR(p_attribute27,1,249), SUBSTR(p_attribute28,1,249), SUBSTR(p_attribute29,1,249), SUBSTR(p_attribute30,1,249), SUBSTR( p_attribute31
  ,1,249), SUBSTR(p_attribute32,1,249), SUBSTR(p_attribute33,1,249), SUBSTR(p_attribute34,1,249), SUBSTR(p_attribute35,1,249), SUBSTR(p_attribute36,1,249), SUBSTR(p_attribute37,1,249), SUBSTR(p_attribute38,1,249), SUBSTR(p_attribute39,1,249), SUBSTR(p_attribute40,1,249), SUBSTR(p_attribute41,1,249), SUBSTR(p_attribute42,1,249), SUBSTR(p_attribute43,1,249), SUBSTR(p_attribute44,1,249), SUBSTR(p_attribute45,1,249), SUBSTR(p_attribute46,1,249), SUBSTR(p_attribute47,1,249), SUBSTR(p_attribute48,1,249), SUBSTR(p_attribute49,1,249), SUBSTR(p_attribute50,1,249), SUBSTR(p_attribute51,1,249), SUBSTR(p_attribute52,1,249), SUBSTR(p_attribute53,1,249), SUBSTR(p_attribute54,1,249), SUBSTR(p_attribute55,1,249), SUBSTR(p_attribute56,1,249), SUBSTR(p_attribute57,1,249), SUBSTR(p_attribute58,1,249), SUBSTR(p_attribute59,1,249), SUBSTR(p_attribute60,1,249), SUBSTR(p_attribute61,1,249), SUBSTR(p_attribute62,1,249), SUBSTR(p_attribute63,1,249), SUBSTR(p_attribute64,1,249), SUBSTR( p_attribute65,1,249),
  SUBSTR(p_attribute66,1,249), SUBSTR(p_attribute67,1,249), SUBSTR(p_attribute68,1,249), SUBSTR(p_attribute69,1,249), SUBSTR(p_attribute70,1,249), SUBSTR(p_attribute71,1,249), SUBSTR(p_attribute72,1,249), SUBSTR(p_attribute73,1,249), SUBSTR(p_attribute74,1,249), SUBSTR(p_attribute75,1,249), SUBSTR(p_attribute76,1,249), SUBSTR(p_attribute77,1,249), SUBSTR(p_attribute78,1,249), SUBSTR(p_attribute79,1,249), SUBSTR(p_attribute80,1,249), SUBSTR(p_attribute81,1,249), SUBSTR(p_attribute82,1,249), SUBSTR(p_attribute83,1,249), SUBSTR(p_attribute84,1,249), SUBSTR(p_attribute85,1,249), SUBSTR(p_attribute86,1,249), SUBSTR(p_attribute87,1,249), SUBSTR(p_attribute88,1,249), SUBSTR(p_attribute89,1,249), SUBSTR(p_attribute90,1,249), SUBSTR(p_attribute91,1,249), SUBSTR(p_attribute92,1,249), SUBSTR(p_attribute93,1,249), SUBSTR(p_attribute94,1,249), SUBSTR(p_attribute95,1,249), SUBSTR(p_attribute96,1,249), SUBSTR(p_attribute97,1,249), SUBSTR(p_attribute98,1,249), SUBSTR( p_attribute99,1,249), SUBSTR(
  p_attribute100,1,249));
END insert_pre_stg;
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
-- +============================================================================================+
-- |  Name  : parse                                                                 |
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse
  (
    p_delimstring IN VARCHAR2 ,
    p_table OUT varchar2_table ,
    p_nfields OUT INTEGER ,
    p_delim IN VARCHAR2 DEFAULT chr(
      9) ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2
  )
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
  p_error_msg := 'Error in parse - record:'||SUBSTR(p_delimstring,150)||SUBSTR(sqlerrm,1,150);
END PARSE;
/**********************************************************************
* Procedure CHECK_DUP_REC to check duplicate records for marketplace
* updated XX_CE_MARKETPLACE_PRE_STG
***********************************************************************/
/*PROCEDURE CHECK_DUP_REC
(
P_PROCESS_NAME    VARCHAR2,
P_FILE_SHORT_NAME VARCHAR2
)
IS
BEGIN
---------------------------Update for duplicate file check
IF p_process_name ='SEARS_MPL' THEN
UPDATE XX_CE_MARKETPLACE_PRE_STG
SET process_flag='E',
ERR_MSG       ='Duplicate Record'
WHERE rec_id   IN
(SELECT A.rec_id
FROM XX_CE_MARKETPLACE_PRE_STG A,
XX_CE_MARKETPLACE_PRE_STG B
WHERE A.process_name=b.process_name
AND A.attribute5    =b.attribute5
AND A.attribute9    =b.attribute9
AND a.rowid         > B.rowid
AND A.process_name  =p_process_name
)
AND PROCESS_FLAG   ='N'
AND PROCESS_NAME   =P_PROCESS_NAME;
ELSIF P_PROCESS_NAME ='NEWEGG_MPL' AND P_FILE_SHORT_NAME='NEGGT' THEN
UPDATE XX_CE_MARKETPLACE_PRE_STG
SET process_flag='E',
ERR_MSG       ='Duplicate Record'
WHERE rec_id   IN
(SELECT A.rec_id
FROM XX_CE_MARKETPLACE_PRE_STG A,
XX_CE_MARKETPLACE_PRE_STG B
WHERE a.PROCESS_NAME=B.PROCESS_NAME
AND a.ATTRIBUTE3    =B.ATTRIBUTE3 ---order id
AND A.attribute4    =b.attribute4----Invoice id
AND a.rowid         > B.rowid
AND A.process_name  =p_process_name
)
AND PROCESS_FLAG   ='N'
AND PROCESS_NAME   =P_PROCESS_NAME;
ELSIF P_PROCESS_NAME ='NEWEGG_MPL' AND P_FILE_SHORT_NAME='NEGGS' THEN
UPDATE XX_CE_MARKETPLACE_PRE_STG
SET process_flag='E',
ERR_MSG       ='Duplicate Record'
WHERE rec_id   IN
(SELECT A.rec_id
FROM XX_CE_MARKETPLACE_PRE_STG A,
XX_CE_MARKETPLACE_PRE_STG B
WHERE a.PROCESS_NAME=B.PROCESS_NAME
AND a.ATTRIBUTE1    =B.ATTRIBUTE3 ---Settlement date
AND A.attribute4    =b.attribute4----Settlement ID
AND a.rowid         > B.rowid
AND A.process_name  =p_process_name
)
AND PROCESS_FLAG ='N'
AND PROCESS_NAME =P_PROCESS_NAME;
END IF;
COMMIT;
EXCEPTION
WHEN OTHERS THEN
LOGIT(P_MESSAGE => 'Error in CHECK_DUP_REC procedure as  '|| SUBSTR(SQLERRM,1,150));
END CHECK_DUP_REC;*/
/**********************************************************************
* Procedure LOAD_MKTPLC_FILES to Insert common Pre-Stage table
* XX_CE_MARKETPLACE_PRE_STG
***********************************************************************/
PROCEDURE load_mktplc_files
  (
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_debug_flag   VARCHAR2,
    P_REQUEST_ID   NUMBER
  )
AS
  l_prog_name VARCHAR2
  (
    100
  )
  := 'LOAD_MKT_PLACE_FILES';
  l_filehandle utl_file.file_type;
  l_filedir VARCHAR2(20) := 'XXFIN_INBOUND_MPL';
  l_dirpath VARCHAR2(500);
  l_newline VARCHAR2(4000); -- Input line
  l_max_linesize binary_integer := 32767;
  l_user_id  NUMBER              := fnd_global.user_id;
  l_login_id NUMBER              := fnd_global.login_id;
  ---l_request_id NUMBER              := fnd_global.conc_request_id;
  l_rec_cnt NUMBER := 0;
  l_table varchar2_table;
  l_nfields            INTEGER;
  l_error_msg          VARCHAR2(1000) := NULL;
  l_error_loc          VARCHAR2(2000) := 'XX_CE_MRKTPLC_PRESTG_PKG.LOAD_MKTPLC_FILES';
  l_retcode            VARCHAR2(3)    := NULL;
  l_ajb_file_name      VARCHAR2(200);
  parse_exception      EXCEPTION;
  dup_exception        EXCEPTION;
  l_dup_transaction_id VARCHAR2(50);
  l_process_flag_tdr   VARCHAR2(150 ):='N';
  l_process_flag_ca    VARCHAR2(150 ):='N';
  l_err_msg            VARCHAR2(500 );
  plsql_block          VARCHAR2(30000);
  node_blk             VARCHAR2(30000);
  n                    NUMBER := 0;
  CURSOR c_process_map
  IS
    SELECT xftv.source_value1 process_name,
      xftv.source_value2 filemap_translation,
      xftv.target_value7 file_type,
      xftv.target_value9 file_name,
      xftv.target_value20 col_separator,
      xftv.target_value8 inbound_path,
      xftv.target_value10 archival_path,
      XX_CE_MRKTPLC_PRESTG_PKG.get_file_type(p_file_name,xftv.target_value7,xftv.target_value20,'T') file_seperator,
      XX_CE_MRKTPLC_PRESTG_PKG.get_file_type(p_file_name,xftv.target_value7,xftv.target_value20,'S') file_short_name
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = p_process_name
    AND xftd.translate_id       =xftv.translate_id
    AND xftd.enabled_flag       ='Y'
    AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE);
  CURSOR c_file_map (l_translation VARCHAR2,l_file_type VARCHAR2)
  IS
    SELECT b.source_value1 process_name,
      source_value2 file_name,
      source_value3 file_type,
      source_value4 file_column,
      source_value5 node,
      upper(b.target_value1) table_column
    FROM xx_fin_translatevalues b ,
      xx_fin_translatedefinition A
    WHERE A.translation_name = l_translation
      --- AND b.SOURCE_VALUE2 LIKE l_file_name||'%'
    AND upper(b.source_value3)=upper(l_file_type)
    AND b.translate_id        = A.translate_id
    AND b.enabled_flag        ='Y'
    AND SYSDATE BETWEEN b.start_date_active AND NVL(b.end_date_active,SYSDATE)
    ORDER BY to_number(REPLACE(upper(b.target_value1), 'ATTRIBUTE','0'));
  l           NUMBER := 0;
  p_retcode   VARCHAR2(100);
  p_errbuf    VARCHAR2(10000);
  last_line   NUMBER := 0;
  l_total_cnt NUMBER :=0;
  l_xml_file CLOB ;
  L_DUP_CHECK     VARCHAR2(2);
  L_XML_HDR_START NUMBER;
  L_XML_HDR_END   NUMBER;
BEGIN
  set_debug( p_debug_flag );
  -- Check file duplicate
  IF check_duplicate_file(p_file_name) = 'N' THEN
    FOR i IN c_process_map
    LOOP
      p_retcode :=0;
      BEGIN
        logit(p_message =>'Start Procedure :'|| i.process_name);
        l_filehandle := utl_file.fopen(l_filedir, p_file_name,'r',l_max_linesize);
        logit(p_message =>'File Directory path' || l_filedir);
        logit(p_message =>'File open successfull');
        L := 0;
        ----  logit(p_message =>'i.file_seperator'|| i.file_seperator);
        IF i.file_seperator='XML' THEN
          LOOP
            BEGIN
              l           := l+1;
              l_retcode   := NULL;
              l_error_msg :=NULL;
              utl_file.get_line(l_filehandle,l_newline);
              -- Skip last line
              IF P_PROCESS_NAME ='SEARS_MPL' THEN
                SELECT INSTR(L_NEWLINE,'<remittance-response',1,1),
                  INSTR(L_NEWLINE,'>',INSTR(L_NEWLINE,'<remittance-response',1,1),1)
                INTO L_XML_HDR_START,
                  L_XML_HDR_END
                FROM DUAL;
                L_NEWLINE:= REPLACE(L_NEWLINE,SUBSTR(L_NEWLINE,L_XML_HDR_START,L_XML_HDR_END-L_XML_HDR_START),'<remittance-response');
                /*  IF l_newline LIKE '<remittance-response%' THEN
                last_line := l ;
                l_newline := '<remittance-response>'||chr(10)||chr(13);
                END IF;*/
              END IF;
              l_xml_file := l_xml_file||' '||l_newline;
            EXCEPTION
            WHEN no_data_found THEN
              EXIT;
            END;
          END LOOP;
          utl_file.fclose(l_filehandle);
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
                XMLTYPE(l_xml_file),
                'N',
                p_request_id,
                SYSDATE,
                fnd_global.user_id,
                SYSDATE,
                fnd_global.user_id,
                fnd_global.user_id
              );
            IF sql%ROWCOUNT > 0 THEN
              logit(p_message =>'File '''||p_file_name||''' loaded successfully to xx_ce_mktplc_pre_stg_files table ');
            ELSE
              logit(p_message =>'File '''||p_file_name||''' load failed');
            END IF;
            COMMIT;
          EXCEPTION
          WHEN OTHERS THEN
            logit(p_message =>'Exception while insert into XX_CE_MKTPLC_PRE_STG_FILES  '|| SUBSTR(sqlerrm,1,150));
          END;
          BEGIN
            plsql_block := '';
            node_blk    := '';
            plsql_block := ' INSERT INTO XX_CE_MARKETPLACE_PRE_STG ( ';
            plsql_block := plsql_block||' REC_ID, SETTLEMENT_ID, PROCESS_NAME, FILENAME, File_type, REQUEST_ID,REPORT_DATE, PROCESS_FLAG, ERR_MSG';
            FOR j IN c_file_map
            (
              i.filemap_translation,i.file_short_name
            )
            LOOP
              plsql_block := plsql_block||','||j.table_column;
              node_blk    := node_blk||','||'ExtractValue(VALUE(b),''*/'||j.node||'/text()'') AS '||j.file_column;
            END LOOP;
            NODE_BLK         := NODE_BLK ||' '||' FROM XX_CE_MKTPLC_PRE_STG_FILES A,';
            IF p_process_name ='SEARS_MPL' THEN
              NODE_BLK       := NODE_BLK ||' '||' TABLE(xmlsequence(EXTRACT(A.file_data,''remittance-response//remittance''))) b';
              /*   ELSIF P_PROCESS_NAME ='NEWEGG_MPL' AND i.file_short_name='NEGGT' THEN
              NODE_BLK          := NODE_BLK ||' '||' TABLE(xmlsequence(EXTRACT(A.file_data,''NeweggAPIResponse//SettlementTransactionInfo''))) b';
              ELSIF P_PROCESS_NAME ='NEWEGG_MPL' AND i.file_short_name='NEGGS' THEN
              NODE_BLK          := NODE_BLK ||' '||' TABLE(xmlsequence(EXTRACT(A.file_data,''NeweggAPIResponse//SettlementSummary''))) b';*/
            END IF;
            node_blk    := node_blk ||' '||' WHERE status = ''N''';
            plsql_block := plsql_block||')';
            plsql_block := plsql_block||' Select ';
            plsql_block := plsql_block||' XX_CE_MKT_PRE_STG_REC_S.nextval ';
            plsql_block := plsql_block||', NULL';
            plsql_block := plsql_block||', '''|| p_process_name||'''';
            plsql_block := plsql_block||', '''|| p_file_name||'''';
            plsql_block := plsql_block||', '''|| i.file_short_name||'''';
            plsql_block := plsql_block||', '''|| p_request_id||'''';
            plsql_block := plsql_block||', '''|| SYSDATE||'''';
            plsql_block := plsql_block||', ''N''';
            plsql_block := plsql_block||', NULL';
            plsql_block := plsql_block||' '||node_blk;
            BEGIN
              EXECUTE IMMEDIATE plsql_block;
              -- Mark reord processed
              l_rec_cnt := l_rec_cnt+NVL(SQL%rowcount,0);
              UPDATE xx_ce_mktplc_pre_stg_files
              SET status      = 'P'
              WHERE file_name = p_file_name;
            EXCEPTION
            WHEN OTHERS THEN
              logit(p_message =>'In exception for Execute Immediate');
              P_ERRBUF := SUBSTR(SQLERRM,1,150);
              xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'D');
              plsql_block := NULL;
              UPDATE xx_ce_mktplc_pre_stg_files
              SET status      = 'E'
              WHERE file_name = p_file_name;
            END;
            ---END LOOP;
          END;
        ELSE
          LOOP
            l:= l+1;
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
            WHEN L = 1;
              ---  logit(p_message =>SUBSTR(l_newline,1,199));
              IF i.col_separator = 'COMMA' THEN
                parse(l_newline,l_table,l_nfields,chr(44),l_error_msg,l_retcode);
              END IF;
              IF i.col_separator = 'TAB' THEN
                parse(l_newline,l_table,l_nfields,chr(9),l_error_msg,l_retcode);
              END IF;
              IF i.col_separator = 'PIPE' THEN
                parse(l_newline,l_table,l_nfields,'|',l_error_msg,l_retcode);
              END IF;
              IF l_retcode = '2' THEN
                raise parse_exception;
              END IF;
              -- ==========================
              plsql_block := ' BEGIN  XX_CE_MRKTPLC_PRESTG_PKG.INSERT_PRE_STG';
              plsql_block := plsql_block ||'(';
              n           := 0;
              -----Process Name /  File Type  / File Name
              plsql_block := plsql_block ||' '||''''||i.process_name||''''||',';
              plsql_block := plsql_block ||' '||''''||p_file_name||''''||',';
              --  FOR k IN c_file_type(p_file_name, i.file_type)
              --  LOOP
              plsql_block := plsql_block ||' '||''''||i.file_short_name ||''''||',';
              PLSQL_BLOCK := PLSQL_BLOCK ||' '||''''||P_REQUEST_ID ||''''||',';
              -- file attributes are mapped in translation
              FOR j IN c_file_map (i.filemap_translation,i.file_short_name)
              LOOP
                n           := n +1;
                plsql_block := plsql_block ||' '||''''||trim(REPLACE(l_table(n),'''','"'))||''''||',';
              END LOOP;
              PLSQL_BLOCK := RTRIM(PLSQL_BLOCK,',') ||');   END;';
              BEGIN
                EXECUTE IMMEDIATE PLSQL_BLOCK;
                L_REC_CNT   := L_REC_CNT+NVL(SQL%ROWCOUNT,0);
                PLSQL_BLOCK := NULL;
              EXCEPTION
              WHEN OTHERS THEN
                ---  p_errbuf:=substr(SQLERRM,1,150);
                xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , p_request_id, sysdate, p_errbuf , p_file_name, 'D');
                logit(p_message =>'Error while File Parsing ');
                plsql_block := NULL;
              END;
            EXCEPTION
            WHEN no_data_found THEN
              EXIT;
            END;
          END LOOP;
          utl_file.fclose(l_filehandle);
        END IF;---- seperator is XML
        ---   LOGIT(P_MESSAGE =>'L_REC_CNT'|| L_REC_CNT);
        IF L_REC_CNT       > 0 THEN
          IF P_PROCESS_NAME='WALMART_MPL' THEN
            SELECT l_rec_cnt-COUNT(1)
            INTO l_total_cnt
            FROM xx_ce_mktplc_pre_stg_excpn
            WHERE process_name=i.process_name
            AND request_id    =p_request_id
            AND file_name     =p_file_name
            AND RECORD_TYPE   ='D';
            LOGIT(P_MESSAGE =>L_TOTAL_CNT||' Records successfully inserted in XX_CE_MARKETPLACE_PRE_STG Table');
            ---  logit(p_message =>'Records uploaded :'||l_total_cnt);
            insert_file_rec( p_process_name => i.process_name, p_file_name => p_file_name);
          ELSE
            SELECT COUNT(1)
            INTO l_rec_cnt
            FROM XX_CE_MARKETPLACE_PRE_STG
            WHERE process_name=i.process_name
            AND REQUEST_ID    =P_REQUEST_ID
            AND FILENAME      =P_FILE_NAME ;
            LOGIT(P_MESSAGE =>L_REC_CNT||' Records successfully inserted in XX_CE_MARKETPLACE_PRE_STG Table');
            ------call procesdure to insert processed file into XX_CE_MPL_FILES
            INSERT_FILE_REC( P_PROCESS_NAME => I.PROCESS_NAME, P_FILE_NAME => P_FILE_NAME);
            ------Call procesure to check duplicate records
            ---  CHECK_DUP_REC(P_PROCESS_NAME => I.PROCESS_NAME, P_FILE_SHORT_NAME=>i.file_short_name);
          END IF;
        ELSE
          logit(p_message =>'Error while parsing the file');
        END IF;
        COMMIT;
      EXCEPTION
      WHEN dup_exception THEN
        p_errbuf  := l_error_msg;
        p_retcode := '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN parse_exception THEN
        ROLLBACK;
        p_errbuf  := l_error_msg;
        p_retcode := l_retcode;
        logit(p_message => p_errbuf);
      WHEN utl_file.invalid_operation THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name ||' File - '||p_file_name||' '|| ' Invalid Operation , Check if file exist on the inbound folder and have sufficient Previlages ';
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
        p_retcode:= '1';
        logit(p_message => p_errbuf);
      WHEN utl_file.invalid_filehandle THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name||' File - '||p_file_name||' '|| ' Invalid File Handle';
        p_retcode:= '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN utl_file.read_error THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name||' File - '||p_file_name||' '||' Read Error';
        p_retcode:= '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN utl_file.invalid_path THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name||' File - '||p_file_name||' '||' Invalid Path';
        p_retcode:= '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN utl_file.invalid_mode THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name||' File - '||p_file_name||' '||'Invalid MODE';
        p_retcode:= '1';
        logit(p_message => p_errbuf);
      WHEN utl_file.internal_error THEN
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES'||' - '||i.process_name||' File - '||p_file_name||' '||' : Internal Error';
        p_retcode:= '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN value_error THEN
        ROLLBACK;
        utl_file.fclose(l_filehandle);
        p_errbuf := 'LOAD_MKT_PLACE_FILES VA'||' - '||i.process_name||' File - '||p_file_name||' '||SUBSTR(sqlerrm,1,250);
        p_retcode:= '1';
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      WHEN OTHERS THEN
        ROLLBACK;
        utl_file.fclose(l_filehandle);
        p_retcode:= '1';
        p_errbuf :='LOAD_MKT_PLACE_FILES WO'||' - '||i.process_name||' File - '||p_file_name||' '||SUBSTR(sqlerrm,1,250);
        logit(p_message => p_errbuf);
        xx_ce_mrktplc_prestg_pkg.insert_pre_stg_excpn ( p_process_name , P_REQUEST_ID, SYSDATE, p_errbuf , p_file_name, 'F');
      END;
    END LOOP;
    archive_purge_process( p_days => 30 );
  ELSE
    LOGIT(P_MESSAGE => P_FILE_NAME ||' : File processed in prior run');
  END IF;
END LOAD_MKTPLC_FILES;
FUNCTION GET_START_DATE(
    P_PROCESS_NAME VARCHAR2)
  RETURN DATE
IS
  --- L_PROG_COMPLETION_DATE DATE;
  L_MAX_RECD_DATE    DATE;
  L_START_DATE_DURTN DATE;
  L_START_DATE       DATE;
BEGIN
  BEGIN
    -----------Start date duration value from sysdate as setup in translation
    SELECT sysdate-NVL(xftv.target_value21,0)
    INTO L_START_DATE_DURTN
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE XFTD.TRANSLATION_NAME ='OD_SETTLEMENT_PROCESSES'
    AND xftv.source_value1      = P_PROCESS_NAME
    AND xftd.translate_id       =xftv.translate_id
    AND XFTD.ENABLED_FLAG       ='Y'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
    -----------Pre-stage max report_date as per process name
    SELECT MAX(REPORT_DATE)
    INTO L_MAX_RECD_DATE
    FROM XX_CE_MARKETPLACE_PRE_STG
    WHERE PROCESS_NAME =P_PROCESS_NAME;
    IF L_MAX_RECD_DATE > L_START_DATE_DURTN THEN
      L_START_DATE    :=L_MAX_RECD_DATE;
    ELSE
      L_START_DATE :=L_START_DATE_DURTN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    L_START_DATE:=SYSDATE-1;
    LOGIT(P_MESSAGE =>'In exception of GET_START_DATE   '||L_START_DATE);
  END;
  RETURN L_START_DATE;
END GET_START_DATE;
END xx_ce_mrktplc_prestg_pkg; 
/
show errors;