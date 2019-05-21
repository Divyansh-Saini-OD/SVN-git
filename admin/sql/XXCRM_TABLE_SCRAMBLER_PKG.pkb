-- +============================================================================================+
-- |                  Office Depot - Ebiz Generic Process					                              |
-- +============================================================================================+
-- | Name        : XXCRM_TABLE_SCRAMBLER_PKG.pkb                                                |
-- | Description : Generic Process to create export file.                                       |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/07/11       Devendra Petkar        Initial version                            |
-- |2.0        04/28/15       Havish Kasina          Changes done as per Defect 1191            |
-- |3.0        11/12/15       Havish Kasina          Removed the Schema References as per R12.2 |
-- |                                                 Retrofit Changes                           |
-- |3.0        05/21/19       Dinesh Nagapuri        Replaced from v$instance to USER_ENV DB_NAME|
-- |                                                 for LNS		                            |
-- +============================================================================================+
create or replace
PACKAGE BODY xxcrm_table_scrambler_pkg
-- +===================================================================+
-- |                  Office Depot -  Ebiz Generic Process.            |
-- +===================================================================+
-- | Name       :  XXCRM_TABLE_SCRAMBLER_PKG                           |
-- | Description: Generic Process to create export file.           |
-- |                                       |
-- |                                       |
-- |                                       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |V 1.0    08/07/11   Devendra Petkar                       |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name             : generate_table_exp_file                        |
-- | Description      : Generic Process to create export file          |
-- |                                                                   |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE generate_customer_account_exp (
      x_errbuf             OUT NOCOPY      VARCHAR2,
      x_retcode            OUT NOCOPY      NUMBER,
      p_scrambler_method   IN              VARCHAR2 DEFAULT 'RANDOM'
   )
   IS
   BEGIN
      -- Initialize the out Parameters
      x_errbuf := NULL;
      x_retcode := 0;

      IF p_scrambler_method = 'RANDOM'
      THEN
         generate_table_exp_file (x_errbuf,
                                  x_retcode,
                                  'XX_CRM_CUSTMAST_HEAD_STG'
                                 );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error during Customer Account API call '
                            || '::'
                            || SQLERRM
                           );
   END generate_customer_account_exp;

   PROCEDURE generate_customer_address_exp (
      x_errbuf             OUT NOCOPY      VARCHAR2,
      x_retcode            OUT NOCOPY      NUMBER,
      p_scrambler_method   IN              VARCHAR2 DEFAULT 'RANDOM'
   )
   IS
   BEGIN
      -- Initialize the out Parameters
      x_errbuf := NULL;
      x_retcode := 0;

      IF p_scrambler_method = 'RANDOM'
      THEN
         generate_table_exp_file (x_errbuf, x_retcode, 'XX_CRM_CUSTADDR_STG');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error during Customer Address API call '
                            || '::'
                            || SQLERRM
                           );
   END generate_customer_address_exp;

   PROCEDURE generate_customer_contact_exp (
      x_errbuf             OUT NOCOPY      VARCHAR2,
      x_retcode            OUT NOCOPY      NUMBER,
      p_scrambler_method   IN              VARCHAR2 DEFAULT 'RANDOM'
   )
   IS
   BEGIN
      -- Initialize the out Parameters
      x_errbuf := NULL;
      x_retcode := 0;

      IF p_scrambler_method = 'RANDOM'
      THEN
         generate_table_exp_file (x_errbuf, x_retcode, 'XX_CRM_CUSTCONT_STG');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error during Customer Contact API call '
                            || '::'
                            || SQLERRM
                           );
   END generate_customer_contact_exp;

   PROCEDURE copy_file (p_sourcepath IN VARCHAR2, p_destpath IN VARCHAR2)
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
     fnd_file.put_line(fnd_file.log,'Copy File Program');
      ln_request_id := fnd_global.conc_request_id ();
      lc_sourcepath := p_sourcepath;
      lc_destpath := p_destpath;
      
     fnd_file.put_line(fnd_file.log, 'Request Id:'||ln_request_id ||' '||'Source Path:'||lc_sourcepath||' '||'Destination Path:'||lc_destpath);
      
      ln_req_id :=
         fnd_request.submit_request ('XXFIN'
                         ,'XXCOMFILCOPY','',''
                         ,FALSE ,lc_sourcepath
                         ,lc_destpath,'','','Y','','','','',
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
                                              
    fnd_file.put_line(fnd_file.log,' Copy Program Request Id :'||ln_req_id);
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


  PROCEDURE Zip_File(p_sourcepath  IN VARCHAR2,
                     p_destpath    IN VARCHAR2
                    )
  IS

    ln_req_id        NUMBER;
    lc_sourcepath    VARCHAR2(1000);
    lc_destpath      VARCHAR2(1000);
    lb_result        BOOLEAN;
    lc_phase         VARCHAR2(1000);
    lc_status        VARCHAR2(1000);
    lc_dev_phase     VARCHAR2(1000);
    lc_dev_status    VARCHAR2(1000);
    lc_message       VARCHAR2(1000);
    lc_token         VARCHAR2(4000);
    ln_request_id    NUMBER DEFAULT 0;

  BEGIN
   fnd_file.put_line(fnd_file.log,' Zip File Program');
    ln_request_id  := fnd_global.conc_request_id();
    lc_sourcepath  := p_sourcepath;
    lc_destpath    := p_destpath;
   fnd_file.put_line(fnd_file.log, 'Request Id:'||ln_request_id ||' '||'Source Path:'||lc_sourcepath||' '||'Destination Path:'||lc_destpath);
    
    ln_req_id := fnd_request.submit_request
                          ('XXCRM'
                           ,'XXODCRZIPNOPATH'
                           ,''
                           ,''
                           ,FALSE
                           ,lc_sourcepath
                           ,lc_destpath
                           );


    commit;

    lb_result:=fnd_concurrent.wait_for_request(ln_req_id,1,0,
         lc_phase      ,
         lc_status     ,
         lc_dev_phase  ,
         lc_dev_status ,
         lc_message    ); 
  fnd_file.put_line(fnd_file.log,'Zip File Program Request Id:'||ln_req_id);
  EXCEPTION
    WHEN OTHERS THEN
      lc_token   := SQLCODE||':'|| SUBSTR(SQLERRM,1,256);
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, 'An error occured. Details : '||lc_token);
      fnd_file.put_line (fnd_file.LOG, ' ');
  END Zip_File;


   PROCEDURE generate_table_exp_file (
      x_errbuf       OUT NOCOPY      VARCHAR2,
      x_retcode      OUT NOCOPY      NUMBER,
      p_table_name   IN              VARCHAR2,
      p_delimiter    IN              VARCHAR2 DEFAULT '|~'
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
      
		-- Get the Instance Name                         -- Added by Havish Kasina as per defect#1191
        --SELECT lower(instance_name) INTO lc_instance_name FROM v$instance;
		
		--Replaced from v$instance to USERENV DB_NAME --Added for LNS
		SELECT SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8)
		INTO lc_instance_name
		FROM dual;
          
       fnd_file.put_line(fnd_file.log,'Instance Name :'||lc_instance_name);

            IF p_table_name = 'XX_CRM_CUSTMAST_HEAD_STG' THEN

         SELECT UPPER (b.target_value4)
		INTO lc_file_name_env
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = 'CUST_HEADER';

            ELSIF p_table_name = 'XX_CRM_CUSTADDR_STG' THEN


         SELECT UPPER (b.target_value4)
		INTO lc_file_name_env
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = 'CUST_ADDRESSES';

            ELSIF  p_table_name = 'XX_CRM_CUSTCONT_STG' THEN

         SELECT UPPER (b.target_value4)
		INTO lc_file_name_env
           FROM xx_fin_translatedefinition a,
                xx_fin_translatevalues b
          WHERE a.translate_id = b.translate_id
            AND a.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND b.enabled_flag = 'Y'
            AND SYSDATE BETWEEN b.start_date_active
                            AND NVL (b.end_date_active, SYSDATE + 1)
            AND b.source_value1 = 'CUST_CONTACTS';

            END IF;

      lc_file_name :=
         lc_file_name_env || '_' || lc_date_time || '-' || l_file_number||'.dat';

      lc_message1 := p_table_name || ' Feed Generate Init.';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, ' ');
     fnd_file.put_line(fnd_file.log,' File Name is :'||lc_file_name);
     fnd_file.put_line(fnd_file.log,' Message is :'||lc_message1);

      BEGIN
         SELECT TRIM (' ' FROM directory_path || '/' || lc_file_name)
           INTO lc_sourcepath
           FROM all_directories
          WHERE directory_name = 'XXCRM_OUTBOUND';

         lc_message1 := ' File creating is ' || lc_sourcepath;
         fnd_file.put_line (fnd_file.LOG, lc_message1);
         fnd_file.put_line (fnd_file.LOG, ' ');
         
         lc_destpath :=
              nvl(fnd_profile.VALUE ('XX_CRM_WEBCOLLECT_DEST_PATH'),'/app/ebs/ct'||lc_instance_name||'/xxcrm/ftp/out/webcollect/')
              || lc_file_name;            -- Added by Havish Kasina as per defect#1191

          lc_archpath :=
              nvl(fnd_profile.VALUE ('XX_CRM_WEBCOLLECT_ARCH_PATH'),'/app/ebs/ct'||lc_instance_name||'/xxcrm/archive/outbound')
              ; -- Added by Havish Kasina as per defect#1191
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
            AND b.source_value1 = p_table_name;
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

      FOR tabcol IN c1 (p_table_name)
      LOOP
         lc_heading := lc_heading || tabcol.exportfieldname || p_delimiter;
         lc_sourcefieldname := '';

         FOR scrambcol IN c2 (p_table_name)
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
            || p_delimiter;
            
           --fnd_file.put_line(fnd_file.log,' lc_stmt_str is :'||lc_stmt_str);
      END LOOP;

      lc_stmt_str := TRIM (SUBSTR(p_delimiter,2,1) FROM lc_stmt_str);

      lc_stmt_str := TRIM ('|' FROM lc_stmt_str);

      lc_stmt_str := TRIM ('''' FROM lc_stmt_str);

      lc_stmt_str := TRIM ('|' FROM lc_stmt_str);

      lc_stmt_str := 'SELECT ' || lc_stmt_str || ' , cust_account_id FROM APPS.' || p_table_name;
          -- Add the Header Record
--          UTL_FILE.put_line (v_file, lc_heading);
      fnd_file.put_line (fnd_file.LOG, lc_stmt_str);
      --DBMS_OUTPUT.PUT_LINE(' lc_stmt_str2 is :'||lc_stmt_str);
      ----------------------------------------------------------------------
---                Get Request ID                                  ---
----------------------------------------------------------------------
/*
      ln_request_id := fnd_global.conc_request_id ();

	SELECT  a.program, a.program_short_name
		INTO ln_program_name, ln_program_short_name
	FROM FND_CONC_REQ_SUMMARY_V A
	WHERE a.request_id = ln_request_id;
*/

      v_file :=
         UTL_FILE.fopen (LOCATION          => lc_file_loc,
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
             INTO lc_exp_record, lc_exp_account_id;

            EXIT WHEN lc_exp_cursor%NOTFOUND;
            UTL_FILE.put_line (v_file, lc_exp_record);
            ln_total_cnt := ln_total_cnt + 1;
	    ln_file_record_cnt := ln_file_record_cnt+1;

          BEGIN

            IF p_table_name = 'XX_CRM_CUSTMAST_HEAD_STG' THEN

            UPDATE xx_crm_wcelg_cust
               SET cust_mast_head_ext = 'Y'
             WHERE cust_account_id = lc_exp_account_id AND cust_mast_head_ext = 'N';
           -- fnd_file.put_line(fnd_file.log,'XX_CRM_CUSTMAST_HEAD_STG :'||SQL%ROWCOUNT);

            COMMIT;

            ELSIF p_table_name = 'XX_CRM_CUSTADDR_STG' THEN

            UPDATE xx_crm_wcelg_cust
               SET cust_addr_ext = 'Y'
             WHERE cust_account_id = lc_exp_account_id AND cust_addr_ext = 'N';
            --fnd_file.put_line(fnd_file.log,'XX_CRM_CUSTADDR_STG :'||SQL%ROWCOUNT);
            COMMIT;

            ELSIF  p_table_name = 'XX_CRM_CUSTCONT_STG' THEN

              UPDATE xx_crm_wcelg_cust
               SET cust_cont_ext = 'Y'
             WHERE cust_account_id = lc_exp_account_id AND cust_cont_ext = 'N';
            --DBMS_OUTPUT.PUT_LINE('XX_CRM_CUSTCONT_STG :'||SQL%ROWCOUNT);
            COMMIT;

            END IF;



          EXCEPTION
          WHEN OTHERS THEN
          NULL;--DBMS_OUTPUT.PUT_LINE('EXCEPTION:'||SQLERRM);
          END;

      --fnd_file.put_line(fnd_file.log,'Split File');
--------------------------------------------------------------
---                Split File                              ---
--------------------------------------------------------------
            IF MOD (ln_total_cnt, l_file_record_limit) = 0
            THEN
               lc_message1:= '';
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'Total number of Records Fetched on '||SYSDATE||' is: '||ln_file_record_cnt;
             --fnd_file.put_line(fnd_file.log,lc_message1);
               UTL_FILE.put_line (v_file, lc_message1);
               lc_message1:= 'File name '||lc_file_name ||' have total number of Records '||ln_file_record_cnt ||' as of '||SYSDATE||' .';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
              --fnd_file.put_line(fnd_file.log,lc_message1);
	       ln_file_record_cnt :=0;
	       UTL_FILE.fclose (v_file);
	       lc_message1 := lc_file_name || ' File Copy Init';
               fnd_file.put_line (fnd_file.LOG, lc_message1);
               fnd_file.put_line (fnd_file.LOG, '');
              --DBMS_OUTPUT.PUT_LINE(lc_message1);
              --DBMS_OUTPUT.PUT_LINE('Before inserting into xx_crmar_file_log table');
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
               Zip_File(p_sourcepath    => lc_sourcepath ,
                        p_destpath      => lc_archpath
                        );
             fnd_file.put_line(fnd_file.log,'After Creating zip file to archieve folder');
             fnd_file.put_line(fnd_file.log,'Before Creating Source file to Destination');
              -- Creating Source file to Destination
               copy_file (p_sourcepath      => lc_sourcepath,
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
                  lc_destpath :=
                        nvl(fnd_profile.VALUE ('XX_CRM_WEBCOLLECT_DEST_PATH'),'/app/ebs/ct'||lc_instance_name||'/xxcrm/ftp/out/webcollect/')
                     || lc_file_name;            -- Added by Havish Kasina as per defect#1191
                  lc_archpath :=
                        nvl(fnd_profile.VALUE ('XX_CRM_WEBCOLLECT_ARCH_PATH'),'/app/ebs/ct'||lc_instance_name||'/xxcrm/archive/outbound')
                     ;                           -- Added by Havish Kasina as per defect#1191
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
      lc_message1 := p_table_name || ' Feed Generate Complete.';
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
               Zip_File(p_sourcepath    => lc_sourcepath ,
                        p_destpath      => lc_archpath
                        );

     fnd_file.put_line(fnd_file.log,lc_message1);
              -- Creating Source file to Destination
                copy_file (p_sourcepath => lc_sourcepath,
                          p_destpath => lc_destpath
                          );

      COMMIT;
      lc_message1 := lc_file_name || ' File Copy Complete';
      fnd_file.put_line (fnd_file.LOG, lc_message1);
      fnd_file.put_line (fnd_file.LOG, '');
     fnd_file.put_line(fnd_file.log,lc_message1);
----ln_total_cnt

      ----------------------------------------------------------------------
---         Printing summary report in the LOG file                ---
----------------------------------------------------------------------
      lc_message1 := 'Total number of ' || p_table_name || ' Records : ';
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
   END generate_table_exp_file;
END xxcrm_table_scrambler_pkg;
/
SHOW ERRORS;

EXIT;