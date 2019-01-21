create or replace
PACKAGE BODY xx_ap_dcn_pkg
IS

-- +=============================================================================================+
-- |  Office Depot - Project Simplify                                                            |
-- |                                                                                             |
-- +=============================================================================================+
-- |  Name:  XX_AP_DCN_PKG                                                                       |
-- |  Description:  This package is used to process DCN data from the vendor ACS                 |
-- |                                                                                             |
-- |  Change Record:                                                                             |
-- +=============================================================================================+
-- | Version     Date         Author            Remarks                                          |
-- | =========   ===========  =============     ===============================================  |
-- | 1.0         03/10/2007   Anamitra Banerjee Initial version                                  |
-- | 2.0         12/16/2009   Joe Klein         Defects 3359 and 2908                            |
-- |                                            Added process_dcn_records procedure to replace   |
-- |                                            sql plus script XXAPDCNINT.sql.  See that script |
-- |                                            for all defects previous to this procedure that  |
-- |                                            are included in this new procedure.              |
-- | 2.1         08/23/2013   Avinash Baddam    I1358 - Modified for R12 Upgrade Retrofit        |
-- | 2.2         10/27/2015   Harvinder Rakhra  Modified for R12.2 Upgrade Retrofit              |
-- +=============================================================================================+



-- ===========================================================================
-- Procedure for processing DCN records
-- ===========================================================================
  PROCEDURE process_dcn_records
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2)
  IS
    v_filename VARCHAR2(100);
    v_dir_name VARCHAR2(100);
    v_row_count VARCHAR(20);
    v_file_date CHARACTER(15);
    v_trail_date CHARACTER(20);
    v_out_header VARCHAR2(262);
    v_out_trailer VARCHAR2(100);
    v_log_msg VARCHAR2(100);
    file UTL_FILE.FILE_TYPE;
    
    -- variables for file copy
    ln_req_id    	NUMBER;
    lc_sourcepath varchar2(1000);
    lc_destpath 	varchar2(1000);
    lb_result      boolean;
    lc_phase      varchar2(1000);
    lc_status     varchar2(1000);
    lc_dev_phase  varchar2(1000);
    lc_dev_status varchar2(1000);
    lc_message    varchar2(1000);
    lc_err_status varchar2(10);
    lc_err_mesg   varchar2(1000);
    lc_err_flag   VARCHAR2(10) := 'N';
    
    CURSOR c_out IS
      SELECT out_rec
      FROM (
            SELECT /*+ use_nl(stg api glc aip apc poh) index(api AP_INVOICES_N6) */ 'H'
            ||'|'
            ||api.attribute9
            ||'|'
            ||api.invoice_date
            ||'|'
            ||api.invoice_amount
            ||'|'
            ||glc.segment4
            ||'|'
            ||poh.segment1
            ||'|'
            ||DECODE(api.cancelled_date,NULL,'N','Y')
            ||'|'
            ||apc.check_number
            ||'|'
            ||apc.amount
            ||'|'
            ||DECODE(apc.status_lookup_code,'VOIDED','Y',
                                            'SPOILED','Y',
                                            'OVERFLOW','Y',
                                            'N')
            ||'|'
            ||apc.check_date out_rec
            FROM  gl_code_combinations glc,
                  ap_checks_all apc,
                  ap_invoice_payments_all aip,
                  ap_invoices_all api,
                  po_headers_all poh,
                  xx_ap_dcn_stg stg
            WHERE api.invoice_id = aip.invoice_id (+)
              AND aip.check_id = apc.check_id
              AND api.accts_pay_code_combination_id = glc.code_combination_id
              AND api.po_header_id = poh.po_header_id (+)
              AND api.payment_status_flag != 'N'
              AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
              AND stg.invoice_num = api.invoice_num
              AND stg.invoice_date = api.invoice_date
              AND stg.status = 'PROCESSING'
            UNION
            SELECT /*+ use_nl(stg api glc aip poh) index(api AP_INVOICES_N6) */ 'H'
            ||'|'
            ||api.attribute9
            ||'|'
            ||api.invoice_date
            ||'|'
            ||api.invoice_amount
            ||'|'
            ||glc.segment4
            ||'|'
            ||poh.segment1
            ||'|'
            ||DECODE(api.cancelled_date,NULL,'N','Y')
            ||'||||'
            FROM  gl_code_combinations glc,
                  ap_invoice_payments_all aip,
                  ap_invoices_all api,
                  po_headers_all poh,
                  xx_ap_dcn_stg stg
            WHERE api.invoice_id = aip.invoice_id (+)
              AND api.accts_pay_code_combination_id = glc.code_combination_id
              AND api.po_header_id = poh.po_header_id (+)
              AND api.payment_status_flag = 'N'
              AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
              AND stg.invoice_num = api.invoice_num
              AND stg.invoice_date = api.invoice_date
              AND stg.status = 'PROCESSING'
            UNION
            SELECT /*+ use_nl(stg api apd glc pap pat) index(api AP_INVOICES_N6) */ 'D'
            ||'|'
            ||api.attribute9
            ||'|'
            ||apd.distribution_line_number
            ||'|'
            ||apd.amount
            ||'|'
            ||glc.segment4
            ||'|'
            ||glc.segment2
            ||'|'
            ||glc.segment3
            ||'|'
            ||glc.segment1
            ||'|'
            ||glc.segment6
            ||'|'
            ||pap.segment1
            ||'|'
            ||pat.task_number
            ||'|'
            ||apd.line_type_lookup_code
            FROM  gl_code_combinations glc,
                  ap_invoice_distributions_all apd,
                  ap_invoices_all api,
                  pa_tasks pat,
                  pa_projects_all pap,
                  xx_ap_dcn_stg stg
            WHERE api.invoice_id = apd.invoice_id
              AND apd.dist_code_combination_id = glc.code_combination_id
              AND apd.project_id = pap.project_id (+)
              AND apd.task_id = pat.task_id (+)
              AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
              AND stg.invoice_num = api.invoice_num
              AND stg.invoice_date = api.invoice_date
              AND stg.status = 'PROCESSING'
            ORDER BY 1 DESC
           );

  BEGIN
  
    SELECT directory_path 
    INTO   v_dir_name
    FROM   dba_directories
    WHERE  directory_name = 'XXFIN_OUTBOUND';
    
    -- Recycle all old error records
    v_log_msg := 'Recycling old error records... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE xx_ap_dcn_stg
    SET status = NULL
    WHERE status = 'ERROR';
    COMMIT;
    
    -- Trim right spaces from staging invoice number
    v_log_msg := 'Trimming spaces from invoice number... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE xx_ap_dcn_stg stg
    SET stg.invoice_num = rtrim(stg.invoice_num)
    WHERE rtrim(stg.invoice_num) IS NOT NULL
      AND stg.status IS NULL;
    COMMIT;

    -- Matching DCN records with Invoices
    v_log_msg := 'Matching DCN records with invoices... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE xx_ap_dcn_stg stg
    SET    stg.status = (SELECT 'PROCESSING'
                         FROM  ap_invoices_all api
                         WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                           AND stg.invoice_num = api.invoice_num
                           AND stg.invoice_date = api.invoice_date
		                       AND ROWNUM = 1)
    WHERE  stg.status IS NULL ;
    COMMIT;

    -- Updating Invoices with DCN
    v_log_msg := 'Updating invoices with DCN... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE ap_invoices_all api
    SET    api.attribute9 = (SELECT stg.dcn
                             FROM  xx_ap_dcn_stg stg
                             WHERE stg.status = 'PROCESSING'
                               AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                               AND stg.invoice_num = api.invoice_num
                               AND stg.invoice_date = api.invoice_date
                               AND ROWNUM = 1)
    WHERE  (api.attribute9 IS NULL)
      AND  api.invoice_num IN (SELECT invoice_num FROM xx_ap_dcn_stg WHERE status = 'PROCESSING');
    COMMIT; 
    
    -- DCN exception handling
    v_log_msg := 'Identifying errors... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE xx_ap_dcn_stg stg
    SET    stg.status = 'ERROR'
    WHERE  stg.status IS NULL 
      AND  NOT EXISTS (SELECT invoice_id
                       FROM  ap_invoices_all api
                       WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                         AND stg.invoice_num = api.invoice_num
                         AND stg.invoice_date = api.invoice_date);
    COMMIT;
    
    -- Determine record count
    v_log_msg := 'Determining record count... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    SELECT /*+ use_nl(apd) */ '|' ||to_char(COUNT(DISTINCT apd.invoice_id) + COUNT(DISTINCT (to_char(apd.invoice_id)
             ||to_char(distribution_line_number)))) INTO v_row_count
    FROM   ap_invoice_distributions_all apd
    WHERE apd.invoice_id in
      (SELECT /*+ use_nl(stg api) index(api AP_INVOICES_N6) */api.invoice_id
       FROM xx_ap_dcn_stg stg, ap_invoices_all api
       WHERE stg.status = 'PROCESSING'
         AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num) ,sysdate) = api.vendor_site_id
         AND stg.invoice_num= api.invoice_num
         AND stg.invoice_date = api.invoice_date);

    v_file_date   := to_char(SYSDATE,'YYYYMMDD_HH24MISS');
    v_filename    := 'TDM_APDCNINT_' || v_file_date || '.dat';
    v_trail_date  := to_char(SYSDATE,'DD-MON-YYYY||HH24:MI:SS');
    v_out_header  := 'RECORD TYPE|DCN|INVOICE DATE OR LINE NUMBER|INVOICE OR DISTRIBUTION AMOUNT|LOCATION|PO NUMBER OR COST CENTER|INVOICE CANCEL FLAG OR ACCOUNT|CHECK NUMBER OR COMPANY|CHECK AMOUNT OR LINE OF BUSINESS|VOIDED FLAG OR PROJECT NUMBER|CHECK DATE OR TASK NUMBER|LINE TYPE';
    v_out_trailer := '3|' || v_filename || '|' || v_trail_date || v_row_count;

    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'v_file_date = ' || v_file_date);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'v_trail_date = ' || v_trail_date);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'v_out_header = ' || v_out_header);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'v_out_trailer = ' || v_out_trailer);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'v_dir_name = ' || v_dir_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'v_filename = ' || v_filename);    
    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
   
    -- outbound extract 
    v_log_msg := 'Writing output file... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    file:= UTL_FILE.FOPEN('XXFIN_OUTBOUND', v_filename, 'W'); 
    UTL_FILE.PUT_LINE(file, v_out_header);
    FOR c_out_rec IN c_out LOOP
      UTL_FILE.PUT_LINE(file, c_out_rec.out_rec);
    END LOOP;
    UTL_FILE.PUT_LINE(file, v_out_trailer);
    UTL_FILE.FCLOSE(file);
    
    --Submit the Request to copy the file from XXFIN_OUTBOUND directory to XXFIN_DATA/ftp/out and to archive the file
    v_log_msg := 'Archiving file... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
			        	                         ,'XXCOMFILCOPY'
					                               ,''
                                         ,''
                                         ,FALSE
                                           ,v_dir_name ||'/'||v_filename
                                           ,'$XXFIN_DATA/ftp/out/tdm/'||v_filename
                                           ,'','','Y','$XXFIN_DATA/archive/outbound');
    COMMIT;

    IF ln_req_id > 0 THEN
     lb_result:=fnd_concurrent.wait_for_request(
               ln_req_id,
               10,
               0,
               lc_phase      ,
               lc_status     ,
               lc_dev_phase  ,
               lc_dev_status ,
               lc_message    );
    END IF;

    IF trim(lc_status) = 'Error' THEN
      lc_err_status := 'Y' ;
      lc_err_mesg := 'File Copy Failed : '||v_filename||
                     ': Please check the Log file for Request ID : '||ln_req_id;
      FND_FILE.PUT_LINE(fnd_file.log,'Error : ' || lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM) ;
    END IF;



    -- Updating status on processed DCN records
    v_log_msg := 'Setting status to UPDATED... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    UPDATE xx_ap_dcn_stg stg
    SET    stg.status = REPLACE(stg.status,'PROCESSING','UPDATED')
    WHERE  stg.status = 'PROCESSING';
    COMMIT;

    -- Purging matched DCN records
    v_log_msg := 'Purging matched DCN records... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    DELETE FROM xx_ap_dcn_stg stg
    WHERE stg.status = 'UPDATED'
      AND EXISTS (SELECT /*+ index(api AP_INVOICES_N6) */ api.invoice_id
                        FROM  ap_invoices_all api
                        WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                          AND stg.invoice_num = api.invoice_num
                          --AND api.payment_status_flag = 'Y' --defect 2908
                          AND stg.invoice_date = api.invoice_date
                  );
    COMMIT;
    
    -- Purging outdated DCN errors, defect 2908
    v_log_msg := 'Purging outdated DCN errors... ' || to_char(sysdate, 'YYYY-MM-DD HH24:mi:ss');
    FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    DELETE FROM xx_ap_dcn_stg stg
    WHERE ROUND(TO_NUMBER(sysdate - stg.creation_date),0) > 105
      AND stg.status = 'ERROR';
    COMMIT;

  END process_dcn_records;
  
