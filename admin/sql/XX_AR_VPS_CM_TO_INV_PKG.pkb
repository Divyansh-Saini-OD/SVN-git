create or replace 
PACKAGE BODY XX_AR_VPS_CM_TO_INV_PKG AS 
-- +============================================================================================+
-- |  Office Depot                                                                          	  |
-- +============================================================================================+
-- |  Name:  XX_AR_VPS_CM_TO_INV_PKG                                                     	      |
-- |                                                                                            |
-- |  Description:  This packages helps to Autoapplication of credit memo to open invoices      | 
-- |                E7031 - AR VPS Auto Apply Credit Memos             	                        |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         11-AUG-2017  Uday Jadhav      Initial version                                  |
-- +============================================================================================+
 	PROCEDURE insert_log(
                        p_type    	  IN VARCHAR2,
                        p_inv_trx_num IN VARCHAR2,
                        p_inv_date	  IN DATE,
                        p_inv_amt     IN NUMBER,
                        p_cm_trx_num  IN VARCHAR2,
                        p_cm_amt	    IN NUMBER,
                        p_amt_applied IN NUMBER,
                        p_err_msg	    IN VARCHAR2
                      )
	IS 
    l_log_msg VARCHAR2(32000) := NULL;
	  PRAGMA AUTONOMOUS_TRANSACTION;
		BEGIN
			IF p_type= 'C' THEN
				l_log_msg := rpad(p_cm_trx_num,15,' ')
							||Lpad(To_Char(-1*p_cm_amt,'99G999G990D00PR'),15,' ')
							||rpad(p_inv_trx_num,16,' ')
							||rpad(p_inv_date,15,' ')
							||Lpad(To_Char(p_inv_amt,'99G999G990D00PR'),16,' ')
							||Lpad(To_Char(p_amt_applied,'99G999G990D00PR'),17,' ');
				ELSE
					l_log_msg :=p_err_msg;
			END IF;
		
			INSERT
			INTO xx_vps_netting_gt
			(
				Log_Type ,
				trx_number ,
				Log_Msg ,
				status
			)
			VALUES
			(
				p_type,
				p_cm_trx_num,
				l_log_msg,
				NULL
			);
			COMMIT;
		END;
  
  procedure print_log 
    IS
      CURSOR cur_cm is
            SELECT DISTINCT trx_number,substr(log_msg,1,30) log_msg
             FROM xx_vps_netting_gt
            WHERE LOG_TYPE='C';
      
      CURSOR cur_inv(p_trx_number IN VARCHAR2) is
            SELECT substr(log_msg,31) log_msg
             FROM xx_vps_netting_gt
            WHERE LOG_TYPE='C'
              AND trx_number=p_trx_number; 
            
      CURSOR cur is
			SELECT * 
			FROM xx_vps_netting_gt 
			WHERE LOG_TYPE='E';
      
   BEGIN   
              fnd_file.put_line(fnd_file.log,'Following CM Applied Successfully at '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss'));
              FOR r in cur_cm
                  LOOP
                      fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------');
                      fnd_file.put_line(fnd_file.log,'Credit Memo    '
                                                       ||'         Amount');
                      fnd_file.put_line(fnd_file.log,r.log_msg);
                      fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------');
                      fnd_file.put_line(fnd_file.log,'  Invoice Number '
                                 ||'   Invoice Date   '
                                 ||'  Invoice Amount'
                                 ||'   Amount Applied');
                      fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------');
                       FOR r1 in cur_inv(r.trx_number)
                            LOOP 
                            fnd_file.put_line(fnd_file.log,r1.log_msg);  
                            END LOOP; 
              fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------');  
       
              fnd_file.put_line(fnd_file.log,'----------------------------------------------------------');
              fnd_file.put_line(fnd_file.log,'Following Exceptions Occured during CM Matching Process');
              fnd_file.put_line(fnd_file.log,'----------------------------------------------------------');
            END LOOP;
			  FOR e in cur
			  	LOOP
			  		fnd_file.put_line(fnd_file.log,e.log_msg);   
			  	END LOOP;  
          fnd_file.put_line(fnd_file.log,'----------------------------------------------------------');  
   EXCEPTION           
      WHEN OTHERS
      THEN
          fnd_file.put_line(fnd_file.log,'Unable to print Output '||SQLERRM);  
   END;  
   
  /*   procedure SEND_EMAIL_NOTIF 
    IS
      CURSOR cur_cm is
            SELECT DISTINCT trx_number,substr(log_msg,1,30) log_msg
             FROM 
                xx_vps_netting_gt
            WHERE LOG_TYPE='C';
      
      CURSOR cur_inv(p_trx_number IN VARCHAR2) is
            SELECT substr(log_msg,31) log_msg
             FROM 
                xx_vps_netting_gt
            WHERE LOG_TYPE='C'
              AND trx_number=p_trx_number
            ;
            
      CURSOR cur is
      select * from xx_vps_netting_gt where LOG_TYPE='E';

             lc_conn                   UTL_SMTP.connection;
             lc_attach_text                               VARCHAR2 (2000);
             lc_success_data varchar2(32000);
             lc_exp_data varchar2(32000);
             lc_err_nums NUMBER := 0;
             lc_request_id                 NUMBER := fnd_global.conc_request_id;
             lc_mail_from       VARCHAR2(100);  
             lc_mail_to       VARCHAR2(100);   
             lc_mail_request_id NUMBER;
   BEGIN  
          
        BEGIN
          SELECT target_value1,target_value2 INTO  lc_mail_from,lc_mail_to
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name ='OD_VPS_TRANSLATION'
            AND source_value1='AUTOAPPLY_CM_INV'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';
         
         EXCEPTION WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM); 
          fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SEND_EMAIL_NOTIF',
                         'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM
                        ); 
         END;   
             
              lc_success_data :='Following CM Applied Successfully at '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||CHR(10); 
              FOR r in cur_cm
                  LOOP
                      lc_success_data :=lc_success_data||'-------------------------------------------------------------------'||CHR(10);
                      lc_success_data :=lc_success_data||'Credit Memo    '
                                                       ||'         Amount'||CHR(10);
                      lc_success_data :=lc_success_data||r.log_msg||CHR(10);
                      LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'-------------------------------------------------------------------'||CHR(10);
                      lc_success_data :=lc_success_data||'  Invoice Number '
                                 ||'   Invoice Date   '
                                 ||'  Invoice Amount'
                                 ||'   Amount Applied'||CHR(10);
                      LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'-------------------------------------------------------------------'||CHR(10);
                       FOR r1 in cur_inv(r.trx_number)
                            LOOP 
                            lc_success_data :=lc_success_data||r1.log_msg||CHR(10); 
               
                                IF length(lc_success_data)>31000 THEN
                                  lc_success_data :=lc_success_data||'Too Many CM Application Processed, Please check Log file of Conc Req ID-'||lc_request_id||CHR(10) ;
                                EXIT;
                                END IF;
                            END LOOP; 
              lc_success_data :=lc_success_data||'-------------------------------------------------------------------'||CHR(10);  
       
              lc_exp_data :=lc_exp_data||'----------------------------------------------------------'||CHR(10);
              lc_exp_data :=lc_exp_data||'Following Exceptions Occured during CM Matching Process'||CHR(10);
              lc_exp_data :=lc_exp_data||'----------------------------------------------------------'||CHR(10);
            END LOOP;
			  FOR e in cur
			  	LOOP
			  		lc_exp_data :=lc_exp_data|| e.log_msg||CHR(10);  
			  		lc_err_nums := cur%ROWCOUNT;  
			  		IF length(lc_exp_data)>31000 THEN
			  		lc_exp_data :=lc_exp_data||'Too Many Errors, Please check Log file of Conc Req ID-'||lc_request_id||CHR(10) ;
			  		EXIT;
			  		END IF;
			  	END LOOP; 
               
				IF lc_err_nums=0 THEN
					lc_exp_data :=lc_exp_data||'No Exceptions Found'||CHR(10);
				END IF;
				
				lc_exp_data :=lc_exp_data||'----------------------------------------------------------'||CHR(10);
				lc_attach_text:= lc_success_data||chr(10)||lc_exp_data; 
				
				lc_conn := xx_pa_pb_mail.begin_mail (sender          =>  lc_mail_from,
													recipients      =>  lc_mail_to,
													cc_recipients   => NULL,
													subject         => 'AR VPS Auto Apply CM to INV Status Report'
													); 
					
					--Attach text in the mail                                              
				xx_pa_pb_mail.write_text (conn   => lc_conn,
										message   => lc_attach_text);
       --End of mail                                    
				xx_pa_pb_mail.end_mail (conn => lc_conn);
      
			fnd_file.put_line(fnd_file.log,'lc_attach_text'||lc_attach_text);  
   EXCEPTION           
      WHEN OTHERS
      THEN
          fnd_file.put_line(fnd_file.log,'Unable to send mail '||SQLERRM); 
          fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || 'SEND_EMAIL_NOTIF',
                         SQLERRM
                        ); 
   END;  
   */
   
    PROCEDURE apply_cm_inv_process (p_cm_customer_trx_id    IN  NUMBER
                                   ,p_cm_trx_number         IN VARCHAR2
                                   ,p_inv_customer_trx_id   IN  NUMBER
                                   ,p_inv_trx_number        IN VARCHAR2
                                   ,p_payment_schedule_id   IN  NUMBER
                                   ,p_amount_applied        IN  NUMBER
                                   ,p_msg_comments          IN  VARCHAR2
                                   ,p_user_id               IN  NUMBER
                                   ,p_resp_id               IN  NUMBER
                                   ,p_resp_appl_id          IN  NUMBER
                                   ,p_debug_flag            IN  VARCHAR2
                                   ,p_cycle_date            IN  VARCHAR2
                                   ,x_msg_count             OUT NUMBER
                                   ,x_msg_data              OUT VARCHAR2
                                   ,x_return_status         OUT VARCHAR2
                                   )
    IS
    
    --Local Variables Declaration
    
            ln_msg_count                    NUMBER  := 0;
            lc_msg_data                     VARCHAR2(255);
            ln_out_rec_application_id       NUMBER;
            lc_error_msg                    VARCHAR2(4000);
            lc_debug_msg                    VARCHAR2(4000);
            ln_api_version                  CONSTANT NUMBER := 1;
            lc_init_msg_list                CONSTANT VARCHAR2(1) := FND_API.g_true;
            lc_comments                     CONSTANT ar_receivable_applications.comments%TYPE := p_msg_comments;
            lc_commit                       CONSTANT VARCHAR2(1) := FND_API.g_false;
            ln_acctd_amount_applied_from    ar_receivable_applications.acctd_amount_applied_from%TYPE;
            ln_acctd_amount_applied_to      ar_receivable_applications.acctd_amount_applied_to%TYPE;
            lr_cm_app_rec                   AR_CM_API_PUB.cm_app_rec_type;
            lc_return_status                VARCHAR2(1000);
    
    BEGIN
    -----------------------------------------------------------------------------------------------------------------
    -- Calling standard API to apply CM to invoice-------------------------------------------------------------------
    -- First set the environment of the user submitting the request by submitting fnd_global.apps_initialize()-------
    --The procedure requires three parameters ... Fnd_Global.apps_initialize(userId,responsibilityId,applicationId)--
    -----------------------------------------------------------------------------------------------------------------
    
            Fnd_Global.apps_initialize(p_user_id,p_resp_id,p_resp_appl_id);
            Mo_global.init('AR'); 
    
            lc_debug_msg :='User ID           : ' || p_user_id;
            fnd_file.put_line(fnd_file.log,lc_debug_msg);
            lc_debug_msg :='Responsiblity ID  : ' || p_resp_id;
            fnd_file.put_line(fnd_file.log,lc_debug_msg);
            lc_debug_msg :='Application ID    : ' || p_resp_appl_id;
            fnd_file.put_line(fnd_file.log,lc_debug_msg);
            lc_debug_msg :='Passing values in Apply CM Inv Process Procedure to call Standard API';
            fnd_file.put_line(fnd_file.log,lc_debug_msg);
    
    
            lr_cm_app_rec.cm_customer_trx_id        := p_cm_customer_trx_id;
            lr_cm_app_rec.cm_trx_number             := null; -- Credit Memo Number
            lr_cm_app_rec.inv_customer_trx_id       := p_inv_customer_trx_id;
            lr_cm_app_rec.inv_trx_number            := null ; -- Invoice Number
            lr_cm_app_rec.installment               := null;
            lr_cm_app_rec.amount_applied            := p_amount_applied;
            lr_cm_app_rec.applied_payment_schedule_id := p_payment_schedule_id;
            lr_cm_app_rec.apply_date                := p_cycle_date;
            lr_cm_app_rec.gl_date                   := p_cycle_date;
            lr_cm_app_rec.inv_customer_trx_line_id  := null;
            lr_cm_app_rec.inv_line_number           := null;
            lr_cm_app_rec.show_closed_invoices      := null;
            lr_cm_app_rec.ussgl_transaction_code    := null;
            lr_cm_app_rec.attribute_category        := null;
            lr_cm_app_rec.attribute1                := null;
            lr_cm_app_rec.attribute2                := null;
            lr_cm_app_rec.attribute3                := null;
            lr_cm_app_rec.attribute4                := null;
            lr_cm_app_rec.attribute5                := null;
            lr_cm_app_rec.attribute6                := null;
            lr_cm_app_rec.attribute7                := null;
            lr_cm_app_rec.attribute8                := null;
            lr_cm_app_rec.attribute9                := null;
            lr_cm_app_rec.attribute10               := null;
            lr_cm_app_rec.attribute11               := null;
            lr_cm_app_rec.attribute12               := null;
            lr_cm_app_rec.attribute13               := null;
            lr_cm_app_rec.attribute14               := null;
            lr_cm_app_rec.attribute15               := null;
            lr_cm_app_rec.global_attribute_category := null;
            lr_cm_app_rec.global_attribute1         := null;
            lr_cm_app_rec.global_attribute2         := null;
            lr_cm_app_rec.global_attribute3         := null;
            lr_cm_app_rec.global_attribute4         := null;
            lr_cm_app_rec.global_attribute5         := null;
            lr_cm_app_rec.global_attribute6         := null;
            lr_cm_app_rec.global_attribute7         := null;
            lr_cm_app_rec.global_attribute8         := null;
            lr_cm_app_rec.global_attribute9         := null;
            lr_cm_app_rec.global_attribute10        := null;
            lr_cm_app_rec.global_attribute11        := null;
            lr_cm_app_rec.global_attribute12        := null;
            lr_cm_app_rec.global_attribute12        := null;
            lr_cm_app_rec.global_attribute14        := null;
            lr_cm_app_rec.global_attribute15        := null;
            lr_cm_app_rec.global_attribute16        := null;
            lr_cm_app_rec.global_attribute17        := null;
            lr_cm_app_rec.global_attribute18        := null;
            lr_cm_app_rec.global_attribute19        := null;
            lr_cm_app_rec.global_attribute20        := null;
            lr_cm_app_rec.comments                  := lc_comments;
            lr_cm_app_rec.called_from               := null;
    
            ln_msg_count := 0; 
    
    --/*
                 AR_CM_API_PUB.APPLY_ON_ACCOUNT( p_api_version               => ln_api_version
                                               , p_init_msg_list             => lc_init_msg_list
                                               , p_commit                    => lc_commit
                                               , p_cm_app_rec                => lr_cm_app_rec
                                               , x_return_status             => lc_return_status
                                               , x_msg_count                 => ln_msg_count
                                               , x_msg_data                  => lc_msg_data
                                               , x_out_rec_application_id    => ln_out_rec_application_id
                                               , x_acctd_amount_applied_from => ln_acctd_amount_applied_from
                                               , x_acctd_amount_applied_to   => ln_acctd_amount_applied_to
                                               );
    --*/
    
            x_msg_count   := ln_msg_count;
            x_return_status := lc_return_status;
            fnd_file.put_line(fnd_file.log,'Message Count     : '||x_msg_count);
            fnd_file.put_line(fnd_file.log,'Return Status is ' ||lc_return_status);
            lc_debug_msg := 'Standard API Process Completed';
            fnd_file.put_line(fnd_file.log,lc_debug_msg);
    
    
       IF ln_msg_count = 1
       THEN
            x_msg_data  := 'Error while Applying Invoice ' || p_inv_trx_number || ' to CM  '||p_cm_trx_number ||' ' || lc_msg_data;
            fnd_file.put_line(fnd_file.log,(x_msg_data));
            fnd_file.put_line(fnd_file.log,('Return Status is ' ||lc_return_status));
    
       ELSIF ln_msg_count > 1
       THEN
            lc_error_msg :='Error occured while Applying Invoice  ' || p_inv_trx_number || ' to CM  '||p_cm_trx_number;
            fnd_file.put_line(fnd_file.log,('Return Status is ' ||lc_return_status));
         FOR I IN 1..ln_msg_count
         LOOP
            lc_error_msg:= lc_error_msg || (I||'. '||SUBSTR(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE ), 1,255));
    
         END LOOP;
            x_msg_data:=lc_error_msg;
            fnd_file.put_line(fnd_file.log,'Error Message from Standard API  ' || lc_error_msg);
       END IF;
            ln_msg_count := 0;
            fnd_file.put_line(fnd_file.log,'Successfully submitted Standard API');
    
    EXCEPTION
    WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Exception raised while submitting Standard API'  || SQLERRM);
    
    END APPLY_CM_INV_PROCESS;  

  PROCEDURE cm_match_process (
                              p_errbuf_out              OUT       VARCHAR2
                              ,p_retcod_out             OUT       VARCHAR2 
                              ,p_vendor_number          IN        VARCHAR2
                              ,p_attr_group_id          IN        NUMBER
                              )
  IS
  -- CM
    CURSOR cur_rec(p_vendor_number IN VARCHAR2,p_attr_group_id IN NUMBER)
        IS
          SELECT rct.customer_trx_id,
				 rct.trx_number cm_trx_number,
				 rct.attribute14,
				 aps.customer_id,
				 ABS(aps.amount_due_remaining) amount_due_remaining
          FROM  ra_cust_trx_types     rctt,
                ar_payment_schedules  aps,
                ra_customer_trx       rct,
                hz_cust_accounts            hca,
                xx_cdh_cust_acct_ext_b extb
          WHERE rct.cust_trx_type_id     = rctt.cust_trx_type_id
          AND 	rctt.name                ='US_VPS_CM_OA'
          AND 	aps.customer_trx_id      =rct.customer_trx_id 
          AND 	aps.status               ='OP'
          AND 	aps.class                ='CM' 
          AND 	extb.cust_account_id     = hca.cust_account_id
          and 	extb.attr_group_id       = p_attr_group_id
          AND 	aps.customer_id          = hca.cust_account_id
          AND 	hca.orig_system_reference=nvl(p_vendor_number, hca.orig_system_reference)
          AND 	aps.invoice_currency_code = 'USD'
          AND 	aps.amount_due_remaining < 0;
          
          --CM total Amount
      CURSOR cur_rec_amt(p_customer_trx_id IN NUMBER)
      IS
        SELECT abs((NVL(aps.amount_due_remaining,0))) amount_due_remaining
          FROM ar_payment_schedules aps  
         WHERE aps.org_id =fnd_global.org_id 
           AND aps.customer_trx_id=p_customer_trx_id; 
           
      -- Select Invoices     
     CURSOR cur( p_customer_id IN NUMBER,p_pgm_id IN VARCHAR2)
         IS
            SELECT rct.attribute14,
                  aps.customer_id,
                  rct.creation_date,
                  rct.trx_date invoice_date,
                  aps.payment_schedule_id,
                  rct.trx_number inv_trx_number,
                  rct.customer_trx_id inv_customer_trx_id,
                  aps.amount_due_remaining inv_amount
             FROM ra_cust_trx_types rctt,
                  ra_customer_trx rct ,
                  ar_payment_schedules aps  
            WHERE rct.cust_trx_type_id = rctt.cust_trx_type_id
              AND rctt.name ='US_VPS_OA'
              AND rct.attribute14 = TO_CHAR(p_pgm_id) 
              AND rct.attribute_category = 'US_VPS' 
              AND rct.customer_trx_id = aps.customer_trx_id
              AND aps.customer_id = p_customer_id 
              AND aps.invoice_currency_code = 'USD' 
              AND aps.status = 'OP' 
              AND aps.amount_due_remaining > 0 
         ORDER BY rct.trx_date, rct.creation_date;

		l_cm_amount NUMBER :=0;
		lc_count                        NUMBER :=0;
		lc_rec_cnt                      NUMBER :=0;
		lc_msg_data                     VARCHAR2(1000);
		lc_return_status                VARCHAR2(25);  
		
        l_user_id              NUMBER := FND_PROFILE.VALUE('USER_ID');
        l_resp_id              NUMBER := FND_PROFILE.VALUE('RESP_ID') ;
        l_resp_appl_id         NUMBER := FND_PROFILE.VALUE('RESP_APPL_ID');
  
  BEGIN
		/*Truncate log table */
		EXECUTE IMMEDIATE('TRUNCATE TABLE xxfin.xx_vps_netting_gt');
		
       FOR r_cm in cur_rec(p_vendor_number,p_attr_group_id) 
          LOOP 
          l_cm_amount :=r_cm.amount_due_remaining; 
              FOR r_inv IN cur(r_cm.customer_id,r_cm.attribute14)
                 LOOP
                     fnd_file.put_line(fnd_file.log,'Invoice:'||r_inv.inv_customer_trx_id||':'||r_inv.payment_schedule_id||':'||r_inv.inv_amount); 
                      
					  IF l_cm_amount >r_inv.inv_amount THEN
						l_cm_amount:= r_inv.inv_amount;
					  END IF;
					  --Call Matching API
					    apply_cm_inv_process(r_cm.customer_trx_id
											,r_cm.cm_trx_number
											,r_inv.inv_customer_trx_id
											,r_inv.inv_trx_number
											,r_inv.payment_schedule_id
											,l_cm_amount  
											,TO_CHAR(SYSDATE,'DD-MON-YYYY hh24:mi:ss')
											,l_user_id
											,l_resp_id
											,l_resp_appl_id
											,sysdate --lc_debug_flag
											,sysdate --ld_cycle_date
											,lc_count
											,lc_msg_data
											,lc_return_status
											);  
                      
					IF (lc_count =0 or lc_return_status <> 'E')
					THEN
						fnd_file.put_line(fnd_file.log,r_inv.inv_trx_number||'Invoice Applied to CM '||r_cm.cm_trx_number); 
						
						insert_log('C',r_inv.inv_trx_number,r_inv.invoice_date,r_inv.inv_amount, r_cm.cm_trx_number, r_cm.amount_due_remaining,l_cm_amount, lc_msg_data);
						
						OPEN cur_rec_amt(r_cm.customer_trx_id);
							FETCH cur_rec_amt INTO  l_cm_amount;
						CLOSE cur_rec_amt; 
						
						IF l_cm_amount=0 THEN  
							fnd_file.put_line(fnd_file.log,'CM Remaining Amt:'||l_cm_amount); 
							EXIT;
						ELSE
							fnd_file.put_line(fnd_file.log,'CM Remaining Amt:'||l_cm_amount);
						END IF; 
					ELSE
						insert_log('E',r_inv.inv_trx_number,r_inv.invoice_date,r_inv.inv_amount, r_cm.cm_trx_number,r_cm.amount_due_remaining,l_cm_amount,lc_msg_data);
						fnd_file.put_line(fnd_file.log,lc_return_status); 
						ROLLBACK;
					END IF; 
				 END LOOP;
			COMMIT;
		 END LOOP; 
      print_log;
	EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.log,SQLCODE||':'||SQLERRM); 
			insert_log('E',NULL,NULL,NULL, NULL, NULL,NULL,lc_msg_data);
  END;  
  
  PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
     ,p_vendor_number           IN       VARCHAR2
   )
   IS
       l_errbuf_out varchar2(2000);
       l_retcod_out varchar2(1); 
	     l_vendor_number VARCHAR2(100);
       l_attr_group_id NUMBER;
   BEGIN
        BEGIN
             SELECT attr_group_id
             INTO   l_attr_group_id
             FROM   ego_attr_groups_v
             WHERE  1=1
             AND    attr_group_type='XX_CDH_CUST_ACCOUNT'
             AND    attr_group_name = 'XX_CDH_VPS_CUST_ATTR';
         EXCEPTION
             WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in getting XX_CDH_VPS_CUST_ATTR in XX_FIN_VPS_NETTING_PKG.main: '||SQLERRM);
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || 'MAIN',
                               'Error Deriving Attr_group_id'||SQLERRM
                            ); 
         END;    
         
        IF p_vendor_number is NOT NULL
        THEN
            l_vendor_number :=p_vendor_number||'-VPS';
        ELSE
            l_vendor_number := NULL;
        END IF;

			  	cm_match_process (
			  					 p_errbuf_out  		=> p_errbuf_out
			  					,p_retcod_out  		=> p_retcod_out 
			  					,p_vendor_number 	=> l_vendor_number
								,p_attr_group_id  => l_attr_group_id
			  					);     
	   EXCEPTION
		 WHEN OTHERS THEN
		   fnd_file.put_line(fnd_file.log,'Unexpected Error in XX_AR_VPS_CM_TO_INV_PKG.main: '||SQLERRM||DBMS_UTILITY.format_error_backtrace); 
		   insert_log('E',NULL,NULL,NULL, NULL, NULL,NULL,g_pkg_name || 'MAIN'||SQLERRM||DBMS_UTILITY.format_error_backtrace);
		   fnd_log.STRING (fnd_log.level_statement,
                        g_pkg_name || 'MAIN',
                        SQLERRM||DBMS_UTILITY.format_error_backtrace
                        ); 
   END; 
end XX_AR_VPS_CM_TO_INV_PKG;
/
