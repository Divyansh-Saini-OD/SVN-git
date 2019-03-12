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

      p_param := ' AND 1=1';

      IF p_vendor_site_id IS NOT NULL THEN
        p_param := p_param
                   || ' AND TO_NUMBER(regexp_replace(assa.vendor_site_code, ''[^[:digit:]]'', '''')) = '
                   || p_vendor_site_id;
      END IF;

      RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
               fnd_file.Put_line (fnd_file.log, 'ERROR at XX_AP_DSDISTRPT_PKG.beforeReport:- '
                                                || SQLERRM);
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

      fnd_file.Put_line (fnd_file.log, 'Completed ');

      COMMIT;

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
      /*+ LEADING(AIA AILA AIDA) FULL(AIA) PARALLEL(AIA) PARALLEL(AILA) PARALLEL(AIDA) NO_MERGE */ 
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
      FROM   apps.mtl_system_items_b msb,
             apps.mtl_parameters mp
      WHERE  msb.inventory_item_id = aila.inventory_item_id
      AND mp.master_organization_id = mp.organization_id
      AND mp.organization_id = msb.organization_id)    sku,
      gcc.segment3 gl_account
      FROM   apps.ap_invoices_all aia,
             apps.ap_invoice_lines_all aila,
             apps.ap_invoice_distributions_all aida,
             apps.gl_code_combinations gcc,
             apps.po_headers_all pha,
             apps.hr_locations_all hla
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
                         FROM   apps.ap_invoice_distributions_all aida1
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

  EXCEPTION
    WHEN OTHERS THEN
               x_retcode := 1;

               fnd_file.Put_line (fnd_file.log, 'Error in burst report procedure '
                                                || SQLERRM);
  END extract_data;
END xx_ap_dsdistrpt_pkg;
/

SHOW ERRORS;