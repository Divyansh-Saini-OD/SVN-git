create or replace PACKAGE BODY XX_FIN_VPS_NETTING_PKG AS 
-- =========================================================================================================================
--   NAME:       XX_FIN_VPS_NETTING_PKG .
--   PURPOSE:    This package contains procedures and functions for the
--                AP/AR Netting process.
--                E7030 - VPS AP/AR Netting - Systematic 
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        08/01/2017  Sreedhar Mohan      Created this package.
--   1.1        08/03/2017  Uday Jadhav         Modified the package to add AP invoice import and Email Notification
--   1.2        12/19/2017  Theja Rajula        Pass CCID to CONSIGNMENT Vendors.
--   1.3        06/05/2018  Havish Kasina       Changes added as per Defect 44886 (VPS Phase 2) 
--   1.4        09/19/2018  Havish Kasina       Production Defect 61712: AP Invoices are not created. Fixed the issue to  
--                                              pass the invoice amount
--	1.5			30/04/2019	Harika Nukala		Adding oracle instance for this JIRA-NAIT-93555
-- =========================================================================================================================
g_conc_request_id NUMBER :=fnd_global.conc_request_id;
PROCEDURE update_trans( 
					 p_trx_num IN VARCHAR2,
					 p_receipt_num IN VARCHAR2,
					 p_receipt_amt NUMBER, 
					 p_status VARCHAR2,
					 p_err_msg varchar2 DEFAULT NULL
					)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN 
		
		IF p_trx_num is not null THEN
			UPDATE 
				XX_FIN_VPS_SYS_NETTING_STG
			SET
				receipt_number=p_receipt_num,
				receipt_amount=p_receipt_amt,
				status =p_status,
				error_message=p_err_msg
			WHERE
				trx_number=p_trx_num
			AND request_id=g_conc_request_id;
			
		ELSE 
			update 
				xx_fin_vps_sys_netting_stg
			SET 
				status =p_status,
				ap_invoice_number=p_receipt_num,--DECODE(p_status,'I',p_receipt_num,NULL),
				error_message=p_err_msg
			WHERE
				receipt_number=p_receipt_num
			AND request_id=g_conc_request_id;
		END IF;
			
		COMMIT;
	END;
 

   PROCEDURE print_output
    IS
    CURSOR c_success is 
          SELECT  xfvs.receipt_number,xfvs.receipt_amount,request_id,
				(SELECT listagg( '[' || xfvs1.Trx_number || ', ' || xfvs1.amount_due_remaining || ']', ', ') within group ( order by xfvs1.Trx_number ) as  trx_numbers
					FROM xx_fin_vps_sys_netting_stg xfvs1
					WHERE  xfvs1.receipt_number=xfvs.receipt_number
          AND    xfvs1.customer_trx_type_id=xfvs.customer_trx_type_id
          ) ar_invoice_num
					FROM  XX_FIN_VPS_SYS_NETTING_STG  XFVS
					WHERE status='S' 
					AND   email_status is NULL
					AND 	request_id=g_conc_request_id
					GROUP BY xfvs.receipt_number,xfvs.receipt_amount,request_id,customer_trx_type_id
					;        

	CURSOR c_e1 is
				SELECT distinct error_message 
				FROM 	XX_FIN_VPS_SYS_NETTING_STG 
				WHERE status='E' 
				AND   email_status is NULL
				AND 	request_id=g_conc_request_id
				;
				
	CURSOR c_error(p_error_msg IN VARCHAR2) is
				SELECT * 
				FROM 	xx_fin_vps_sys_netting_stg 
				WHERE 	status='E'
				AND   email_status is NULL
				AND 	request_id=g_conc_request_id
				AND 	error_message=p_error_msg
				;
 
             lc_excp_msg_cnt 			      NUMBER :=1;
             lv_invoice_sum             NUMBER;
             lv_row_cnt                 NUMBER;
   BEGIN  
           
		fnd_file.put_line(fnd_file.output,'Daily AP/AR Netting Report Run on '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss'));
		fnd_file.put_line(fnd_file.output,'**************************************************************');
        fnd_file.put_line(fnd_file.output,'Exceptions Occurred in EBS Oracle during AR/AP Netting Process');
        fnd_file.put_line(fnd_file.output,'**************************************************************'); 
        
        FOR e1 in c_e1
              LOOP 
					fnd_file.put_line(fnd_file.output,'Exception '||lc_excp_msg_cnt||': '||e1.error_message);
					fnd_file.put_line(fnd_file.output,'AR INVOICE NUMBER       '||'RECEIPT NUMBER');
					fnd_file.put_line(fnd_file.output,'------------------------------------------'); 
                FOR e in c_error(e1.error_message)
					LOOP 
							fnd_file.put_line(fnd_file.output,rpad(e.trx_number,25,' ')||NVL(e.ap_invoice_number,'N/A'));
					END LOOP;  
							lc_excp_msg_cnt := lc_excp_msg_cnt+1;
              END LOOP;
              
              fnd_file.put_line(fnd_file.output,'**********************************************************************************');
              fnd_file.put_line(fnd_file.output,'Following Receipts and Invoices Created in EBS Successfully at '||TO_CHAR(SYSDATE,'MM/DD/YYYY hh24:mi:ss'));
              fnd_file.put_line(fnd_file.output,'**********************************************************************************');
              fnd_file.put_line(fnd_file.output,'RECEIPT NUMBER           '||'AP INVOICE AMOUNT'||'      AR INVOICE APPLICATIONS AND AMOUNTS');
              fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------------------------------');
			   
        FOR r in c_success
				LOOP 
					fnd_file.put_line(fnd_file.output,rpad(r.receipt_number,25,' ')||Lpad(To_Char(-1*r.Receipt_Amount,'99G999G990D00PR'),17,' ')||'     '||r.ar_invoice_num);
				END LOOP;   
         
   EXCEPTION           
      WHEN OTHERS
      THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Pring Log: '||SQLERRM);  
   END;  

  procedure send_email 
    IS
    CURSOR c_success is
				SELECT  xfvs.receipt_number,xfvs.receipt_amount,request_id,
				(SELECT listagg( '[' || xfvs1.Trx_number || ', ' || xfvs1.amount_due_remaining || ']', ', ') within group ( order by xfvs1.Trx_number ) as  trx_numbers
					FROM 	xx_fin_vps_sys_netting_stg xfvs1
					WHERE  xfvs1.receipt_number=xfvs.receipt_number) ar_invoice_num
					FROM 	XX_FIN_VPS_SYS_NETTING_STG  XFVS
					WHERE status='S' 
					AND   email_status is NULL
					AND 	request_id=g_conc_request_id
					GROUP BY xfvs.receipt_number,xfvs.receipt_amount,request_id
          ; 
          
  CURSOR c_success_sum is
	SELECT sum(a.receipt_amount)
	  FROM (SELECT  xfvs.receipt_number,xfvs.receipt_amount,request_id,
          (SELECT listagg( '[' || xfvs1.Trx_number || ', ' || xfvs1.amount_due_remaining || ']', ', ') within group ( order by xfvs1.Trx_number ) as  trx_numbers
            FROM 	xx_fin_vps_sys_netting_stg xfvs1
            WHERE  xfvs1.receipt_number=xfvs.receipt_number) ar_invoice_num
            FROM 	XX_FIN_VPS_SYS_NETTING_STG  XFVS
            WHERE status='S' 
            AND   email_status is NULL
            AND 	request_id=g_conc_request_id
            GROUP BY xfvs.receipt_number,xfvs.receipt_amount,xfvs.request_id)a;
	
	CURSOR c_e1 is
				SELECT distinct error_message 
				FROM 	XX_FIN_VPS_SYS_NETTING_STG 
				WHERE status='E' 
				AND   email_status is NULL
				AND 	request_id=g_conc_request_id
				;
				
	CURSOR c_error(p_error_msg IN VARCHAR2) is
				SELECT * 
				FROM 	xx_fin_vps_sys_netting_stg 
				WHERE 	status='E'
				AND   email_status is NULL
				AND 	request_id=g_conc_request_id
				AND 	error_message=p_error_msg
				;

             lc_conn                   	UTL_SMTP.connection;
             lc_attach_text            	VARCHAR2(32767);
             lc_success_data 			      VARCHAR2(32767);
             lc_inv_sum                 VARCHAR2(32767);
             lc_exp_data 				        VARCHAR2(32767);
             lc_err_msg         		    VARCHAR2(32767);
             lc_err_nums 				        NUMBER := 0;
             lc_request_id            	NUMBER := fnd_global.conc_request_id;
             lc_mail_from       		    VARCHAR2(100);
             lc_mail_to       			    VARCHAR2(100);
             lc_mail_request_id 		    NUMBER;
             lc_body 					          BLOB :=utl_raw.cast_to_raw('Attached Receipts and Invoices Created in EBS Successfully');
             lc_file_data 				      BLOB;
             lc_src_data 				        BLOB;
             lc_record 					        NUMBER :=1;
             lc_err_msg_cnt 			      NUMBER :=1;
             lc_excp_msg_cnt 			      NUMBER :=1;
             lv_invoice_sum             NUMBER;
             lv_row_cnt                 NUMBER := 0;
			 lv_Instance_name    		VARCHAR2(100); --Added for this JIRA NAIT-93555 to add the instance name to the subject
   BEGIN  
          
        BEGIN
          SELECT target_value1,target_value2 INTO  lc_mail_from,lc_mail_to
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='SYSTEMATIC_NETTING'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';
         
         EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM);  
         END;   
            
              dbms_lob.createtemporary(lc_file_data, TRUE);
			  
              lc_exp_data :=lc_exp_data||'Daily AP/AR Netting Report Run on '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||chr(13)||chr(10);
              lc_exp_data :=lc_exp_data||'**************************************************************'||chr(13)||chr(10);
              lc_exp_data :=lc_exp_data||'Exceptions Occurred in EBS Oracle during AR/AP Netting Process'||chr(13)||chr(10);
              lc_exp_data :=lc_exp_data||'**************************************************************'||chr(13)||chr(10);
               
              lc_record:=1;
        
        FOR e1 in c_e1
              LOOP 
					lc_err_msg :=chr(13)||chr(10)||'Exception '||lc_excp_msg_cnt||': '||e1.error_message||chr(13)||chr(10); 
					lc_err_msg :=lc_err_msg||'AR INVOICE NUMBER       '||'RECEIPT NUMBER'||chr(13)||chr(10);
					lc_err_msg :=lc_err_msg||'------------------------------------------'||chr(13)||chr(10);
					lc_err_msg_cnt:=1;
                FOR e in c_error(e1.error_message)
					LOOP
					if lc_record=1 then
						lc_src_data := utl_raw.cast_to_raw(lc_exp_data||lc_err_msg||rpad(e.trx_number,25,' ')||NVL(e.ap_invoice_number,'N/A')||chr(13)||chr(10)); 
					ELSE
						if lc_err_msg_cnt=1 THEN
							lc_src_data := utl_raw.cast_to_raw(lc_err_msg||rpad(e.trx_number,25,' ')||NVL(e.ap_invoice_number,'N/A')||chr(13)||chr(10)); 
						ELSE
							lc_src_data := utl_raw.cast_to_raw(rpad(e.trx_number,25,' ')||NVL(e.ap_invoice_number,'N/A')||chr(13)||chr(10)); 
						END IF;
					end if;
				
						DBMS_LOB.APPEND(lc_file_data,lc_src_data); 
						lc_record:= lc_record+1; 
						lc_err_msg_cnt:= lc_err_msg_cnt+1;
					END LOOP; 
						lc_excp_msg_cnt := lc_excp_msg_cnt+1;
              END LOOP;
              
              LC_SUCCESS_DATA :=chr(13)||chr(10)||'**********************************************************************************'||chr(13)||chr(10); 
              LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'Following Receipts and Invoices Created in EBS Successfully at '||TO_CHAR(SYSDATE,'MM/DD/YYYY hh24:mi:ss')||CHR(13)||CHR(10); 
              LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'**********************************************************************************'||chr(13)||chr(10)||chr(13)||chr(10); 
              LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'RECEIPT NUMBER           '||'AP INVOICE AMOUNT'||'      AR INVOICE APPLICATIONS AND AMOUNTS'||CHR(13)||CHR(10);
              LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'-----------------------------------------------------------------------------------'||chr(13)||chr(10); 
			  
              lc_record:=1;
          
        FOR r in c_success
				LOOP
          lv_row_cnt := lv_row_cnt + 1;
					if lc_record=1 then
						lc_src_data := utl_raw.cast_to_raw(lc_success_data||rpad(r.receipt_number,25,' ')||Lpad(To_Char(-1*r.Receipt_Amount,'99G999G990D00'),17,' ')||'     '||r.ar_invoice_num||chr(13)||chr(10)); 
						else
						lc_src_data := utl_raw.cast_to_raw(rpad(r.receipt_number,25,' ')||Lpad(To_Char(-1*r.Receipt_Amount,'99G999G990D00'),17,' ')||'     '||r.ar_invoice_num||chr(13)||chr(10)); 
            
					end if;
					dbms_lob.append(lc_file_data,lc_src_data); 
					lc_record:= lc_record+1; 
				END LOOP;  
        IF lv_row_cnt >0 THEN
          lc_inv_sum  :=lc_inv_sum||chr(13)||chr(10);
          lc_inv_sum  :=lc_inv_sum ||rpad('Count : '||lv_row_cnt,25,' ');  
          OPEN  c_success_sum;
          FETCH c_success_sum into lv_invoice_sum;
          CLOSE c_success_sum;
          lc_src_data     := utl_raw.cast_to_raw(lc_inv_sum||Lpad(To_Char(-1*lv_invoice_sum,'99G999G990D00'),17,' ')||chr(13)||chr(10));
          dbms_lob.append(lc_file_data,lc_src_data); 
          lc_record:= lc_record+1;
        END IF;
		Select instance_name 		into lv_Instance_name		from v$instance; --Added for this JIRA NAIT-93555 to add the instance name to the subject
        lc_conn := xx_pa_pb_mail.begin_mail
                               (sender             => lc_mail_from,
                                recipients         => lc_mail_to,
                                cc_recipients      => NULL,
                                subject            => lv_Instance_name ||': '||'AP_AR Daily Netting Status Report '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss'),    --Added for this JIRA NAIT-93555 to add the instance name to the subject   
                                mime_type          => xx_pa_pb_mail.multipart_mime_type
                               );

                    
                   xx_pa_pb_mail.begin_attachment(conn           => lc_conn,
                                                   mime_type  =>'text/plain',
                                                   inline     =>NULL,
                                                   filename   => NULL,
                                                   transfer_enc => NULL); 
                 
                     xx_pa_pb_mail.xx_attch_doc (lc_conn,
                                                 'AP_AR Daily netting Status Report '||to_char(sysdate,'DD_MON_YYYY')||'.txt',
                                                 lc_file_data,
                                                 'text/plain; charset=UTF-8'
                                                ); 

                     xx_pa_pb_mail.end_attachment (conn => lc_conn);
                 
                     xx_pa_pb_mail.end_mail (conn => lc_conn);
         --commit; 
            UPDATE XX_FIN_VPS_SYS_NETTING_STG
              SET email_status='Y'
            WHERE status in ('S','E')
              AND email_status is NULL
              AND request_id=g_conc_request_id 
            ;
            
   EXCEPTION           
      WHEN OTHERS
      THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to send mail '||SQLERRM);  
   END;  

