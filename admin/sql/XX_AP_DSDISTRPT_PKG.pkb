SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE; 
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY xx_ap_dsdistrpt_pkg
IS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AP_DSDISTRPT_PKG                                                                |
  -- |                                                                                            |
  -- |  Description: Package for OD: AP Dropship Distributions Report                             |
  -- |  RICE ID   : R7049 Dropship Distributions Report                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         28-JAN-2019  Naveen Srinivasa     Initial Version                              |
  -- +============================================================================================|
  -- +============================================================================================+
  -- |  Name  : beforereport                                                                      |
  -- |  Description: Before Report trigger function which will derive email details               |
  -- =============================================================================================|
  FUNCTION Beforereport
  RETURN BOOLEAN
  IS
  BEGIN
      xx_ap_xml_bursting_pkg.Get_email_detail ('XXAPDSDISTRPT', g_smtp_server, g_email_subject, g_email_content, g_distribution_list);

      p_where_clause := ' AND 1=1';
	  p_from_clause  := ' ' ;

      IF p_vendor_site_id IS NOT NULL THEN
        p_where_clause := p_where_clause
                          || ' AND TO_NUMBER(regexp_replace(assa.vendor_site_code, ''[^[:digit:]]'', '''')) = '
                          || p_vendor_site_id;
      END IF;
      
      IF p_period_from IS NULL
        AND p_period_to IS NULL
        AND p_gl_date_from IS NULL
        AND p_gl_date_to IS NULL
      THEN
        fnd_file.Put_line (fnd_file.log,'Please provide values for either Period From/To or GL Booked Date From/To parameters');
        RETURN FALSE;
      END IF;
      
      IF (p_period_from IS NOT NULL
        AND p_period_to IS NULL) 
        OR (p_period_from IS NULL
        AND p_period_to IS NOT NULL)
      THEN
        fnd_file.Put_line (fnd_file.log,'Please provide values for both Period From and Period To parameters');
        RETURN FALSE;
      ELSIF p_period_from IS NOT NULL
        AND p_period_to IS NOT NULL
      THEN
        p_from_clause := ' , gl_period_statuses gps_from '
                      || ', gl_period_statuses gps_to ';
    
        p_where_clause := p_where_clause
                          || ' AND gps_from.application_id = 200'
                          || ' AND gps_from.adjustment_period_flag <> ''Y'''
                          || ' AND aia.set_of_books_id = gps_from.set_of_books_id'
                          || ' AND gps_to.application_id = 200'
                          || ' AND gps_to.adjustment_period_flag <> ''Y'''
                          || ' AND aia.set_of_books_id = gps_to.set_of_books_id'
                          || ' AND aida.accounting_date BETWEEN gps_from.start_date AND gps_to.end_date'
                          || ' AND gps_from.period_name = ''' || p_period_from || ''''
                          || ' AND gps_to.period_name = ''' || p_period_to || '''';
      END IF;      

      IF (p_gl_date_from IS NOT NULL
        AND p_gl_date_to IS NULL) 
        OR (p_gl_date_from IS NULL
        AND p_gl_date_to IS NOT NULL)
      THEN
        fnd_file.Put_line (fnd_file.log,'Please provide values for both GL Booked Date From and GL Booked Date To parameters');
        RETURN FALSE;
      ELSIF p_gl_date_from IS NOT NULL
        AND p_gl_date_to IS NOT NULL
      THEN
        p_where_clause := p_where_clause
                          || ' AND aida.accounting_date BETWEEN fnd_date.canonical_to_date('''
                          || p_gl_date_from
                          || ''')'
                          || ' AND fnd_date.canonical_to_date('''
                          || p_gl_date_to
                          || ''')';
      END IF;
      
      RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.Put_line (fnd_file.log, 'ERROR at XX_AP_DSDISTRPT_PKG.beforeReport:- ' || SQLERRM);
  END beforereport;
  
  -- +============================================================================================+
  -- |  Name  : afterreport                                                                       |
  -- |  Description: After Report trigger function which submit bursting concurrent program       |
  -- =============================================================================================|
  FUNCTION Afterreport
  RETURN BOOLEAN
  IS
    l_request_id NUMBER;
  BEGIN
      p_conc_request_id := fnd_global.conc_request_id;

      fnd_file.Put_line (fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');

      l_request_id := fnd_request.Submit_request ('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', p_conc_request_id, 'Y');

      COMMIT;
	  
	  fnd_file.Put_line (fnd_file.log, 'Request ID : ' || l_request_id);

      RETURN ( TRUE );
  EXCEPTION
    WHEN OTHERS THEN
               fnd_file.Put_line (fnd_file.log, 'Unable to submit burst request '
                                                || SQLERRM);
  END afterreport;

  -- +============================================================================================+
  -- |  Name  : extract_data                                                                      |
  -- |  Description: Procedure to fetch Dropship Distributions for selected period                |
  -- =============================================================================================|  
  PROCEDURE Extract_data (x_errbuf  OUT nocopy VARCHAR2,
                          x_retcode OUT nocopy NUMBER,
                          p_period  IN VARCHAR2)
  IS
    lc_delimiter         VARCHAR2 (30) := Chr (09);
    lc_file_name         VARCHAR2 (100);
    lc_file_path         VARCHAR2 (500) := 'XXFIN_OUTBOUND';
    lc_source_file_path  VARCHAR2 (500);
    lc_dest_file_path    VARCHAR2 (500);
    lc_archive_file_path VARCHAR2 (500);
    lc_source_file_name  VARCHAR2 (1000);
    lc_dest_file_name    VARCHAR2 (1000);
    lc_phase             VARCHAR2 (50);
    lc_status            VARCHAR2 (50);
    lc_dev_phase         VARCHAR2 (50);
    lc_dev_status        VARCHAR2 (50);
    lc_message           VARCHAR2 (50);
    lb_result            BOOLEAN;
    lc_error_msg         VARCHAR2 (4000);
    ln_request_id        NUMBER;
    lt_file              utl_file.file_type;
    ln_buffer            BINARY_INTEGER := 32767;
    lb_error_flag        BOOLEAN := FALSE;
    lc_conn              utl_smtp.connection;
    
    CURSOR get_dropship_dist_c IS
      SELECT
      /*+ LEADING(AIA AILA AIDA) FULL(AIA) PARALLEL(AIA,8) PARALLEL(AILA,8) PARALLEL(AIDA,8) NO_MERGE */ 
      aia.vendor_site_id                                   vendor,
      aia.doc_sequence_value                               voucher_number,
      aia.invoice_num                                      invoice_number,
      To_char (aia.invoice_date, 'MM/DD/YYYY HH24:MI')     invoice_date,
      NULL                                                 cpu_date,
      To_char (aida.accounting_date, 'MM/DD/YYYY HH24:MI') accounting_date,
      aila.attribute11                                     reason_code,
      hla.attribute1                                       location_id,
      NULL                                                 user_id_approved,
      aia.attribute11                                      po_number,
      pha.segment1                                         check_description,
      SUM (aida.amount)                                    gross_amount,
      (SELECT msb.segment1
      FROM   mtl_system_items_b msb,
             mtl_parameters mp
      WHERE  msb.inventory_item_id = aila.inventory_item_id
      AND mp.master_organization_id = mp.organization_id
      AND mp.organization_id = msb.organization_id)    sku,
      gcc.segment3 gl_account
      FROM   ap_invoices_all aia,
             ap_invoice_lines_all aila,
             ap_invoice_distributions_all aida,
             gl_code_combinations gcc,
             po_headers_all pha,
             hr_locations_all hla
      WHERE  aia.invoice_id = aila.invoice_id
         AND aila.line_number = aida.invoice_line_number
         AND aia.invoice_id = aida.invoice_id
         AND aia.org_id = aida.org_id
         AND aila.po_header_id = pha.po_header_id
         AND pha.ship_to_location_id = hla.location_id
         AND aida.dist_code_combination_id = gcc.code_combination_id
         AND aida.posted_flag = 'Y'
         AND aida.period_name = p_period
         AND aia.source = 'US_OD_DROPSHIP'
         AND aida.line_type_lookup_code = 'ACCRUAL'
         AND gcc.segment3 = '22003000'
         AND NOT EXISTS (SELECT 1
                         FROM   ap_invoice_distributions_all aida1
                         WHERE  aia.invoice_id = aida1.invoice_id
                            AND aia.org_id = aida1.org_id
                            AND aida1.posted_flag = 'N')
      GROUP  BY aia.vendor_site_id,
                aia.doc_sequence_value,
                aia.invoice_num,
                aia.invoice_date,
                aida.accounting_date,
                aila.attribute11,
                hla.attribute1,
                aia.attribute11,
                pha.segment1,
                aila.inventory_item_id,
                gcc.segment3
      ORDER  BY invoice_number;
  BEGIN
      fnd_file.Put_line (fnd_file.log, '*************************************************************');

      fnd_file.Put_line (fnd_file.log, 'OD: AP Dropship Distributions Extract');

      fnd_file.Put_line (fnd_file.log, 'Period Name  : '
                                       || p_period);

      fnd_file.Put_line (fnd_file.log, '-------------------------------------------------------------');

      fnd_file.Put_line (fnd_file.output, '*************************************************************');

      fnd_file.Put_line (fnd_file.output, 'OD: AP Dropship Distributions Extract');

      fnd_file.Put_line (fnd_file.output, 'Period Name  : '
                                          || p_period);

      fnd_file.Put_line (fnd_file.output, '-------------------------------------------------------------');

      BEGIN
          SELECT directory_path
          INTO   lc_source_file_path
          FROM   dba_directories
          WHERE  directory_name = lc_file_path;
      EXCEPTION
          WHEN OTHERS THEN
            fnd_file.Put_line (fnd_file.log, 'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                             || SQLERRM);
      END;

      lc_file_name := 'AP_DropShip_Distribution_Extract_'
                      || p_period
                      || '.tsv';

      fnd_file.Put_line (fnd_file.log, 'Extract File Name : '
                                       || lc_file_name);

      fnd_file.Put_line (fnd_file.log, 'File Path         : '
                                       || lc_source_file_path);

      fnd_file.Put_line (fnd_file.log, '*************************************************************');

      BEGIN
          lt_file := utl_file.Fopen (lc_file_path, lc_file_name, 'w', ln_buffer);
      EXCEPTION
          WHEN OTHERS THEN
            fnd_file.Put_line (fnd_file.log, 'Exception raised while Opening the file. '
                                             || SQLERRM);
      END;

      utl_file.Put_line (lt_file, 'VENDOR'
                                  || lc_delimiter
                                  || 'VOUCHER_NUMBER'
                                  || lc_delimiter
                                  || 'INVOICE_NUMBER'
                                  || lc_delimiter
                                  || 'INVOICE_DATE'
                                  || lc_delimiter
                                  || 'CPU_DATE'
                                  || lc_delimiter
                                  || 'ACCOUNTING_DATE'
                                  || lc_delimiter
                                  || 'REASON_CODE'
                                  || lc_delimiter
                                  || 'LOCATION_ID'
                                  || lc_delimiter
                                  || 'USER_ID_APPROVED'
                                  || lc_delimiter
                                  || 'PO_NUMBER'
                                  || lc_delimiter
                                  || 'CHECK_DESCRIPTION'
                                  || lc_delimiter
                                  || 'GROSS_AMOUNT'
                                  || lc_delimiter
                                  || 'SKU'
                                  || lc_delimiter
                                  || 'GL_ACCOUNT');

      FOR lcu_dropship_dist_rec IN get_dropship_dist_c LOOP
          utl_file.Put_line (lt_file, lcu_dropship_dist_rec.vendor
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.voucher_number
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.invoice_number
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.invoice_date
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.cpu_date
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.accounting_date
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.reason_code
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.location_id
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.user_id_approved
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.po_number
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.check_description
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.gross_amount
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.sku
                                      || lc_delimiter
                                      || lcu_dropship_dist_rec.gl_account);
      END LOOP;

      utl_file.Fclose (lt_file);

      fnd_file.Put_line (fnd_file.log, 'AP Dropship Distributions have been written into the file successfully.');
      
      fnd_file.Put_line (fnd_file.log, 'Submitting OD: Common Put Program');

      -- Submit File Put Program
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST( application => 'XXFIN'
                                                  ,program     => 'XXCOMFTP'
                                                  ,description => 'OD: Common Put Program'
                                                  ,sub_request => FALSE
                                                  ,argument1   => 'OD_AP_DROPSHIP_DIST_EXT'       -- Row from OD_FTP_PROCESSES translation
                                                  ,argument2   => lc_file_name          -- Source file name
                                                  ,argument3   => lc_file_name          -- Dest file name
                                                  ,argument4   => 'Y'                   -- Delete source file
                                                 );

      COMMIT;

      IF ln_request_id = 0 THEN
        fnd_file.Put_line (fnd_file.log, 'Request not submitted');
      ELSE
        fnd_file.Put_line (fnd_file.log, 'Request ID : ' || ln_request_id);
        lc_phase := NULL;

        lc_status := NULL;

        lc_dev_phase := NULL;

        lc_dev_status := NULL;

        lc_message := NULL;

        << wait_loop >>
        LOOP
            -- Wait for child programs to be completed
            lb_result := fnd_concurrent.Wait_for_request (ln_request_id, 5, 15, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);

            -- Terminated status also added in check
            -- check for the completion of the concurrent program
            IF lc_dev_phase = 'COMPLETE' THEN
              -- check for the status of the concurrent program
              IF lc_dev_status IN ( 'TERMINATED', 'WARNING', 'ERROR' ) THEN
                lb_error_flag := TRUE;
              END IF;

              EXIT wait_loop;
            END IF;
        END LOOP wait_loop;
      END IF;

      -- End File Put
      
      fnd_file.Put_line (fnd_file.log, 'Send Email notification');
      
      IF NOT lb_error_flag THEN
         xx_ap_xml_bursting_pkg.Get_email_detail ('XXAPDSDISTEXT', g_smtp_server, g_email_subject, g_email_content, g_distribution_list);

         lc_conn := xx_pa_pb_mail.Begin_mail (sender => 'AccountsPayable@officedepot.com', recipients => g_distribution_list, cc_recipients => NULL, subject => g_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);

         xx_pa_pb_mail.Attach_text (conn => lc_conn, data => g_email_content);

         xx_pa_pb_mail.End_mail (conn => lc_conn);
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
               x_retcode := 1;

               fnd_file.Put_line (fnd_file.log, 'Error in burst report procedure '
                                                || SQLERRM);
  END extract_data;
END xx_ap_dsdistrpt_pkg;
/

SHOW ERRORS;