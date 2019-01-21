CREATE OR REPLACE PACKAGE BODY APPS.xx_cdh_omx_contacts_pkg
AS
-- +=========================================================================+
-- |                        Office Depot                                      |
-- +=========================================================================+
-- | Name  : XX_CDH_OMX_CONTACTS_PKG                                         |
-- | Rice ID: C0701                                                          |
-- | Description      : This Program will extract all the OMX contacts       |
-- |                    and create .csv file and sent to web collect         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     0-FEB-2015  Abhi K          Initial draft version                |
-- |1.1    24-MAR-2015  Abhi K          Code Review  Chages                  | 
-- |1.2     5-MAY-2015  Havish K        Changes done as per Defect#1239      |
-- |1.3     8-JUL-2015  Havish K        MOD5 Changes                         |
-- +=========================================================================+
   -- Global Variable Declaration
   g_debug_flag            BOOLEAN;
   gc_success              VARCHAR2 (100)                        := 'SUCCESS';
   gc_failure              VARCHAR2 (100)                        := 'FAILURE';
   gd_last_update_date     DATE                                    := SYSDATE;
   gn_last_updated_by      NUMBER                       := fnd_global.user_id;
   gd_creation_date        DATE                                    := SYSDATE;
   gn_created_by           NUMBER                       := fnd_global.user_id;
   gn_last_update_login    NUMBER                      := fnd_global.login_id;
   gn_request_id           NUMBER               := fnd_global.conc_request_id;
   gn_nextval              NUMBER;
   gn_ret_code             NUMBER                                       := 0;
   gd_cycle_date           DATE                                    := SYSDATE;
   -- Variables for Interface Settings
   gn_limit                NUMBER;
   gn_threads_delta        NUMBER;
   gn_threads_full         NUMBER;
   gn_threads_file         NUMBER;
   gc_program_short_name   VARCHAR2 (200);
   gc_program_name         VARCHAR2 (200);
   gc_conc_short_delta     xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full      xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file      xx_fin_translatevalues.target_value18%TYPE;
   gc_delimiter            xx_fin_translatevalues.target_value3%TYPE;
   gc_file_name            xx_fin_translatevalues.target_value4%TYPE;
   gc_email                xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats        xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size            NUMBER;
   gc_file_path            xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records          NUMBER;
   gc_debug                xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path        xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path       xx_fin_translatevalues.target_value12%TYPE;
   gn_full_num_days        NUMBER;
   gc_sender_email         xx_fin_translatevalues.target_value19%TYPE;
   gb_retrieved_trans      BOOLEAN                                   := FALSE;
   gc_err_msg_trans        VARCHAR2 (100)                             := NULL;
   gc_module_name          VARCHAR2 (100)                             := NULL;
   gc_process_type         xx_ar_mt_wc_details.process_type%TYPE
                                                    := 'XXOD_OMX_AP_CONTACTS';

   PROCEDURE log_exception (
      p_error_location   IN   VARCHAR2,
      p_error_msg        IN   VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : log_exception                                             |
-- | Description     : The log_exception procedure logs all exceptions |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : p_error_location     IN -> Error location       |
-- |                   p_error_msg          IN -> Error message        |
-- +===================================================================+

      --------------------------------
-- Local Variable Declaration --
--------------------------------
      ln_login     NUMBER := fnd_global.login_id;
      ln_user_id   NUMBER := fnd_global.user_id;
   BEGIN
      xx_com_error_log_pub.log_error
                        (p_return_code                 => fnd_api.g_ret_sts_error,
                         p_msg_count                   => 1,
                         p_application_name            => 'XXCRM',
                         p_program_type                => 'Custom Messages',
                         p_program_name                => 'XX_CDH_OMX_CONTACTS_PKG',
                         p_attribute15                 => 'XX_CDH_OMX_CONTACTS_PKG',
                         p_program_id                  => NULL,
                         p_module_name                 => 'MOD4A',
                         p_error_location              => p_error_location,
                         p_error_message_code          => NULL,
                         p_error_message               => p_error_msg,
                         p_error_message_severity      => 'MAJOR',
                         p_error_status                => 'ACTIVE',
                         p_created_by                  => ln_user_id,
                         p_last_updated_by             => ln_user_id,
                         p_last_update_login           => ln_login
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error while writting to the log ...' || SQLERRM
                           );
   END log_exception;

   PROCEDURE log_msg (p_string IN VARCHAR2)
   IS
-- +===================================================================+
-- | Name  : log_msg                                                   |
-- | Description     : The log_msg procedure displays the log messages |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : p_string             IN -> Log Message          |
-- +===================================================================+
   BEGIN
      IF (g_debug_flag)
      THEN
         fnd_file.put_line (fnd_file.LOG, p_string);
      END IF;
   END log_msg;

-- +===================================================================+
-- | Name  : get_customer_aops_detail                                   |
-- | Description     :                                                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters                                                       |
-- +===================================================================+
   PROCEDURE get_aops_addr_reference (
      p_omx_bill_consignee   IN       VARCHAR2,
      p_aops_cust_number     IN       VARCHAR2,
      p_aops_addr_ref        OUT      VARCHAR2,
      p_return_status        OUT      VARCHAR2,
      p_error_msg            OUT      VARCHAR2
   )
   IS
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (1000);
   BEGIN

      SELECT hcas.orig_system_reference
        INTO p_aops_addr_ref
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_accounts hca,
             hz_parties hp,
             hz_party_sites hps
       WHERE hcas.cust_account_id = hca.cust_account_id
         AND hp.party_id = hca.party_id
         AND hp.party_id = hps.party_id
         AND hcas.party_site_id = hps.party_site_id
		 AND hcas.status = 'A'
		 AND SUBSTR(hps.orig_system_reference,8,INSTR(hps.orig_system_reference,'-OMX')-8) = p_omx_bill_consignee -- Added as per Version 1.3, MOD5 Changes
         AND hca.orig_system_reference =LPAD (TO_CHAR (p_aops_cust_number), 8, 0) || '-'|| '00001-A0';
         
      p_return_status := gc_success;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg := 'aops address reference not found';
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.GET_CUSTOMER_AOPS_DETAIL',
             p_error_msg           => lc_error_msg
            );
         p_return_status := gc_failure;
         p_error_msg := lc_error_msg;
      WHEN TOO_MANY_ROWS
      THEN
         lc_error_msg :=
            'TOO_MANY_ROWS - aops address reference not found';
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.GET_AOPS_ADDR_REFERENCE',
             p_error_msg           => lc_error_msg
            );
         p_return_status := gc_failure;
         p_error_msg := lc_error_msg;
      WHEN OTHERS
      THEN
         lc_error_msg :=
                'Unable to fetch the aops address reference:'|| ' ' || SQLERRM;
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.GET_CUSTOMER_AOPS_DETAIl',
             p_error_msg           => lc_error_msg
            );
         p_return_status := gc_failure;
         p_error_msg := lc_error_msg;
   END get_aops_addr_reference;

   PROCEDURE log_file (
      p_success_records   IN   NUMBER,
      p_faliure_records   IN   NUMBER,
      p_batch_id          IN   NUMBER,
      p_file_name         IN   VARCHAR2,
      p_status            IN   VARCHAR2
   )
   IS
       /*===================================================================================+
      | Name       : log_file                                                             |
      | Description: This procedure is used to log  program name and total_records          |
      |                                                                                     |
      | Parameters : p_success_records     IN ->  success records                           |
      |              p_batch_id            IN -> batch number                               |
      +====================================================================================*/

      --------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg      VARCHAR2 (200);
      lc_program_name   VARCHAR2 (200);
   BEGIN
