create or replace
PACKAGE BODY xx_ap_inv_pmt_outbound_pkg
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       Providge  Consulting                              |
-- +=========================================================================+
-- | Name             :   XX_AP_INV_PMT_OUTBOUND_PKG                         |
-- | Description      :   Generate AP Invoice Payments outbound files        |
-- |                      to Below Vendor Applications                       |
-- |                      1. Big Sky          2. Consignment Inventory       |
-- |                      3. Retail Lease     4. Financial Planning          |
-- |                      5. Sales Accounting 6. PAID  7. TDM  8. GSS        |
-- |                      9. Project Mates     10. Datalink                  |
-- | Rice ID          : I0159                                                |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date         Author              Remarks                       |
-- |=======   ===========  ================  ================================|
-- |1.0       05-Mar-2007  Sarat Uppalapati  Initial version                 |
-- |1.0       05-Jun-2007  Sarat Uppalapati  Big Sky Source Updated          |
-- |1.0       05-Jun-2007  Sarat Uppalapati  SOB Short Name Updated          |
-- |1.0       05-Jun-2007  Sarat Uppalapati  Output files moved to           |
-- |                                        $CUSTOM_DATA/xxfin/ftp/out       |
-- |1.0       14-Jun-2007  Sarat Uppalapati  Added Projectmates Code         |
-- |1.0       14-Jun-2007  Sarat Uppalapati  Deleted Financial Planning      |
-- |1.0       02-Aug-2007  Sarat Uppalapati  Added logic for Translation     |
-- |                                         values for AP_BANK_CODE and     |
-- |                                         AP_PAYMENT_STATUS               |
-- |1.0       11-Sep-2007  Sarat Uppalapati  Changed Program name from       |
-- |                                        XXCOMOUTRED to XXCOMFILCOPY      |
-- |                                                                         |
-- |1.0       19-Sep-2007  Sandeep          Changed ftp outbound directory   |
-- |1.0       01-Oct-2007  Sandeep         Defect 2125 Remove Source for PAID|
-- |1.0       01-Oct-2007  Sandeep          Defect 2274 Change GSS Logic     |
-- |1.0       02-Oct-07    Sandeep          Dates have changed to greater    |
-- |                                        than 10 for LNK testing          |
-- |2.0       10-Oct-2007  Sandeep          Defect 2381 - Formatting for     |
-- |                                        BIG SKY and Project Mates        |
-- |2.0       10-Oct-2007  Sandeep          Defect 2386 - Changes for TDM:   |
-- |}                              Voucher echo KSC_EXIT_STATUS $? 1 number  |
-- |2.1       15-Oct-2007  Sandeep          Defect 2381/2431                 |
-- |2.2       15-Oct-2007  Sandeep          2431 - For PAID file, change the |
-- |amount length to 12                                                      |
-- |2.3       14-Dec-2007  Sandeep          Change Sales Accounting layout   |
-- |2.4       31-Jan-2008  Sandeep          Defect 4096                      |
-- |2.5       31-Jan-2008  Sandeep Pandhare Defect 4381                      |
-- |2.5       23-Jul-2008  Sandeep Pandhare Defect 9190                      |
-- |2.6       17-SEP-2008  Sandeep Pandhare Defect 11014 - Format for PAID   |
-- |2.7       22-SEP-2008  Sandeep Pandhare Defect 11443 -                   |
-- |                       Format for BIGsky/PM                              |
-- |2.8       30-SEP-2008  Sandeep Pandhare Defect 11612 -                   |
-- |                       Splitting of BIGsky File                          |
-- |2.9       13-Oct-2008  Sandeep Pandhare 11935 - Add Date Input Parameter |
-- |2.10      22-Oct-2008  Sandeep Pandhare Add Carriage return to           |
-- |                       the GSS file                                      |
-- |2.10      12-Nov-2008  Sandeep Pandhare Defect 12369 - PAID              |
-- |2.15      16-DEC-2008  Peter Marco      Defect 12642 Added paygroup      |
-- |                                        and check num                    |
-- |2.16      02-MAR-2009  Peter Marco      Defect 13517 Added org_id and    |
-- |                                        check_date to datalink           |
-- |2.17      03-MAR-2009  Peter Marco      Defect 13518  removed sum of     |
-- |                                        check amount from Datalink       |
-- |                                        cursor.                          |
-- |2.18      10-MAR-2009  Peter Marco      Defect 13648 and 13606 Data-     |
-- |                                        link changes                     |
-- |2.19      10-MAR-2009  Peter Marco      Defect 13649                     |
-- |2.20      10-MAR-2009  Peter Marco      DEFECT 13671 EFT payments need   |
-- |                                        to be added to the outbound      |
-- |                                        file for the current date        |
-- |                                        A union was added to the TRADE   |
-- |                                        EFT cursors PAID,TDM, GSS,       |
-- |                                        DATALINK and RETAIL LEASE        |
-- |2.3      22-MAR-2009  Peter Marco       defect 13769 remove leading      |
-- |                                        zero from dsn number in TDM      |
-- |2.4      07-MAY-2009  Peter Marco       Defect 14872 Update statements   |
-- |                                        from defect 13769 to properly    |
-- |                                        handle a zero value being past   |
-- |                                        to the DSN number                |
-- |2.5      09-NOV-2009  Lenny Lee         defect# 2575 update consignment  |
-- |                                        extract.                         |
-- |2.6      15-APR-2009  Dhanya V          Defect#3254 to add a warning     |
-- |                                        message when files are not       |
-- |                                        generated and to add a parameter |
-- |                                        to rerun the program for a       |
-- |                                        specific file.
-- |2.7     25-MAR-2011  Deepti S           Changes for SDR Project in       |
-- |                                        procedure sales_accounting       |
-- |2.8     20-SEP-2011  P Marco            Direct Commerce  CR889 changes   |
-- |2.9     04-OCT-2011  P Marco            Defect 14187, 14184              |
-- |3.0     06-OCT-2011  p Marco            Defect 14192                     |
-- |3.1     06-OCT-2011  P Marco            Defect 14191                     |
-- |3.2     19-OCT-2011  P Marco            Defect 14597                     |
-- |3.3     24-OCT-2011  P Marco            Defect 14706                     |
-- |3.4     04-DEC-2011  Abdul Khan         Modified lcu_main cursor in      |
-- |                                        sales_accounting procedure       |
-- |                                        for POS mailcheck refunds        |
-- |                                        QC Defect # 13669                |
-- |3.5     16-MAR-2013  Ankit Arora        Defect 22217 - Modified lcu_main |
-- |                                        curosr in big_sky_corp ,         |
-- |                                        big_sky_stores and project_mates |
-- |                                        procedure			             |	
-- |3.6     12-Sep-13   Paddy Sanjeevi	    Modified for R12                 |
-- |3.7     10-Apr-14   Santosh             Defect 29459 (Added Hint         |
-- |3.8     16-Apr-14   Darshini            Modified for Defect# 29459       |
-- |3.9     09-Mar-15   Madhu Bolli         Modified to support new source   |
-- |                                        Facilities Source Defect 38896   |
-- |4.0     04-May-15   Madhu Bolli         FMS file should move to          |
-- |                                    $CUSTOM_DATA/xxfin/ftp/out/appayment/|
-- |                                			instead of					 |
-- |							  $CUSTOM_DATA/xxfin/ftp/out/invoicepayment/ |
-- |4.1     05-May-15   Paddy Sanjeevi      Modified to archive the file for Facility|
-- |4.2     04-May-15   Harvinder Rakhra    Retroffit R12.2                  |
-- |4.3     15-Nov-16   Sinon Perlas        Modify Projectmate invoice paymt |
-- |                                        to use MFTP. Replace SOA.        |
-- |5.0     30-Jan-18   Antonio Morales     Add generation for Legal Tracker |
-- |                                                                         |
-- +=========================================================================+
AS

   ln_days   NUMBER := 1 ;

-----------------------------------------------------------------------------------------------------------------------------------

-- +===================================================================+
-- | Name :        Legal                                               |
-- | Description : To create the Payments outbound file to             |
-- |               Legal Tracker Application                           |
-- +===================================================================+

PROCEDURE legal (lc_extract_date IN DATE
                ,x_error_flag OUT VARCHAR2 
                ) IS

 c_legal_dhr  CONSTANT VARCHAR2(500) := '"INVOICE_NUMBER","INVOICE_DATE","OFFICE_VENDOR_ID","FIRM_NAME","PAYMENT_DATE",'||
                                        '"PAYMENT_EXCHANGE_RATE","PAYMENT_NUMBER","PAYMENT_STATUS","PAYMENT_COMMENTS"';
 c_bulk_limit CONSTANT INTEGER := 10000;
 c_dirpath    CONSTANT VARCHAR2 (200) := 'XXFIN_OUTBOUND';

 CURSOR c_legal IS
 SELECT i.invoice_num invoice
       ,vs.vendor_site_id remit_vendor
       ,c.status_lookup_code pymnt_status
       ,c.check_date check_dt
       ,c.check_number check_nbr
       ,i.invoice_date
       ,i.remit_to_supplier_name
       ,i.payment_reason_comments
   FROM ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
       ,ap_payment_schedules_all aps
  WHERE 1=1
    AND c.check_date BETWEEN trunc(lc_extract_date )-1 AND trunc(lc_extract_date)-(1/86400)
    AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
    AND ip.check_id=c.check_id
    AND i.invoice_id=ip.invoice_id 
    AND vs.vendor_site_id=c.vendor_site_id
    AND v.vendor_id=vs.vendor_id 
    AND i.source = 'US_OD_LEGAL'
    AND aps.invoice_id=i.invoice_id
    AND NVL (aps.payment_method_lookup_code, aps.payment_method_code) IN ('EFT')
 UNION ALL
 SELECT i.invoice_num invoice
       ,vs.vendor_site_id remit_vendor
       ,c.status_lookup_code pymnt_status
       ,c.check_date check_dt
       ,c.check_number check_nbr
       ,i.invoice_date
       ,i.remit_to_supplier_name
       ,i.payment_reason_comments
   FROM ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
       ,ap_payment_schedules_all aps
  WHERE 1=1
    AND c.check_date BETWEEN trunc(lc_extract_date) AND trunc(lc_extract_date)+1-(1/86400)
    AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
    AND ip.check_id=c.check_id
    AND i.invoice_id=ip.invoice_id 
    AND vs.vendor_site_id=c.vendor_site_id
    AND v.vendor_id=vs.vendor_id 
    AND i.source = 'US_OD_LEGAL'
    AND aps.invoice_id=i.invoice_id
    AND NVL (aps.payment_method_lookup_code, aps.payment_method_code) = 'CHECK';

 TYPE tlegal IS TABLE OF c_legal%ROWTYPE;
 t_legal tlegal;

 lc_filename        VARCHAR2 (200) := 'XX_AP_LEGAL_INVOICE_PYMT_'||to_char(sysdate,'yyyymmddhh24miss')||'.txt';

 l_fhandle          UTL_FILE.file_type;
 lc_recordstr       VARCHAR2 (2000);
 lc_errbuf          VARCHAR2 (200) := NULL;
 lc_retcode         VARCHAR2 (25)  := NULL;
 ln_req_id          NUMBER;
 lc_error_message   VARCHAR2 (2000);
 lc_err_msg         VARCHAR2 (2000);
 lc_error_flag      VARCHAR2(10) := NULL;


BEGIN

  l_fhandle := UTL_FILE.fopen (c_dirpath, lc_filename, 'w');

  -- Write the header record
  UTL_FILE.put_line (l_fhandle, c_legal_dhr);

  OPEN c_legal;

  LOOP
    FETCH c_legal
     BULK COLLECT
     INTO t_legal LIMIT c_bulk_limit;

    EXIT WHEN t_legal.COUNT = 0;

         FOR i IN t_legal.FIRST .. t_legal.LAST
         LOOP
              lc_recordstr := '"'|| NVL(t_legal(i).invoice,0) || '",' || -- invoice_number
                              to_char(t_legal(i).invoice_date,'mm/dd/yyyy') || ',' || -- invoice_date
                              '"'|| t_legal(i).remit_vendor || '"' || ',' || -- office_vendor_id
                              '"'|| t_legal(i).remit_to_supplier_name || '",' || -- firm_name
                              to_char(t_legal(i).check_dt,'mm/dd/yyyy') || ',' || -- payment_date
                              0 || ',' || -- payment_exchange_rate
                              '"'|| t_legal(i).check_nbr || '",' || -- payment_number
                              '"'|| t_legal(i).pymnt_status || '",' || -- payment_status
                              '"'|| t_legal(i).payment_reason_comments || '",' -- payment_comments
              ;

              UTL_FILE.put_line (l_fhandle, lc_recordstr);
        END LOOP;
  
  END LOOP;

  UTL_FILE.fclose (l_fhandle);

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST  ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');


   dbms_output.put_line('file = ' || '$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename );
   dbms_output.put_line('ln_req_id = ' || ln_req_id);

   IF ln_req_id = 0  THEN

      fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
      fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
      fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
      x_error_flag := 'Y';
      lc_err_msg := fnd_message.get;
      fnd_file.put_line (fnd_file.log, lc_err_msg || ' ' || sqlerrm);
      xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'LEGAL'
                       );

   ELSE
    
     fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
     fnd_file.put_line (fnd_file.output, ' ');
     x_error_flag := 'N';
   END IF;
EXCEPTION
  WHEN OTHERS  THEN
       fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
       fnd_message.set_token ('ERR_ORA', SQLERRM);
       lc_err_msg := fnd_message.get;
       fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
       x_error_flag := 'Y';
       xx_com_error_log_pub.log_error
                                    (p_program_type                => 'CONCURRENT PROGRAM',
                                     p_program_name                => 'XXAPIPOB',
                                     p_program_id                  => fnd_global.conc_program_id,
                                     p_module_name                 => 'AP',
                                     p_error_location              => 'Error ',
                                     p_error_message_count         => 1,
                                     p_error_message_code          => 'E',
                                     p_error_message               => lc_err_msg,
                                     p_error_message_severity      => 'Major',
                                     p_notify_flag                 => 'N',
                                     p_object_type                 => 'LEGAL'
                                    );
       UTL_FILE.fclose (l_fhandle);
END legal;


-----------------------------------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- |         Name : BIG_SKY_CORP                                       |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Big Sky Vendor Application                          |
-- +===================================================================+

PROCEDURE big_sky_corp (  lc_extract_date IN DATE
                         ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                       )
IS
CURSOR lcu_main
IS
SELECT  substr(i.description, 1, 9) 	"WORK_ORDER_NBR"
       ,i.invoice_num 			"INVOICE"
       ,vs.vendor_site_id 		"REMIT_VENDOR"
       ,c.status_lookup_code 		"PYMNT_STATUS"
       ,c.check_date 			"CHECK_DT"
       ,c.check_number 			"CHECK_NBR"
       ,c.amount 			"PAID_AMT"
       ,ip.amount 			"INVC_PAID_AMT"
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE  TRUNC (c.check_date) = trunc(lc_extract_date) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_BIG_SKY_CORP'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='CHECK'
	      )
       -- AND c.payment_method_lookup_code='CHECK' -- 22217 Adding the condition, removed for R12
       -- Defect 11612           AND i.SOURCE IN ('US_OD_BIG_SKY_CORP', 'US_OD_BIG_SKY_STORES');
       -- Defect 22217 -- Starting -- Including union to extract the EFT transactions for current date
