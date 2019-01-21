create or replace
PACKAGE BODY xx_crm_wc_cust_inbound_pkg
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :XX_CRM_WC_CUST_INBOUND_PKG                              |
--|RICE        :106313                                                  |
--|Description : This package is used for getting the data from         |
--|              webcollet and insert date into Oracle Stage tables     |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version  Date          Author                     Remarks            |
--|=======  ===========   =====================      =========          |
--|1.00     28-Nov-2011   Balakrishna Bolikonda      Initial Version    |
--|1.10     22-Feb-2012   Jay Gupta                  Defect#17102       |
--|1.20     23-Feb-2012   Jay Gupta                  Defect#16904       |
--|1.30     09-Mar-2012   Jay Gupta                  Defect#17455       |
--|1.40     16-Mar-2012   Jay Gupta                  Defect#17373       |
--|1.5      22-May-2012   Jay Gupta              Defect 18387 - Add     |
--|                                             Request_id in LOG tables|
--|2.0      3-Sep-2014    Sridevi K                  Added comments     |
--|                                                  for Defect30204    |
--|                                                   changes           |
--|3.0      16-Apr-2015   Arun Gannarapu             Defect 33938       |
--|4.0      18-Mar-2015   Havish Kasina         Removed the Schema refe |
--|                                             rences in the existing  |
--|                                             code as per R12.2 Retro-|
--|                                             fit Changes             | 
--+=====================================================================+
AS

   /* V1.2, Declared package body global variable
            created a procedure to get the email and assign it to global variable */

   gc_notify_email VARCHAR2(200);

-- +===============================================================================+
-- | Name       : get_notify_email                                                 |
-- |                                                                               |
-- | Description: It is used to get the notification email from translation valueus|
-- |                                                                               |
-- | Parameters : None                                                             |
-- |                                                                               |
-- +===============================================================================+

   PROCEDURE get_notify_email
   IS
   BEGIN
      SELECT XFTV.target_value5
        INTO gc_notify_email
        FROM xx_fin_translatedefinition XFTD ,
             xx_fin_translatevalues XFTV
       WHERE XFTV.translate_id = XFTD.translate_id
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
         AND XFTV.source_value1    = 'XX_CRM_INBOUND_NOTIFY'
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.enabled_flag     = 'Y'
         AND XFTD.enabled_flag     = 'Y';

      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line
                          (fnd_file.LOG,
                              'Notification Email not defined '
                           || SQLERRM ()
                          );
   END get_notify_email;


-- +===============================================================================+
-- | Name       : WRITE_LOG                                                        |
-- |                                                                               |
-- | Description: This procedure is used to to display detailed                    |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_debug_flag                                                     |
-- |              p_msg                                                            |
-- |                                                                               |
-- | Returns    : none                                                             |
-- +===============================================================================+


   PROCEDURE write_log (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      END IF;
   END write_log;

-- +===============================================================================+
-- | Name       : compute_stats                                                    |
-- |                                                                               |
-- | Description: This procedure is used to to display detailed                    |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_compute_stats                                                  |
-- |              p_schema                                                         |
-- |              p_tablename                                                      |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE compute_stats (
      p_compute_stats   IN   VARCHAR2
     ,p_schema          IN   VARCHAR2
     ,p_tablename       IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_compute_stats = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Gathering table stats');
         fnd_stats.gather_table_stats (ownname      => p_schema
                                      ,tabname => p_tablename);
      END IF;
   END compute_stats;



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
      ln_request_id := fnd_global.conc_request_id ();
      lc_sourcepath := p_sourcepath;
      lc_destpath := p_destpath;
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

--+=====================================================================+
--| Name       :  ins_int_log                                           |
--| Description:  This procedure is used to insert the file entries     |
--|               int log table                                         |
--| Parameters :  p_file_name                                           |
--|               p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE ins_int_log (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_file_name       IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   IS
   BEGIN
      gc_debug_flag := p_debug;

      get_notify_email; -- V1.2, Calling proc to initialize the global variable

      gc_error_debug := 'Start of Inserting file names into log file ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '********** Ins_int_log Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, '   File name is:' || p_file_name);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || p_debug);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || p_compute_stats);


      /* V1.1, In case of inbound process, need to check for file naming convention
         added IF condition - if finename is not correct, do not insert into log table
         so that it will not be picked up via insert program, did not change else part */

      IF gc_program_short_name='XX_CRM_WC_CUST_INBOUND_PKG'
      AND UPPER(SUBSTR(p_file_name,1,15))<>'XX_CDH_INBOUND_'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File name '||p_file_name||' is not correct');
      ELSE
         BEGIN
            SELECT xx_crmar_int_log_s.NEXTVAL
              INTO gn_nextval
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               gc_error_debug := SQLERRM || 'Exception raised while getting sequence value';
               fnd_file.put_line (fnd_file.LOG, gc_error_debug);
               p_retcode := 2;
         END;

         gc_error_debug := 'Before inserting into log table';
         write_log (gc_debug_flag, gc_error_debug);

         INSERT INTO xx_crmar_int_log
                  (Program_Run_Id
                  ,program_name
                  ,program_short_name
                  ,module_name
                  ,program_run_date
                  ,filename
                  ,status
                  ,MESSAGE
                  ,request_id  -- V1.5
                  )
           VALUES (gn_nextval
                  ,gc_Program_name
                  ,gc_program_short_name
                  ,gc_module_name
                  ,SYSDATE
                  ,p_file_name
                  ,'Copied file from FTP to In directory '
                  ,'NEW'
                  ,gn_request_id
                  );

         COMMIT;
         gc_error_debug := 'After inserting into log table';
         write_log (gc_debug_flag, gc_error_debug);
         gc_error_debug := 'End of Inserting file names into log file ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END IF;   -- V1.1 Changes end

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO Data found in read_file_ins_int procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception raised in read_file_ins_int procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   END ins_int_log;