-------------------------------------------------------------------
--Insert record in xx_cdh_omx_file_log table for tracking purpose .
----------------------------------------------------------------
      BEGIN
         SELECT fcp.user_concurrent_program_name
           INTO lc_program_name
           FROM fnd_concurrent_programs_vl fcp, fnd_concurrent_requests fcr
          WHERE fcp.concurrent_program_id = fcr.concurrent_program_id
            AND fcr.request_id = gn_request_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_error_msg :=
                  'Concurrent Program Name not found for Request ID: '
               || gn_request_id;
            log_msg (lc_error_msg);
            log_exception
                      (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.LOG_FILE',
                       p_error_msg           => lc_error_msg
                      );
         WHEN OTHERS
         THEN
            lc_error_msg :=
                  'Unable to fetch Concurrent Program name for Request ID :'
               || gn_request_id
               || ' '
               || SQLERRM;
            log_msg (lc_error_msg);
            log_exception
                      (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.LOG_FILE',
                       p_error_msg           => lc_error_msg
                      );
      END;

      BEGIN
         INSERT INTO xx_cdh_omx_file_log_stg
                     (program_id, program_name, program_run_date, file_name,
                      success_records, failure_records, status,
                      request_id, cycle_date, batch_num, error_message,
                      creation_date, created_by, last_updated_by,
                      last_update_date, last_update_login
                     )
              VALUES (gn_request_id, lc_program_name, SYSDATE, p_file_name,
                      p_success_records, p_faliure_records, p_status,
                      gn_request_id, gd_cycle_date, p_batch_id, NULL,
                      gd_creation_date, gn_created_by, gn_last_updated_by,
                      gd_last_update_date, gn_last_update_login
                     );

         log_msg
            (   'Inserting records into xx_cdh_omx_file_log table for batch id: '
             || p_batch_id
            );
      EXCEPTION
         WHEN OTHERS
         THEN
            IF lc_error_msg IS NULL
            THEN
               lc_error_msg :=
                       'Unable to insert the records in log table' || SQLERRM;
            END IF;

            log_msg (lc_error_msg);
            log_exception
                    (p_error_location      => 'XXX_CDH_OMX_CONTACTS_PKG.LOG_TABLE',
                     p_error_msg           => lc_error_msg
                    );
      END;
   END log_file;

    /*=====================================================================================+
   | Name       : Update xx_cdh_omx_ap_contacts_stg for each record_id if it is completed |
   |                OR Errored Out.                                                       |
   | Description: This procedure is update the status                                    |
   |                                                                                     |
   | Parameters : none                                                                   |
   |                                                                                     |
   | Returns    : none                                                                   |
   +=====================================================================================*/
   PROCEDURE update_ap_contacts_stg (
      p_status      IN       VARCHAR2,
      p_record_id   IN       NUMBER,
      p_error_msg   IN OUT   VARCHAR2
   )
   IS
   BEGIN
             log_msg ('updating status to ....'||' '||p_status||' '||'for the record id'||' '||p_record_id);

      UPDATE xx_cdh_omx_ap_contacts_stg
         SET status = p_status,
             error_message = p_error_msg,
             last_update_date = SYSDATE
       WHERE 1 = 1 AND record_id = p_record_id;

      log_msg ('Number of Rows updated :' || SQL%ROWCOUNT);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_error_msg IS NULL
         THEN
            p_error_msg :=
                  'Error while updating the status xx_cdh_omx_ap_contacts_stg '
               || SQLERRM;
         END IF;

         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.UPDATE_AP_CONTACTS_STG',
             p_error_msg           => p_error_msg
            );
   END update_ap_contacts_stg;

   /*=====================================================================================+
   | Name       : GET_INTERFACE_SETTINGS                                                 |
   | Description: This procedure is used to fetch the transalation definition details    |
   |                                                                                     |
   | Parameters : none                                                                   |
   |                                                                                     |
   | Returns    : none                                                                   |
   +=====================================================================================*/
   PROCEDURE get_interface_settings (p_error_msg OUT VARCHAR2)
   IS
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (1000);
   BEGIN
      p_error_msg := NULL;
