create or replace PACKAGE BODY XX_FIN_VPS_MANUAL_NETTING_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_MANUAL_NETTING_PKG                                                     	|
  -- |                                                                                            |
  -- |  Description:  This package is used to create AR AP Manual Netting.        	              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- | 1.1         25-FEB-2019  Satheesh Suthari     Defect#84541 Receipts did not apply to invoices |
  -- +============================================================================================+
  
g_conc_request_id                       NUMBER:= fnd_global.conc_request_id;
g_total_records                         NUMBER;

PROCEDURE Update_Requestid
IS
BEGIN

    UPDATE xx_fin_vps_receipts_stg
       SET request_id             = g_conc_request_id
    WHERE request_id          IS NULL
      AND NVL(record_status,'N') ='N';
    g_total_records           := SQL%ROWCOUNT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Id :'||fnd_global.conc_request_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Records Selected from xx_fin_vps_receipts_stg :'||SQL%ROWCOUNT);
    COMMIT;
END Update_Requestid;

PROCEDURE Send_Email_Notif(  p_errbuf_out              OUT      VARCHAR2
                            ,p_retcod_out              OUT      VARCHAR2)
    IS
CURSOR cur_recep_inv (p_org_id number) is
     SELECT a.receipt_number
            ,TO_CHAR(nvl(-1*a.receipt_amount,0),'99G999G990D00')receipt_amount
            ,TO_CHAR(NVL((a.sum_appl-a.receipt_amount),a.receipt_amount),'99G999G990D00')unapplied_receipt_amount
            ,a.invoice_id
      FROM (SELECT acr.receipt_number
            ,stg.receipt_amount
            ,(SELECT SUM(aras.amount_applied)
              FROM ar_receivable_applications_all aras
              WHERE aras.cash_receipt_id = acr.cash_receipt_id
               AND aras.status='APP')sum_appl
              ,stg.invoice_id
        FROM  ar_receivable_applications_all ara
              ,ar_cash_receipts_all acr
              ,ap_invoices_all aia
              ,xx_fin_vps_receipts_stg stg
        WHERE 1=1
          AND ara.cash_receipt_id = acr.cash_receipt_id
          AND ara.org_id=p_org_id
          AND acr.org_id = p_org_id
          AND acr.receipt_number=stg.receipt_number
          AND acr.receipt_number=aia.invoice_num
          AND UPPER(aia.source) like 'US%VENDOR%'
          AND (stg.email_flag IS NULL OR stg.email_flag='N')
          --AND trunc(stg.creation_date)=trunc(SYSDATE)
          AND stg.record_status='S'
          GROUP BY acr.receipt_number
                  ,stg.receipt_amount
                  ,acr.cash_receipt_id
                  ,stg.invoice_id
              ) a 
          ;
CURSOR cur_recep_sum (p_org_id number) is
     SELECT nvl(SUM(-1*a.receipt_amount),0)sum_receipt_amount
      FROM (SELECT acr.receipt_number
            ,stg.receipt_amount
            ,(SELECT SUM(aras.amount_applied)
              FROM ar_receivable_applications_all aras
              WHERE aras.cash_receipt_id = acr.cash_receipt_id
               AND aras.status='APP')sum_appl
              ,stg.invoice_id
        FROM  ar_receivable_applications_all ara
              ,ar_cash_receipts_all acr
              ,ap_invoices_all aia
              ,xx_fin_vps_receipts_stg stg
        WHERE 1=1
          AND ara.cash_receipt_id = acr.cash_receipt_id
          AND ara.org_id=p_org_id
          AND acr.org_id = p_org_id
          AND acr.receipt_number=stg.receipt_number
          AND acr.receipt_number=aia.invoice_num
          AND UPPER(aia.source) like 'US%VENDOR%'
          AND (stg.email_flag IS NULL OR stg.email_flag='N')
          --AND trunc(stg.creation_date)=trunc(SYSDATE)
          AND stg.record_status='S'
          GROUP BY acr.receipt_number
                  ,stg.receipt_amount
                  ,acr.cash_receipt_id
                  ,stg.invoice_id
              ) a 
          ;