--+=====================================================================+
--| Name       :  read_file_ins_int                                     |
--| Description:  This procedure is used to read the file from IN       |
--|               directory and to insert into custom interface table   |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
--   PROCEDURE read_file_ins_int (
--      p_errbuf          OUT      VARCHAR2
--     ,p_retcode         OUT      NUMBER
--     ,p_debug           IN       VARCHAR2
--     ,p_compute_stats   IN       VARCHAR2
--   )
--   IS
--      -- Variable declaration
--      lc_filehandle                   UTL_FILE.file_type;
--      lc_message                      VARCHAR2 (32767);
--      lc_delimiter                    VARCHAR2 (3);
--      ln_site_use_id                  NUMBER (15);
--      ln_org_id                       NUMBER (15);
--      lc_customer_number              VARCHAR2 (30);
--      lc_site_orig_system_refe        VARCHAR2 (240);
--      lc_collector_name               VARCHAR2 (30);
--      ln_collector_id                 NUMBER (15);
--      ln_contact_id                  VARCHAR2 (240);
--      lc_contact_last_name            VARCHAR2 (150);
--      lc_contact_first_name           VARCHAR2 (150);
--      lc_job_title                    VARCHAR2 (60);
--      lc_email_address                VARCHAR2 (240);
--      lc_contact_role                 VARCHAR2 (60);
--      lc_contact_role_primary_flag    VARCHAR2 (3);
--      lc_phone_purpose                VARCHAR2 (60);
--      lc_email_purpose                VARCHAR2 (60);
--      lc_fax_purpose                  VARCHAR2 (60);
--      --lc_contact_point_type           VARCHAR2 (60);
--      lc_phone_country_code           VARCHAR2 (10);
--      lc_phone_area_code              VARCHAR2 (10);
--      lc_phone_number                 VARCHAR2 (15);
--      lc_fax_country_code             VARCHAR2 (10);
--      lc_fax_area_code                VARCHAR2 (10);
--      lc_fax_number                   VARCHAR2 (15);
--      lc_webcollect_contact_id        VARCHAR2 (240);
--      lc_extension                    VARCHAR2 (10);
--      lc_contact_point_primary_flag   VARCHAR2 (3);
--      lc_contact_start_date           VARCHAR2 (22);
--      lc_contact_end_date             VARCHAR2 (22);
--      lc_contact_orig_system_ref      VARCHAR2 (240);
--      lc_phone_osr                    VARCHAR2 (30);
--      lc_fax_osr                      VARCHAR2 (30);
--      lc_email_osr                    VARCHAR2 (30);
--      ln_total_length                 NUMBER;
--      ln_total_comma                  NUMBER             := 0;
--      ln_record_comma                 NUMBER;
--      ln_total_records                NUMBER             := 0;
--      ln_count                        NUMBER             := 0;
--      lc_filename                     VARCHAR2 (200);
--      ln_linesize                     NUMBER;
--      lc_filepath                     VARCHAR2 (200);
--      lc_mode                         VARCHAR2 (2)       := 'R';
--      ln_err_no                       NUMBER             := 1;
--      ln_ftp_request_id               NUMBER;
--      ln_retcode                      NUMBER;
--      lc_webcollect_dl                VARCHAR2 (50);
--      lc_first_column                 VARCHAR2 (200);
--	v_sqlerrm                 VARCHAR2 (1000);
--      lc_target_filepath	VARCHAR2 (200);
--
--      -- V1.2, declared 4 variable
--      ln_trailer_rec_found  NUMBER;
--      ln_first_comma NUMBER;
--      ln_first_colon  NUMBER;
--      ln_rec_count_check  NUMBER;
--      -- V1.40,
--      lc_collector_desc               AR_COLLECTORS.DESCRIPTION%TYPE;
--
--      --Table type declaration
--      file_names_tbl_type             lt_file_names;
--
--	lc_sourcepath	VARCHAR2 (200);
--	lc_destpath VARCHAR2 (200);
--
--   BEGIN
--      gc_error_debug := 'Start of Inserting file data into staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
--      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
--      gc_debug_flag := p_debug;
--      gc_compute_stats := p_compute_stats;
--      get_notify_email; -- V1.2, Calling proc to initialize the global variable
--
--      BEGIN
--         SELECT XFTV.target_value2
--               ,XFTV.target_value7
--               ,XFTV.target_value3                                                                                                       --Source path for inbound, files stored here from FTP directory
--               ,XFTV.target_value12
--         INTO   lc_delimiter
--               ,ln_linesize
--               ,lc_filepath
--               ,lc_target_filepath
--         FROM   xx_fin_translatevalues XFTV
--               ,xx_fin_translatedefinition XFTD
--          WHERE XFTV.translate_id = XFTD.translate_id
--            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
--            AND XFTV.source_value1 = 'XX_OD_WC_OB_INTERFACES'
--            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
--            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
--            AND XFTV.enabled_flag = 'Y'
--            AND XFTD.enabled_flag = 'Y';
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            gc_error_debug := 'NO data found while selecting translation defination values';
--            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
--      END;
--
--
--
--      /* V1.2, Changes to mark 'Failed', if there is no Trailer record or if it has Trailer record */
--
--      BEGIN
--         SELECT filename
--           BULK COLLECT INTO file_names_tbl_type
--           FROM xx_crmar_int_log
--          WHERE program_short_name = 'XX_CRM_WC_CUST_INBOUND_PKG'
--            AND program_run_date > FND_DATE.CANONICAL_TO_DATE (TO_CHAR (SYSDATE - 1, 'YYYYMMDDHH24MISS'))
--            AND MESSAGE = 'NEW';
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            gc_error_debug := 'NO data found while getting filenames from log table';
--            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
--         WHEN OTHERS
--         THEN
--            gc_error_debug := SQLCODE || ' Others exception raised while getting filenames from log table';
--            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
--            p_retcode := 2;
--      END;
--
--
--------------------Start
--
--      IF file_names_tbl_type.COUNT < 1
--      THEN
--		fnd_file.put_line (fnd_file.LOG, 'Not Processing');
--		--sp_email_notification('There is no files for process.');
--	return;
--      END IF;
--
--         gc_error_debug := 'Before truncating Custom interface table ';
--         write_log (gc_debug_flag, gc_error_debug);
--
--         EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_wc_cust_dcca_int';
--
--       FOR i IN file_names_tbl_type.FIRST .. file_names_tbl_type.LAST
--         LOOP
--            ln_trailer_rec_found := 0;
--            lc_filehandle := UTL_FILE.fopen (lc_filepath
--                                            ,file_names_tbl_type(i)
--                                            ,lc_mode
--                                            ,ln_linesize
--                                            );
--
--		ln_total_records := 0;
--				LOOP
--					BEGIN
--						UTL_FILE.get_line (lc_filehandle, lc_message);
--						fnd_file.put_line (fnd_file.LOG, lc_message);
--
--						BEGIN
--							lc_message := REPLACE (lc_message,'",','`');
--							 SELECT  TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 1)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 2)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 3)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 4)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 5)) ,
--								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 6)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 7)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 8)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 9)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 10)) ,
--								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 11)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 12)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 13)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 14)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 15)) ,
--								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 16)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 17)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 18)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 19)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 20)) ,
--								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 21)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 22)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 23)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 24)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 25)) ,
--								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 26)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 27)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 28)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 29)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 30))
--						       INTO ln_site_use_id, ln_org_id, lc_customer_number, lc_site_orig_system_refe, lc_collector_desc,
--									lc_collector_name, ln_contact_id, lc_contact_last_name, lc_contact_first_name, lc_job_title,
--									lc_email_address, lc_contact_role, lc_contact_role_primary_flag, lc_phone_purpose, lc_phone_country_code,
--									lc_phone_area_code, lc_phone_number, lc_extension, lc_contact_point_primary_flag, lc_contact_start_date,
--									lc_contact_end_date, lc_fax_country_code, lc_fax_area_code, lc_fax_number, lc_webcollect_contact_id,
--									lc_email_purpose, lc_fax_purpose, lc_email_osr, lc_phone_osr, lc_fax_osr
--							FROM dual;
--
--
--					     BEGIN
--						SELECT COLLECTOR_ID
--						  INTO ln_collector_id
--						  FROM AR_COLLECTORS
--						 WHERE NAME = lc_collector_name;
--					     EXCEPTION
--						WHEN OTHERS THEN
--						   ln_collector_id := null;
--					     END;
--
--
--						INSERT INTO xx_crm_wc_cust_dcca_int
--						(site_use_id, org_id, customer_number, site_orig_system_refe, collector_name,
--						collector_id, contact_id, contact_last_name, contact_first_name, job_title,
--						email_address, contact_role, contact_role_primary_flag, phone_purpose, phone_country_code,
--						phone_area_code, phone_number, extension, contact_point_primary_flag, contact_start_date,
--						contact_end_date, fax_country_code, fax_area_code, fax_number, webcollect_contact_id,
--						email_purpose, fax_purpose, email_osr, phone_osr, fax_osr  ,process_status
--						,Process_Flag ,Creation_Date ,Created_By ,Last_Updated_By ,Last_Update_Login ,Request_Id ,last_update_date
--						)
--						VALUES (ln_site_use_id, ln_org_id, lc_customer_number, lc_site_orig_system_refe, lc_collector_name,
--							ln_collector_id, ln_contact_id, lc_contact_last_name, lc_contact_first_name, lc_job_title,
--							lc_email_address, lc_contact_role, lc_contact_role_primary_flag, lc_phone_purpose, lc_phone_country_code,
--							lc_phone_area_code, lc_phone_number, lc_extension, lc_contact_point_primary_flag, lc_contact_start_date,
--							lc_contact_end_date, lc_fax_country_code, lc_fax_area_code, lc_fax_number, lc_webcollect_contact_id,
--							lc_email_purpose, lc_fax_purpose, lc_email_osr, lc_phone_osr, lc_fax_osr ,'' ,'N' ,Gd_Creation_Date ,gn_created_by ,Gn_Last_Updated_By ,Gn_Last_Update_Login
--						,Gn_Request_Id ,gd_last_update_date
--						);
--
--
--							IF sql%rowcount >0 THEN
--								ln_total_records := ln_total_records+1;
--							END IF;
--
--
--						commit;
--
--
--						EXCEPTION
--						WHEN OTHERS THEN
--					v_sqlerrm:=sqlerrm;
--					fnd_file.put_line (fnd_file.LOG, sqlerrm);
--
--						END ;
--
--						fnd_file.put_line (fnd_file.LOG, ln_org_id);
--
--
--					EXCEPTION
--					WHEN OTHERS THEN
--					v_sqlerrm:=sqlerrm;
--					fnd_file.put_line (fnd_file.LOG, sqlerrm);
--					exit;
--					END ;
--				END LOOP;
--
--	    UTL_FILE.fclose (lc_filehandle);
--
--
--
--
--         SELECT TRIM (' ' FROM directory_path || '/' || file_names_tbl_type(i) )
--           INTO lc_sourcepath
--           FROM all_directories
--          WHERE directory_name = lc_filepath;
--
--	lc_destpath := lc_target_filepath||'/'||file_names_tbl_type(i);
--
--
--              -- Creating Source file to Destination
--               copy_file (p_sourcepath      => lc_sourcepath,
--                          p_destpath        => lc_destpath
--                         );
--
--
--                        UPDATE xx_crmar_int_log
--                           SET status = 'Records records inserted'||ln_total_records||' into Custom Interface Table'
--                              ,MESSAGE = 'Processed'
--                         WHERE filename = file_names_tbl_type (i);
--
--                        COMMIT;
--
--	 END LOOP;
--
-------------------End
--
--
--
--      gc_error_debug := 'Loop ended here';
--      write_log (gc_debug_flag, gc_error_debug);
----      UTL_FILE.fclose (lc_filehandle);
--      --Gathering table stats
--      compute_stats (gc_compute_stats
--                    ,'XXCRM'
--                    ,'XX_CRM_WC_CUST_DCCA_INT'
--                    );
--      gc_error_debug := 'End of Inserting file data into staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
--      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_path
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.invalid_mode
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.read_error
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.write_error
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN UTL_FILE.internal_error
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--      WHEN OTHERS
--      THEN
--         gc_error_debug := SQLCODE || '-' || SQLERRM;
--         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
--         p_retcode := 2;
--   --End of read_file_ins_int procedure
--   END read_file_ins_int;