--========================================================================
-- Retrieve Interface Settings from Translation Definition
--========================================================================
      xx_ar_wc_utility_pkg.get_interface_settings
                                  (p_process_type           => gc_process_type,
                                   p_bulk_limit             => gn_limit,
                                   p_delimiter              => gc_delimiter,
                                   p_num_threads_delta      => gn_threads_delta,
                                   p_file_name              => gc_file_name,
                                   p_email                  => gc_email,
                                   p_gather_stats           => gc_compute_stats,
                                   p_line_size              => gn_line_size,
                                   p_file_path              => gc_file_path,
                                   p_num_records            => gn_num_records,
                                   p_debug                  => gc_debug,
                                   p_ftp_file_path          => gc_ftp_file_path,
                                   p_arch_file_path         => gc_arch_file_path,
                                   p_full_num_days          => gn_full_num_days,
                                   p_num_threads_full       => gn_threads_full,
                                   p_num_threads_file       => gn_threads_file,
                                   p_child_conc_delta       => gc_conc_short_delta,
                                   p_child_conc_full        => gc_conc_short_full,
                                   p_child_conc_file        => gc_conc_short_file,
                                   p_staging_table          => gc_sender_email,
                                   p_retrieved              => gb_retrieved_trans,
                                   p_error_message          => gc_err_msg_trans,
                                   p_print_to_req_log       => 'Y'
                                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_msg :=
               'Unable to fetch the transalation definition details failied  :'
            || ' '
            || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.GET_INTERFACE_SETTINGS',
             p_error_msg           => lc_error_msg
            );
   END get_interface_settings;

   PROCEDURE send_mail (
      p_file_name       IN       VARCHAR2,
      p_email_subject   IN       VARCHAR2,
      p_email_body      IN       VARCHAR2,
      p_return_status   OUT      VARCHAR2,
      p_return_msg      OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : send_mail                                                   |
-- | Description     : The send_mail  procedure copies the outbound file to |
-- |                   the required directoy , archivesr and also email's..|
-- |                                                                   |
-- | Parameters      : p_file_name     -> file name
-- |                   p_return_status -> return status                |
-- |                   p_return_msg    -> return message               |
-- +===================================================================+
      lc_conn                   UTL_SMTP.connection;
      lc_sourcepath             VARCHAR2 (4000);
      lc_destpath               VARCHAR2 (4000);
      lc_archpath               VARCHAR2 (4000);
      ln_copy_conc_request_id   NUMBER;
      lb_complete               BOOLEAN;
      lc_phase                  VARCHAR2 (100);
      lc_status                 VARCHAR2 (100);
      lc_dev_phase              VARCHAR2 (100);
      lc_dev_status             VARCHAR2 (100);
      lc_message                VARCHAR2 (100);
      lc_error_msg              VARCHAR2 (1000);
      lc_date                   VARCHAR2 (200)
                                           := TO_CHAR (SYSDATE, 'MM/DD/YYYY');
      e_process_exception       EXCEPTION;
   BEGIN
      lc_error_msg := NULL;

      BEGIN
         SELECT directory_path
           INTO lc_sourcepath
           FROM all_directories
          WHERE directory_name = gc_file_path;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Source Directory path not found'
                              );
            lc_error_msg := 'Source Directory path not found';
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Unable to fetch Source Directory path'
                               || SQLERRM
                              );
            lc_error_msg := 'Unable to fetch SourceDirectory path' || SQLERRM;
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
      END;

      BEGIN
         SELECT directory_path
           INTO lc_destpath
           FROM all_directories
          WHERE directory_name = gc_ftp_file_path;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Email Destination Directory path not found'
                              );
            lc_error_msg := 'Email Destination Directory path not found';
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                       (fnd_file.LOG,
                           'Unable to fetch Email Destination Directory path'
                        || SQLERRM
                       );
            lc_error_msg :=
                 'Unable to fetch Email Destination Directory path' || SQLERRM;
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
      END;

      IF (lc_sourcepath IS NOT NULL)
      THEN
         lc_sourcepath := lc_sourcepath || '/' || p_file_name;
         lc_destpath := lc_destpath || '/' || p_file_name;
         lc_archpath := gc_arch_file_path || '/' || p_file_name;
         fnd_file.put_line (fnd_file.LOG, 'source path :' || lc_sourcepath);
         fnd_file.put_line (fnd_file.LOG,
                            'destination path :' || lc_destpath);
         fnd_file.put_line (fnd_file.LOG, 'archive path  :' || lc_archpath);
         ln_copy_conc_request_id :=
            fnd_request.submit_request (application      => 'XXFIN',
                                        program          => 'XXCOMFILCOPY',
                                        description      => NULL,
                                        start_time       => NULL,
                                        sub_request      => FALSE,
                                        argument1        => lc_sourcepath,
                                        argument2        => lc_destpath,
                                        argument3        => NULL,
                                        argument4        => NULL,
                                        argument5        => 'Y',
                                        argument6        => gc_arch_file_path,
                                        argument7        => NULL,
                                        argument8        => NULL,
                                        argument9        => NULL,
                                        argument10       => NULL,
                                        argument11       => NULL,
                                        argument12       => NULL,
                                        argument13       => NULL
                                       );

         IF ln_copy_conc_request_id > 0
         THEN
            COMMIT;
            lb_complete :=
               fnd_concurrent.wait_for_request
                                      (request_id      => ln_copy_conc_request_id,
                                       INTERVAL        => 30,
                                       max_wait        => 0   -- out arguments
                                                           ,
                                       phase           => lc_phase,
                                       status          => lc_status,
                                       dev_phase       => lc_dev_phase,
                                       dev_status      => lc_dev_status,
                                       MESSAGE         => lc_message
                                      );
         ELSE
            lc_error_msg :=
                  'fnd_concurrent.wait_for_request Faliure' || ' ' || SQLERRM;
            RAISE e_process_exception;
         END IF;

         log_msg ('lc_dev_phase: ' || lc_dev_phase);

         IF UPPER (lc_dev_phase) IN ('COMPLETE')
         THEN
            lc_conn :=
               xx_pa_pb_mail.begin_mail
                             (sender             => gc_sender_email,
                              recipients         => gc_email,
                              cc_recipients      => NULL,
                              subject            =>    p_email_subject
                                                    || ' '
                                                    || lc_date,
                              mime_type          => xx_pa_pb_mail.multipart_mime_type
                             );
            xx_pa_pb_mail.xx_attach_excel (lc_conn, p_file_name);
            xx_pa_pb_mail.end_attachment (conn => lc_conn);
            xx_pa_pb_mail.attach_text (conn => lc_conn, DATA => p_email_body);
            xx_pa_pb_mail.end_mail (conn => lc_conn);
         ELSE
            lc_error_msg := 'lc_dev_phase is not complete' || ' ' || SQLERRM;
            RAISE e_process_exception;
         END IF;

         p_return_status := gc_success;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Unable to email the  file'||' ' || SQLERRM
                           );
         lc_error_msg := 'Unable to email the file' || SQLERRM;
         log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.send_mail',
                      p_error_msg           => lc_error_msg
                     );
         p_return_status := gc_failure;
         p_return_msg := lc_error_msg;
   END send_mail;

   PROCEDURE generate_exception_report (
      x_retcode     OUT NOCOPY   NUMBER,
      x_errbuf      OUT NOCOPY   VARCHAR2,
      p_file_name   OUT          VARCHAR2,
      p_error_msg   OUT          VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : generate_exception_report                                  |
-- | Description     :  generate_exception_report                      |
-- +===================================================================+
-- local variable declaration
      lc_filehandle          UTL_FILE.file_type;
      lc_file_name           VARCHAR2 (200)
                                   := 'xxod_omx_ap_contacts_exception_report';
      lc_date                VARCHAR2 (200)
                                      := '_' || TO_CHAR (SYSDATE, 'MMDDYYYY');
      lc_mode                VARCHAR2 (1)       := 'W';
      ln_failed_records      NUMBER;
      ln_records_processed   NUMBER;
      lc_string              VARCHAR2 (32000);
      lc_header_string       VARCHAR2 (4000);
      lc_success             VARCHAR2 (200);
      lc_error_msg           VARCHAR2 (4000);
      lc_source_path         VARCHAR2 (200);
      lc_return_status       VARCHAR2 (5);
      e_process_exception    EXCEPTION;

      CURSOR cur_exp_rpt
      IS
         SELECT *
           FROM xx_cdh_omx_ap_contacts_stg
          WHERE 1 = 1
            AND status = 'E'
            AND TRUNC (last_update_date) = TRUNC (SYSDATE)
            order by record_id asc;
   BEGIN
      ln_records_processed := 0;
      ln_failed_records := 0;
      lc_return_status := NULL;
      lc_error_msg := NULL;
      log_msg ('Getting Interface Settings from Translation Definition ..');
      get_interface_settings (p_error_msg => lc_error_msg);

      IF p_error_msg IS NOT NULL
      THEN
         RAISE e_process_exception;
      END IF;

-------------------------------------------------------------------------
--Set the lc_filename||date||.csv
-------------------------------------------------------------------------
      lc_file_name :=
                     lc_file_name || lc_date || '_' || gn_request_id || '.csv';
      log_msg ('Opening a utl_file ..');
      fnd_file.put_line (fnd_file.LOG, 'UTLFILE_Path :' || gc_file_path);
      fnd_file.put_line (fnd_file.LOG, 'file_name :' || lc_file_name);
      fnd_file.put_line(fnd_file.LOG,'***************************************************************************************************************************************************');
-------------------------------------------------------------------------
-- UTL_FILE.fopen
-------------------------------------------------------------------------
      lc_filehandle := UTL_FILE.fopen (gc_file_path, lc_file_name, lc_mode);
-------------------------------------------------------------------------
---- Building a exception header string to spit out  the file to the specific
---- output directory
-------------------------------------------------------------------------
      lc_header_string :=
            'AOPS Account Number'
         || ','
         || 'Oracle Account Number'
         || ','
         || 'OD North Account Number'
         || ','
         || 'Last Name'
         || ','
         || 'First Name'
         || ','
         || 'Email Address'
         || ','
         || 'Telephone Area Code'
         || ','
         || 'Telephone'
         || ','
         || 'Fax Area Code'
         || ','
         || 'Fax Number'
         || ','
         || 'Bill To Consignee Number'
         || ','
         || 'Contact Type'
         || ','
         || 'Error Message';
      UTL_FILE.put_line (lc_filehandle, lc_header_string);

      FOR cur_exp_rpt_rec IN cur_exp_rpt
      LOOP
         BEGIN
            lc_return_status := NULL;
            lc_error_msg := NULL;
            lc_string := NULL;
-------------------------------------------------------------------------
---- Building a exception string to spit out the file to the specific
---- output directory
-------------------------------------------------------------------------
            lc_string :=
                  cur_exp_rpt_rec.aops_customer_number
               || ','
               || cur_exp_rpt_rec.customer_number
               || ','
               || cur_exp_rpt_rec.omx_account_number
               || ','
               || cur_exp_rpt_rec.contact_last_name
               || ','
               || cur_exp_rpt_rec.contact_first_name
               || ','
               || cur_exp_rpt_rec.email_address
               || ','
               || cur_exp_rpt_rec.phone_area_code
               || ','
               || cur_exp_rpt_rec.phone_number
               || ','
               || cur_exp_rpt_rec.fax_area_code
               || ','
               || cur_exp_rpt_rec.fax_number
               || ','
               || '='
               || '"'
               || cur_exp_rpt_rec.bill_consignee_ref
               || '"'
               || ','
               || cur_exp_rpt_rec.contact_type
               || ','
               || cur_exp_rpt_rec.error_message;
            UTL_FILE.put_line (lc_filehandle, lc_string);
--------------------------------------------------------------------------
--Count Sucessful records loaded into the exception file
--------------------------------------------------------------------------
            ln_records_processed := ln_records_processed + 1;
         EXCEPTION
            WHEN UTL_FILE.invalid_mode
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20052, 'Invalid Mode');
            WHEN UTL_FILE.internal_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20053, 'Internal Error');
            WHEN UTL_FILE.invalid_operation
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20054, 'Invalid Operation');
            WHEN UTL_FILE.invalid_filehandle
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20055, 'Invalid Filehandle');
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20056, 'Write Error');
            WHEN OTHERS
            THEN
               IF lc_error_msg IS NULL
               THEN
                  lc_error_msg := 'Unable to fetch date :' || ' ' || SQLERRM;
               END IF;

               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.GENERATE_EXCEPTION_REPORT',
                   p_error_msg           => lc_error_msg
                  );
         END;
  
      END LOOP;
      
                    
    log_msg ('Commit the error log changes ..');
   COMMIT; 

      UTL_FILE.fclose (lc_filehandle);
      p_file_name := lc_file_name;
   END generate_exception_report;

   PROCEDURE process_bill_contacts (
      x_retcode         OUT NOCOPY      NUMBER,
      x_errbuf          OUT NOCOPY      VARCHAR2,
      p_status          IN              VARCHAR2,
      p_return_status   OUT             VARCHAR2,
      p_error_msg       OUT             VARCHAR2
   )
   IS
      -- local variable declaration
      lc_filehandle             UTL_FILE.file_type;
      lc_file_name              VARCHAR2 (200)     := 'xxod_omx_ap_contacts';
      lc_date                   VARCHAR2 (200)
                                      := '_' || TO_CHAR (SYSDATE, 'MMDDYYYY');
      lc_message                VARCHAR2 (4000);
      lc_mode                   VARCHAR2 (1)       := 'W';
      lc_source_path            VARCHAR2 (500);
      lc_header_string          VARCHAR2 (4000);
      lc_string                 VARCHAR2 (32000);
      lc_error_msg              VARCHAR2 (4000);
      lc_return_status          VARCHAR2 (100);
      lc_email_file             VARCHAR2 (100);
      ln_failed_records         NUMBER;
      ln_records_processed      NUMBER;
      lc_batch_id               NUMBER;
      lc_aops_customer_number   VARCHAR2 (200);
      lc_aops_addr_ref          VARCHAR2 (200);
      lc_success                VARCHAR2 (200);
      lc_utl_file_fopen         VARCHAR2 (2)       := 'Y';
      e_process_exception       EXCEPTION;

      CURSOR cur_contacts
      IS
         SELECT *
           FROM xx_cdh_omx_ap_contacts_stg
          WHERE status = NVL (p_status, 'N')
          order by record_id desc;
   BEGIN
      ln_records_processed := 0;
      ln_failed_records := 0;
      lc_return_status := NULL;
      lc_error_msg := NULL;
      log_msg ('Getting Interface Settings from Translation Definition ..');
      get_interface_settings (p_error_msg => lc_error_msg);

      IF lc_error_msg IS NOT NULL
      THEN
         lc_error_msg :=
               'Getting Interface Settings from Translation Definition failed'
            || ' '
            || SQLERRM;
         RAISE e_process_exception;
      END IF;

