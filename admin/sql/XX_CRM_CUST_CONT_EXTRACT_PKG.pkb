
CREATE OR REPLACE PACKAGE BODY xx_crm_cust_cont_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_CONT_EXTRACT_PKG                           |
--|RICE        : 106313                                                 |
--|Description :This Package is used for insert data into staging       |
--|             table and fetch data from staging table to flat file    |
--|                                                                     |
--|            The STAGING Procedure will perform the following steps   |
--|                                                                     |
--|             1.It will fetch the records into staging table. The     |
--|               data will be either full or incremental               |
--|                                                                     |
--|             EXTRACT STAGING procedure will perform the following    |
--|                steps                                                |
--|                                                                     |
--|              1.It will fetch the staging table data to flat file    |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--|1.0      30-Aug-2011   Balakrishna Bolikonda      Initial Version    |
--|1.1      10-May-2012   Jay Gupta               Defect 18387 - Add    |
--|                                            Request_id in LOG tables |
--|1.2      11-Nov-2015   Havish Kasina        Removed the Schema References|
--|                                            as per R12.2 Retrofit Changes|
--/1.3     28-MAY-2016    Sridhar Pamu         Modified the select stmt in
--/                                           insert_incrdata to fix performance issue
--/                                           Defect 37965
--/1.4    07-JUL-2016    Sridhar Pamu         Included Parallel thread processing for
--/                                           defect 37771 . Added new procedure
--/                                           insert_incrdata_child to call child programs
--+=====================================================================+

   -- +===============================================================================+
-- | Name       : write_log                                                        |
-- |                                                                               |
-- | Description: This procedure is used to to display detailed                    |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_debug_flag                                                     |
-- |              p_msg                                                            |
-- |                                                                               |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE write_log (p_debug_flag IN VARCHAR2, p_msg IN VARCHAR2)
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
      p_compute_stats   IN   VARCHAR2,
      p_schema          IN   VARCHAR2,
      p_tablename       IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_compute_stats = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Gathering table stats');
         fnd_stats.gather_table_stats (ownname      => p_schema,
                                       tabname      => p_tablename
                                      );
      END IF;
   END compute_stats;

--+==================================================================+
--|Name        :insert_fulldata                                      |
--|Description :This procedure is used to fetch the total data       |
--|             from base tables to staging table                    |
--|                                                                  |
--|                                                                  |
--|Parameters : p_batch_limit                                        |
--|                                                                  |
--|                                                                  |
--|Returns    : p_retcode                                            |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE insert_fulldata (p_batch_limit IN NUMBER, p_retcode OUT NUMBER)
   IS
      --Variable declaration of Table type
      cm_full_tbl_type   lt_cust_contacts;
      --variable declaration
      ln_batch_limit     NUMBER;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_fulldata
      IS
         SELECT /*+ ORDERED FULL(HRR) USE_NL(HR) index(hr XXHZ_RELATIONSHIPS_N10) */
                org_cont.orig_system_reference "CONT_OSR",
                xcec.cust_account_id, hcsua.site_use_id,
                org_cont.contact_number,
                SUBSTRB (hp.person_last_name, 1, 50) last_name,
                SUBSTRB (hp.person_first_name, 1, 40) first_name,
                NVL
                   (arpt_sql_func_util.get_lookup_meaning
                                                      ('RESPONSIBILITY',
                                                       org_cont.job_title_code
                                                      ),
                    org_cont.job_title
                   ) "JOB_TITLE",
                hcp.email_address "email_address",
                hcp.contact_point_purpose "cont_point_purpose",
                hcp.primary_flag "contact_point_primary_flag",
                hrr.primary_flag "contact_role_primary flag",
                hcp.contact_point_type, hcp.phone_line_type,
                hcp.phone_country_code "country_code",
                hcp.phone_area_code "area_code", hcp.phone_number,
                hcp.phone_extension "exension",
                hcas.orig_system_reference "SITE_OSR",
                hcp.orig_system_reference "CONT_POINT_OSR",
                gn_last_updated_by "last_updated_by",
                gd_creation_date "creation_date", gn_request_id "request_id",
                gn_created_by "created_by",
                gd_last_update_date "last_update_date",
                gn_program_id "program_id"
           FROM xx_crm_wcelg_cust xcec,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsua,
                hz_cust_account_roles hcar,
                hz_role_responsibility hrr,
                hz_contact_points hcp,
                hz_relationships hr,
                hz_org_contacts org_cont,
                hz_parties hp
          WHERE xcec.cust_account_id = hcas.cust_account_id
            AND hcas.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hcsua.site_use_code = 'BILL_TO'
            AND hp.party_id = hr.subject_id
            AND hcar.party_id = hr.party_id
            AND hrr.responsibility_type = 'DUN'
            AND hcar.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hrr.cust_account_role_id = hcar.cust_account_role_id
            AND hr.subject_type = 'PERSON'
            AND hr.relationship_id = org_cont.party_relationship_id
            AND hcar.status = 'A'
            AND hrr.primary_flag = 'Y'
            AND hcar.party_id = hcp.owner_table_id
            AND hcp.owner_table_name = 'HZ_PARTIES'
            AND hcp.status = 'A'
            --AND HCP.contact_point_purpose = 'DUNNING'
            AND xcec.cust_cont_ext IN ('N');
   BEGIN
      gc_error_debug :=
            'Start Extracting full data from customer base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug :=
            'Before truncating staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custcont_stg';

      --Cursor Loop started here
      gc_error_debug := NULL;
      ln_batch_limit := p_batch_limit;
      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      OPEN lcu_fulldata;

      LOOP
         FETCH lcu_fulldata
         BULK COLLECT INTO cm_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_full_tbl_type.COUNT
            INSERT INTO xx_crm_custcont_stg
                 VALUES cm_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_fulldata%NOTFOUND;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug :=
            'Total number of Records inserted into the Staging table are: '
         || lcu_fulldata%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');

      --Cursor Loop ended here
      CLOSE lcu_fulldata;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);
      --Gathering table stats
      compute_stats (gc_compute_stats, 'XXCRM', 'XX_CRM_CUSTCONT_STG');
      gc_error_debug :=
            'End of Extracting Full data from customer base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug :=
               SQLCODE
            || ' No data found exception is raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug :=
               SQLERRM
            || ' Others exception is raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_fulldata_proc procedure
   END insert_fulldata;

