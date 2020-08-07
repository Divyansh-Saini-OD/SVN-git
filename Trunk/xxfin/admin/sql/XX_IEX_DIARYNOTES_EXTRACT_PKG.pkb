create or replace
PACKAGE BODY XX_IEX_DIARYNOTES_EXTRACT_PKG
AS
   /*+=========================================================================+
   | Office Depot - Project FIT                                                |
   | Capgemini/Office Depot/Consulting Organization                            |
   +===========================================================================+
   |Name        : XX_IEX_DIARYNOTES_EXTRACT_PKG                                |
   |RICE        : I2159                                                        |
   |Description : This Package is used for inserting data into diary notes     |
   |              staging table and extract data from staging table to flat    |
   |              file. Then the file will be transferred to Webcollect        |
   |                                                                           |
   |Change Record:                                                             |
   |==============                                                             |
   |Version    Date         Author                Remarks                      |
   |========   ===========  ====================  =============================|
   |  1.0      18-OCT-2011  Gangi Reddy M         Initial Version              |
   |                                                                           |
   |  1.1      30-NOV-2011  Maheswararao N        Modified as per 11/29/11     |
   |                                              review                       |
   |  1.2      30-DEC-2011  Maheswararao N        Modified to fix defect#16025 |
   |                                                                           |
   |  1.3      25-JAN-2011  Maheswararao N        Modified to fix defect#16434 |
   |                                                                           |
   |  1.4      04-FEB-2012  R.Aldridge            Defect 16768 - Create new    | 
   |                                              utility to remove special    |
   |                                              characters                   |
   |                                                                           |
   |  1.5      13-FEB-2012  R.Aldridge            Defect 16234 - Performance   | 
   |                                              tuning for full daily and    |
   |                                              full initial conversion      |
   |                                                                           |
   |  1.5      13-FEB-2012  R.Aldridge            Defect 16234 - Additional    |
   |                                              Performance tuning           |
   |  1.7      21-May-2012  Jay Gupta             Defect#18336, Filename passed|
   |                                              in INT table is incorrect    |
   |  1.8      21-May-2012  Jay Gupta             Added Request_id,cycle_date  |
   |                                              and batch_num in LOG Tables  |
   |  1.9      12-Jun-2012  Deepti S              Defect#18427 Modified cursor |
   |                                              to include the account level |
   |                                              notes                        |
   |  2.0      18-Jun-2012  Jay Gupta             Defect#18336-batchnum in file|
   |  2.1      10-Jul-2012  Jay Gupta             Defect#19201-performa Change |
   |  2.2      11-Jul-2012  Jay Gupta             Excluded account level notes |
   |  2.3     09-11-2015   Shubashree R     R12.2  Compliance changes Defect# 36369 |
   +=========================================================================+*/
   -- Global Variable Declaration
   gd_last_update_date        DATE                                         := SYSDATE;
   gn_last_updated_by         NUMBER                                       := FND_GLOBAL.USER_ID;
   gd_creation_date           DATE                                         := SYSDATE;
   gn_created_by              NUMBER                                       := FND_GLOBAL.USER_ID;
   gn_request_id              NUMBER                                       := FND_GLOBAL.CONC_REQUEST_ID;
   gn_nextval                 NUMBER;
   gn_ret_code                NUMBER                                       := 0;
   gd_cycle_date              DATE;
   -- Variables for Interface Settings
   gn_limit                   NUMBER;
   gn_threads_delta           NUMBER;
   gn_threads_full            NUMBER;
   gn_threads_file            NUMBER;
   gc_conc_short_delta        xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full         xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file         xx_fin_translatevalues.target_value18%TYPE;
   gc_delimiter               xx_fin_translatevalues.target_value3%TYPE;
   gc_file_name               xx_fin_translatevalues.target_value4%TYPE;
   gc_email                   xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats           xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size               NUMBER;
   gc_file_path               xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records             NUMBER;
   gc_debug                   xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path           xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path          xx_fin_translatevalues.target_value12%TYPE;
   gn_full_num_days           NUMBER;
   gc_staging_table           xx_fin_translatevalues.target_value19%TYPE;
   gb_retrieved_trans         BOOLEAN                                      := FALSE;
   gc_err_msg_trans           VARCHAR2 (100)                               := NULL;
   gc_process_type            xx_ar_mt_wc_details.process_type%TYPE        := 'DIARY_NOTES';
   GC_YES                     VARCHAR2 (1)                                 := 'Y';
   gc_error_loc               VARCHAR2 (2000)                              := NULL;
   -- Variables for Cycle Date and Batch Cycle Settings
   gc_action_type             xx_ar_mt_wc_details.action_type%TYPE;
   gn_batch_num               xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute        BOOLEAN                                      := FALSE;
   gb_reprocessing_required   BOOLEAN                                      := FALSE;
   gb_retrieved_cntl          BOOLEAN                                      := FALSE;
   gc_err_msg_cntl            VARCHAR2 (100)                               := NULL;
   gc_post_process_status     VARCHAR (1)                                  := 'Y';
   gd_delta_from_date         DATE;
   gd_full_from_date          DATE;
   gd_control_to_date         DATE;
   gc_reprocess_cnt           NUMBER;
   gb_print_option            BOOLEAN;
   -- Custom Exceptions
   EX_NO_CONTROL_RECORD       EXCEPTION;
   EX_CYCLE_COMPLETED         EXCEPTION;
   EX_STAGING_COMPLETED       EXCEPTION;
   EX_INVALID_ACTION_TYPE     EXCEPTION;

   -- +====================================================================+
   -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE print_time_stamp_to_logfile
   IS
   BEGIN
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
   END;

   -- +====================================================================+
   -- | Name       : LOCATION_AND_LOG                                      |
   -- |                                                                    |
   -- | Description: This procedure is used to display detailed messages   |
   -- |               to log file                                          |
   -- |                                                                    |
   -- | Parameters : p_debug                                               |
   -- |              p_msg                                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE location_and_log (
      p_debug   VARCHAR2
     ,p_msg     VARCHAR2
   )
   IS
   BEGIN
      xx_ar_wc_utility_pkg.location_and_log (p_debug, p_msg);
   END location_and_log;

   /*=====================================================================================+
   | Name       : GET_INTERFACE_SETTINGS                                                 |
   | Description: This procedure is used to fetch the transalation definition details    |
   |                                                                                     |
   | Parameters : none                                                                   |
   |                                                                                     |
   | Returns    : none                                                                   |
   +=====================================================================================*/
   PROCEDURE get_interface_settings
   IS
   BEGIN
      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      xx_ar_wc_utility_pkg.get_interface_settings (p_process_type           => gc_process_type
                                                  ,p_bulk_limit             => gn_limit
                                                  ,p_delimiter              => gc_delimiter
                                                  ,p_num_threads_delta      => gn_threads_delta
                                                  ,p_file_name              => gc_file_name
                                                  ,p_email                  => gc_email
                                                  ,p_gather_stats           => gc_compute_stats
                                                  ,p_line_size              => gn_line_size
                                                  ,p_file_path              => gc_file_path
                                                  ,p_num_records            => gn_num_records
                                                  ,p_debug                  => gc_debug
                                                  ,p_ftp_file_path          => gc_ftp_file_path
                                                  ,p_arch_file_path         => gc_arch_file_path
                                                  ,p_full_num_days          => gn_full_num_days
                                                  ,p_num_threads_full       => gn_threads_full
                                                  ,p_num_threads_file       => gn_threads_file
                                                  ,p_child_conc_delta       => gc_conc_short_delta
                                                  ,p_child_conc_full        => gc_conc_short_full
                                                  ,p_child_conc_file        => gc_conc_short_file
                                                  ,p_staging_table          => gc_staging_table
                                                  ,p_retrieved              => gb_retrieved_trans
                                                  ,p_error_message          => gc_err_msg_trans
                                                  ,p_print_to_req_log       => 'Y'
                                                  );
      print_time_stamp_to_logfile;
   END get_interface_settings;

   /*+=============================================================================+
   | Name       : COMPUTE_STATS                                                    |
   |                                                                               |
   | Description: This procedure is used to to display detailed                    |
   |                     messages to log file                                      |
   |                                                                               |
   | Parameters : p_schema                                                         |
   |              p_tablename                                                      |
   | Returns    : none                                                             |
   +===============================================================================+*/
   PROCEDURE compute_stats (
      p_schema      IN   VARCHAR2
     ,p_tablename   IN   VARCHAR2
   )
   IS
   BEGIN
      FND_STATS.GATHER_TABLE_STATS (ownname      => p_schema, tabname => p_tablename);
   END compute_stats;

   /*+=============================================================================+
   |Name        :extract_stagedata                                                 |
   |Description :This procedure is used to fetch the staging table                 |
   |             data to flat file                                                 |
   |                                                                               |
   |Parameters : p_errcode OUT                                                     |
   |                                                                               |
   |Returns    : NA                                                                |
   +===============================================================================+*/
   PROCEDURE extract_stagedata (
      p_cycle_date   IN       DATE
     ,p_batch_num    IN       NUMBER
     ,p_errcode      OUT      NUMBER
   )
   IS
      -- local variable declaration
      lc_filehandle       UTL_FILE.file_type;
      lc_filename         VARCHAR2 (100);
      lc_file             VARCHAR2 (100)                := '_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS');
      lc_message          VARCHAR2 (4000);
      lc_message1         VARCHAR2 (4000);
      lc_mode             VARCHAR2 (1)         := 'W';
      ln_count            NUMBER               := 0;
      ln_count1           NUMBER               := 0;
      ln_fno              NUMBER               := 1;
      ln_total_count      NUMBER               := 0;
      ln_ftp_request_id   NUMBER;
      lc_source_path      VARCHAR2 (500);
      ln_idx              NUMBER               := 1;
      ln_idx2             NUMBER               := 1;
      lc_phase            VARCHAR2 (200);
      lc_status           VARCHAR2 (200);
      lc_dev_phase        VARCHAR2 (200);
      lc_dev_status       VARCHAR2 (200);
      lc_message2         VARCHAR2 (200);
      ln_retcode          NUMBER               := 0;
      lc_inst               VARCHAR2(5);
      -- V1.7
      lc_int_filename VARCHAR2(200);

      -- Declaration of Table type and variable
      cm_diarynotes_stg   diary_notes_tbl_type;
      lt_req_number       req_number_tbl_type;
      lt_file_name        file_name_tbl_type;

      -- This Cursor is used to fetch the staging table data
      CURSOR lcu_diary_notes
      IS
         SELECT note_id
               ,cust_account_id
               ,note_date
               ,status
               ,source_name
               ,bill_to_site_use_id
               ,contact_first_name
               ,contact_last_name
               ,action_code
               ,note_text
               ,attachements
               ,creation_date
               ,last_updated_by
               ,request_id
               ,created_by
               ,last_upadte_date
               ,p_cycle_date
               ,p_batch_num
           FROM xx_iex_diary_notes_stg;
   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing in extract_stagedata');
         p_errcode := 0;
         gn_limit := gn_limit;

         location_and_log (GC_YES, CHR (10)||'Capture Instance Name');
         SELECT substr(instance_name,4,5) 
           INTO lc_inst
           FROM v$instance;      

         BEGIN
            location_and_log (gc_debug, 'Getting the directory path from all_directories table at');

            SELECT AD.directory_path
              INTO lc_source_path
              FROM all_directories AD
             WHERE AD.directory_name = gc_file_path;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               location_and_log (GC_YES, 'NO data found while selecting source path from translation defination');
         END;
      END;                                                                                                                                                                     --  Initialize Processing

      print_time_stamp_to_logfile;

      BEGIN
         location_and_log (GC_YES, 'getting the count from diary notes stage table');

         SELECT COUNT (1)
           INTO ln_count1
           FROM xx_iex_diary_notes_stg;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            location_and_log (GC_YES, 'NO data found in getting count from diary notes stage table');
      END;

      --========================================================================
      -- Retrieve Data and Create Files
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieve Data and Create Files');
         -- V2.0 lc_filename := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
         lc_filename := gc_file_name || '_' || lc_inst || '_' || p_batch_num || lc_file || '-' || ln_fno || '.dat';         
         lt_file_name (ln_idx2) := lc_filename;
         ln_idx2 := ln_idx2 + 1;
         location_and_log (gc_debug, 'Before opening the ' || lc_filename || 'file ');
         lc_filehandle := UTL_FILE.fopen (gc_file_path
                                         ,lc_filename
                                         ,lc_mode
                                         ,gn_line_size
                                         );

         IF ln_count1 > 0
         THEN
            -- Cursor loop start
            location_and_log (GC_YES, 'Before opening the lcu_diary_notes cursor ');

            OPEN lcu_diary_notes;

            LOOP
               FETCH lcu_diary_notes
               BULK COLLECT INTO cm_diarynotes_stg LIMIT gn_limit;

               FOR i IN 1 .. cm_diarynotes_stg.COUNT
               LOOP
                  lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                        cm_diarynotes_stg (i).note_id
                     || gc_delimiter
                     || cm_diarynotes_stg (i).cust_account_id
                     || gc_delimiter
                     || cm_diarynotes_stg (i).note_date
                     || gc_delimiter
                     || cm_diarynotes_stg (i).status
                     || gc_delimiter
                     || cm_diarynotes_stg (i).source_name
                     || gc_delimiter
                     || cm_diarynotes_stg (i).bill_to_site_use_id
                     || gc_delimiter
                     || cm_diarynotes_stg (i).contact_last_name
                     || gc_delimiter
                     || cm_diarynotes_stg (i).contact_first_name
                     || gc_delimiter
                     || cm_diarynotes_stg (i).action_code
                     || gc_delimiter
                     || cm_diarynotes_stg (i).note_text
                     || gc_delimiter
                     || cm_diarynotes_stg (i).attachments);
                  UTL_FILE.put_line (lc_filehandle, lc_message);
                  ln_count := ln_count + 1;
                  ln_total_count := ln_total_count + 1;

                  IF (ln_count >= gn_num_records)
                  THEN
                     location_and_log (GC_YES, 'Generating a new file based on number of records for file limit ');
                     lc_message1 := ' ';
                     UTL_FILE.put_line (lc_filehandle, lc_message1);
                     lc_message1 := 'Total number of records extracted:' || ln_count;
                     location_and_log (GC_YES, 'Insert the file log into xx_crmar_file_log table inside the loop ');

                     INSERT INTO xx_crmar_file_log
                                 (program_id
                                 ,program_name
                                 ,program_run_date
                                 ,filename
                                 ,total_records
                                 ,status
                                 -- V1.8, Added request_id, cycle_date and batch_num
                                 ,request_id 
                                 ,cycle_date
                                 ,batch_num
                                 )
                          VALUES (gn_nextval
                                 ,'OD: IEX - Extract WC - Diary Notes'
                                 ,SYSDATE
                                 ,lc_filename
                                 ,ln_count
                                 ,'SUCCESS'
                                 , gn_request_id  
                                 , gd_cycle_date
                                 , p_batch_num
                                 );

                     UTL_FILE.put_line (lc_filehandle, lc_message1);
                     location_and_log (GC_YES, 'File Name ' || lc_filename);
                     UTL_FILE.fclose (lc_filehandle);
                     location_and_log (GC_YES, 'Open the file handle after generating the file: ' || ln_fno);
                     ln_count := 0;
                     ln_fno := ln_fno + 1;
                     -- V2.0 lc_filename := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
                     lc_filename := gc_file_name || '_' || lc_inst || '_' || p_batch_num|| lc_file || '-' || ln_fno || '.dat';                              
                     
                     
                     lt_file_name (ln_idx2) := lc_filename;
                     ln_idx2 := ln_idx2 + 1;
                     lc_filehandle := UTL_FILE.fopen (gc_file_path
                                                     ,lc_filename
                                                     ,lc_mode
                                                     ,gn_line_size
                                                     );
                  END IF;
               END LOOP;

               COMMIT;
               EXIT WHEN lcu_diary_notes%NOTFOUND;
            END LOOP;

            CLOSE lcu_diary_notes;
         ELSE
            p_errcode := 1;
         END IF;

         UTL_FILE.put_line (lc_filehandle, lc_message1);
         lc_message1 := 'Total number of records extracted:' || ln_count;
         UTL_FILE.put_line (lc_filehandle, lc_message1);
         --Summary data inserting into file log table
         UTL_FILE.fclose (lc_filehandle);
         location_and_log (GC_YES, '     File creation completed ');
      END;                                                                                                                                                                 --  Retrieve and Create Files

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate and Update Status in Control Table
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Validate and Update Status in Control Table');
         location_and_log (gc_debug, 'Inserting into file Log Table after loop');

         INSERT INTO xx_crmar_file_log
                     (program_id
                     ,program_name
                     ,program_run_date
                     ,filename
                     ,total_records
                     ,status
                     -- V1.8, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (gn_nextval
                     ,'OD: IEX - Extract WC - Diary Notes'
                     ,SYSDATE
                     ,lc_filename
                     ,ln_count
                     ,'SUCCESS'
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                     );

         location_and_log (gc_debug, '     Updating the Elgibility Table with the Flag as Y');

         UPDATE xx_ar_wc_ext_control
            SET diary_notes_ext = 'Y'
               ,last_updated_by = gn_last_updated_by
               ,last_update_date = SYSDATE
          WHERE cycle_date = p_cycle_date AND batch_num = p_batch_num;
      END;    -- Validate and Update Status in Control Table

      print_time_stamp_to_logfile;

      --========================================================================
      -- Copy Files to FTP Directory
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Setting Print Options Before submitting Common File Copy Program');
         -- Added for defect# 16434
         gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS (printer => NULL
         						     ,copies  => 0);
         location_and_log (GC_YES, 'Calling the Common File Copy to move the output file to ftp directory');

         FOR i IN lt_file_name.FIRST .. lt_file_name.LAST
         LOOP
            -- Start of FTP Program
            ln_ftp_request_id :=
               fnd_request.submit_request ('XXFIN'
                                          ,'XXCOMFILCOPY'
                                          ,''
                                          ,''
                                          ,FALSE
                                          , lc_source_path || '/' || lt_file_name (i)
                                          ,                                                                                                                                           --Source File Name
                                           gc_ftp_file_path || '/' || lt_file_name (i)
                                          ,                                                                                                                                             --Dest File Name
                                           ''
                                          ,''
                                          ,'Y'
                                          ,gc_arch_file_path
                                          --Deleting the Source File
                                          );
            COMMIT;

            -- End of FTP Program
            IF ln_ftp_request_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Common File copy Program is not submitted');
               ln_retcode := 2;
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Request ID ' || ln_ftp_request_id || 'For file ' || lt_file_name (i));
               lt_req_number (ln_idx) := ln_ftp_request_id;
               ln_idx := ln_idx + 1;
            END IF;
         END LOOP;

         location_and_log (gc_debug, 'End of Calling the Common File Copy program at ');
         location_and_log (gc_debug, 'Inserting the Diary Notes program details into xx_crmar_int_log table  at ');

         --V1.7
         lc_int_filename := SUBSTR(lc_filename,1,INSTR(lc_filename,'-')-1);

         --Summary data inserting into log table
         INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,module_name
                     ,program_short_name
                     ,program_run_date
                     ,filename
                     ,total_files
                     ,total_records
                     ,status
                     ,MESSAGE
                     -- V1.8, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (gn_nextval
                     ,'OD: IEX - Extract WC - Diary Notes'
                     ,'XXFIN'
                     ,'XXIEXEXTWC'
                     ,SYSDATE
                     ,lc_int_filename -- V1.7, inserting the file name passed in file table -- lc_file
                     ,ln_fno
                     ,ln_total_count
                     ,'SUCCESS'
                     ,'File generated'
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                     );

         COMMIT;
         location_and_log (gc_debug, 'After inserting into Log Table and submitting requests ');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total number of records extracted:' || ln_total_count);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Program run date:' || SYSDATE);
         location_and_log (gc_debug, 'Getting the child request statuses using fnd_concurrent.wait_for_request ');

         FOR i IN lt_req_number.FIRST .. lt_req_number.LAST
         LOOP
            IF fnd_concurrent.wait_for_request (lt_req_number (i)
                                                    ,2
                                                    ,0
                                                    ,lc_phase
                                                    ,lc_status
                                                    ,lc_dev_phase
                                                    ,lc_dev_status
                                                    ,lc_message2
                                                    )
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with error');
                  p_errcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with warning');
                  p_errcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_errcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;

         p_errcode := ln_retcode;
      END;                                                                                                                                                                -- Copy Files to FTP Directory

   EXCEPTION
      WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_mode THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_filehandle THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_operation THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.read_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.write_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.internal_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Error - WHEN OTHERS - ' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
   END EXTRACT_STAGEDATA;  --  End of extract_stagedata procedure

   /*+======================================================================================+
   |Name        : diary_notes_main                                                          |
   |Description : This procedure is used to call the above two procedures insert_diarynotes |
   |              and extract_stagedata.                                                    |
   |                                                                                        |
   |Parameters :  p_compute_stats                                                           |
   |              p_debug                                                                   |
   |                                                                                        |
   |Returns    : NA                                                                         |
   |                                                                                        |
   +========================================================================================+*/
   PROCEDURE DIARY_NOTES_MAIN (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_cycle_date      IN       VARCHAR2
     ,p_batch_num       IN       NUMBER
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
     ,p_process_type    IN       VARCHAR2
   )
   IS
      ln_errcode      NUMBER;
      -- Declaration of Table type and variable
      cm_diarynotes   diary_notes_tbl_type;

      -------------------------------------------------------
      -- Cursor for Full DAILY Conversion of New Customers 
      -------------------------------------------------------