UNION
SELECT  substr(i.description, 1, 9) 	"WORK_ORDER_NBR"
       ,i.invoice_num 			"INVOICE"
       ,vs.vendor_site_id 		"REMIT_VENDOR"
       ,c.status_lookup_code 		"PYMNT_STATUS"
       ,c.check_date 			"CHECK_DT"
       ,c.check_number 			"CHECK_NBR" 
       ,c.amount "PAID_AMT"
       ,ip.amount "INVC_PAID_AMT"
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date-1)  --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_BIG_SKY_CORP'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT'
	      );

-- Defect 22217 -- Ending -- Including union to extract the EFT transactions for current date


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'BSCinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lcinvccheckamt     VARCHAR2(12);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.


BEGIN

  -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);

  l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

  FOR rcu_main IN lcu_main
  LOOP
  
    ln_vendor := xx_po_global_vendor_pkg.f_get_outbound (rcu_main.remit_vendor);

         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_PAYMENT_STATUS',
                                p_source_value1         => rcu_main.pymnt_status,
                                x_target_value1         => lc_status,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );


    IF (rcu_main.invc_paid_amt * 100) < 0 THEN

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * -100), 10, '0');
       lcinvccheckamt := lcinvccheckamt || '-' ;

    ELSE

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * 100), 10, '0'); --Defect 2431
       lcinvccheckamt := lcinvccheckamt || '+' ;

    END IF;


    SELECT    RPAD (nvl(rcu_main.work_order_nbr,' '), 9,' ')
                || RPAD (nvl(rcu_main.invoice,' '), 20, ' ')
                || LPAD (to_char(ln_vendor), 9, '0')   -- DEFECT 2381 ,4096
                || RPAD (nvl(lc_status,' '), 4, ' ')
                || RPAD (TO_CHAR (rcu_main.check_dt, 'YYYY-MM-DD'), 10)
                || LPAD (nvl(to_char(rcu_main.check_nbr),' '), 7, ' ') -- defect 4096
                || lcinvccheckamt  -- Defect 11443
                || chr(13)
      INTO lc_recordstr
      FROM DUAL;

     --      fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
     UTL_FILE.put_line (l_fhandle, lc_recordstr);
  
  END LOOP;

  UTL_FILE.fclose (l_fhandle);

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

   IF ln_req_id = 0  THEN

      fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
      fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
      fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
      x_error_flag := 'Y';                           --Added for the Defect 3254.
      lc_err_msg := fnd_message.get;
      fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
      xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'BIG SKY'
                       );

   ELSE
    
     fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
     fnd_file.put_line (fnd_file.output, ' ');
     x_error_flag := 'N';                           --Added for the Defect 3254.
   END IF;
EXCEPTION
  WHEN OTHERS  THEN
    fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
    fnd_message.set_token ('ERR_ORA', SQLERRM);
    lc_err_msg := fnd_message.get;
    fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
    x_error_flag := 'Y';                           --Added for the Defect 3254.
    xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'BIG SKY'
                                 );
    UTL_FILE.fclose (l_fhandle);
END big_sky_corp;


-- +===================================================================+
-- |         Name : BIG_SKY_STORES                                            |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Big Sky Vendor Application                          |
-- +===================================================================+

PROCEDURE big_sky_stores(  lc_extract_date IN DATE
                          ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                        )
IS
CURSOR lcu_main
IS
SELECT   substr(i.description, 1, 9) 		"WORK_ORDER_NBR" 
	,i.invoice_num 				"INVOICE"
        ,vs.vendor_site_id 			"REMIT_VENDOR"
        ,c.status_lookup_code 			"PYMNT_STATUS"
	,c.check_date 				"CHECK_DT"
        ,c.check_number 			"CHECK_NBR"
	,c.amount 				"PAID_AMT"
        ,ip.amount 				"INVC_PAID_AMT"
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE  TRUNC(c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_BIG_SKY_STORES'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='CHECK'
	      )
   -- defect 11612  AND i.SOURCE IN ('US_OD_BIG_SKY_CORP', 'US_OD_BIG_SKY_STORES');
   -- AND c.payment_method_lookup_code='CHECK' --22217 Adding condition 
   -- Defect 22217 -- Starting -- Including union to extract the EFT transactions for current date
UNION
SELECT  substr(i.description, 1, 9) 	"WORK_ORDER_NBR"
       ,i.invoice_num 			"INVOICE"
       ,vs.vendor_site_id 		"REMIT_VENDOR"
       ,c.status_lookup_code 		"PYMNT_STATUS"
       ,c.check_date 			"CHECK_DT"
       ,c.check_number 			"CHECK_NBR"
       ,c.amount 			"PAID_AMT"
       ,ip.amount 			"INVC_PAID_AMT"
 FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE  TRUNC (c.check_date) = trunc(lc_extract_date-1) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_BIG_SKY_STORES'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT'
	      );
-- Defect 22217 -- Ending -- Including union to extract the EFT transactions for current date

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'BSSinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lcinvccheckamt     VARCHAR2(12);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.


BEGIN

  -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);

  l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

  FOR rcu_main IN lcu_main
  LOOP
 
    ln_vendor :=xx_po_global_vendor_pkg.f_get_outbound (rcu_main.remit_vendor);

    xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_PAYMENT_STATUS',
                                p_source_value1         => rcu_main.pymnt_status,
                                x_target_value1         => lc_status,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );


    IF (rcu_main.invc_paid_amt * 100) < 0 THEN

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * -100), 10, '0');
       lcinvccheckamt := lcinvccheckamt || '-' ;

    ELSE

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * 100), 10, '0'); --Defect 2431
       lcinvccheckamt := lcinvccheckamt || '+' ;

    END IF;

    SELECT     RPAD (nvl(rcu_main.work_order_nbr,' '), 9,' ')
            || RPAD (nvl(rcu_main.invoice,' '), 20, ' ')
            || LPAD (to_char(ln_vendor), 9, '0')   -- DEFECT 2381 ,4096
            || RPAD (nvl(lc_status,' '), 4, ' ')
            || RPAD (TO_CHAR (rcu_main.check_dt, 'YYYY-MM-DD'), 10)
            || LPAD (nvl(to_char(rcu_main.check_nbr),' '), 7, ' ') -- defect 4096
            || lcinvccheckamt  -- Defect 11443
            || chr(13)
      INTO lc_recordstr
      FROM DUAL;

    --  fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
    UTL_FILE.put_line (l_fhandle, lc_recordstr);
  END LOOP;

  UTL_FILE.fclose (l_fhandle);

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');



  IF ln_req_id = 0  THEN

     fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
     fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
     fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
     lc_err_msg := fnd_message.get;
     fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
     x_error_flag := 'Y';                           --Added for the Defect 3254.
     xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'W',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'BIG SKY'
                       );

  ELSE

     fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
     fnd_file.put_line (fnd_file.output, ' ');
     x_error_flag := 'N';                           --Added for the Defect 3254.
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
    fnd_message.set_token ('ERR_ORA', SQLERRM);
    lc_err_msg := fnd_message.get;
    x_error_flag := 'Y';                           --Added for the Defect 3254.
    fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
    xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'BIG SKY'
                                 );
    UTL_FILE.fclose (l_fhandle);