PROCEDURE PROCESS_AP_INVOICE(
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
    o_invoice_id               OUT NUMBER,
    x_err_msg                  OUT VARCHAR2
    )
IS
  v_company           	VARCHAR2(150);
  v_lob                 VARCHAR2(150);
  v_location_type       VARCHAR2(150);
  v_cost_center_type    VARCHAR2(150); 
  v_user_id             NUMBER := NVL (fnd_profile.VALUE ('USER_ID'), 0);
  v_invoice_id          NUMBER;
  v_vendor_site_id      NUMBER;
  v_vendor_id           NUMBER;
  v_rcpt_method_name	VARCHAR2(250); 
  v_org_id po_vendor_sites_all.org_id%TYPE;
  v_count               NUMBER;
  v_terms_id            NUMBER;
  v_payment_method      VARCHAR2(25);
  v_pay_group_lookup    VARCHAR2(25);
  v_full_gl_code        VARCHAR2 (2000);
  v_ccid                NUMBER; 
  lc_error_flag         VARCHAR2 (1) := 'N';
  lc_error_loc          VARCHAR2 (2000);
  lc_loc_err_msg        VARCHAR2 (2000);
  v_cnt                 NUMBER:=0;
  v_inv_cnt             NUMBER;
  v_sup_attr8           VARCHAR2(100); 
  v_consignment_flag    VARCHAR2(10); 
  v_vendor_site_code    po_vendor_sites_all.vendor_site_code%TYPE;


