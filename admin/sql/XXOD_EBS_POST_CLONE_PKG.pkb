CREATE OR REPLACE PACKAGE BODY XXOD_EBS_POST_CLONE_PKG
AS

-- +=======================================================================================================+
-- |                  Office Depot - R12 Upgrade Project                                                   |
-- |                    Office Depot Organization                                                          |
-- +=======================================================================================================+
-- | Name  : XXOD_EBS_POST_CLONE_PKG                                                                       |
-- | Description :  This PKG will be used to execute after the clone                                       |
-- |                of a new instance.This has multiple procedures                                         |
-- |                instance specific and non instance specific.                                           |
-- |                                                                                                       |
-- |                                                                                                       |
-- |Change Record:                                                                                         |
-- |===============                                                                                        |
-- |Version   Date        Author          Remarks                                                          |
-- |=======   ==========  =============   =================================================================|
-- |1.0      15-July-2014  Santosh Gopal  E3094 Initial draft version                                      |
-- |1.1      21-July-2014  Darshini G     Added update procedures for E3094                                |
-- |1.2      03-Sep-2014   Darshini G     Added the piece of code to generate a CSV file.                  |
-- |1.3      22-Sep-2014   Darshini G     Modified to add additional items.                                |
-- |1.4      07-OCT-2014   R.Aldridge     Modified Bill_NI_03 to account for VPD policy                    |
-- |1.5      20-OCT-2014   Sridevi K      Modified for iREC_IS_01                                          |
-- |1.6      21-OCT-2014   P.Sanjeevi     Modified for SC_NI_01                                            |
-- |1.7      23-DEC-2014   R.Aldridge     Fixed Bill_NI_11 for Ray                                         |
-- |1.8      23-DEC-2014   R.Aldridge     Modified file name to include time                               | 
-- |1.9      05-FEB-2015   P.Suresh       Added logic to cleanup email_address                             |
-- |1.10     03-APR-2015   Havish Kasina  Get SMTP server from profile                                     |
-- |1.11     30-APR-2015   Havish Kasina  Update the E-mail                                                |
-- |1.12     07-MAY-2015   Havish Kasina  Changed the lc_soa_host value from 'soasit01' to 'soadev01'      |
-- |                                       for GSISIT01 and GSISIT02 Instances as per Defect Id # 33858    | 
-- |1.13     12-MAY-2015   Havish Kasina  Update the Target_value1 for Source_value1='HTTPURL' for         |
-- |                                       Translation  FTP_DETAILS_AJB                                    |
-- |1.14     20-MAY-2015   Havish Kasina  Added logic to pull the concurrent jobs running information      |
-- |1.15     15-JUN-2015   Havish Kasina  Update the Target_value1,Target_value2 for Source_value1=        |
-- |                                       'XX_TDS_EMAIL' for Translation XX_TDS_EBS_NOTIFY_EMAIL          |
-- |1.16     15-JUN-2015   Havish Kasina  Update the Source_value1,Source_value2 for Translation           |
-- |									   XX_FIN_SPC_CONFIG                                               |
-- |1.17     16-JUN-2015   Havish Kasina  Added DBMS_OUTPUT messages and two variables (ln_err_num and     |
-- |									   lc_err_msg) in both instance specific and non-instance          |
-- |									   specific procedures                                             |
-- |1.18     16-JUN-2015   Havish Kasina  Added 4 new identifiers FND_NI_04,FND_NI_05, FND_NI_06 and       |
-- |									   FND_IS_02-> To update the Parameter values for their            |
-- |									   respective display names                                        |
-- |1.19     17-JUN-2015   Havish Kasina  Added 3 Profile Options for iReceivables                         |
-- |1.20     24-JUN-2015   Havish Kasina  Changed the Date Conversion and added the SQL error message and  |
-- |                                       code in the xx_write_to_file procedure                          | 
-- |1.21     30-JUN-2015   Havish Kasina  Added for GSIDEV03 Instance in iREC_IS_01 Identifier             |
-- |1.22     30-JUN-2015   Havish Kasina  Added for GSISIT03 Instance in Instance Specific Procedure       |
-- |1.23     22-JUL-2015   Havish Kasina  Added a new identifier iREC_IS_03 to update the Translation      |
-- |                                       XX_FIN_IREC_TOKEN_PARAMS --> Defect # 35177                     | 
-- |1.24     27-JUL-2015   Havish Kasina  Added a new identifier SERVICE_IS_06 to update the Translation   |
-- |                                       XXCS_EMAIL_CONFIG                                               | 
-- |1.25     26-AUG-2015   Havish Kasina  Changed the Target_value1 for Identifier Bill_NI_11              |
-- |1.26     11-SEP-2015   Havish Kasina  Added a new identifier AR_NI_09 to update the Translation        |
-- |                                      XXOD_AR_POD_URL                                                  |
-- |1.27     23-OCT-2015   Havish Kasina  Added two new Translation values for Translation                 |
-- |                                      XXCRM_SCRAMBL_FILE_FORMAT for Source Value1                      |
-- |                                      = 'XX_CRM_CUSTMAST_HEAD_STG'                                     |
-- |1.28     16-NOV-2015   Havish Kasina  Removed the schema references as per R12.2 Retrofit changes      |
-- |1.29     19-JAN-2016   Havish Kasina  Changed the value for the Profile XX_OM_USE_TEST_CC from 'Yes'   |
-- |                                      to 'Y'. Defect # 37006                                           |
-- |1.30     20-JAN-2016   Havish Kasina  Added a new identifier iREC_NI_07 to update the Translation      |
-- |                                       XX_FIN_IREC_TOKEN_PARAMS --> Defect # 37006                     | 
-- |1.31     21-JAN-2016   Havish Kasina  Defect # 37006 -                                                 |
-- |                                      a. Modify the log and csv file names for both instance spec and  |
-- |                                         non-instance spec                                             |
-- |                                      b. Added the Timestamp in the file name for instance spec        |
-- |                                      c. Added Duration field before Exception Message in the csv for  |
-- |                                         both instance and non-instance specific                       |
-- |                                      d. Removed the commas in lc_action in SERVICE_IS_O6 identifier   |
-- |1.32     22-JAN-2016   Havish Kasina  Defect # 37006. Added target_value5 in the existing Bill_NI_11   |
-- |                                      Identifier                                                       |
-- |1.33     27-JAN-2016   Havish Kasina  Added new identifier FND_IS_03 to Check for SYSTEM_TEMP_DR       |
-- |                                      value in XDO_CONFIG_VALUES Table. Defect # 37039                 |
-- |1.34     29-JAN-2016   Havish Kasina  Added new identifier FND_IS_04 to Check the Values in fields     |
-- |                                      infobundle_upload_date and infobundle_creation_date from         |
-- |                                      AD_PM_MASTER Table.Defect # 37039                                |
-- |1.35     01-FEB-2016   Havish Kasina  Added a new identifier AR_NI_10 to update the table              |
-- |                                      XX_AR_WC_EXT_CONTROL.Defect 34678                                |
-- |1.36     11-FEB-2016   Havish Kasina  Added 2 new identifiers INV_NI_01 and IEX_NI_01 to update the    |
-- |                                      profile options for E-mail servers.Defect 37152                  |
-- |1.37     12-FEB-2016   Havish Kasina  Added a new identifier Bill_NI_17 to update the description of   |
-- |                                      the program 'OD: AR EBL Transmit eBills via Email (Parent)' and  |
-- |                                      and disable the program in all Non-PROD instances. Defect 37166  |
-- |1.38     24-FEB-2016   Havish Kasina  Commented the existing logic for identifier FND_NI_03. Added a   |
-- |                                      new logic for identifier FND_NI_03 as per Defect 37269           |
-- |1.39     24-FEB-2016   Havish Kasina  Added a new identifier FND_IS_05 to update the the value for     |
-- |                                      SYSTEM_TEMP_DR(Property Code) in XDO_CONFIG_VALUES Table (as per |
-- |                                      Defect 37274)                                                    |
-- |1.40     26-FEB-2016   Havish Kasina  Defect 37296 -->                                                 |
-- |                                      a. Updated the target_value1 for the 'AJB_URL' in the            |
-- |                                         translation XX_FIN_IREC_TOKEN_PARAMS                          |
-- |                                      b. Updated the value for the Profile Option IBY_ECAPP_URL        |
-- |                                      c. Updated the value for the Profile Option ICX_PAY_SERVER       |
-- |1.41     02-MAR-2016   Havish Kasina  Updated the source_value9 in translation AP_CHECK_PRINT_BANK_DTLS|
-- |                                      (Defect 37340)                                                   |
-- |1.42     09-MAY-2016   Havish Kasina  Updated the target_value3, target_value4, target_value5 and      |
-- |                                      target_value9 in the translation EBS_NOTIFICATIONS (Defect 37831)|
-- |1.43     23-MAY-2016   Havish Kasina  Updated the target_value1 for the source value1=WALLET_LOCATION  |
-- |                                      in the translation XX_FIN_IREC_TOKEN_PARAMS (Defect 37222)       |
-- |1.44     08-JUN-2016   Havish Kasina  Changed the target_value2 from PRODFTP to ODPFTP in the Post     |
-- |                                      Clone Identifier TAX_NI_02 (Defect 38083)                        |
-- |1.45     06-JUL-2016   Havish Kasina  Changed the URLs for all instances https instead of http         |
-- |                                      (Defect 38347)                                                   |   
-- |1.46     13-SEP-2016   Havish Kasina  Added a new identifier HR_NI_03 (Defect 39317)                   |
-- |1.47     18-NOV-2016   Havish Kasina  Added a new identifier iPAY_NI_02 (Defect 40180)                 |
-- |1.48     21-FEB-2017   Havish Kasina  Added a new identifier iEXP_IS_01 (Defect 40333)                 |
-- |1.49     03-AUG-2017   Suresh Naragam Added a new identifiers PO_NI_01,02,03 (Defect#42904)            |
-- |1.50     15-AUG-2017   Shalu George	  Disabled enable_flag and Default_printer_flag 				   |
-- |									  WSH_REPORT_PRINTERS| (Defect 42913)               			   |	
-- |1.51     04-OCT-2017   Suresh Naragam Added a new identifiers OM_IS_04 (Defect#43399)                  |
-- |1.52     12-OCT-2017   Havish Kasina  Added a new identifier iREC_NI_08                                |
-- |1.53     16-MAY-2018   Havish Kasina  Added new identifiers AR_NI_11 and AR_NI_12(Defect#NAIT-42194)   |     
-- |1.54     15-JUN-2018   Havish Kasina  Added new identifier FND_IS_06 to update the Profile values for  |
-- |                                      the profile option FND_EXTERNAL_ADF_URL                          | 
-- |1.55     10-JUL-2018   Havish Kasina  Added new identifier AR_IS_03 to update the Subscription Billing |
-- |                                      values for the translation XX_AR_SUBSCRIPTIONS                   |   
-- |1.56     22-AUG-2018   Havish Kasina  Added new identifier AR_NI_13 to update the OD_VPS_TRANSLATION   |
-- |                                      translation                                                      |       
-- |1.57     04-oct-2018   Havish Kasina  Added new identifier FND_NI_07 to udpate the OD_MAIL_GROUPS      |
-- |                                      translation                                                      | 
-- +=======================================================================================================+

-- +==========================================================+
-- | Global Variable                                          |
-- +==========================================================+
 gc_mail_host        VARCHAR2(100):= 'USCHEBSSMTPD01.NA.ODCORP.NET'; -- Added as per Version 1.10
 gc_email_address    VARCHAR2(100):= 'ebs_test_notifications@officedepot.com'; -- Added as per Version 1.11
-- +===================================================================+
-- | Name        : XXOD_EBS_POST_CLONE_PKG                             |
-- |                                                                   |
-- | Description : This program is to be used in non production        |
-- |               instances to ensure that objects dependent on       |
-- |               production instance are modified to non prod        |
-- |               instances like profiles, email, credit card nos etc.|
-- +===================================================================+
  PROCEDURE xx_write_to_log ( p_filehandle_log     IN UTL_FILE.file_type
                              ,p_string            IN VARCHAR2
                             )
  IS
  -- +===================================================================+
  -- | Name  : xx_write_to_log                                           |
  -- | Description     : The xx_write_to_log procedure writes the        |
  -- |                   comments into the log file                      |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
   
   BEGIN

     UTL_FILE.PUT_LINE (p_filehandle_log,p_string);

   EXCEPTION 
     WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20055, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20056, 'Invalid Operation');
     WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE ('Error while writing into the CSV file'); -- Commented as per Version 1.20
		DBMS_OUTPUT.PUT_LINE ('Error while writing into the log file : '|| SQLCODE ||' - '||SQLERRM); -- Added as per Version 1.20
   END xx_write_to_log;


   FUNCTION xx_get_inst_name( p_filehandle     IN   UTL_FILE.file_type
                            )
  RETURN VARCHAR2
  IS
  -- +===================================================================+
  -- | Name  : xx_get_inst_name                                          |
  -- | Description     : The xx_get_inst_name function returns the       |
  -- |                   instance name                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  p_instance_name  VARCHAR2(30);

  BEGIN
     SELECT SUBSTR(UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME')),1,8) -- Commented by Havish Kasina as per Version 1.17--UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME')) 
       INTO p_instance_name
       FROM dual;
     RETURN p_instance_name;
  EXCEPTION 
     WHEN NO_DATA_FOUND THEN
        p_instance_name := NULL;
        xx_write_to_log (p_filehandle,'No data found while getting the Instance Name : '||p_instance_name);
        RETURN p_instance_name;
     WHEN OTHERS THEN
        p_instance_name := NULL;
        xx_write_to_log (p_filehandle,'Exception while getting the Instance Name : '||p_instance_name);
        RETURN p_instance_name;
  END xx_get_inst_name;


   FUNCTION xx_get_dir_path( p_filehandle     IN   UTL_FILE.file_type
                             ,p_dir_name       IN   VARCHAR2
                            )
  RETURN VARCHAR2
  IS
  -- +===================================================================+
  -- | Name  : xx_get_dir_path                                           |
  -- | Description     : The xx_get_dir_path function returns the DBA    |
  -- |                   directory path.                                 |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  lc_dba_dirpath        VARCHAR2(2000);

  BEGIN
     SELECT directory_path
     INTO   lc_dba_dirpath
     FROM   dba_directories
     WHERE  directory_name = p_dir_name;
     RETURN lc_dba_dirpath;
  EXCEPTION 
     WHEN NO_DATA_FOUND THEN
     lc_dba_dirpath := NULL;
     xx_write_to_log (p_filehandle,'No data found while getting the directory path for : '||p_dir_name);
     RETURN lc_dba_dirpath;
     WHEN OTHERS THEN
     lc_dba_dirpath := NULL;
     xx_write_to_log (p_filehandle,'Exception while getting the directory path for : '||p_dir_name);
     RETURN lc_dba_dirpath;
  END xx_get_dir_path;


  PROCEDURE xx_write_to_file( p_filehandle_csv    IN UTL_FILE.file_type
                              ,p_identifier        IN VARCHAR2
                              ,p_status            IN VARCHAR2
                              ,p_object_type       IN VARCHAR2  
                              ,p_object_name       IN VARCHAR2
                              ,p_action            IN VARCHAR2
                              ,p_result            IN VARCHAR2
                              ,p_start_date_time   IN VARCHAR2
                              ,p_end_date_time     IN VARCHAR2
                              ,p_exception_message IN VARCHAR2
                             )
  IS
  -- +===================================================================+
  -- | Name  : xx_write_to_file                                          |
  -- | Description     : The xx_write_to_file procedure writes the       |
  -- |                   results to the CSV file                         |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+

   ld_duration            NUMBER; 

   BEGIN

      SELECT 
	  --TO_CHAR(((TO_DATE(p_end_date_time,'yyyy/mm/dd hh24:mi:ss') - TO_DATE(p_start_date_time,'yyyy/mm/dd hh24:mi:ss')) * 1440),'999.99') -- Commented as per Version 1.20
	  TO_CHAR(((TO_DATE(p_end_date_time,'mm/dd/yyyy hh24:mi:ss') - TO_DATE(p_start_date_time,'mm/dd/yyyy hh24:mi:ss')) * 1440),'999.99') -- Added as per Version 1.20
      INTO ld_duration
      FROM DUAL;

      UTL_FILE.PUT_LINE (p_filehandle_csv,p_identifier||','||p_status||','||p_object_type||','||p_object_name||','||p_action||','||
                                          p_result||','||p_start_date_time||','||p_end_date_time||','||ld_duration||','||p_exception_message);
   EXCEPTION 
     WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20055, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20056, 'Invalid Operation');
     WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE ('Error while writing into the CSV file'); -- Commented as per Version 1.20
		DBMS_OUTPUT.PUT_LINE ('Error while writing into the CSV file : '||SQLCODE || ' - '||SQLERRM); -- Commented as per Version 1.20
   END xx_write_to_file;


  PROCEDURE  xx_update_non_inst_specific
  AS
  -- +===================================================================+
  -- | Name  : xx_update_non_inst_specific                               |
  -- | Description     : The xx_update_non_inst_specific procedure       |
  -- |                   performs all not instance specific updates.     |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  lc_filehandle         UTL_FILE.file_type;
  lc_filehandle_csv     UTL_FILE.file_type;
  lc_dirpath            VARCHAR2(2000) := 'XX_UTL_FILE_OUT_DIR';
  lc_curr_date          VARCHAR2(100)  := TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS');
  lc_order_file_name    VARCHAR2(100)  := UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'_'||'appdev_non_inst_post_clone'||'.log'; -- Changed as per Version 1.31 --'appdev_non_inst_post_clone_'||UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'.log';
  lc_csv_file_name      VARCHAR2(100)  := UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'_'||'appdev_non_inst_post_clone'||'.csv'; -- Changed as per Version 1.31 --'appdev_non_inst_post_clone_'||UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'.csv';
  lc_mode               VARCHAR2(1)    := 'W';
  lc_instance_name      VARCHAR2(30);
  lb_profile_chg_result BOOLEAN;
  lc_identifier         VARCHAR2(25);
  lc_object_type        VARCHAR2(50);
  lc_object_name        VARCHAR2(100);
  lc_action             VARCHAR2(100);
  ld_start_date_time    VARCHAR2(20);
  ld_end_date_time      VARCHAR2(20);
  lc_exception_message  VARCHAR2(1000);
  lc_result             VARCHAR2(1000);
  lc_status             VARCHAR2(10);
  ln_count              NUMBER;
  lc_value              varchar2(1000);
  --lc_flag               VARCHAR2(1);  -- Added as per Version 1.14 -- Commented as per Version 1.38 ( Defect 37269)
  --lc_error_text         VARCHAR2(1000);
  -- Added by Havish Kasina as per Version 1.17
  ln_err_num            NUMBER;
  lc_err_msg            VARCHAR2(100);
  ln_pending_count      NUMBER; -- Added as per Version 1.38 ( Defect 37269) 
  ln_running_count      NUMBER; -- Added as per Version 1.38 ( Defect 37269)

  BEGIN

     lc_filehandle     := UTL_FILE.FOPEN (lc_dirpath, lc_order_file_name, lc_mode);
     lc_filehandle_csv := UTL_FILE.FOPEN (lc_dirpath, lc_csv_file_name, lc_mode);
     lc_instance_name  := xx_get_inst_name(lc_filehandle);
     dbms_output.put_line('File Location: '||xx_get_dir_path(lc_filehandle,lc_dirpath));
     dbms_output.put_line('Log file name for non-instance specific steps: '||lc_order_file_name);
     dbms_output.put_line('CSV file name for non-instance specific steps: '||lc_csv_file_name);

     IF lc_instance_name <>'GSIPRDGB' THEN
        xx_write_to_log (lc_filehandle,'Start of update for non instance specific steps');
        xx_write_to_log (lc_filehandle,'-----------------------------------------------'||CHR(10));

        --------------------------------------------------
        -- Writing the title and header for the CSV file--
        --------------------------------------------------
        xx_write_to_log (lc_filehandle_csv, 'AppDev Non-Instance Post-Cloning '||lc_instance_name||' '||TO_CHAR(SYSDATE,'YYYY-MM-DD')||CHR(10));
        xx_write_to_log (lc_filehandle_csv,'Identifier'||','||'Status'||','||'Object Type'||','||'Object Name'||','||'Action'||','
                                              ||'Result'||','||'Start Date/Time'||','||'End Date/Time'||','||'Duration'||','||'Exception Message'); -- Added Duration as per Version 1.31
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Accounts Payables ...'||CHR(10));
           BEGIN
              -------------------------------------------------
              -- AP_NI_01 - Update for AP_CHECK_PRINT_BANK_DTLS 
              -------------------------------------------------
              lc_identifier          := 'AP_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AP_CHECK_PRINT_BANK_DTLS';
              lc_action              := 'Update 4 banks';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              --lc_error_text          := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_01');

              UPDATE xx_fin_translatevalues 
              SET    source_value2  = null, 
                     source_value6  = null, 
                     source_value9  = 'noprint',  -- Updated as per Version 1.41 (Defect 37340)  --null,  
                     source_value10 = null
              WHERE  source_value1  IN ('Scotia - Corp CAD AP Disb', 'Scotia - Corp USD AP Disb','Wach - Corp AP Disb',
                                        'Scotia AP Disbursements - USD','CORP-AP DISBURSEMENT','SCOTIA - CORP CAD AP DISB',
                    'SCOTIA - CORP USD AP DISB'
                    ) 
              AND    translate_id   = (SELECT translate_id 
                                       FROM   xx_fin_translatedefinition 
                                       WHERE  translation_name = 'AP_CHECK_PRINT_BANK_DTLS');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           BEGIN
              -----------------------------------------
              -- AP_NI_02 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AP_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AP_ESCHEAT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_02');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = '/acap/AbandonedProperty/TEST/OracleTestFiles'  
              WHERE  source_value1 = 'OD_AP_ESCHEAT'
              AND    translate_id  = (SELECT translate_id  
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------
              -- AP_NI_03 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AP_NI_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AP_PAR';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_03');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = '/acap/PostAudit/Test'
              WHERE  source_value1 = 'OD_AP_PAR'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_03 is:' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR';
              lc_result              := 'Unable to update transalation definition';
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------
              -- AP_NI_04 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AP_NI_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AP_TAX_AUDIT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AP_NI_04');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = '/ACTX/Test'
              WHERE  source_value1 = 'OD_AP_TAX_AUDIT'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------------------------------
              -- AP_NI_05 - Update for PO_VENDOR_SITES_ALL and PO_VENDOR_CONTACTS 
              -------------------------------------------------------------------
              lc_identifier          := 'AP_NI_05';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'ap_supplier_sites_all';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for standard tables - AP_NI_05');

              UPDATE ap_supplier_sites_all
              SET    email_address =  gc_email_address -- Changes done as per version 1.11 --'PO_Testing@officedepot.com'
              WHERE  email_address IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for email address, for AP_NI_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

              lc_object_name         := 'ap_supplier_sites_all';
              lc_action              := 'Update remittance email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              UPDATE ap_supplier_sites_all
              SET    remittance_email = gc_email_address -- Changes done as per version 1.11 --'PO_Testing@officedepot.com'
              WHERE  remittance_email IS NOT NULL; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for remittance email, for AP_NI_05 is: ' || SQL%rowcount );
              COMMIT;


              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

              lc_object_name         := 'ap_supplier_contacts';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              UPDATE ap_supplier_contacts
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'PO_Testing@officedepot.com'
              WHERE  email_address IS NOT NULL; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for ap_supplier_contacts(email address), for AP_NI_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------------------------------
              -- AP_NI_06 - Update for PO_VENDOR_SITES_ALL and PO_VENDOR_CONTACTS 
              -------------------------------------------------------------------
              lc_identifier          := 'AP_NI_06';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'ap_supplier_sites_all';
              lc_action              := 'Update fax area code';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_06');

              UPDATE ap_supplier_sites_all 
              SET    fax_area_code = '000'
              WHERE  fax_area_code IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated, for ap_supplier_sites_all(fax area code), for AP_NI_06 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

              lc_object_name         := 'ap_supplier_contacts';
              lc_action              := 'Update fax area code';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              UPDATE ap_supplier_contacts 
              SET    fax_area_code = '000' 
              WHERE  fax_area_code IS NOT NULL; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for ap_supplier_contacts(fax area code), for AP_NI_06 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------
              -- AP_NI_07 - Update for IBY_SYS_PMT_PROFILES_B 
              -----------------------------------------------
              lc_identifier          := 'AP_NI_07';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'IBY_SYS_PMT_PROFILES_B';
              lc_action              := 'Update default printer';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_07 Default Printer');

              UPDATE iby_sys_pmt_profiles_b
              SET    default_printer = 'noprint'
              WHERE  system_profile_code LIKE 'OD%' 
              AND    default_printer IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_07 default printer is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_07: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ------------------------------------------
              -- AP_NI_08 - Update for HZ_CONTACT_POINTS 
              ------------------------------------------
              lc_identifier          := 'AP_NI_08';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'HZ_CONTACT_POINTS';
              lc_action              := 'Update phone area code';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_08');

              BEGIN
               DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', FALSE);
              END;

              UPDATE hz_contact_points hcp5
              SET    phone_area_code         ='000'
              WHERE  hcp5. owner_table_name  = 'HZ_PARTIES'
              AND    hcp5.contact_point_type = 'PHONE'
              AND    hcp5.phone_line_type    = 'FAX'
              AND    hcp5.owner_table_id     IN (SELECT pvc.rel_party_id  
                                                 FROM   ap_supplier_contacts pvc
                                                        ,ap_supplier_sites_all pvs
                                                        ,hz_parties hp
                                                        ,hz_relationships hpr
                                                        ,hz_party_sites hps
                                                        ,hz_org_contacts hoc
                                                        ,hz_parties hp2
                                                        ,ap_suppliers aps
                                                 WHERE  pvc.per_party_id     = hp.party_id
                                                 AND    pvc.rel_party_id     = hp2.party_id
                                                 AND    pvc.party_site_id    = hps.party_site_id
                                                 AND    pvc.org_contact_id   = hoc.org_contact_id(+)
                                                 AND    pvc.relationship_id  = hpr.relationship_id
                                                 AND    hpr.directional_flag = 'F'
                                                 AND    pvs.party_site_id    = pvc.org_party_site_id
                                                 AND    pvs.vendor_id        = aps.vendor_id
                                                 AND    NVL( aps.vendor_type_lookup_code, 'DUMMY' ) <> 'EMPLOYEE')
              AND hcp5.phone_area_code IS NOT NULL;

              BEGIN
               DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', TRUE);
              END;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_08 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_08: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Standard Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------
              -- AP_NI_09 - Update for HZ_PARTIES 
              -----------------------------------
              lc_identifier          := 'AP_NI_09';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'HZ_PARTIES';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_09');

              BEGIN
                DBMS_RLS.ENABLE_POLICY('AR', 'HZ_PARTIES#', 'XX_CDH_UPD_PLCY_HZ_PARTIES', FALSE);
              END;

              UPDATE /*+ parallel(p) */ hz_parties p
              SET    email_address= gc_email_address -- Changes done as per version 1.11 --'PO_Testing@officedepot.com'
              WHERE  email_address is not null;

              BEGIN
                DBMS_RLS.ENABLE_POLICY('AR', 'HZ_PARTIES#', 'XX_CDH_UPD_PLCY_HZ_PARTIES', TRUE);
              END;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_09 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_09: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Standard Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_09: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------------------------------------
              -- AP_NI_10 - Update for HZ_PARTIES, HZ_CONTACT_POINTS and IBY_EXTERNAL_PAYEES_ALL 
              -----------------------------------------------------------------------------------
              lc_identifier          := 'AP_NI_10';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'HZ_CONTACT_POINTS';
              lc_action              := 'Update email address for HZ_PARTIES';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_10');

              BEGIN
                 DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', FALSE);