END big_sky_stores;



-- +===================================================================+
-- |         Name : CONSIGNMENT_INV                                    |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Consignment Inventory Vendor Application            |
-- +===================================================================+
PROCEDURE consignment_inv( lc_extract_date IN DATE
                          ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                         )
IS
CURSOR lcu_main
IS
SELECT     DECODE(SUBSTR(c.currency_code,1,2),'US','US','CA','CN')
        || DECODE(SUBSTR(vs.attribute8,1,2),'TR','TRA','EX','EXP') "COMPANY"
       ,vs.vendor_site_id 		"VENDOR"
       ,c.bank_account_name 		"BANK_CD"
       ,i.invoice_num 			"INVOICE_NBR"
       ,c.CHECK_FORMAT_ID 		"CHECK_FORMAT_ID"   -- defect 4096
       ,c.payment_instruction_id	
       ,NVL (aps.payment_method_lookup_code, aps.payment_method_code)   	"PAYMENT_METHOD" -- defect 4096
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 WHERE TRUNC (ip.creation_date) = TRUNC (lc_extract_date - 1)  -- defect# 2575
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_CONSIGNMENT_SALES';


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'CIinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_bank_cd         VARCHAR2 (2);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_check_format_name         VARCHAR2 (100)   := null;
      lc_line_written  NUMBER := 0;  -- defect# 2575
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.

BEGIN

  -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
  l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

  FOR rcu_main IN lcu_main
  LOOP

/*  commented for R12
    begin
      select name
      into lc_check_format_name
      from ap_check_formats
      where check_format_id = rcu_main.check_format_id
      and payment_method_lookup_code = rcu_main.payment_method;

      exception
      when others then
        lc_check_format_name := null;
      end;
*/

    BEGIN
      SELECT ifmt.format_name
        INTO lc_check_format_name
        FROM iby_formats_tl ifmt,
	     iby_payment_profiles pp,
	     iby_pay_instructions_all pi
       WHERE pi.payment_instruction_id=rcu_main.payment_instruction_id
         AND pp.payment_profile_id=pi.payment_profile_id
         AND ifmt.format_code=pp.payment_format_code;
    EXCEPTION
      WHEN others THEN
	lc_check_format_name := NULL;
    END;

    ln_vendor :=xx_po_global_vendor_pkg.f_get_outbound (rcu_main.vendor);

    --fnd_file.put_line (fnd_file.LOG, 'CONSIGN: ' || lc_check_format_name
    -- || ' ' || rcu_main.payment_method || ' ' || rcu_main.check_format_id);

    IF  (lc_check_format_name IS NOT NULL)  THEN

	-- Question to elaine

        xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_BANK_CODES',
                                p_source_value1         => rcu_main.bank_cd,
                                p_source_value2         => rcu_main.payment_method,
                                p_source_value3         => lc_check_format_name,
                                x_target_value1         => lc_bank_cd,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );
    END IF;

    SELECT    RPAD (rcu_main.company, 4)
           || LPAD (to_char(ln_vendor), 9,'0')
           || RPAD (nvl(lc_bank_cd,' '), 2,' ')   -- defect 4096
           || RPAD (nvl(rcu_main.invoice_nbr, ' '), 20,' ')
           || RPAD ('', 27, ' ')                                -- Filler
                                || chr(13)
      INTO lc_recordstr
      FROM DUAL;

    UTL_FILE.put_line (l_fhandle, lc_recordstr);
    lc_line_written := lc_line_written + 1;  -- defect# 2575

  END LOOP;

  UTL_FILE.fclose (l_fhandle);
  fnd_file.put_line (fnd_file.LOG, 'Consign Extract Date:' || ' ' || TRUNC(lc_extract_date - 1) );  -- defetc# 2575
  fnd_file.put_line (fnd_file.LOG, 'Total Consign Records Written:' || ' ' || lc_line_written);  -- defetc# 2575

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');


  IF ln_req_id = 0  THEN

      fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
      fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
      fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
      lc_err_msg := fnd_message.get;
      fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
      x_error_flag := 'Y';                           --Added for the Defect 3254.
      xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'CONSIGNMENT INVENTORY'
                       );
  ELSE
 
    fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line (fnd_file.output, ' ');
    x_error_flag := 'N';                           --Added for the Defect 3254.

  END IF;
EXCEPTION
  WHEN OTHERS THEN
    fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
    fnd_message.set_token ('ERR_ORA', SQLERRM);
    lc_err_msg := fnd_message.get;
    x_error_flag := 'Y';                           --Added for the Defect 3254.
    fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
    xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'CONSIGNMENT INVENTORY'
                                 );
         UTL_FILE.fclose (l_fhandle);
END consignment_inv;

-- +===================================================================+
-- |         Name : RETAIL_LEASE                                       |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Retail Lease Vendor Application                     |
-- +===================================================================+
PROCEDURE retail_lease(  lc_extract_date IN DATE
                        ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                      )
IS
CURSOR lcu_main
IS
SELECT   i.invoice_num 		"INVOICE_NBR"
	,c.check_number 	"CHECK_NBR"
        ,DECODE(c.status_lookup_code,'VOIDED', 'Y','N') "VOID_INDICATOR"
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_RENT'
UNION                                                            -- ADDED UNION per defect 13671
SELECT /*+ leading(c) */   -- Defect 29459
 	 i.invoice_num 		"INVOICE_NBR"
	,c.check_number 	"CHECK_NBR"
        ,DECODE(c.status_lookup_code,'VOIDED','Y','N') "VOID_INDICATOR"
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date - 1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_RENT'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT'
	      );

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_headerstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'RLinvcpymt' || '.txt';
      lr_main            lcu_main%ROWTYPE;
      --lc_fieldSeprator1  VARCHAR2(2000):= chr(39)||chr(34);
      lc_fieldseprator   VARCHAR2 (2000)                  := CHR (34);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.

BEGIN

  -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
  l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

  SELECT    CHR (34)
         || 'INVOICE NBR'
         || CHR (34)
         || ','
         || CHR (34)
         || 'CHECK NBR'
         || CHR (34)
         || ','
         || CHR (34)
         || 'VOID INDICATOR'
         || CHR (34)
    INTO lc_headerstr
    FROM DUAL;

  UTL_FILE.put_line (l_fhandle, lc_headerstr);

  FOR rcu_main IN lcu_main
  LOOP

     SELECT    lc_fieldseprator
                || RPAD (nvl(rcu_main.invoice_nbr, ' '), 20, ' ')
                || lc_fieldseprator
                || ','
                || lc_fieldseprator
                || LPAD (to_char(rcu_main.check_nbr), 7, ' ')
                || lc_fieldseprator
                || ','
                || lc_fieldseprator
                || rcu_main.void_indicator
                || lc_fieldseprator
                || RPAD ('', 44, ' ')                                -- Filler
                                || chr(13)
       INTO lc_recordstr
       FROM DUAL;

     UTL_FILE.put_line (l_fhandle, lc_recordstr);

  END LOOP;

  UTL_FILE.fclose (l_fhandle);
 
  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

  IF ln_req_id = 0  THEN

     fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
     fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
     fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
     lc_err_msg := fnd_message.get;
     fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
     x_error_flag := 'Y';                           --Added for the Defect 3254.
     xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'RETAIL LEASE'
                       );
  ELSE

    fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line (fnd_file.output, ' ');
    x_error_flag := 'N';                           --Added for the Defect 3254.

  END IF;
EXCEPTION
  WHEN OTHERS THEN
    fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
    fnd_message.set_token ('ERR_ORA', SQLERRM);
    lc_err_msg := fnd_message.get;
    x_error_flag := 'Y';                           --Added for the Defect 3254.
    fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
    xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'RETAIL LEASE'
                                 );
    UTL_FILE.fclose (l_fhandle);
END retail_lease;

-- +===================================================================+
-- |         Name : SALES_ACCOUNTING                                   |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Sales Accounting Vendor Application                 |
-- +===================================================================+
PROCEDURE sales_accounting(lc_extract_date IN DATE
                              ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                              )
IS
CURSOR lcu_main
IS
SELECT  xamch.ref_mailcheck_id "MAIL_CHECK_ID", 
	i.invoice_date "INVOICE_DT",
        SUBSTR (cc.segment4, 2) "STORE",
        vs.customer_num "CUSTOMER", 
	c.amount "NET_AMT",
        i.invoice_num "INVOICE", 
	c.check_date "CHECK_DT",
        c.check_number "CHECK_NBR", 
	vs.vendor_site_id "REMIT_VENDOR"
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs,
        ap_suppliers v,
        xx_ar_mail_check_holds xamch,
        xx_om_return_tenders_all xort,
        ar_cash_receipts_all acr,
        xx_ar_refund_trx_tmp xartt,
        gl_code_combinations cc,
	ap_invoices_all i,
	ap_invoice_payments_all ip,
	ap_checks_all c
  --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
  WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
    AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
    AND ip.check_id=c.check_id
    AND i.invoice_id=ip.invoice_id 
    AND i.SOURCE = 'US_OD_RETAIL_REFUND'
    AND vs.vendor_site_id=c.vendor_site_id
    AND v.vendor_id=vs.vendor_id 
    AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
    AND xartt.ap_invoice_number = i.invoice_num
    AND xartt.ap_vendor_site_code = vs.vendor_site_code
    AND xartt.trx_type = 'R'
    AND xartt.identification_type = 'OM'
    AND xartt.inv_created_flag = 'Y'
    AND acr.cash_receipt_id=xartt.trx_id 
    AND xort.cash_receipt_id=acr.cash_receipt_id
    AND NVL(xamch.aops_order_number, xamch.pos_transaction_number) = xort.orig_sys_document_ref

       /*  UNION ALL
         SELECT xamch.ref_mailcheck_id "MAIL_CHECK_ID", i.invoice_date "INVOICE_DT",
                SUBSTR (cc.segment4, 2) "STORE",
                vs.customer_num "CUSTOMER", c.amount "NET_AMT",
                i.invoice_num "INVOICE", c.check_date "CHECK_DT",
                c.check_number "CHECK_NBR", vs.vendor_site_id "REMIT_VENDOR"
           FROM ap_checks_all c,
                ap_invoice_payments_all ip,
                ap_invoices_all i,
                po_vendor_sites_all vs,
                po_vendors v,
                gl_code_combinations cc,
                xx_ar_refund_trx_tmp xartt,
                ar_cash_receipts_all acr,
                xx_ar_mail_check_holds xamch,
                xx_om_legacy_deposits xold
          WHERE vs.vendor_id = v.vendor_id
            AND c.vendor_site_id = vs.vendor_site_id
            AND ip.invoice_id = i.invoice_id
            AND c.check_id = ip.check_id
            AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
            AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
            AND TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days)
            AND i.SOURCE = 'US_OD_RETAIL_REFUND'             -- watch out on this one, we do have Canada
            AND xartt.identification_type = 'OM'
             AND xartt.trx_type = 'R'
             AND xartt.trx_id = acr.cash_receipt_id
             AND acr.cash_receipt_id = xold.cash_receipt_id
             AND NVL(xamch.aops_order_number, xamch.pos_transaction_number) = xold.orig_sys_document_ref
             AND xartt.inv_created_flag = 'Y'
             AND xartt.ap_invoice_number = i.invoice_num
             AND xartt.ap_vendor_site_code = vs.vendor_site_code
             AND xold.prepaid_amount < 0;    -- defect 4381 */

 -- Changes related to SDR Project.
 -- Query modified so that the orig_sys_document_ref column is been looked up from two tables  XX_OM_LEGACY_DEPOSITS and XX_OM_LEGACY_DEP_DTLS