-------------------------------------------------------------------------
--Set the lc_filename||date||.csv
-------------------------------------------------------------------------
      lc_file_name :=
                     lc_file_name || lc_date || '_' || gn_request_id || '.csv';
      log_msg ('Opening a utl_file ..');
      fnd_file.put_line (fnd_file.LOG, 'UTLFILE_Path :' || gc_file_path);
      fnd_file.put_line (fnd_file.LOG, 'file_name, :' || lc_file_name);
      fnd_file.put_line(fnd_file.LOG,'**********************************************************************************************************************************************************');
-------------------------------------------------------------------------
---- Building a header string to spit out the the file to the specific
---- output directory
-------------------------------------------------------------------------
      lc_header_string :=
            'Last Name '
         || ','
         || 'First Name'
         || ','
         || 'Email Address'
         || ','
         || 'Telephone Area Code'
         || ','
         || 'Telephone'
         || ','
         || 'Fax Area Code'
         || ','
         || 'Fax Number'
         || ','
         || 'AOPS Account Number'
         || ','
         || 'AOPS Address Sequence'
         || ','
         || 'Contact type';

      FOR cur_contacts_rec IN cur_contacts
      LOOP
         BEGIN
            lc_return_status := NULL;
            lc_error_msg := NULL;
            lc_string := NULL;
            lc_aops_addr_ref:= NULL;
			
            log_msg ('Processing record_id ....' || cur_contacts_rec.record_id ||' For Customer Number '|| cur_contacts_rec.customer_number);
            
                   fnd_file.put_line (fnd_file.LOG,
                                  'bill_consignee_ref :'
                               || cur_contacts_rec.bill_consignee_ref
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'aops_customer_number :'
                               || cur_contacts_rec.aops_customer_number
                              );

 -------------------------------------------------------------------------