--                 EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
--
--                 UPDATE /*+ parallel(p) */ hz_contact_points p
--                 SET    email_address      = gc_email_address -- Changes done as per version 1.11 --'po_testing@officedepot.com'
--                 WHERE  owner_table_id     IN (SELECT /*+ parallel(s) */ party_id 
--                                               FROM   ap_suppliers s)
--                 AND    owner_table_name   = 'HZ_PARTIES'
--                 AND    contact_point_type = 'EMAIL';
--
--                 ln_count := SQL%rowcount;
--
--                 xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_10(HZ_PARTIES) is: ' || SQL%rowcount );
--                 COMMIT;
--
--                 lc_status        := 'Success'; 
--                 lc_result        := 'Updated: '||ln_count||' rows';   
--                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           
--
--                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
--                                 ,p_identifier         => lc_identifier
--                                 ,p_status             => lc_status
--                                 ,p_object_type        => lc_object_type
--                                 ,p_object_name        => lc_object_name
--                                 ,p_action             => lc_action
--                                 ,p_result             => lc_result
--                                 ,p_start_date_time    => ld_start_date_time
--                                 ,p_end_date_time      => ld_end_date_time
--                                 ,p_exception_message  => lc_exception_message);
--
--                 EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
--
--                 lc_object_name         := 'HZ_CONTACT_POINTS';
--                 lc_action              := 'Update email address for HZ_PARTY_SITES';
--                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
--
--                 ld_end_date_time       := NULL;
--                 lc_result              := NULL;
--                 lc_status              := NULL;
--                 ln_count               := 0;
--
--                 UPDATE /*+ parallel(p) */ hz_contact_points p
--                 SET    email_address      = gc_email_address -- Changes done as per version 1.11 --'po_testing@officedepot.com'
--                 WHERE  owner_table_id     IN (SELECT /*+ parallel(s) */ party_site_id 
--                                               FROM   ap_supplier_sites_all s)
--                 AND    owner_table_name   = 'HZ_PARTY_SITES'
--                 AND    contact_point_type = 'EMAIL';
--
--                 ln_count := SQL%rowcount;
--
--                 xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_10(HZ_PARTY_SITES) is: ' || SQL%rowcount );
--                 COMMIT;
--
--                 lc_status        := 'Success'; 
--                 lc_result        := 'Updated: '||ln_count||' rows';   
--                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           
--
--                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
--                                 ,p_identifier         => lc_identifier
--                                 ,p_status             => lc_status
--                                 ,p_object_type        => lc_object_type
--                                 ,p_object_name        => lc_object_name
--                                 ,p_action             => lc_action
--                                 ,p_result             => lc_result
--                                 ,p_start_date_time    => ld_start_date_time
--                                 ,p_end_date_time      => ld_end_date_time
--                                 ,p_exception_message  => lc_exception_message);
--
--                
--                  lc_object_name         := 'HZ_CONTACT_POINTS';
--                 lc_action              := 'Update email address for AP_SUPPLIER_CONTACTS';
--                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
--
--                 ld_end_date_time       := NULL;
--                 lc_result              := NULL;
--                 lc_status              := NULL;
--                 ln_count               := 0;
--
--                 
--                 UPDATE /*+ parallel(p) */ hz_contact_points p
--                 SET email_address         = gc_email_address -- Changes done as per version 1.11 --'po_testing@officedepot.com'
--                 WHERE owner_table_id     IN (SELECT /*+ parallel(s) */ rel_party_id 
--                                             FROM   ap_supplier_contacts s)
--                 AND owner_table_name      = 'HZ_PARTIES'
--                 AND contact_point_type    = 'EMAIL';
--
--                 ln_count := SQL%rowcount;
--
--                 xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_10(AP_SUPPLIER_CONTACTS) is: ' || SQL%rowcount );
--                 COMMIT;
--
--                 lc_status        := 'Success'; 
--                 lc_result        := 'Updated: '||ln_count||' rows';   
--                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           
--
--                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
--                                 ,p_identifier         => lc_identifier
--                                 ,p_status             => lc_status
--                                 ,p_object_type        => lc_object_type
--                                 ,p_object_name        => lc_object_name
--                                 ,p_action             => lc_action
--                                 ,p_result             => lc_result
--                                 ,p_start_date_time    => ld_start_date_time
--                                 ,p_end_date_time      => ld_end_date_time
--                                 ,p_exception_message  => lc_exception_message);

                                 
                 lc_object_name         := 'IBY_EXTERNAL_PAYEES_ALL';
                 lc_action              := 'Update email address';
                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE iby_external_payees_all p
                 SET    remit_advice_email = gc_email_address -- Changes done as per version 1.11 --'po_testing@officedepot.com'
                 WHERE  EXISTS (SELECT 1 
                                FROM   ap_suppliers aps 
                                WHERE  aps.party_id = p.payee_party_id)
                 AND    remit_advice_email IS NOT NULL;

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_10(IBY_EXTERNAL_PAYEES_ALL) is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';   
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';

                 DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', TRUE);  
              END;

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_10: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Standard Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_10: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
        
         BEGIN
              -----------------------------------------------
              -- AP_NI_11 - Update for XX_PO_VENDOR_SITES_ALL_AUD 
              -----------------------------------------------
              lc_identifier          := 'AP_NI_11';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_PO_VENDOR_SITES_ALL_AUD';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_11 PO Email Address');

              UPDATE xx_po_vendor_sites_all_aud 
                 SET email_address= gc_email_address  --'po_testing@officedepot.com'  V 1.11 --> Update E-mail
               WHERE email_address IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_11 PO Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_11: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update custom table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_11: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
        END;
        
       -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_12 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_12';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_12 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XX_AP_ESCH_PAR_MAIN_PRG'
                 and end_user_column_name ='p_email_addr_par';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_12 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_12: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_12: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
         
         -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_13 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_13';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_13 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XX_AP_ESCH_PAR_MAIN_PRG'
                 and end_user_column_name ='p_email_addr_esc';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_13 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_13: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_13: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
         
          -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_14 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_14';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_14 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXAPEFTPROC'
                 and end_user_column_name ='Email ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_14 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_14: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_14: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
        
         -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_15 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_15';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_15 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXAPPBP2'
                 and end_user_column_name ='Email ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_15 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_15: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_15: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
         
          -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_16 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_16';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_16 Email Address');

              update fnd_descr_flex_column_usages 
                  SET default_value = gc_email_address
                where descriptive_flexfield_name = '$SRS$.' ||'XXAPPBP1'
                  and end_user_column_name ='Email ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_16 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_16: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_16: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
         
           -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_17 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_17';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_17 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXAPPBP5'
                 and end_user_column_name ='Email ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_17 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_17: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_17: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
         
      -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- AP_NI_18 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AP_NI_18';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AP_NI_18 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXAPPBP4'
                 and end_user_column_name ='Email ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AP_NI_18 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AP_NI_18: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AP_NI_18: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
      EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Account Payables non instance specific steps: '||SQLERRM||CHR(10));
        END;
		
	BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Inventory ...'||CHR(10));
		 -- Added by Havish Kasina as per Defect 37152
          BEGIN
              ---------------------------------------------------------
              -- INV_NI_01 - Update for OD: INV Mail Host       
              ---------------------------------------------------------
              lc_identifier          := 'INV_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: INV Mail Host';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for INV_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_INV_MAIL_HOST'
                                                       ,x_value      => gc_mail_host 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for INV_NI_01' );
                 lc_result        := gc_mail_host; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for INV_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during INV_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during INV_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
       EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Inventory non instance specific steps: '||SQLERRM||CHR(10));
       END;
	   
	 	BEGIN
		  -- Added by Havish Kasina as per Defect 37152
          xx_write_to_log (lc_filehandle,'Start of update for Advanced Collections...'||CHR(10));
          BEGIN
              ---------------------------------------------------------
              -- IEX_NI_01 - Update for OD: IEX: SMTP Host      
              ---------------------------------------------------------
              lc_identifier          := 'IEX_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'IEX: SMTP Host';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for IEX_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IEX_SMTP_HOST'
                                                       ,x_value      => gc_mail_host 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for IEX_NI_01' );
                 lc_result        := gc_mail_host; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for IEX_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during IEX_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during IEX_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
       EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Advanced Collections non instance specific steps: '||SQLERRM||CHR(10));
       END;

      BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Purchasing ...'||CHR(10));
          BEGIN
              -----------------------------------------------
              -- PO_N1_01 - Update for PO_HEADERS_ALL 
              -----------------------------------------------
              lc_identifier          := 'PO_N1_01';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'PO_HEADERS_ALL';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for PO_N1_01 PO Email Address');

              UPDATE po_headers_all 
                 SET email_address= gc_email_address  --'po_testing@officedepot.com'  V 1.11 --> Update the E-mail 
               WHERE email_address IS NOT NULL; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for PO_N1_01 PO Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during PO_N1_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during PO_N1_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
       EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Purchasing non instance specific steps: '||SQLERRM||CHR(10));
       END;
   
       BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Receivables ...'||CHR(10));
           BEGIN
              -----------------------------------------
              -- AR_NI_03 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AR_NI_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_GET_AMEX_MERCHANT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AR_NI_03');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'MVSSYSD'
              WHERE  source_value1 = 'OD_GET_AMEX_MERCHANT'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           BEGIN
              -----------------------------------------
              -- AR_NI_04 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AR_NI_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AR_ESCHEATS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AR_NI_04');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = '/acap/AbandonedProperty/TEST/UATGB'
              WHERE  source_value1 = 'OD_AR_ESCHEATS'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------
              -- AR_NI_05 - Update for OD_FTP_PROCESSES 
              -----------------------------------------
              lc_identifier          := 'AR_NI_05';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AR_CREDITBKUP';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AR_NI_05');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'FUTURE'
              WHERE  source_value1 = 'OD_AR_CREDITBKUP'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           end;
           -- Added as per Version 1.11
           BEGIN
              ------------------------------------------------------
              -- AR_NI_06 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AR_NI_06';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_06 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXARGLIMPSUMM'
                 and end_user_column_name ='P_EMAIL_ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_06 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_06: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         end;
         
         -- Added as per Version 1.11
         BEGIN
              ------------------------------------------------------
              -- AR_NI_07 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'AR_NI_07';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_07 Email Address');

              update fnd_descr_flex_column_usages
                 set default_value = gc_email_address
               where end_user_column_name = 'e-mail to'
                 and descriptive_flexfield_name = '$SRS$.XXODSPCOPTRANS';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_07 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_07: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;
		 
		 -- Added as Per Version 1.16		   
		   BEGIN
              ------------------------------------------------------------------
              -- AR_NI_08 - Update for XX_FIN_SPC_CONFIG Translation   
              ------------------------------------------------------------------
              lc_identifier          := 'AR_NI_08';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_FIN_SPC_CONFIG';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, AR_NI_08');

              UPDATE xx_fin_translatevalues 
              SET    source_value1 = gc_email_address ,
			         source_value2 = gc_email_address
              WHERE  translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'XX_FIN_SPC_CONFIG');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_08 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_08: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Translation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   		 
		 -- Added as Per Version 1.26		   
		   BEGIN
              ------------------------------------------------------------------
              -- AR_NI_09 - Update for XXOD_AR_POD_URL Translation   
              ------------------------------------------------------------------
              lc_identifier          := 'AR_NI_09';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_AR_POD_URL';
              lc_action              := 'Update URL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, AR_NI_09');

              UPDATE xx_fin_translatevalues 
                 SET    source_value1 = 'http://sigcapdev80.uschecomrnd.net/SignatureCapture/BSDInquiry?data=summary|00000000|' ,
			            source_value2 = 'http://sigcapdev80.uschecomrnd.net/SignatureCapture/BSDInquiry?data=summary|00000000|'
               WHERE    translate_id  = (SELECT   translate_id 
                                           FROM   xx_fin_translatedefinition 
                                          WHERE   translation_name = 'XXOD_AR_POD_URL'); 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_09 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_09: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Translation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_09: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
	
    --  Added by Havish Kasina as per Version 1.35	
		   BEGIN
              --------------------------------------------------
              -- AR_NI_10 - Update for XX_AR_WC_EXT_CONTROL  
              --------------------------------------------------
              lc_identifier          := 'AR_NI_10';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_WC_EXT_CONTROL';
              lc_action              := 'Update POST_PROCESS_STATUS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_10');

              UPDATE xx_ar_wc_ext_control
                 SET post_process_status  ='Y',
                     pmt_upd_full         ='Y',
                     pmt_upd_delta        ='Y',
                     trx_ext_full         ='Y',
                     trx_ext_delta        ='Y',
                     trx_gen_file         ='Y',
                     rec_ext_full         ='Y',
                     rec_ext_delta        ='Y',
                     rec_gen_file         ='Y',
                     adj_ext_full         ='Y',
                     adj_ext_delta        ='Y',
                     adj_gen_file         ='Y',
                     pmt_ext_full         ='Y',
                     pmt_ext_delta        ='Y',
                     pmt_gen_file         ='Y',
                     app_ext_full         ='Y',
                     app_ext_delta        ='Y',
                     app_gen_file         ='Y',
                     diary_notes_ext      ='Y',
                     ar_recon             ='Y'
               WHERE cycle_date = (SELECT MAX(cycle_date)
                                     FROM xx_ar_wc_ext_control);
									 
              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_10 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_10: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Webcollect details';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_10: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
	 --  Added by Havish Kasina as per Version 1.53
		   BEGIN
              --------------------------------------------------
              -- AR_NI_11 - Update for XX_AR_CONTRACTS  
              --------------------------------------------------
              lc_identifier          := 'AR_NI_11';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_CONTRACTS';
              lc_action              := 'Update CUSTOMER_EMAIL and CARD_TOKEN';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_11');

              UPDATE xx_ar_contracts
                 SET customer_email = null,
				     card_token = null;
									 
              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_NI_11 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_11: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update XX_AR_CONTRACTS table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_11: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
	
	
	 --  Added by Havish Kasina as per Version 1.53
		   BEGIN
              --------------------------------------------------
              -- AR_NI_12 - Truncate XX_AR_SUBSCRIPTION_PAYLOADS  
              --------------------------------------------------
              lc_identifier          := 'AR_NI_12';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_SUBSCRIPTION_PAYLOADS';
              lc_action              := 'Truncate XX_AR_SUBSCRIPTION_PAYLOADS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_12');

              EXECUTE IMMEDIATE 'TRUNCATE TABLE xx_ar_subscription_payloads';
									 
              lc_status        := 'Success'; 
              lc_result        := 'Truncated XX_AR_SUBSCRIPTION_PAYLOADS';    
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_12: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to truncate XX_AR_SUBSCRIPTION_PAYLOADS table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_12: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   	 --  Added by Havish Kasina as per Version 1.56
		   BEGIN
              --------------------------------------------------
              -- AR_NI_13 - Update Translation OD_VPS_TRANSLATION
              --------------------------------------------------
              lc_identifier          := 'AR_NI_13';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_VPS_TRANSLATION';
              lc_action              := 'Update OD_VPS_TRANSLATION';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for AR_NI_13');

              UPDATE xx_fin_translatevalues 
                 SET target_value1 = gc_email_address,
                     target_value2 = gc_email_address
               WHERE source_value1 IN ( 'SYSTEMATIC_NETTING',
                                        'REFUNDS',
                                        'MANUAL_NETTING',
                                        'AUTOAPPLY_CM_INV',
                                        'CORE_BACKUP_EXCEPTION',
                                        'DISCREPANCY_REPORT',
                                        'SMALL_DOLLAR_PENNY_ADJ',
                                        'VPS_CUST_STATEMENTS'
                                      )
                 AND translate_id  = (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name = 'OD_VPS_TRANSLATION');
									 
              lc_status        := 'Success'; 
              lc_result        := 'Updated OD_VPS_TRANSLATION';    
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_NI_13: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update OD_VPS_TRANSLATION Translation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_NI_13: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

         
       EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Receivables non instance specific steps: '||SQLERRM||CHR(10));
       END;
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Billing ...'||CHR(10));
           BEGIN
              --------------------------------------------------
              -- Bill_NI_01 - Update for XX_AR_EBL_TRANSMISSION  
              --------------------------------------------------
              lc_identifier          := 'Bill_NI_01';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_EBL_TRANSMISSION';
              lc_action              := 'Update DEST_EMAIL_ADDR';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_01');

              UPDATE xx_ar_ebl_transmission
              SET    dest_email_addr = gc_email_address -- Changes done as per version 1.11 --'OfficeDepot.eBilling@gmail.comDUMMY'
              WHERE  dest_email_addr IS NOT NULL; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transmission details';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------------------
              -- Bill_NI_02 - Update for XX_CDH_EBL_TRANSMISSION_DTL  
              -------------------------------------------------------
              lc_identifier          := 'Bill_NI_02';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_CDH_EBL_TRANSMISSION_DTL';
              lc_action              := 'Update FTP_CUST_CONTACT_EMAIL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_02');

              update xx_cdh_ebl_transmission_dtl
              SET    ftp_cust_contact_email = gc_email_address -- Changes done as per version 1.11 --ftp_cust_contact_email||'DUMMY'
              WHERE  ftp_cust_contact_email IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer contact email, for Bill_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

              lc_action              := 'Update FTP_CC_EMAILS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              update xx_cdh_ebl_transmission_dtl
              SET    ftp_cc_emails = gc_email_address -- Changes done as per version 1.11 -- ftp_cc_emails||'DUMMY'
              WHERE  ftp_cc_emails IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for cc email, for Bill_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transmission details';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- Bill_NI_03 - Update for HZ_CONTACT_POINTS  
              ---------------------------------------------
              lc_identifier          := 'Bill_NI_03';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'HZ_CONTACT_POINTS';
              lc_action              := 'Update contact email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_03');

              BEGIN
                 DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', FALSE);
                 EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML'; 
                 
                 --After discussin with the team, commenting out this update. We want to update **ALL** email addresses to DUMMY
                 --UPDATE /*+ parallel(p) */ hz_contact_points p
                 --   SET email_address = email_address||'DUMMY'
                 -- WHERE contact_point_purpose IN ( 'STATEMENTS','BILLING');

                 --After discussing with the team, we want to update **ALL** email addresses to DUMMY, and no restriction to parallel threads
                 UPDATE /*+parallel(p) full(p)*/  hz_contact_points p
                    SET email_address = gc_email_address  --email_address||'DUMMY'  V 1.11 Update E-mail --> Havish Kasina
                  WHERE 1 =1 
                    AND contact_point_type = 'EMAIL'
                    --AND contact_point_purpose IN ( 'STATEMENTS','BILLING')
                  ;  

                 ln_count := SQL%rowcount;
 
                 xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_03 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML'; 

                 DBMS_RLS.ENABLE_POLICY('AR', 'HZ_CONTACT_POINTS#', 'XX_CDH_UPD_PLCY_HZ_CNCT_PNT', TRUE);  
              END;

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_04 - Update for AR_STANDARD_TEXT_TL 
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_04';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'AR_STANDARD_TEXT_TL';
              lc_action              := 'Update OD_CUST_STMT_FROM_EMAIL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_04');

              UPDATE ar_standard_text_tl
              SET    text = gc_email_address -- Changes done as per version 1.11 --'ebill_mailbox_test@officedepot.com'
              WHERE  standard_text_id = (SELECT standard_text_id 
                                         FROM   ar_standard_text_b 
                                         WHERE  name = 'OD_CUST_STMT_FROM_EMAIL');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_05 - Update for XX_AR_STMT_TYPES    
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_05';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_AR_STMT_TYPES';
              lc_action              := 'Update XX_AR_STMT_TYPES';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_05');

              UPDATE xx_fin_translatevalues
              SET    target_value10 = gc_email_address   --'ebill_mailbox_test@officedepot.com'  V 1.11 --> Update E-mail
              WHERE  SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1)
              AND    enabled_flag   = 'Y'
              AND    target_value2 IS NOT NULL
              AND    target_value3 IS NOT NULL
              AND    target_value4 IS NOT NULL
              AND    target_value5 IS NOT NULL
              AND    translate_id IN(SELECT translate_id 
                                     FROM   xx_fin_translatedefinition 
                                     WHERE  translation_name = 'XX_AR_STMT_TYPES'
                                     AND    enabled_flag     = 'Y'
                                     AND    SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1));

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_06 - Update for OD_FTP_PROCESSES    
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_06';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update FTP_EBILL_PROCESS_REPORT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_06');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'uschfinbilldev',
                     target_value5 = '/OracleTest/Process_Reports'
              WHERE  source_value1 = 'FTP_EBILL_PROCESS_REPORT'
              AND    translate_id IN (SELECT translate_id 
                                      FROM   XX_FIN_TRANSLATEDEFINITION 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_06 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR';
              lc_result              := 'Unable to update transalation definition';
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_07 - Update for AR_EBL_EMAIL_CONFIG 
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_07';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AR_EBL_EMAIL_CONFIG';
              lc_action              := 'Update RESEND';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_07');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_mail_host,   -- Commented as per Version 1.10 'uschmsx28.na.odcorp.net'
                     target_value3 = gc_email_address   --'ebill_mailbox_test@officedepot.com'  V 1.11 --> Update E-mail
              WHERE  source_value1 = 'RESEND'
              AND    translate_id IN (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'AR_EBL_EMAIL_CONFIG');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_07 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_07: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_08 - Update for AR_EBL_FTP_CONFIG   
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_08';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AR_EBL_FTP_CONFIG';
              lc_action              := 'Update AR_EBL_FTP_CONFIG';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_08');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = NULL, 
                     target_value3 = NULL
              WHERE  translate_id IN(SELECT translate_id 
                                     FROM   xx_fin_translatedefinition 
                                     WHERE  translation_name = 'AR_EBL_FTP_CONFIG');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_08 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_08: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_09 - Update for OD_AR_SOX_BILLING   
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_09';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_AR_SOX_BILLING';
              lc_action              := 'Update OD_AR_SOX_BILLING';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_09');

              UPDATE xx_fin_translatevalues
              SET    target_value1 = gc_email_address --'ebill_mailbox_test@officedepot.com'  V 1.11 --> Update E-mail
              WHERE  translate_id  = (SELECT translate_id FROM xx_fin_translatedefinition
                                      WHERE  translation_name = 'OD_AR_SOX_BILLING')
                                      AND    source_value1 IN ('Certegy'
                                                               ,'EBill'
                                                               ,'EDI'
                                                               ,'Special Handling'
                                                               ,'eTXT'
                                                               ,'eXLS'
                                                               ,'ePDF');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_09 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_09:'||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_09: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_10 - Update for AR_EBL_CONFIG      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_10';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AR_EBL_CONFIG';
              lc_action              := 'Update NOTIFY_CD';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_10');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = '200'
              WHERE  source_value1 = 'NOTIFY_CD'
              AND    source_value2 = 'NO_OLDER_THAN_N_DAYS'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'AR_EBL_CONFIG');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_10 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_10: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_10: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_11 - Update for AR_EBL_CONFIG      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_11';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AR_EBL_CONFIG';
              lc_action              := 'Update OD_AR_EBILL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_11');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 =  'USCHFS1'   --'Uschfinbilldev'-- Changed as per Version 1.25
			        ,target_value5 =  '/FinBillDev/MBSELEC' -- Added as per Version 1.32
              WHERE  source_value1 = 'OD_AR_EBILL'
              AND    translate_id  = (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_11 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_11: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during Bill_NI_11: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_12 - Update for XX_AR_EBL_CONS_HDR_HIST      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_12';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_EBL_CONS_HDR_HIST';
              lc_action              := 'Update XX_AR_EBL_CONS_HDR_HIST';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_12');

              UPDATE /*+ parallel(p) */ XX_AR_EBL_CONS_HDR_HIST p
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_12 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_12: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during Bill_NI_12: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_13 - Update for XX_AR_EBL_CONS_HDR_MAIN      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_13';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_EBL_CONS_HDR_MAIN';
              lc_action              := 'Update XX_AR_EBL_CONS_HDR_MAIN';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_13');

              UPDATE XX_AR_EBL_CONS_HDR_MAIN
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_13 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_13: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during Bill_NI_13: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_14 - Update for XX_AR_EBL_IND_HDR_HIST      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_14';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_EBL_IND_HDR_HIST';
              lc_action              := 'Update XX_AR_EBL_IND_HDR_HIST';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_14');

              UPDATE /*+ parallel(p) */ XX_AR_EBL_IND_HDR_HIST p
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_14 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_14: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during Bill_NI_14: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- Bill_NI_15 - Update for XX_AR_EBL_IND_HDR_MAIN      
              ----------------------------------------------
              lc_identifier          := 'Bill_NI_15';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_AR_EBL_IND_HDR_MAIN';
              lc_action              := 'Update XX_AR_EBL_IND_HDR_MAIN';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_15');

              UPDATE XX_AR_EBL_IND_HDR_MAIN
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_15 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_15: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during Bill_NI_15: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;
           
           -- V 1.11 --> Added the Email
           BEGIN
              ---------------------------------------------------
              -- Bill_NI_16 - Update for OD_AR_ALL_IN_ONE_BILLING   
              ---------------------------------------------------
              lc_identifier          := 'Bill_NI_16';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_AR_ALL_IN_ONE_BILLING';
              lc_action              := 'Update OD_AR_ALL_IN_ONE_BILLING';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_16');

              UPDATE xx_fin_translatevalues
                 SET target_value1= gc_email_address
              where translate_id in (select translate_id from xx_fin_translatedefinition 
                                      WHERE translation_name = 'OD_AR_ALL_IN_ONE_BILLING'
                                        AND enabled_flag = 'Y');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_16 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_16:'||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_16: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		-- V 1.37 --> Added by Havish Kasina as per Defect 37166
           BEGIN
              ---------------------------------------------------------------------------------------------------------------------------------
              -- Bill_NI_17 - To Update the description of the program 'OD: AR EBL Transmit eBills via Email (Parent)' and disable the program   
              ---------------------------------------------------------------------------------------------------------------------------------
              lc_identifier          := 'Bill_NI_17';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'OD: AR EBL Transmit eBills via Email (Parent)';
              lc_action              := 'Disable the program OD: AR EBL Transmit eBills via Email (Parent)';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_NI_17');

                 UPDATE fnd_concurrent_programs_tl
                    SET description = '***** Check with Billing SME before Enable *****'
                  WHERE user_concurrent_program_name = 'OD: AR EBL Transmit eBills via Email (Parent)';

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_NI_17 is: ' || SQL%rowcount );
              COMMIT;
			  
			  xx_write_to_log (lc_filehandle,'Disabling the Concurrent Program OD: AR EBL Transmit eBills via Email (Parent)');
			  
              fnd_program.enable_program('XX_AR_EBL_TRANSMIT_EMAIL_P',     --CP Short Name
                                         'XXFIN', -- Application Name
                                         'N'); 
										 
			  COMMIT;
			  
			   SELECT COUNT(1) 
			     INTO ln_count
				 FROM fnd_concurrent_programs a,
                      fnd_concurrent_programs_tl b
                WHERE a.concurrent_program_id=b.concurrent_program_id 
                  AND b.user_concurrent_program_name = 'OD: AR EBL Transmit eBills via Email (Parent)'
				  AND a.enabled_flag = 'N';
				  
			  IF ln_count = 1
			  THEN
			  
                lc_status        := 'Success'; 
                lc_result        := 'Updated: '||ln_count||' rows';
                ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
		      ELSE
			    lc_status        := 'ERROR'; 
                lc_result        := 'Updated: '||ln_count||' rows';
                ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS'); 
              END IF;
              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_NI_16:'||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_NI_16: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
          END;


        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Billing non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for CDH ...'||CHR(10));
           BEGIN
              ------------------------------------------------------------
              -- CDH_NI_01 - Update for OD: CDH AOPS AB FLAG DB Link Name  
              ------------------------------------------------------------
              lc_identifier          := 'CDH_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: CDH AOPS AB FLAG DB Link Name';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_AB_FLAG_DBLINK_NAME'
                                                       ,x_value      => 'racoondta.ccu007f@AS400.NA.odcorp.net'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_01' );
                 lc_result        := 'racoondta.ccu007f@AS400.NA.odcorp.net';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------------
              -- CDH_NI_02 - Update for OD: CDH AOPS AB FLAG DET DB Link Name  
              ----------------------------------------------------------------
              lc_identifier          := 'CDH_NI_02';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: CDH AOPS AB FLAG DET DB Link Name';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_02');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_AB_FLAG_DET_DBLINK_NAME'
                                                       ,x_value      => 'racoondta.fcu000p@AS400.NA.odcorp.net'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_02' );
                 lc_result        := 'racoondta.fcu000p@AS400.NA.odcorp.net';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_02' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------------
              -- CDH_NI_03 - Update for OD: CDH AOPS MISMATCH DB LINK NAME     
              ----------------------------------------------------------------
              lc_identifier          := 'CDH_NI_03';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: CDH AOPS MISMATCH DB LINK NAME';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_03');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_AOPS_MISMATCH_DBLINK_NAME'
                                                       ,x_value      => 'RACOONDTA.FCU005P@AS400.NA.ODCORP.NET'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_03' );
                 lc_result        := 'RACOONDTA.FCU005P@AS400.NA.ODCORP.NET';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_03' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------------
              -- CDH_NI_04 - Update for OD: CDH Conversion AOPS DB Link Name   
              ----------------------------------------------------------------
              lc_identifier          := 'CDH_NI_04';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: CDH Conversion AOPS DB Link Name';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_04');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_OWB_AOPS_DBLINK_NAME'
                                                       ,x_value      => 'ODWORKFILE.OREBATCHF@AS400.NA.ODCORP.NET'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_04' );
                 lc_result        := 'ODWORKFILE.OREBATCHF@AS400.NA.ODCORP.NET';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_04' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------------------------
              -- CDH_NI_05 - Update for OD: DB link for Rels table in AOPS   
              --------------------------------------------------------------
              lc_identifier          := 'CDH_NI_05';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: DB link for Rels table in AOPS';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_05');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_RELS_AOPS_DB_LINK'
                                                       ,x_value      => 'RACOONDTA.FCU005P@AS400.NA.ODCORP.NET'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_05' );
                 lc_result        := 'RACOONDTA.FCU005P@AS400.NA.ODCORP.NET';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_05' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------
              -- CDH_NI_06 - Update for OD: GP AOPS HOST  
              -------------------------------------------
              lc_identifier          := 'CDH_NI_06';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: GP AOPS HOST';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_06');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_GP_AOPS_HOST'
                                                       ,x_value      => 'AS400'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_06' );
                 lc_result        := 'AS400';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_06' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------
              -- CDH_NI_07 - Update for XXCOM: Web Contacts Source Table 
              ----------------------------------------------------------
              lc_identifier          := 'CDH_NI_07';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'XXCOM: Web Contacts Source Table';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_07');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XXOD_WEB_USERS_SOURCE_TABLE'
                                                       ,x_value      => 'CSTAOSYNC.FNDIRLST@AS400.NA.ODCORP.NET'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_07'||CHR(10));
                 lc_result        := 'CSTAOSYNC.FNDIRLST@AS400.NA.ODCORP.NET';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_07'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_07: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