UNION
SELECT  xamch.ref_mailcheck_id "MAIL_CHECK_ID", 
        i.invoice_date "INVOICE_DT",
        SUBSTR (cc.segment4, 2) "STORE",
        vs.customer_num "CUSTOMER",
        c.amount "NET_AMT",
        i.invoice_num "INVOICE",
        c.check_date "CHECK_DT",
        c.check_number "CHECK_NBR",
        vs.vendor_site_id "REMIT_VENDOR"
FROM
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs,
        ap_suppliers v,
	XX_OM_LEGACY_DEP_DTLS xoldd,
        xx_om_legacy_deposits xold,
        xx_ar_mail_check_holds xamch,
        ar_cash_receipts_all acr,
        xx_ar_refund_trx_tmp xartt,
        gl_code_combinations cc,
	ap_invoices_all i,
	ap_invoice_payments_all ip,
	ap_checks_all c
  --WHERE TRUNC (c.check_date) = trunc(lc_extract_date) --Commented for Defect# 29459
  WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
    AND c.org_id        IN (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US')) 
    AND ip.check_id=c.check_id
    AND i.invoice_id=ip.invoice_id 
    AND i.SOURCE = 'US_OD_RETAIL_REFUND'
    AND vs.vendor_site_id=c.vendor_site_id
    AND v.vendor_id=vs.vendor_id 
    AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
    AND xartt.ap_invoice_number     = i.invoice_num
    AND xartt.ap_vendor_site_code   = vs.vendor_site_code
    AND xartt.trx_type    = 'R'
    AND xartt.identification_type = 'OM'
    AND xartt.inv_created_flag = 'Y'
    AND acr.cash_receipt_id=xartt.trx_id                                               
    AND xold.cash_receipt_id=acr.cash_receipt_id      
    AND NVL(xamch.aops_order_number, xamch.pos_transaction_number) = NVL(xold.orig_sys_document_ref,xoldd.orig_sys_document_ref)
    AND xoldd.transaction_number(+) = xold.transaction_number
    AND xold.prepaid_amount         < 0
        -- Added for defect # 13669 -- Start
UNION
SELECT  xamch.ref_mailcheck_id "MAIL_CHECK_ID",
        i.invoice_date "INVOICE_DT",
        SUBSTR (cc.segment4, 2) "STORE",
        vs.customer_num "CUSTOMER", 
	c.amount "NET_AMT",
        i.invoice_num "INVOICE", 
	c.check_date "CHECK_DT",
        c.check_number "CHECK_NBR", 
	vs.vendor_site_id "REMIT_VENDOR"
  FROM  
	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs,
        ap_suppliers v,
	xx_ar_mail_check_holds xamch,
        ar_cash_receipts_all acr,
        xx_ar_refund_trx_tmp xartt,
        gl_code_combinations cc,
	ap_invoices_all i,
	ap_invoice_payments_all ip,
	ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date) -- Commented for Defect# 29459
  WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
    AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
    AND ip.check_id=c.check_id
    AND i.invoice_id=ip.invoice_id 
    AND i.SOURCE = 'US_OD_RETAIL_REFUND'
    AND vs.vendor_site_id=c.vendor_site_id
    AND v.vendor_id=vs.vendor_id 
    AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
    AND xartt.ap_invoice_number = i.invoice_num
    AND xartt.ap_vendor_site_code = vs.vendor_site_code
    AND xartt.identification_type = 'OM'
    AND xartt.trx_type = 'R'
    AND xartt.inv_created_flag = 'Y'
    AND acr.cash_receipt_id=xartt.trx_id     
    AND xamch.ref_mailcheck_id=xartt.ref_mailcheck_id 
    AND xamch.ar_cash_receipt_id=acr.cash_receipt_id 
        -- Added for defect # 13669 -- End
              ;

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'SAinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_store           VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.

   BEGIN
      -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
         ln_vendor :=
               xx_po_global_vendor_pkg.f_get_outbound (rcu_main.remit_vendor);


         SELECT    LPAD (nvl(to_char(rcu_main.mail_check_id), ' '), 10, ' ')
                || RPAD (TO_CHAR (rcu_main.invoice_dt, 'MMDDYY'), 6)
                || RPAD (nvl(rcu_main.STORE, ' ' ), 5, ' ')
                || RPAD (nvl(rcu_main.customer, ' '), 10, ' ')
                || LPAD (nvl((to_char(rcu_main.net_amt * 100)),'0'), 11, '0')
                || RPAD (nvl(rcu_main.invoice, ' '), 20, ' ')
                || RPAD (TO_CHAR (rcu_main.check_dt, 'MMDDYY'), 6)
                || LPAD (nvl(TO_CHAR(rcu_main.check_nbr), ' '), 7, ' ')
                ||  LPAD (nvl(TO_CHAR(ln_vendor), ' '), 9, ' ')
                                || chr(13)
           INTO lc_recordstr
           FROM DUAL;
 fnd_file.put_line
                         (fnd_file.LOG,
                          lc_recordstr
                         );
         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || 'XXCOMFILCOPY cannot be created');
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'SALES ACCOUNTING'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SALES ACCOUNTING'
                                 );
         UTL_FILE.fclose (l_fhandle);
END sales_accounting;

-- +===================================================================+
-- |         Name : PAID                                               |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               PAID Vendor Application                             |
-- +===================================================================+
PROCEDURE paid( lc_extract_date IN DATE
               ,x_error_flag   OUT VARCHAR2)        --Added for the Defect 3254.
IS
CURSOR lcu_main
IS
SELECT   DECODE(c.org_id,'404', 'US','403', 'CN')
                || DECODE (SUBSTR (vs.attribute8, 1, 2),'TR', 'TRA','EX', 'EXP') "AP_COMPANY"  -- defect 12369
        ,vs.vendor_site_id "VENDOR"
	,i.voucher_num "VOUCHER"
        ,c.check_number "CHECK_NBR"
	,c.check_date "CHECK_DT"
        ,c.amount "CHECK_AMT"
	,i.invoice_amount "GROSS_AMT"
        ,ip.discount_taken "DISC_AMT"
	,c.bank_account_name "BANK_CD"
        ,i.attribute13 "TYPE_CD"
        ,c.CHECK_FORMAT_ID "CHECK_FORMAT_ID"   -- defect 4096
	,c.payment_instruction_id 
        ,NVL (aps.payment_method_lookup_code, aps.payment_method_code)   "PAYMENT_METHOD" -- defect 4096
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND SUBSTR (vs.attribute8, 1, 1) = 'T'   -- Defect 2125
       --AND i.SOURCE = 'Integral';                    Defect 2125
UNION   
SELECT   DECODE(c.org_id,'404', 'US','403', 'CN'  )
                || DECODE (SUBSTR (vs.attribute8, 1, 2),'TR', 'TRA','EX', 'EXP') "AP_COMPANY"  -- defect 12369
        ,vs.vendor_site_id "VENDOR"
	,i.voucher_num "VOUCHER"
        ,c.check_number "CHECK_NBR"
	,c.check_date "CHECK_DT"
        ,c.amount "CHECK_AMT"
	,i.invoice_amount "GROSS_AMT"
        ,ip.discount_taken "DISC_AMT"
	,c.bank_account_name "BANK_CD"
        ,i.attribute13 "TYPE_CD"
        ,c.CHECK_FORMAT_ID "CHECK_FORMAT_ID"   -- defect 4096
	,c.payment_instruction_id 
        ,NVL (aps.payment_method_lookup_code, aps.payment_method_code)   "PAYMENT_METHOD" -- defect 4096
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) =  trunc(lc_extract_date - 1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459 
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND SUBSTR (vs.attribute8, 1, 1) = 'T'   -- Defect 2125
   AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT';

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)            := 'PAIDinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_bank_cd         VARCHAR2 (2);
      lc_type_cd         VARCHAR2 (1);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_check_format_name         VARCHAR2 (100)   := null;
      lccheckamt         VARCHAR2(12);
      lcgrossamt         VARCHAR2(12);
      lcdiscamt          VARCHAR2(12);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.



   BEGIN
-- Defect 11205
-- 1. The Check Number field should be padded with a leading zero instead of a space.
-- 2. The negative amount sign should be at the end of the amount field.
-- 3. The Amount field should be 11 characters in length plus 1 position for the sign.
--

      -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
/*    Commented for R12
      begin
      select name
      into lc_check_format_name
      from ap_check_formats
      where check_format_id = rcu_main.check_format_id
      and payment_method_lookup_code = rcu_main.payment_method;

      exception
      when others then
        lc_check_format_name := null;
      end;
*/

    -- Addd for R12	

    BEGIN 
      SELECT ifmt.format_name
        INTO lc_check_format_name
        FROM iby_formats_tl ifmt,
	     iby_payment_profiles pp,
	     iby_pay_instructions_all pi
       WHERE pi.payment_instruction_id=rcu_main.payment_instruction_id
         AND pp.payment_profile_id=pi.payment_profile_id
         AND ifmt.format_code=pp.payment_format_code;
    EXCEPTION
      WHEN others THEN
	lc_check_format_name := NULL;
    END;

--         fnd_file.put_line (fnd_file.LOG, 'PAID:' || lc_check_format_name
--                            || ' ' || rcu_main.payment_method || ' ' || rcu_main.check_format_id);


         ln_vendor :=
                     xx_po_global_vendor_pkg.f_get_outbound (rcu_main.vendor);

         if  (lc_check_format_name is not null)  then
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_BANK_CODES',
                                p_source_value1         => rcu_main.bank_cd,
                                p_source_value2         => rcu_main.payment_method,
                                p_source_value3         => lc_check_format_name,
                                x_target_value1         => lc_bank_cd,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );
         end if;