--+=====================================================================+
--| Name       :  load_cint_extng_int                                   |
--| Description: This procedure is used Load data from custom interface |
--|               table into existing customer conversion interface     |
--|                tables                                               |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE load_cint_extng_int (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   IS

       -- Variable declaration
      lc_filehandle                   UTL_FILE.file_type;
      lc_message                      VARCHAR2 (32767);
      lc_delimiter                    VARCHAR2 (3);
      ln_site_use_id                  NUMBER (15);
      ln_org_id                       NUMBER (15);
      lc_customer_number              VARCHAR2 (30);
      lc_site_orig_system_refe        VARCHAR2 (240);
      lc_collector_name               VARCHAR2 (30);
      ln_collector_id                 NUMBER (15);
      ln_contact_id                  VARCHAR2 (240);
      lc_contact_last_name            VARCHAR2 (150);
      lc_contact_first_name           VARCHAR2 (150);
      lc_job_title                    VARCHAR2 (60);
      lc_email_address                VARCHAR2 (240);
      lc_contact_role                 VARCHAR2 (60);
      lc_contact_role_primary_flag    VARCHAR2 (3);
      lc_phone_purpose                VARCHAR2 (60);
      lc_email_purpose                VARCHAR2 (60);
      lc_fax_purpose                  VARCHAR2 (60);
      --lc_contact_point_type           VARCHAR2 (60);
      lc_phone_country_code           VARCHAR2 (10);
      lc_phone_area_code              VARCHAR2 (10);
      lc_phone_number                 VARCHAR2 (15);
      lc_fax_country_code             VARCHAR2 (10);
      lc_fax_area_code                VARCHAR2 (10);
      lc_fax_number                   VARCHAR2 (15);
      lc_webcollect_contact_id        VARCHAR2 (240);
      lc_extension                    VARCHAR2 (10);
      lc_contact_point_primary_flag   VARCHAR2 (3);
      lc_contact_start_date           VARCHAR2 (22);
      lc_contact_end_date             VARCHAR2 (22);
      lc_contact_orig_system_ref      VARCHAR2 (240);
      --Modified for Defect30204 by Sreedhar
      lc_phone_osr                    hz_orig_sys_references.ORIG_SYSTEM_REFERENCE%TYPE; --VARCHAR2 (30);
      lc_fax_osr                      hz_orig_sys_references.ORIG_SYSTEM_REFERENCE%TYPE; --VARCHAR2 (30);
      lc_email_osr                    hz_orig_sys_references.ORIG_SYSTEM_REFERENCE%TYPE; --VARCHAR2 (30);
      lc_collector_portfolio          VARCHAR2(25);
      --End - Modified for Defect30204 by Sreedhar
      ln_total_length                 NUMBER;
      ln_total_comma                  NUMBER             := 0;
      ln_record_comma                 NUMBER;
      ln_total_records                NUMBER             := 0;
      ln_count                        NUMBER             := 0;
      lc_filename                     VARCHAR2 (200);
      ln_linesize                     NUMBER;
      lc_filepath                     VARCHAR2 (200);
      lc_mode                         VARCHAR2 (2)       := 'R';
      ln_err_no                       NUMBER             := 1;
      ln_ftp_request_id               NUMBER;
      ln_retcode                      NUMBER;
      lc_webcollect_dl                VARCHAR2 (50);
      lc_first_column                 VARCHAR2 (200);
	v_sqlerrm                 VARCHAR2 (1000);
      lc_target_filepath	VARCHAR2 (200);

      -- V1.2, declared 4 variable
      ln_trailer_rec_found  NUMBER;
      ln_first_comma NUMBER;
      ln_first_colon  NUMBER;
      ln_rec_count_check  NUMBER;
      -- V1.40,
      lc_collector_desc               AR_COLLECTORS.DESCRIPTION%TYPE;

      --Table type declaration
      file_names_tbl_type             lt_file_names;

	lc_sourcepath	VARCHAR2 (200);
	lc_destpath VARCHAR2 (200);

   BEGIN
      gc_error_debug := 'Start of Inserting file data into staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_debug_flag := p_debug;
      gc_compute_stats := p_compute_stats;
      get_notify_email; -- V1.2, Calling proc to initialize the global variable

      BEGIN
         SELECT XFTV.target_value2
               ,XFTV.target_value7
               ,XFTV.target_value3                                                                                                       --Source path for inbound, files stored here from FTP directory
               ,XFTV.target_value12
         INTO   lc_delimiter
               ,ln_linesize
               ,lc_filepath
               ,lc_target_filepath
         FROM   xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'XX_OD_WC_OB_INTERFACES'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;



      /* V1.2, Changes to mark 'Failed', if there is no Trailer record or if it has Trailer record */

      BEGIN
         SELECT filename
           BULK COLLECT INTO file_names_tbl_type
           FROM xx_crmar_int_log
          WHERE program_short_name = 'XX_CRM_WC_CUST_INBOUND_PKG'
            AND program_run_date > FND_DATE.CANONICAL_TO_DATE (TO_CHAR (SYSDATE - 1, 'YYYYMMDDHH24MISS'))
            AND MESSAGE = 'NEW';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while getting filenames from log table';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         WHEN OTHERS
         THEN
            gc_error_debug := SQLCODE || ' Others exception raised while getting filenames from log table';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
            p_retcode := 2;
      END;


------------------Start

      IF file_names_tbl_type.COUNT < 1
      THEN
		fnd_file.put_line (fnd_file.LOG, 'Not Processing');
		--sp_email_notification('There is no files for process.');
	--return; -- commented for testing
      END IF;

         gc_error_debug := 'Before truncating Custom interface table ';
         write_log (gc_debug_flag, gc_error_debug);

         EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_wc_cust_dcca_int';

       FOR i IN file_names_tbl_type.FIRST .. file_names_tbl_type.LAST
         LOOP
            ln_trailer_rec_found := 0;
            lc_collector_portfolio := NULL;
            lc_filehandle := UTL_FILE.fopen (lc_filepath
                                            ,file_names_tbl_type(i)
                                            ,lc_mode
                                            ,ln_linesize
                                            );

		ln_total_records := 0;
				LOOP
					BEGIN
					UTL_FILE.get_line (lc_filehandle, lc_message);
						fnd_file.put_line (fnd_file.LOG, lc_message);

						BEGIN
							lc_message := REPLACE (lc_message,'",','`');
							 SELECT  TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 1)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 2)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 3)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 4)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 5)) ,
								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 6)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 7)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 8)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 9)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 10)) ,
								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 11)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 12)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 13)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 14)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 15)) ,
								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 16)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 17)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 18)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 19)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 20)) ,
								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 21)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 22)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 23)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 24)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 25)) ,
								TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 26)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 27)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 28)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 29)) , TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 30)),
                                                                TRIM('"' FROM regexp_substr(lc_message, '[^`]+', 1, 31))
						       INTO ln_site_use_id, ln_org_id, lc_customer_number, lc_site_orig_system_refe, lc_collector_desc,
									lc_collector_name, ln_contact_id, lc_contact_last_name, lc_contact_first_name, lc_job_title,
									lc_email_address, lc_contact_role, lc_contact_role_primary_flag, lc_phone_purpose, lc_phone_country_code,
									lc_phone_area_code, lc_phone_number, lc_extension, lc_contact_point_primary_flag, lc_contact_start_date,
									lc_contact_end_date, lc_fax_country_code, lc_fax_area_code, lc_fax_number, lc_webcollect_contact_id,
									lc_email_purpose, lc_fax_purpose, lc_email_osr, lc_phone_osr, lc_fax_osr,lc_collector_portfolio
							FROM dual;

					     BEGIN
						SELECT COLLECTOR_ID
						  INTO ln_collector_id
						  FROM AR_COLLECTORS
						 WHERE NAME = lc_collector_name;


                                                 IF lc_collector_portfolio IS NOT NULL
                                                 THEN 
                                                   UPDATE ar_collectors
                                                   SET attribute1 = lc_collector_portfolio,
                                                       attribute_category = 'GLB',
                                                       last_update_date = SYSDATE,
                                                       last_updated_by  = fnd_global.user_id
                                                   WHERE collector_id = ln_collector_id;
                                                 END IF;

					     EXCEPTION
						WHEN OTHERS THEN
						   ln_collector_id := null;
                                                   fnd_file.put_line(fnd_file.log ,'Collector not exists');
					     END;

						INSERT INTO xx_crm_wc_cust_dcca_int
						(site_use_id, org_id, customer_number, site_orig_system_refe, collector_name,
						collector_id, contact_id, contact_last_name, contact_first_name, job_title,
						email_address, contact_role, contact_role_primary_flag, phone_purpose, phone_country_code,
						phone_area_code, phone_number, extension, contact_point_primary_flag, contact_start_date,
						contact_end_date, fax_country_code, fax_area_code, fax_number, webcollect_contact_id,
						email_purpose, fax_purpose, email_osr, phone_osr, fax_osr  ,process_status
						,Process_Flag ,Creation_Date ,Created_By ,Last_Updated_By ,Last_Update_Login ,Request_Id ,last_update_date,
                                                 collector_portfolio
						)
						VALUES (ln_site_use_id, ln_org_id, lc_customer_number, lc_site_orig_system_refe, lc_collector_name,
							ln_collector_id, ln_contact_id, lc_contact_last_name, lc_contact_first_name, lc_job_title,
							lc_email_address, lc_contact_role, lc_contact_role_primary_flag, lc_phone_purpose, lc_phone_country_code,
							lc_phone_area_code, lc_phone_number, lc_extension, lc_contact_point_primary_flag, lc_contact_start_date,
							lc_contact_end_date, lc_fax_country_code, lc_fax_area_code, lc_fax_number, lc_webcollect_contact_id,
							lc_email_purpose, lc_fax_purpose, lc_email_osr, lc_phone_osr, lc_fax_osr ,'' ,'N' ,Gd_Creation_Date ,gn_created_by ,Gn_Last_Updated_By ,Gn_Last_Update_Login
						,Gn_Request_Id ,gd_last_update_date,lc_collector_portfolio
						);

							IF sql%rowcount >0 THEN
								ln_total_records := ln_total_records+1;
							END IF;


						commit;


						EXCEPTION
						WHEN OTHERS THEN
					v_sqlerrm:=sqlerrm;
					fnd_file.put_line (fnd_file.LOG, sqlerrm);

						END ;

						fnd_file.put_line (fnd_file.LOG, ln_org_id);


					EXCEPTION
					WHEN OTHERS THEN
					v_sqlerrm:=sqlerrm;
					fnd_file.put_line (fnd_file.LOG, sqlerrm);
					exit;
					END ;
				END LOOP;

	    UTL_FILE.fclose (lc_filehandle);

         SELECT TRIM (' ' FROM directory_path || '/' || file_names_tbl_type(i) )
           INTO lc_sourcepath
           FROM all_directories
          WHERE directory_name = lc_filepath;

	lc_destpath := lc_target_filepath||'/'||file_names_tbl_type(i);


              -- Creating Source file to Destination
               copy_file (p_sourcepath      => lc_sourcepath,
                          p_destpath        => lc_destpath
                         );


                        UPDATE xx_crmar_int_log
                           SET status = 'Records records inserted'||ln_total_records||' into Custom Interface Table'
                              ,MESSAGE = 'Processed'
                         WHERE filename = file_names_tbl_type (i);

                        COMMIT;

	 END LOOP;