-- Commented this identifier because the table XXBI_CONTACT_MV_TBL no longer exists 
--         BEGIN
--              ----------------------------------------------
--              -- CDH_NI_08 - Update for XXBI_CONTACT_MV_TBL      
--              ----------------------------------------------
--              lc_identifier          := 'CDH_NI_08';
--              lc_object_type         := 'Custom Table';
--              lc_object_name         := 'XXBI_CONTACT_MV_TBL';
--              lc_action              := 'Update XXBI_CONTACT_MV_TBL';
--              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
--
--              ld_end_date_time       := NULL;
--              lc_exception_message   := NULL;
--              lc_result              := NULL;
--              lc_status              := NULL;
--              ln_count               := 0;
--
--              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_08');
--
--              UPDATE /*+ parallel(p) */ XXBI_CONTACT_MV_TBL p
--              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
--              WHERE  email_address is NOT NULL;
--
--              ln_count := SQL%rowcount;
--
--              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_08 is: ' || SQL%rowcount||CHR(10) );
--              COMMIT;
--
--              lc_status        := 'Success'; 
--              lc_result        := 'Updated: '||ln_count||' rows';
--              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
--
--              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
--                              ,p_identifier         => lc_identifier
--                              ,p_status             => lc_status
--                              ,p_object_type        => lc_object_type
--                              ,p_object_name        => lc_object_name
--                              ,p_action             => lc_action
--                              ,p_result             => lc_result
--                              ,p_start_date_time    => ld_start_date_time
--                              ,p_end_date_time      => ld_end_date_time
--                              ,p_exception_message  => lc_exception_message);
--
--           EXCEPTION 
--              WHEN OTHERS THEN
--                 xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_08: '||SQLERRM||CHR(10));
--                 ROLLBACK;
--                 lc_status              := 'ERROR'; 
--                 lc_result              := 'Unable to update transalation definition';   
--                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
--                 lc_exception_message   := 'Error encountered during CDH_NI_08: '||SQLERRM;
--
--                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
--                                 ,p_identifier         => lc_identifier
--                                 ,p_status             => lc_status
--                                 ,p_object_type        => lc_object_type
--                                 ,p_object_name        => lc_object_name
--                                 ,p_action             => lc_action
--                                 ,p_result             => lc_result
--                                 ,p_start_date_time    => ld_start_date_time
--                                 ,p_end_date_time      => ld_end_date_time
--                                 ,p_exception_message  => lc_exception_message);
--           END;
           

           BEGIN
              ----------------------------------------------
              -- CDH_NI_09 - Update for XX_CDH_EBL_CONV_CONTACT_DTL
              ----------------------------------------------
              lc_identifier          := 'CDH_NI_09';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_CDH_EBL_CONV_CONTACT_DTL';
              lc_action              := 'Update XX_CDH_EBL_CONV_CONTACT_DTL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_09');

              UPDATE XX_CDH_EBL_CONV_CONTACT_DTL
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_09 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_09: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during CDH_NI_09: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- CDH_NI_10 - Update for XX_CDH_EBL_CONV_LOGIN_DTL
              ----------------------------------------------
              lc_identifier          := 'CDH_NI_10';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_CDH_EBL_CONV_LOGIN_DTL';
              lc_action              := 'Update XX_CDH_EBL_CONV_LOGIN_DTL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_10');

              UPDATE XX_CDH_EBL_CONV_LOGIN_DTL
              SET    email_address = gc_email_address -- Changes done as per version 1.11 --'DUMMY@OFFICEDEPOT.COM'
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_10 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_10: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during CDH_NI_10: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ------------------------------------------------------------
              -- CDH_NI_11 - Update for Profile Option XX_CDH_RELS_EMAIL_ID
              ------------------------------------------------------------
              lc_identifier          := 'CDH_NI_11';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'XX_CDH_RELS_EMAIL_ID';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_11');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_RELS_EMAIL_ID'
                                                       ,x_value      => gc_email_address -- Changes done as per version 1.11 --'IT_ERP_SYSTEMS@officedepot.com'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_11' );
                 lc_result        := gc_email_address; -- Changes done as per version 1.11 --'IT_ERP_SYSTEMS@officedepot.com';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_11' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_11: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_11: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------
              -- CDH_NI_12 - Update for WF_LOCAL_ROLES
              ----------------------------------------------
              lc_identifier          := 'CDH_NI_12';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'WF_LOCAL_ROLES';
              lc_action              := 'Update WF_LOCAL_ROLES';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_12');

              UPDATE /*+parallel(b) full(b)*/ WF_LOCAL_ROLES b
              SET    email_address =gc_email_address ---'DUMMY@OFFICEDEPOT.COM' -- V 1.11 --> Update E-mail Address
              WHERE  email_address is NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_12 is: ' || SQL%rowcount||CHR(10) );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
                 xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_12: '||SQLERRM||CHR(10));
                 ROLLBACK;
                 lc_status              := 'ERROR'; 
                 lc_result              := 'Unable to update transalation definition';   
                 ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_exception_message   := 'Error encountered during CDH_NI_12: '||SQLERRM;

                 xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
           END;
          
          -- Added as per Version 1.11 
           BEGIN
              -----------------------------------------------------------
              -- CDH_NI_13 - Update for XX_CDH_DATA_ALERTER Translation 
              -----------------------------------------------------------
              lc_identifier          := 'CDH_NI_13';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_CDH_DATA_ALERTER';
              lc_action              := 'Update Mail Server and Mail To';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_13');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_mail_host,  
                     target_value3 = gc_email_address   
              WHERE  1 = 1
              AND    translate_id IN (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'XX_CDH_DATA_ALERTER');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_13 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_13: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_13: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- Added as per Version 1.10 
            BEGIN
              ---------------------------------------------------------
              -- CDH_NI_14 - Update for OD: CDH Rels Mail Server        
              ---------------------------------------------------------
              lc_identifier          := 'CDH_NI_14';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: CDH Rels Mail Server';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_14');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CDH_REL_MAIL_SERVER'
                                                       ,x_value      => gc_mail_host 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for CDH_NI_14' );
                 lc_result        := gc_mail_host; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for CDH_NI_14' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_14: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
         -- Added as per Version 1.10 
           BEGIN
              --------------------------------------------------------------
              -- CDH_NI_15 - Update for XXOD_OMX_MOD4_INTERFACE Translation 
              --------------------------------------------------------------
              lc_identifier          := 'CDH_NI_15';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_OMX_MOD4_INTERFACE';
              lc_action              := 'Update Email(Recepients)';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CDH_NI_15');
                                      
              UPDATE xx_fin_translatevalues 
                 SET target_value4 = gc_email_address   
               WHERE  1 = 1
                 AND  translate_id IN (SELECT translate_id 
                                         FROM xx_fin_translatedefinition
                                        WHERE translation_name = 'XXOD_OMX_MOD4_INTERFACE')
                 AND  target_value4 IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CDH_NI_15 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CDH_NI_15: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CDH_NI_15: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during CDH non instance specific steps: '||SQLERRM||CHR(10));
        END;
        
        -- V 1.11 --> Added Email Address
          BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for CRM ...'||CHR(10));
           BEGIN
              ---------------------------------------------
              -- CRM_NI_01 - Update for XX_CRM_MAIL_LIST    
              ---------------------------------------------
              lc_identifier          := 'CRM_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_CRM_MAIL_LIST';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for CRM_NI_01');

              UPDATE xx_fin_translatevalues
                 SET target_value1= gc_email_address
               where translate_id in (select translate_id from xx_fin_translatedefinition 
                                       WHERE translation_name = 'XX_CRM_MAIL_LIST' 
                                         AND enabled_flag = 'Y');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for CRM_NI_01 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during CRM_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during CRM_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during CRM non instance specific steps: '||SQLERRM||CHR(10));
        END;
        
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for FND ...'||CHR(10));
        
           -- Added 1.10 -- New Profile Option XX_COMN_SMTP_MAIL_SERVER
           BEGIN
              ---------------------------------------------
              -- FND_NI_01 - Update for OD: SMTP Mail Server 
              ---------------------------------------------
              lc_identifier          := 'FND_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: SMTP Mail Server';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_COMN_SMTP_MAIL_SERVER'
                                                       ,x_value      =>  gc_mail_host
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for FND_NI_01' );
                 lc_result        := gc_mail_host;
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for FND_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
          -- Added 1.11 -- Update E-mail Address 
           BEGIN
              ------------------------------------------------------
              -- FND_NI_02 - Update E-mail address in FND_USER Table 
              ------------------------------------------------------
              lc_identifier          := 'FND_NI_02';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_USER';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_02');

                UPDATE /*+parallel(b) full(b)*/ fnd_user b
                   SET    b.email_address  = gc_email_address
                 WHERE b.email_address IS NOT NULL;
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_NI_02 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the Email Address';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- Added V 1.14 -- Added to know the concurrent programs which are running currently 
		   -- Commented by Havish Kasina as per Defect 37269
         /*  BEGIN
              ---------------------------------------------------------------------------
              -- FND_NI_03 - Checking the count of Concurrent Programs which are running 
              ---------------------------------------------------------------------------
              lc_identifier          := 'FND_NI_03';
              LC_OBJECT_TYPE         := 'Standard Tables';
              LC_OBJECT_NAME         := 'FND_CONCURRENT_REQUESTS,FND_CONCURRENT_PROGRAMS,FND_CONCURRENT_PROGRAMS_TL,FND_USER';
              lc_action              := 'Get the count of Running Concurrent Programs';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start for FND_NI_03');

                FOR cur_rec IN (SELECT DISTINCT  c.user_concurrent_program_name,
                                                 a.request_id,
                                                 a.parent_request_id,
                                                 a.request_date,
                                                 d.user_name,
                                                 A.STATUS_CODE,
                                                 DECODE(a.phase_code,'C','Completed','I','Inactive','P','Pending','R','Running') phase_code
                                           FROM  fnd_concurrent_requests a,
                                                 fnd_concurrent_programs b,
                                                 fnd_concurrent_programs_tl c,
                                                 fnd_user d
                                          WHERE  a.concurrent_program_id=b.concurrent_program_id 
                                            AND  b.concurrent_program_id=c.concurrent_program_id 
                                            AND  a.requested_by=d.user_id 
                                            AND  (a.phase_code='R' OR a.status_code = 'T')
                                UNION
                                 SELECT DISTINCT  c.user_concurrent_program_name,
                                                 a.request_id,
                                                 a.parent_request_id,
                                                 a.request_date,
                                                 d.user_name,
                                                 A.STATUS_CODE,
                                                 DECODE(a.phase_code,'C','Completed','I','Inactive','P','Pending','R','Running') phase_code
                                           FROM  fnd_concurrent_requests a,
                                                 fnd_concurrent_programs b,
                                                 fnd_concurrent_programs_tl c,
                                                 fnd_user d
                                          WHERE  a.concurrent_program_id=b.concurrent_program_id 
                                            AND  b.concurrent_program_id=c.concurrent_program_id 
                                            AND  a.REQUESTED_BY=d.USER_ID 
                                            AND  a.PHASE_CODE='P' 
                                            AND  a.status_code IN ('Q','I'))
                 LOOP
                     lc_flag := 'Y';
                    begin
                        xx_write_to_log (lc_filehandle,'Concurent Programs Information which are either Running or Pending');              
                        LC_STATUS        := 'ERROR'; 
                        lc_result        := 'Concurrent Program:'||cur_rec.user_concurrent_program_name||' is '||cur_rec.phase_code;
                        LD_END_DATE_TIME := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                        lc_exception_message := 'Request Id:'||cur_rec.REQUEST_ID||' Parent Request Id:'||cur_rec.PARENT_REQUEST_ID||' User Name :'||cur_rec.USER_NAME;

                        xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                        ,p_identifier         => lc_identifier
                                        ,p_status             => lc_status
                                        ,p_object_type        => lc_object_type
                                        ,p_object_name        => lc_object_name
                                        ,p_action             => lc_action
                                        ,p_result             => lc_result
                                        ,p_start_date_time    => ld_start_date_time
                                        ,p_end_date_time      => ld_end_date_time
                                        ,p_exception_message  => lc_exception_message);
                    EXCEPTION
                      WHEN OTHERS 
                      THEN
                        xx_write_to_log (lc_filehandle,'Unable to get the Concurent Programs Information');              
                        lc_status        := 'ERROR'; 
                        lc_result        := 'Concurrent Program:'||cur_rec.user_concurrent_program_name;
                        ld_end_date_time := to_char(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                        lc_exception_message := SUBSTR(SQLERRM,1,255);

                        xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                        ,p_identifier         => lc_identifier
                                        ,p_status             => lc_status
                                        ,p_object_type        => lc_object_type
                                        ,p_object_name        => lc_object_name
                                        ,p_action             => lc_action
                                        ,p_result             => lc_result
                                        ,p_start_date_time    => ld_start_date_time
                                        ,p_end_date_time      => ld_end_date_time
                                        ,p_exception_message  => lc_exception_message);
                   END;
              END LOOP;
            
            IF lc_flag <> 'Y'
            then
                   xx_write_to_log (lc_filehandle,'Concurent Jobs are neither Running nor Pending');              
                        lc_status        := 'SUCCESS'; 
                        lc_result        := 'Concurent Jobs are neither Running nor Pending';
                        ld_end_date_time := to_char(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                        lc_exception_message := NULL;

                        xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                        ,p_identifier         => lc_identifier
                                        ,p_status             => lc_status
                                        ,p_object_type        => lc_object_type
                                        ,p_object_name        => lc_object_name
                                        ,p_action             => lc_action
                                        ,p_result             => lc_result
                                        ,p_start_date_time    => ld_start_date_time
                                        ,p_end_date_time      => ld_end_date_time
                                        ,p_exception_message  => lc_exception_message);
            END IF;

           EXCEPTION 
              when OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_03: '||SQLERRM);
              ROLLBACK;
              LC_STATUS              := 'ERROR'; 
              lc_result              := 'Unable to Get the Concurrent Progarms Information';   
              LD_END_DATE_TIME       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		 */ 
       -- Added by Havish Kasina as per Version 1.38 (Defect 37269)	 
		 BEGIN
              --------------------------------------------------------------------------------------------
              -- FND_NI_03 - Checking the count of Concurrent Programs which are either running or pending
              --------------------------------------------------------------------------------------------
              lc_identifier          := 'FND_NI_03';
              LC_OBJECT_TYPE         := 'Standard Tables';
              LC_OBJECT_NAME         := 'FND_CONCURRENT_REQUESTS and FND_USER';
              lc_action              := 'Get the count of Running or Pending Concurrent Programs';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_running_count       := 0;
			  ln_pending_count       := 0;
              
              xx_write_to_log (lc_filehandle,'Start for FND_NI_03');

				    SELECT COUNT(a.request_id)
					  INTO ln_running_count
                      FROM fnd_concurrent_requests a,
                           fnd_user d
                     WHERE 1 = 1
                       AND a.requested_by=d.user_id 
                       AND (a.phase_code='R' OR a.status_code = 'T')
                       AND d.user_name IN ('SVC_ESP_FIN', 'SVC_ESP_OM', 'SVC_ESP_OMX', 'SVC_ESP_CRM');
					   
					SELECT COUNT(a.request_id)
					  INTO ln_pending_count
                      FROM fnd_concurrent_requests a,
                           fnd_user d
                     WHERE 1 = 1
                       AND a.requested_by=d.user_id 
                       AND a.phase_code='P' 
                       AND a.status_code IN ('Q','I')
                       AND d.user_name IN ('SVC_ESP_FIN', 'SVC_ESP_OM', 'SVC_ESP_OMX', 'SVC_ESP_CRM');
					   
					 IF ln_running_count>0 OR ln_pending_count>0 
					 THEN					   
                        xx_write_to_log (lc_filehandle,'Concurent Jobs are either Running or Pending');              
                        LC_STATUS        := 'ERROR'; 
                        lc_result        := 'Concurent Jobs are either Running or Pending';
                        LD_END_DATE_TIME := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                        lc_exception_message := 'Number of programs are in Pending status: '||ln_pending_count||' and '||'Number of programs are in Running status: '||ln_running_count;

                        xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                        ,p_identifier         => lc_identifier
                                        ,p_status             => lc_status
                                        ,p_object_type        => lc_object_type
                                        ,p_object_name        => lc_object_name
                                        ,p_action             => lc_action
                                        ,p_result             => lc_result
                                        ,p_start_date_time    => ld_start_date_time
                                        ,p_end_date_time      => ld_end_date_time
                                        ,p_exception_message  => lc_exception_message);										
					ELSE
					    xx_write_to_log (lc_filehandle,'Concurent Jobs are neither Running nor Pending');              
                        lc_status        := 'SUCCESS'; 
                        lc_result        := 'Concurent Jobs are neither Running nor Pending';
                        ld_end_date_time := to_char(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                        lc_exception_message := NULL;

                        xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                        ,p_identifier         => lc_identifier
                                        ,p_status             => lc_status
                                        ,p_object_type        => lc_object_type
                                        ,p_object_name        => lc_object_name
                                        ,p_action             => lc_action
                                        ,p_result             => lc_result
                                        ,p_start_date_time    => ld_start_date_time
                                        ,p_end_date_time      => ld_end_date_time
                                        ,p_exception_message  => lc_exception_message);
                    END IF;										
					   
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_03: '||SQLERRM);
              ROLLBACK;
              LC_STATUS              := 'ERROR'; 
              lc_result              := 'Unable to Get the Concurrent Progarms Information';   
              LD_END_DATE_TIME       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added 1.18 -- Update SMTP Server
           BEGIN
              ------------------------------------------------------------------
              -- FND_NI_04 - Update SMTP Server in FND_SVC_COMP_PARAM_VALS Table 
              ------------------------------------------------------------------
              lc_identifier          := 'FND_NI_04';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_SVC_COMP_PARAM_VALS';
              lc_action              := 'Update SMTP Server';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_04');

                UPDATE FND_SVC_COMP_PARAM_VALS FSCPV
                   SET FSCPV.PARAMETER_VALUE = gc_mail_host 
                 WHERE EXISTS ( SELECT 1 FROM FND_SVC_COMP_PARAMS_TL FSCPT
                                 WHERE FSCPT.PARAMETER_ID = FSCPV.PARAMETER_ID
                                   AND fscpt.display_name =  'Outbound Server Name');
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_NI_04 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update SMTP Server';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		 -- Added 1.18 -- Update E-mail Address
           BEGIN
              ----------------------------------------------------------------------
              -- FND_NI_05 - Update E-mail Address in FND_SVC_COMP_PARAM_VALS Table 
              ----------------------------------------------------------------------
              lc_identifier          := 'FND_NI_05';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_SVC_COMP_PARAM_VALS';
              lc_action              := 'Update E-mail Address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_05');

                UPDATE FND_SVC_COMP_PARAM_VALS FSCPV
                   SET FSCPV.PARAMETER_VALUE = gc_email_address 
                 WHERE EXISTS ( SELECT 1 FROM FND_SVC_COMP_PARAMS_TL FSCPT
                                 WHERE FSCPT.PARAMETER_ID = FSCPV.PARAMETER_ID
                                   AND fscpt.display_name =  'Test Address');
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_NI_05 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update E-mail';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		-- Added 1.18 -- Update the value for Display Name: 'OutboundUser'
           BEGIN
              --------------------------------------------------------------------------------------------------
              -- FND_NI_06 - Update the value for Display Name: 'OutboundUser' in FND_SVC_COMP_PARAM_VALS Table 
              --------------------------------------------------------------------------------------------------
              lc_identifier          := 'FND_NI_06';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_SVC_COMP_PARAM_VALS';
              lc_action              := 'Update the Parameter value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_06');

                UPDATE FND_SVC_COMP_PARAM_VALS FSCPV
                   SET FSCPV.PARAMETER_VALUE = null 
                 WHERE EXISTS ( SELECT 1 FROM FND_SVC_COMP_PARAMS_TL FSCPT
                                 WHERE FSCPT.PARAMETER_ID = FSCPV.PARAMETER_ID
                                   AND fscpt.display_name =  'OutboundUser');
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_NI_06 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the parameter value';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   BEGIN
              -----------------------------------------------------
              -- FND_NI_07 - Update for OD_MAIL_GROUPS Translation    
              -----------------------------------------------------
              lc_identifier          := 'FND_NI_07';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_MAIL_GROUPS';
              lc_action              := 'Update OD_MAIL_GROUPS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for FND_NI_07');

              UPDATE xx_fin_translatevalues  
                 SET target_value1 = gc_email_address
               WHERE 1 = 1 
                 AND source_value1 = 'XXOD_COMN_GSCC_VIOLATIONS'
                 AND translate_id IN ( SELECT translate_id 
                                         FROM xx_fin_translatedefinition
                                        WHERE translation_name = 'OD_MAIL_GROUPS'); 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_NI_07 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_NI_07: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during FND instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for General Ledger ...'||CHR(10));
           BEGIN
              ---------------------------------------------
              -- GL_NI_01 - Update for GL_INTERFACE_EMAIL   
              ---------------------------------------------
              lc_identifier          := 'GL_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'GL_INTERFACE_EMAIL';
              lc_action              := 'Update GL_INTERFACE_EMAIL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_01');

              UPDATE xx_fin_translatevalues
              SET    target_value1 = NULL,
                     target_value2 = NULL,
                     target_value3 = NULL,
                     target_value4 = NULL
              WHERE  translate_id  = (SELECT translate_id
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'GL_INTERFACE_EMAIL');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- GL_NI_02 - Update for OD_FTP_PROCESSES     
              ---------------------------------------------
              lc_identifier          := 'GL_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update GL_RATES_TO_JDE';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_02');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = 'VJDEDVDTA'
              WHERE  source_value1 = 'GL_RATES_TO_JDE'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- GL_NI_03 - Update for OD_FTP_PROCESSES     
              ---------------------------------------------
              lc_identifier          := 'GL_NI_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_EPM_RATES';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_03');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'uschepmftpd01',
                     target_value2 = 'SVC-GLOBAL_FXRATES_D'
              WHERE  source_value1 = 'OD_EPM_RATES'
              AND    translate_id  = ( SELECT translate_id 
                                       FROM   xx_fin_translatedefinition 
                                       WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- GL_NI_04 - Update for OD_FTP_PROCESSES     
              ---------------------------------------------
              lc_identifier          := 'GL_NI_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_EPM_GL_BAL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_04');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'uschepmftpd01',
                     target_value2 = 'SVC-NAGL_HFM_D'
              WHERE  source_value1 = 'OD_EPM_GL_BAL'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- GL_NI_05 - Update for OD_FTP_PROCESSES     
              ---------------------------------------------
              lc_identifier          := 'GL_NI_05';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_FMR_GL_BAL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_05');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'uschepmftpd01',
                     target_value2 = 'SVC-ESSBASE_D'
              WHERE  source_value1 = 'OD_FMR_GL_BAL'
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_05 is: ' || sql%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_05: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
            -- V 1.11 --> Added Email , Havish Kasina
        BEGIN
              ------------------------------------------------------
              -- GL_NI_06 - Update for FND_DESCR_FLEX_COLUMN_USAGES 
              ------------------------------------------------------
              lc_identifier          := 'GL_NI_06';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_DESCR_FLEX_COLUMN_USAGES';
              lc_action              := 'Update Default Value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for GL_NI_06 Email Address');

              update fnd_descr_flex_column_usages 
                 SET default_value = gc_email_address
               where descriptive_flexfield_name = '$SRS$.' ||'XXCOGSGLIMPSUMM'
                 and end_user_column_name ='P_EMAIL_ID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for GL_NI_06 Email Address is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';   
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');           

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

        EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_NI_06: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
         END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during General Ledger non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Human Resource ...'||CHR(10));
           BEGIN
              ---------------------------------------------
              -- HR_NI_01 - Update for OD_FTP_PROCESSES     
              ---------------------------------------------
              lc_identifier          := 'HR_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_HR_USER_ACCTCOUR';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for HR_NI_01');

              UPDATE xx_fin_translatevalues 
              SET    target_value5 = '/infosec/courion/global/test'
              WHERE  source_value1 = 'OD_HR_USER_ACCTCOUR'
              AND    translate_id  = (SELECT translate_id
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for HR_NI_01 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during HR_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during HR_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- Added 1.11 -- Update E-mail Address 
           BEGIN
              -------------------------------------------------------------
              -- HR_NI_02 - Update E-mail address in PER_ALL_PEOPLE_F Table 
              -------------------------------------------------------------
              lc_identifier          := 'HR_NI_02';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'PER_ALL_PEOPLE_F';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for HR_NI_02');

                UPDATE /*+parallel(b) full(b)*/ per_all_people_f b
                   SET    b.email_address  = gc_email_address
                 WHERE b.email_address IS NOT NULL;
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for HR_NI_02 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during HR_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the Email Address';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during HR_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina as per Version 1.46
		   BEGIN
              ----------------------------------------------
              -- HR_NI_03 - Update for OD_HR_ERROR_REPORT    
              ----------------------------------------------
              lc_identifier          := 'HR_NI_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_HR_ERROR_REPORT';
              lc_action              := 'Update OD_HR_ERROR_REPORT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for HR_NI_03');

              UPDATE xx_fin_translatevalues  
                 SET target_value1 = gc_email_address
               WHERE SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1)
                 AND enabled_flag   = 'Y'
                 AND translate_id IN(SELECT translate_id 
                                       FROM xx_fin_translatedefinition 
                                      WHERE translation_name = 'OD_HR_ERROR_REPORT'
                                        AND enabled_flag     = 'Y'
                                        AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1))
                 AND source_value1 = 'OUTBOUND_EMAILS'; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for HR_NI_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during HR_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during HR_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Human Resource non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for iPayments ...'||CHR(10));
           BEGIN
              ---------------------------------------------
              -- iPAY_NI_01 - Update for FTP_DETAILS_AJB    
              ---------------------------------------------
              lc_identifier          := 'iPAY_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_NI_01');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_email_address -- Changes done as per version 1.11 --'Lori.Cirella@OfficeDepot.com,Bapuji.nanapaneni@officedepot.com'
              WHERE  source_value1 = 'Email' 
              AND    translate_id  = (SELECT translate_id 
                                       FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_NI_01 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		-- Changes done as per Version 1.47 (Defect 40180) by Havish Kasina
		   BEGIN
              ---------------------------------------------
              -- iPAY_NI_02 - Update for FTP_DETAILS_AJB    
              ---------------------------------------------
              lc_identifier          := 'iPAY_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_NI_02');

              UPDATE xx_fin_translatevalues 
                 SET target_value1 = gc_email_address 
               WHERE source_value1 = 'Avg_Email'
                 AND translate_id  = (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name = 'FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;
			  
			  UPDATE xx_fin_translatevalues 
                 SET target_value1 = gc_email_address,
                     target_value2 = gc_email_address,
                     target_value3 = gc_email_address	   
               WHERE source_value1 = 'ORDT_Alert'
                 AND translate_id  = (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name = 'FTP_DETAILS_AJB');
									   
			  ln_count := ln_count + SQL%rowcount;
			  
			  UPDATE xx_fin_translatevalues 
                 SET target_value1 = gc_email_address,
                     target_value2 = gc_email_address,
                     target_value3 = gc_email_address 
               WHERE source_value1 = 'Dup_Issue'
                 AND translate_id  = (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name = 'FTP_DETAILS_AJB');
									   
			   ln_count := ln_count + SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_NI_02 is: ' || ln_count||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_NI_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during iPayments non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for iReceivables ...'||CHR(10));
           BEGIN
              ---------------------------------------------
              -- iREC_NI_01 - Update for ACH_ECHECK_DETAILS 
              ---------------------------------------------
              lc_identifier          := 'iREC_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'ACH_ECHECK_DETAILS';
              lc_action              := 'Update SOA_PASSWORD';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_01');

              UPDATE xx_fin_translatevalues xftv 
              SET    target_value1 = (SELECT xx_encrypt_decryption_toolkit.encrypt ('development123') 
                                      FROM DUAL) 
              WHERE  EXISTS (SELECT 'x' 
                             FROM   xx_fin_translatedefinition xftd 
                             WHERE  xftv.translate_id     = xftd.translate_id 
                             AND    xftd.translation_name = 'ACH_ECHECK_DETAILS' 
                             AND    SYSDATE BETWEEN xftd.start_date_active 
                             AND    NVL (xftd.end_date_active, SYSDATE + 1) 
                             AND    xftd.enabled_flag     = 'Y') 
              AND    UPPER (xftv.source_value1) = UPPER ('soa_password') 
              AND    SYSDATE BETWEEN xftv.start_date_active 
              AND    NVL (xftv.end_date_active, SYSDATE + 1) 
              AND    xftv.enabled_flag = 'Y';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------
              -- iREC_NI_02 - Update for ACH_ECHECK_DETAILS 
              ---------------------------------------------
              lc_identifier          := 'iREC_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'ACH_ECHECK_DETAILS';
              lc_action              := 'Update SOA_USERNAME';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_02');

              UPDATE xx_fin_translatevalues xftv
              SET    target_value1 = 'development'
              WHERE  EXISTS (SELECT 'x'
                             FROM   xx_fin_translatedefinition xftd
                             WHERE  xftv.translate_id     = xftd.translate_id
                             AND    xftd.translation_name = 'ACH_ECHECK_DETAILS'
                             AND    SYSDATE BETWEEN xftd.start_date_active
                             AND    NVL (xftd.end_date_active, SYSDATE + 1)
                             AND    xftd.enabled_flag     = 'Y')
              AND UPPER (xftv.source_value1) = UPPER ('soa_username')
              AND SYSDATE BETWEEN xftv.start_date_active
              AND NVL (xftv.end_date_active, SYSDATE + 1)
              AND xftv.enabled_flag = 'Y';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_NI_02 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
        -- Added 1.11 -- Update E-mail Address 
           BEGIN
              ---------------------------------------------------------------------
              -- iREC_NI_03 - Update E-mail address in XX_EXTERNAL_USERS_STG Table 
              ---------------------------------------------------------------------
              lc_identifier          := 'iREC_NI_03';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_EXTERNAL_USERS_STG';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_03');

                update /*+parallel(b) full(b)*/ XX_EXTERNAL_USERS_STG b
                   set email = gc_email_address
                 WHERE email is not null;
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_NI_03 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Custom Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
       -- Added 1.11 -- Update E-mail Address 
           BEGIN
              ---------------------------------------------------------------------
              -- iREC_NI_04 - Update E-mail address in XX_EXTERNAL_USERS_STG Table 
              ---------------------------------------------------------------------
              lc_identifier          := 'iREC_NI_04';
              lc_object_type         := 'Custom Table';
              lc_object_name         := 'XX_EXTERNAL_USERS';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_04');

                update /*+parallel(b) full(b)*/ XX_EXTERNAL_USERS b
                  set email = gc_email_address
                WHERE email is not null;
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_NI_04 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Custom Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END; 
		   
		  -- Added as per Version 1.19  by Havish Kasina
            BEGIN
              ---------------------------------------------------------
              -- iREC_NI_05 - Update for OD: AR iRec Email SMTP Server        
              ---------------------------------------------------------
              lc_identifier          := 'iREC_NI_05';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: AR iRec Email SMTP Server';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_05');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_AR_IREC_EMAIL_SMTPSERVER'
                                                       ,x_value      => gc_mail_host 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iREC_NI_05' );
                 lc_result        := gc_mail_host; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iREC_NI_05' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		 -- Added as per Version 1.19  by Havish Kasina
            BEGIN
              ---------------------------------------------------------
              -- iREC_NI_06 - Update for OD: AR iRec Email From        
              ---------------------------------------------------------
              lc_identifier          := 'iREC_NI_06';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: AR iRec Email From';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_06');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_AR_IREC_EMAIL_FROM'
                                                       ,x_value      => gc_email_address 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iREC_NI_06' );
                 lc_result        := gc_email_address; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iREC_NI_06' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added as per Version 1.30 by Havish Kasina
		   BEGIN
              ----------------------------------------------------------------
              -- iREC_NI_07 - Update for XX_FIN_IREC_TOKEN_PARAMS Translation 
              ----------------------------------------------------------------
              lc_identifier          := 'iREC_NI_07';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_FIN_IREC_TOKEN_PARAMS';
              lc_action              := 'Update Host and email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_07');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_mail_host,   
                     target_value4 = gc_email_address    
              WHERE  source_value1 = 'SEND_EMAIL'
              AND    translate_id IN (SELECT translate_id 
                                        FROM xx_fin_translatedefinition
                                       WHERE translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_NI_07 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_07: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added as per Version 1.52  by Havish Kasina
            BEGIN
              ---------------------------------------------------------
              -- iREC_NI_08 - Update for OD: AR iRec Email From        
              ---------------------------------------------------------
              lc_identifier          := 'iREC_NI_08';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD iReceivables Vantiv PayFrame URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_NI_08');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_OD_IREC_PAYPAGE_URL'
                                                       ,x_value      => 'https://request.eprotect.vantivprelive.com/eProtect/js/payframe-client3.min.js' 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iREC_NI_08' );
                 lc_result        := gc_email_address; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iREC_NI_08' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_NI_08: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_NI_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during iReceivables non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Order Management ...'||CHR(10));
           BEGIN
              ------------------------------------------------------------------------------------
              -- OM_NI_01 - Update for OD: Use Test Credit Cards generated from first 6 and last 4 
              ------------------------------------------------------------------------------------
              lc_identifier          := 'OM_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: Use Test Credit Cards generated from first 6 and last 4';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for OM_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_OM_USE_TEST_CC'
                                                       ,x_value      => 'Y' --'Yes' -- Changed the value from 'Yes' to 'Y' 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for OM_NI_01'||CHR(10));
                 lc_result        := 'Yes';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                  xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for OM_NI_01'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ------------------------------------------------------------
              -- OM_NI_02 - Update for Profile Option XX_OM_HVOP_EMAIL_RECIPIENTS
              ------------------------------------------------------------
              lc_identifier          := 'OM_NI_02';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'XX_OM_HVOP_EMAIL_RECIPIENTS';
              lc_action              := 'Update email address';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for OM_NI_02');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_OM_HVOP_EMAIL_RECIPIENTS'
                                                       ,x_value      => gc_email_address -- Changes done as per version 1.11 --'IT_ERP_SYSTEMS@officedepot.com'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for OM_NI_02' );
                 lc_result        := gc_email_address; -- Changes done as per version 1.11 --'IT_ERP_SYSTEMS@officedepot.com';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for OM_NI_02' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           BEGIN
              ----------------------------------------------
              -- OM_NI_03 - Update for XX_OM_INV_NOTIFICATION   
              ----------------------------------------------
              lc_identifier          := 'OM_NI_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_OM_INV_NOTIFICATION';
              lc_action              := 'Update XX_OM_INV_NOTIFICATION';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for OM_NI_03');

              UPDATE xx_fin_translatevalues
                 SET target_value1= gc_email_address,
                     target_value2 = gc_email_address
               WHERE translate_id in (select translate_id from xx_fin_translatedefinition 
                                       WHERE translation_name = 'XX_OM_INV_NOTIFICATION'
                                         AND enabled_flag = 'Y');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for OM_NI_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_NI_03:'||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		BEGIN
        ---------------------------------------------------------------------------------------------------------------
        -- OM_NI_04 - Update WSH_REPORT_PRINTERS table disable pick-slip generation for printers in non-prod environment
        ---------------------------------------------------------------------------------------------------------------
        lc_identifier        := 'OM_NI_04';
        lc_object_type       := 'Disable flags ';
        lc_object_name       := 'WSH_REPORT_PRINTERS';
        lc_action            := 'Disable default_printer_flag and enable_flag feilds in wsh_report_printers ';
        ld_start_date_time   := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
        ld_end_date_time     := NULL;
        lc_exception_message := NULL;
        lc_result            := NULL;
        lc_status            := NULL;
        ln_count             := 0;
        
        xx_write_to_log (lc_filehandle,'Start of update, for OM_NI_04');
        
        UPDATE wsh_report_printers
        SET enabled_flag ='N',
        last_update_date = SYSDATE
        WHERE enabled_flag = 'Y';
       
		UPDATE wsh_report_printers
		SET default_printer_flag ='N', 
		last_update_date = SYSDATE
		WHERE default_printer_flag = 'Y';
       
		COMMIT;
       
        lc_status        := 'Success';
        lc_result        := 'Updated: '||ln_count||' rows';
        ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
        xx_write_to_file(p_filehandle_csv => lc_filehandle_csv ,
                         p_identifier => lc_identifier ,
                         p_status => lc_status ,
                         p_object_type => lc_object_type ,
                         p_object_name => lc_object_name ,
                         p_action => lc_action ,
                         p_result => lc_result ,
                         p_start_date_time => ld_start_date_time ,
                         p_end_date_time => ld_end_date_time ,
                         p_exception_message => lc_exception_message
                         );
      EXCEPTION
      WHEN OTHERS THEN
        xx_write_to_log (lc_filehandle,'Error encountered during OM_NI_04: '||SQLERRM);
        ROLLBACK;
        lc_status            := 'ERROR';
        lc_result            := 'Unable to update transalation';
        ld_end_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
        lc_exception_message := 'Error encountered during OM_NI_04: '||SQLERRM;
        xx_write_to_file(p_filehandle_csv => lc_filehandle_csv ,
                         p_identifier => lc_identifier ,
                         p_status => lc_status ,
                         p_object_type => lc_object_type ,
                         p_object_name => lc_object_name ,
                         p_action => lc_action ,
                         p_result => lc_result ,
                         p_start_date_time => ld_start_date_time ,
                         p_end_date_time => ld_end_date_time ,
                         p_exception_message => lc_exception_message
                         );
      END;
      -- Added by Shalu G as per Version 1.50 on 15-AUG-2017  End
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Order Management non instance specific steps '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Purchasing ...'||CHR(10));
		   -- Added by Suresh N as per Version 1.49 on 02-AUG-2017  Start (Defect#42904)
		   BEGIN
              ---------------------------------------------------
              -- PO_NI_01 - Update for XXPO_PUNCHOUT_CONFIG 
              ---------------------------------------------------
              lc_identifier          := 'PO_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXPO_PUNCHOUT_CONFIG';
              lc_action              := 'Update Target VAlues for XXPO_PUNCHOUT_CONFIG Translations';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for PO_NI_01');

              UPDATE xx_fin_translatevalues 
              SET target_value4 = gc_email_address ,
			      target_value5 = gc_email_address                      
              WHERE translate_id IN (SELECT translate_id 
                                     FROM   xx_fin_translatedefinition
                                     WHERE  translation_name = 'XXPO_PUNCHOUT_CONFIG')
			  AND  SOURCE_VALUE1 IN ('CONFIG_DETAILS','SHIPMENT_NOTIFY');
				
              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for PO_NI_01 is: '||SQL%ROWCOUNT);
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during PO_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during PO_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   BEGIN
              ---------------------------------------------------
              -- PO_NI_02 - Update for XX_PO_NOTIFY_WF_FAILURES 
              ---------------------------------------------------
              lc_identifier          := 'PO_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_PO_NOTIFY_WF_FAILURES';
              lc_action              := 'Update Target VAlues for XX_PO_NOTIFY_WF_FAILURES Translations';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for PO_NI_02');

              UPDATE xx_fin_translatevalues 
              SET    target_value2 = gc_email_address ,
			         target_value3 = gc_email_address
              WHERE  translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'XX_PO_NOTIFY_WF_FAILURES')
			  AND  SOURCE_VALUE1 = 'POAPPRV';
				
              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for PO_NI_02 is: '||SQL%ROWCOUNT);
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during PO_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during PO_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   BEGIN
              ---------------------------------------------------
              -- PO_NI_03 - Update for Trading Partner Record 
              ---------------------------------------------------
              lc_identifier          := 'PO_NI_03';
              lc_object_type         := 'ECE_TP_DETAILS';
              lc_object_name         := 'Trading Partner Record ecx_tp_details';
              lc_action              := 'Update Trading Partner Record in ecx_tp_details';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for PO_NI_03');

			  UPDATE ecx_tp_details
			  SET protocol_address = 'https://b2bwmvendors.officedepot.com/invoke/cXML/orderRequest'
			  WHERE connection_type = 'DIRECT'
			  AND protocol_type = 'HTTPS-ATCH'
		      AND username = 'NetworkId';
				
              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for PO_NI_03 is: '||SQL%ROWCOUNT);
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during PO_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during PO_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   -- Added by Suresh N as per Version 1.49 on 02-AUG-2017  End
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Purchasing non instance specific steps '||SQLERRM||CHR(10));
        END;
		
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Projects ...'||CHR(10));
           BEGIN
              -----------------------------------------------------------
              -- PA_NI_01 - Update for OD: PA PB Send Email Notifications 
              -----------------------------------------------------------
              lc_identifier          := 'PA_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: PA PB Send Email Notifications';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for PA_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_PA_PB_SEND_EMAIL'
                                                        ,x_value      => 'No'
                                                        ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for PA_NI_01'||CHR(10));
                 lc_result        := 'No';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for PA_NI_01'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during PA_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during PA_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Projects non instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for QA ...'||CHR(10));
           BEGIN
              --------------------------------------------
              -- QA_NI_01 - Update for OD: PA PB Mail Host 
              --------------------------------------------
              lc_identifier          := 'QA_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: PA PB Mail Host';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for QA_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_PA_PB_MAIL_HOST'
                                                       ,x_value      => gc_mail_host -- Commented as per Version 1.10 'USCHMSX28.na.odcorp.net'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for QA_NI_01' );
                 lc_result        := gc_mail_host; -- Commented as per Version 1.10 'USCHMSX28.na.odcorp.net';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for QA_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during QA_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during QA_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------
              -- QA_NI_02 - Update for OD OB QA Send Mail  
              --------------------------------------------
              lc_identifier          := 'QA_NI_02';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD OB QA Send Mail';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for QA_NI_02');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_PB_QA_SEND_MAIL'
                                                        ,x_value      => 'N'
                                                        ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for QA_NI_02'||CHR(10));
                 lc_result        := 'N';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for QA_NI_02'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during QA_NI_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during QA_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;          

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during QA Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Social Compliance ...'||CHR(10));
           BEGIN
              --------------------------------------------
              -- SC_NI_01 - Update for OD: PB SC Send Mail  
              --------------------------------------------
              lc_identifier          := 'SC_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: PB SC Send Mail';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SC_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_PB_SC_SEND_MAIL'
                                                        ,x_value      => 'N'
                                                        ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SC_NI_01'||CHR(10));
                 lc_result        := 'N';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SC_NI_01'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SC_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SC_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during SC Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Service ...'||CHR(10));
           BEGIN
              -----------------------------------------------
              -- SERVICE_NI_01 - Update for OD_FTP_PROCESSES  
              -----------------------------------------------
              lc_identifier          := 'SERVICE_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update XX_MPS_ORD_DW_OUT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_01');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value1 = 'USCHVSDST01D'
              WHERE  v.source_value1 = 'XX_MPS_ORD_DW_OUT'
              AND    v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'OD_FTP_PROCESSES'); 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for target value 1, for SERVICE_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

              lc_action              := 'Update XX_MPS_ORD_DW_OUT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              UPDATE xx_fin_translatevalues v
              SET    v.target_value2 = 'dstebsq',
                     v.target_value3 = 'ebsDSTQ12'
              WHERE  v.source_value1 = 'XX_MPS_ORD_DW_OUT'
              AND    v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for target values 2 and 3, for SERVICE_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------
              -- SERVICE_NI_02 - Update for XX_CS_POP3_CODE   
              -----------------------------------------------
              lc_identifier          := 'SERVICE_NI_02';
              lc_object_type         := 'Lookup';
              lc_object_name         := 'XX_CS_POP3_CODE';
              lc_action              := 'Update PASSWD';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_02');

              UPDATE fnd_lookup_values
              SET    meaning     = 'Center2013'
              WHERE  lookup_type = 'XX_CS_POP3_CODE'
              AND    lookup_Code = 'PASSWD';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------
              -- SERVICE_NI_03 - Update for XX_CS_POP3_CODE   
              -----------------------------------------------
              lc_identifier          := 'SERVICE_NI_03';
              lc_object_type         := 'Lookup';
              lc_object_name         := 'XX_CS_POP3_CODE';
              lc_action              := 'Update USERID';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_03');

              UPDATE fnd_lookup_values
              SET    meaning     = gc_email_address -- Changes done as per version 1.11 --'SVC-CallCenter-test@na.odcorp.net'
              WHERE  lookup_type = 'XX_CS_POP3_CODE'
              AND    lookup_Code = 'USERID';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------
              -- SERVICE_NI_04 - Update for XX_CS_POP3_CODE   
              -----------------------------------------------
              lc_identifier          := 'SERVICE_NI_04';
              lc_object_type         := 'Lookup';
              lc_object_name         := 'XX_CS_POP3_CODE';
              lc_action              := 'Update SERVER';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_04');

              UPDATE fnd_lookup_values
              SET    meaning     = 'USCHMSX03.na.odcorp.net'
              WHERE  lookup_type = 'XX_CS_POP3_CODE'
              AND    lookup_Code = 'SERVER';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ------------------------------------------
              -- SERVICE_NI_05 - Update for CS_LOOKUPS   
              ------------------------------------------
              lc_identifier          := 'SERVICE_NI_05';
              lc_object_type         := 'Lookup';
              lc_object_name         := 'CS_LOOKUPS';
              lc_action              := 'Update AMAZON';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_05');

              UPDATE cs_lookups csl
              SET    meaning          = gc_email_address -- Changes done as per version 1.11 --'marketplace.support@officedepot.com'
              WHERE  csl.lookup_type  = 'XX_CS_WH_EMAIL'
              AND    csl.enabled_flag = 'Y'
              AND    lookup_code      = 'AMAZON';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for SERVICE_NI_05 '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_06 - Update for CS_INCIDENTS_ALL_B   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_06';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'CS_INCIDENTS_ALL_B';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_06');

              update /*+parallel(b) full(b)*/ cs_incidents_all_b
              SET    incident_attribute_8  = gc_email_address -- Changes done as per version 1.11 --incident_attribute_8||'DUMMY'
              WHERE  1=1
              AND    incident_attribute_8 IS NOT NULL 
              AND    sr_creation_channel  = 'Email';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_06 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_07 - Update for FND_LOOKUP_VALUES    
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_07';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_LOOKUP_VALUES';
              lc_action              := 'Update XX_CS_TDS_VENDOR_LINK';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_07');

              UPDATE FND_LOOKUP_VALUES
              SET    description = 'https://officedepot-sdms.test.support.com/rang/download?tid='
              WHERE  lookup_type = 'XX_CS_TDS_VENDOR_LINK'
              AND    meaning     = 'Support.com';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_07 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_07: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------
              -- SERVICE_NI_08 - Update for OD : CS AOPS ORDER B2B LINK  
              ----------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_08';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS AOPS ORDER B2B LINK';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_08');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_AOPS_ORDER_B2B_LINK'
                                                       ,x_value      => 'http://b2bwmvendors.officedepot.com:5555/rest/ODServices/purchaseOrder?async=false'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_08' );
                 lc_result        := 'http://b2bwmvendors.officedepot.com:5555/rest/ODServices/purchaseOrder?async=false';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_08' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_08: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------------------------
              -- SERVICE_NI_09 - Update for OD CS TDS Service Confirmation  
              -------------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_09';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD CS TDS Service Confirmation';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_09');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_EMAIL_WORK_ORDER'
                                                       ,x_value      => 'https://wwwbeta.officedepot.com/orderhistory/orderHistoryAnonDisplay.do?id='
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_09' );
                 lc_result        := 'https://wwwbeta.officedepot.com/orderhistory/orderHistoryAnonDisplay.do?id=';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_09' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_09: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_09: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------------------
              -- SERVICE_NI_10 - Update for OD : CS MPS Aprimo Link    
              ---------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_10';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS MPS Aprimo Link';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_10');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_APRIMO_URL'
                                                       ,x_value      => NULL
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_10' );
                 lc_result        := 'NULL';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_10' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_10: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_10: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------------------------
              -- SERVICE_NI_11 - Update for OD: MPS Group1 WebService URL    
              ---------------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_11';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: MPS Group1 WebService URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_11');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_G1_WS_URL'
                                                       ,x_value      => 'http://soauat01.na.odcorp.net/soa-infra/services/cdh_rt/G1AddressValidationProcess/G1AddressValidationService_Client_ep'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_11' );
                 lc_result        := 'http://soauat01.na.odcorp.net/soa-infra/services/cdh_rt/G1AddressValidationProcess/G1AddressValidationService_Client_ep';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_11' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_11: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_11: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------------------
              -- SERVICE_NI_12 - Update for OD : CS MPS GROUP Email    
              ---------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_12';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS MPS GROUP Email';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_12');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_SHIPTO_ADDR'
                                                       ,x_value      => gc_email_address -- Changes done as per version 1.11 --'EBS_REL_Services_Case_Notifications@officedepot.com'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_12' );
                 lc_result        := gc_email_address; -- Changes done as per version 1.11 --'EBS_REL_Services_Case_Notifications@officedepot.com';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_12' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_12: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_12: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------------------
              -- SERVICE_NI_13 - Update for OD : CS SMTP Server        
              ---------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_13';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS SMTP Server';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_13');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_SMTP_SERVER'
                                                       ,x_value      => gc_mail_host -- Commented as per Version 1.10  'USCHMSX28.na.odcorp.net'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_13' );
                 lc_result        := gc_mail_host; -- Commented as per Version 1.10 'USCHMSX28.na.odcorp.net';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_13' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_13: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_13: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------------
              -- SERVICE_NI_14 - Update for OD : CS TDS Parts Quote Link 
              -----------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_14';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS TDS Parts Quote Link';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_14');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_TDS_PARTS_QUOTE_LINK'
                                                       ,x_value      => 'http://b2btest.nexicore.com/Nexicore/Parts/home.dsp?'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_14' );
                 lc_result        := 'http://b2btest.nexicore.com/Nexicore/Parts/home.dsp?';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_14' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_14: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_14: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------------------
              -- SERVICE_NI_15 - Update for OD : CS TDS Parts Print Order Link 
              -----------------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_15';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS TDS Parts Print Order Link';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_NI_15');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_TDS_PRINT_LINK'
                                                       ,x_value      => 'https://gmildev01.na.odcorp.net/web/searchPartOrder.do?'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_NI_15'||CHR(10));
                 lc_result        := 'https://gmildev01.na.odcorp.net/web/searchPartOrder.do?';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_NI_15'||CHR(10));
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_15: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_15: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_16 - Update for CS_INCIDENTS_ALL_B   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_16';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'CS_INCIDENTS_ALL_B';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_16');

              UPDATE /*+parallel(b) full(b)*/ cs_incidents_all_b
              SET    incident_attribute_14  = gc_email_address -- Changes done as per version 1.11 --'DUMMY@officedepot.com'
              WHERE  1=1
              AND    incident_attribute_14 IS NOT NULL 
              AND    incident_attribute_14 like '%@%';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_16 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_16: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_16: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           -- V 1.11 --> Update E-mail 
           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_17 - Update for CS_INCIDENTS_ALL_B   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_17';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'CS_INCIDENTS_ALL_B';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_17');

              UPDATE /*+parallel(b) full(b)*/ cs_incidents_all_b b
              SET    incident_attribute_3  = gc_email_address
              WHERE  1=1
              AND    incident_attribute_3 IS NOT NULL 
              AND    incident_attribute_3 like '%@%';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_17 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_17: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_17: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- V 1.11 --> Update E-mail 
           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_18 - Update for CS_INCIDENT_TYPES_B   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_18';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'CS_INCIDENT_TYPES_B';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_18');

              UPDATE /*+parallel(b) full(b)*/ cs_incident_types_b b
              SET    attribute10  = gc_email_address
              WHERE  1=1
              AND    attribute10 IS NOT NULL 
              AND    attribute10 like '%@%';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_18 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_18: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_18: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
            
         -- V 1.11 --> Update E-mail 
           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_19 - Update for JTF_RS_GROUPS_B   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_19';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'JTF_RS_GROUPS_B';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_19');

              update jtf_rs_groups_b
                 set email_address = gc_email_address
              where email_address is not null
                and email_address like '%@%';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_19 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_19: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_19: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- V 1.11 --> Update E-mail 
           BEGIN
              --------------------------------------------------
              -- SERVICE_NI_20 - Update for JTF_RS_RESOURCE_EXTNS   
              --------------------------------------------------
              lc_identifier          := 'SERVICE_NI_20';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'JTF_RS_RESOURCE_EXTNS';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_20');

              update JTF_RS_RESOURCE_EXTNS
                 set source_email = gc_email_address
               where source_email is not null
                 and source_email like '%@%';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_20 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_20: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update standard table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_20: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