if (rcu_main.check_amt * 100) < 0 then
  lccheckamt := LPAD (nvl((rcu_main.check_amt * -100), '0'), 11, '0');
  lccheckamt := lccheckamt || '-' ;
else
  lccheckamt := LPAD (nvl((rcu_main.check_amt * 100), '0'), 11, '0'); --Defect 2431
  lccheckamt := lccheckamt || '+' ;
end if;
if (rcu_main.gross_amt * 100) < 0 then
  lcgrossamt := LPAD (nvl((rcu_main.gross_amt * -100), '0'), 11, '0');
  lcgrossamt := lcgrossamt || '-';
else
  lcgrossamt := LPAD (nvl((rcu_main.gross_amt * 100), '0'), 11, '0'); --Defect 2431
  lcgrossamt := lcgrossamt || '+';
end if;
if (rcu_main.disc_amt * 100) < 0 then
  lcdiscamt := LPAD (nvl((rcu_main.disc_amt * -100), '0'), 11, '0');
  lcdiscamt := lcdiscamt || '-';
else
  lcdiscamt := LPAD (nvl((rcu_main.disc_amt * 100), '0'), 11, '0'); --Defect 2431
  lcdiscamt := lcdiscamt || '+';
end if;



         SELECT    LPAD (substr(rcu_main.ap_company,1,4), 4, ' ')
                || LPAD (to_char(ln_vendor), 9, '0')
                || LPAD (nvl(rcu_main.voucher,' '), 6, ' ')
                || LPAD (rcu_main.check_nbr, 8, '0')
                || RPAD (TO_CHAR (rcu_main.check_dt, 'YYYY-MM-DD'), 10,' ')
                || lccheckamt  --LPAD (nvl((rcu_main.check_amt * 100), '0'), 12, '0')   --Defect 2431
                || lcgrossamt  --LPAD (nvl((rcu_main.gross_amt * 100),'0'), 12, '0')     --Defect 2431
                || lcdiscamt   --LPAD (nvl((rcu_main.disc_amt * 100), '0'), 12, '0')     --Defect 2431
                || RPAD (nvl(lc_bank_cd,' '), 2,' ')
                || RPAD (nvl(rcu_main.type_cd, ' '), 1,' ')
                                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' ||SQLERRM) ;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'PAID'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA',SQLERRM );
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'PAID'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END paid;

-- +===================================================================+
-- |         Name : Datalink                                           |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Datalink Vendor Application                         |
-- | Created by : Sandeep Pandhare 09/04/07                            |
-- +===================================================================+
PROCEDURE datalink(  lc_extract_date IN DATE
                    ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                  )
IS
CURSOR lcu_main
IS
SELECT  DECODE(c.org_id,'404', 'US','403', 'CN'  ) "AP_COMPANY" -- Added for defect 13517
       ,vs.vendor_site_id "VENDOR"
       ,v.vendor_name "NAME"
       ,vs.attribute8 "SITE_CATEGORY"
       ,NVL(c.amount,0) "CHECK_AMT"                      -- Added for defect 13518
       ,NVL(SUM (i.invoice_amount),0)  "GROSS_AMT"
       ,NVL(SUM (ip.discount_taken),0) "DISC_AMT"
       ,c.check_date "CHECK_DT"                                 -- Added for defect 13517
       ,i.pay_group_lookup_code "PAYGROUP"                      -- Added per defect 12642
       ,c.check_number  "CHECK_NUM"                             -- Added per defect 12642
       ,c.check_id      "CHECK_ID"
 FROM     
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND ps.invoice_id = i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
 GROUP BY -- c.currency_code             -- Comment out for defect 13517
         c.org_id
        ,vs.vendor_site_id
        ,c.amount                       -- Added for defect 13518
        ,v.vendor_name
        ,vs.attribute8
        ,C.check_date                   -- Added for defect 13517
        ,i.pay_group_lookup_code        -- Added per defect 12642
        ,c.check_number                 -- Added per defect 12642
        ,c.check_id                     -- Added per defect 13648 and 13606
UNION                                                           -- ADDED UNION per defect 13671
SELECT  DECODE(c.org_id,'404', 'US','403', 'CN'  ) "AP_COMPANY" -- Added for defect 13517
       ,vs.vendor_site_id "VENDOR"
       ,v.vendor_name "NAME", vs.attribute8 "SITE_CATEGORY"
       ,NVL(c.amount,0) "CHECK_AMT"                              -- Added for defect 13518
       ,NVL(SUM (i.invoice_amount),0)  "GROSS_AMT"
       ,NVL(SUM (ip.discount_taken),0) "DISC_AMT"
       ,c.check_date "CHECK_DT"                                  -- Added for defect 13517
       ,i.pay_group_lookup_code "PAYGROUP"                       -- Added per defect 12642
       ,c.check_number  "CHECK_NUM"                              -- Added per defect 12642
       ,c.check_id      "CHECK_ID"
  FROM   
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date - 1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND ps.invoice_id = i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND NVL(ps.payment_method_lookup_code, ps.payment_method_code)='EFT'
 GROUP BY c.org_id
         ,vs.vendor_site_id
         ,c.amount                       -- Added for defect 13518
         ,v.vendor_name
         ,vs.attribute8
         ,C.check_date                   -- Added for defect 13517
         ,i.pay_group_lookup_code        -- Added per defect 12642
         ,c.check_number                 -- Added per defect 12642
         ,c.check_id                     -- Added per defect 13648 and 13606
 ORDER BY NAME;



-- lcu_details cursor added for defect 13648 and 13606

      CURSOR lcu_details (p_Check_id NUMBER)
      IS
         SELECT   NVL(i.invoice_amount,0)  "GROSS_AMT"
                  ,NVL(ip.discount_taken,0) "DISC_AMT"
                  ,NVL(ip.discount_lost,0)  "DISC_LOST"
                  ,i.gl_date "ACCT_DATE"
--                  ,ps.discount_date  "DISC_DT"
                  ,ps.due_date  "DUE_DT"
                  ,i.attribute14   "SH_COMMENT"            -- Added per defect 13606
         FROM     ap_invoice_payments_all ip,
                  ap_invoices_all i,
                  gl_code_combinations cc,
                  ap_payment_schedules_all ps
            WHERE ip.check_id = p_check_id
              AND ip.invoice_id = i.invoice_id
              AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
              AND ps.invoice_id = ip.invoice_id;


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)                   := 'DLKinvcpymt.txt';
      lc_fieldseprator   VARCHAR2 (1)                     := '|';
      lc_bu              VARCHAR2 (5)                     := NULL;
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      ln_disc_lost       NUMBER;
      lc_bank_cd         VARCHAR2 (2);
      lc_type_cd         VARCHAR2 (1);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);

      ln_past_due        NUMBER;   -- Added per defect 13648
      ln_on_time         NUMBER;   -- Added per defect 13648
      lc_sh_comments     ap_invoices_all.attribute14%type;
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.



   BEGIN
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
         ln_vendor :=
                     xx_po_global_vendor_pkg.f_get_outbound (rcu_main.vendor);

        --  lc_bu := rcu_main.currency;  -- Comment out for defect 13517

         lc_bu := rcu_main.AP_COMPANY;   -- Added for defect 13517

         IF (SUBSTR (rcu_main.site_category, 1, 2) = 'TR')
         THEN
            lc_bu := lc_bu || 'TRA';
         END IF;

         IF (SUBSTR (rcu_main.site_category, 1, 2) = 'EX')
         THEN
            lc_bu := lc_bu || 'EXP';
         END IF;



         ln_disc_lost  := 0;
         ln_past_due   := 0;
         ln_on_time    := 0;
         lc_sh_comments := NULL;

         FOR rcu_details  IN lcu_details (rcu_main.CHECK_ID)
         LOOP

           ----------------------------------------------------------------------------
           -- Added for defect 13648
           -- Discount Lost: if Paid Equals Gross Amounts and Dis amt exists
           ----------------------------------------------------------------------------

           IF  rcu_main.CHECK_AMT = rcu_main.GROSS_AMT AND rcu_details.DISC_AMT <> 0 THEN

                 ln_disc_lost := ln_disc_lost + rcu_details.DISC_AMT;

           END IF;

           ----------------------------------------------------------------------------
           -- Added for defect 13648
           -- Discount Past Due: If Paid and Gross Amounts <> and Accounting Date
           --                    greater than Discount Due Date then Discount Past Due.
           ----------------------------------------------------------------------------
           IF  rcu_main.CHECK_AMT <> rcu_main.GROSS_AMT
                    AND trunc(rcu_details.ACCT_DATE) > TRUNC(rcu_details.DUE_DT) THEN

                ln_past_due := ln_past_due + rcu_details.DISC_AMT;

           END IF;

           ----------------------------------------------------------------------------
           -- Added for defect 13648
           -- Discount On Time: If Paid and Gross Amount <> and Accounting Date is
           --                   <= to Due Date then  Discount On Time.
           ----------------------------------------------------------------------------

           IF  rcu_main.CHECK_AMT <> rcu_main.GROSS_AMT
                    AND trunc(rcu_details.ACCT_DATE) <= TRUNC(rcu_details.DUE_DT) THEN

                ln_on_time :=  ln_on_time + rcu_details.DISC_AMT;

           END IF;

                  IF  rcu_details.SH_COMMENT IS NOT NULL THEN

                        lc_sh_comments  := rcu_details.SH_COMMENT;

                  END IF;

         END LOOP;


         SELECT    RPAD (lc_bu, 5)
                || lc_fieldseprator
                || to_char(ln_vendor)
                || lc_fieldseprator
                || rcu_main.NAME
                || lc_fieldseprator
                || to_char(rcu_main.gross_amt)
                || lc_fieldseprator
                || to_char(rcu_main.disc_amt)
                || lc_fieldseprator
                || to_char(ln_on_time)
--                || '0'                                                  -- Comment out for defect 13648
                || lc_fieldseprator
                || to_char(ln_past_due)
--                || '0'                                                  -- Comment out for defect 13648
                || lc_fieldseprator
                || to_char(ln_disc_lost)
--                || to_char(rcu_main.disc_lost)                          -- Comment out for defect 13648
                || lc_fieldseprator
                || to_char(rcu_main.check_amt)
                || lc_fieldseprator
--              || RPAD (TO_CHAR (sysdate, 'YYYY-MM-DD'), 10)             -- Comment out for defect 13517
                || RPAD (TO_CHAR (rcu_main.CHECK_DT, 'YYYY-MM-DD'), 10)   -- Added for defect 13517
                || lc_fieldseprator
                || rcu_main.PAYGROUP                   -- Added per defect 12642
                || lc_fieldseprator                    -- Added per defect 12642
                || to_char(rcu_main.check_num)         -- Added per defect 12642
                || lc_fieldseprator                    -- Added per defect 13648
                || lc_sh_comments                      -- Added per defect 13606
                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

