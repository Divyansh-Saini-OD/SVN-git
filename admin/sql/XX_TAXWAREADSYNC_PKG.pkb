SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY XX_TAXWAREADSYNC_PKG
AS
  -- +=====================================================================================================+
  -- |                       Office Depot                                                                  |
  -- +=====================================================================================================+
  -- | Name       : XX_TAXWAREADSYNC_PKG.pkb                                                               |
  -- | Description: OD: EBS and Taxware AD Users Sync Program                                                          |
  -- |                                                                                                     |
  -- |                                                                                                     |
  -- |Change Record                                                                                        |
  -- |==============                                                                                       |
  -- |Version  Date         Authors            Remarks                                                     |
  -- |=======  ===========  ===============    ============================                                |
  -- |1.0      29-JAN-2018  Visu P             Initial version                                             |
  -- |1.1      07-FEB-2018  Visu P             Modified as per Pramod suggestions                          |
  -- |                                          a)For Active Lookup values from custom                     |
  -- |                                              FND Lookup XX_EBS_TAXWARE_USERS                        |
  -- |                                          b)user_id column used to update Taxware                    |
  -- |                                              custome table                                          |
  -- |                                          c)No Data Found Exception while looking                    |
  -- |                                            for Taxware users in EBS and relevant                    |
  -- |                                              log message.                                           |
  -- |                                          d)New Translation used to send                             |
  -- |                                              email notifications                                    |
  -- |1.2      08-FEB-2018  M K Pramod         a.Modified to deactivate user in Taxware if does not        |
  -- |                                                                               exists in EBS.        |
  -- |                                         b. Added NVL and Trunc on end_Date to identify Inactive user|
  -- |                                         c. Updated the Output Messages with Header information      |
  -- |                                         d. Modified to get user_f_name and user_l_name from Taxware |
  -- |1.3      09-FEB-2018  Visu P             Modified DB Link logic to get it from Translation instead of|
  -- |                                           profile as suggested by Digamber/Pramod                   |
  -- |1.4      12-FEB-2018  Visu P             Added enabled flag condition for fnd lookup                 |
  -- |1.5      12-FEB-2018  Visu P             Added warning condition if DB Link does not exist in system |
  -- +=====================================================================================================+
  /* ---------------------------------------------------------------------
  |  PROCEDURE                                                            |
  |       xx_ebs_ad_sync                                                  |
  |                                                                       |
  |  DESCRIPTION                                                          |
  |       Sync Taxware AD users with EBS users                            |
  |                                                                       |
  --------------------------------------------------------------------- */
PROCEDURE xx_ebs_ad_sync(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER )
IS
  --
  lc_db_link              VARCHAR2(500);
  ld_end_date             DATE;
  lc_instance             VARCHAR2(500);
  ln_count                NUMBER:=0;
  lc_smtp_server          XX_FIN_TRANSLATEVALUES.TARGET_VALUE9%TYPE;
  ln_smtp_server_port     PLS_INTEGER;
  lc_from_name            XX_FIN_TRANSLATEVALUES.TARGET_VALUE2%TYPE;
  lc_recepients           XX_FIN_TRANSLATEVALUES.TARGET_VALUE3%TYPE;
  lc_cc                   XX_FIN_TRANSLATEVALUES.TARGET_VALUE4%TYPE;
  lc_bcc                  XX_FIN_TRANSLATEVALUES.TARGET_VALUE5%TYPE;
  lc_subject              XX_FIN_TRANSLATEVALUES.TARGET_VALUE7%TYPE;
  lc_subject_prefix       XX_FIN_TRANSLATEVALUES.TARGET_VALUE6%TYPE;
  lc_body                 XX_FIN_TRANSLATEVALUES.TARGET_VALUE8%TYPE;
  lc_conn                 UTL_SMTP.connection;
  lc_message              VARCHAR2(200);
  lc_error                VARCHAR2(1);
  ln_err_count            NUMBER:=0;
  ln_success              NUMBER:=0;
  ln_unchanged            NUMBER:=0;
  lc_ebs_ad               SYS_REFCURSOR;
  lc_statement            VARCHAR2(1000);
  lc_statement2           VARCHAR2(1000);
  ln_request_id           NUMBER;
  lc_email_address        VARCHAR2 (240);
  ln_main_prog_req_id     NUMBER       := fnd_global.conc_request_id;
  lc_source_code          VARCHAR2(100):='TAXWARE_AD_EBS';
  ln_tab_count            NUMBER       :=0;
  lcu_aops_to_temp        SYS_REFCURSOR;
  lc_user_name            VARCHAR2(500);
  lc_user_message         VARCHAR2(500);
  lc_taxware_user_flag    VARCHAR2(1);
  --
