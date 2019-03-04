create or replace PACKAGE BODY xx_cdh_aops_ab_pkg
AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- +===============================================================================+
-- | Name  :  XX_CDH_AOPS_AB_PKG                                                   |
-- |                                                                               |
-- | Description: Package to verify mismatch in AOPS Load and Oracle DB for AB and |
-- |              generate OD: CRM AOPS to Oracle AB Mismatch Report which will be |
-- |              send to AOPS for customer data sync                              |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date        Author           Remarks                                 |
-- |=======   ==========  =============    ========================================|
-- |1.0       16-Sep-16   Poonam Gupta     Initial draft version                   |
-- |                                       for Defect #37159                       |
-- | 1.2      04-May-18   Vivek Kumar	   Defect#45176 Extract the customers has  |
-- |                                       active BIll doc.                        |
-- | 1.3      03-JAN-19   BIAS             INSTANCE_NAME is replaced with DB_NAME  |
-- |                                       for OCI Migration                       |
-- +===============================================================================+
   g_db_link   VARCHAR2 (2000);

-- +===============================================================================+
-- | Name       : wr_log                                                           |
-- |                                                                               |
-- | Description: This procedure is used to display detailed                       |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_msg                                                            |
-- |                                                                               |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE wr_log (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
   END wr_log;

-- +===============================================================================+
-- | Name       : wr_out                                                           |
-- |                                                                               |
-- | Description: This procedure is used to display detailed                       |
-- |                     messages to output file                                   |
-- |                                                                               |
-- | Parameters : p_msg                                                            |
-- |                                                                               |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE wr_out (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   END wr_out;

-- +===============================================================================+
-- | Name       : copy_file                                                        |
-- |                                                                               |
-- | Description: This procedure is used to copy the AOPS file from FTP location to|
-- |              to the inbound location                              |
-- |                                                                               |
-- | Parameters : p_load_aops                                                      |
-- |                                                                               |
-- | Returns    : x_retcode                                                        |
-- +===============================================================================+
   PROCEDURE copy_file (
      p_sourcepath    IN   VARCHAR2,
      p_destpath      IN   VARCHAR2,
      p_archivepath   IN   VARCHAR2
   )
   IS
      ln_req_id        NUMBER;
      lc_sourcepath    VARCHAR2 (1000);
      lc_destpath      VARCHAR2 (1000);
      lc_archivepath   VARCHAR2 (1000);
      lb_result        BOOLEAN;
      lc_phase         VARCHAR2 (1000);
      lc_status        VARCHAR2 (1000);
      lc_dev_phase     VARCHAR2 (1000);
      lc_dev_status    VARCHAR2 (1000);
      lc_message       VARCHAR2 (1000);
      lc_token         VARCHAR2 (4000);
      ln_request_id    NUMBER          DEFAULT 0;
   BEGIN
      ln_request_id := fnd_global.conc_request_id ();
      lc_sourcepath := p_sourcepath;
      lc_destpath := p_destpath;
      lc_archivepath := p_archivepath;
      ln_req_id :=
                  fnd_request.submit_request ('XXFIN'
                         ,'XXCOMFILCOPY','',''
                         ,FALSE ,lc_sourcepath
                         ,lc_destpath,'','','Y',lc_archivepath,'','','',
                         '','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,''
                         );
      COMMIT;
      lb_result :=
         fnd_concurrent.wait_for_request (ln_req_id,
                                          1,
                                          0,
                                          lc_phase,
                                          lc_status,
                                          lc_dev_phase,
                                          lc_dev_status,
                                          lc_message
                                         );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXCRM', 'XX_CRM_EXP_OTHER_ERROR_MSG');
         lc_token := SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
         fnd_message.set_token ('MESSAGE', lc_token);
         lc_message := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG,
                            'An error occured. Details : ' || lc_token
                           );
         fnd_file.put_line (fnd_file.LOG, ' ');
   END copy_file;

-- +===============================================================================+
-- | Name       : load_aops                                                        |
-- |                                                                               |
-- | Description: This procedure is used to load the data contained in AOPS file   |
-- |              to the staging table xxcrm.xxod_cdh_ab_cust_stg                  |
-- |                                                                               |
-- | Parameters : p_load_aops                                                      |
-- |                                                                               |
-- | Returns    : x_retcode                                                        |
-- +===============================================================================+
   PROCEDURE load_aops (p_load_aops IN VARCHAR2, x_retcode OUT NUMBER)
   IS
      -- Variable declaration
      lc_filehandle          UTL_FILE.file_type;
      lc_message             VARCHAR2 (32767);
      lc_delimiter           VARCHAR2 (3);
      lc_email               VARCHAR2 (400);
      ln_total_length        NUMBER;
      ln_total_comma         NUMBER             := 0;
      ln_record_comma        NUMBER;
      ln_total_records       NUMBER             := 0;
      ln_count               NUMBER             := 0;
      lc_file_name           VARCHAR2 (200);
      lc_filein              VARCHAR2 (200);
      lc_file_in             VARCHAR2 (400);
      lc_file_path           VARCHAR2 (400);
      lc_archive_path        VARCHAR2 (400);
      lc_directory           VARCHAR2 (200);
      lc_archive             VARCHAR2 (200);
      ln_linesize            NUMBER;
      lc_filepath            VARCHAR2 (200);
      lc_mode                VARCHAR2 (2)       := 'r';
      ln_err_no              NUMBER             := 1;
      ln_ftp_request_id      NUMBER;
      ln_retcode             NUMBER;
      lc_first_column        VARCHAR2 (200);
      v_sqlerrm              VARCHAR2 (2000);
      lc_target_filepath     VARCHAR2 (200);
      ln_trailer_rec_found   NUMBER;
      ln_first_comma         NUMBER;
      ln_first_colon         NUMBER;
      ln_rec_count_check     NUMBER;
      --Table type declaration
      --TYPE LT_FILE_NAMES IS TABLE OF VARCHAR2 (4000);
      --file_names_tbl_type    lt_file_names;
      lc_sourcepath          VARCHAR2 (200);
      lc_destpath            VARCHAR2 (200);
      lc_aops_number         VARCHAR2 (10);
      lc_credit_flag         VARCHAR2 (5);
      lc_account_type        VARCHAR2 (20);
      lc_account_name        VARCHAR2 (240);
      lc_account_status      VARCHAR2 (5);
      i                      NUMBER;
      p_delflag              VARCHAR2 (2);
   BEGIN
      wr_log (   'Start of loading AOPS data '
              || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
             );
      wr_log ('Getting Translation Values ');

      BEGIN
         SELECT xftv.target_value2, xftv.target_value4, xftv.target_value5,
                xftv.target_value7, xftv.target_value8, xftv.target_value11,
                xftv.target_value12, xftv.target_value9
           INTO lc_delimiter, lc_file_name, lc_email,
                ln_linesize, lc_filepath, lc_filein,
                lc_archive, lc_directory
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'XX_CDH_AOPS_CUST_PROF'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            wr_log ('Unable to retrieve Translation setup values ');
      END;

      BEGIN
         wr_log ('Setting File Paths ');
         lc_file_in := lc_filein || '/' || lc_file_name || '.TXT';
         -- FROM .CSV TO .TXT
         lc_file_path := lc_filepath || '/' || lc_file_name || '.TXT';
         -- FROM .CSV TO .TXT
         lc_archive_path := lc_archive || '/';
         wr_log ('Copying file to inbound/Archiving..');
         copy_file (p_sourcepath       => lc_file_in,
                    p_destpath         => lc_file_path,
                    p_archivepath      => lc_archive_path
                   );
      EXCEPTION
         WHEN OTHERS
         THEN
            wr_log ('Error in Copy/Archive File : ' || SQLERRM);
            x_retcode := 2;
      END;

      BEGIN
         wr_log ('Opening File');

         BEGIN
            fnd_file.put_line (fnd_file.LOG, 'lc_filepath: ' || lc_directory);
            fnd_file.put_line (fnd_file.LOG,
                               'lc_file_name: ' || lc_file_name);
            lc_file_name := lc_file_name || '.TXT';      -- FROM .CSV TO .TXT
            --
            lc_filehandle :=
               UTL_FILE.fopen (lc_directory,
                               lc_file_name,
                               lc_mode,
                               ln_linesize
                              );
            --
            ln_total_records := 0;
         EXCEPTION
            WHEN OTHERS
            THEN
               wr_log ('Error in Opening File : ' || SQLERRM);
               x_retcode := 2;
         END;

         wr_log ('Before truncating Custom interface table ');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxod_cdh_ab_cust_stg';

         wr_log (   'Start of Inserting file data into staging table'
                 || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                );

         LOOP
            BEGIN
               UTL_FILE.get_line (lc_filehandle, lc_message);

               -- fnd_file.put_line (fnd_file.LOG, lc_message);
               BEGIN
                  -- wr_log ('lc_message :' || lc_message);

                  --lc_message := REPLACE (lc_message, '",', '`');
                  SELECT REGEXP_SUBSTR (lc_message,'[^|]+|[^|]+|[^|]+|[^|]+|[^|]+', 1, 1),
                         REGEXP_SUBSTR (lc_message,'[^|]+|[^|]+|[^|]+|[^|]+',1 ,2),
                         REGEXP_SUBSTR (lc_message, '[^|]+|[^|]+|[^|]+', 1, 3),
                         REGEXP_SUBSTR (lc_message, '[^|]+|[^|]+', 1, 4),
                         SUBSTR (REGEXP_SUBSTR (lc_message, '[^|]+$', 1, 1),1,1)
                    INTO lc_aops_number,
                         lc_credit_flag,
                         lc_account_type,
                         lc_account_name,
                         lc_account_status
                    FROM DUAL;

                  --wr_log ('DEBUG1 - Message Splitted to column values '||lc_aops_number);
                  INSERT INTO xxod_cdh_ab_cust_stg
                              (aops_number, aops_credit_flag,
                               account_type, account_name,
                               account_status, ebs_credit_flag,
                               creation_date, created_by, last_updated_by,
                               last_update_date, request_id
                              )
                       VALUES (lc_aops_number, lc_credit_flag,
                               lc_account_type, lc_account_name,
                               lc_account_status, 'Y',
                               SYSDATE, -1, -1,
                               SYSDATE, fnd_global.conc_request_id
                              );

                  --wr_log ('DEBUG2 - Insert executed'||'lc_aops_number :' || lc_aops_number||'error :'||sqlerrm);
                  IF SQL%ROWCOUNT > 0
                  THEN
                     ln_total_records := ln_total_records + 1;
                  END IF;

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     wr_log (SQLERRM);
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  wr_log (SQLERRM);
                  EXIT;
            END;
         END LOOP;
      END;

      UTL_FILE.fclose (lc_filehandle);
      wr_log (   'Total Records inserted into Staging Table : '
              || ln_total_records
             );
      wr_log ('Loop ended here');
--      UTL_FILE.fclose (lc_filehandle);
      --Gathering table stats
      wr_log (   'End of Inserting file data into staging table'
              || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
             );
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         -- fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         x_retcode := 2;
      WHEN UTL_FILE.invalid_mode
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.invalid_operation
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.read_error
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.write_error
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN UTL_FILE.internal_error
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
      WHEN OTHERS
      THEN
         wr_log ('Error:' || SQLCODE || '-' || SQLERRM);
         x_retcode := 2;
   --End of read_file_ins_int procedure
   END load_aops;

-- +===============================================================================+
-- | Name       : update_cust                                                      |
-- |                                                                               |
-- | Description: This procedure is used to update the customer related values in  |
-- |              the staging table xxcrm.xxod_cdh_ab_cust_stg                        |
-- |                                                                               |
-- | Parameters : p_load_aops                                                      |
-- |                                                                               |
-- | Returns    : x_retcode                                                        |
-- +===============================================================================+
   PROCEDURE update_cust (p_load_aops IN VARCHAR2, x_retcode OUT NUMBER)
   AS
      lc_db_name   VARCHAR2 (100);
      ln_limit     NUMBER            := 1000;
      lc_query     VARCHAR2 (2000);

      TYPE lr_rec_type IS RECORD (
         aops_number        VARCHAR2 (10),
         account_name       VARCHAR2 (240),
         ebs_credit_flag    VARCHAR2 (1),
         aops_credit_flag   VARCHAR2 (1),
		 missing_bill       VARCHAR2(1)
      );

      --Table type declaration
      TYPE lt_rec_type IS TABLE OF lr_rec_type;

      lr_rec       lt_rec_type;
      ln_count     NUMBER;

      -- l_tabcount   NUMBER            := 0;
      -- lc_query2    VARCHAR2 (1000);
      TYPE r_c_aops_cur_type IS REF CURSOR;

      c_aops_cur   r_c_aops_cur_type;
   BEGIN
      wr_log (   'Start Validating  '
              || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
             );

      IF p_load_aops = 'Y'
      THEN
         lc_query :=
              'SELECT aops_number   ,
          account_name   ,
          ebs_credit_flag  ,
          aops_credit_flag ,''N'' MISSING_BILL
		  FROM  xxod_cdh_ab_cust_stg ap'
            || ' WHERE 1=1'
            || ' AND ap.account_type = ''CONTRACT'' '
            || ' AND ap.account_status = ''A'' '
            || ' AND  EXISTS (
          SELECT 1
            FROM hz_cust_accounts hc, hz_customer_profiles hcp
           WHERE hc.cust_account_id = hcp.cust_account_id
             AND hc.orig_system_reference = lpad(ap.aops_number,8,0) || ''-00001-A0''
             AND hcp.site_use_id IS NULL
             AND (profile_class_id = 0 OR standard_terms = 5))
			  union                                                           -----Added below union For Defect#45176 -------
			 SELECT aops_number   ,
          ap.account_name   ,
		  ''N''  ,
		  aops_credit_flag ,''Y'' MISSING_BILL
          FROM  xxod_cdh_ab_cust_stg ap,hz_Cust_accounts hc
            WHERE 1=1
                         AND ap.account_type = ''CONTRACT''
			 AND ap.account_status = ''A''
       and hc.orig_system_reference = lpad(ap.aops_number,8,0) || ''-00001-A0''
             and not exists (select ''x'' from XX_CDH_CUST_ACCT_EXT_B XB
 WHERE 1               =1
AND xb.cust_account_id=hc.cust_account_id
AND Attr_group_id     in (166)
and C_ext_attr2=''Y''
AND SYSDATE BETWEEN d_ext_attr1 AND NVL (d_ext_attr2, SYSDATE + 1))';
         wr_log ('Query used : ' || lc_query);

         BEGIN
            UPDATE xxod_cdh_ab_cust_stg xs
               SET ebs_credit_flag = 'Y';

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               wr_log ('Error in Updating ebs_credit_flag  ' || SQLERRM);
         END;

         OPEN c_aops_cur FOR lc_query;

         LOOP
            FETCH c_aops_cur
            BULK COLLECT INTO lr_rec LIMIT ln_limit;

            EXIT WHEN lr_rec.COUNT < 1;

            FOR i IN 1 .. lr_rec.COUNT
            LOOP
               wr_log ('inside loop  ');

               UPDATE xxod_cdh_ab_cust_stg xs
                  SET ebs_credit_flag = decode(lr_rec (i).missing_bill,'Y','X','N'),
                      last_update_date = SYSDATE
                WHERE xs.aops_number = lr_rec (i).aops_number;

               -- wr_log ('Updated ' || SQL%ROWCOUNT);
               --wr_log ('Aops Number ' || lr_rec (i).aops_number);
               COMMIT;
               -- exception when others then
               wr_log ('Error ' || SQLERRM);
            END LOOP;
         END LOOP;
      ELSE
         lc_query :=
               'SELECT aops_number ,account_name,ebs_credit_flag,aops_Credit_flag,''N'' MISSING_BILL
			   FROM  xxod_cdh_ab_cust_stg ap'
            || ' WHERE 1=1'
            || ' AND ebs_credit_flag=''N'' '
            || ' AND ap.account_type = ''CONTRACT'' '
            || ' AND ap.account_status = ''A'' '
            || ' AND  EXISTS (
           SELECT 1
             FROM hz_cust_accounts hc, hz_customer_profiles hcp
            WHERE hc.cust_account_id = hcp.cust_account_id
              AND hc.orig_system_reference = lpad(ap.aops_number,8,0) || ''-00001-A0''
              AND hcp.site_use_id IS NULL
              AND (profile_class_id <> 0 OR standard_terms <> 5))
			   union                                                   -----Added below union For Defect#45176 -------
			 SELECT aops_number   ,
             ap.account_name   ,
		     ebs_credit_flag  ,
		  aops_credit_flag ,''Y''
          FROM  xxod_cdh_ab_cust_stg ap,hz_Cust_accounts hc
            WHERE 1=1
                         AND ap.account_type = ''CONTRACT''
			 AND ap.account_status = ''A''
       and hc.orig_system_reference = lpad(ap.aops_number,8,0) || ''-00001-A0''
             and not exists (select ''x'' from XX_CDH_CUST_ACCT_EXT_B XB
WHERE 1               =1
AND xb.cust_account_id=hc.cust_account_id
AND Attr_group_id     in (166)
and C_ext_attr2=''Y''
AND SYSDATE BETWEEN d_ext_attr1 AND NVL (d_ext_attr2, SYSDATE + 1))';
         wr_log ('Query used : ' || lc_query);

         OPEN c_aops_cur FOR lc_query;

         LOOP
            FETCH c_aops_cur
            BULK COLLECT INTO lr_rec LIMIT ln_limit;

            EXIT WHEN lr_rec.COUNT < 1;
            FORALL i IN lr_rec.FIRST .. lr_rec.LAST
               UPDATE xxod_cdh_ab_cust_stg xs
                  SET ebs_credit_flag = decode(lr_rec (i).missing_bill,'Y','X','Y'),
                      last_update_date = SYSDATE
                WHERE xs.aops_number = lr_rec (i).aops_number;
            COMMIT;
            -- exception when others then
            wr_log ('Error ' || SQLERRM);
         END LOOP;

         COMMIT;

         CLOSE c_aops_cur;

         x_retcode := 0;
         wr_log ('Completed load_aops procedure successfully');
         wr_log (   'End of Validation '
                 || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log ('Error in Load_aops procedure  :' || SQLERRM);
         x_retcode := 2;
   END update_cust;

-- +===============================================================================+
-- | Name       : print_report                                                     |
-- |                                                                               |
-- | Description: This procedure is used to print report OD: CRM AOPS to Oracle    |
-- |              AB Mismatch Report in the form of    email using the output           |
-- |              generated, which is send to specified email addresses.           |
-- |                                                                               |
-- | Parameters : none                                                               |
-- |                                                                               |
-- | Returns    : x_retcode                                                        |
-- +===============================================================================+
   PROCEDURE print_report (x_retcode OUT NOCOPY NUMBER)
   AS
      lc_instance_name   VARCHAR2 (240);
      lc_email           VARCHAR2 (400);
      lc_delimiter       VARCHAR2 (3);
      lc_file_name       VARCHAR2 (200);
      lc_filepath        VARCHAR2 (200);
      lc_email_address   VARCHAR2 (2000);
      l_extract_date     VARCHAR2 (240);
      lc_email_subject   VARCHAR2 (2000)
                               := 'OD: CRM AOPS to Oracle AB Mismatch Report';
      ln_request_id      NUMBER          := fnd_global.conc_request_id;
      ln_req_id          NUMBER;

      CURSOR get_cust_det
      IS
         SELECT   lpad(x.aops_number,8,0) aops_number, hca.account_name,  DECODE(hcp.standard_terms,5,'N','Y')ebs_credit_flag,
		 (SELECT DECODE(COUNT(1),0,'N','Y')
            FROM XX_CDH_CUST_ACCT_EXT_B XB
            WHERE 1               =1
               AND xb.cust_account_id=hca.cust_account_id
               AND Attr_group_id    IN (166)
               AND C_ext_attr2       ='Y'
               AND SYSDATE BETWEEN d_ext_attr1 AND NVL (d_ext_attr2, SYSDATE + 1)
        )billdoc,RPAD(rt.name,20) payment_term
             FROM xxod_cdh_ab_cust_stg x, hz_cust_accounts hca,hz_customer_profiles hcp,ra_terms rt
            WHERE hca.orig_system_reference = lpad(x.aops_number,8,0) || '-00001-A0'
              AND hca.cust_account_id=hcp.cust_Account_id
              and hcp.site_use_id is null
              and rt.term_id=hcp.standard_terms
              AND NVL (ebs_credit_flag, 'Y') <> 'Y'
              AND x.account_type = 'CONTRACT'
			  ORDER BY 3;
   BEGIN
      BEGIN
         SELECT SYS_CONTEXT ('USERENV', 'DB_NAME')
           INTO lc_instance_name
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_instance_name := NULL;
            wr_log (   'No data found while getting the Instance Name : '
                    || lc_instance_name
                   );
         WHEN OTHERS
         THEN
            lc_instance_name := NULL;
            wr_log (   'Exception while getting the Instance Name : '
                    || lc_instance_name
                   );
      END;

      lc_email_subject := lc_instance_name || ' ' || lc_email_subject;

      BEGIN
         SELECT xftv.target_value5
           INTO lc_email_address
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'XX_CDH_AOPS_CUST_PROF'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';

         wr_log ('Email ID' || lc_email_address);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_email_address := NULL;
            wr_log ('No data found in Email Address  ');
            RAISE;
         WHEN OTHERS
         THEN
            lc_email_address := NULL;
            wr_log ('Error @ Others - Email Address for the run date: ');
            RAISE;
      END;

      BEGIN
         SELECT TO_CHAR (NVL (MAX (creation_date), SYSDATE),
                         'DD-MON-RRRR HH24:MI:SS'
                        )
           INTO l_extract_date
           FROM xxod_cdh_ab_cust_stg;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_extract_date := SYSDATE;
            wr_log ('No Extract Date available : ');
      END;

      fnd_file.put_line
         (fnd_file.output,
          'Office Depot                     OD: CRM AOPS to Oracle AB Mismatch      '
         );
      fnd_file.put_line (fnd_file.output, '     ');
      fnd_file.put_line (fnd_file.output, '     ');
      fnd_file.put_line (fnd_file.output,
                            RPAD ('Instance            :', 25, ' ')
                         || lc_instance_name
                        );
      fnd_file.put_line (fnd_file.output,
                            RPAD ('Date of Run         :', 25, ' ')
                         || l_extract_date
                        );
      -- Added for QC Defect # 23956
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output,
                            'AOPS Customer Number     '
                         || '   '
                         || 'Credit Flag     '
                         || '   '
                         || 'Billdoc     '
                         || '            '
                         || 'Terms      '
                         || '                     '
                         || 'Customer Name  '
                         || '   '
                        );
      fnd_file.put_line (fnd_file.output,
                            '--------------------     '
                         || '   '
                         || '-----------     '
                         || '   '
                         || '------------  '
                         || '          '
                         || '-------------  '
                         || '                 '
                         || '-------------  '
                         || '   '
                        );

      FOR lc_rep IN get_cust_det
      LOOP
         EXIT WHEN get_cust_det%NOTFOUND;
             fnd_file.put_line (fnd_file.output,
                               lc_rep.aops_number
                            || '                     '
                            || lc_rep.ebs_credit_flag
                            || '                 '
                            || lc_rep.billdoc
                            || '                       '
                            || lc_rep.payment_term
                            || '            '
                            || lc_rep.account_name
                            || '   '
                           );




      END LOOP;

      fnd_file.put_line (fnd_file.output,
                         LPAD ('*** End Of Report ***', 60, ' ')
                        );
      wr_log ('Calling FND_REQUEST.SUBMIT_REQUEST for XXODROEMAILER');
      ln_req_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXODROEMAILER',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     'XX_CDH_AOPS_CUST_PROF',
                                     lc_email_address,
                                     lc_email_subject,
                                     NULL,
                                     'Y',
                                     ln_request_id
                                    );
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                         'Request ID of XXODROEMAILER :' || ln_req_id
                        );
   END;

-- +===============================================================================+
-- | Name       : main                                                              |
-- |                                                                               |
-- | Description: This is the main procedure which is called when the concurrent   |
-- |              program is submitted.                                               |
-- |                                                                               |
-- | Parameters : p_load_aops                                                      |
-- |                                                                               |
-- | Returns    : x_errbuf                                                            |
-- |             : x_retcode                                                        |
-- +===============================================================================+
   PROCEDURE main (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER,
      p_load_aops   IN              VARCHAR2 DEFAULT 'N'

   )
   AS
      ln_retcode   NUMBER;
   BEGIN
      IF (NVL (p_load_aops, 'N') = 'Y')
      THEN
         load_aops (p_load_aops, ln_retcode);
      END IF;

      update_cust (p_load_aops, ln_retcode);
      print_report (ln_retcode);
   END;
END xx_cdh_aops_ab_pkg;
/
SHOW ERRORS;