CURSOR cur_inv_details (p_org_id number) is
      SELECT stg.receipt_number
            ,stg.invoice_number
            ,TO_CHAR(nvl(stg.invoice_amount,0),'99G999G990D00')invoice_amount
            ,TO_CHAR(nvl(ara.amount_applied,0),'99G999G990D00')amount_applied
            ,TO_CHAR(nvl(arp.amount_due_remaining,0),'99G999G990D00')amount_due_remaining
            ,TO_CHAR(nvl(arp.amount_due_original,0),'99G999G990D00')amount_due_original
        FROM ar_payment_schedules_all arp
              ,ra_customer_trx_all rct
              ,ar_receivable_applications_all ara
              ,ar_cash_receipts_all acr
              ,ap_invoices_all aia
              ,xx_fin_vps_receipts_stg stg
        WHERE 1=1
          AND arp.customer_trx_id= rct.customer_trx_id
          AND ara.applied_customer_trx_id = rct.customer_trx_id
          AND rct.org_id=p_org_id
          AND rct.trx_number=stg.invoice_number
          AND ara.cash_receipt_id = acr.cash_receipt_id
          AND acr.org_id=p_org_id
          AND ara.org_id=p_org_id
          AND acr.receipt_number=stg.receipt_number
          AND acr.receipt_number=aia.invoice_num
          AND UPPER(aia.source) like 'US%VENDOR%'
          AND (stg.email_flag IS NULL OR stg.email_flag='N')
          --AND trunc(stg.creation_date)=trunc(SYSDATE)
          AND stg.record_status='S'
         -- AND stg.receipt_number=p_receipt_number
          AND ara.status='APP'
          ;      
 
          
 CURSOR cur_ap_rejections (p_org_id number) IS
      SELECT rct.trx_number
            ,acr.receipt_number
            ,TO_CHAR(nvl(stg.receipt_amount,0),'99G999G990D00')receipt_amount
            ,TO_CHAR(nvl(stg.invoice_amount,0),'99G999G990D00')invoice_amount
            ,TO_CHAR(nvl(ara.amount_applied,0),'99G999G990D00')amount_applied
            ,TO_CHAR(nvl(arp.amount_due_remaining,0),'99G999G990D00')amount_due_remaining
            ,TO_CHAR(nvl(arp.amount_due_original,0),'99G999G990D00')amount_due_original
            ,alc.description error_message
            ,stg.invoice_id
        FROM ar_payment_schedules_all arp
              ,ra_customer_trx_all rct
              ,ar_receivable_applications_all ARA
              ,ar_cash_receipts_all acr
              ,xx_fin_vps_receipts_stg stg
              ,ap_interface_rejections air
              ,ap_lookup_codes alc
        WHERE 1=1
          AND arp.customer_trx_id = rct.customer_trx_id
          AND ara.applied_customer_trx_id = rct.customer_trx_id
          AND rct.org_id=p_org_id
          AND ara.cash_receipt_id = acr.cash_receipt_id
          AND ara.org_id=p_org_id
          AND acr.org_id=p_org_id
          AND acr.receipt_number=stg.receipt_number
          AND (stg.email_flag IS NULL OR stg.email_flag='N')
          --AND trunc(stg.creation_date)=trunc(SYSDATE)
          AND stg.record_status='E'
          AND stg.invoice_id=air.parent_id
          AND air.reject_lookup_code=alc.lookup_code
          ; 

  lc_conn             UTL_SMTP.connection;
  lc_attach_text      VARCHAR2(32320);
  lc_success_data     VARCHAR2(32320);
  lc_receipt_summary  VARCHAR2(32320);
  lc_rec_inv_detail   VARCHAR2(32320);
  lc_exp_data         VARCHAR2(32320);
  lc_err_nums         NUMBER := 0;
  lc_request_id       NUMBER := fnd_global.conc_request_id;
  lc_mail_from        VARCHAR2(100); -- := 'ebs_test_notifications@officedepot.com';
  lc_mail_to          VARCHAR2(100); --:= fnd_profile.value('XX_VPS_SEND_MAIL_TO');
  lc_mail_request_id  NUMBER;
  lv_email_flag       VARCHAR2(1);
  lc_body 					  BLOB :=utl_raw.cast_to_raw('Attached Receipts and Invoices Created in EBS Successfully');
  lc_file_data 				BLOB;
  lc_blob_data        BLOB;
  lc_record 					NUMBER :=1;
  lc_err_msg_cnt 			NUMBER :=1;
  lc_excp_msg_cnt 	  NUMBER :=1;
  lv_org_id           NUMBER;
  lv_sob_id           NUMBER;
  lv_sum_rcpt_amt     NUMBER;
  lv_row_cnt          NUMBER := 0;
  lc_rcpt_sum_cnt     VARCHAR2(32320);
  lv_invoice_sum      NUMBER;
   BEGIN  
    --Org Id
      BEGIN
     SELECT organization_id, set_of_books_id
       INTO lv_org_id, lv_sob_id
      FROM hr_operating_units
      WHERE name = 'OU_US_VPS';
    EXCEPTION
        WHEN OTHERS THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating Unit Error: ' ||SQLERRM);	
    END;
      -- To Email
        BEGIN
          SELECT target_value1,target_value2 INTO  lc_mail_from,lc_mail_to
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='MANUAL_NETTING'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';       
         EXCEPTION 
         WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM); 
          fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SEND_EMAIL_NOTIF',
                         'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM
                        ); 
         END;   
         
         dbms_lob.createtemporary(lc_file_data, TRUE);
         
      -- Calling xx_pa_pb_mail procedure to mail with text in the mail body  
              lc_receipt_summary :='Following Receipts and Invoices Created in EBS Successfully at '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||CHR(13)||CHR(10);
              lc_receipt_summary :=lc_receipt_summary||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);
              lc_receipt_summary :=lc_receipt_summary|| RPAD ('AP Inv/AR Rcpt Number', 27, ' ') || ' ' 
                                               || RPAD ('AP Inv/AR Rcpt Amount', 27, ' ') || ' '
                                               || RPAD ('Unapplied Amount Receipt', 25, ' ')
                                               ||CHR(13)||CHR(10);
            lc_receipt_summary :=lc_receipt_summary||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10); 
             lc_record:=1;
              FOR i in cur_recep_inv(lv_org_id)
              LOOP
                lv_row_cnt := lv_row_cnt + 1;
                IF lc_record=1 then
                  lc_blob_data :=utl_raw.cast_to_raw(lc_receipt_summary
                                  ||RPAD (NVL (i.receipt_number, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (i.receipt_amount, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (i.unapplied_receipt_amount, ' '), 35, ' ')
                                  ||CHR(13)||CHR(10)) ;
                  ELSE
                      lc_blob_data :=utl_raw.cast_to_raw(RPAD (NVL (i.receipt_number, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (i.receipt_amount, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (i.unapplied_receipt_amount, ' '), 35, ' ')
                                  ||CHR(13)||CHR(10)) ; 
                  END IF;
                  DBMS_LOB.APPEND(lc_file_data,lc_blob_data);
                  lc_record:= lc_record+1;
                 END LOOP;
                 IF lv_row_cnt>0 THEN
                  lc_rcpt_sum_cnt :=lc_rcpt_sum_cnt||chr(13)||chr(10);
                  lc_rcpt_sum_cnt :=lc_rcpt_sum_cnt||rpad('Count : '||lv_row_cnt,17,' '); 
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Count: ' ||lv_row_cnt);
                  OPEN cur_recep_sum (lv_org_id);
                  FETCH cur_recep_sum into lv_invoice_sum;
                  CLOSE cur_recep_sum;
                  
                  lc_blob_data     := utl_raw.cast_to_raw(lc_rcpt_sum_cnt||Lpad(To_Char(lv_invoice_sum,'99G999G990D00'),25,' ')||chr(13)||chr(10));
                  DBMS_LOB.APPEND(lc_file_data,lc_blob_data);
                  	
                 END IF;
                      lc_rec_inv_detail :=lc_rec_inv_detail||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);
                      lc_rec_inv_detail :=lc_rec_inv_detail|| RPAD ('Receipt Number', 20, ' ') || ' '
                                                       || RPAD ('Transaction Number', 20, ' ') || ' ' 
                                                       || RPAD ('Oracle Invoice Amount', 27, ' ') || ' ' 
                                                       || RPAD ('Amount Applied', 25, ' ')||' '
                                                       || RPAD ('Invoice Amount Due', 25, ' ') || ' '
                                                       ||CHR(13)||CHR(10);
                      lc_rec_inv_detail :=lc_rec_inv_detail||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);
                    lc_record:=1;
                    FOR det in cur_inv_details(lv_org_id)
                    LOOP
                    IF lc_record=1 then
                      lc_blob_data :=utl_raw.cast_to_raw(lc_rec_inv_detail||RPAD (NVL (det.receipt_number, ' '), 20, ' ') || ' '
                                  ||RPAD (NVL (det.invoice_number, ' '), 20, ' ') || ' '
                                  ||RPAD (NVL (det.amount_due_original, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (det.amount_applied, ' '), 25, ' ')||' '
                                  ||RPAD (NVL (det.amount_due_remaining, ' '), 25, ' ')
                                  ||CHR(13)||CHR(10)
                                  ||CHR(13)||CHR(10));
                      ELSE
                        lc_blob_data :=utl_raw.cast_to_raw(RPAD (NVL (det.receipt_number, ' '), 20, ' ') || ' '
                                  ||RPAD (NVL (det.invoice_number, ' '), 20, ' ') || ' '
                                  ||RPAD (NVL (det.amount_due_original, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (det.amount_applied, ' '), 25, ' ')||' '
                                  ||RPAD (NVL (det.amount_due_remaining, ' '), 25, ' ')
                                  ||CHR(13)||CHR(10)
                                  ||CHR(13)||CHR(10));
                      END IF;
                      DBMS_LOB.APPEND(lc_file_data,lc_blob_data);
                      lc_record:= lc_record+1;
                      END LOOP;
                      
              --EXIT WHEN length(lc_success_data)>31000;
               /*   IF length(lc_success_data)>31000 THEN
                  lc_success_data :=lc_success_data||'Too Many Receipts Processed, Please check Log file of Conc Req ID-'||lc_request_id||CHR(10) ;
                  EXIT;
                  END IF; */
              
              --lc_success_data :=lc_success_data||'----------------------------------------------------------------------------------------------------------------------------------------'||CHR(10);  
              lc_exp_data :=lc_exp_data||CHR(13)||CHR(10)
                                       ||CHR(13)||CHR(10)
                                       ||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);  
              lc_exp_data :=lc_exp_data||'Following Exceptions Occured during AR/AP Netting Process'||CHR(13)||CHR(10);
              lc_exp_data :=lc_exp_data||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);  
              lc_exp_data :=lc_exp_data||RPAD ('Transaction Number', 20, ' ') || ' ' 
                                       ||RPAD ('Receipt Number', 20, ' ') || ' '
                                       ||RPAD ('Receipt Amount', 20, ' ') || ' ' 
                                       ||RPAD ('Error Message', 100, ' ')
                                       ||CHR(13)||CHR(10);
              lc_exp_data :=lc_exp_data||'-----------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10); 
              lc_record:= 1;
        FOR r in cur_ap_rejections(lv_org_id)
              LOOP
              IF lc_record=1 THEN
                lc_blob_data :=utl_raw.cast_to_raw(lc_exp_data||RPAD (NVL (r.trx_number, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (r.receipt_number, ' '), 25, ' ') || ' '
                                  ||RPAD (NVL (r.receipt_amount, ' '), 25, ' ') || ' '
                                  ||RPAD (NVL (r.error_message, ' '), 100, ' ') 
                                  ||CHR(13)||CHR(10));  
                lc_err_nums := cur_ap_rejections%ROWCOUNT; 
                --EXIT WHEN length(lc_exp_data)>31000;
                  IF length(lc_exp_data)>31000 THEN
                  lc_exp_data :=lc_exp_data||'Too Many Errors, Please check Log file of Conc Req ID-'||lc_request_id||CHR(10) ;
                  EXIT;
                  END IF;
              ELSE 
                lc_blob_data :=utl_raw.cast_to_raw(RPAD (NVL (r.trx_number, ' '), 27, ' ') || ' '
                                  ||RPAD (NVL (r.receipt_number, ' '), 25, ' ') || ' '
                                  ||RPAD (NVL (r.receipt_amount, ' '), 25, ' ') || ' '
                                  ||RPAD (NVL (r.error_message, ' '), 100, ' ') 
                                  ||CHR(13)||CHR(10)); 
                END IF;
                  DBMS_LOB.APPEND(lc_file_data,lc_blob_data);
                  lc_record:= lc_record+1;
              END LOOP; 
           --   fnd_file.put_line(fnd_file.output,'lc_err_nums'||lc_err_nums);
        
        IF lc_err_nums=0 THEN
              lc_blob_data :=utl_raw.cast_to_raw(lc_exp_data||'No Exceptions Found'||CHR(13)||CHR(10));
        END IF;
        dbms_lob.append(lc_file_data,lc_blob_data); 
        BEGIN
        lv_email_flag:='N'; -- Email not sent
        lc_conn := xx_pa_pb_mail.begin_mail (sender          =>  lc_mail_from,
                                            recipients      =>  lc_mail_to,
                                            cc_recipients   => NULL,
                                            subject         => 'Manual Upload AP_AR Daily Netting Status Report',
                                            mime_type          => xx_pa_pb_mail.multipart_mime_type
                                            );        
                    xx_pa_pb_mail.begin_attachment(conn       => lc_conn,
                                                   mime_type  =>'text/plain',
                                                   inline     =>NULL,
                                                   filename   => NULL,
                                                   transfer_enc => NULL); 
                     xx_pa_pb_mail.xx_attch_doc (lc_conn,
                                                 'Manual Upload AP_AR Daily Netting Status Report '||to_char(sysdate,'DD_MON_YYYY')||'.txt',
                                                 lc_file_data,--lc_attach_text,
                                                 'text/plain; charset=UTF-8'
                                                ); 
              
                     xx_pa_pb_mail.end_attachment (conn => lc_conn);                                    
                    xx_pa_pb_mail.end_mail (conn => lc_conn);--End of mail
                    
       lv_email_flag:='Y'; -- Email sent
      EXCEPTION
        WHEN OTHERS THEN 
          lv_email_flag:='E'; -- Error in sending email
          NULL;
      END;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Flag: '||lv_email_flag);
      FOR i in cur_recep_inv (lv_org_id) LOOP
        UPDATE xx_fin_vps_receipts_stg
          SET email_flag=lv_email_flag
              ,last_update_date=sysdate
        WHERE 1=1
          AND receipt_number=i.receipt_number
          AND invoice_id =i.invoice_id;
       END LOOP;
      COMMIT;
      FOR r in cur_ap_rejections(lv_org_id) LOOP
        UPDATE xx_fin_vps_receipts_stg
          SET email_flag=lv_email_flag
              ,last_update_date=sysdate
        WHERE 1=1
          AND receipt_number=r.receipt_number
          AND invoice_id =r.invoice_id;
       END LOOP;
      COMMIT;
   EXCEPTION           
      WHEN OTHERS
      THEN
          fnd_file.put_line(fnd_file.log,'Unable to send mail '||SQLERRM); 
          fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SEND_EMAIL_NOTIF',
                         SQLERRM
                        ); 
END;

PROCEDURE Print_Receipt_Invoice_Details
   IS
      lv_row_cnt                    NUMBER := 0;
 CURSOR cur_stg_tbl (p_request_id   NUMBER)
      IS
         SELECT   vendor_num
                  ,receipt_number
                  ,receipt_method
                  ,receipt_amount
                  ,invoice_number
                  ,invoice_amount
                  ,record_status
                  ,decode(error_message,'You may not apply more than the receipt amount.','You may not apply more than the receipt amount.Please check the Oracle Invoice amount'
                                          ,error_message)error_message
         FROM     xx_fin_vps_receipts_stg
         WHERE    request_id = p_request_id
         ORDER BY interface_id;
   --
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Print_Receipt_Invoice_Details');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('-',360 , '-'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'VPS Receipt/Invoice Details Report');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 360, '-'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('Vendor#', 30, ' ') || ' '
                                    || RPAD ('Receipt#', 20, ' ') || ' '
                                    || RPAD ('Receipt Method', 30, ' ') || ' '
                                    || RPAD ('Receipt Amount', 20, ' ') || ' '
                                    || RPAD ('Invoice#', 20, ' ') || ' '
                                    || RPAD ('Invoice Amount', 20, ' ') || ' '
                                    || RPAD ('Status', 20, ' ') || ' '
                                    || RPAD ('Message', 200, ' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 30, '-') || ' '
                                    || RPAD ('-', 20, '-') || ' '
                                    || RPAD ('-', 30, '-') || ' '
                                    || RPAD ('-', 20, '-') || ' '
                                    || RPAD ('-', 20, '-') || ' '
                                    || RPAD ('-', 20, '-') || ' '
                                    || RPAD ('-', 200, '-'));
  Fnd_File.Put_Line(Fnd_File.Log,'g_conc_request_id '||g_conc_request_id);
   FOR stg_tbl_rec IN cur_stg_tbl (g_conc_request_id)
      LOOP
        -- Fnd_File.Put_Line(Fnd_File.Log,'Inside loop g_conc_request_id '||g_conc_request_id);
         --
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD (NVL (stg_tbl_rec.vendor_num, ' '), 30, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.receipt_number, ' '), 20, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.receipt_method, ' '), 30, ' ') || ' '
                || RPAD (TO_CHAR(nvl(stg_tbl_rec.receipt_amount,0),'99G999G990D00PR'), 20, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.invoice_number, ' '), 20, ' ') || ' '
                || RPAD (TO_CHAR(nvl(stg_tbl_rec.invoice_amount,0),'99G999G990D00PR'),20, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.record_status, ' '), 20, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.error_message, ' '), 200, ' ') 
                );
         lv_row_cnt := lv_row_cnt + 1;
      END LOOP;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Row Count: ' || lv_row_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 360, '-'));
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in Print_Receipt_Invoice_Details: '||SQLERRM);
   END Print_Receipt_Invoice_Details;