--  Business Unit, Vendor Number, Vendor Name, GROSS_PAY, Discount Taken
-- DISC_ON_TIME, DISC_PAST_DUE, DISC_LOST, NET_PAID, REPORT DAte


         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'W',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'DATALINK'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'DATALINK'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END datalink;

-- +===================================================================+
-- |         Name : TDM                                                |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               TDM Vendor Application                              |
-- +===================================================================+
   PROCEDURE tdm(lc_extract_date IN DATE
                 ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                 )
   IS
      CURSOR lcu_main
      IS
--       Defect 13649 commentd out orginal lcu_main cursor

--         SELECT DECODE (i.attribute9, NULL, ' ', i.attribute9) dcn_number,
--                i.voucher_num voucher, -- defect 2386
--                ps.due_date due_date,
--                ip.accounting_date setup_per
--           FROM ap_checks_all c,
--                ap_invoice_payments_all ip,
--                ap_invoices_all i,
--                po_vendor_sites_all vs,
--                ap_payment_schedules_all ps,
--                po_vendors v,
--                gl_code_combinations cc
--          WHERE vs.vendor_id = v.vendor_id
--            AND c.vendor_site_id = vs.vendor_site_id
--            AND ip.invoice_id = i.invoice_id
--            AND ps.invoice_id = i.invoice_id
--            AND c.check_id = ip.check_id
--            AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
--            AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
--            AND TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days)
--            AND i.attribute9 is not null;  -- defect 2386
--            AND i.SOURCE = 'US_OD_TDM';  defect 2386
--

--       Defect 13649 updated cursor to remove payment and vendor tables added gl_date

         SELECT DECODE (i.attribute9, NULL, ' ','0',' ', i.attribute9) dcn_number,             --Defect 14872 Added '0' to decode statement
                i.voucher_num voucher,
                ps.due_date due_date,
                i.gl_date setup_per
           FROM ap_invoices_all i,
                ap_payment_schedules_all ps
          WHERE
                ps.invoice_id = i.invoice_id
            AND i.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))--= ou.organization_id
            AND TRUNC(i.gl_date) =  trunc(lc_extract_date -1)  -- > TRUNC (SYSDATE - ln_days)
            AND i.attribute9 is not null;

CURSOR lcu_main1
IS
SELECT  DECODE (i.attribute9, NULL, ' ','0',' ', i.attribute9) dcn_number              --Defect 14872 Added '0' to decode statement
       ,c.check_number check_nbr_pd
       ,c.amount check_amt
       ,DECODE (i.invoice_type_lookup_code,'CREDIT', '-','DEBIT', '-','+') check_amt_sign
       ,c.check_date check_dt
FROM 
	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
        -- hr_operating_units ou,
        -- gl_sets_of_books sb,
--WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
  AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
  AND ip.check_id=c.check_id
  AND i.invoice_id=ip.invoice_id 
  AND ps.invoice_id = i.invoice_id
  AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
  AND vs.vendor_site_id=c.vendor_site_id
  AND v.vendor_id=vs.vendor_id 
  AND i.attribute9 is not null  -- defect 2386
  AND c.status_lookup_code != 'VOIDED'
      -- AND i.SOURCE = 'US_OD_TDM'        defect 2386
UNION                                                           -- ADDED UNION per defect 13671
SELECT  DECODE (i.attribute9, NULL, ' ','0',' ', i.attribute9) dcn_number             --Defect 14872 Added '0' to decode statement
       ,c.check_number check_nbr_pd
       ,c.amount check_amt
       ,DECODE (i.invoice_type_lookup_code,'CREDIT', '-','DEBIT', '-','+') check_amt_sign
       ,c.check_date check_dt
FROM 
	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
        -- hr_operating_units ou,
        -- gl_sets_of_books sb,
--WHERE TRUNC (c.check_date) = trunc(lc_extract_date -1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
  AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
  AND ip.check_id=c.check_id
  AND i.invoice_id=ip.invoice_id 
  AND ps.invoice_id = i.invoice_id
  AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
  AND vs.vendor_site_id=c.vendor_site_id
  AND v.vendor_id=vs.vendor_id 
  AND i.attribute9 is not null  -- defect 2386
  AND c.status_lookup_code != 'VOIDED'
  AND NVL (ps.payment_method_lookup_code, ps.payment_method_code) = 'EFT';
     -- AND i.SOURCE = 'US_OD_TDM'        defect 2386


CURSOR lcu_main2
IS
SELECT  DECODE (i.attribute9, NULL, ' ','0',' ', i.attribute9) dcn_number                   --Defect 14872 Added '0' to decode statement
       ,c.check_number check_nbr_vd
FROM 
	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
--WHERE  TRUNC (c.void_date) = trunc(lc_extract_date - 1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
  AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
  AND ip.check_id=c.check_id
  AND i.invoice_id=ip.invoice_id 
  AND ps.invoice_id = i.invoice_id
  AND ip.accts_pay_code_combination_id = cc.code_combination_id(+)
  AND vs.vendor_site_id=c.vendor_site_id
  AND v.vendor_id=vs.vendor_id 
  AND i.attribute9 is not null  -- defect 2386
  AND c.status_lookup_code = 'VOIDED';
      --AND i.SOURCE = 'US_OD_TDM'               defect 2386


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)             := 'TDMinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_store           VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.


   BEGIN
      -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
         SELECT    '10'
                || LPAD(LTRIM (rcu_main.dcn_number,'0'),9,' ')                  -- ltrim per defect 13769
                || RPAD (nvl(rcu_main.voucher,' ') ,8,' ')
                || RPAD (TO_CHAR (rcu_main.due_date, 'YYYYMMDD'), 8, ' ')
                || RPAD (TO_CHAR (rcu_main.setup_per, 'YYYYMM'), 6,' ')
                || RPAD ('', 78, ' ')
                                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      FOR rcu_main1 IN lcu_main1
      LOOP
         SELECT    '15'
                || LPAD(LTRIM (rcu_main1.dcn_number,'0'),9,' ')                -- LTRIM per defect 13769
                || LPAD (rcu_main1.check_nbr_pd, 9, ' ')
                || LPAD ((rcu_main1.check_amt * 100), 11, '0')
                || RPAD (rcu_main1.check_amt_sign, 1)
                || RPAD (TO_CHAR (rcu_main1.check_dt, 'MM-DD-YYYY'), 10)
                || RPAD ('', 69, ' ')
                                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      FOR rcu_main2 IN lcu_main2
      LOOP
         SELECT    '20'
                || LPAD(LTRIM (rcu_main2.dcn_number,'0'),9,' ')               -- LTRIM per defect 13769
                || LPAD (rcu_main2.check_nbr_vd, 9, ' ')
                || RPAD ('', 91, ' ')
                                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'TDM'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'PAID'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END tdm;

-- +===================================================================+
-- |         Name : DCI                                                |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Direct Commerce  added per CR889                    |
-- +===================================================================+
   PROCEDURE DCI(lc_extract_date IN DATE
                 ,p_org_id       IN NUMBER                                      --added per Defect 14597
                 ,x_error_flag  OUT VARCHAR2
                 )
   IS
      --------------------------------
      -- Invoice set up for payment
      --------------------------------
CURSOR lcu_main
IS
SELECT  nvl(vs.attribute9,vs.vendor_site_id) VENDOR
       ,i.invoice_num 
       ,to_char(i.invoice_date,'MMDDYY') invoice_dt
       ,i.invoice_amount
       ,to_char(i.gl_date,'YYYYMM') setup_per                           --updated per defect 14191
  FROM  ap_invoices_all i
        --,po_vendor_sites_all vs
       ,ap_supplier_sites_all vs		-- Added for R12
       ,ap_payment_schedules_all ps
 WHERE ps.invoice_id = i.invoice_id
   AND i.vendor_site_id = vs.vendor_site_id
   AND i.org_id  = p_org_id                                            --added per Defect 14597
   AND i.gl_date =  trunc(lc_extract_date -1);


         ----------------
         -- invoices paid
         ----------------
CURSOR lcu_main1
IS
SELECT  nvl(vs.attribute9,vs.vendor_site_id) VENDOR             --added per defect 14706
       ,i.invoice_num 
       ,to_char(i.invoice_date,'MMDDYY') invoice_dt
       ,i.invoice_amount
       ,NVL(ip.discount_taken,0) disc_taken
       ,c.check_number
       ,c.amount
       ,DECODE (sign(c.amount),-1, '-','+') check_amt_sign       --added  per defect 14184
       ,to_char(c.check_date,'MM-DD-YYYY') check_dt
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 WHERE c.check_date = trunc(lc_extract_date)
   AND c.org_id  = p_org_id                                         --added per Defect 14597
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND ps.invoice_id = i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+) 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND c.status_lookup_code != 'VOIDED'
UNION
SELECT  nvl(vs.attribute9,vs.vendor_site_id) VENDOR             --added per defect 14706
       ,i.invoice_num 
       ,to_char(i.invoice_date,'MMDDYY') invoice_dt
       ,i.invoice_amount
       ,NVL(ip.discount_taken,0) disc_taken
       ,c.check_number
       ,c.amount
       ,DECODE (sign(c.amount),-1, '-','+') check_amt_sign      --added  per defect 14184
       ,to_char(c.check_date,'MM-DD-YYYY') check_dt
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,gl_code_combinations cc
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 WHERE c.check_date = trunc(lc_extract_date -1)
   AND c.org_id  = p_org_id                                        --added per Defect 14597
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND ps.invoice_id = i.invoice_id
   AND ip.accts_pay_code_combination_id = cc.code_combination_id(+) 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND c.status_lookup_code != 'VOIDED'
   AND NVL(ps.payment_method_lookup_code, ps.payment_method_code)= 'EFT';


      ------------------
      -- Voided Payments
      ------------------