TYPE taxware_data_record
IS
  RECORD
  (
    lr_login_name  VARCHAR2(1000),
    lr_user_lock   VARCHAR2(1),
    lr_user_id     VARCHAR2(1000),
    lr_user_F_name VARCHAR2(1000),
    lr_user_L_name VARCHAR2(1000) );
    lc_db_link_not_exists VARCHAR2(1):= 'N';
TYPE taxware_data_table
IS
  TABLE OF taxware_data_record INDEX BY BINARY_INTEGER;
  lt_ad_data_tab taxware_data_table;
  --
TYPE taxware_users_updated
IS
  RECORD
  (
    lr_user_name  VARCHAR2(1000),
    lr_login_name VARCHAR2(1000),
    lr_message    VARCHAR2(500));
TYPE taxware_users_table
IS
  TABLE OF taxware_users_updated INDEX BY BINARY_INTEGER;
  lt_ad_users_tab taxware_users_table;
  --
BEGIN
  fnd_file.put_line(fnd_file.log, 'Taxware AD Sync program start:');
  fnd_file.put_line(fnd_file.log, '----------------------------------------------');
  -- Get the DB Link name from profile
  BEGIN
    --lc_db_link := FND_PROFILE.VALUE('XX_TWR_AD_DB_LINK'); 09/02/2018
    SELECT XFTV.target_value2
    INTO lc_db_link
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1    = 'TAXWARE_AD_EBS'
    AND XFTD.translation_name = 'OD_TAXWARE_AD_EBS' --07/02/2018
    AND XFTV.enabled_flag     = 'Y'
    AND XFTD.enabled_flag     = 'Y';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    fnd_file.put_line(fnd_file.log, 'DB Link is not configured in the custom translation ');
   WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Error in deriving EBS Taxware DB Link name '||SQLERRM);
  END;
  --
  fnd_file.put_line(fnd_file.log,'DB Link Name: '||lc_db_link);
  --
  BEGIN -- 12/02/2018
    SELECT db_link INTO lc_db_link FROM all_db_links WHERE db_link = lc_db_link;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
     fnd_file.put_line(fnd_file.log,'DB Link Name: '||lc_db_link||' does not exist in the system');
     lc_db_link_not_exists := 'Y';
  -- The defined DB Link does not exist in the system, show warning and come out
     x_retcode := 1; -- Warning
  WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log,'DB Link Name: '||lc_db_link||' exception '||SQLERRM);
     lc_db_link_not_exists := 'Y';
     x_retcode := 1; -- Warning
  END;
  
  IF lc_db_link_not_exists = 'N' 
  THEN
  -- ==========================================================================
  -- 07/02/2018
  lc_statement := 'SELECT uf.login_name, uf.user_lock, uf.user_id,uf.user_f_name,uf.user_l_name FROM user_info@'||lc_db_link||' '||'uf WHERE 