PROCEDURE Process_AP_Invoice(
    p_vendor_num               IN VARCHAR2 ,
    p_vendor_site_code         IN VARCHAR2 ,
    p_source                   IN VARCHAR2 ,
    p_group_id                 IN VARCHAR2 ,
    p_invoice_id               IN NUMBER ,
    p_invoice_num              IN VARCHAR2 ,
    p_invoice_type_lookup_code IN VARCHAR2 ,
    p_invoice_date             IN DATE ,
    p_invoice_amount           IN NUMBER ,
    p_description              IN VARCHAR2 ,
    p_attribute_category       IN VARCHAR2 ,
    p_attribute10              IN VARCHAR2 ,
    p_attribute11              IN VARCHAR2 ,
    p_vendor_email_address     IN VARCHAR2 ,
    p_external_doc_ref         IN VARCHAR2 ,
    p_legacy_segment2          IN VARCHAR2 ,
    p_legacy_segment3          IN VARCHAR2 ,
    p_legacy_segment4          IN VARCHAR2 ,
    p_invoice_line_id          IN NUMBER ,
    p_line_number              IN VARCHAR2 ,
    p_line_type_lookup_code    IN VARCHAR2 ,
    p_invoice_line_amount      IN NUMBER ,
    p_global_attribute11       IN VARCHAR2,
    p_receipt_method           IN VARCHAR2,
    o_invoice_id               OUT NUMBER,
    x_err_msg                  OUT VARCHAR2
    )