-- V2.2, Used old cursor to exclude account level notes

      CURSOR lcu_diarynotes (p_from_date   IN   DATE
                            ,p_to_date     IN   DATE)
      IS
         SELECT /*+ LEADING(XCE HCA HP HR) USE_NL(HCA) INDEX(HR HZ_RELATIONSHIPS_N6) */
                JNB.jtf_note_id                       CALL_ID
               ,HCA.cust_account_id                   CUST_ACCOUNT_ID
               ,JNB.creation_date                     "NOTE DATE"
               ,FND_STATUS.meaning                    STATUS
               ,JRE.source_name                       "COLLECTOR NAME"
               ,HCSU.site_use_id                      BILL_TO_SITE_USE_ID
               ,HPC.person_last_name                  "CONTACT LAST NAME"
               ,HPC.person_first_name                 "CONTACT FIRST NAME"
               ,FND_TYPE.meaning                      TYPE
               ,JNT.notes                             NOTE_TEXT
               ,DECODE(FAD.pk1_value,NULL, 'N','Y')   ATTACHEMENTS
               ,gd_creation_date                      CREATION_DATE
               ,gn_last_updated_by                    LAST_UPDATED_BY
               ,gn_request_id                         REQUEST_ID
               ,gn_created_by                         CREATED_BY
               ,gd_last_update_date                   LAST_UPDATE_DATE
               ,gd_cycle_date                         CYCLE_DATE
               ,p_batch_num                           BATCH_NUM
           FROM jtf_notes_b             JNB
               ,jtf_notes_tl            JNT
               ,fnd_lookups             FND_TYPE
               ,fnd_lookups             FND_STATUS
               ,jtf_rs_resource_extns   JRE
               ,hz_cust_accounts        HCA
               ,hz_parties              HP
               ,fnd_attached_documents  FAD
               ,xx_crm_wcelg_cust       XCE
               ,hz_party_sites          HPS
               ,hz_cust_acct_sites_all  HCAS
               ,hz_cust_site_uses_all   HCSU
               ,hz_parties              HPC
               ,hz_relationships        HR
          WHERE HR.relationship_type      = 'COLLECTIONS'
            AND HR.status                 = 'A'
            AND HCSU.site_use_code        = 'BILL_TO'
            AND JNB.source_object_code    = 'IEX_BILLTO' 
            AND JNT.LANGUAGE              = USERENV ('LANG')
            AND FND_STATUS.lookup_type    = 'JTF_NOTE_STATUS'
            AND FND_STATUS.lookup_code    = JNB.note_status
            AND FND_TYPE.lookup_type      = 'JTF_NOTE_TYPE'
            AND FND_TYPE.lookup_code      = JNB.note_type
            AND JNB.jtf_note_id           = JNT.jtf_note_id
            AND JRE.user_id(+)            = JNB.entered_by
            AND HCSU.site_use_id          = JNB.source_object_id
            AND HCA.cust_account_id       = XCE.cust_account_id
            AND XCE.cust_account_id       = HCAS.cust_account_id
            AND HCA.party_id              = HP.party_id
            AND FAD.pk1_value(+)          = TO_CHAR(JNB.jtf_note_id)
            AND HP.party_id               = HPS.party_id
            AND HR.subject_id             = HPC.party_id
            AND HR.object_id              = HP.party_id
            AND HPS.party_site_id         = HCAS.party_site_id
            AND HCAS.cust_acct_site_id    = HCSU.cust_acct_site_id
            AND XCE.notes_processed_to_wc = 'N'
            AND XCE.cust_mast_head_ext    = 'Y'
            AND JNB.last_update_date BETWEEN p_from_date 
                                             AND p_to_date;

      -------------------------------------------------------
      -- Cursor for Full INTIAL Conversion of New Customers 
      -------------------------------------------------------
      CURSOR lcu_diarynotes_conv (p_from_date   IN   DATE
                                 ,p_to_date     IN   DATE)
      IS
         SELECT /*+ ORDERED INDEX(HCSU HZ_CUST_SITE_USES_U1) INDEX(HCAS HZ_CUST_ACCT_SITES_U1) USE_NL(HR) */
                JNB.jtf_note_id                       CALL_ID
               ,HCA.cust_account_id                   CUST_ACCOUNT_ID
               ,JNB.creation_date                     "NOTE DATE"
               ,FND_STATUS.meaning                    STATUS
               ,JRE.source_name                       "COLLECTOR NAME"
               ,HCSU.site_use_id                      BILL_TO_SITE_USE_ID
               ,HPC.person_last_name                  "CONTACT LAST NAME"
               ,HPC.person_first_name                 "CONTACT FIRST NAME"
               ,FND_TYPE.meaning                      TYPE
               ,JNT.notes                             NOTE_TEXT
               ,DECODE(FAD.pk1_value,NULL, 'N','Y')   ATTACHEMENTS
               ,gd_creation_date                      CREATION_DATE
               ,gn_last_updated_by                    LAST_UPDATED_BY
               ,gn_request_id                         REQUEST_ID
               ,gn_created_by                         CREATED_BY
               ,gd_last_update_date                   LAST_UPDATE_DATE
               ,gd_cycle_date                         CYCLE_DATE
               ,p_batch_num                           BATCH_NUM
           FROM jtf_notes_b             JNB
               ,fnd_lookups             FND_TYPE
               ,fnd_lookups             FND_STATUS
               ,hz_cust_site_uses_all   HCSU
               ,hz_cust_acct_sites_all  HCAS
               ,xx_crm_wcelg_cust       XCE
               ,hz_cust_accounts        HCA
               ,hz_parties              HP
               ,hz_relationships        HR
               ,hz_parties              HPC
               ,jtf_rs_resource_extns   JRE
               ,jtf_notes_tl            JNT
               ,fnd_attached_documents  FAD
               ,hz_party_sites          HPS
          WHERE HR.relationship_type      = 'COLLECTIONS'
            AND HR.status                 = 'A'
            AND HCSU.site_use_code        = 'BILL_TO'
            AND JNB.source_object_code    = 'IEX_BILLTO' 
            AND JNT.LANGUAGE              = USERENV ('LANG')
            AND FND_STATUS.lookup_type    = 'JTF_NOTE_STATUS'
            AND FND_STATUS.lookup_code    = JNB.note_status
            AND FND_TYPE.lookup_type      = 'JTF_NOTE_TYPE'
            AND FND_TYPE.lookup_code      = JNB.note_type
            AND JNB.jtf_note_id           = JNT.jtf_note_id
            AND JRE.user_id(+)            = JNB.entered_by
            AND HCSU.site_use_id          = JNB.source_object_id
            AND HCA.cust_account_id       = XCE.cust_account_id
            AND XCE.cust_account_id       = HCAS.cust_account_id
            AND HCA.party_id              = HP.party_id
            AND FAD.pk1_value(+)          = TO_CHAR(JNB.jtf_note_id)
            AND HP.party_id               = HPS.party_id
            AND HR.subject_id             = HPC.party_id
            AND HR.object_id              = HP.party_id
            AND HPS.party_site_id         = HCAS.party_site_id
            AND HCAS.cust_acct_site_id    = HCSU.cust_acct_site_id
            AND XCE.notes_processed_to_wc = 'N'
            AND XCE.cust_mast_head_ext    = 'Y'
            AND JNB.last_update_date BETWEEN p_from_date 
                                         AND p_to_date;

   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date := FND_DATE.CANONICAL_TO_DATE (p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR PAYMENT SCHEDULE(FULL)*******************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date               :' || p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch number             :' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics        :' || p_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag               :' || p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type             :' || p_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '**********************************************************************************');

         BEGIN
            location_and_log (gc_debug, gc_error_loc || 'Getting the sequence XX_CRMAR_INT_LOG_S value at');

            SELECT xx_crmar_int_log_s.NEXTVAL
              INTO gn_nextval
              FROM DUAL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               location_and_log (GC_YES, SQLCODE || 'NO data found while getting sequence next value ');
         END;

         location_and_log (GC_YES, 'Nextvalue from xx_crmar_int_log_s                   : ' || gn_nextval);
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         get_interface_settings;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Determine if parameter value for debug is used' || CHR (10));
         gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --==================================================================
      -- Retrieve Cycle Date Information from Control Table
      --==================================================================
      BEGIN
         location_and_log (GC_YES, 'Calling get_control_info to evaluate cucle date information' || CHR (10));
         xx_ar_wc_utility_pkg.get_control_info (p_cycle_date                 => gd_cycle_date
                                               ,p_batch_num                  => p_batch_num
                                               ,p_process_type               => p_process_type
                                               ,p_action_type                => NULL
                                               ,p_delta_from_date            => gd_delta_from_date
                                               ,p_full_from_date             => gd_full_from_date
                                               ,p_control_to_date            => gd_control_to_date
                                               ,p_post_process_status        => gc_post_process_status
                                               ,p_ready_to_execute           => gb_ready_to_execute
                                               ,p_reprocessing_required      => gb_reprocessing_required
                                               ,p_reprocess_cnt              => gc_reprocess_cnt
                                               ,p_retrieved                  => gb_retrieved_cntl
                                               ,p_error_message              => gc_err_msg_cntl
                                               );
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log (GC_YES, '     Validate Control Information to Determine Processing Required');
         location_and_log (GC_YES, 'Evaluate Control Record Status.' || CHR (10));

         IF NOT gb_retrieved_cntl THEN
            location_and_log (GC_YES, gc_error_loc || ' Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;
         
         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log (GC_YES, gc_error_loc || ' Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;
         
         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log (GC_YES, gc_error_loc || ' Data has already been staged for this process.');
            RAISE EX_STAGING_COMPLETED;
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Truncate XXFIN.XX_IEX_DIARY_NOTES_STG table ');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_IEX_DIARY_NOTES_STG';

         location_and_log (GC_YES, 'Truncate complete ');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve and Stage Data
      --========================================================================
      BEGIN
         IF p_process_type = 'DIARY_NOTES' THEN
            -----------------------------------
            -- Process Full DAILY Conversion
            -----------------------------------
            location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));
            location_and_log (gc_debug, 'Opening cursor lcu_diarynotes');
   
            OPEN lcu_diarynotes (gd_full_from_date
                                ,gd_control_to_date);
   
            LOOP
               FETCH lcu_diarynotes
               BULK COLLECT INTO cm_diarynotes LIMIT gn_limit;
   
               FORALL i IN 1 .. cm_diarynotes.COUNT
                  INSERT INTO xx_iex_diary_notes_stg
                       VALUES cm_diarynotes (i);
               COMMIT;
               EXIT WHEN lcu_diarynotes%NOTFOUND;
            END LOOP;
   
            CLOSE lcu_diarynotes;
   
            location_and_log (gc_debug, 'After closing the cursor lcu_diarynotes at ');

         ELSIF p_process_type = 'DIARY_NOTES_CONV' THEN
            -----------------------------------
            -- Process Full INITIAL Conversion
            -----------------------------------
            location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));
            location_and_log (gc_debug, 'Opening cursor lcu_diarynotes_conv');
   
            OPEN lcu_diarynotes_conv (gd_full_from_date
                                     ,gd_control_to_date);
   
            LOOP
               FETCH lcu_diarynotes_conv
               BULK COLLECT INTO cm_diarynotes LIMIT gn_limit;
   
               FORALL i IN 1 .. cm_diarynotes.COUNT
                  INSERT INTO xx_iex_diary_notes_stg
                       VALUES cm_diarynotes (i);
               COMMIT;
               EXIT WHEN lcu_diarynotes_conv%NOTFOUND;
            END LOOP;
   
            CLOSE lcu_diarynotes_conv;
   
            location_and_log (gc_debug, 'After closing the cursor lcu_diarynotes_conv at ');
         ELSE
            location_and_log (GC_YES, gc_error_loc || ' - Invalid Action Type Parameter Value');
            RAISE EX_INVALID_ACTION_TYPE;
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Gather Statitics
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Determine if gathering statistics' || CHR (10));

         IF gc_compute_stats = 'Y'
         THEN
            -- Gather Table statistics
            location_and_log (GC_YES, 'Gathering statistics for table XX_IEX_DIARY_NOTES_STG');
            compute_stats ('XXFIN', 'XX_IEX_DIARY_NOTES_STG');
         ELSE
            location_and_log (GC_YES, 'Statistics were not gathered for table XX_IEX_DIARY_NOTES_STG');
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Call Procedure to Stage and Extract Diary Notes
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Call Procedure to Stage and Extract Diary Notes' || CHR (10));
         location_and_log (gc_debug, '     Executing extract_stagedata.');
         extract_stagedata (gd_cycle_date
                           ,p_batch_num
                           ,ln_errcode
                           );
         location_and_log (gc_debug, '     Check/Set error code from extract_stagedata');

         IF ln_errcode <> 0
         THEN
            p_retcode := ln_errcode;
            location_and_log (gc_debug, '     ln_errcode is ' || ln_errcode);
         END IF;
      END;
   EXCEPTION
      WHEN EX_INVALID_ACTION_TYPE THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_ACTION_TYPE at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;
         
      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || '. ' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;
      
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || '. ' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;
   END DIARY_NOTES_MAIN;

END XX_IEX_DIARYNOTES_EXTRACT_PKG;
/

SHOW ERR;