--+==================================================================+
--|Name        :extract_stagedata                                    |
--|Description :This procedure is used to fetch the staging table    |
--|             data to flat file                                    |
--|                                                                  |
--|                                                                  |
--|Parameters :                                                      |
--|               p_debug_flag                                       |
--|               p_compute_stats                                    |
--|Returns    :   p_errbuf                                           |
--|               p_retcode                                          |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE extract_stagedata (
      p_errbuf          OUT      VARCHAR2,
      p_retcode         OUT      NUMBER,
      p_debug_flag      IN       VARCHAR2,
      p_compute_stats   IN       VARCHAR2
   )
   IS
      --Variable declaration
      lc_filehandle           UTL_FILE.file_type;
      lc_filepath             VARCHAR2 (500);
      lc_filename             VARCHAR2 (100);
      lc_message              VARCHAR2 (32767);
      lc_message1             VARCHAR2 (4000);
      lc_mode                 VARCHAR2 (1)       := 'W';
      ln_linesize             NUMBER;
      lc_comma                VARCHAR2 (2);
      ln_batch_limit          NUMBER;
      ln_count                NUMBER             := 0;
      ln_total_count          NUMBER             := 0;
      ln_fno                  NUMBER             := 1;
      ln_no_of_records        NUMBER;
      lc_debug_flag           VARCHAR2 (2);
      lc_compute_stats        VARCHAR2 (2);
      lc_destination_path     VARCHAR2 (500);
      ln_ftp_request_id       NUMBER;
      lc_archive_directory    VARCHAR2 (500);
      lc_source_path          VARCHAR2 (500);
      ln_idx                  NUMBER             := 1;
      ln_idx2                 NUMBER             := 1;
      lc_phase                VARCHAR2 (200);
      lc_status               VARCHAR2 (200);
      lc_dev_phase            VARCHAR2 (200);
      lc_dev_status           VARCHAR2 (200);
      lc_message2             VARCHAR2 (200);
      ln_retcode              NUMBER             := 0;
      ln_rec_count            NUMBER             := 0;
      --Table type declaration
      cm_stage_tbl_type       lt_cust_contacts;
      req_id_tbl_type         lt_req_id;
      file_names_tbl_type     lt_file_names;
      ln_request_id_p         NUMBER             DEFAULT 0;
      ln_program_name         VARCHAR2 (100);
      ln_program_short_name   VARCHAR2 (60);

      --cursor declaration: This is used to fetech the staging table data
      CURSOR lcu_customer_contacts
      IS
         SELECT cont.cont_osr, cont.cust_account_id, cont.site_use_id,
                cont.contact_number, cont.last_name, cont.first_name,
                cont.job_title, cont.email_address, cont.cont_point_purpose,
                cont.cont_point_primary_flag, cont.contact_role_primary_flag,
                cont.contact_point_type, cont.phone_line_type,
                cont.country_code, cont.area_code, cont.phone_number,
                cont.extension, cont.site_osr, cont.cont_point_osr,
                cont.last_updated_by, cont.creation_date, cont.request_id,
                cont.created_by, cont.last_update_date, cont.program_id
           FROM xx_crm_custcont_stg cont;
   BEGIN
      lc_debug_flag := p_debug_flag;
      lc_compute_stats := p_compute_stats;
      gc_error_debug :=
            'Start Extracting Staging table data into flat file'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);

      BEGIN
         SELECT xftv.target_value1, xftv.target_value2,
                   xftv.target_value4
                || '_'
                || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS'),
                xftv.target_value7, xftv.target_value8, xftv.target_value9,
                xftv.target_value11, xftv.target_value12
           INTO ln_batch_limit, lc_comma,
                gc_filename,
                ln_linesize, lc_filepath, ln_no_of_records,
                lc_destination_path, lc_archive_directory
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'CUST_CONTACTS'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug :=
                'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT ad.directory_path
           INTO lc_source_path
           FROM all_directories ad
          WHERE directory_name = lc_filepath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug :=
               'NO data found while selecting source path from translation defination';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO gn_nextval
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug :=
                   SQLERRM || 'Exception raised while getting sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      ln_request_id_p := fnd_global.conc_request_id ();

      SELECT a.program, a.program_short_name
        INTO ln_program_name, ln_program_short_name
        FROM fnd_conc_req_summary_v a
       WHERE a.request_id = ln_request_id_p;

      fnd_file.put_line (fnd_file.LOG,
                         '********** Customer Contacts Stage File **********'
                        );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG,
                         '   Compute stats is:' || lc_compute_stats
                        );
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG,
                         'Parameters derived from Translation Definition:'
                        );
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG,
                         '   Bulk collect Limit is :' || ln_batch_limit
                        );
      fnd_file.put_line (fnd_file.LOG,
                         '   Line Size limit is :' || ln_linesize
                        );
      fnd_file.put_line (fnd_file.LOG,
                         '   Source File Path is :' || lc_source_path
                        );
      fnd_file.put_line (fnd_file.LOG,
                         '   Destination File Path is :'
                         || lc_destination_path
                        );
      fnd_file.put_line (fnd_file.LOG,
                         '   Archive File Path is :' || lc_archive_directory
                        );
      fnd_file.put_line (fnd_file.LOG, '   Delimiter is :' || lc_comma);
      fnd_file.put_line (fnd_file.LOG,
                         '   No of records per File :' || ln_no_of_records
                        );

      SELECT COUNT (*)
        INTO ln_rec_count
        FROM xx_crm_custcont_stg;

      IF ln_rec_count = 0
      THEN
         gc_error_debug := 'No record found today';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         ln_retcode := 1;
      END IF;

      lc_filename := gc_filename || '-' || ln_fno || '.dat';
      lc_filehandle :=
               UTL_FILE.fopen (lc_filepath, lc_filename, lc_mode, ln_linesize);
      file_names_tbl_type (ln_idx) := lc_filename;
      ln_idx2 := ln_idx2 + 1;
      --Gathering table stats
      compute_stats (lc_compute_stats, 'XXCRM', 'XX_CRM_CUSTCONT_STG');
      --Cursor loop started here
      gc_error_debug := 'Loop started here';
      write_log (gc_debug_flag, gc_error_debug);

      OPEN lcu_customer_contacts;

      LOOP
         FETCH lcu_customer_contacts
         BULK COLLECT INTO cm_stage_tbl_type LIMIT ln_batch_limit;

         FOR i IN 1 .. cm_stage_tbl_type.COUNT
         LOOP
            lc_message :=
               xx_ar_wc_utility_pkg.remove_special_characters
                           (   cm_stage_tbl_type (i).cont_osr
                            || lc_comma
                            || cm_stage_tbl_type (i).cust_account_id
                            || lc_comma
                            || cm_stage_tbl_type (i).site_use_id
                            || lc_comma
                            || cm_stage_tbl_type (i).contact_number
                            || lc_comma
                            || cm_stage_tbl_type (i).last_name
                            || lc_comma
                            || cm_stage_tbl_type (i).first_name
                            || lc_comma
                            || cm_stage_tbl_type (i).job_title
                            || lc_comma
                            || cm_stage_tbl_type (i).email_address
                            || lc_comma
                            || cm_stage_tbl_type (i).cont_point_purpose
                            || lc_comma
                            || cm_stage_tbl_type (i).cont_point_primary_flag
                            || lc_comma
                            || cm_stage_tbl_type (i).contact_role_primary_flag
                            || lc_comma
                            || cm_stage_tbl_type (i).contact_point_type
                            || lc_comma
                            || cm_stage_tbl_type (i).phone_line_type
                            || lc_comma
                            || cm_stage_tbl_type (i).country_code
                            || lc_comma
                            || cm_stage_tbl_type (i).area_code
                            || lc_comma
                            || cm_stage_tbl_type (i).phone_number
                            || lc_comma
                            || cm_stage_tbl_type (i).extension
                            || lc_comma
                            || cm_stage_tbl_type (i).site_osr
                            || lc_comma
                            || cm_stage_tbl_type (i).cont_point_osr
                           );
            UTL_FILE.put_line (lc_filehandle, lc_message);
            --Incrementing count of records in the file and total records fethed on particular day
            ln_count := ln_count + 1;
            ln_total_count := ln_total_count + 1;

            UPDATE xx_crm_wcelg_cust
               SET cust_cont_ext = 'Y'
             WHERE cust_account_id = cm_stage_tbl_type (i).cust_account_id
               AND cust_cont_ext = 'N';

            IF ln_count >= ln_no_of_records
            THEN
               lc_message1 := ' ';
               UTL_FILE.put_line (lc_filehandle, lc_message1);
               lc_message1 :=
                             'Total number of records extracted:' || ln_count;

               INSERT INTO xx_crmar_file_log
                           (program_id, program_name, program_run_date,
                            filename, total_records, status,
                            request_id               -- V1.1, Added request_id
                           )
                    VALUES (gn_nextval, ln_program_name, SYSDATE,
                            lc_filename, ln_count, 'SUCCESS',
                            fnd_global.conc_request_id
                           -- V1.1, Added request_id
                           );

               UTL_FILE.put_line (lc_filehandle, lc_message1);
               UTL_FILE.fclose (lc_filehandle);
               ln_count := 0;
               ln_fno := ln_fno + 1;
               lc_filename := gc_filename || '-' || ln_fno || '.dat';
               file_names_tbl_type (ln_idx) := lc_filename;
               ln_idx2 := ln_idx2 + 1;
               lc_filehandle :=
                  UTL_FILE.fopen (lc_filepath,
                                  lc_filename,
                                  lc_mode,
                                  ln_linesize
                                 );
            END IF;
         END LOOP;

         EXIT WHEN lcu_customer_contacts%NOTFOUND;
      END LOOP;

      COMMIT;
      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      --Cursor loop ended here
      CLOSE lcu_customer_contacts;

      lc_message1 := ' ';
      UTL_FILE.put_line (lc_filehandle, lc_message1);
      lc_message1 := 'Total number of records extracted:' || ln_count;

      INSERT INTO xx_crmar_file_log
                  (program_id, program_name, program_run_date, filename,
                   total_records, status,
                   request_id                        -- V1.1, Added request_id
                  )
           VALUES (gn_nextval, ln_program_name, SYSDATE, lc_filename,
                   ln_count, 'SUCCESS',
                   fnd_global.conc_request_id        -- V1.1, Added request_id
                  );

      UTL_FILE.put_line (lc_filehandle, lc_message1);
      UTL_FILE.fclose (lc_filehandle);

      --Summary data inserting into log table
      INSERT INTO xx_crmar_int_log
                  (program_run_id, program_name, program_short_name,
                   module_name, program_run_date, filename, total_files,
                   total_records, status, MESSAGE,
                   request_id                        -- V1.1, Added request_id
                  )
           VALUES (gn_nextval, ln_program_name, ln_program_short_name,
                   gc_module_name, SYSDATE, lc_filename, ln_fno,
                   ln_total_count, 'SUCCESS', 'File generated',
                   ln_request_id_p                   -- V1.1, Added request_id
                  );

      FOR i IN file_names_tbl_type.FIRST .. file_names_tbl_type.LAST
      LOOP
         -- Start of FTP Program
         gc_error_debug :=
            'Calling the Common File Copy to move the output file to ftp directory';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         ln_ftp_request_id :=
            fnd_request.submit_request
                                ('XXFIN',
                                 'XXCOMFILCOPY',
                                 '',
                                 '',
                                 FALSE,
                                    lc_source_path
                                 || '/'
                                 || file_names_tbl_type (i) --Source File Name
                                                           ,
                                    lc_destination_path
                                 || '/'
                                 || file_names_tbl_type (i)   --Dest File Name
                                                           ,
                                 '',
                                 '',
                                 'Y'                --Deleting the Source File
                                    ,
                                 lc_archive_directory --Archive directory path
                                );
         COMMIT;

         IF ln_ftp_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Common File copy Program is not submitted'
                              );
            p_retcode := 2;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            req_id_tbl_type (ln_idx) := ln_ftp_request_id;
            ln_idx := ln_idx + 1;
         END IF;
      -- End of FTP Program
      END LOOP;

      --req_id_tbl_type Loop started here
      FOR i IN req_id_tbl_type.FIRST .. req_id_tbl_type.LAST
      LOOP
         IF fnd_concurrent.wait_for_request (req_id_tbl_type (i),
                                             30,
                                             0,
                                             lc_phase,
                                             lc_status,
                                             lc_dev_phase,
                                             lc_dev_status,
                                             lc_message2
                                            )
         THEN
            IF UPPER (lc_status) = 'ERROR'
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Common File copy program for File '
                                  || i
                                  || ' completed with error'
                                 );
               p_retcode := 2;
            ELSIF UPPER (lc_status) = 'WARNING'
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Common File copy program for File '
                                  || i
                                  || ' completed with warning'
                                 );
               p_retcode := 1;
            ELSE
               fnd_file.put_line (fnd_file.LOG,
                                     'Common File copy program for File '
                                  || i
                                  || ' completed normal'
                                 );
               p_retcode := 0;
            END IF;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         END IF;
      --req_id_tbl_type Loop Ended here
      END LOOP;

      p_retcode := ln_retcode;
      gc_error_debug := 'Total no of records fetched : ' || ln_total_count;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Program run date:' || SYSDATE;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug :=
            'End Extracting Staging table data into flat file'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
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
   --End of extract_stagedata
   END extract_stagedata;

   PROCEDURE insert_incrdata (p_batch_limit IN NUMBER, p_retcode OUT NUMBER)
   IS
      --Table type declaration
      cm_incr_tbl_type        lt_cust_contacts;
      --variable declaration
      ln_batch_limit          NUMBER;
      l_currdt                DATE;
      l_rundt                 DATE;
      l_count                 NUMBER;
      l_range                 NUMBER;
      v_stmt                  VARCHAR2 (200);
      l_parent_sid            NUMBER;
      v_jobno                 NUMBER;
      v_running_jobs          NUMBER;
      v_expected              NUMBER;
      v_actual                NUMBER;
      v_in_degree             NUMBER;
      min_record              NUMBER;
      max_record              NUMBER;
      l_batch_id              NUMBER;
      lv_phase                VARCHAR2 (20);
      lv_status               VARCHAR2 (20);
      lv_dev_phase            VARCHAR2 (20);
      lv_dev_status           VARCHAR2 (20);
      lv_message1             VARCHAR2 (20);
      ln_request_id           NUMBER           := 0;
      lb_result               BOOLEAN;

      TYPE num_array IS TABLE OF NUMBER
         INDEX BY BINARY_INTEGER;

      ln_header_cnt           NUMBER           := 0;
      l_child_conc            VARCHAR2 (50);
      l_degree                NUMBER;
      ln_request_id_p         NUMBER           DEFAULT 0;
      ln_program_name         VARCHAR2 (100);
      ln_program_short_name   VARCHAR2 (60);
      ln_nextval              NUMBER           DEFAULT 0;
      req_array               num_array;
      ln_request_number       NUMBER           := 0;

      --cursor declaration: This is used to fetch the incremental customer  contacts  data from base tables
      CURSOR lcu_incremental
      IS
         SELECT ROWNUM record_id, cust_account_id
           FROM (SELECT DISTINCT cust_account_id
                            FROM xx_crm_common_delta a
                           WHERE content_type IN
                                    ('HZ_CUST_ACCOUNTS',
                                     'HZ_CUST_ACCT_SITES_ALL',
                                     'HZ_CUST_SITE_USES_ALL',
                                     'HZ_ORG_CONTACTS',
                                     'HZ_CONTACT_POINTS'
                                    )
                 UNION
                 SELECT DISTINCT cust_account_id
                            FROM xx_crm_wcelg_cust a
                           WHERE cust_cont_ext = 'N');
   BEGIN
      gc_error_debug :=
            'Start Extracting Incremental data from customer contacts  base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating staging table';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custcont_stg';

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_cust_contid_stg';