-- Calling the procedure get_customer_aops_detail
-------------------------------------------------------------------------
            IF cur_contacts_rec.bill_consignee_ref IS NOT NULL
            THEN
               get_aops_addr_reference
                  (p_omx_bill_consignee      => cur_contacts_rec.bill_consignee_ref,
                   p_aops_cust_number        => cur_contacts_rec.aops_customer_number,
                   p_aops_addr_ref           => lc_aops_addr_ref,
                   p_return_status           => lc_return_status,
                   p_error_msg               => lc_error_msg
                  );

               IF (lc_return_status != gc_success)
               THEN 
                  IF lc_error_msg is null then
                  lc_error_msg :='customer_AOPS_detail no data found';
                  END IF;
                  RAISE e_process_exception;
               END IF;
            END IF;

 -------------------------------------------------------------------------
 -- UTL_FILE.fopen
-------------------------------------------------------------------------
            IF lc_utl_file_fopen = 'Y'
            THEN
               lc_filehandle :=
                         UTL_FILE.fopen (gc_file_path, lc_file_name, lc_mode);
               UTL_FILE.put_line (lc_filehandle, lc_header_string);
               lc_utl_file_fopen := 'N';
            END IF;

-------------------------------------------------------------------------
---- Building a Detail string to spit out the the file to the specific
---- output directory
-------------------------------------------------------------------------
            lc_string :=
                  NVL (cur_contacts_rec.contact_last_name, 'Payable')
               || ','
               || NVL (cur_contacts_rec.contact_first_name, 'Accounts')
               || ','
               || cur_contacts_rec.email_address
               || ','
               || cur_contacts_rec.phone_area_code
               || ','
               || cur_contacts_rec.phone_number
               || ','
               || cur_contacts_rec.fax_area_code
               || ','
               || cur_contacts_rec.fax_number
               || ','
               || cur_contacts_rec.aops_customer_number
               || ','
               || '='
               || '"'
               || lc_aops_addr_ref
               || '"'
               || ','
               || cur_contacts_rec.contact_type;
            UTL_FILE.put_line (lc_filehandle, lc_string);