IS
  v_company                 VARCHAR2(150);
  v_lob                     VARCHAR2(150);
  v_location_type           VARCHAR2(150);
  v_cost_center_type        VARCHAR2(150);
  v_intercompany            gl_code_combinations.segment5%TYPE:='0000';
  v_future                  gl_code_combinations.segment7%TYPE:= '000000';
  v_user_id                 NUMBER:= NVL (fnd_profile.VALUE ('USER_ID'), 0);
  v_invoice_id              NUMBER;
  v_vendor_site_id          NUMBER;
  v_vendor_id               NUMBER;
  v_org_id                  po_vendor_sites_all.org_id%TYPE;
  v_count                   NUMBER;
  v_terms_id                NUMBER;
  v_payment_method          VARCHAR2(25);
  v_pay_group_lookup        VARCHAR2(25);
  v_full_gl_code            VARCHAR2 (2000);
  v_ccid                    NUMBER;
  lc_coa_id                 gl_sets_of_books_v.chart_of_accounts_id%TYPE;
  lc_error_flag             VARCHAR2 (1) := 'N';
  lc_error_loc              VARCHAR2 (2000);
  lc_loc_err_msg            VARCHAR2 (2000);
  v_cnt                     NUMBER:=0;
  v_sup_attr8               VARCHAR2(100); 
  v_consignment_flag        VARCHAR2(10);
  v_vendor_site_code        po_vendor_sites_all.vendor_site_code%TYPE;
    --lc_err_mesg             VARCHAR2(1000);