-- Inserting cust_account_id into staging table start
      FOR accountid_cont IN lcu_incremental
      LOOP
         BEGIN
            INSERT INTO xx_crm_cust_contid_stg
                        (record_id,
                         cust_account_id
                        )
                 VALUES (accountid_cont.record_id,
                         accountid_cont.cust_account_id
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Account ID:'
                                  || accountid_cont.cust_account_id
                                  || ' Could Not be Inserted'
                                  || '::'
                                  || SQLERRM
                                 );
         END;

         COMMIT;
      END LOOP;

-- Inserting cust_account_id into staging table end

      -- Parallel thread degree and child conc program name start
      SELECT xftv.target_value14, xftv.target_value16
        INTO l_degree, l_child_conc
        FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND xftv.source_value1 = 'CUST_CONTACTS'
         AND SYSDATE BETWEEN xftv.start_date_active
                         AND NVL (xftv.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN xftd.start_date_active
                         AND NVL (xftd.end_date_active, SYSDATE + 1)
         AND xftv.enabled_flag = 'Y'
         AND xftd.enabled_flag = 'Y';

-- Parallel thread degree and child conc program name end

      -- Parallel thread start
      SELECT   NVL (MAX (TO_NUMBER (record_id)), -1)--- remove t_number and give only max and min
             - NVL (MIN (TO_NUMBER (record_id)), 0)
             + 1,
             NVL (MIN (TO_NUMBER (record_id)), 0),
             NVL (MAX (TO_NUMBER (record_id)), 0)
        INTO l_count,
             min_record,
             max_record
        FROM xx_crm_cust_contid_stg;

      l_currdt := SYSDATE;
      l_range := CEIL (l_count / l_degree);

      FOR i IN 1 .. (l_degree - 1)
      LOOP
-- ---------------------------------------------------------
-- Call the custom concurrent program for parallel execution
-- ---------------------------------------------------------  

----- begin end exception
         ln_request_id :=
            fnd_request.submit_request (application      => 'XXCRM',
                                        program          => l_child_conc,
                                        sub_request      => FALSE,
                                        argument1        => (TO_CHAR
                                                                 (  min_record
                                                                  + (  l_range
                                                                     * (i - 1
                                                                       )
                                                                    )
                                                                 )
                                                            ),
                                        argument2        => (TO_CHAR
                                                                 (  min_record
                                                                  + (    l_range
                                                                       * i
                                                                     - 1
                                                                    )
                                                                 )
                                                            )
                                       );
         req_array (i) := ln_request_id;
         
         
        /* (TO_CHAR
                                                                (  min_record
                                                                 + (    (l_range * i)
                                                                    - 1
                                                                   )
                                                                )
                                                           )
*/
         IF ln_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'could not submit the child request at '
                               || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                              );
         END IF;                                          -- ln_request_id = 0

         ln_request_number := i;
      END LOOP;

      ln_request_id :=
         fnd_request.submit_request (application      => 'XXCRM',
                                     program          => l_child_conc,
                                     sub_request      => FALSE,
                                     argument1        => (TO_CHAR
                                                               (  min_record
                                                                + (    l_range
                                                                     * (  l_degree
                                                                        - 1
                                                                       )
                                                                   - 1
                                                                  )
                                                                + 1
                                                               )
                                                         ),
                                     argument2        => (max_record)
                                    );
      ln_request_number := ln_request_number + 1;
      req_array (ln_request_number) := ln_request_id;

      IF ln_request_id = 0
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'could not submit the child request at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
      END IF;

      COMMIT;
      v_running_jobs := 1;

      WHILE v_running_jobs > 0
      LOOP
         DBMS_LOCK.sleep (60);
         v_running_jobs := 0;

         FOR i IN req_array.FIRST .. req_array.LAST
         LOOP
            lb_result :=
               fnd_concurrent.wait_for_request (req_array (i),
                                                10,
                                                0,
                                                lv_phase,
                                                lv_status,
                                                lv_dev_phase,
                                                lv_dev_status,
                                                lv_message1
                                               );

            IF lv_dev_phase = 'COMPLETE'
            THEN
               NULL;
            ELSE
               v_running_jobs := v_running_jobs + 1;
            END IF;
         END LOOP;
      END LOOP;