-------------------------------------------------------------------------
--Procedure to Updatethe status to 'C'in table xx_cdh_omx_ap_contacts_stg
--------------------------------------------------------------------------
            update_ap_contacts_stg (p_status         => 'C',
                                    p_record_id      => cur_contacts_rec.record_id,
                                    p_error_msg      => lc_error_msg
                                   );
--------------------------------------------------------------------------
--Count Sucessful records loaded
--------------------------------------------------------------------------
            ln_records_processed := ln_records_processed + 1;
         EXCEPTION
            WHEN UTL_FILE.invalid_mode
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20052, 'Invalid Mode');  
            WHEN UTL_FILE.internal_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20053, 'Internal Error');
            WHEN UTL_FILE.invalid_operation
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20054, 'Invalid Operation');
            WHEN UTL_FILE.invalid_filehandle
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20055, 'Invalid Filehandle');
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20056, 'Write Error');
            WHEN OTHERS
            THEN
               IF lc_error_msg IS NULL
               THEN
                  lc_error_msg :=
                        'Unable to fetch data cur_contacts error:'
                     || ' '
                     || SQLERRM;
               END IF;

               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.PROCESS_BILL_CONTACTS',
                   p_error_msg           => lc_error_msg
                  );
               log_msg ('Rollback the changes ..');
               ROLLBACK;