CURSOR lcu_main2
IS
SELECT  nvl(vs.attribute9,vs.vendor_site_id) VENDOR                --added per defect 14706
       ,i.invoice_num 
       ,to_char(i.invoice_date,'MMDDYY') invoice_dt
       ,i.invoice_amount
       ,NVL(ip.discount_taken,0) disc_taken
       ,c.check_number
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_payment_schedules_all ps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 WHERE c.void_date = trunc(lc_extract_date - 1)
   AND c.status_lookup_code = 'VOIDED'
   AND c.org_id  = p_org_id                                          --added per defect 14597
   AND ip.check_id=c.check_id
   AND ip.accounting_date = c.void_date                              --added per defect 14192
   AND ip.reversal_inv_pmt_id is not null                            --added per defect 14706
   AND i.invoice_id=ip.invoice_id 
   AND ps.invoice_id = i.invoice_id
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id;




      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)                   := 'DCIinvcpymt.txt';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_store           VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_error_flag      VARCHAR2(10)                   := NULL;



   BEGIN

       fnd_file.put_line (fnd_file.log, 'Executing DCI Procedure');
       fnd_file.put_line (fnd_file.log, ' lc_extract_date=' || lc_extract_date);

       l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');


       fnd_file.put_line (fnd_file.log, ' Calling lcu_main cursor');

       FOR rcu_main IN lcu_main
       LOOP
         SELECT '10'                    ||'|'||
                LPAD(LTRIM (rcu_main.VENDOR,'0'),9,'0') ||'|'||       -- added per defect 14187
                rcu_main.invoice_num    ||'|'||
                rcu_main.invoice_dt     ||'|'||
                rcu_main.invoice_amount ||'|'||
     --           rcu_main.disc_taken     ||'|'||
                rcu_main.setup_per
               INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
       END LOOP;

       fnd_file.put_line (fnd_file.log, ' Calling lcu_main1 cursor');

       FOR rcu_main1 IN lcu_main1
       LOOP

         SELECT    '15'                        ||'|'||
                      LPAD(LTRIM (rcu_main1.VENDOR,'0'),9,'0') ||'|'||     -- added per defect 14187
                      rcu_main1.invoice_num    ||'|'||
                      rcu_main1.invoice_dt     ||'|'||
                      rcu_main1.invoice_amount ||'|'||
                      rcu_main1.disc_taken     ||'|'||
                      rcu_main1.check_number   ||'|'||
                      rcu_main1.amount         ||'|'||
                      rcu_main1.check_amt_sign ||'|'||
                      rcu_main1.check_dt
           INTO lc_recordstr
           FROM DUAL;



         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      fnd_file.put_line (fnd_file.log, ' Calling lcu_main2 cursor');

      FOR rcu_main2 IN lcu_main2
      LOOP
         SELECT    '20'                    ||'|'||
                  LPAD(LTRIM (rcu_main2.VENDOR,'0'),9,'0') ||'|'||         -- added per defect 14187
                  rcu_main2.invoice_num    ||'|'||
                  rcu_main2.invoice_dt     ||'|'||
                  rcu_main2.invoice_amount ||'|'||
                  rcu_main2.disc_taken     ||'|'||
                  rcu_main2.check_number
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);

         x_error_flag := 'Y';

         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'TDM'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');

         x_error_flag := 'N';

      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN

         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'PAID'
                                 );
         UTL_FILE.fclose (l_fhandle);

   END DCI;


-- +===================================================================+
-- |         Name : GSS                                                |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               GSS Vendor Application                              |
-- +===================================================================+
   PROCEDURE gss(lc_extract_date IN DATE
                 ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                 )
   IS
CURSOR lcu_main
IS
SELECT i.invoice_num invoice_num,
       i.vendor_site_id vendor_id,
       vs.country country,
       i.invoice_id invoice_id,
       c.check_date entered_dt,
       v.vendor_name vendor_name,
       i.Invoice_date invoice_dt,
       ip.amount invoice_amt,
       DECODE (i.invoice_type_lookup_code,'CREDIT', '-','DEBIT', '-','+') invoice_amt_sign
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND i.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND v.vendor_id = i.vendor_id
   AND vs.vendor_id = v.vendor_id
   AND vs.vendor_site_id=i.vendor_site_id
   AND c.vendor_site_id = vs.vendor_site_id
   AND i.SOURCE = 'US_OD_GLOBAL_SOURCING'
UNION                                                        -- ADDED UNION per defect 13671
SELECT i.invoice_num invoice_num,
       i.vendor_site_id vendor_id,
       vs.country country,
       i.invoice_id invoice_id,
       c.check_date entered_dt,
       v.vendor_name vendor_name,
       i.Invoice_date invoice_dt,
       ip.amount invoice_amt,
       DECODE (i.invoice_type_lookup_code,'CREDIT', '-','DEBIT', '-','+') invoice_amt_sign
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date - 1)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND i.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND v.vendor_id = i.vendor_id
   AND vs.vendor_id = v.vendor_id
   AND vs.vendor_site_id=i.vendor_site_id
   AND c.vendor_site_id = vs.vendor_site_id
   AND i.SOURCE = 'US_OD_GLOBAL_SOURCING'
   AND NVL(aps.payment_method_lookup_code, aps.payment_method_code)='EFT';


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)             := 'GSSinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_store           VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lcinvccheckamt     VARCHAR2(12);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.



   BEGIN
      -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
         ln_vendor :=
                  xx_po_global_vendor_pkg.f_get_outbound (rcu_main.vendor_id);


          if (rcu_main.invoice_amt * 100) < 0 then
            lcinvccheckamt := LPAD ((rcu_main.invoice_amt * -100), 11, '0');
--            lcinvccheckamt := lcinvccheckamt || '-' ;
          else
            lcinvccheckamt := LPAD ((rcu_main.invoice_amt * 100), 11, '0'); --Defect 2431
--            lcinvccheckamt := lcinvccheckamt || '+' ;
          end if;




         SELECT    RPAD (rcu_main.invoice_num, 20)
                || LPAD (to_char(ln_vendor), 9, '0')
                || RPAD (nvl(rcu_main.country,' '), 3,' ')
                || RPAD (rcu_main.invoice_id, 8)
                || RPAD (TO_CHAR (rcu_main.entered_dt, 'YYYY-MM-DD'), 10)
                || RPAD (rcu_main.vendor_name, 15)
                || RPAD (TO_CHAR (rcu_main.invoice_dt, 'MMDDYY'), 6)
                || lcinvccheckamt    -- || LPAD(TO_CHAR (rcu_main.invoice_amt * 100), 11,'0') -- remove negative sign
                || RPAD (rcu_main.invoice_amt_sign, 1)
                || RPAD (' ', 37, ' ')
                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'GSS'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'GSS'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END gss;

-- +===================================================================+
-- |         Name : PROJECT MATES                                      |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Project Mates Vendor Application                    |
-- +===================================================================+
PROCEDURE project_mates(  lc_extract_date IN DATE
                         ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                       )
IS
CURSOR lcu_main
IS
SELECT substr(i.description, 1, 9) "PROJECT_NUMBER",
       i.invoice_num "INVOICE_NUMBER",
       vs.vendor_site_id "VENDOR_ID",
       c.status_lookup_code "PAYMENT_STATUS",
       c.check_date "CHECK_DATE", c.check_number "CHECK_NUMBER",
       c.amount "PAID_AMOUNT", ip.amount "INVC_PAID_AMT"
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date)  -- > TRUNC (SYSDATE - ln_days) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = ('US_OD_PROJECT_MATES')
   AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='CHECK' --22217 Adding Condition
   -- Defect 22217 -- Starting -- Including union to extract the EFT transactions for current date
UNION
SELECT substr(i.description, 1, 9) "PROJECT_NUMBER",
       i.invoice_num "INVOICE_NUMBER",
       vs.vendor_site_id "VENDOR_ID",
       c.status_lookup_code "PAYMENT_STATUS",
       c.check_date "CHECK_DATE", c.check_number "CHECK_NUMBER",
       c.amount "PAID_AMOUNT", ip.amount "INVC_PAID_AMT"
  FROM 
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_payment_schedules_all aps
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date-1) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND aps.invoice_id=i.invoice_id
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = ('US_OD_PROJECT_MATES')
   AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT'; --22217 Adding Condition
   -- Defect 22217 -- Ending -- Including union to extract the EFT transactions for current date

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'PMinvcpymt' || '.txt';
-- create archive file name for PM
      lc_filename_PM_archive VARCHAR2 (200)              := 'PMinvcpymt.txt_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HHMISS')
;
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lcinvccheckamt     VARCHAR2(12);
      lc_value           VARCHAR2(100);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.


   BEGIN
      -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP
         ln_vendor :=
                  xx_po_global_vendor_pkg.f_get_outbound (rcu_main.vendor_id);
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_PAYMENT_STATUS',
                                p_source_value1         => rcu_main.payment_status,
                                x_target_value1         => lc_status,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );


          if (rcu_main.invc_paid_amt * 100) < 0 then
            lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * -100), 10, '0');
            lcinvccheckamt := lcinvccheckamt || '-' ;
          else
            lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * 100), 10, '0'); --Defect 2431
            lcinvccheckamt := lcinvccheckamt || '+' ;
          end if;


         SELECT    RPAD (rcu_main.project_number, 9)
                || RPAD (rcu_main.invoice_number, 20,' ')
                || LPAD (to_char(ln_vendor), 9, '0')
                || LPAD (nvl(lc_status,' '), 4, ' ')
                || RPAD (TO_CHAR (rcu_main.check_date, 'YYYY-MM-DD'), 10)
                || LPAD (to_char(rcu_main.check_number), 7, ' ')
                || lcinvccheckamt
                || chr(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/invoicepayment/outbound/' || lc_filename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'PROJECT MATES'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
         UTL_FILE.fclose (l_fhandle);
----begin move PMinvpymt.txt file to archive folder
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/archive/outbound/' || lc_filename_PM_archive
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Program Ends in warning for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001A_ERR');
         fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'PROJECT MATES'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
         x_error_flag := 'N';                           --Added for the Defect 3254.
      END IF;
----end  move PMinvpymt.txt file to archive folder
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         x_error_flag := 'Y';                           --Added for the Defect 3254.
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'PROJECT MATES'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END project_mates;


-- +===================================================================+
-- |         Name : FACILITIES_SOURCE                                  |
-- | Description : To create the Invoices Payment outbound file to     |
-- |               Facilities Source Vendor Application                |
-- +===================================================================+

PROCEDURE facilities_source (  lc_extract_date IN DATE
                         ,x_error_flag OUT VARCHAR2        --Added for the Defect 3254.
                       )
IS
CURSOR lcu_main
IS
SELECT  substr(i.description, 1, 9) 	"WORK_ORDER_NBR"
       ,i.invoice_num 			"INVOICE"
       ,vs.vendor_site_id 		"REMIT_VENDOR"
       ,c.status_lookup_code 		"PYMNT_STATUS"
       ,c.check_date 			"CHECK_DT"
       ,c.check_number 			"CHECK_NBR"
       ,c.amount 			"PAID_AMT"
       ,ip.amount 			"INVC_PAID_AMT"
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE  TRUNC (c.check_date) = trunc(lc_extract_date) --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date) and trunc(lc_extract_date)+1-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_FACILITY_SOURCE'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='CHECK'
	      )
       -- AND c.payment_method_lookup_code='CHECK' -- 22217 Adding the condition, removed for R12       
       -- Defect 22217 -- Starting -- Including union to extract the EFT transactions for current date