BEGIN
  v_vendor_id        := NULL;
  v_vendor_site_id   := NULL;
  v_org_id           := NULL;
  v_terms_id         := NULL;
  v_payment_method   := NULL;
  v_pay_group_lookup := NULL;
  v_ccid             := NULL;
  x_err_msg          := NULL;
  

 
  SELECT ap_invoices_interface_s.NEXTVAL
    INTO   v_invoice_id
    FROM   DUAL;
  
    BEGIN
        SELECT term_id 
        INTO v_terms_id
        FROM ap_terms 
        WHERE name='00';
    EXCEPTION WHEN OTHERS THEN
         v_terms_id := NULL;
         lc_error_flag:='Y';
         x_err_msg :=    SQLCODE
                            || SQLERRM;
    END;
	  
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
    x_err_msg := x_err_msg||'VENDOR_SITE_CODE-'||v_vendor_site_code||': Error Message: '||SQLERRM;
  END;
	
	BEGIN
        SELECT count(1) 
        INTO v_inv_cnt
        FROM ap_invoices_all 
        WHERE invoice_num=p_invoice_num
        AND	  vendor_id=v_vendor_id
        AND   vendor_site_id=v_vendor_site_id
        ; 
		
		IF v_inv_cnt>=1 THEN
		lc_error_flag:='Y';
		x_err_msg := 'Duplicate AP Invoice found';
		END IF;
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
                       AND segment7='000000'; -- Added by Theja Rajula 12/19/2017
                  IF v_sup_attr8 IN ('TR-CON' , 'TR-OMXCON') THEN
                    SELECT count(1) into v_count
                      FROM  
                          iby_external_payees_all iep,
                          iby_pmt_instr_uses_all ipiu 
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
            x_err_msg := x_err_msg||'v_consignment_flag'||SQLCODE
                          || SQLERRM;
            fnd_file.put_line(fnd_file.log,'Error While Getting Consignment Validation Flag'||SQLERRM);
        END;
   fnd_file.put_line(fnd_file.log,'CCID: '||v_ccid);       
  IF lc_error_flag='N' THEN
  BEGIN
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
        SOURCE,
        GROUP_ID,
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
        v_invoice_id, 
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
    x_err_msg := x_err_msg||'INSERT_HEADER'||SQLCODE
                          || SQLERRM;
    fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SEND_EMAIL_NOTIF',
                         x_err_msg
                    );                      
  END;
  
  --Get the CCID for AP INVOICE LINES
		IF lc_error_flag='N' THEN
			BEGIN
				
				BEGIN
					SELECT target_value1 INTO  v_rcpt_method_name
					FROM xx_fin_translatedefinition xftd
						, xx_fin_translatevalues xftv
					WHERE xftv.translate_id = xftd.translate_id
					AND xftd.translation_name ='OD_VPS_TRANSLATION'
					AND source_value1='SYSTEMATIC_NETTING_RECEIPT_METHOD'
					AND NVL (xftv.enabled_flag, 'N') = 'Y';
					
				EXCEPTION WHEN OTHERS THEN
						fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION:SYSTEMATIC_NETTING_RECEIPT_METHOD not defined'||SQLERRM);  
				END; 
				
				SELECT ara.cash_ccid
				INTO  v_ccid
				FROM  ar_receipt_methods arm,
					  ar_receipt_method_accounts_all ara
				WHERE ara.receipt_method_id=arm.receipt_method_id
				AND   arm.name  =v_rcpt_method_name
				AND   ara.org_id=fnd_global.org_id;
			EXCEPTION
				WHEN OTHERS THEN
					v_ccid := NULL;
          x_err_msg := x_err_msg||    SQLCODE
                          || SQLERRM;
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
				x_err_msg := x_err_msg||SQLCODE||SQLERRM;
				lc_error_flag:='Y';
				fnd_log.STRING (fnd_log.level_statement,
									g_pkg_name || 'PROCESS_AP_INVOICE',
									x_err_msg
									); 
			END;
		END IF;
		   
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Interfaced Successfully: '||v_invoice_id); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
		   fnd_log.STRING (fnd_log.level_statement,
								 g_pkg_name || 'PROCESS_AP_INVOICE',
								 'Invoice Interfaced Successfully: '||p_invoice_num
								); 
  END IF;
 o_invoice_id :=v_invoice_id; 
  
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No records found to process for the Source :'||p_source);
  o_invoice_id :=0;
  x_err_msg := x_err_msg||'INVOICE_INSERT_MAIN'||SQLCODE
                          || SQLERRM; 
 fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'PROCESS_AP_INVOICE',
                         x_err_msg
                        );                         
END PROCESS_AP_INVOICE; 

PROCEDURE submit_ap_invoice_import(p_request_id OUT NUMBER)
IS
  --conc request parameter
    PRAGMA AUTONOMOUS_TRANSACTION; 
    ln_req_id     NUMBER; 
    lc_phase      VARCHAR2(200);
    lc_status     VARCHAR2(200);
    lc_dev_phase  VARCHAR2(200);
    lc_dev_status VARCHAR2(200);
    lc_message    VARCHAR2(200);
    lc_inv_org_id NUMBER;
    lb_wait       BOOLEAN;
    BEGIN  
		BEGIN
			SELECT organization_id into lc_inv_org_id
			  FROM HR_OPERATING_UNITS
			 WHERE name='OU_US'; 
		EXCEPTION
		WHEN OTHERS THEN
			lc_inv_org_id := NULL;
		END;
		
                ln_req_id :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXIIMPT'                                                      --program
                                                         ,
                                               'Payables Open Interface Import'                            --description
                                                                               ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               lc_inv_org_id 
                                                   ,
                                               'US_OD_VENDOR_PROGRAM', 
                                                                 
                                               CHR(0)                                                        --argument3
                                                     ,
                                                  NULL, 
                                               'AP/AR NETTING'||TO_CHAR(SYSDATE,
                                                          'DD-MON-YY')                                       --argument4
                                                                      ,
                                               CHR(0)                                                        --argument5
                                                     ,
                                               CHR(0)                                                        --argument6
                                                     ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               'N'                                                           --argument8
                                                  ,
                                               'N'                                                           --argument9
                                                  );

                IF (ln_req_id = 0)
                THEN
                     Fnd_File.Put_Line(Fnd_File.Log, '*** Error Submitting "Payables Open Interface Import"');
                     fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SUBMIT_AP_INVOICE_IMPORT',
                         'Payables Open Interface Import Failed'
                        );
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);
                FND_FILE.PUT_LINE(FND_FILE.LOG, ' Payables Open Interface Import Successfully Completed Request id:"'||ln_req_id);                                                        
                END IF;  
                p_request_id := ln_req_id;
EXCEPTION WHEN OTHERS THEN
fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SUBMIT_AP_INVOICE_IMPORT',
                         'Payables Open Interface Import:'||SQLERRM
                        );
END;