-- Added as Per Version 1.15		   
		   BEGIN
              ------------------------------------------------------------------
              -- SERVICE_NI_21 - Update for XX_TDS_EBS_NOTIFY_EMAIL Translation   
              ------------------------------------------------------------------
              lc_identifier          := 'SERVICE_NI_21';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_TDS_EBS_NOTIFY_EMAIL';
              lc_action              := 'Update Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for, SERVICE_NI_21');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_email_address ,
			         target_value2 = gc_email_address
              WHERE  translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'XX_TDS_EBS_NOTIFY_EMAIL')
		        AND  source_value1 = 'XX_TDS_EMAIL';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_NI_21 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_NI_21: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update Translation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_NI_21: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Service Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;
      -- Added as per Version 1.10 
       BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for XDO ...'||CHR(10)); 
            BEGIN
              ---------------------------------------------------------
              -- XDO_NI_01 - Update for OD: XML Publisher SMTP Host        
              ---------------------------------------------------------
              lc_identifier          := 'XDO_NI_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: XML Publisher SMTP Host';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for XDO_NI_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_XDO_SMTP_HOST'
                                                       ,x_value      => gc_mail_host 
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for XDO_NI_01' );
                 lc_result        := gc_mail_host; 
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for XDO_NI_01' );
              END IF;

              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during XDO_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during XDO_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
         EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during XDO Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;
        
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Tax ...'||CHR(10));
           BEGIN
              ---------------------------------------------------
              -- TAX_NI_01 - Update for XX_SALES_TAX_EXTRACT_MAIL 
              ---------------------------------------------------
              lc_identifier          := 'TAX_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_SALES_TAX_EXTRACT_MAIL';
              lc_action              := 'Update XX_SALES_TAX_EXTRACT_MAIL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for TAX_NI_01');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = gc_email_address -- Changes done as per version 1.11 --'sinon.perlas@officedepot.com'
              WHERE  translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'XX_SALES_TAX_EXTRACT_MAIL');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for TAX_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during TAX_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during TAX_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ------------------------------------------
              -- TAX_NI_02 - Update for OD_FTP_PROCESSES 
              ------------------------------------------
              lc_identifier          := 'TAX_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_FTP_PROCESSES';
              lc_action              := 'Update OD_AR_VERTEX_IFACE';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for TAX_NI_02');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'FUTURE', 
                     target_value2 = 'ODPFTP', --'PRODFTP' -- Commented as per version 1.44  
                     target_value3 = 'FTP16@od77', -- 'FTPPROD' -- Commented as per version 1.44 
                     target_value5 = 'SDPLIB' 
              WHERE  source_value1 = ('OD_AR_VERTEX_IFACE') 
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'OD_FTP_PROCESSES');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for TAX_NI_02 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during TAX_NI_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during TAX_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Tax Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;
      -- Added for Version 1.11  
         BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Web Collect Non-instance specific steps...'||CHR(10));
           BEGIN
              -----------------------------------------------------
              -- WEBC_NI_01 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update Notification Email';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_NI_01');

              UPDATE xx_fin_translatevalues 
                 SET target_value5 = gc_email_address   
               WHERE  1 = 1
                 AND  translate_id IN (SELECT translate_id 
                                         FROM xx_fin_translatedefinition
                                       WHERE translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
                 AND  target_value5 IS NOT NULL;

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_NI_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
           
           -- Added for Version 1.11
           BEGIN
              -----------------------------------------------------
              -- WEBC_NI_02 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_NI_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update Mail Host';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_NI_02');

              UPDATE  xx_fin_translatevalues 
                 SET  target_value1= gc_mail_host
               WHERE  source_value1 = 'XX_CRM_OUTBOUND_NOTIFY'
                 AND  translate_id IN (SELECT  translate_id 
                                         FROM  xx_fin_translatedefinition
                                        WHERE  translation_name = 'XXOD_WEBCOLLECT_INTERFACE');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_NI_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_NI_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_NI_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
          
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Web Collect Non-instance specific steps '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Webcollect CDH Scramble ...'||CHR(10));
           BEGIN
              --------------------------------------------------------------------
              -- WCS_NI_01 - Update for Webcollect CDH Scramble translation tables 
              --------------------------------------------------------------------
              lc_identifier          := 'WCS_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXCRM_SCRAMBL_FILE_FORMAT';
              lc_action              := 'Delete / Insert XXCRM_SCRAMBL_FILE_FORMAT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for WCS_NI_01');

              ---------------------------------------------------------
              -- Deleting XX_FIN_TRANSLATEVALUES                           --
              ---------------------------------------------------------

              DELETE FROM XX_FIN_TRANSLATEVALUES WHERE TRANSLATE_ID IN
              (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME IN              
              ('XX_CRM_SCRAM_FILE_REC_LIM','XX_CRM_SCRAMBLER_FORMAT','XXCRM_SCRAMBL_FILE_FORMAT'));
              COMMIT;

              ---------------------------------------------------------
              -- Deleting XX_FIN_TRANSLATEDEFINITIONS                           --
              ---------------------------------------------------------

              DELETE XX_FIN_TRANSLATEDEFINITION
              WHERE  translation_name in ('XX_CRM_SCRAMBLER_FORMAT', 'XX_CRM_SCRAM_FILE_REC_LIM', 'XXCRM_SCRAMBL_FILE_FORMAT');
              COMMIT;

               ---------------------------------------------------------
               -- Inserting XX_FIN_TRANSLATEDEFINITIONS                           --
               ---------------------------------------------------------

               INSERT INTO XX_FIN_TRANSLATEDEFINITION                                  
               (TRANSLATE_ID, TRANSLATION_NAME, TRANSLATE_DESCRIPTION, SOURCE_FIELD1, SOURCE_FIELD2, SOURCE_FIELD3, SOURCE_FIELD4,
               CREATION_DATE,CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG)
               VALUES(xx_fin_translatedefinition_s.nextval,'XXCRM_SCRAMBL_FILE_FORMAT','CRM Scrambler File Format',
               'TABLE_NAME','COLUMN_NAME','SEQUENCE',NULL,sysdate,0,sysdate,0,'01-JAN-14','Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEDEFINITION
               (TRANSLATE_ID, TRANSLATION_NAME, TRANSLATE_DESCRIPTION, SOURCE_FIELD1, SOURCE_FIELD2, SOURCE_FIELD3, SOURCE_FIELD4,
               CREATION_DATE,CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG)
               VALUES(xx_fin_translatedefinition_s.nextval,'XX_CRM_SCRAM_FILE_REC_LIM','CRM Scrambler File Record Limit',
               'TABLE_NAME','RECORD_CNT',NULL,NULL,sysdate,0,sysdate,0,'01-JAN-14','Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEDEFINITION
               (TRANSLATE_ID, TRANSLATION_NAME, TRANSLATE_DESCRIPTION, SOURCE_FIELD1, SOURCE_FIELD2, SOURCE_FIELD3, SOURCE_FIELD4,
               CREATION_DATE,CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG)
               VALUES(xx_fin_translatedefinition_s.nextval,'XX_CRM_SCRAMBLER_FORMAT','Export table with specific column scrambler',
               'TABLE_NAME','COLUMN_NAME','DATA_TYPE','DATA_LENGTH',sysdate,0,sysdate,0,'01-JAN-14','Y');
               COMMIT;

               ---------------------------------------------------------
               -- Inserting  XX_CRM_SCRAM_FILE_REC_LIM                               --
               ---------------------------------------------------------

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,last_update_login,
               start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','1000000',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAM_FILE_REC_LIM'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,last_update_login,
               start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','1000000',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAM_FILE_REC_LIM'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,last_update_login,
               start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','1000000',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAM_FILE_REC_LIM'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               ---------------------------------------------------------
               -- Inserting      XX_CRM_SCRAMBLER_FORMAT                           --
               ---------------------------------------------------------

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS1','VARCHAR2','240',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS2','VARCHAR2','240',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CITY','VARCHAR2','60',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','POSTAL_CODE','VARCHAR2','60',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','STATE','VARCHAR2','60',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','AREA_CODE','VARCHAR2','6',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','EMAIL_ADDRESS','VARCHAR2','60',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','FIRST_NAME','VARCHAR2','120',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','LAST_NAME','VARCHAR2','120',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','PHONE_NUMBER','VARCHAR2','15',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_NAME','VARCHAR2','360',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','DUNS_NUMBER','VARCHAR2','30',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               ---------------------------------------------------------
               -- Inserting          XXCRM_SCRAMBL_FILE_FORMAT                       --
               ---------------------------------------------------------

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUST_ACCOUNT_ID','1',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_NUMBER','2',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ORGANIZATION_NUMBER','3',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_NUMBER_AOPS','4',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_NAME','5',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','STATUS','6',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_TYPE','7',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUSTOMER_CLASS_CODE','8',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','SALES_CHANNEL_CODE','9',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','SIC_CODE','10',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CUST_CATEGORY_CODE','11',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','DUNS_NUMBER','12',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','SIC_CODE_TYPE','13',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','COLLECTOR_NUMBER','14',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','COLLECTOR_NAME','15',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CREDIT_CHECKING','16',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CREDIT_RATING','17',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ACCOUNT_ESTABLISHED_DATE','18',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ACCOUNT_CREDIT_LIMIT_USD','19',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ACCOUNT_CREDIT_LIMIT_CAD','20',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ORDER_CREDIT_LIMIT_USD','21',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','ORDER_CREDIT_LIMIT_CAD','22',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','CREDIT_CLASSIFICATION','23',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','EXPOSURE_ANALYSIS_SEGMENT','24',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','RISK_CODE','25',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','SOURCE_OF_CREATION_FOR_CREDIT','26',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','PO_VALUE','27',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','PO','28',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','RELEASE_VALUE','29',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','RELEASE','30',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','COST_CENTER_VALUE','31',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','COST_CENTER','32',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','DESKTOP_VALUE','33',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','DESKTOP','34',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;
			   
			   -- Added two Insert statements as per Version 1.27
			   INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','OMX_ACCOUNT_NUMBER','35',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTMAST_HEAD_STG','BILLDOCS_DELIVERY_METHOD','36',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;
               -- End of changes added as per Version 1.27
			   
               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','SITE_USE_ID','1',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ORG_ID','2',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CUST_ACCOUNT_ID','3',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS1','4',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS2','5',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS3','6',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESS4','7',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','POSTAL_CODE','8',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CITY','9',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','STATE','10',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','PROVINCE','11',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','COUNTRY','12',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','PARTY_SITE_NUMBER','13',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','PRIMARY_FLAG','14',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','SEQUENCE','15',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ORIG_SYSTEM_REFERENCE','16',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','LOCATION','17',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','COLLECTOR_NUMBER','18',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','COLLECTOR_NAME','19',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               --INSERT INTO XX_FIN_TRANSLATEVALUES
               --(SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               --last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               --VALUES ('XX_CRM_CUSTADDR_STG','DUNNING_LETTERS','20',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               --where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               --COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','SEND_STATEMENTS','21',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CREDIT_LIMIT_USD','22',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CREDIT_LIMIT_CAD','23',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','PROFILE_CLASS_NAME','24',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CONSOLIDATED_BILLING','25',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','CONS_BILLING_FORMATS_TYPE','26',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','BILL_IN_THE_BOX','27',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','BILLING_CURRENCY','28',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','DUNNING_DELIVERY','29',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','STATEMENT_DELIVERY','30',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','TAXWARE_ENTITY_CODE','31',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','REMIT_TO_SALES_CHANNEL','32',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','EDI_LOCATION','33',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ADDRESSEE','34',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','IDENTIFYING_ADDRESS','35',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','ACCT_SITE_STATUS','36',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','SITE_USE_STATUS','37',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTADDR_STG','SITE_USE_CODE','38',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONT_OSR','1',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CUST_ACCOUNT_ID','2',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','SITE_USE_ID','3',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONTACT_NUMBER','4',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','LAST_NAME','5',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','FIRST_NAME','6',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','JOB_TITLE','7',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','EMAIL_ADDRESS','8',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONT_POINT_PURPOSE','9',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONT_POINT_PRIMARY_FLAG','10',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONTACT_ROLE_PRIMARY_FLAG','11',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONTACT_POINT_TYPE','12',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','PHONE_LINE_TYPE','13',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','COUNTRY_CODE','14',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','AREA_CODE','15',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','PHONE_NUMBER','16',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','EXTENSION','17',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','SITE_OSR','18',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

               INSERT INTO XX_FIN_TRANSLATEVALUES
               (SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,TRANSLATE_ID,creation_date,created_by,last_update_date,last_updated_by,
               last_update_login,start_date_active,TRANSLATE_VALUE_ID,ENABLED_FLAG)
               VALUES ('XX_CRM_CUSTCONT_STG','CONT_POINT_OSR','19',(select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
               where TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT'), sysdate,-1,sysdate,-1,0,'01-JAN-05',XX_FIN_TRANSLATEVALUES_S.NEXTVAL,'Y');
               COMMIT;

              xx_write_to_log (lc_filehandle,'rows deleted / Inserted for WCS_NI_01 ');


              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WCS_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WCS_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
      
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Webcollect CDH Scramble Non Instance Specific steps: '||SQLERRM||CHR(10));
        END;
		
	--Added as per version 1.42 -- Defect 37831	
	  BEGIN
         xx_write_to_log (lc_filehandle,'Start of update for Common Module ...'||CHR(10));
          BEGIN
              ----------------------------------------------
              -- XXCOMN_NI_01 - Update for EBS_NOTIFICATIONS 
              ----------------------------------------------
              lc_identifier          := 'XXCOMN_NI_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'EBS_NOTIFICATIONS';
              lc_action              := 'Update email and Host name';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for XXCOMN_NI_01');

              UPDATE xx_fin_translatevalues 
              SET    target_value3 = gc_email_address,
			         target_value4 = NULL,
					 target_value5 = NULL,
			         target_value9 = gc_mail_host                         
              WHERE  translate_id IN (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'EBS_NOTIFICATIONS');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for XXCOMN_NI_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during XXCOMN_NI_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during XXCOMN_NI_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
     EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Common Module non instance specific steps: '||SQLERRM||CHR(10));
     END;

     ELSE
         xx_write_to_log (lc_filehandle,' Not supposed to be executed in Production Instances : '||lc_instance_name);
     END IF;

     UTL_FILE.FCLOSE(lc_filehandle);
     UTL_FILE.FCLOSE(lc_filehandle_csv);
  EXCEPTION 
     WHEN UTL_FILE.INVALID_PATH THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20051, 'Invalid Path');
     WHEN UTL_FILE.INVALID_MODE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20052, 'Invalid Mode');
     WHEN UTL_FILE.INTERNAL_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20053, 'Internal Error');
     WHEN UTL_FILE.INVALID_OPERATION THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20054, 'Invalid Operation');
     WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20055, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20056, 'Invalid Operation');
     WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE ('Error while writing the logs for non instance specific updates into the UTL file'); -- Commented by Havish Kasina as per Version 1.17
		-- Added by Havish Kasina as per Version 1.17
		ln_err_num := SQLCODE;
        lc_err_msg := SQLERRM;
        DBMS_OUTPUT.put_line ('WHEN OTHERS EXCEPTION (non-instance specific): '||ln_err_num ||': '|| lc_err_msg);
        xx_write_to_log (lc_filehandle,'WHEN OTHERS EXCEPTION (non-instance specific): '||ln_err_num ||': '|| lc_err_msg);
		-- End of Adding Changes by Havish Kasina as per Version 1.17
  END xx_update_non_inst_specific; 

  PROCEDURE  xx_update_inst_specific
  AS
  -- +===================================================================+
  -- | Name  : xx_update_inst_specific                                   |
  -- | Description     : The xx_update_inst_specific procedure           |
  -- |                   performs all not instance specific updates.     |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  lc_filehandle         UTL_FILE.file_type;
  lc_filehandle_csv     UTL_FILE.file_type;
  lc_dirpath            VARCHAR2 (2000) := 'XX_UTL_FILE_OUT_DIR';
  lc_curr_date          VARCHAR2 (100)  := TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS'); -- Added as per Version 1.31--TO_CHAR (SYSDATE, 'YYYYMMDD');
  lc_order_file_name    VARCHAR2(100)   := UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'_'||'appdev_inst_spec_post_clone'||'.log'; -- Changed as per Version 1.31 --'appdev_inst_spec_post_clone_'||UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'.log';
  lc_csv_file_name      VARCHAR2(100)   := UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'_'||'appdev_inst_spec_post_clone'||'.csv'; -- Changed as per Version 1.31 --'appdev_inst_spec_post_clone_'||UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME'))||'_'||lc_curr_date||'.csv';
  lc_mode               VARCHAR2 (1)    := 'W';
  lc_instance_name      VARCHAR2(30);
  lb_profile_chg_result BOOLEAN;
  ln_dir_cnt            NUMBER;
  lc_identifier         VARCHAR2(25);
  lc_object_type        VARCHAR2(50);
  lc_object_name        VARCHAR2(100);
  lc_action             VARCHAR2(100);
  ld_start_date_time    VARCHAR2(20);
  ld_end_date_time      VARCHAR2(20);
  lc_exception_message  VARCHAR2(1000);
  lc_result             VARCHAR2(1000);
  lc_status             VARCHAR2(10);
  ln_count              NUMBER;
  -- Added by Havish Kasina as per Version 1.17
  ln_err_num            NUMBER;
  lc_err_msg            VARCHAR(100);
  lc_profile_value      VARCHAR2(100);

  -- iREC_IS_01 Variables
  lc_profile_name fnd_profile_options.profile_option_name%type;
  lc_soa_host VARCHAR2(10);
  lc_soa_hosturl fnd_profile_option_Values.profile_option_value%type; 
  
  -- FND_IS_03 Variable
  lc_temp_dir_value  VARCHAR2(100);
  
  -- FND_IS_04 Variables
  ld_infobundle_upload_date DATE;
  ld_infobundle_creation_date DATE;
  
  BEGIN

     lc_filehandle                 := UTL_FILE.FOPEN (lc_dirpath, lc_order_file_name, lc_mode); 
     lc_filehandle_csv             := UTL_FILE.FOPEN (lc_dirpath, lc_csv_file_name, lc_mode);
	 
     dbms_output.put_line('File Location: '||xx_get_dir_path(lc_filehandle,lc_dirpath));
     dbms_output.put_line('Log file name for instance specific steps: '||lc_order_file_name);
     dbms_output.put_line('CSV file name for instance specific steps: '||lc_csv_file_name);
	 
	 LC_INSTANCE_NAME              := XX_GET_INST_NAME(LC_FILEHANDLE);
	 dbms_output.put_line('Instance Name: '||lc_instance_name); --Added by Havish Kasina as per Version 1.17
	 
     GC_8_CHAR_INSTANCE_NAME_LOWER := LOWER(LC_INSTANCE_NAME);
	 dbms_output.put_line('8 Char Name lower: '||gc_8_char_instance_name_lower); --Added by Havish Kasina as per Version 1.17
	 
     GC_5_CHAR_INSTANCE_NAME_LOWER := LOWER(SUBSTR(LC_INSTANCE_NAME,4,5));
	 dbms_output.put_line('5 Char Name lower: '||gc_5_char_instance_name_lower); --Added by Havish Kasina as per Version 1.17
	 
     gc_8_char_instance_name_upper := UPPER(lc_instance_name);
	 dbms_output.put_line('8 Char Name upper: '||gc_8_char_instance_name_upper);-- Added by Havish Kasina as per Version 1.17
	 
     GC_5_CHAR_INSTANCE_NAME_UPPER := UPPER(SUBSTR(LC_INSTANCE_NAME,4,5));
     dbms_output.put_line('5 Char Name upper: '||gc_5_char_instance_name_upper); --Added by Havish Kasina as per Version 1.17
     
	 dbms_output.put_line('Checking Environment.....'); --Added by Havish Kasina as per Version 1.17
	 
     IF lc_instance_name <>'GSIPRDGB' THEN
	    dbms_output.put_line('Start of update for instance specific steps'); --Added by Havish Kasina as per Version 1.17 
        xx_write_to_log (lc_filehandle,'Start of update for instance specific steps');
        xx_write_to_log (lc_filehandle,'-----------------------------------------------'||CHR(10));

       --------------------------------------------------
       -- Writing the title and header for the CSV file--
       --------------------------------------------------
       xx_write_to_log (lc_filehandle_csv, 'AppDev Instance-Specific Post-Cloning '||lc_instance_name||' '||TO_CHAR(SYSDATE,'YYYY-MM-DD')||CHR(10));
       xx_write_to_log (lc_filehandle_csv,'Identifier'||','||'Status'||','||'Object Type'||','||'Object Name'||','||'Action'||','
                                             ||'Result'||','||'Start Date/Time'||','||'End Date/Time'||','||'Duration'||','||'Exception Message'); -- Added Duration as per Version 1.31
        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Account Receivables ...'||CHR(10));
           BEGIN
              -----------------------------------------------
              -- AR_IS_01 - Update for AR_LOCKBOX_BPEL_SETUP  
              -----------------------------------------------
              lc_identifier          := 'AR_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'AR_LOCKBOX_BPEL_SETUP';
              lc_action              := 'Update URL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              IF lc_instance_name = 'GSISIT01' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for SIT01');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soasit01.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in SIT01 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for SIT02');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soasit02.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in SIT02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			 -- Added as per Version 1.22 by Havish Kasina	
			 
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for SIT03');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://eaiuat01.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in SIT03 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
              -- End of Adding changes as per Version 1.22 by Havish Kasina

              ELSIF lc_instance_name = 'GSIDEV01' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for DEV01');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soadev01.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in DEV01 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIDEV02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for DEV02');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soadev02.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in DEV02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for UATGB');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soauat01.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in UATGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for PRFGB');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 = 'http://soaprf01.na.odcorp.net:80/soa-infra/services/finance/SyncReleaseESPJob/client'
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in PRFGB is: ' || SQL%rowcount );
                COMMIT;

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for AR_IS_01, for all other instances ');

                 UPDATE xx_fin_translatevalues v
                 SET    v.target_value2 =  NULL
                 WHERE  v.target_value1 = 'BPEL_INVOKE'
                 AND    v.source_value1 = 'URL'
                 AND    v.translate_id  = (SELECT d.translate_id
                                           FROM   xx_fin_translatedefinition d
                                           WHERE  d.translation_name = 'AR_LOCKBOX_BPEL_SETUP');

                 xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_01, in all other instances is: ' || SQL%rowcount );
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during AR_IS_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              --------------------------------------------------
              -- AR_IS_02 - Update for XX_AR_CUST_EXT_TRADE_FILE 
              --------------------------------------------------
              lc_identifier          := 'AR_IS_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_AR_CUST_EXT_TRADE_FILE';
              lc_action              := 'Update DNB';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AR_IS_02');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value5 = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxfin/ftp/out/trade',
                     v.target_value6 = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxfin/archive/outbound'
              WHERE  v.translate_id in (SELECT translate_id 
                                        FROM   xx_fin_translatedefinition
                                        WHERE  translation_name LIKE 'XX_AR_CUST_EXT_TRADE_FILE')
              AND    v.source_value3 = 'DNB';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_02 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for AR_IS_02 '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   /* Added as per Version 1.55 by Havish Kasina */
		   BEGIN
              ----------------------------------------------
              -- AR_IS_03 - Update for XX_AR_SUBSCRIPTIONS 
              ----------------------------------------------
              lc_identifier          := 'AR_IS_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_AR_SUBSCRIPTIONS';
              lc_action              := 'Update Subscription Billing Type';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update for AR_IS_03');
			  
			  IF lc_instance_name IN ('GSIDEV02', 'GSIDEV03')
			  THEN

                  UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-dev-min.uschecomrnd.net/services/subscription-payment-service/eaiapi/subscriptions/creditAuthorization',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'AUTH_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'http://eaiapiuat.na.odcorp.net/eaiapi/bizclub/calculateTax?async=false',
                         v.target_value2 = 'SVC-BIZBOXWS',
				    	 v.target_value3 = 'svc4bizboxws'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'TAX_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://dev.odplabs.com/services/subscription-billing-history/eaiapi/subscriptions/billingHistory',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BILL_HISTORY_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-rnd-min.uschecomrnd.net/services/subscription-email-notifications/eaiapi/subscriptions/billingStatusEmail',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BILL_EMAIL_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-dev-min.uschecomrnd.net/services/dev-subscription-email-notifications/eaiapi/subscriptions/contractEmail',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BS_EMAIL_SERVICE';
				  
			  ELSE
			     
                  UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-rnd-min.uschecomrnd.net/services/subscription-payment-service/eaiapi/subscriptions/creditAuthorization',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'AUTH_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'http://eaiapiuat.na.odcorp.net/eaiapi/bizclub/calculateTax?async=false',
                         v.target_value2 = 'SVC-BIZBOXWS',
				    	 v.target_value3 = 'svc4bizboxws'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'TAX_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://staging.odplabs.com/services/subscription-billing-history/eaiapi/subscriptions/billingHistory/',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BILL_HISTORY_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-rnd-min.uschecomrnd.net/services/subscription-email-notifications/eaiapi/subscriptions/billingStatusEmail',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BILL_EMAIL_SERVICE';
			  
			      UPDATE xx_fin_translatevalues v
                  SET    v.target_value1 = 'https://ch-kube-dev-min.uschecomrnd.net/services/dev-subscription-email-notifications/eaiapi/subscriptions/contractEmail',
                         v.target_value2 = 'SVC-EBSWS',
				    	 v.target_value3 = 'svcebs4uat'
                  WHERE  v.translate_id in (SELECT translate_id 
                                            FROM   xx_fin_translatedefinition
                                            WHERE  translation_name LIKE 'XX_AR_SUBSCRIPTIONS')
                  AND    v.source_value1 = 'BS_EMAIL_SERVICE';
              END IF;				  

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for AR_IS_03 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for AR_IS_03 '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during AR_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Account Receivables instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Billing ...'||CHR(10));
           BEGIN
              -----------------------------------------------
              -- Bill_IS_01 - Update for XX_EBL_COMMON_TRANS  
              -----------------------------------------------
              lc_identifier          := 'Bill_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_EBL_COMMON_TRANS';
              lc_action              := 'Update FPATH';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for Bill_IS_01');

              UPDATE xx_fin_translatevalues 
                 SET target_value1 ='/app/ebs/it'||gc_8_char_instance_name_lower||'/'||gc_8_char_instance_name_lower||'cust/xxfin/media'
               WHERE source_value1 = 'FPATH'
                 AND translate_id IN (SELECT translate_id 
                                        FROM xx_fin_translatedefinition 
                                       WHERE translation_name ='XX_EBL_COMMON_TRANS');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for Bill_IS_01 is: ' || SQL%rowcount||CHR(10));
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during Bill_IS_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during Bill_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during Billing instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for ESP ...'||CHR(10));
           BEGIN
              -------------------------------------
              -- ESP_IS_01 - Update for ESP_E%_DEF  
              -------------------------------------
              lc_identifier          := 'ESP_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'ESP_E%_DEF';
              lc_action              := 'Update ESP_E%_DEF';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;


              IF lc_instance_name = 'GSISIT01' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for SIT01');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'1'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in SIT01 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E1%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'1'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E1%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in SIT01 is: ' || SQL%rowcount||CHR(10));
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for SIT02');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'2'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in SIT02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E2%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'2'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E2%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in SIT02 is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			
              -- Added as per Version 1.22 by Havish Kasina	
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for SIT03');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'3'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in SIT03 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E3%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'3'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E3%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in SIT03 is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
		      -- End of adding changes as per Version 1.22 by Havish Kasina

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for UATGB');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'F'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in UATGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_EF%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'F'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_EF%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in UATGB is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for PRFGB');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'9'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in PRFGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E9%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'9'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E9%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in PRFGB is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISYS01' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for ESP_IS_01, for SYS01');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'8'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01, in SYS01 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E8%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'8'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id in (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E8%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01, in SYS01 is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update ESP_IS_01, for all other instances ');

                 UPDATE xx_fin_translatedefinition
                 SET    translation_name = SUBSTR(translation_name,1,5)||'?'|| SUBSTR(translation_name,7,20)  
                 WHERE  translation_name LIKE 'ESP_E%_DEF';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update1 - No of rows updated for ESP_IS_01 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

                 ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 lc_action              := 'Update ESP_E?%_JOB_DEF';

                 ld_end_date_time       := NULL;
                 lc_result              := NULL;
                 lc_status              := NULL;
                 ln_count               := 0;

                 UPDATE xx_fin_translatevalues
                 SET    source_value1 = SUBSTR(source_value1,1,1)||'?'|| SUBSTR(source_value1,3,20)
                 WHERE  translate_id IN (SELECT translate_id
                                         FROM   xx_fin_translatedefinition
                                         WHERE  translation_name LIKE 'ESP_E?%_JOB_DEF');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'Update2 - No of rows updated for ESP_IS_01 is: ' || SQL%rowcount||CHR(10));
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during ESP_IS_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during ESP_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during ESP instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for FND ...'||CHR(10));
           BEGIN
              ------------------------------------------------------------------
              -- FND_IS_01 - Update for FND: Personalization Document Root Path  
              ------------------------------------------------------------------
              lc_identifier          := 'FND_IS_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'FND: Personalization Document Root Path';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for FND_IS_01');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'FND_PERZ_DOC_ROOT_PATH'
                                                       ,x_value      => '/app/ebs/it'||gc_8_char_instance_name_lower||'/'||gc_8_char_instance_name_lower||'cust/xxcomn/java/'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for FND_IS_01'||CHR(10));
                 lc_result        := '/app/ebs/it'||gc_8_char_instance_name_lower||'/'||gc_8_char_instance_name_lower||'cust/xxcomn/java/';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for FND_IS_01'||CHR(10));
              END IF;
              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added 1.18 -- Update the value for Display Name: 'From'
           BEGIN
              --------------------------------------------------------------------------------------------------
              -- FND_IS_02 - Update the value for Display Name: 'From' in FND_SVC_COMP_PARAM_VALS Table 
              --------------------------------------------------------------------------------------------------
              lc_identifier          := 'FND_IS_02';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'FND_SVC_COMP_PARAM_VALS';
              lc_action              := 'Update the Parameter value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_IS_02');

                UPDATE FND_SVC_COMP_PARAM_VALS FSCPV
                   SET FSCPV.PARAMETER_VALUE =  SUBSTR(UPPER(SYS_CONTEXT('USERENV','INSTANCE_NAME')),1,8)||' Office Depot Workflow Mailer' 
                 WHERE EXISTS ( SELECT 1 FROM FND_SVC_COMP_PARAMS_TL FSCPT
                                 WHERE FSCPT.PARAMETER_ID = FSCPV.PARAMETER_ID
                                   AND fscpt.display_name =  'From');
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_IS_02 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the parameter value';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina as per Version 1.39 ( as per Defect 37274)
           BEGIN
              --------------------------------------------------------------------------------------------------
              -- FND_IS_05 - To update the value for SYSTEM_TEMP_DR(Property Code) in XDO_CONFIG_VALUES Table
              --------------------------------------------------------------------------------------------------
              lc_identifier          := 'FND_IS_05';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'XDO_CONFIG_VALUES';
              lc_action              := 'Update the value for SYSTEM_TEMP_DR(Property Code)';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
              
              xx_write_to_log (lc_filehandle,'Start of update, for FND_IS_05');

                UPDATE xdo_config_values
			       SET value = '/app/ebs/ct'||gc_8_char_instance_name_lower||'_system/APPLTMP/temp'
                 WHERE property_code = 'SYSTEM_TEMP_DIR';
                   
                ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for FND_IS_05 is: ' || SQL%rowcount );

              COMMIT;
              
              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_05: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the value for SYSTEM_TEMP_DR(Property Code) in XDO_CONFIG_VALUES Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		  
          -- Added by Havish Kasina as per Version 1.33		  
		   BEGIN
              -------------------------------------------------------------------
              -- FND_IS_03 - Check for SYSTEM_TEMP_DR in XDO_CONFIG_VALUES Table 
              -------------------------------------------------------------------
              lc_identifier          := 'FND_IS_03';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'XDO_CONFIG_VALUES';
              lc_action              := 'Verify SYSTEM_TEMP_DR value';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

			  lc_temp_dir_value      := NULL;
              xx_write_to_log (lc_filehandle,'Start of update, for FND_IS_03');

              SELECT value
			    INTO lc_result 
                FROM XDO_CONFIG_VALUES 
               WHERE property_code = 'SYSTEM_TEMP_DIR';
				 
			  lc_temp_dir_value := '/app/ebs/ct'||gc_8_char_instance_name_lower||'_system/APPLTMP/temp';

              IF lc_temp_dir_value = lc_result THEN
                 xx_write_to_log (lc_filehandle,'SYSTEM_TEMP_DIR exists and is properly configured: '||lc_result);
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle,'***ERROR*** SYSTEM_TEMP_DIR is NOT properly configured: '||lc_result);
				 lc_status        := 'ERROR'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
				 lc_exception_message := 'SYSTEM_TEMP_DIR is NOT properly configured';
              END IF;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_03: '||SQLERRM);
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to verify DBA directory';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina as per Version 1.34
		   BEGIN
              ------------------------------------------------------------------------------------------------------------------------
              -- FND_IS_04 - Checking the Values in fields infobundle_upload_date and infobundle_creation_date from AD_PM_MASTER Table
              ------------------------------------------------------------------------------------------------------------------------
              lc_identifier          := 'FND_IS_04';
              lc_object_type         := 'Standard Table';
              lc_object_name         := 'AD_PM_MASTER';
              lc_action              := 'Checking the fields infobundle_upload_date and infobundle_creation_date from AD_PM_MASTER Table';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
			  
			  ld_infobundle_upload_date := NULL;
              ld_infobundle_creation_date := NULL;
              IF lc_instance_name IN ('GSIDEV02','GSIDEV03') THEN
                 xx_write_to_log (lc_filehandle,'Check for FND_IS_04, for DEV02 and DEV03');

                 SELECT infobundle_upload_date, 
				        infobundle_creation_date
				   INTO ld_infobundle_upload_date,
				        ld_infobundle_creation_date
                   FROM AD_PM_MASTER; 
				   
                 IF ld_infobundle_upload_date IS NOT NULL OR ld_infobundle_creation_date IS NOT NULL
 				 THEN
                    xx_write_to_log (lc_filehandle,'Values in infobundle_upload_date and ld_infobundle_creation_date fields exist in AD_PM_MASTER Table');
                    lc_result        := 'Values in infobundle_upload_date and ld_infobundle_creation_date fields exists in AD_PM_MASTER Table';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle,'Values in infobundle_upload_date and ld_infobundle_creation_date fields do not exist in AD_PM_MASTER Table');
                    lc_result        := 'Values in infobundle_upload_date and ld_infobundle_creation_date fields do not exist in AD_PM_MASTER Table';
                    lc_status        := 'ERROR'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
					lc_exception_message   := 'Error encountered during FND_IS_04';
                 END IF;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_04: '||SQLERRM);
              lc_status              := 'ERROR'; 
              lc_result              := 'Values in infobundle_upload_date and ld_infobundle_creation_date fields do not exist in AD_PM_MASTER Table';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		 -- Added by Havish Kasina as per Version 1.54 
		  BEGIN
               -------------------------------------------------------
               -- FND_IS_06 - Update for External ADF Application URL  
               -------------------------------------------------------
               lc_identifier          := 'FND_IS_06';
               lc_object_type         := 'Profile Option';
               lc_object_name         := 'External ADF Application URL';
               lc_action              := 'Update site level';
               ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
               
               ld_end_date_time       := NULL;
               lc_exception_message   := NULL;
               lc_result              := NULL;
               lc_status              := NULL;
               ln_count               := 0;

               IF lc_instance_name = 'GSIDEV02' 
		       THEN
                   xx_write_to_log (lc_filehandle,'Start of update for FND_IS_06, for DEV02');
		       	
		       	lc_profile_value := 'https://tpmdev.na.odcorp.net/ODTradeMatchInvoiceWorkbench-ViewController-context-root';
		       	
		       ELSIF lc_instance_name = 'GSIUATGB' 
		       THEN
		       
		           xx_write_to_log (lc_filehandle,'Start of update for FND_IS_06, for UATGB');
		       	
		       	lc_profile_value := 'https://tpmuat.na.odcorp.net/ODTradeMatchInvoiceWorkbench-ViewController-context-root';
		       	
		       ELSIF  lc_instance_name = 'GSIPRFGB' 
		       THEN
		       
		           xx_write_to_log (lc_filehandle,'Start of update for FND_IS_06, for PRFGB');
		       	
		       	lc_profile_value := 'https://tpmprf.na.odcorp.net/ODTradeMatchInvoiceWorkbench-ViewController-context-root';
		       END IF;

               lb_profile_chg_result := NULL;
               lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'FND_EXTERNAL_ADF_URL'
                                                        ,x_value      => lc_profile_value
                                                        ,x_level_name => 'SITE');
               IF lb_profile_chg_result 
		       THEN
                   xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for FND_IS_06' );
                   lc_result        := lc_profile_value;
                   lc_status        := 'Success'; 
                   ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
               ELSE
                   xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for FND_IS_06' );
               END IF;
               COMMIT;

               xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);

              
          EXCEPTION 
          WHEN OTHERS 
          THEN
             xx_write_to_log (lc_filehandle,'Error encountered during FND_IS_06: '||SQLERRM);
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update the Profile Value for the Profile Option FND_EXTERNAL_ADF_URL ';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during FND_IS_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
		  END;
               
        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during FND instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Genneral Ledger ...'||CHR(10));
           BEGIN
              --xx_write_to_log (lc_filehandle,'Start of update, for GL_IS_01');
              -------------------------------------------------
              -- GL_IS_01 - Update for GL_SYNC_RATES_BPEL_SETUP 
              -------------------------------------------------
              lc_identifier          := 'GL_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'GL_SYNC_RATES_BPEL_SETUP';
              lc_action              := 'Update URL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for GL_IS_01, for PRFGB');

                 UPDATE (SELECT  XFTV.*      
                         FROM    xx_fin_translatedefinition XFTD
                                 ,xx_fin_translatevalues    XFTV
                         WHERE   XFTD.translate_id = XFTV.translate_id
                         AND     XFTD.translation_name like 'GL_SYNC_RATES_BPEL_SETUP') a
                 SET    a.target_value2 = 'http://esbprf01.na.odcorp.net/orabpel/financebatch/SynchCurrencyExchangeRate/d20100218_t14.53.58_r00093801_p38948.10'
                 WHERE  a.source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for GL_IS_01, in PRFGB is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for GL_IS_01, for UATGB');

                 UPDATE (SELECT  XFTV.*      
                         FROM    xx_fin_translatedefinition XFTD
                                 ,xx_fin_translatevalues    XFTV
                         WHERE   XFTD.translate_id = XFTV.translate_id
                         AND     XFTD.translation_name like 'GL_SYNC_RATES_BPEL_SETUP') a
                 SET    a.target_value2 = 'http://esbuat01.na.odcorp.net/orabpel/financebatch/SynchCurrencyExchangeRate/d20100218_t14.53.58_r00093801_p38948.10'
                 WHERE  a.source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for GL_IS_01, in UATGB is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- Added as per Version 1.22 by Havish Kasina
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for GL_IS_01, for SIT03');

                 UPDATE (SELECT  XFTV.*      
                         FROM    xx_fin_translatedefinition XFTD
                                 ,xx_fin_translatevalues    XFTV
                         WHERE   XFTD.translate_id = XFTV.translate_id
                         AND     XFTD.translation_name like 'GL_SYNC_RATES_BPEL_SETUP') a
                 SET    a.target_value2 = 'http://esbxxxxx.na.odcorp.net/orabpel/financebatch/SynchCurrencyExchangeRate/d20100218_t14.53.58_r00093801_p38948.10'
                 WHERE  a.source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for GL_IS_01, in SIT03 is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			 -- End of adding changes as per Version 1.22 by Havish Kasina

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update GL_IS_01, for all other instances ');

                 UPDATE (SELECT  XFTV.*      
                         FROM    xx_fin_translatedefinition XFTD
                                 ,xx_fin_translatevalues    XFTV
                         WHERE   XFTD.translate_id = XFTV.translate_id
                         AND     XFTD.translation_name like 'GL_SYNC_RATES_BPEL_SETUP') a
                 SET    a.target_value2 = NULL
                 WHERE  a.source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for GL_IS_01 is: ' || SQL%rowcount||CHR(10));
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;   
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during GL_IS_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during GL_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during General Ledger instance specific steps: '||SQLERRM||CHR(10));
           ROLLBACK;
           lc_status              := 'ERROR'; 
           lc_result              := 'Unable to update General Ledger instance specific steps';   
           ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
           lc_exception_message   := 'Error encountered during General Ledger instance specific steps: '||SQLERRM;

           xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                            ,p_identifier         => lc_identifier
                            ,p_status             => lc_status
                            ,p_object_type        => lc_object_type
                            ,p_object_name        => lc_object_name
                            ,p_action             => lc_action
                            ,p_result             => lc_result
                            ,p_start_date_time    => ld_start_date_time
                            ,p_end_date_time      => ld_end_date_time
                            ,p_exception_message  => lc_exception_message);
        END;

        BEGIN
          xx_write_to_log (lc_filehandle,'Start of update for iPayments ...'||CHR(10));
           BEGIN
              -------------------------------------------
              -- iPAY_IS_01 - Update for FTP_DETAILS_AJB  
              -------------------------------------------
              lc_identifier          := 'iPAY_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update AJB_SETTLEMENT_ARCHIVE_PATH';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_IS_01');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxfin/archive/outbound/AJB'
              WHERE  source_value1 = 'AJB_SETTLEMENT_ARCHIVE_PATH' 
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name='FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_IS_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------
              -- iPAY_IS_02 - Update for FTP_DETAILS_AJB  
              -------------------------------------------
              lc_identifier          := 'iPAY_IS_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update HTTPWalletLoc';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_IS_02');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'file:/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxfin/ewallet'
              WHERE  source_value1 = 'HTTPWalletLoc' 
              AND    translate_id = (SELECT translate_id 
                                     FROM   xx_fin_translatedefinition 
                                     WHERE  translation_name = 'FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_IS_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for iPAY_IS_02 '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------
              -- iPAY_IS_03 - Update for FTP_DETAILS_AJB  
              -------------------------------------------
              lc_identifier          := 'iPAY_IS_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update Amex File Path';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_IS_03');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxfin/ftp/out/amexcpc'
              WHERE  source_value1 = 'Amex File Path' 
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_IS_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------
              -- iPAY_IS_04 - Update for FTP_DETAILS_AJB  
              -------------------------------------------
              lc_identifier          := 'iPAY_IS_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'FTP_DETAILS_AJB';
              lc_action              := 'Update HTTPURL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iPAY_IS_04');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'https://USCHAJBAPPS01T.na.odcorp.net:28101' --Commented as per Version 1.13 --gc_8_char_instance_name_lower 
              WHERE  source_value1 = 'HTTPURL' 
              AND    translate_id  = (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition 
                                      WHERE  translation_name = 'FTP_DETAILS_AJB');

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iPAY_IS_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------
              -- iPAY_IS_05 - Update for IBY: XML Base  
              -----------------------------------------
              lc_identifier          := 'iPAY_IS_05';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'IBY: XML Base';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => '/app/ebs/itgsiprfgb/gsiprfgbapps/apps/apps_st/appl/iby/12.0.0/xml'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := '/app/ebs/itgsiprfgb/gsiprfgbapps/apps/apps_st/appl/iby/12.0.0/xml';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => '/app/ebs/itgsiuatgb/gsiuatgbapps/apps/apps_st/appl/iby/12.0.0/xml'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := '/app/ebs/itgsiuatgb/gsiuatgbapps/apps/apps_st/appl/iby/12.0.0/xml';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for SIT02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => '/app/ebs/itgsisit02/gsisit02apps/apps/apps_st/appl/iby/12.0.0/xml'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := '/app/ebs/itgsisit02/gsisit02apps/apps/apps_st/appl/iby/12.0.0/xml';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			  
              -- Added as per Version 1.22 by Havish Kasina	
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => '/app/ebs/itgsisit03/gsisit03apps/apps/apps_st/appl/iby/12.0.0/xml'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := '/app/ebs/itgsisit03/gsisit03apps/apps/apps_st/appl/iby/12.0.0/xml';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
              -- End of adding changes as per Version 1.22 by Havish Kasina	
			  
              ELSIF lc_instance_name = 'GSIDEV02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for DEV02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => '/app/ebs/itgsidev02/gsidev02apps/apps/apps_st/appl/iby/12.0.0/xml'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := '/app/ebs/itgsidev02/gsidev02apps/apps/apps_st/appl/iby/12.0.0/xml';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_05, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_05' );
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_05' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for iPAY_IS_05 '||SQLERRM);
              ROLLBACK;
           END;

           BEGIN
              ---------------------------------------------------
              -- iPAY_IS_06 - Update for IBY: XML Temp Directory  
              ---------------------------------------------------
              lc_identifier          := 'iPAY_IS_06';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'IBY: XML Temp Directory';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              IF lc_instance_name = 'GSIDEV02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_06, for DEV02');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_TEMP'
                                                          ,x_value      => '/app/ebs/itgsidev02/gsidev02inst/apps/GSIDEV02_choleba31d/appltmp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_06' );
                    lc_result        := '/app/ebs/itgsidev02/gsidev02inst/apps/GSIDEV02_choleba31d/appltmp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_06' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_06, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_TEMP'
                                                          ,x_value      => '/app/ebs/ct'||gc_8_char_instance_name_lower||'_system/APPLTMP/temp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_06' );
                    lc_result        := '/app/ebs/ct'||gc_8_char_instance_name_lower||'_system/APPLTMP/temp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_06' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------
              -- iPAY_IS_07 - Update for IBY: ECAPP URL 
              -----------------------------------------
              lc_identifier          := 'iPAY_IS_07';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'IBY: ECAPP URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              -- Commented as per Version 1.40 ( Defect 37296)
			 
              /*IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'http://gsiprfgbipayment.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'http://gsiprfgbipayment.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'http://gsiuatgbipayment.na.odcorp.net:80/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'http://gsiuatgbipayment.na.odcorp.net:80/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for SIT02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'http://gsisit02.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'http://gsisit02.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- Added as per Version 1.22 by Havish Kasina
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'http://gsisit03.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'http://gsisit03.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								
			  -- End of adding changes as per Version 1.22 by Havish Kasina

              ELSIF lc_instance_name = 'GSIDEV02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for DEV02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'http://choleba31d.na.odcorp.net:8031/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'http://choleba31d.na.odcorp.net:8031/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              END IF;*/
			  -- Added as per Version 1.40 (Defect 37296)
			  
			  IF lc_instance_name IN ('GSIPRFGB','GSIUATGB')  -- Added as per version 1.45 (Defect 38347)
			  THEN
			    xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'ipayment.na.odcorp.net/OA_HTML/ibyecapp'  
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'ipayment.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;			    
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			  ELSE
			    xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_07');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_ECAPP_URL'
                                                          ,x_value      => 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'.na.odcorp.net/OA_HTML/ibyecapp'  
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_07'||CHR(10));
                    lc_result        := 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_07'||CHR(10));
                 END IF;			    
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			  END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_07: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_07: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

            BEGIN
              ----------------------------------------------------------
              -- iPAY_IS_08 - Update for ICX: Oracle Payment Server URL 
              ----------------------------------------------------------
              lc_identifier          := 'iPAY_IS_08';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'ICX: Oracle Payment Server URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
          -- Commented as per Version 1.40 (Defect 37296)
		  
              /*IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'http://gsiprfgbipayment.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'http://gsiprfgbipayment.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'http://gsiuatgbipayment.na.odcorp.net:80/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'http://gsiuatgbipayment.na.odcorp.net:80/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for SIT02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'http://gsisit02.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'http://gsisit02.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- Added as per Version 1.22 by Havish Kasina
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'http://gsisit03.na.odcorp.net/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'http://gsisit03.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
				-- End of adding changes as per Version 1.22 by Havish Kasina

              ELSIF lc_instance_name = 'GSIDEV02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for DEV02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'http://choleba31d.na.odcorp.net:8031/OA_HTML/ibyecapp'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'http://choleba31d.na.odcorp.net:8031/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              END IF;*/
	 -- Added as per Version 1.40 (Defect 37296)  
	 
	       IF lc_instance_name IN ('GSIPRFGB','GSIUATGB')  -- Added as per version 1.45 (Defect 38347)
		   THEN
			  xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'ipayment.na.odcorp.net/OA_HTML/ibyecapp' 
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'ipayment.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
		  ELSE
		     xx_write_to_log (lc_filehandle,'Start of update for iPAY_IS_08');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'ICX_PAY_SERVER'
                                                          ,x_value      => 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'.na.odcorp.net/OA_HTML/ibyecapp' 
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iPAY_IS_08'||CHR(10));
                    lc_result        := 'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'.na.odcorp.net/OA_HTML/ibyecapp';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iPAY_IS_08'||CHR(10));
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
		  END IF;
								 			  
         EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iPAY_IS_08: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iPAY_IS_08: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

       EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during iPayments instance specific steps: '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Order Management ...'||CHR(10));
           BEGIN
              ---------------------------------------
              -- OM_IS_01 - Update for XXOM_INBOUND  
              ---------------------------------------
              lc_identifier          := 'OM_IS_01';
              lc_object_type         := 'DBA Directories';
              lc_object_name         := 'XXOM_INBOUND';
              lc_action              := 'Verify DBA Directories';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for OM_IS_01');

              ln_dir_cnt := 0;
              SELECT COUNT(1)
              INTO   ln_dir_cnt
              FROM   (SELECT owner
                             ,directory_name
                             ,directory_path
                      FROM   dba_directories DBAD
                      WHERE  directory_name  = 'XXOM_INBOUND'
                      AND    directory_path  = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/ftp/in');

              IF ln_dir_cnt > 0 THEN
                 xx_write_to_log (lc_filehandle,'XXOM_INBOUND exists and is properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/ftp/in');
                 lc_result        := '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/ftp/in';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle,'***ERROR*** XXOM_INBOUND is NOT properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/ftp/in');
				 lc_status        := 'ERROR'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
				 lc_exception_message := 'XXOM_INBOUND does not exist';
              END IF;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_IS_01: '||SQLERRM);
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to verify DBA directory';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -------------------------------------------
              -- OM_IS_02 - Update for XXOM_INBOUND_ARCH  
              -------------------------------------------
              lc_identifier          := 'OM_IS_02';
              lc_object_type         := 'DBA Directories';
              lc_object_name         := 'XXOM_INBOUND_ARCH';
              lc_action              := 'Verify DBA Directories';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for OM_IS_02');

              ln_dir_cnt := 0;
              SELECT COUNT(1)
              INTO   ln_dir_cnt
              FROM   (SELECT owner 
                             ,directory_name
                             ,directory_path
                      FROM   dba_directories DBAD
                      WHERE  directory_name  = 'XXOM_INBOUND_ARCH'
                      AND    directory_path  = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/archive/inbound');

              IF ln_dir_cnt > 0 THEN
                 xx_write_to_log (lc_filehandle,'XXOM_INBOUND_ARCH exists and is properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/archive/inbound');
                 lc_result        := '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/archive/inbound';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle,'***ERROR*** XXOM_INBOUND_ARCH is NOT properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/archive/inbound');
				 lc_status        := 'ERROR'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
				 lc_exception_message := 'XXOM_INBOUND_ARCH does not exist';
              END IF;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_IS_02: '||SQLERRM);
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to verify DBA directory';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
               -------------------------------------------
               -- OM_IS_03 - Update for XXOM_OUTBOUND  
               -------------------------------------------
              lc_identifier          := 'OM_IS_03';
              lc_object_type         := 'DBA Directories';
              lc_object_name         := 'XXOM_OUTBOUND';
              lc_action              := 'Verify DBA Directories';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

               xx_write_to_log (lc_filehandle,'Start of update, for OM_IS_03');

              ln_dir_cnt := 0;
              SELECT COUNT(1)
              INTO   ln_dir_cnt
              FROM   (SELECT owner 
                             ,directory_name
                             ,directory_path
                      FROM   dba_directories DBAD
                      WHERE  directory_name  = 'XXOM_OUTBOUND'
                      AND    directory_path  = '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/outbound');

              IF ln_dir_cnt > 0 THEN
                 xx_write_to_log (lc_filehandle,'XXOM_OUTBOUND exists and is properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/outbound'||CHR(10));
                 lc_result        := '/app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/outbound';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle,'***ERROR*** XXOM_OUTBOUND is NOT properly configured: /app/ebs/ct'||gc_8_char_instance_name_lower||'/xxom/outbound'||CHR(10));
				 lc_status        := 'ERROR'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
				 lc_exception_message := 'XXOM_OUTBOUND does not exist';
              END IF;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_IS_03: '||SQLERRM||CHR(10));
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to verify DBA directory';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Suresh Naragam on 04-Oct-2017
		   BEGIN
		      -----------------------------------------------------------
              -- OM_IS_04 - Update Translation OD_SHIP_OUTBOUND_SERVICE 
              -----------------------------------------------------------
              lc_identifier          := 'OM_IS_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'OD_SHIP_OUTBOUND_SERVICE';
              lc_action              := 'Update URL For Outbound Service ';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              IF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for OM_IS_04, for SIT02');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'http://osbsit01.na.odcorp.net/eai/OrderManagement/NoneTradeShipmentTrackingService'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in SIT02 is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'R8xdw2bs'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'PASSWORD';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in SIT02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
			  ELSIF lc_instance_name = 'GSIDEV02' THEN					 
				xx_write_to_log (lc_filehandle,'Start of update for OM_IS_04, for DEV02');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'http://osbdev01.na.odcorp.net/eai/OrderManagement/NoneTradeShipmentTrackingService'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in DEV02 is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'R8xdw2bs'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'PASSWORD';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in DEV02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
			  ELSIF lc_instance_name = 'GSIUATGB' THEN					 
				xx_write_to_log (lc_filehandle,'Start of update for OM_IS_04, for UATGB');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'http://osbuat01.na.odcorp.net/eai/OrderManagement/NoneTradeShipmentTrackingService'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'URL';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in UATGB is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'R8xdw2bs'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'PASSWORD';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in UATGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for OM_IS_04, for PRFGB');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'http://osbprf01.na.odcorp.net/eai/OrderManagement/NoneTradeShipmentTrackingService'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'URL';
				  
                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in PRFGB is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = 'R8xdw2bs'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'PASSWORD';

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in PRFGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for OM_IS_04, for all other instances ');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = NULL
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'URL';

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in all other instances is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = NULL
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'PASSWORD';

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in all other instances is: ' || SQL%rowcount );
				 
				 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value1 = NULL
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'OD_SHIP_OUTBOUND_SERVICE')
				  AND source_value1 = 'USERNAME';

                 xx_write_to_log (lc_filehandle,'No of rows updated for OM_IS_04, in all other instances is: ' || SQL%rowcount );
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during OM_IS_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update translation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during OM_IS_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Order Management instance specific steps '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Service ...'||CHR(10));
           BEGIN
              ----------------------------------------------------
              -- SERVICE_IS_01 - Update for OD B2B Web Methods URL 
              ----------------------------------------------------
              lc_identifier          := 'SERVICE_IS_01';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD B2B Web Methods URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_01, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_B2B_WEB_URL'
                                                          ,x_value      => 'http://soaprf01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_01' );
                    lc_result        := 'http://soaprf01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_01' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

         ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_01, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_B2B_WEB_URL'
                                                          ,x_value      => 'http://soauat01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_01' );
                    lc_result        := 'http://soauat01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_01' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_01, for SIT02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_B2B_WEB_URL'
                                                          ,x_value      => 'http://soasit01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_01' );
                    lc_result        := 'http://soasit01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_01' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              -- Added as per Version 1.22 by Havish Kasina
								 
	          ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_01, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_B2B_WEB_URL'
                                                          ,x_value      => 'http://eaiuat01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_01' );
                    lc_result        := 'http://eaiuat01.na.odcorp.net/soa-infra/services/om/ServiceB2BOutbound/client';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_01' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- End of adding changes as per version 1.22 by Havish Kasina

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_01, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_B2B_WEB_URL'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_01' );
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_01' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_IS_01: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ----------------------------------------------------------------------
              -- SERVICE_IS_02 - Update for OD: MPS Cost Center and PO validation URL
              ----------------------------------------------------------------------
              lc_identifier          := 'SERVICE_IS_02';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: MPS Cost Center and PO validation URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_02, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_COSTCTR_PO_URL'
                                                          ,x_value      => 'http://soaprf01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_02' );
                    lc_result        := 'http://soaprf01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_02' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_02, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_COSTCTR_PO_URL'
                                                          ,x_value      => 'http://soauat01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_02' );
                    lc_result        := 'http://soauat01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_02' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_02, for SIT02');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_COSTCTR_PO_URL'
                                                          ,x_value      => 'http://soasit01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_02' );
                    lc_result        := 'http://soasit01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_02' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- Added as per Version 1.22 by Havish Kasina
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_02, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_COSTCTR_PO_URL'
                                                          ,x_value      => 'http://eaiuat01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_02' );
                    lc_result        := 'http://eaiuat01.na.odcorp.net/soa-infra/services/cdh_rt/SyncCustomerCCAOPSReqABCS/SyncCustomerCCAOPSReqABCS_client_ep';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_02' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
				-- End of adding changes as per Version 1.22 by Havish Kasina

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_02, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_COSTCTR_PO_URL'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_02' );
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_02' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_IS_02: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------------------------------------
              -- SERVICE_IS_03 - Update for OD: MPS Usage Vendor Data Transmission WebService URL 
              -----------------------------------------------------------------------------------
              lc_identifier          := 'SERVICE_IS_03';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: MPS Usage Vendor Data Transmission WebService URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              IF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_03, for PRFGB');

                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_USG_VENDOR_URL'
                                                          ,x_value      => 'http://osbprf01.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_03' );
                    lc_result        := 'http://osbprf01.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_03' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              ELSIF lc_instance_name = 'GSIUATGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_03, for UATGB');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_USG_VENDOR_URL'
                                                          ,x_value      => 'http://osbuat01.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_03' );
                    lc_result        := 'http://osbuat01.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_03' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- Added as per Version 1.22 by Havish Kasina
			  
			  ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_03, for SIT03');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_USG_VENDOR_URL'
                                                          ,x_value      => 'http://osbxxxxx.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS'
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_03' );
                    lc_result        := 'http://osbxxxxx.na.odcorp.net/osb-infra/GetMPSGalcMeterABCS/Services/ProxyServices/GetMPSGalcMeterABCSPS';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_03' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  -- End of adding changes as per Version 1.22 by Havish Kasina

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_03, for all other instances ');
                 lb_profile_chg_result := NULL;
                 lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_MPS_USG_VENDOR_URL'
                                                          ,x_value      => NULL
                                                          ,x_level_name => 'SITE');
                 IF lb_profile_chg_result THEN
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_03' );
                    lc_result        := 'NULL';
                    lc_status        := 'Success'; 
                    ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 ELSE
                    xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_03' );
                 END IF;
                 COMMIT;

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);

              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_IS_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              ---------------------------------------------------
              -- SERVICE_IS_04 - Update for OD : CS SOP Func URL  
              ---------------------------------------------------
              lc_identifier          := 'SERVICE_IS_04';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS SOP Func URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_IS_04');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_SOP_FUNCTION_URL'
                                                       ,x_value      => 'https://'||gc_8_char_instance_name_lower||'.na.odcorp.net/XXCRM_HTML/xxod_ibuStoreSupportDashboard.jsp?srID='  -- Modified as per version 1.45
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_04' );
                 lc_result        := 'https://'||gc_8_char_instance_name_lower||'.na.odcorp.net/XXCRM_HTML/xxod_ibuStoreSupportDashboard.jsp?srID=';  -- Modified as per version 1.45
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_04' );
              END IF;
              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error while updating, for SERVICE_IS_04 '||SQLERRM);
              ROLLBACK;
           END;

           BEGIN
              ---------------------------------------------------
              -- SERVICE_IS_05 - Update for OD : CS SOP Link URL  
              ---------------------------------------------------
              lc_identifier          := 'SERVICE_IS_05';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD : CS SOP Link URL';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for SERVICE_IS_05');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_CS_SOP_LINK_URL'
                                                       ,x_value      => 'https://'||gc_8_char_instance_name_lower||'.na.odcorp.net/OA_HTML/xx_ibuSRDetails.jsp?srID='  -- Modified as per version 1.45
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for SERVICE_IS_05'||CHR(10));
                 lc_result        := 'https://'||gc_8_char_instance_name_lower||'.na.odcorp.net/OA_HTML/xx_ibuSRDetails.jsp?srID=';  -- Modified as per version 1.45
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for SERVICE_IS_05'||CHR(10));
              END IF;
              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_IS_05: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_IS_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina, as per Version 1.24 
		   BEGIN
		      -----------------------------------------------------------
              -- SERVICE_IS_06 - Update Translation XXCS_EMAIL_CONFIG 
              -----------------------------------------------------------
              lc_identifier          := 'SERVICE_IS_06';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXCS_EMAIL_CONFIG';
              lc_action              := 'Update POP_WALLET_PATH and POP_WALLET_PWD and EMAIL_USER_NAME and EMAIL_PWD ';  -- Modified as per Version 1.31
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              IF lc_instance_name = 'GSISIT02' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for SIT02');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsisit02/owm/wallets/oracle',
                         target_value5 = 'orasit02',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in SIT02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name = 'GSISIT03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for SIT03');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsisit03/owm/wallets/oracle',
                         target_value5 = 'orasit03',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in SIT03 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  ELSIF lc_instance_name = 'GSIDEV02' THEN					 
				xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for DEV02');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsidev02/owm/wallets/oracle',
                         target_value5 = 'oradev02',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in DEV02 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name = 'GSIDEV03' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for DEV03');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsidev03/owm/wallets/oracle',
                         target_value5 = 'oradev03',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in DEV03 is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
			  ELSIF lc_instance_name = 'GSIUATGB' THEN					 
				xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for UATGB');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsiuatgb/owm/wallets/oracle',
                         target_value5 = 'walletuatgb',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in UATGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name = 'GSIPRFGB' THEN
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for PRFGB');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = 'file:/oracle/product/database/11.2.0/gsiprfgb/owm/wallets/oracle',
                         target_value5 = 'walletprfgb',
                         target_value6 = 'SVC-CallCenter-test@officedepot.com',
                         target_value7 =  'Center2013'
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in PRFGB is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 
              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for SERVICE_IS_06, for all other instances ');

                 UPDATE  XX_FIN_TRANSLATEVALUES
                    SET  target_value4 = NULL,
                         target_value5 = NULL,
                         target_value6 = NULL,
                         target_value7 = NULL
                  WHERE  translate_id = ( SELECT  translate_id
                                            FROM  XX_FIN_TRANSLATEDEFINITION
                                           WHERE  translation_name =  'XXCS_EMAIL_CONFIG');

                 xx_write_to_log (lc_filehandle,'No of rows updated for SERVICE_IS_06, in all other instances is: ' || SQL%rowcount );
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF;
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during SERVICE_IS_06: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update translation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during SERVICE_IS_06: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Service instance specific steps '||SQLERRM||CHR(10));
        END;

        BEGIN
           xx_write_to_log (lc_filehandle,'Start of update for Web Collect instance specific steps...'||CHR(10));
           BEGIN
              -----------------------------------------------------
              -- WEBC_IS_01 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_IS_01';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update CUST_ADDRESSES';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_IS_01');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value4 = 'XX_CRM_CUSTADDR_STG_'||gc_5_char_instance_name_upper
              WHERE  v.translate_id = (SELECT d.translate_id
                                       FROM   xx_fin_translatedefinition d
                                       WHERE  d.translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
              AND    v.source_value1 = 'CUST_ADDRESSES'; 

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_IS_01 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_IS_01: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_IS_01: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------
              -- WEBC_IS_02 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_IS_02';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update CUST_CONTACTS';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_IS_02');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value4 = 'XX_CRM_CUSTCONT_STG_'||gc_5_char_instance_name_upper
              WHERE  v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
              AND    v.source_value1 = 'CUST_CONTACTS';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_IS_02 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_IS_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------
              -- WEBC_IS_03 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_IS_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update CUST_HEADER';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_IS_03');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value4 = 'XX_CRM_CUSTMAST_HEAD_STG_'||gc_5_char_instance_name_upper
              WHERE  v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
              AND    v.source_value1 = 'CUST_HEADER';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_IS_03 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_IS_03: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------
              -- WEBC_IS_04 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_IS_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update CUST_RELATIONSHIP';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_IS_04');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value4 = 'XXOD_CRM_CUST_REL_'||gc_5_char_instance_name_upper
              WHERE  v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
              AND    v.source_value1 = 'CUST_RELATIONSHIP';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_IS_04 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_IS_04: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_IS_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

           BEGIN
              -----------------------------------------------------
              -- WEBC_IS_05 - Update for XXOD_WEBCOLLECT_INTERFACE  
              -----------------------------------------------------
              lc_identifier          := 'WEBC_IS_05';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XXOD_WEBCOLLECT_INTERFACE';
              lc_action              := 'Update CUST_SALES_ASSIGNMENT';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for WEBC_IS_05');

              UPDATE xx_fin_translatevalues v
              SET    v.target_value4 = 'XXOD_CRM_SLSA_'||gc_5_char_instance_name_upper
              WHERE  v.translate_id  = (SELECT d.translate_id
                                        FROM   xx_fin_translatedefinition d
                                        WHERE  d.translation_name = 'XXOD_WEBCOLLECT_INTERFACE')
              AND    v.source_value1 = 'CUST_SALES_ASSIGNMENT';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for customer addresses, for WEBC_IS_05 is: ' || SQL%rowcount );
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during WEBC_IS_05: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during WEBC_IS_05: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;

        EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for Web Collect instance specific steps '||SQLERRM||CHR(10));
        END;
    BEGIN
     xx_write_to_log (lc_filehandle,'Start of update for iREC instance specific steps...'||CHR(10));
     ------------------------------------------------------------------------------------
     -- Added  for iREC_IS_01
     ------------------------------------------------------------------------------------
     BEGIN
     -----------------------------------------------------------------------------------
     -- iREC_IS_01  - Update for OD IReceivables Host URL
     -----------------------------------------------------------------------------------
     lc_identifier        := 'iREC_IS_01';
     lc_object_type       := 'Profile Option';
     lc_object_name       := 'OD IReceivables Host URL';
     lc_action            := 'Update site level';
     ld_start_date_time   := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
     ld_end_date_time     := NULL;
     lc_exception_message := NULL;
     lc_result            := NULL;
     lc_status            := NULL;
     lc_profile_name      :='XX_OD_IREC_URL';
     lc_soa_host          :=NULL;
     lc_soa_hosturl       :=NULL;
     --IF lc_instance_name IN ('GSIDEV01' , 'GSIDEV02') THEN -- Commented as per Version 1.21
	 IF lc_instance_name IN ('GSIDEV01' , 'GSIDEV02' , 'GSIDEV03') THEN -- Added GSIDEV03 instance as per Version 1.21
      lc_soa_host := 'soadev01';
     ELSIF lc_instance_name IN ('GSISIT01','GSISIT02') THEN
      lc_soa_host         := 'soadev01';  --'soasit01'; -- V 1.12 --> Commented as per Defect#33858. 
     ELSIF lc_instance_name = 'GSISIT03' THEN -- Added as per Version 1.22 by Havish Kasina
      lc_soa_host         := 'eaiuat01';	 
     ELSIF lc_instance_name = 'GSIUATGB' THEN
      lc_soa_host         := 'soauat01';
     ELSIF lc_instance_name = 'GSIPRFGB' THEN
      lc_soa_host         := 'soaprf01';
     ELSIF lc_instance_name = 'GSIPRDGB' THEN
      lc_soa_host         := 'soaprd01';
	 ELSE
	  lc_soa_host         := 'soaxxxxx';  -- Added as per Version 1.22 by Havish Kasina
     END IF;
     IF lc_soa_host  IS NOT NULL THEN
      lc_soa_hosturl:='http://'||lc_soa_host||'.na.odcorp.net:80/soa-infra/services/finance_rt/CreateBankACHPaymentsReqABCS/createbankachpaymentsreqabcsprocess_client_ep?WSDL';
      xx_write_to_log (lc_filehandle,'Start of update for'||lc_identifier||', for '||lc_instance_name);
      lb_profile_chg_result := NULL;
      lb_profile_chg_result := FND_PROFILE.SAVE(x_name => lc_profile_name ,x_value => lc_soa_hosturl ,x_level_name => 'SITE');
      IF lb_profile_chg_result THEN
        xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for '||lc_identifier );
        lc_result        := lc_soa_hosturl;
        lc_status        := 'Success';
        ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
      ELSE
        xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for '||lc_identifier );
      END IF;
      COMMIT;
      xx_write_to_file(p_filehandle_csv => lc_filehandle_csv ,p_identifier => lc_identifier ,p_status => lc_status ,p_object_type => lc_object_type ,p_object_name => lc_object_name ,p_action => lc_action ,p_result => lc_result ,p_start_date_time => ld_start_date_time ,p_end_date_time => ld_end_date_time ,p_exception_message => lc_exception_message);
     ELSE -- SOA Host null
      xx_write_to_log (lc_filehandle, 'Profile Value not exists for '|| lc_instance_name || ' '||lc_identifier);
      lc_status            := 'ERROR';
      lc_result            := 'Unable to update profile option';
      ld_end_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
      lc_exception_message := 'Error encountered during '||lc_identifier||' '||'Profile Value for '|| lc_instance_name || ' not found ';
      xx_write_to_file(p_filehandle_csv => lc_filehandle_csv ,p_identifier => lc_identifier ,p_status => lc_status ,p_object_type => lc_object_type ,p_object_name => lc_object_name ,p_action => lc_action ,p_result => lc_result ,p_start_date_time => ld_start_date_time ,p_end_date_time => ld_end_date_time ,p_exception_message => lc_exception_message);
     END IF;
     EXCEPTION
        WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error encountered during '||lc_identifier||' '||SQLERRM);
           ROLLBACK;
           lc_status            := 'ERROR';
           lc_result            := 'Unable to update profile option';
           ld_end_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
           lc_exception_message := 'Error encountered during '||lc_identifier||' '||SQLERRM;
           xx_write_to_file(p_filehandle_csv => lc_filehandle_csv ,p_identifier => lc_identifier ,p_status => lc_status ,p_object_type => lc_object_type ,p_object_name => lc_object_name ,p_action => lc_action ,p_result => lc_result ,p_start_date_time => ld_start_date_time ,p_end_date_time => ld_end_date_time ,p_exception_message => lc_exception_message);
      END;
     -- End - Added  for iREC_IS_01
	  
	 -- Added as per Version 1.19 by Havish Kasina
	 BEGIN
              ------------------------------------------------------------------------
              -- iREC_IS_02 -> Update for OD: iRec Receipts Confirm Page Template Url  
              ------------------------------------------------------------------------
              lc_identifier          := 'iREC_IS_02';
              lc_object_type         := 'Profile Option';
              lc_object_name         := 'OD: iRec Receipts Confirm Page Template Url';
              lc_action              := 'Update site level';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              
              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_IS_02');

              lb_profile_chg_result := NULL;
              lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_FIN_IREC_CONF_PAGE_TEMPLATE_URL'
                                                       ,x_value      => '/app/ebs/it'||GC_8_CHAR_INSTANCE_NAME_LOWER||'/'||GC_8_CHAR_INSTANCE_NAME_LOWER||'cust/xxfin/xml/templates/'
                                                       ,x_level_name => 'SITE');
              IF lb_profile_chg_result THEN
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = TRUE - profile updated, for iREC_IS_02'||CHR(10));
                 lc_result        := '/app/ebs/it'||GC_8_CHAR_INSTANCE_NAME_LOWER||'/'||GC_8_CHAR_INSTANCE_NAME_LOWER||'cust/xxfin/xml/templates/';
                 lc_status        := 'Success'; 
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              ELSE
                 xx_write_to_log (lc_filehandle, 'lb_profile_result = FALSE - profile NOT updated, for iREC_IS_02'||CHR(10));
              END IF;
              COMMIT;

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_IS_02: '||SQLERRM||CHR(10));
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update profile option';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_IS_02: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina, as per Version 1.23 --> Defect # 35177
		   BEGIN
		      -----------------------------------------------------------
              -- iREC_IS_03 - Update Translation XX_FIN_IREC_TOKEN_PARAMS 
              -----------------------------------------------------------
              lc_identifier          := 'iREC_IS_03';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_FIN_IREC_TOKEN_PARAMS';
              lc_action              := 'Update AJB_URL';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;
               -- Commented as per Version 1.40 (Defect 37296)
			   
              /*IF lc_instance_name IN ('GSISIT02','GSISIT03') THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iREC_IS_03, for SIT02 and SIT03');

                 UPDATE  xx_fin_translatevalues
                    SET  target_value1 = 'http://gsisit02.na.odcorp.net/OA_HTML/oramipp_ods'
                  WHERE  source_value1 = 'AJB_URL'
                    AND  translate_id  = (SELECT translate_id 
                                            FROM  xx_fin_translatedefinition 
                                           WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_03, in SIT02 and SIT03 are: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
                 
              ELSIF lc_instance_name IN ('GSIDEV02','GSIDEV03') THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iREC_IS_03, for DEV02 and DEV03');

                 UPDATE  xx_fin_translatevalues
                    SET  target_value1 = 'http://gsidev02.na.odcorp.net/OA_HTML/oramipp_ods'
                  WHERE  source_value1 = 'AJB_URL'
                    AND  translate_id  = (SELECT translate_id 
                                            FROM  xx_fin_translatedefinition 
                                           WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_03, in DEV02 and DEV03 are: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			 
			  ELSIF lc_instance_name IN ('GSIPRFGB','GSIUATGB') THEN
                 xx_write_to_log (lc_filehandle,'Start of update for iREC_IS_03, for UATGB and PRFGB');

                 UPDATE  xx_fin_translatevalues
                    SET  target_value1 = 'http://gsiuatgb.na.odcorp.net/OA_HTML/oramipp_ods'
                  WHERE  source_value1 = 'AJB_URL'
                    AND  translate_id  = (SELECT translate_id 
                                            FROM  xx_fin_translatedefinition 
                                           WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_03, in UATGB and PRFGB are: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
								 

              ELSE
                 xx_write_to_log (lc_filehandle,'Start of update for iREC_IS_03, for all other instances ');

                 UPDATE  xx_fin_translatevalues
                    SET  target_value1 = NULL
                  WHERE  source_value1 = 'AJB_URL'
                    AND  translate_id  = (SELECT translate_id 
                                            FROM  xx_fin_translatedefinition 
                                           WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

                 xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_03, in all other instances are: ' || SQL%rowcount );
                COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
              END IF; */ 
			  -- Added as per Version 1.40 (Defect 37296)
			  xx_write_to_log (lc_filehandle,'Start of update for iREC_IS_03');

                 UPDATE  xx_fin_translatevalues
                    SET  target_value1 =  'https://'||GC_8_CHAR_INSTANCE_NAME_LOWER||'.na.odcorp.net/OA_HTML/oramipp_ods' -- Modified as per version 1.45
                  WHERE  source_value1 = 'AJB_URL'
                    AND  translate_id  = (SELECT translate_id 
                                            FROM  xx_fin_translatedefinition 
                                           WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS');

                 ln_count := SQL%rowcount;

                 xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_03, is: ' || SQL%rowcount );
                 COMMIT;

                 lc_status        := 'Success'; 
                 lc_result        := 'Updated: '||ln_count||' rows';
                 ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
                 
                 xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                                 ,p_identifier         => lc_identifier
                                 ,p_status             => lc_status
                                 ,p_object_type        => lc_object_type
                                 ,p_object_name        => lc_object_name
                                 ,p_action             => lc_action
                                 ,p_result             => lc_result
                                 ,p_start_date_time    => ld_start_date_time
                                 ,p_end_date_time      => ld_end_date_time
                                 ,p_exception_message  => lc_exception_message);
			  
           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_IS_03: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update translation definition';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_IS_03: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
		   -- Added by Havish Kasina as per Version 1.43
		   BEGIN
              ---------------------------------------------------
              -- iREC_IS_04 - Update for XX_FIN_IREC_TOKEN_PARAMS 
              ---------------------------------------------------
              lc_identifier          := 'iREC_IS_04';
              lc_object_type         := 'Translation';
              lc_object_name         := 'XX_FIN_IREC_TOKEN_PARAMS';
              lc_action              := 'Update Target_value1 for WALLET_LOCATION';
              ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              ld_end_date_time       := NULL;
              lc_exception_message   := NULL;
              lc_result              := NULL;
              lc_status              := NULL;
              ln_count               := 0;

              xx_write_to_log (lc_filehandle,'Start of update, for iREC_IS_04');

              UPDATE xx_fin_translatevalues 
              SET    target_value1 = 'file:/app/ebs/ct'||GC_8_CHAR_INSTANCE_NAME_LOWER||'/xxfin/ewallet'                       
              WHERE  translate_id IN (SELECT translate_id 
                                      FROM   xx_fin_translatedefinition
                                      WHERE  translation_name = 'XX_FIN_IREC_TOKEN_PARAMS')
			    AND  SOURCE_VALUE1 = 'WALLET_LOCATION';

              ln_count := SQL%rowcount;

              xx_write_to_log (lc_filehandle,'No of rows updated for iREC_IS_04 is: '||SQL%ROWCOUNT);
              COMMIT;

              lc_status        := 'Success'; 
              lc_result        := 'Updated: '||ln_count||' rows';
              ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

              xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
                              ,p_identifier         => lc_identifier
                              ,p_status             => lc_status
                              ,p_object_type        => lc_object_type
                              ,p_object_name        => lc_object_name
                              ,p_action             => lc_action
                              ,p_result             => lc_result
                              ,p_start_date_time    => ld_start_date_time
                              ,p_end_date_time      => ld_end_date_time
                              ,p_exception_message  => lc_exception_message);

           EXCEPTION 
              WHEN OTHERS THEN
              xx_write_to_log (lc_filehandle,'Error encountered during iREC_IS_04: '||SQLERRM);
              ROLLBACK;
              lc_status              := 'ERROR'; 
              lc_result              := 'Unable to update transalation';   
              ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
              lc_exception_message   := 'Error encountered during iREC_IS_04: '||SQLERRM;

              xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
                               ,p_identifier         => lc_identifier
                               ,p_status             => lc_status
                               ,p_object_type        => lc_object_type
                               ,p_object_name        => lc_object_name
                               ,p_action             => lc_action
                               ,p_result             => lc_result
                               ,p_start_date_time    => ld_start_date_time
                               ,p_end_date_time      => ld_end_date_time
                               ,p_exception_message  => lc_exception_message);
           END;
		   
	  EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for iREC instance specific steps '||SQLERRM||CHR(10));
      END;
	 