-- Parallel thread end
      SELECT COUNT (*)
        INTO ln_header_cnt
        FROM xx_crm_custcont_stg;

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO ln_nextval
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug :=
                   SQLERRM || 'Exception raised while getting sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      ln_request_id_p := fnd_global.conc_request_id ();

      SELECT a.program, a.program_short_name
        INTO ln_program_name, ln_program_short_name
        FROM fnd_conc_req_summary_v a
       WHERE a.request_id = ln_request_id_p;

      INSERT INTO xx_crmar_int_log
                  (program_run_id, program_name, program_short_name,
                   module_name, program_run_date, filename, total_files,
                   total_records, status, MESSAGE,
                   request_id                        -- V1.1, Added request_id
                  )
           VALUES (ln_nextval, ln_program_name, ln_program_short_name,
                   gc_module_name, SYSDATE, '', 0,
                   ln_header_cnt, 'SUCCESS', 'Processed',
                   ln_request_id_p                   -- V1.1, Added request_id
                  );

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug :=
            'Total number of Records inserted into the Staging table are: '
         || ln_header_cnt;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug :=
         'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);
      gc_error_debug :=
            'End Extracting Incremental data from customer contacts base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug :=
               SQLCODE
            || ' No data found while fetching incremental data from customer contacts base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug :=
               SQLERRM
            || ' Others exception raised while fetching full data from customer contacts base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_incrdata
   END insert_incrdata;

   --+==================================================================+