BEGIN
  v_vendor_id        := NULL;
  v_vendor_site_id   := NULL;
  v_org_id           := NULL;
  v_terms_id         := NULL;
  v_payment_method   := NULL;
  v_pay_group_lookup := NULL;
  v_ccid             := NULL;
  x_err_msg          := NULL;

 --Get Invoice Id
  SELECT ap_invoices_interface_s.NEXTVAL
    INTO   v_invoice_id
    FROM   DUAL;
  --Get AP Payment Terms
    BEGIN
        SELECT term_id 
        INTO v_terms_id
        FROM ap_terms 
        WHERE name='00';
    EXCEPTION WHEN OTHERS THEN
         v_terms_id := NULL;
         lc_error_flag:='Y';
         x_err_msg :=    SQLCODE|| SQLERRM;
    END;
  --Get Vendor Details
    BEGIN
    SELECT
        ssa.vendor_site_id,
        ssa.vendor_id,
        ssa.org_id, 
        ieppm.payment_method_code,
        ssa.pay_group_lookup_code,
      --  ssa.accts_pay_code_combination_id,
        ssa.attribute8,
        ssa.vendor_site_code
      INTO v_vendor_site_id,
        v_vendor_id,
        v_org_id, 
        v_payment_method,
        v_pay_group_lookup,
    --    v_ccid,
        v_sup_attr8,
        v_vendor_site_code
    FROM   ap_supplier_sites_all ssa
          ,iby_external_payees_all iepa
          ,iby_ext_party_pmt_mthds ieppm 
    WHERE  LTRIM(ssa.vendor_site_code_alt,'0')=P_VENDOR_NUM
      AND  ssa.pay_site_flag='Y'
      AND  ssa.attribute8 like 'TR%'
      AND  (ssa.inactive_date  IS NULL
      OR   ssa.inactive_date     > SYSDATE)
      AND  ssa.vendor_site_id = iepa.supplier_site_id 
      AND  iepa.ext_payee_id = ieppm.ext_pmt_party_id 
      AND ((ieppm.inactive_date IS NULL) OR (ieppm.inactive_date > SYSDATE))
      AND ieppm.primary_flag = 'Y' ;  
     
  EXCEPTION
  WHEN OTHERS THEN
    lc_error_flag:='Y';
    x_err_msg :=    SQLCODE|| SQLERRM;
  END;
  
  BEGIN
          SELECT target_value1 INTO  v_consignment_flag
                 FROM xx_fin_translatedefinition xftd
                    , xx_fin_translatevalues xftv
                WHERE xftv.translate_id = xftd.translate_id
                  AND xftd.translation_name ='OD_VPS_TRANSLATION'
                  AND source_value1='CONSIGNMENT_VALIDATION'
                  AND NVL (xftv.enabled_flag, 'N') = 'Y';
   IF v_consignment_flag='Yes' THEN
      SELECT code_combination_id
                      INTO v_ccid
                      FROM gl_code_combinations
                     WHERE 1=1
                       AND segment1='1001'
                       AND segment2='00000'
                       AND segment3='20101000'
                       AND segment4='010000'
                       AND segment5='0000'
                       AND segment6='90'
                       AND segment7='000000';
              IF v_sup_attr8 IN ('TR-CON' , 'TR-OMXCON') THEN
                  SELECT count(1) into v_count
                    FROM  
                        apps.iby_external_payees_all iep,
                        apps.iby_pmt_instr_uses_all ipiu 
                  WHERE iep.supplier_site_id=v_vendor_site_id
                    AND payment_flow='DISBURSEMENTS'
                    AND ipiu.ext_pmt_party_id=iep.ext_payee_id
                    AND (ipiu.end_date is null or (sysdate between start_date and end_date)) 
                    AND ipiu.instrument_type = 'BANKACCOUNT';
              
                      IF v_count > 0 then
                        v_payment_method := 'EFT';
                        v_pay_group_lookup := 'US_OD_TRADE_EFT';
                      ELSE
                        v_payment_method := 'CHECK';
                        v_pay_group_lookup := 'US_OD_TRADE_NON_DISCOUNT'; 
                      END IF;
            END IF;
       ELSE
              v_ccid:=NULL;
    END IF;
        EXCEPTION WHEN OTHERS THEN
            v_consignment_flag :=NULL; 
            x_err_msg :=    'v_consignment_flag'||SQLCODE
                          || SQLERRM;
            fnd_file.put_line(fnd_file.log,'Error While Getting Consignment Validation Flag'||SQLERRM);
        END;
  fnd_file.put_line(fnd_file.log,'CCID: '||v_ccid);
  IF lc_error_flag='N' THEN
  BEGIN
  -- accts_pay_code_combination_id Added by Thejaswini Rajula 12/19/17
    INSERT
    INTO ap_invoices_interface
      (
        invoice_id,
        invoice_num,
        invoice_type_lookup_code,
        invoice_date,
        vendor_id,
        vendor_site_id,
        invoice_amount,
        invoice_currency_code,
        terms_id,
        description,
        last_update_date,
        last_updated_by,
        last_update_login,
        creation_date,
        created_by,
        attribute_category,
        attribute7,
        attribute10,
        attribute11,
        source,
        group_id,
        payment_method_code,
        pay_group_lookup_code,
        org_id,
        vendor_email_address,
        external_doc_ref,
        goods_received_date,
        accts_pay_code_combination_id  
      )
      VALUES
      (
        v_invoice_id, --AP_INVOICES_INTERFACE_S.NEXTVAL, --p_invoice_id,
        p_invoice_num,
        p_invoice_type_lookup_code,
        NVL (p_invoice_date, SYSDATE),
        v_vendor_id,
        v_vendor_site_id,
        p_invoice_amount,
        'USD',
        v_terms_id,
        p_description,
        SYSDATE,
        v_user_id,
        NULL,      --last_update_login
        SYSDATE,   --creation_date
        v_user_id, --created_by
        p_attribute_category,
        p_source,
        p_attribute10,
        p_attribute11,
        p_source,
        p_GROUP_ID,
        v_payment_method,
        v_pay_group_lookup,
        v_org_id,
        p_vendor_email_address,
        p_external_doc_ref,
        NVL (p_invoice_date, SYSDATE),
        v_ccid 
      );
  EXCEPTION
  WHEN OTHERS THEN 
    lc_error_flag:='Y';
    fnd_file.put_line (fnd_file.LOG, 'Unable to insert Header for Invoice/Vendor/Site : '|| p_invoice_num||','||p_vendor_num||','||p_vendor_site_code);
    x_err_msg :=    SQLCODE|| SQLERRM;
    fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'Process_AP_Invoice',
                         x_err_msg
                    );                      
  END;
  
  --Get the CCID for AP INVOICE LINES
IF lc_error_flag='N' THEN
          BEGIN
            SELECT cash_ccid
              INTO v_ccid
              FROM ar_receipt_methods arm,
                 ar_receipt_method_accounts_all ara
            WHERE ara.receipt_method_id=arm.receipt_method_id
              AND arm.name               =p_receipt_method--'US_VPS_DM_AUTO_NET'  -- change receipt_method
              AND ara.org_id             =fnd_global.org_id;
          EXCEPTION
          WHEN OTHERS THEN
            v_ccid := NULL;
          END;
 
  BEGIN
    INSERT
    INTO ap_invoice_lines_interface
      (
        invoice_id,
        invoice_line_id,
        line_number,
        line_type_lookup_code,
        amount,
        description,
        dist_code_concatenated,
        dist_code_combination_id,
        last_updated_by,
        last_update_date,
        last_update_login,
        created_by,
        creation_date,
        org_id,
        global_attribute11
      )
      VALUES
      (
        v_invoice_id, 
        AP_INVOICE_LINES_INTERFACE_S.NEXTVAL,  
        '1',  
        'ITEM',  
        p_invoice_amount, 
        p_description,
        NULL,  
        v_ccid,
        v_user_id, --last_updated_by
        SYSDATE,   --last_update_date
        NULL,      --last_update_login
        v_user_id, --created_by
        SYSDATE,   --creation_date
        v_org_id,
        p_global_attribute11
      );
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_LINES_INTERFACE '||SQLERRM);
    lc_error_loc := 'Unable to insert invoice line for Invoice/Line No : '||p_invoice_num||','||TO_CHAR(p_line_number); 
    fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
    x_err_msg :=    SQLCODE|| SQLERRM;
    lc_error_flag:='Y';
     fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'Process_AP_Invoice',
                         x_err_msg
                        ); 
  END;