-- Added by Havish Kasina as per Version 1.48	 
	 BEGIN
     xx_write_to_log (lc_filehandle,'Start of update for iEXP instance specific steps...'||CHR(10));
     ------------------------------------------------------------------------------------
     -- Added  for iEXP_IS_01
     ------------------------------------------------------------------------------------
		 BEGIN
		 -------------------------------------------------------
		   -- iEXP_IS_01 - Update for WF_MESSAGES_TL 
		 -------------------------------------------------------
				  lc_identifier          := 'iEXP_IS_01';
				  lc_object_type         := 'Standard Table';
				  lc_object_name         := 'WF_MESSAGES_TL';
				  lc_action              := 'Update html_body';
				  ld_start_date_time     := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

				  ld_end_date_time       := NULL;
				  lc_exception_message   := NULL;
				  lc_result              := NULL;
				  lc_status              := NULL;
				  ln_count               := 0;

				  xx_write_to_log (lc_filehandle,'Start of update, for iEXP_IS_01');

				  UPDATE wf_messages_tl wm
					 SET wm.html_body=replace(wm.html_body,'gsiprdgb',gc_8_char_instance_name_lower)
				   WHERE wm.type = 'WFMAIL'
					 AND wm.name = 'VIEW_FROMUI';

				  ln_count := SQL%rowcount;

				  xx_write_to_log (lc_filehandle,'No of rows updated for iEXP_IS_01 is: '||SQL%ROWCOUNT);
				  COMMIT;

				  lc_status        := 'Success'; 
				  lc_result        := 'Updated: '||ln_count||' rows';
				  ld_end_date_time := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');

				  xx_write_to_file(p_filehandle_csv     => lc_filehandle_csv
								  ,p_identifier         => lc_identifier
								  ,p_status             => lc_status
								  ,p_object_type        => lc_object_type
								  ,p_object_name        => lc_object_name
								  ,p_action             => lc_action
								  ,p_result             => lc_result
								  ,p_start_date_time    => ld_start_date_time
								  ,p_end_date_time      => ld_end_date_time
								  ,p_exception_message  => lc_exception_message);

			   EXCEPTION 
				  WHEN OTHERS THEN
				  xx_write_to_log (lc_filehandle,'Error encountered during iEXP_IS_01: '||SQLERRM);
				  ROLLBACK;
				  lc_status              := 'ERROR'; 
				  lc_result              := 'Unable to update transalation';   
				  ld_end_date_time       := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI:SS');
				  lc_exception_message   := 'Error encountered during iEXP_IS_01: '||SQLERRM;

				  xx_write_to_file(p_filehandle_csv      => lc_filehandle_csv
								   ,p_identifier         => lc_identifier
								   ,p_status             => lc_status
								   ,p_object_type        => lc_object_type
								   ,p_object_name        => lc_object_name
								   ,p_action             => lc_action
								   ,p_result             => lc_result
								   ,p_start_date_time    => ld_start_date_time
								   ,p_end_date_time      => ld_end_date_time
								   ,p_exception_message  => lc_exception_message);
			   END;
		   
	  EXCEPTION
           WHEN OTHERS THEN
           xx_write_to_log (lc_filehandle,'Error while updating, for iREC instance specific steps '||SQLERRM||CHR(10));
      END;
		   
     ELSE
         xx_write_to_log (lc_filehandle,' Not supposed to be executed in Production Instances : '||lc_instance_name);
   END IF;

     UTL_FILE.FCLOSE(lc_filehandle_csv);
     UTL_FILE.FCLOSE(lc_filehandle);
  EXCEPTION 
     WHEN UTL_FILE.INVALID_PATH THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20051, 'Invalid Path');
     WHEN UTL_FILE.INVALID_MODE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20052, 'Invalid Mode');
     WHEN UTL_FILE.INTERNAL_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20053, 'Internal Error');
     WHEN UTL_FILE.INVALID_OPERATION THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20054, 'Invalid Operation');
     WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20055, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR(-20056, 'Invalid Operation');
     WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE ('Error while writing the logs for instance specific updates into the UTL file'); -- Commented by Havish Kasina as per Version 1.17
		--Added by Havish Kasina as per Version 1.17
		ln_err_num := SQLCODE;
        lc_err_msg := SQLERRM;
        DBMS_OUTPUT.put_line ('WHEN OTHERS EXCEPTION (instance specific): '||ln_err_num ||': '|| lc_err_msg);
        xx_write_to_log (lc_filehandle,'WHEN OTHERS EXCEPTION (instance specific): '||ln_err_num ||': '|| lc_err_msg);
		-- End of Adding changes by Havish Kasina as per Version 1.17
  END xx_update_inst_specific; 

  PROCEDURE  xx_update_all
  AS
  -- +===================================================================+
  -- | Name  : xx_update_all                                             |
  -- | Description     : The xx_update_all procedure performs all updates|
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  BEGIN
  -----------------------------------------------------
  -- Calling non-instance specific update procedure    
  -----------------------------------------------------
  xx_update_non_inst_specific;

  -----------------------------------------------------
  -- Calling non-instance specific update procedure    
  -----------------------------------------------------
  xx_update_inst_specific;

     DBMS_OUTPUT.PUT_LINE('Email the above listed files to '||gc_email_address);

  EXCEPTION
     WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Error while calling instance and non-instance specific updates');
  END;


END XXOD_EBS_POST_CLONE_PKG;
/
SHOW ERRORS;