-------------------------------------------------------------------------
--Procedure to Updatethe status to 'E'in table xx_cdh_omx_ap_contacts_stg
--------------------------------------------------------------------------
               update_ap_contacts_stg
                                   (p_status         => 'E',
                                    p_record_id      => cur_contacts_rec.record_id,
                                    p_error_msg      => lc_error_msg
                                   );
               ln_failed_records := ln_failed_records + 1;
         END;

         lc_batch_id := cur_contacts_rec.batch_id;
                     
     fnd_file.put_line (fnd_file.LOG, '*****************************************************************************************************************************************************');  
     log_msg ('Commit the error log changes ..');
      COMMIT;  
      END LOOP;


      UTL_FILE.fclose (lc_filehandle);
      fnd_file.put_line (fnd_file.LOG, '********************************************************************************');
      fnd_file.put_line (fnd_file.LOG,
                         'Number Successfully ..' || ln_records_processed
                        );
      fnd_file.put_line (fnd_file.LOG,
                         'Number failed ....' || ln_failed_records
                        );
      fnd_file.put_line(fnd_file.LOG,'********************************************************************************');

      IF ln_records_processed >= 1
      THEN
         BEGIN
------------------------------------------------------------------
-- Calling  send_mail procedure  to move the  file to
-- destination/archive Directory and also to email
------------------------------------------------------------------
            lc_return_status := NULL;
            lc_error_msg := NULL;
            log_msg ('Calling  procedure email_file');
            --send_mail procedure OMX AP Contacts Report
            send_mail
               (p_file_name          => lc_file_name,
                p_email_subject      => 'OMX AP Contacts - Mass Upload - ',
                p_email_body         => 'The attached file contains multiple customers with additional AP contacts. Please perform the mass upload accordingly .',
                p_return_status      => lc_return_status,
                p_return_msg         => lc_error_msg
               );
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_msg :=
                  'Unable to fetch date to send_mail error:' || ' '
                  || SQLERRM;
               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.PROCESS_BILL_CONTACTS',
                   p_error_msg           => lc_error_msg
                  );
         END;
      END IF;

      IF ln_failed_records >= 1
      THEN
         BEGIN
            lc_return_status := NULL;
            lc_error_msg := NULL;
            lc_file_name := NULL;
            log_msg ('Calling Process generate_exception_report ..');
            generate_exception_report (x_retcode        => x_retcode,
                                       x_errbuf         => x_errbuf,
                                       p_file_name      => lc_file_name,
                                       p_error_msg      => lc_error_msg
                                      ); 