-----------------End



      gc_error_debug := 'Loop ended here';
      write_log (gc_debug_flag, gc_error_debug);
--      UTL_FILE.fclose (lc_filehandle);
      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_WC_CUST_DCCA_INT'
                    );
      gc_error_debug := 'End of Inserting file data into staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_mode
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_operation
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.read_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.write_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.internal_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
   --End of read_file_ins_int procedure
   END load_cint_extng_int;

--+=====================================================================+
--| Name       :  collector_errors                                      |
--| Description:  This procedure is used send the notification for      |
--|               Collector errors                                      |
--| Parameters :                                                        |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE collector_errors (
      p_errbuf    OUT   VARCHAR2
     ,p_retcode   OUT   NUMBER
   )
   IS
--variable declaration
      ln_ftp_request_id   NUMBER;

--Cursor declaration
      CURSOR lcu_collector_errors
      IS
         SELECT HCA.account_number
               ,HCA.account_name
               ,PROF.collector_name
               ,ELOG.exception_log
           FROM xxod_hz_imp_account_prof_stg PROF
               ,hz_cust_accounts HCA
               ,xx_com_exceptions_log_conv ELOG
          WHERE HCA.orig_system_reference = PROF.account_orig_system_reference
            AND PROF.batch_id = ELOG.batch_id
            AND PROF.record_id = ELOG.record_control_id
            AND PROF.interface_status = '6'
            AND PROF.batch_id IN (SELECT batch_id
                                    FROM xx_crm_wc_cust_dcca_int
                                   WHERE ROWNUM = 1);
   BEGIN
      gc_error_debug := 'Start of sending notification for collector Assignments errors ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      get_notify_email; -- V1.2, Calling proc to initialize the global variable
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.output, 'WebCollect CDH Inbound Collector Assignment Errors');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, 'Customer         Customer Name              Collector Name       Error');
      fnd_file.put_line (fnd_file.output, '----------      ----------------          ---------------     ------------');

      FOR i IN lcu_collector_errors
      LOOP
         fnd_file.put_line (fnd_file.output, RPAD (i.account_number, 18) || RPAD (i.account_name, 25) || RPAD (i.collector_name, 18) || i.exception_log);
      END LOOP;

      gc_error_debug := 'Calling the OD: Concurrent Request Output Emailer Program';
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      ln_ftp_request_id :=
      fnd_request.submit_request ('XXFIN'
                                    ,'XXODROEMAILER'
                                    ,''
                                    ,''
                                    ,FALSE
                                    ,'XXODROEMAILER'
                                    , gc_notify_email -- V1.2 'balakrishna.bolikonda@capgemini.com'
                                    ,'CDH_Inbound_Errors'
                                    ,'body'
                                    ,'YES'
                                    ,fnd_global.conc_request_id
                                    ,gc_notify_email -- V1.2 'balakrishna.bolikonda@capgemini.com'
                                    );
      COMMIT;

      IF ln_ftp_request_id = 0
      THEN
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is not submitted');
         p_retcode := 2;
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is submitted successfully');
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program request id is:' || ln_ftp_request_id);
      END IF;

      gc_error_debug := 'End of sending notification for collector Assignments errors ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO Data found in collector_errors procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception raised in collector_errors procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of collector_errors  procedure
   END collector_errors;