UNION
SELECT  substr(i.description, 1, 9) 	"WORK_ORDER_NBR"
       ,i.invoice_num 			"INVOICE"
       ,vs.vendor_site_id 		"REMIT_VENDOR"
       ,c.status_lookup_code 		"PYMNT_STATUS"
       ,c.check_date 			"CHECK_DT"
       ,c.check_number 			"CHECK_NBR" 
       ,c.amount "PAID_AMT"
       ,ip.amount "INVC_PAID_AMT"
  FROM  
 	-- ,po_vendor_sites_all vs  -- Removed for R12
        -- ,po_vendors v	    -- Removed for R12	
        ap_supplier_sites_all vs
       ,ap_suppliers v
       ,ap_invoices_all i
       ,ap_invoice_payments_all ip
       ,ap_checks_all c
 --WHERE TRUNC (c.check_date) = trunc(lc_extract_date-1)  --Commented for Defect# 29459
 WHERE c.check_date between trunc(lc_extract_date )-1 and trunc(lc_extract_date)-(1/86400) --Modified for Defect# 29459
   AND c.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
   AND ip.check_id=c.check_id
   AND i.invoice_id=ip.invoice_id 
   AND vs.vendor_site_id=c.vendor_site_id
   AND v.vendor_id=vs.vendor_id 
   AND i.SOURCE = 'US_OD_FACILITY_SOURCE'
   AND EXISTS (SELECT 'x'
		 FROM ap_payment_schedules_all aps
                WHERE aps.invoice_id=i.invoice_id
		  AND NVL (aps.payment_method_lookup_code, aps.payment_method_code)='EFT'
	      );

-- Defect 22217 -- Ending -- Including union to extract the EFT transactions for current date


      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'FMSinvcpymt' || '.txt';
      --lc_fieldSeprator  VARCHAR2(2000) := '~';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lcinvccheckamt     VARCHAR2(12);
      lc_error_flag      VARCHAR2(10)                   := NULL; --Added for the Defect 3254.


BEGIN

  -- fnd_file.put_line (fnd_file.LOG, 'Processing Pyment Batch:    ' || payment_batch);

  l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

  FOR rcu_main IN lcu_main
  LOOP
  
    ln_vendor := xx_po_global_vendor_pkg.f_get_outbound (rcu_main.remit_vendor);

         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               (p_translation_name      => 'AP_PAYMENT_STATUS',
                                p_source_value1         => rcu_main.pymnt_status,
                                x_target_value1         => lc_status,
                                x_target_value2         => lr_target.target_value2,
                                x_target_value3         => lr_target.target_value3,
                                x_target_value4         => lr_target.target_value4,
                                x_target_value5         => lr_target.target_value5,
                                x_target_value6         => lr_target.target_value6,
                                x_target_value7         => lr_target.target_value7,
                                x_target_value8         => lr_target.target_value8,
                                x_target_value9         => lr_target.target_value9,
                                x_target_value10        => lr_target.target_value10,
                                x_target_value11        => lr_target.target_value11,
                                x_target_value12        => lr_target.target_value12,
                                x_target_value13        => lr_target.target_value13,
                                x_target_value14        => lr_target.target_value14,
                                x_target_value15        => lr_target.target_value15,
                                x_target_value16        => lr_target.target_value16,
                                x_target_value17        => lr_target.target_value17,
                                x_target_value18        => lr_target.target_value18,
                                x_target_value19        => lr_target.target_value19,
                                x_target_value20        => lr_target.target_value20,
                                x_error_message         => lc_error_message
                               );


    IF (rcu_main.invc_paid_amt * 100) < 0 THEN

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * -100), 10, '0');
       lcinvccheckamt := lcinvccheckamt || '-' ;

    ELSE

       lcinvccheckamt := LPAD ((rcu_main.invc_paid_amt * 100), 10, '0'); --Defect 2431
       lcinvccheckamt := lcinvccheckamt || '+' ;

    END IF;


    SELECT    RPAD (nvl(rcu_main.work_order_nbr,' '), 9,' ')
                || RPAD (nvl(rcu_main.invoice,' '), 20, ' ')
                || LPAD (to_char(ln_vendor), 9, '0')   -- DEFECT 2381 ,4096
                || RPAD (nvl(lc_status,' '), 4, ' ')
                || RPAD (TO_CHAR (rcu_main.check_dt, 'YYYY-MM-DD'), 10)
                || LPAD (nvl(to_char(rcu_main.check_nbr),' '), 7, ' ') -- defect 4096
                || lcinvccheckamt  -- Defect 11443
                || chr(13)
      INTO lc_recordstr
      FROM DUAL;

     --      fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
     UTL_FILE.put_line (l_fhandle, lc_recordstr);
  
  END LOOP;

  UTL_FILE.fclose (l_fhandle);

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/appayment/' || lc_filename     -- 4.0
                                           ,''
					   ,''
					   ,''
					   ,'$CUSTOM_DATA/xxfin/archive/outbound'
					   ,'','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');

   IF ln_req_id = 0  THEN

      fnd_file.put_line(fnd_file.LOG,'Program Ends in warning for ''Output Redirect''.');
      fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
      fnd_message.set_token ('ERR_ORA', 'XXCOMFILCOPY cannot be created');
      x_error_flag := 'Y';                           --Added for the Defect 3254.
      lc_err_msg := fnd_message.get;
      fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
      xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPIPOB',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'FACILITIES SOURCE'
                       );

   ELSE
    
     fnd_file.put_line (fnd_file.output,'Started ''Redirecting Output File'' at '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
     fnd_file.put_line (fnd_file.output, ' ');
     x_error_flag := 'N';                           --Added for the Defect 3254.
   END IF;
EXCEPTION
  WHEN OTHERS  THEN
    fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
    fnd_message.set_token ('ERR_ORA', SQLERRM);
    lc_err_msg := fnd_message.get;
    fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
    x_error_flag := 'Y';                           --Added for the Defect 3254.
    xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'FACILITIES SOURCE'
                                 );
    UTL_FILE.fclose (l_fhandle);
END facilities_source;   

   PROCEDURE start_process (p_errbuf OUT VARCHAR2
                            , p_retcode OUT VARCHAR2
                            , p_extract_date IN VARCHAR2
                            , p_interface IN VARCHAR2         --Added for the Defect 3254.
                            )
   IS
      lc_errbuf               VARCHAR2 (200)     := NULL;
      lc_retcode              VARCHAR2 (25)      := NULL;
      lc_err_msg              VARCHAR2 (2000);
      lc_extract_date         DATE;
      lc_error_flag           VARCHAR2(10) ;    --Added for the Defect 3254.
      lc_program_err_flag     VARCHAR2(10)         :=NULL;     --Added for the Defect 3254.
      ln_org_id               NUMBER;


   BEGIN
      ln_org_id := FND_PROFILE.VALUE('ORG_ID');

      lc_extract_date := fnd_conc_date.string_to_date(p_extract_date);
    CASE p_interface                          --Added for the Defect 3254.
    WHEN  'All' THEN

        fnd_file.put_line (fnd_file.LOG,
                           'Starting AP Payment Outbound Extract for ' || p_extract_date
                           || 'ln_org_id = '  || ln_org_id
                          );
        fnd_file.put_line (fnd_file.LOG,
                           'Starting AP extract to Big Sky Stores interfaces...'
                          );

        big_sky_stores(lc_extract_date ,lc_error_flag );  -- defect 11612
        IF lc_error_flag = 'Y' THEN
             lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,
                           'Starting AP extract to Big Sky Corp interfaces...');

        big_sky_corp(lc_extract_date ,lc_error_flag );    -- defect 11612
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line
                    (fnd_file.LOG,'Starting AP extract to Consignment Inventory interface...');

        consignment_inv(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;
        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Retail Lease interface...' );

        retail_lease(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line(fnd_file.LOG,'Starting AP extract to Sales Accounting interface...');

        sales_accounting(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
             lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to PAID interface...' );

        paid(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
             lc_Program_err_flag := 'Y';
        END IF;
        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to TDM interface...');

        tdm(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to GSS interface...');

        gss(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Project Mates interface...');

        project_mates(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to DATALINK interface...');

        datalink(lc_extract_date ,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
             lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Direct Commerce interface...');

        DCI(lc_extract_date ,ln_org_id,lc_error_flag );   -- added per CR889
        IF lc_error_flag = 'Y' THEN
             lc_Program_err_flag := 'Y';
        END IF;

        fnd_file.put_line (fnd_file.LOG,
                           'Starting AP extract to Facilities Source interfaces...');

        facilities_source(lc_extract_date ,lc_error_flag );   
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;        

        fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Legal Tracker interface...');

        Legal(lc_extract_date,lc_error_flag );
        IF lc_error_flag = 'Y' THEN
            lc_Program_err_flag := 'Y';
        END IF;        

        WHEN 'Big Sky Stores' THEN

             fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for '|| p_extract_date );
             fnd_file.put_line (fnd_file.LOG,
                           'Starting AP extract to Big Sky Stores interfaces...');

             big_sky_stores(lc_extract_date ,lc_error_flag );

        WHEN 'Big Sky Corp' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Big Sky Corp interfaces...');

              big_sky_corp(lc_extract_date ,lc_error_flag );

        WHEN  'Consignment Inventory' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line(fnd_file.LOG, 'Starting AP extract to Consignment Inventory interface...');
              consignment_inv(lc_extract_date ,lc_error_flag );

        WHEN  'Retail Lease' THEN
               fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
               fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Retail Lease interface...');
               retail_lease(lc_extract_date ,lc_error_flag );

        WHEN  'Sales Accounting' THEN
               fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
               fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Sales Accounting interface...');
               sales_accounting(lc_extract_date ,lc_error_flag );

        WHEN  'PAID' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to PAID interface...');
              paid(lc_extract_date ,lc_error_flag ) ;

        WHEN  'TDM' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to TDM interface...' );
              tdm(lc_extract_date ,lc_error_flag );

        WHEN  'GSS' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to GSS interface...');
              gss(lc_extract_date ,lc_error_flag );

        WHEN  'Project Mates' THEN
               fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
               fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Project Mates interface...');
               project_mates(lc_extract_date ,lc_error_flag );

        WHEN  'DATALINK' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to DATALINK interface...');
              datalink(lc_extract_date ,lc_error_flag );

        WHEN  'DCI' THEN                  -- added per CR889
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Direct Commerce interface...');
              DCI(lc_extract_date ,ln_org_id,lc_error_flag );

        WHEN 'Facilities Source' THEN
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Facilities Source interfaces...');

              facilities_source(lc_extract_date ,lc_error_flag );              

        WHEN  'Legal' THEN                  -- added per CR889
              fnd_file.put_line (fnd_file.LOG,'Starting AP Payment Outbound Extract for ' || p_extract_date);
              fnd_file.put_line (fnd_file.LOG,'Starting AP extract to Legal Tracker interface...');
              Legal(lc_extract_date,lc_error_flag );

       END CASE;                                         --Added for the Defect 3254.

     IF lc_error_flag = 'Y' OR lc_Program_err_flag = 'Y' THEN                      --Added for the Defect 3254.
         p_retcode  :=1;
         fnd_file.put_line (fnd_file.LOG,'Program ends in warning');
     ELSE
         p_retcode  :=0;
     END IF;
     EXCEPTION
      WHEN OTHERS THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0002_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         p_retcode  :=2;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPIPOB',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'START PROCESS'
                                 );
   END start_process;
END xx_ap_inv_pmt_outbound_pkg;
/