END IF;
  
  --COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Interfaced Successfully: '||v_invoice_id); 
   fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'Process_AP_Invoice',
                         'Invoice Interfaced Successfully: '||p_invoice_num
                        ); 
 END IF;
 o_invoice_id :=v_invoice_id; 
  
EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No records found to process for the Source :'||p_source);
    o_invoice_id :=0;
    x_err_msg :=    SQLCODE
                            || SQLERRM; 
   fnd_log.STRING (fnd_log.level_statement,
                           g_pkg_name || 'Process_AP_Invoice',
                           x_err_msg
                          );                         
END Process_AP_Invoice; 

PROCEDURE Process_Vendor_Netting (p_retcod_out OUT VARCHAR2)
IS 

  l_user_id                NUMBER;
  l_responsibility_id      NUMBER;
  l_responsibility_appl_id NUMBER;
  ln_org_id                NUMBER;
  l_cash_ccid              NUMBER;
  l_msg_index_num          NUMBER:= 1;
  l_msg_count              NUMBER;
  l_data_txt               VARCHAR2(1000);
  l_msg_data               VARCHAR2(1000);
  l_err_msg                VARCHAR2(2000);
  l_apl_return_status      VARCHAR2 (1);
  l_apl_msg_count          NUMBER;
  l_apl_msg_data           VARCHAR2 (240);
  l_org_id                 NUMBER := fnd_global.org_id;
  l_return_status          VARCHAR2(10);
  l_currency_code          fnd_currencies.currency_code%TYPE;
  l_account_name           HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE;
  l_account_number         HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
  l_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;
  l_gl_date_count          NUMBER;
  l_functional_currency    fnd_currencies.currency_code%TYPE;
  l_conv_type              gl_daily_conversion_types.conversion_type%TYPE;
  l_conv_rate              gl_daily_rates.conversion_rate%TYPE;
  l_cust_account_id        hz_cust_accounts.cust_account_id%TYPE;
  l_trx_number             ra_customer_trx_all.trx_number%TYPE;
  l_customer_trx_id        ra_customer_trx_all.customer_trx_id%TYPE;
  l_inv_status             ar_payment_schedules_all.status%TYPE;
  l_err_text               VARCHAR2(256);
  ln_attr_group_id         NUMBER;
  lv_error_flag            VARCHAR2(1);
  lv_output                VARCHAR2(4000);
  l_invoice_id             NUMBER;
  l_success_text           VARCHAR2(32000);
  l_amount_due_remaining    NUMBER;
  l_amount_apply           NUMBER;
  lv_row_cnt               NUMBER;
  l_receipt_method         ar_receipt_methods.name%TYPE;

CURSOR cur_receipts
IS
  SELECT distinct vendor_num,receipt_number,receipt_amount,receipt_method,receipt_date
  FROM  xx_fin_vps_receipts_stg
  WHERE 1=1
    AND record_status='N'
	AND request_id=g_conc_request_id;
  
  
CURSOR cur_receipts_inv(p_vendor_num varchar2, p_receipt_number varchar2)
IS
  SELECT distinct vendor_num,receipt_number,invoice_number,invoice_amount,receipt_amount,interface_id
  FROM  xx_fin_vps_receipts_stg
  WHERE 1=1
    AND record_status='N'
    AND request_id=g_conc_request_id
    AND vendor_num=p_vendor_num
    AND receipt_number=p_receipt_number
    order by interface_id; 
    
CURSOR cur_cust_account (p_vendor_num varchar2,p_attr_group_id number)
IS	
	SELECT hca.cust_account_id,hca.account_name,hca.account_number
	FROM hz_cust_accounts_all hca
	WHERE 1                  =1
  AND hca.orig_system_reference=p_vendor_num||'-VPS';
  
CURSOR cur_receipt_method (p_receipt_method varchar2)
IS 
  SELECT target_value1 
    FROM xx_fin_translatedefinition xftd
        , xx_fin_translatevalues xftv
   WHERE xftv.translate_id = xftd.translate_id
     AND xftd.translation_name ='OD_VPS_TRANSLATION'
     AND source_value1='MANUAL_NETTING_RECEIPT_METHOD'
     AND target_value1=p_receipt_method
     AND NVL (xftv.enabled_flag, 'N') = 'Y';