--+=====================================================================+
--| Name       :  contact_errors                                        |
--| Description:  This procedure is used send the notification for      |
--|               Contact errors                                        |
--| Parameters :                                                        |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE contact_errors (
      p_errbuf    OUT   VARCHAR2
     ,p_retcode   OUT   NUMBER
   )
   IS
--variable declaration
      ln_ftp_request_id   NUMBER;

--Cursor declaration
      CURSOR lcu_contact_errors
      IS
         SELECT HCA.account_number
               ,HCA.account_name
               ,HOC.contact_number
               ,ELOG.exception_log
           FROM xxod_hz_imp_acct_contact_stg CONT
               ,xxod_hz_imp_contactpts_stg CONTPTS
               ,hz_cust_accounts HCA
               ,xx_com_exceptions_log_conv ELOG
               ,hz_org_contacts HOC
          WHERE HCA.orig_system_reference = CONT.account_orig_system_reference
            AND CONT.contact_orig_system_reference = CONTPTS.contact_orig_system_reference
            AND HOC.orig_system_reference = CONT.contact_orig_system_reference
            AND CONT.batch_id = CONTPTS.batch_id
            AND CONTPTS.batch_id = ELOG.batch_id
            AND CONTPTS.record_id = ELOG.record_control_id
            AND CONTPTS.interface_status = '6'
            AND CONT.batch_id IN (SELECT batch_id
                                    FROM xx_crm_wc_cust_dcca_int
                                   WHERE ROWNUM = 1);
   BEGIN
      gc_error_debug := 'Start of sending notification for Contacts errors ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      get_notify_email; -- V1.2, Calling proc to initialize the global variable
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.output, 'WebCollect CDH Inbound Contact Errors');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, 'Customer        Customer Name               Contact Name         Error');
      fnd_file.put_line (fnd_file.output, '----------    -------------------         --------------       ----------');

      FOR i IN lcu_contact_errors
      LOOP
         fnd_file.put_line (fnd_file.output, RPAD (i.account_number, 18) || RPAD (i.account_name, 25) || RPAD (i.contact_number, 18) || i.exception_log);
      END LOOP;

      gc_error_debug := 'Calling the OD: Concurrent Request Output Emailer Program';
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      ln_ftp_request_id :=
         fnd_request.submit_request ('XXFIN'
                                    ,'XXODROEMAILER'
                                    ,''
                                    ,''
                                    ,FALSE
                                    ,'XXODROEMAILER'
                                    ,gc_notify_email -- V1.2 'balakrishna.bolikonda@capgemini.com'
                                    ,'CDH_Inbound_Errors'
                                    ,'body'
                                    ,'YES'
                                    ,fnd_global.conc_request_id
                                    ,gc_notify_email -- V1.2 'balakrishna.bolikonda@capgemini.com'
                                    );
      COMMIT;

      IF ln_ftp_request_id = 0
      THEN
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is not submitted');
         p_retcode := 2;
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is submitted successfully');
         fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program request id is:' || ln_ftp_request_id);
      END IF;

      gc_error_debug := 'Start of sending notification for Contacts errors ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO Data found in contact_errors procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception raised in contact_errors procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of contact_errors  procedure
   END contact_errors;