-- ===========================================================================
-- Function for getting the correct vendor pay site for an invoice
-- =========================================================================== 
  
  FUNCTION get_pay_site
       (v_global_vendor_id  VARCHAR2,
        v_sysdate           DATE DEFAULT SYSDATE)
  RETURN NUMBER
  IS
    --commented and added by Avinash(v2.1) for R12 Upgrade Retrofit
    --v_vendor_site_id  po_vendor_sites_all.vendor_site_id%TYPE := 0;
    v_vendor_site_id  ap_supplier_sites_all.vendor_site_id%TYPE := 0;
  BEGIN
    BEGIN
      SELECT vendor_site_id
      INTO   v_vendor_site_id
      --commented and added by Avinash(v2.1) for R12 Upgrade Retrofit
      FROM   --po_vendor_sites_all
             ap_supplier_sites_all
      WHERE  nvl(ltrim(attribute9,'0'),to_char(vendor_site_id)) = ltrim(v_global_vendor_id,'0')
             AND pay_site_flag = 'Y'
             AND trunc(nvl(inactive_date,v_sysdate + 1)) > trunc(v_sysdate);
    EXCEPTION
      WHEN too_many_rows THEN
        SELECT vendor_site_id
        INTO   v_vendor_site_id
        --commented and added by Avinash(v2.1) for R12 Upgrade Retrofit
        FROM   --po_vendor_sites_all
               ap_supplier_sites_all
        WHERE  nvl(ltrim(attribute9,'0'),to_char(vendor_site_id)) = ltrim(v_global_vendor_id,'0')
               AND primary_pay_site_flag = 'Y'
               AND trunc(nvl(inactive_date,v_sysdate + 1)) > trunc(v_sysdate);
      WHEN no_data_found THEN
        SELECT vendor_site_id
        INTO   v_vendor_site_id
        --commented and added by Avinash(v2.1) for R12 Upgrade Retrofit
        FROM   --po_vendor_sites_all
               ap_supplier_sites_all
        WHERE  nvl(ltrim(attribute9,'0'),to_char(vendor_site_id)) = ltrim(v_global_vendor_id,'0')
               AND trunc(nvl(inactive_date,v_sysdate + 1)) > trunc(v_sysdate);
      WHEN OTHERS THEN
        v_vendor_site_id := - 1;
    END;

    RETURN v_vendor_site_id;
  END get_pay_site;
END xx_ap_dcn_pkg;
/