UPPER(uf.login_name) NOT IN (SELECT flv.lookup_code                                    
FROM fnd_lookup_values flv WHERE flv.lookup_type = '||'''XX_EBS_TAXWARE_USERS'''||'            
AND flv.enabled_flag = '||'''Y'''||' AND (SYSDATE            
BETWEEN flv.start_date_active AND NVL(flv.end_date_active,SYSDATE+1))) AND NVL(user_lock,'||'''N'''||') != '||'''Y'''; --12/02/2018
  fnd_file.put_line(fnd_file.log,'string built:'||lc_statement);
  OPEN lc_ebs_ad FOR lc_statement;
  LOOP
  fnd_file.put_line(fnd_file.log, 'statement opened');
  FETCH lc_ebs_ad BULK COLLECT INTO lt_ad_data_tab LIMIT 10000;
  EXIT
  WHEN lt_ad_data_tab.COUNT=0;
  fnd_file.put_line(fnd_file.log, 'before for loop');
  FOR i IN 1..lt_ad_data_tab.COUNT
  LOOP
  ld_end_date := NULL;
  ln_count    := ln_count+1;
  lc_error    := 'N';
  lc_taxware_user_flag:='N';
  lc_user_name := NULL;
  lc_user_message:=Null;
  --
  fnd_file.put_line(fnd_file.log, 'Processing Taxware Login Name:'||lt_ad_data_tab(i).lr_login_name);
  --
  BEGIN
  SELECT end_date, user_name
  INTO ld_end_date, lc_user_name
  FROM FND_USER
  WHERE USER_NAME = SUBSTR(UPPER(lt_ad_data_tab(i).lr_login_name),2);
  if ld_end_date is not null then
  lc_user_message:='User deactivated in EBS on Date:'||to_char(ld_end_date,'DD-MON-YYYY');
  end if;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN -- 07/02/2018
  fnd_file.put_line(fnd_file.log, 'Taxware User does not exist in EBS, So deactivate the Taxware user-'||lt_ad_data_tab(i).lr_login_name );
  --lc_error := 'Y';
  lc_taxware_user_flag:='Y';
  lc_user_message:='User do not exist in EBS';
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error during deriving End_date for EBS User '||SQLERRM);
  lc_error := 'Y';
  END;
  --
  IF ((trunc(NVL(ld_end_date,sysdate+1)) <= trunc(SYSDATE) or lc_taxware_user_flag='Y' ) AND (lc_error = 'N'))THEN
  -- User is end dated in EBS, so update the information in Taxware system
  BEGIN --07/02/2018
  --lc_statement2 := 'UPDATE user_info@'||lc_db_link||' SET user_lock   = '||'''Y'''||' WHERE login_name ='||''''||lt_ad_data_tab(i).lr_user_name||'''';
  lc_statement2 := 'UPDATE user_info@'||lc_db_link||' SET user_lock   = '||'''Y'''||' WHERE user_id ='||''''||lt_ad_data_tab(i).lr_user_id||'''';
  fnd_file.put_line(fnd_file.log, lc_statement2);
  --EXECUTE IMMEDIATE ('UPDATE '||lc_db_link||' SET user_lock   = '||'''Y'''||' WHERE login_name ='||'||lt_ad_data_tab(i).lr_user_name||''');
  EXECUTE IMMEDIATE lc_statement2;
  ln_success := ln_success+1;
  ln_tab_count                               := ln_tab_count+1;
  lt_ad_users_tab(ln_tab_count).lr_login_name := lt_ad_data_tab(i).lr_login_name;
  lt_ad_users_tab(ln_tab_count).lr_user_name := lt_ad_data_tab(i).lr_user_F_name||' '||lt_ad_data_tab(i).lr_user_l_name;
  lt_ad_users_tab(ln_tab_count).lr_message := lc_user_message;
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error occured during AD table update for Taxware user'||SQLERRM);
  lc_error := 'Y';
  END;
  ELSIF ((ld_end_date IS NULL) AND (lc_error = 'N'))THEN
  fnd_file.put_line(fnd_file.log, 'User is still active as on today, no need to update AD table '||SQLERRM);
  ln_unchanged := ln_unchanged+1;
  END IF;
  IF lc_error     = 'Y' THEN
  ln_err_count := ln_err_count +1;
  END IF;
  END LOOP;
  fnd_file.put_line(fnd_file.log, 'after for loop');
  END LOOP;
  fnd_file.put_line(fnd_file.log, 'after end loop');
  COMMIT;
  CLOSE lc_ebs_ad ;
  -- ==========================================================================
  -- Send email to admin following AD users are deactivated in Taxware system to make it sync with Oracle EBS
  IF ln_success >0 THEN
    -- user is updated in AD hence send an email
    BEGIN
      fnd_file.put_line (fnd_file.LOG, 'Submitting the Concurrent Request Emailer program   ' );
      BEGIN
        SELECT XFTV.target_value1
        INTO lc_email_address
        FROM xx_fin_translatedefinition XFTD ,
          xx_fin_translatevalues XFTV
        WHERE XFTV.translate_id = XFTD.translate_id
        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND XFTV.source_value1    = lc_source_code
        AND XFTD.translation_name = 'OD_TAXWARE_AD_EBS' --07/02/2018
        AND XFTV.enabled_flag     = 'Y'
        AND XFTD.enabled_flag     = 'Y';
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.log, 'Exception translation value fetch: '||SQLERRM);
      END;
      -- Derive Instance Name
      BEGIN
        SELECT instance_name INTO lc_instance FROM V$INSTANCE;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Error fetching instance name :'||SQLERRM);
      END;
      fnd_file.put_line(fnd_file.log,'Instance Name:'||lc_instance);
      lc_subject    :='Taxware AD Sync program Notice Sent By Office Depot ';
      ln_request_id := fnd_request.submit_request ('xxfin', 'XXODROEMAILER', NULL, NULL, FALSE, NULL, lc_email_address, lc_instance||':'||'EBS and Taxware AD Users Sync Program Notice Sent By Office Depot', '', 'N', ln_main_prog_req_id, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '' );
      --ln_request_id := fnd_request.submit_request ('xxfin', 'XXODROEMAILER', NULL, NULL, FALSE, NULL, lc_email_address, lc_instance||':'||lc_subject, 'See the email for further details.', 'N', ln_main_prog_req_id, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '' );
      --CHR (0)
      COMMIT;
      IF ln_request_id = 0 THEN
        fnd_file.put_line (fnd_file.LOG, 'The Concurrent Request Emailer Program Has Failed.' );
      ELSE
        fnd_file.put_line (fnd_file.LOG, 'The Concurrent Request Emailer Program Has Been Submitted.  Request ID is   ' || ln_request_id );
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Exception sending email:'||SQLERRM);
    END;
  END IF; -- ln_success end if
  --
  -- ==========================================================================
  fnd_file.put_line(fnd_file.log, 'Total No.Of Users            :'||ln_count);
  fnd_file.put_line(fnd_file.log, 'Total No.Of Users Updated    :'||ln_success);
  fnd_file.put_line(fnd_file.log, 'Total No.Of Users not Updated:'||ln_unchanged);
  fnd_file.put_line(fnd_file.log, 'Total No.Of Users in Error   :'||ln_err_count);
  fnd_file.put_line(fnd_file.log, '----------------------------------------------');
  --
  IF ln_count = 0 THEN
    fnd_file.put_line(fnd_file.output, '                                                  OD: EBS and Taxware AD Users Sync Program');
    fnd_file.put_line(fnd_file.output, '                                                ---------------------------------------------');
    fnd_file.put_line(fnd_file.output, ' ');
    fnd_file.put_line(fnd_file.output, 'There are no eligible Taxware Users to be deactivated.');
  ELSIF (ln_success =0) AND (ln_count > 0) THEN
    fnd_file.put_line(fnd_file.output, '                                                  OD: EBS and Taxware AD Users Sync Program');
    fnd_file.put_line(fnd_file.output, '                                                ---------------------------------------------');
    fnd_file.put_line(fnd_file.output, ' ');
    fnd_file.put_line(fnd_file.output, 'There are no Taxware Users to be deactivated.');
  ELSIF (ln_success >0) AND (ln_count > 0) THEN
    fnd_file.put_line(fnd_file.output, '                                                  OD: EBS and Taxware AD Users Sync Program');
    fnd_file.put_line(fnd_file.output, '                                                ----------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, ' ');
    fnd_file.put_line(fnd_file.output, 'Admins,');
    fnd_file.put_line(fnd_file.output, '                                                                             ');
    fnd_file.put_line(fnd_file.output, 'Following user(s) are deactivated in Taxware System:');
    fnd_file.put_line(fnd_file.output, '                                                                             ');
    fnd_file.put_line(fnd_file.output, '  Sr.No.        '||RPAD('Login Name',25)|| RPAD('User Name',30)||'Message');
    fnd_file.put_line(fnd_file.output, '-----------------------------------------------------------------------------------------');
    FOR i IN 1..lt_ad_users_tab.COUNT
    LOOP
      fnd_file.put_line(fnd_file.output, '      '||i||'.'||'           '||RPAD(lt_ad_users_tab(i).lr_login_name,25)||''||RPAD(lt_ad_users_tab(i).lr_user_name,30)||''||lt_ad_users_tab(i).lr_message); --07/02/2018
    END LOOP;
    fnd_file.put_line(fnd_file.output, '                                                                             ');
    fnd_file.put_line(fnd_file.output, 'Thank You.');-- 07/02/2018
  END IF;
  END IF; -- DB Link does not exist in the system end if
  fnd_file.put_line(fnd_file.log, '----------------------------------');
  fnd_file.put_line(fnd_file.log, 'Taxware AD Sync program end:');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Entered exception xx_ebs_ad_sync procedure:'||SQLERRM);
  x_retcode := 1; -- warning message
  --
END xx_ebs_ad_sync;
-- ----------------------------------------------------------------------------
END XX_TAXWAREADSYNC_PKG;

/

SHOW ERRORS;