BEGIN
	FND_FILE.put_line(fnd_file.log,'Start:'||g_conc_request_id);
	fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'Process_Vendor_Netting',
										 'Start:'||g_conc_request_id
										);									
  	--Start apps intialization
  SELECT organization_id 
    INTO l_org_id
    FROM hr_operating_units
    WHERE name='OU_US_VPS';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id  : ' || l_org_id);
		mo_global.set_policy_context('S',l_org_id); 
 
	For r in cur_receipts LOOP
    l_msg_count           := 0;
    l_data_txt            := NULL;
    l_msg_index_num       := NULL;
    l_err_msg             := NULL;
    l_gl_date_count       := 0;
    l_currency_code       := 'USD';
    l_functional_currency := NULL;
    l_conv_type           := NULL;
    l_conv_rate           := NULL;
    l_receipt_id          := NULL;
    l_return_status       := NULL;
    l_msg_data            := NULL;
    lv_error_flag         :='N';
    lv_output             := NULL;
    l_amount_due_remaining := NULL;
    l_cust_account_id     := NULL;
    l_account_name        := NULL;
    l_account_number      := NULL;
    l_trx_number          := NULL;
    l_customer_trx_id     := NULL;
    l_receipt_method      := NULL;
    --l_amount_due_original := NULL;
    --Get Cust Account Number 
     open cur_cust_account (r.vendor_num,ln_attr_group_id);
    fetch cur_cust_account into l_cust_account_id ,l_account_name,l_account_number;
    close cur_cust_account;
    IF l_cust_account_id IS NULL THEN 
      lv_error_flag         :='Y';
      lv_output:='No Vendor Found';
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.log,'Account Number:'||l_account_number); 
      FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Amount:'||r.receipt_amount); 
      FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Number:'||r.receipt_number); 
      FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Date:'||TO_DATE(r.receipt_date,'DD-MON-YYYY')); 
      FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Method:'||r.receipt_method);  
    /*  IF r.invoice_amount > l_amount_due_original THEN 
        l_amount_diff:= r.invoice_amount-l_amount_due_original;
      END IF; */
				   -- Call Api to create receipt
			   AR_RECEIPT_API_PUB.CREATE_CASH( p_api_version                => 1.0,
											   p_init_msg_list              => fnd_api.g_true, 
											   p_commit                     => fnd_api.g_false, 
											   p_validation_level           => FND_API.G_VALID_LEVEL_FULL, 
											   p_currency_code              => l_currency_code, 
											   p_exchange_rate_type         => NULL,
											   p_exchange_rate              => NULL,
											   p_exchange_rate_date         => NULL,
											   p_amount                     => r.receipt_amount,      
											   p_receipt_number             => r.receipt_number,
											   p_receipt_date               => TO_DATE(r.receipt_date,'DD-MON-YYYY'),               
											   p_maturity_date              => NULL,
											   p_customer_name              => NULL,     
											   p_customer_number            => l_account_number, 
											   p_comments                   => NULL ,                 
											   p_location                   => NULL ,                 
											   p_customer_bank_account_num  => NULL,         
											   p_customer_bank_account_name => NULL,         
											   p_receipt_method_name        => r.receipt_method,
											   p_org_id                     => l_org_id,
											   p_cr_id                      => l_receipt_id,
											   x_return_status              => l_return_status, 
											   x_msg_count                  => l_msg_count, 
											   x_msg_data                   => l_msg_data 
											   );
				IF l_return_status = 'S' THEN
				   FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Created Successfully:'||l_receipt_id); 
				   fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'Process_Vendor_Netting',
										 'Receipt Created Successfully:'||l_receipt_id
										);
				ELSE
            lv_error_flag         :='Y';
				   FND_FILE.PUT_LINE(FND_FILE.LOG,'Message count ' || l_msg_count);
				   IF l_msg_count = 1 THEN
					  FND_FILE.PUT_LINE(FND_FILE.LOG,'l_msg_data '||l_msg_data);
            lv_output:=lv_output||l_msg_data;
					  fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'Process_Vendor_Netting',
										 l_msg_data
										);
            ROLLBACK;
				   ELSIF l_msg_count > 1 THEN
				   LOOP
            lv_error_flag         :='Y';
					  l_msg_count := l_msg_count+1;
					  L_Msg_Data := Fnd_Msg_Pub.Get(Fnd_Msg_Pub.G_Next,Fnd_Api.G_False);
           lv_output:=lv_output||L_Msg_Data;
           FND_FILE.PUT_LINE(FND_FILE.LOG,lv_output); 
					  fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'Process_Vendor_Netting',
										 l_msg_data
										);
					  IF l_msg_data IS NULL THEN
                EXIT;
					  END IF; 
					  END LOOP;
					  END IF; 
				END IF;   

  IF l_return_status = 'S' THEN   --Created Cash Receipt         
		   --Apply the invoice amount in AR
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Receipts Apply: ');
    FOR i_record in cur_receipts_inv(r.vendor_num,r.receipt_number )LOOP
      l_amount_apply        := NULL;
      l_amount_due_remaining := NULL;
      l_trx_number          := NULL;
      l_customer_trx_id     := NULL;
      BEGIN
            SELECT rct.trx_number,rct.customer_trx_id,arp.amount_due_remaining,arp.status
              INTO l_trx_number,l_customer_trx_id,l_amount_due_remaining,l_inv_status
              FROM ra_customer_trx_all rct,
                  ar_payment_schedules_all arp
            WHERE 1=1
			        AND rct.org_id=l_org_id--Defect#84541 Receipts did not apply to invoices
              AND rct.trx_number=i_record.invoice_number
              AND rct.customer_trx_id=arp.customer_trx_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN 
                l_trx_number:=NULL;
                l_customer_trx_id:=NULL;
              WHEN OTHERS THEN 
                l_trx_number:=NULL;
                l_customer_trx_id:=NULL;
            END;
        FND_FILE.PUT_LINE(FND_FILE.log,'Transaction Number:'||l_trx_number);
        FND_FILE.PUT_LINE(FND_FILE.log,'Transaction Status:'||l_inv_status);
        --Check Invoice Amount
       /* IF i_record.invoice_amount>=l_amount_due_remaining THEN
           -- l_amount_apply:=l_amount_due_remaining;
           l_amount_apply:=i_record.invoice_amount;
          ELSIF i_record.invoice_amount<l_amount_due_remaining THEN
            l_amount_apply:=i_record.invoice_amount;
        END IF; */
      IF l_inv_status<>'CL' THEN
        IF i_record.invoice_amount IS NULL THEN 
          l_amount_apply:=l_amount_due_remaining;
          FND_FILE.PUT_LINE(FND_FILE.log,'Amount Applied to receipt:'||l_amount_apply);
        ELSE 
          l_amount_apply:=i_record.invoice_amount;
          FND_FILE.PUT_LINE(FND_FILE.log,'Amount Applied to receipt:'||l_amount_apply);
      END IF;
      ELSE
        IF i_record.invoice_amount IS NULL THEN 
          l_amount_apply:=0;
          FND_FILE.PUT_LINE(FND_FILE.log,'Amount Applied to receipt:'||l_amount_apply);
        ELSE
          l_amount_apply:=i_record.invoice_amount;
          FND_FILE.PUT_LINE(FND_FILE.log,'Amount Applied to receipt:'||l_amount_apply);
        END IF;
    END IF;
      IF l_trx_number IS NOT NULL THEN 
              
                       AR_RECEIPT_API_PUB.APPLY
                            (p_api_version                      => 1.0,
                             p_init_msg_list                    => fnd_api.g_true,
                             p_commit                           => fnd_api.g_false,
                             p_validation_level                 => fnd_api.g_valid_level_full,
                             x_return_status                    => l_return_status,
                             x_msg_count                        => l_msg_count,
                             x_msg_data                         => l_msg_data,
                             p_cash_receipt_id                  => l_receipt_id,
                             p_customer_trx_id                  => l_customer_trx_id,
                           --  p_installment                      => i_record.terms_sequence_number,
                           --  p_applied_payment_schedule_id      => i_record.payment_schedule_id,
                             p_show_closed_invoices              => 'Y',
                             p_amount_applied                   => l_amount_apply,
                             p_discount                         => NULL,
                             p_apply_date                       => sysdate
                           );
                  
              IF l_return_status = 'S' THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Applied to transaction successfully: '||l_customer_trx_id); 
                           fnd_log.STRING (fnd_log.level_statement,
                                       g_pkg_name || 'Process_Vendor_Netting',
                                       'Transaction Applied Successfully: '||l_customer_trx_id
                                      );                        
                        ELSE
                          lv_error_flag         :='Y';
                          p_retcod_out:=2;
                          ROLLBACK; 
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Message count ' || l_msg_count);
                        IF l_msg_count = 1 THEN
                          Fnd_File.Put_Line(Fnd_File.Log,'l_msg_data '||L_Msg_Data);
                          --insert_log('E',i_record.trx_number,l_account_number||':'||l_msg_data); 
                          lv_output:=lv_output||L_Msg_Data;
                          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_output); 
                          fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || 'Process_Vendor_Netting',
                                     l_msg_data
                                    );
                         ELSIF l_msg_count > 1 THEN
                         LOOP
                          lv_error_flag         :='Y';
                          p_retcod_out:=2;
                          ROLLBACK;
                          l_msg_count := l_msg_count+1;
                          L_Msg_Data := Fnd_Msg_Pub.Get(Fnd_Msg_Pub.G_Next,Fnd_Api.G_False);
                          lv_output:=lv_output||L_Msg_Data;
                          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_output); 
                          --insert_log('E',i_record.trx_number,p_account_number||':'||l_msg_data);
                          IF l_msg_data IS NULL THEN
                              EXIT;
                          End If; 
                        END LOOP;
                          END IF; 
                        END IF;                   
              END IF; --end if for S Receipt Trx Apply
          END LOOP; --end loop for S Receipt Trx Apply
       IF l_return_status = 'S' THEN --If Cash Receipt Creation is successful- create AP Invoice
              --Start AP Invoice Staging
                Fnd_File.Put_Line(Fnd_File.Log,'Start Process_AP_Invoice');
                  fnd_log.STRING (fnd_log.level_statement,
                                 g_pkg_name || 'Process_Vendor_Netting',
                                 'Start Process_AP_Invoice'
                                );
             open cur_receipt_method (r.receipt_method);
            fetch cur_receipt_method into l_receipt_method;
            close cur_receipt_method;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Method Validation: '||l_receipt_method);
          --Process AP Invoice if Receipt Method is MANUAL CM AND MANUAL DM
            IF l_receipt_method IS NOT NULL THEN 
                    BEGIN 
                        Process_AP_Invoice(
                                p_vendor_num =>r.vendor_num  ,
                                p_vendor_site_code => NULL ,
                                p_source =>'US_OD_VENDOR_PROGRAM', 
                                p_group_id  => NULL,
                                p_invoice_id => NULL ,
                                p_invoice_num => r.receipt_number ,
                                p_invoice_type_lookup_code =>'CREDIT', 
                                p_invoice_date => Sysdate,
                                p_invoice_amount =>(r.receipt_amount*-1),
                                p_description =>TO_CHAR(SYSDATE,'DD-MON-YYYY hh24:mi:ss'),
                                p_attribute_category => NULL,
                                p_attribute10=> NULL ,
                                p_attribute11=> NULL ,
                                p_vendor_email_address=> NULL ,
                                p_external_doc_ref => NULL,
                                p_legacy_segment2 => NULL,
                                p_legacy_segment3 => NULL ,
                                p_legacy_segment4 => NULL,
                                p_invoice_line_id => NULL,
                                p_line_number => NULL,
                                p_line_type_lookup_code =>NULL,
                                p_invoice_line_amount =>NULL,
                                p_global_attribute11  => NULL,
                                p_receipt_method=>r.receipt_method,
                                o_invoice_id =>  l_invoice_id,
                                x_err_msg => l_err_msg
                                );  
                      IF l_err_msg is Not null OR l_invoice_id =0 THEN
                            L_Err_Text :=L_Err_Text||Chr(10)||'Invoice Interface Insert Error: '||L_Err_Msg;
                            lv_error_flag:='Y';
                            lv_output:=lv_output||L_Err_Text;
                            Fnd_File.Put_Line(Fnd_File.Log,lv_output);
                            fnd_log.STRING (fnd_log.level_statement,
                                         g_pkg_name || 'Process_Vendor_Netting',
                                         l_err_msg
                                        );
                          ROLLBACK;
                          
                      END IF; 
                            l_success_text :=rpad(r.receipt_number,20,' ')
                              ||Lpad(To_Char(r.Receipt_Amount,'99G999G990D00PR'),23,' ')
                              ||Lpad(To_Char(r.Receipt_Amount*-1,'99G999G990D00PR'),22,' ');    
                    COMMIT;   
                      EXCEPTION
                      WHEN OTHERS THEN 
                        ROLLBACK;
                          Fnd_File.Put_Line(Fnd_File.Log,'Unexpected Error in Process AP Invoice:Process_Vendor_Netting: '||Sqlerrm);
                          l_err_text :='Unexpected Error in Process AP Invoice:Process_Vendor_Netting: '||Sqlerrm;
                          lv_error_flag:='Y';
                          lv_output:=lv_output||l_err_text;
                          Fnd_File.Put_Line(Fnd_File.Log,lv_output); 
                          fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || 'Process_Vendor_Netting',
                                     l_err_text
                                    ); 
                      END;  
                     Fnd_File.Put_Line(Fnd_File.Log,'End Process_AP_Invoice');
                    ELSE
                      l_invoice_id:=NULL;
                    END IF;
                  END IF; --End if for AP Invoice
      END IF;
    END IF;
    Fnd_File.Put_Line(Fnd_File.Log,'Receipt Number - lv_error_flag: '||r.receipt_number||'-'||lv_error_flag);
    Fnd_File.Put_Line(Fnd_File.Log,'Receipt MEthod  '||r.receipt_method);
    Fnd_File.Put_Line(Fnd_File.Log,'Invoice Id : '||l_invoice_id);

      IF lv_error_flag='Y' THEN
        UPDATE xx_fin_vps_receipts_stg
          SET record_status='E'
            ,error_message=lv_output
            ,invoice_id=l_invoice_id
            ,last_update_date=sysdate
        WHERE receipt_number=r.receipt_number
          AND receipt_amount=r.receipt_amount
          AND vendor_num=r.vendor_num
          AND receipt_method=r.receipt_method
          AND receipt_date=r.receipt_date
          AND request_id=g_conc_request_id;
      ELSE
        UPDATE xx_fin_vps_receipts_stg
          SET record_status='S'
            ,error_message='Created'
            ,invoice_id=l_invoice_id
            ,last_update_date=sysdate
        WHERE receipt_number=r.receipt_number
          AND receipt_amount=r.receipt_amount
          AND vendor_num=r.vendor_num
          AND receipt_method=r.receipt_method
          AND receipt_date=r.receipt_date
          AND request_id=g_conc_request_id;
      END IF;
    COMMIT;
	END LOOP; -- end loop for main receipts
END;

PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
   )
 IS
 BEGIN
  --Update Request Id
  	Update_Requestid;
  --Process AR Vendor Netting
    Process_Vendor_Netting (p_retcod_out );
  --Print Details
    Print_Receipt_Invoice_Details;
 END;
END XX_FIN_VPS_MANUAL_NETTING_PKG;
/