--|Name        :insert_incrdata                                      |
--|Description :This procedure is used to fetch the incremental data |
--|              from base tables to staging table                   |
--|                                                                  |
--|                                                                  |
--|Parameters : p_batch_limit                                        |
--|                                                                  |
--|                                                                  |
--|Returns    : p_retcode                                            |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE insert_incrdata_child (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_in_low    IN              NUMBER,
      p_in_high   IN              NUMBER
   )
   IS
      --Table type declaration
      cm_incr_tbl_type        lt_cust_contacts;
      --variable declaration
      ln_batch_limit          NUMBER;
      ln_cont_cnt             NUMBER           := 0;
      ln_request_id_p         NUMBER           DEFAULT 0;
      ln_program_name         VARCHAR2 (100);
      ln_program_short_name   VARCHAR2 (60);
      ln_nextval              NUMBER           DEFAULT 0;

      --cursor declaration: This is used to fetch the incremental customer master data from base tables
      CURSOR lcu_incremental (p_in_low NUMBER, p_in_high NUMBER)
      IS
         SELECT /*+ parallel(6) full(HCAR) */
                org_cont.orig_system_reference "CONT_OSR",
                hcar.cust_account_id, hcsua.site_use_id,
                org_cont.contact_number,
                SUBSTRB (hp.person_last_name, 1, 50) last_name,
                SUBSTRB (hp.person_first_name, 1, 40) first_name,
                NVL
                   (arpt_sql_func_util.get_lookup_meaning
                                                      ('RESPONSIBILITY',
                                                       org_cont.job_title_code
                                                      ),
                    org_cont.job_title
                   ) "JOB_TITLE",
                hcp.email_address "email_address",
                hcp.contact_point_purpose "cont_point_purpose",
                hcp.primary_flag "contact_point_primary_flag",
                hrr.primary_flag "contact_role_primary flag",
                hcp.contact_point_type, hcp.phone_line_type,
                hcp.phone_country_code "country_code",
                hcp.phone_area_code "area_code", hcp.phone_number,
                hcp.phone_extension "exension",
                hcas.orig_system_reference "SITE_OSR",
                hcp.orig_system_reference "CONT_POINT_OSR",
                gn_last_updated_by "last_updated_by",
                gd_creation_date "creation_date", gn_request_id "request_id",
                gn_created_by "created_by",
                gd_last_update_date "last_update_date",
                gn_program_id "program_id"
           FROM hz_cust_account_roles hcar,
                hz_role_responsibility hrr,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsua,
                hz_parties hp,
                hz_relationships hr,
                hz_org_contacts org_cont,
                hz_contact_points hcp,
                xx_crm_cust_contid_stg xstg
          WHERE hcar.cust_account_id = xstg.cust_account_id
            AND hcar.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hcas.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hcsua.site_use_code = 'BILL_TO'
            AND hp.party_id = hr.subject_id
            AND hcar.party_id = hr.party_id
            AND hrr.cust_account_role_id = hcar.cust_account_role_id
            AND hrr.responsibility_type = 'DUN'
            AND hr.subject_type = 'PERSON'
            AND hr.relationship_id = org_cont.party_relationship_id
            AND hcar.status = 'A'
            AND hrr.primary_flag = 'Y'
            AND hcar.party_id = hcp.owner_table_id
            AND hcp.status = 'A'
            AND xstg.record_id BETWEEN p_in_low AND p_in_high
         --AND HCP.contact_point_purpose = 'DUNNING'
         UNION
         SELECT /*+ LEADING(XCEC) parallel(6) full(hcar) */
                org_cont.orig_system_reference "CONT_OSR",
                xcec.cust_account_id, hcsua.site_use_id,
                org_cont.contact_number,
                SUBSTRB (hp.person_last_name, 1, 50) last_name,
                SUBSTRB (hp.person_first_name, 1, 40) first_name,
                NVL
                   (arpt_sql_func_util.get_lookup_meaning
                                                      ('RESPONSIBILITY',
                                                       org_cont.job_title_code
                                                      ),
                    org_cont.job_title
                   ) "JOB_TITLE",
                hcp.email_address "email_address",
                hcp.contact_point_purpose "cont_point_purpose",
                hcp.primary_flag "contact_point_primary_flag",
                hrr.primary_flag "contact_role_primary flag",
                hcp.contact_point_type, hcp.phone_line_type,
                hcp.phone_country_code "country_code",
                hcp.phone_area_code "area_code", hcp.phone_number,
                hcp.phone_extension "exension",
                hcas.orig_system_reference "SITE_OSR",
                hcp.orig_system_reference "CONT_POINT_OSR",
                gn_last_updated_by "last_updated_by",
                gd_creation_date "creation_date", gn_request_id "request_id",
                gn_created_by "created_by",
                gd_last_update_date "last_update_date",
                gn_program_id "program_id"
           FROM xx_crm_wcelg_cust xcec,
                xx_crm_cust_contid_stg xstg,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsua,
                hz_parties hp,
                hz_cust_account_roles hcar,
                hz_relationships hr,
                hz_org_contacts org_cont,
                hz_role_responsibility hrr,
                hz_contact_points hcp
          WHERE xcec.cust_cont_ext = 'N'
            AND hcar.cust_account_id = xstg.cust_account_id
            AND xcec.cust_account_id = hcas.cust_account_id
            AND hcas.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hcsua.site_use_code = 'BILL_TO'
            AND hp.party_id = hr.subject_id
            AND hcar.party_id = hr.party_id
            AND hrr.responsibility_type = 'DUN'
            AND hcar.cust_acct_site_id = hcsua.cust_acct_site_id
            AND hrr.cust_account_role_id = hcar.cust_account_role_id
            AND hr.subject_type = 'PERSON'
            AND hr.relationship_id = org_cont.party_relationship_id
            AND hcar.status = 'A'
            AND hrr.primary_flag = 'Y'
            AND hcar.party_id = hcp.owner_table_id
            AND hcp.status = 'A'
            AND xstg.record_id BETWEEN p_in_low AND p_in_high;
   --AND HCP.contact_point_purpose = 'DUNNING';
   BEGIN
      gc_error_debug :=
            'Start Extracting Incremental data from customer base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug :=
            'Before truncating staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      --cm_incremental curosr started here
      gc_error_debug := 'Loop started here';
      write_log (gc_debug_flag, gc_error_debug);

      BEGIN
         SELECT xftv.target_value1
           INTO ln_batch_limit
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'CUST_CONTACTS'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug :=
                  SQLERRM
               || 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      OPEN lcu_incremental (p_in_low, p_in_high);

      LOOP
         FETCH lcu_incremental
         BULK COLLECT INTO cm_incr_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_incr_tbl_type.COUNT
            INSERT INTO xx_crm_custcont_stg
                 VALUES cm_incr_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_incremental%NOTFOUND;
      END LOOP;

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO ln_nextval
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug :=
                   SQLERRM || 'Exception raised while getting sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      ln_cont_cnt := lcu_incremental%ROWCOUNT;

      SELECT COUNT (*)
        INTO ln_cont_cnt
        FROM xx_crm_custcont_stg;

      ln_request_id_p := fnd_global.conc_request_id ();

      SELECT a.program, a.program_short_name
        INTO ln_program_name, ln_program_short_name
        FROM fnd_conc_req_summary_v a
       WHERE a.request_id = ln_request_id_p;

      INSERT INTO xx_crmar_int_log
                  (program_run_id, program_name, program_short_name,
                   module_name, program_run_date, filename, total_files,
                   total_records, status, MESSAGE,
                   request_id                        -- V1.1, Added request_id
                  )
           VALUES (ln_nextval, ln_program_name, ln_program_short_name,
                   gc_module_name, SYSDATE, '', 0,
                   ln_cont_cnt, 'SUCCESS', 'Processed',
                   ln_request_id_p                   -- V1.1, Added request_id
                  );

      COMMIT;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug :=
            'Total number of Records inserted into the Staging table are: '
         || lcu_incremental%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Loop ended here';
      write_log (gc_debug_flag, gc_error_debug);

      --Curosr loop Ended here
      CLOSE lcu_incremental;

      --Gathering table stats
      compute_stats (gc_compute_stats, 'XXCRM', 'XX_CRM_CUSTCONT_STG');
      gc_error_debug :=
            'End Extracting Incremental data from customer base tables to staging table'
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug :=
               SQLCODE
            || ' No data found while fetching incremental data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug :=
               SQLERRM
            || ' Others exception raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_incrdata
   END insert_incrdata_child;