--+=====================================================================+
--| Name       :  validate_data                                         |
--| Description:  This procedure is used to validate the data after     |
--|                processing all records, to check whether all records |
--|                are processed or not                                 |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE validate_data (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   )
   IS
      --Variable declaration
      lc_debug_flag          VARCHAR2 (2);
      ln_retcode             NUMBER;
      ln_error_count         NUMBER;
      lc_status              VARCHAR2 (20);
      lc_contact_dl          VARCHAR2 (50);
      lc_collector_dl        VARCHAR2 (50);
      ln_collector_err_cnt   NUMBER;
      ln_contact_err_cnt     NUMBER;
      ln_ftp_request_id      NUMBER;
   BEGIN
      gc_error_debug := 'Start of validating data procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      get_notify_email; -- V1.2, Calling proc to initialize the global variable
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      lc_debug_flag := p_debug;
      /*BEGIN
         SELECT XFTV.target_value20
               ,XFTV.target_value12
           INTO lc_contact_dl
               ,lc_collector_dl
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'XX_OD_WC_OB_INTERFACES'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;*/
      fnd_file.put_line (fnd_file.LOG, '********** Validate_data Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');

      --fnd_file.put_line (fnd_file.LOG, '   Contacts Errors Disrtibution List: '||lc_contact_dl);
      --fnd_file.put_line (fnd_file.LOG, '   Collector Errors Disrtibution List: '||lc_collector_dl);
      SELECT COUNT (*)
        INTO ln_collector_err_cnt
        FROM xxod_hz_imp_account_prof_stg PROF
       WHERE PROF.interface_status = '6' AND PROF.batch_id IN (SELECT UNIQUE batch_id
                                                                        FROM xx_crm_wc_cust_dcca_int);

      SELECT COUNT (*)
        INTO ln_contact_err_cnt
        FROM xxod_hz_imp_contactpts_stg CONTPTS
       WHERE CONTPTS.interface_status = '6' AND CONTPTS.batch_id IN (SELECT UNIQUE batch_id
                                                                              FROM xx_crm_wc_cust_dcca_int);

      IF ln_collector_err_cnt != 0
      THEN
         gc_error_debug := 'Calling the OD : WC to Oracle CDH - Inbound -  Collector Error Program';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         ln_ftp_request_id := fnd_request.submit_request ('XXCRM'
                                                         ,'XX_CRM_COLLECTOR_ERRORS'
                                                         ,''
                                                         ,''
                                                         ,FALSE
                                                         );
         COMMIT;

         IF ln_ftp_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is not submitted');
            p_retcode := 2;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is submitted successfully');
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program request id is:' || ln_ftp_request_id);
         END IF;
      ELSE
         fnd_file.put_line (fnd_file.LOG, '  ');
         fnd_file.put_line (fnd_file.LOG, 'No error records found today for collectors');
         fnd_file.put_line (fnd_file.LOG, '  ');
      END IF;

      IF ln_contact_err_cnt != 0
      THEN
         gc_error_debug := 'Calling the OD : WC to Oracle CDH - Inbound -  Contact Errors Program';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         ln_ftp_request_id := fnd_request.submit_request ('XXCRM'
                                                         ,'XX_CRM_CONTACT_ERRORS'
                                                         ,''
                                                         ,''
                                                         ,FALSE
                                                         );
         COMMIT;

         IF ln_ftp_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is not submitted');
            p_retcode := 2;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program is submitted successfully');
            fnd_file.put_line (fnd_file.LOG, 'OD: Concurrent Request Output Emailer Program request id is:' || ln_ftp_request_id);
         END IF;
      ELSE
         fnd_file.put_line (fnd_file.LOG, '  ');
         fnd_file.put_line (fnd_file.LOG, 'No error records found today for contacts');
         fnd_file.put_line (fnd_file.LOG, '  ');
      END IF;

      p_retcode := ln_retcode;
      gc_error_debug := 'End of validating data procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   --End of validate_data procedure
   END validate_data;
--End of xx_crm_wc_cust_inbound_pkg Package Body
END xx_crm_wc_cust_inbound_pkg;
/

SHOW ERRORS;