--------------------------------------
--Send email procedure Exception Email
--------------------------------------
            log_msg ('Calling  procedure Send mail');
            send_mail
               (p_file_name          => lc_file_name,
                p_email_subject      => 'Exception OMX AP Contacts - Mass Upload - ',
                p_email_body         => 'The attached file contains multiple customers with Exceptions .',
                p_return_status      => lc_return_status,
                p_return_msg         => lc_error_msg
               );
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_msg :=
                  'Unable to fetch date to send_mail error:' || ' '
                  || SQLERRM;
               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.PROCESS_BILL_CONTACTS',
                   p_error_msg           => lc_error_msg
                  );
         END;
      END IF;

-----------------------
-- calling log_table procedure
-----------------------
      log_msg ('Calling  procedure log msg');
      log_file (p_success_records      => ln_records_processed,
                p_faliure_records      => ln_failed_records,
                p_batch_id             => lc_batch_id,
                p_file_name            => lc_file_name,
                p_status               => 'C'
               );
               
 fnd_file.put_line (fnd_file.LOG, '*****************************************************************************************************************************************************');        
   EXCEPTION
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to fetch date :' || ' ' || SQLERRM;
         END IF;

         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.PROCESS_BILL_CONTACTS',
             p_error_msg           => lc_error_msg
            );
   END process_bill_contacts;

   PROCEDURE EXTRACT (
      x_retcode      OUT NOCOPY      NUMBER,
      x_errbuf       OUT NOCOPY      VARCHAR2,
      p_status       IN              VARCHAR2,
      p_debug_flag   IN              VARCHAR2
   )
   IS
      lc_error_message   VARCHAR2 (500);
      lc_return_status   VARCHAR2 (10);
      lc_error_msg       VARCHAR2 (200);
-- +===================================================================+
-- | Name  : extract                                                   |
-- | Description     : The Purpose of the procedure is to pick the     |
--|                     entire omx contacts from the oms staging tables|
--                     and write it into the a file .Once done it will |
--                     be either emailed or FTP’d to web collect .     |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+
   BEGIN
      fnd_file.put_line
         (fnd_file.LOG,
          '********************************************************************************'
         );
      fnd_file.put_line (fnd_file.LOG, 'Input parameters .....:');
      fnd_file.put_line (fnd_file.LOG, 'p_debug_flag: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, 'p_status:' || p_status);
      fnd_file.put_line
         (fnd_file.LOG,
          '********************************************************************************'
         );

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;

      log_msg ('Calling Process bill contacts ..');
      process_bill_contacts (x_retcode            => x_retcode,
                             x_errbuf             => x_errbuf,
                             p_status             => p_status,
                             p_return_status      => lc_return_status,
                             p_error_msg          => lc_error_message
                            );
      log_msg ('Commit the changes ..');
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
      ROLLBACK;
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to process ' || SQLERRM;
         END IF;

         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.EXTRACT',
                        p_error_msg           => lc_error_msg
                       );
         x_retcode := 2;
         COMMIT;
   END EXTRACT;
END xx_cdh_omx_contacts_pkg; 
/
SHOW ERRORS;