FUNCTION get_receipt_number(
							p_trx_type 	 IN VARCHAR2,
							p_program_id IN NUMBER,
							p_year_chars IN VARCHAR2,
							p_week_chars IN VARCHAR2,
							p_vendor_num IN VARCHAR2
						   )
      RETURN VARCHAR2            
      IS
      CURSOR c1
		  IS
        SELECT    decode(vals.target_value1,'WW', p_week_chars, 'YY', p_year_chars, 'VVVVVVV', lpad(p_vendor_num,7,'0'), 'PPPPPP', lpad(p_program_id,6,'0'), vals.target_value1) 
               || decode(vals.target_value2,'WW', p_week_chars, 'YY', p_year_chars, 'VVVVVVV', lpad(p_vendor_num,7,'0'), 'PPPPPP', lpad(p_program_id,6,'0'), vals.target_value2)
               || decode(vals.target_value3,'WW', p_week_chars, 'YY', p_year_chars, 'VVVVVVV', lpad(p_vendor_num,7,'0'), 'PPPPPP', lpad(p_program_id,6,'0'), vals.target_value3)
               || decode(vals.target_value4,'WW', p_week_chars, 'YY', p_year_chars, 'VVVVVVV', lpad(p_vendor_num,7,'0'), 'PPPPPP', lpad(p_program_id,6,'0'), vals.target_value4)
               || decode(vals.target_value5,'WW', p_week_chars, 'YY', p_year_chars, 'VVVVVVV', lpad(p_vendor_num,7,'0'), 'PPPPPP', lpad(p_program_id,6,'0'), vals.target_value5)
        FROM   xx_fin_translatedefinition trans
              ,xx_fin_translatevalues     vals
        WHERE  1=1
        AND    trans.translation_name = 'OD_VPS_NETTING_TRX_TYPES'
        AND    trans.translate_id = vals.translate_id
        AND    vals.source_value2 = p_trx_type
        AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,SYSDATE + 1);
   
        l_tmp_receipt_number varchar2(30);
		
    BEGIN  
          OPEN c1;  
          FETCH c1 INTO l_tmp_receipt_number;
          CLOSE c1; 
         
			RETURN l_tmp_receipt_number;
        
			FND_FILE.put_line(fnd_file.log,'vps_trx_type: ' || p_trx_type || ', Receipt Number: ' || l_tmp_receipt_number);

		EXCEPTION
		  when others then
			Return NULL;
			FND_FILE.put_line(fnd_file.log,'Exception: ' || SQLERRM);   
	END;

  PROCEDURE vendor_netting_proc (
								 p_errbuf_out              	OUT      VARCHAR2
								 ,p_retcod_out              OUT      VARCHAR2
								 ,p_account_id              IN       NUMBER
								 ,p_account_number          IN       VARCHAR2
								 ,p_account_name            IN       VARCHAR2
								 ,p_vendor_num              IN       VARCHAR2
								 ,p_run_date                IN       VARCHAR2
								)
  IS 
  
   
   CURSOR c_open_invoices (p_customer_id in number,p_cur_run_date IN date)
    IS  
      SELECT  rct.customer_trx_id, 
        rct.cust_trx_type_id,
			  rct.trx_number,
        aps.customer_id,
			  aps.terms_sequence_number,
			  aps.payment_schedule_id,
        rct.attribute14,
			  aps.amount_due_remaining
        FROM  ra_batch_sources   	rbs
             ,ra_customer_trx       rct
             ,ar_payment_schedules  aps
             ,ra_cust_trx_types     rctt
       WHERE 1=1       
        AND rbs.name='US_VPS_OA'
        AND rbs.batch_source_id         = rct.batch_source_id
        AND rct.cust_trx_type_id        = rctt.cust_trx_type_id  
        AND rct.attribute_category      = 'US_VPS'
        AND rct.attribute14 is not null
        AND rct.customer_trx_id         = aps.customer_trx_id
        AND trim(rct.attribute8)        = 'Vendor Approved'
        AND trim(rct.attribute9)        = 'DBM'
        and aps.customer_id             = p_customer_id
        and aps.invoice_currency_code   = 'USD' 
        and aps.status                  = 'OP' 
        and aps.amount_due_remaining    > 0
        and aps.due_date                <= p_cur_run_date
    UNION ALL
     SELECT  rct.customer_trx_id,
        rct.cust_trx_type_id,
			  rct.trx_number,
        aps.customer_id,
			  aps.terms_sequence_number,
			  aps.payment_schedule_id,
			rct.attribute14,
			  aps.amount_due_remaining
        FROM  ra_batch_sources   rbs
             ,ra_customer_trx       rct
             ,ar_payment_schedules  aps
             ,ra_cust_trx_types     rctt
       WHERE 1=1       
        AND rbs.name in ('US_VPS_CORE','US_VPS_OTHER')
        AND rbs.batch_source_id         = rct.batch_source_id
        AND rct.cust_trx_type_id        = rctt.cust_trx_type_id  
        AND rct.attribute_category      = 'US_VPS'
        AND rct.customer_trx_id         = aps.customer_trx_id 
        AND rct.attribute14 is not null
        AND trim(rct.attribute9)        = 'DBM'
        and aps.customer_id             = p_customer_id
        and aps.invoice_currency_code   = 'USD' 
        and aps.status                  = 'OP' 
        and aps.amount_due_remaining    > 0
        and aps.due_date                <= p_cur_run_date
        ; 
		
   CURSOR c_vendor_programs (p_customer_id in number)
   IS
	SELECT DISTINCT 
              xfvs.vps_program_id,
              xfvs.customer_trx_type_id
       FROM   XX_FIN_VPS_SYS_NETTING_STG xfvs
       WHERE  xfvs.status='N'
		AND   xfvs.request_id=g_conc_request_id;
		 
   
   CURSOR c_vps_trx_types(p_trx_type_id in NUMBER) 
   IS
	 SELECT rtt.cust_trx_type_id, rtt.name
	 FROM   ra_cust_trx_types rtt
	 WHERE  rtt.name like '%VPS%'
	 AND 	rtt.cust_trx_type_id=p_trx_type_id
	 AND 	type in('INV','DM');
  
  -- Commented as per Version 1.3  
  /*   
   CURSOR c_vps_inv_amount  (p_customer_id 	IN NUMBER, 
							 p_trx_type_id 	IN VARCHAR2, 
							 p_pgm_id 	   	IN NUMBER 
							)
    IS 
    SELECT sum(amount_due_remaining)
     FROM XX_FIN_VPS_SYS_NETTING_STG xfvs
       WHERE status='N' 
        AND xfvs.vps_program_id          = TO_CHAR(p_pgm_id)
        AND xfvs.customer_trx_type_id    = p_trx_type_id 
        AND xfvs.cust_account_id         = p_customer_id
		AND xfvs.request_id=g_conc_request_id;
  */
   
   /* Added as per Version 1.3 */
   CURSOR C_VPS_YY_WW_NUM ( p_customer_id 	IN NUMBER, 
						    p_trx_type_id 	IN VARCHAR2, 
						    p_pgm_id 		IN NUMBER
					      )
   IS
   SELECT 	sum(xfvs.amount_due_remaining) amount_due_remaining,
            max(substrb(xfvs.trx_number,instr(vals.target_Value3||vals.target_Value4||vals.target_Value5,'Y'),2)) YEAR_CHARS ,
            max(substrb(xfvs.trx_number,instr(vals.target_Value3||vals.target_Value4||vals.target_Value5,'W'),2)) WEEK_CHARS          
			FROM  xx_fin_translatedefinition trans
				 ,xx_fin_translatevalues vals
				 ,ra_cust_trx_types rtt
				 ,XX_FIN_VPS_SYS_NETTING_STG xfvs
			WHERE  1=1
			  AND trans.translation_name = 'OD_VPS_NETTING_TRX_TYPES'
			  AND trans.translate_id = vals.translate_id
			  AND vals.source_value2 = rtt.name
			  AND rtt.cust_trx_type_id=xfvs.customer_trx_type_id 
			  AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,SYSDATE + 1)
			  AND xfvs.status='N' 
			  AND xfvs.vps_program_id          = TO_CHAR(p_pgm_id)
			  AND xfvs.customer_trx_type_id    = p_trx_type_id 
			  AND xfvs.cust_account_id         = p_customer_id
			  AND xfvs.request_id=g_conc_request_id
    GROUP BY substrb(xfvs.trx_number,instr(vals.target_Value3||vals.target_Value4||vals.target_Value5,'Y'),2); 
			  
   TYPE vps_typ IS TABLE OF C_VPS_YY_WW_NUM%ROWTYPE
   INDEX BY PLS_INTEGER;

   /* Added as per Version 1.3 */
   CURSOR C_VPS_CORE_YY_WW_NUM ( p_customer_id 	IN NUMBER, 
						         p_trx_type_id 	IN VARCHAR2, 
						         p_pgm_id 		IN NUMBER
					           )
   IS
            SELECT 	sum(xfvs.amount_due_remaining) amount_due_remaining,
			        max(substrb(xfvs.trx_number,instr(vals.target_Value2||vals.target_Value3||vals.target_Value4,'Y'),2)) YEAR_CHARS,
                    max(substrb(xfvs.trx_number,instr(vals.target_Value2||vals.target_Value3||vals.target_Value4,'W'),2)) WEEK_CHARS          
			  FROM  xx_fin_translatedefinition trans
				   ,xx_fin_translatevalues vals
				   ,ra_cust_trx_types rtt
				   ,XX_FIN_VPS_SYS_NETTING_STG xfvs
			 WHERE  1=1
			   AND trans.translation_name = 'OD_VPS_NETTING_TRX_TYPES'
			   AND trans.translate_id = vals.translate_id
			   AND vals.source_value2 = rtt.name
			   AND rtt.cust_trx_type_id=xfvs.customer_trx_type_id 
			   AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,SYSDATE + 1)
			   AND xfvs.status='N' 
			   AND xfvs.vps_program_id          = TO_CHAR(p_pgm_id)
			   AND xfvs.customer_trx_type_id    = p_trx_type_id 
			   AND xfvs.cust_account_id         = p_customer_id
			   AND xfvs.request_id=g_conc_request_id
			 GROUP BY substrb(xfvs.trx_number,instr(vals.target_Value2||vals.target_Value3||vals.target_Value4,'Y'),2); 
			   
   /* Added as per Version 1.3 */
   CURSOR C_VPS_OTHER_YY_WW_NUM ( p_customer_id 	IN NUMBER, 
						          p_trx_type_id 	IN VARCHAR2, 
						          p_pgm_id 		    IN NUMBER
					            )
       IS
            SELECT 	sum(xfvs.amount_due_remaining) amount_due_remaining,
			        max(substrb(xfvs.trx_number,instr(vals.target_Value1||vals.target_Value3||vals.target_Value4,'Y'),2)) YEAR_CHARS,
                    max(substrb(xfvs.trx_number,instr(vals.target_Value1||vals.target_Value3||vals.target_Value4,'W'),2)) WEEK_CHARS          
			  FROM  xx_fin_translatedefinition trans
				   ,xx_fin_translatevalues vals
				   ,ra_cust_trx_types rtt
				   ,XX_FIN_VPS_SYS_NETTING_STG xfvs
			 WHERE  1=1
			   AND trans.translation_name = 'OD_VPS_NETTING_TRX_TYPES'
			   AND trans.translate_id = vals.translate_id
			   AND vals.source_value2 = rtt.name
			   AND rtt.cust_trx_type_id=xfvs.customer_trx_type_id 
			   AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,SYSDATE + 1)
			   AND xfvs.status='N' 
			   AND xfvs.vps_program_id          = TO_CHAR(p_pgm_id)
			   AND xfvs.customer_trx_type_id    = p_trx_type_id 
			   AND xfvs.cust_account_id         = p_customer_id
			   AND xfvs.request_id=g_conc_request_id
			 GROUP BY substrb(xfvs.trx_number,instr(vals.target_Value1||vals.target_Value3||vals.target_Value4,'Y'),2); 
        
    CURSOR c_vps_invoices ( p_customer_id 	IN NUMBER, 
							p_trx_type_id 	IN VARCHAR2, 
							p_pgm_id 		IN NUMBER,
                            p_year          IN VARCHAR2							
						  )
    IS 
	  -- Commented as per Version 1.3 
      /*	
      SELECT  xfvs.customer_trx_id, 
			  xfvs.trx_number,
			  xfvs.terms_sequence_number,
			  xfvs.payment_schedule_id,
			  xfvs.amount_due_remaining
       FROM XX_FIN_VPS_SYS_NETTING_STG xfvs
       WHERE status='N' 
        AND xfvs.vps_program_id 		= TO_CHAR(p_pgm_id)
        AND xfvs.customer_trx_type_id   = p_trx_type_id 
        AND xfvs.cust_account_id        = p_customer_id
		AND xfvs.request_id=g_conc_request_id; 
	   */
	  
	  -- Added as per Version 1.3 
	  SELECT  xfvs.customer_trx_id, 
			  xfvs.trx_number,
			  xfvs.terms_sequence_number,
			  xfvs.payment_schedule_id,
			  xfvs.amount_due_remaining
		FROM  xx_fin_translatedefinition trans
			 ,xx_fin_translatevalues vals
			 ,ra_cust_trx_types_all rtt
			 ,xx_fin_vps_sys_netting_stg xfvs
	   WHERE  1=1
		 AND trans.translation_name = 'OD_VPS_NETTING_TRX_TYPES'
		 AND trans.translate_id = vals.translate_id
		 AND vals.source_value2 = rtt.name
		 AND rtt.cust_trx_type_id=xfvs.customer_trx_type_id 
		 AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,SYSDATE + 1)
		 AND xfvs.status='N' 
		 AND xfvs.vps_program_id          = TO_CHAR(p_pgm_id)
		 AND xfvs.customer_trx_type_id    = p_trx_type_id 
		 AND xfvs.cust_account_id         = p_customer_id
		 AND xfvs.request_id = g_conc_request_id
         AND (CASE
              WHEN rtt.name like '%VPS%CORE%' THEN substrb(xfvs.trx_number,instr(vals.target_Value2||vals.target_Value3||vals.target_Value4,'Y'),2)
              WHEN rtt.name in (
                                'US_VPS_OA',
                                'US_VPS_DM_OA',
                                'US_VPS_CCS',
                                'US_VPS_DM_CCS',
                                'US_VPS_ADVEXP',
                                'US_VPS_DM_ADVEXP',
                                'US_VPS_VOPEX',
                                'US_VPS_DM_VOPEX'
                                )
                THEN substrb(xfvs.trx_number,instr(vals.target_Value3||vals.target_Value4||vals.target_Value5,'Y'),2)
             ELSE substrb(xfvs.trx_number,instr(vals.target_Value1||vals.target_Value3||vals.target_Value4,'Y'),2)
             END) = p_year ;
        
     ln_attr_group_id number;
     l_user_id number;
     l_responsibility_id number;
     l_responsibility_appl_id number;
     ln_org_id number;
     l_cash_ccid NUMBER;
    --local Variables
	l_vps_typ_tab 	            vps_typ; 
    g_loc                       NUMBER :=0;
    g_msg                       VARCHAR2(500);
    l_error_description         VARCHAR2 (2000) := NULL;
    g_sysdate                   DATE  := SYSDATE;
    l_ar_receipt_succ_count     NUMBER:= 0;
    l_ar_receipt_err_count      NUMBER:= 0;
    l_ar_receipt_tot_count      NUMBER:= 0;
    l_msg_index_num             NUMBER:= 1;
    l_msg_count                 NUMBER;
    l_data_txt                  VARCHAR2(1000);
    l_msg_data                  VARCHAR2(1000);
    l_apl_return_status         VARCHAR2 (1);
    l_apl_msg_count             NUMBER;
    l_apl_msg_data              VARCHAR2 (240);
    l_org_id                    NUMBER := fnd_global.org_id;
    l_gl_date_count             NUMBER;
    l_functional_currency fnd_currencies.currency_code%TYPE;
    l_conv_type gl_daily_conversion_types.conversion_type%TYPE;
    l_conv_rate gl_daily_rates.conversion_rate%TYPE;
    l_cust_account_id hz_cust_accounts.cust_account_id%TYPE;
    l_receipt_id ar_cash_receipts_all.cash_receipt_id%TYPE;
    l_return_status             VARCHAR2(10);
    l_currency_code             fnd_currencies.currency_code%TYPE;
    l_cust_bank_acct_id         NUMBER;
    l_receipt_number            ar_cash_receipts_all.receipt_number%TYPE ; 
    l_rcpt_method_name          VARCHAR2(250);
    l_customer_trx_id           NUMBER ;
    ld_run_date                 DATE;
    ln_account_id               HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
    l_account_name              HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE;
    l_account_number            HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
    l_receipt_amount            NUMBER(15,2); 
    l_WEEK_CHARS                VARCHAR2(2);
    l_YEAR_CHARS                VARCHAR2(2);
    l_COUNTER_CHARS             VARCHAR2(2);
    
    l_success_text 				VARCHAR2(32000);
    l_err_text 					VARCHAR2(32000);
    l_status 					VARCHAR2(1);
    
    l_counter 					NUMBER;
    l_counter_char 				VARCHAR2(2);
    l_receipt_count 			NUMBER := 0;
    
    l_invoice_id               NUMBER;
    l_err_msg                  VARCHAR2(2000);
    
    x_return_status           VARCHAR2(1);
    x_count                   NUMBER;
    x_msg_count               NUMBER;
    x_msg_data                varchar2(2000);
       
   BEGIN
     /* Commented  as per Version 1.3
      SELECT TO_CHAR(SYSDATE, 'YY') 
      INTO   l_YEAR_CHARS
      FROM dual;
	 */
      
     ld_run_date := fnd_conc_date.string_to_date(p_run_date); 
	
	BEGIN
          SELECT target_value1 INTO  l_rcpt_method_name
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='SYSTEMATIC_NETTING_RECEIPT_METHOD'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';
         
         EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION:SYSTEMATIC_NETTING_RECEIPT_METHOD not defined'||SQLERRM);  
    END; 
	
	FOR r_open_inv in c_open_invoices(p_account_id,ld_run_date)
	LOOP
	INSERT into XX_FIN_VPS_SYS_NETTING_STG (netting_interface_id,
											customer_trx_id,
											customer_trx_type_id,
											trx_number,
											amount_due_remaining,
											payment_schedule_id,
											terms_sequence_number,
											vps_program_id,
											cust_account_id,
											program_id,
											creation_date,
											created_by,
											last_update_date,
											last_updated_by,
											request_id,
											status
											)
									 VALUES
											(
											 XX_FIN_VPS_SYS_NETTING_STG_S.NEXTVAL,
											 r_open_inv.customer_trx_id,
											 r_open_inv.cust_trx_type_id,
											 r_open_inv.trx_number,
											 r_open_inv.amount_due_remaining,
											 r_open_inv.payment_schedule_id,
											 r_open_inv.terms_sequence_number,
											 r_open_inv.attribute14,
											 r_open_inv.customer_id,
											 fnd_global.conc_program_id,
											 sysdate,
											 fnd_global.user_id,
											 sysdate,
											 fnd_global.user_id, 
											 g_conc_request_id,
											 'N'); 
	 
	END LOOP;
	COMMIT; 
	
    FOR k_record IN c_vendor_programs (p_account_id) 
     LOOP
       l_counter := 0;   
       FOR j_record IN c_vps_trx_types(k_record.CUSTOMER_TRX_TYPE_ID)   
		LOOP
		   l_counter := l_counter + 1;
		   
			 SELECT LPAD('' || l_counter || '',2,'0') counter 
			   INTO l_counter_char
			   FROM dual ;
		   
		   l_WEEK_CHARS := NULL;
		   l_YEAR_CHARS := NULL; -- Added as per Version 1.3
		   l_receipt_amount := NULL;
		   l_vps_typ_tab.DELETE;
		   
		   -- Commented as per Version 1.3 
		   /*
		   OPEN c_vps_inv_amount(p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id);
		   FETCH c_vps_inv_amount into l_receipt_amount;
		   CLOSE c_vps_inv_amount;
		   */
		   
		   /* Added as per Version 1.3 */
		   IF j_record.name LIKE '%VPS%CORE%'
		   THEN
		       OPEN C_VPS_CORE_YY_WW_NUM(p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id);
			   FETCH C_VPS_CORE_YY_WW_NUM BULK COLLECT INTO l_vps_typ_tab LIMIT 10;
		       CLOSE C_VPS_CORE_YY_WW_NUM;
		   ELSIF j_record.name IN (
                                   'US_VPS_OA',
                                   'US_VPS_DM_OA',
                                   'US_VPS_CCS',
                                   'US_VPS_DM_CCS',
                                   'US_VPS_ADVEXP',
                                   'US_VPS_DM_ADVEXP',
                                   'US_VPS_VOPEX',
                                   'US_VPS_DM_VOPEX'
                                  )
		   THEN
		       OPEN C_VPS_YY_WW_NUM(p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id);
			   FETCH C_VPS_YY_WW_NUM BULK COLLECT INTO l_vps_typ_tab LIMIT 10;
		       CLOSE C_VPS_YY_WW_NUM;
		   ELSE
		       OPEN C_VPS_OTHER_YY_WW_NUM(p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id);
			   FETCH C_VPS_OTHER_YY_WW_NUM BULK COLLECT INTO l_vps_typ_tab LIMIT 10;
		       CLOSE C_VPS_OTHER_YY_WW_NUM;
		   END IF;
		   
		   FOR indx IN l_vps_typ_tab.FIRST..l_vps_typ_tab.LAST  -- Added as per Version 1.3 
           LOOP 
		   BEGIN
       
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
			   l_receipt_number      := NULL;
			 --  l_YEAR_CHARS          := NULL;
			   l_COUNTER_CHARS       := NULL;
			   
			    l_receipt_amount :=  l_vps_typ_tab(indx).amount_due_remaining; -- Added by Havish K as per Version 1.4
			   
				l_receipt_number :=get_receipt_number(
													  j_record.name,
													  k_record.vps_program_id,
													  l_vps_typ_tab(indx).YEAR_CHARS,
													  l_vps_typ_tab(indx).WEEK_CHARS,
													  p_vendor_num
													  ); 
						  
			   -- Call Api to create receipt
			   AR_RECEIPT_API_PUB.CREATE_CASH( p_api_version                => 1.0,
											   p_init_msg_list              => fnd_api.g_true, 
											   p_commit                     => fnd_api.g_false, 
											   p_validation_level           => FND_API.G_VALID_LEVEL_FULL, 
											   p_currency_code              => l_currency_code, 
											   p_exchange_rate_type         => NULL,
											   p_exchange_rate              => NULL,
											   p_exchange_rate_date         => NULL,
											   p_amount                     => l_vps_typ_tab(indx).amount_due_remaining,      
											   p_receipt_number             => l_receipt_number,
											   p_receipt_date               => SYSDATE,               
											   p_maturity_date              => NULL,
											   p_customer_name              => NULL,--p_account_name,     
											   p_customer_number            => p_account_number, 
											   p_comments                   => NULL ,                 
											   p_location                   => NULL ,                 
											   p_customer_bank_account_num  => NULL,         
											   p_customer_bank_account_name => NULL,         
											   p_receipt_method_name        => l_rcpt_method_name,
											   p_org_id                     => l_org_id,
											   p_cr_id                      => l_receipt_id,
											   x_return_status              => l_return_status, 
											   x_msg_count                  => l_msg_count, 
											   x_msg_data                   => l_msg_data 
											   );
				IF l_return_status = 'S' THEN
				   FND_FILE.PUT_LINE(FND_FILE.log,'Receipt Created Successfully:'||L_RECEIPT_ID); 
				   fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'VENDOR_NETTING_PROC',
										 'Receipt Created Successfully:'||l_receipt_number
										); 
				   l_receipt_count:=l_receipt_count+1;
				ELSE
				   fnd_file.put_line(fnd_file.log,'Message count ' || l_msg_count);
					IF l_msg_count = 1 THEN 
					   l_msg_data := 'Error while creating the receipt-'||l_msg_data;
					   fnd_file.put_line(fnd_file.log,'Error while creating receipt: '||l_receipt_number||'-'||l_msg_data); 
					   fnd_log.STRING (fnd_log.level_statement,
					   		g_pkg_name || 'VENDOR_NETTING_PROC',
					   		l_msg_data
					   		); 
					ELSE 
						FOR r in 1.. l_msg_count
						LOOP 
							l_msg_data := l_msg_data||','||fnd_msg_pub.get(fnd_msg_pub.g_next,fnd_api.g_false);  
						END LOOP; 
					END IF; 
				END IF;   

		 IF l_return_status = 'S' THEN           
		   --Apply the invoice amount in AR
			FOR i_record in c_vps_invoices( p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id,l_vps_typ_tab(indx).YEAR_CHARS)
				 LOOP
					begin
            AR_RECEIPT_API_PUB.APPLY
							(p_api_version                     => 1.0,
							p_init_msg_list                    => fnd_api.g_true,
							p_commit                           => fnd_api.g_false,
							p_validation_level                 => fnd_api.g_valid_level_full,
							x_return_status                    => l_return_status,
							x_msg_count                        => l_msg_count,
							x_msg_data                         => l_msg_data,
							p_cash_receipt_id                  => l_receipt_id,
							p_customer_trx_id                  => i_record.customer_trx_id,
							p_installment                      => i_record.terms_sequence_number,
							p_applied_payment_schedule_id      => i_record.payment_schedule_id,
							p_amount_applied                   => i_record.amount_due_remaining,
							p_discount                         => NULL,
							p_apply_date                       => sysdate
							);
						  
						IF l_return_status = 'S' THEN
								 FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Applied Successfully: '||i_record.customer_trx_id); 
								 fnd_log.STRING (fnd_log.level_statement,
													   g_pkg_name || 'VENDOR_NETTING_PROC',
													   'Invoice Applied Successfully: '||i_record.customer_trx_id
													  );
								
							update_trans(i_record.trx_number,l_receipt_number,l_receipt_amount,l_return_status);                        
						ELSE
							
						  ROLLBACK;
							 FND_FILE.PUT_LINE(FND_FILE.LOG,'Message count ' || l_msg_count);
							 IF l_msg_count = 1 THEN
								Fnd_File.Put_Line(Fnd_File.Log,'l_msg_data '||L_Msg_Data); 
								fnd_log.STRING (fnd_log.level_statement,
												   g_pkg_name || 'VENDOR_NETTING_PROC',
												   l_msg_data
												  );
								update_trans(i_record.trx_number,l_receipt_number,l_receipt_amount,l_return_status,l_msg_data);
							 ELSIF l_msg_count > 1 THEN
								LOOP
									l_msg_count := l_msg_count+1;
									L_Msg_Data := Fnd_Msg_Pub.Get(Fnd_Msg_Pub.G_Next,Fnd_Api.G_False); 
									IF l_msg_data IS NULL THEN
										EXIT;
									End If;
									update_trans(i_record.trx_number,l_receipt_number,l_receipt_amount,l_return_status,l_msg_data);									
								END LOOP;
							END IF; 
						END IF;                   
						
						EXCEPTION WHEN OTHERS THEN
							   Fnd_File.Put_Line(Fnd_File.Log,'Unexpected Error in AR_RECEIPT_API_PUB.APPLY: '||Sqlerrm); 
							   l_err_text :='Unexpected Error in AR_RECEIPT_API_PUB.APPLY: '||Sqlerrm; 
							   fnd_log.STRING (fnd_log.level_statement,
													   g_pkg_name || 'VENDOR_NETTING_PROC',
													   l_err_text
													  );
								update_trans(i_record.trx_number,l_receipt_number,l_receipt_amount,'E',l_err_text);
							   ROLLBACK;
					END;   
				 END LOOP;

				BEGIN 
							  PROCESS_AP_INVOICE(
												p_vendor_num =>p_vendor_num  ,
												p_vendor_site_code => NULL ,
												p_source =>'US_OD_VENDOR_PROGRAM', --'OD_US_VPS_NETTING' ,
												p_group_id  => NULL,
												p_invoice_id => NULL ,
												p_invoice_num => l_receipt_number ,
												p_invoice_type_lookup_code =>'CREDIT',
												p_invoice_date => Sysdate,
												p_invoice_amount =>(-1*l_receipt_amount),
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
												o_invoice_id =>  l_invoice_id,
												x_err_msg => l_err_msg
												);  


			IF l_err_msg is Not null OR l_invoice_id =0 THEN 
				update_trans(p_trx_num 	   => NULL,
							 p_receipt_num => l_receipt_number, 
							 p_receipt_amt => NULL,
							 p_status => 'E',
							 p_err_msg => 'Netting did not process this invoice due to AP invoice interface failure - '||l_err_msg); 
							  
				fnd_log.STRING (fnd_log.level_statement,
										 g_pkg_name || 'VENDOR_NETTING_PROC',
										 l_err_msg
										);
				ROLLBACK;
            ELSE
                	
				update_trans(p_trx_num 	   => NULL,
							 p_receipt_num => l_receipt_number,
							 p_receipt_amt => NULL,
							 p_status => 'I',
							 p_err_msg => 'Record Interfaced Successfully'); 
										  
                COMMIT;   
            END IF;  
				
				EXCEPTION
					When Others Then
					
					Fnd_File.Put_Line(Fnd_File.Log,'Unexpected Error in XX_FIN_VPS_AP_IMP_PKG.PROCESS_AP_INVOICE: '||Sqlerrm);
					l_err_text :='Unexpected Error in XX_FIN_VPS_AP_IMP_PKG.PROCESS_AP_INVOICE: '||Sqlerrm;
					  
					update_trans(p_trx_num 	   => NULL,
								 p_receipt_num => l_receipt_number,
								 p_receipt_amt => NULL,
								 p_status => 'E',
								 p_err_msg => l_err_text); 
											 
					  ROLLBACK; 
					  fnd_log.STRING (fnd_log.level_statement,
									  g_pkg_name || 'VENDOR_NETTING_PROC',
									  l_err_text
								     ); 
				END; 
		ELSE 
                        FOR e_record in c_vps_invoices( p_account_id, j_record.cust_trx_type_id, k_record.vps_program_id,l_vps_typ_tab(indx).YEAR_CHARS)
						LOOP
						update_trans(p_trx_num 	   => e_record.trx_number,
									p_receipt_num => l_receipt_number,
									p_receipt_amt => NULL,
									p_status => 'E',
									p_err_msg => l_msg_data); 
						END LOOP;
		
		END IF;
		END;
		END LOOP; -- l_vps_typ_tab
	   END LOOP;       
	END LOOP;     
 
  EXCEPTION
       WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in VENDOR_NETTING_PROC: '||DBMS_UTILITY.format_error_backtrace||SQLERRM);
         l_err_text :='Unexpected Error in VENDOR_NETTING_PROC: '||DBMS_UTILITY.format_error_backtrace||SQLERRM;
		 
		 update_trans(p_trx_num 	   => NULL,
					  p_receipt_num => l_receipt_number,
					  p_receipt_amt => NULL,
					  p_status => 'E',
					  p_err_msg => l_err_text); 
								  
         fnd_log.STRING (fnd_log.level_statement,
                           g_pkg_name || 'VENDOR_NETTING_PROC',
                           SQLERRM
                          );  
  END VENDOR_NETTING_PROC;


  PROCEDURE PROCESS_VENDOR_NETTING (
									p_errbuf_out              OUT      VARCHAR2
									,p_retcod_out              OUT      VARCHAR2
									,p_vendor_number           IN       VARCHAR2
									,p_run_date                IN       VARCHAR2
									)
  IS 
    ln_account_id               HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
    l_account_name              HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE;
    l_account_number            HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
    
  BEGIN    
		BEGIN
			 SELECT cust_account_id, account_name, account_number
			 INTO   ln_account_id, l_account_name, l_account_number
			 FROM   hz_cust_accounts
			 WHERE  1=1
			 AND    orig_system_reference=TRIM(p_vendor_number) || '-VPS';
         
		EXCEPTION
           WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in getting CUST_ACCOUNT_ID in XX_FIN_VPS_NETTING_PKG.main: '||SQLERRM);
             fnd_log.STRING (fnd_log.level_statement,
                           g_pkg_name || 'PROCESS_VENDOR_NETTING',
                           SQLERRM
                          ); 
            -- RAISE;
		END; 

     BEGIN
         VENDOR_NETTING_PROC (
							  p_errbuf_out       => p_errbuf_out
							 ,p_retcod_out       => p_retcod_out
							 ,p_account_id       => ln_account_id    
							 ,p_account_number   => l_account_number
							 ,p_account_name     => l_account_name
							 ,p_vendor_num       => p_vendor_number
							 ,p_run_date         => p_run_date         
							);
        EXCEPTION
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in calling PROCESS_VENDOR_NETTING in XX_FIN_VPS_NETTING_PKG.PROCESS_VENDOR_NETTING with Vendor Number: '||SQLERRM);
           fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'VENDOR_NETTING_PROC',
                         SQLERRM
                        ); 
     END; 
     
  EXCEPTION     
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in getting CUST_ACCOUNT_ID in XX_FIN_VPS_NETTING_PKG.PROCESS_VENDOR_NETTING with Vendor Number: '||SQLERRM);
      fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'PROCESS_VENDOR_NETTING',
                         SQLERRM
                        ); 
  END PROCESS_VENDOR_NETTING;
  
  PROCEDURE main (
				  p_errbuf_out              OUT      VARCHAR2
				  ,p_retcod_out              OUT      VARCHAR2
				  ,p_vendor_number           IN       VARCHAR2
				  ,p_run_date                IN       VARCHAR2
                 )
   IS
   
       ln_attr_group_id 			NUMBER;
       l_user_id 					NUMBER;
       l_responsibility_id 			NUMBER;
       l_responsibility_appl_id 	NUMBER;
       ln_org_id 					NUMBER;
       ln_account_id                HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
       l_account_name              	HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE;
       l_account_number            	HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
     
     
       l_errbuf_out 				VARCHAR2(2000);
       l_retcod_out 				VARCHAR2(1);
       l_record_count 				NUMBER := 0;
       l_interface_count			NUMBER :=0;
       l_request_id 				NUMBER; 
       ld_run_date                 	DATE;
    
   CURSOR c_vps_custs (p_attr_group_id NUMBER)
   IS
     SELECT acct.cust_account_id, 
			acct.account_name, 
			acct.account_number,  
            SUBSTR(acct.orig_system_reference,1,instr(acct.orig_system_reference,'-',1)-1) as vendor_num
     FROM   xx_cdh_cust_acct_ext_b extb
           ,hz_cust_accounts       acct
     WHERE  1=1
     AND    extb.cust_account_id = acct.cust_account_id
     AND    extb.attr_group_id = p_attr_group_id
     AND    nvl(extb.c_ext_attr13,'N') in('N','No')  -- AR/AP netting Hold value
     AND    acct.orig_system_reference=NVL2(p_vendor_number,TRIM(p_vendor_number) || '-VPS',orig_system_reference); 
   
   BEGIN  
     
     BEGIN
          SELECT organization_id 
            INTO ln_org_id
            FROM hr_operating_units
           WHERE name='OU_US_VPS';
      EXCEPTION WHEN OTHERS THEN
        ln_org_id := NULL;
      END;
      
     mo_global.set_policy_context('S',ln_org_id);
     
     IF fnd_global.user_id IS NULL THEN
        BEGIN
            SELECT user_id,
                   responsibility_id,
                   responsibility_application_id
            INTO   l_user_id,
                   l_responsibility_id,
                   l_responsibility_appl_id
            FROM   fnd_user_resp_groups
            WHERE  user_id=(SELECT user_id
                             FROM  fnd_user
                            WHERE  user_name='ODCDH')
              AND   responsibility_id=(SELECT responsibility_id
                                         FROM FND_RESPONSIBILITY
                                        WHERE responsibility_key = 'OD_US_VPS_CDH_ADMINSTRATOR');
    
            FND_GLOBAL.apps_initialize(
                                 l_user_id,
                                 l_responsibility_id,
                                 l_responsibility_appl_id
                               );
           EXCEPTION
            WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in initializing : ' || SQLERRM); 
        END; ---END apps intialization
     END IF;
     
     BEGIN 
      
       SELECT attr_group_id
		 INTO ln_attr_group_id
		 FROM EGO_ATTR_GROUPS_V
		WHERE 1=1
		  AND attr_group_type='XX_CDH_CUST_ACCOUNT'
		  AND attr_group_name = 'XX_CDH_VPS_CUST_ATTR';
     EXCEPTION
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in getting XX_CDH_VPS_CUST_ATTR in XX_FIN_VPS_NETTING_PKG.main: '||SQLERRM);
           fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'MAIN',
                         'Error Deriving Attr_group_id'||SQLERRM
                        ); 
     END;       
        
     -- Open the c_vps_custs
     FOR j_record IN c_vps_custs (ln_attr_group_id) 
     LOOP 
       BEGIN
       
       VENDOR_NETTING_PROC (
							p_errbuf_out       => p_errbuf_out
							,p_retcod_out       => p_retcod_out
							,p_account_id       => j_record.cust_account_id    
							,p_account_number   => j_record.account_number
							,p_account_name     => j_record.account_name
							,p_vendor_num       => j_record.vendor_num
							,p_run_date         => p_run_date         
							);
       
       EXCEPTION
           WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in calling PROCESS_VENDOR_NETTING from XX_FIN_VPS_NETTING_PKG.main: '||SQLERRM);
               fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'VENDOR_NETTING_PROC',
                         SQLERRM
                        ); 
       END;
         
     END LOOP; -- end of c_vps_custs
     
      SELECT COUNT(1) into l_interface_count
        FROM XX_FIN_VPS_SYS_NETTING_STG
        WHERE status='I'
		AND request_id=g_conc_request_id;
        
     IF l_interface_count>=1 THEN
       submit_ap_invoice_import(l_request_id);   
     --update success records
       UPDATE 
       XX_FIN_VPS_SYS_NETTING_STG
       SET 
       status='S'
       WHERE 
       receipt_number in (SELECT invoice_num
							FROM ap_invoices_interface
						   WHERE request_id=l_request_id
							 AND status='PROCESSED'
                          )  
        AND status='I'
		AND request_id=g_conc_request_id
        ; 
		
     --update error records
       UPDATE 
       XX_FIN_VPS_SYS_NETTING_STG
       SET  
        status='E',
        error_message='AP invoice did not get created in payables, due to interface errors, Please verify the Payables Open Interface Import program Request id:'||l_request_id
       WHERE 
       receipt_number in (SELECT invoice_num
							FROM   ap_invoices_interface
						   WHERE   request_id=l_request_id
                             AND   status='REJECTED'
                          )  
        AND status='I'
		AND request_id=g_conc_request_id
		; 
   END IF;
    
    SELECT COUNT(1) INTO l_record_count
          from xx_fin_vps_sys_netting_stg
          WHERE request_id=g_conc_request_id
          ;
    
	print_output;    
    IF l_record_count >=1 THEN 
       send_email;
    ELSE
    fnd_file.put_line(fnd_file.log,'No Records Selected');
    END IF;  
    
   EXCEPTION
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in XX_FIN_VPS_NETTING_PKG.main: '||SQLERRM||DBMS_UTILITY.format_error_backtrace); 
       fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'MAIN',
                         SQLERRM||DBMS_UTILITY.format_error_backtrace
                        ); 
   END main;  
end XX_FIN_VPS_NETTING_PKG;
/