--End of XX_CRM_CUST_CONT_EXTRACT_PKG Package Body
--+==================================================================+
--|Name        : main                                                |
--|Description : This procedure is used to call the above three      |
--|              procedures. while registering concurrent            |
--|              program this procedure will be used                 |
--|                                                                  |
--|Parameters : p_actiontype                                         |
--|             p_debug_flag                                         |
--|             p_compute_stats                                      |
--|Returns    : NA                                                   |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2,
      p_retcode         OUT      NUMBER,
      p_action_type     IN       VARCHAR2,
      p_debug_flag      IN       VARCHAR2,
      p_compute_stats   IN       VARCHAR2
   )
   IS
      -- Variable Declaration
      lc_action_type   VARCHAR2 (2);
      ln_batch_limit   NUMBER;
      ln_retcode       NUMBER;
   BEGIN
      lc_action_type := p_action_type;
      gc_debug_flag := p_debug_flag;
      gc_compute_stats := p_compute_stats;

      BEGIN
         SELECT xftv.target_value1
           INTO ln_batch_limit
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'CUST_CONTACTS'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug :=
                  SQLERRM
               || 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      gn_count := 0;
      fnd_file.put_line (fnd_file.LOG,
                         '********** Customer Contacts Log File **********'
                        );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG, '   Action Type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG,
                         '   Compute stats is:' || gc_compute_stats
                        );
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG,
                         'Parameters derived from Translation Definition:'
                        );
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG,
                         '   Bulk collect Limit is :' || ln_batch_limit
                        );

      IF lc_action_type = 'F'
      THEN
         insert_fulldata (ln_batch_limit, ln_retcode);

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSIF lc_action_type = 'I'
      THEN
         insert_incrdata (ln_batch_limit, ln_retcode);

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSE
         gc_error_debug := 'Invalid parameter. Enter either F or I';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLERRM || 'NO data found in the main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug :=
                    SQLERRM || 'Others exception is raised in main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   -- End of the main procedure
   END main;
END xx_crm_cust_cont_extract_pkg;
/

SHOW errors;