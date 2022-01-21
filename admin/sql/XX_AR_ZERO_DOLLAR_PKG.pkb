create or replace
PACKAGE BODY XX_AR_ZERO_DOLLAR_PKG
  -- +============================================================================+
  -- |                  Office Depot - Project Simplify                           |
  -- |                        Office Depot Organization                           |
  -- +============================================================================+
  -- | Name             :  XX_AR_ZERO_DOLLAR_PKG.pkb                              |
  -- | RICE ID          : R1389                                                   |
  -- |                                                                            |
  -- | Description      :  This package will display Zero Dollar Application      |
  -- |                     Receipts.                                              |
  -- |                                                                            |
  -- |Change Record:                                                              |
  -- |===============                                                             |
  -- |Version Date        Author            Remarks                               |
  -- |======= =========== =============     ================                      |
  -- |DRAFT1A 03-OCT-13   Gayathri K       Created as part of QC#24465            |
  -- | 1.1    16-SEP-14   Gayathri K       Changed data type from DATE to VARCHAR2|
  -- |                                    as part of QC#30179                     |
  -- | 1.2    30-OCT-15   Vasu R           Removed Schema References for R12.2    |
  -- +============================================================================+
AS
 -- +============================================================================+
  -- | Name             :  XX_AR_ZERO_DOLLAR_PROC                                 |
  -- |                                                                            |
  -- | Description      :This procedure will display Zero Dollar application Trxs |
  -- | Parameters       :  p_from_trans_date        IN ->  Transmission From Date |
  -- |                                                                            | 
  -- |                  :  p_to_trans_date    IN->         Transmission To Date   |
  -- |                                                                            |
  -- +============================================================================+
  
PROCEDURE PUBLISH_REPORT(
      RPT_REQUEST_ID IN NUMBER )
  IS
    -- Local Variable declaration
    x_errbuf        VARCHAR2(1000);
    x_ret_code      VARCHAR2(1000);
    ln_request_id   NUMBER := 0;
    lc_phase        VARCHAR2 (200);
    lc_status       VARCHAR2 (200);
    lc_dev_phase    VARCHAR2 (200);
    lc_dev_status   VARCHAR2 (200);
    lc_message      VARCHAR2 (200);
    lb_wait         BOOLEAN;
    lb_layout       BOOLEAN;
    lc_request_data VARCHAR2(120);
	l_temp       VARCHAR2(200);
	lb_print_option      BOOLEAN;
	
  BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the program OD AR Zero Dollar Application Notification Program - Excel');
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameter values in PUBLISH_REPORT procedure');
    
       lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                              printer           => 'XPTR'
                                                             ,copies            => 1
                                                     ); 
                                                     
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID =' || RPT_REQUEST_ID );
		lb_layout    := fnd_request.add_layout( 'XXFIN' ,'XXZERODOLLORNF' ,'en' ,'US' ,'EXCEL' );
		ln_request_id:=FND_REQUEST.SUBMIT_REQUEST (  'XXFIN' --application name
													,'XXZERODOLLORNF'                            -- short name of the AP concurrent program
													,''                                          -- description
													,SYSDATE                                     -- start time
													,FALSE                                       -- sub request
													,RPT_REQUEST_ID                              -- parameter1
    );
	
    COMMIT;
	
    lb_wait          := fnd_concurrent.wait_for_request (ln_request_id, 20, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
    
	IF ln_request_id <> 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OD AR Zero Dollar Application Notification Program - Excel report has been submitted and the request id is: '||ln_request_id);
      IF lc_dev_status    ='E' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN ERROR';
        x_ret_code       := 2;
      ELSIF lc_dev_status ='G' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN WARNING';
        x_ret_code       := 1;
      ELSE
        x_errbuf   := 'PROGRAM COMPLETED NORMAL';
        x_ret_code := 0;
	  END IF;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');
    END IF;
    
	l_temp  := 'Truncate table XXFIN.XX_AR_ZERO_DOLLAR_APP';
	EXECUTE immediate l_temp;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Truncating table - COMPLETED');
	
END PUBLISH_REPORT;  
  
PROCEDURE XX_AR_ZERO_DOLLAR_PROC(
    x_retcode             OUT NOCOPY      NUMBER,
    x_errbuf              OUT NOCOPY      VARCHAR2,
   -- p_from_trans_date IN DATE,  -- commneted as part of QC#30179
   -- p_to_trans_date IN DATE )   -- commneted as part of QC#30179
    p_from_trans_date IN VARCHAR2,-- Added as part of QC#30179
    p_to_trans_date IN VARCHAR2 )-- Added as part of QC#30179
AS
     CURSOR lcu_identify_receipts
  IS
    SELECT acra.cash_receipt_id cash_receipt_id,
           COUNT (acra.cash_receipt_id) receipt_count
      FROM ar_cash_receipts_all acra,
           ar_cash_receipt_history_all acrh,
           ar_payment_schedules_all arps,
           ar_receivable_applications_all arra
     WHERE acrh.cash_receipt_id     = acra.cash_receipt_id
       AND arps.cash_receipt_id     = acra.cash_receipt_id
       AND arra.cash_receipt_id     = acra.cash_receipt_id
       AND arra.payment_schedule_id = arps.payment_schedule_id
       AND acrh.current_record_flag = 'Y'
       AND arps.status              = 'CL'
       AND arra.display             = 'Y'
       AND arra.status              = 'APP'
       AND arra.application_type    = 'CASH'
       AND acrh.batch_id           IN ( SELECT batch_id
                                          FROM ar_batches_all
                                         WHERE transmission_request_id IN ( SELECT transmission_request_id
                                                                              FROM ar_transmissions_all
                                                                             Where 1=1--transmission_name = 'LB_201307150316FTBCHICRET.txt'
                                                                             And Trunc(Creation_Date) Between --p_from_trans_date AND p_to_trans_date commented as part of QC# 30179
                                                                             TRUNC(to_date(p_from_trans_date,'YYYY/MM/DD HH24:MI:SS')) And TRUNC(to_date(p_to_trans_date,'YYYY/MM/DD HH24:MI:SS'))
                                                                          ) -- Added as part of QC# 30179

                                      )
    GROUP BY acra.cash_receipt_id
    HAVING COUNT (acra.cash_receipt_id) > 1
    ORDER BY acra.cash_receipt_id;


  CURSOR lcu_rec_appl_detail (p_cash_receipt_id IN NUMBER)
  IS
    SELECT arra.amount_applied,
           arra.apply_date,
           ract.trx_number,
           ract.trx_date,
           arps.amount_due_original,
           arps.amount_due_remaining,
           arps.amount_applied trx_amt_applied,
           arps.status
    FROM ar_receivable_applications_all arra,
         ra_customer_trx_all ract,
         ar_payment_schedules_all arps
    WHERE ract.customer_trx_id = arra.applied_customer_trx_id
      AND arps.customer_trx_id   = ract.customer_trx_id
      AND arra.display           = 'Y'
      AND arra.status            = 'APP'
      AND ARRA.APPLICATION_TYPE  = 'CASH'
      AND arra.cash_receipt_id   = p_cash_receipt_id
    ORDER BY arra.amount_applied DESC ;
    
    ln_prob_rcpt_count     NUMBER         := 0;
     ln_rcpt_appl_count     NUMBER         := 0;
     ln_msg_count           NUMBER         := 0;
     lc_status_flag         VARCHAR2(1)    := 'N';
     lc_status              VARCHAR2(20)   DEFAULT NULL;
     lc_msg_data            VARCHAR2(4000) DEFAULT NULL; 
     
     ln_cust_trx_id         ra_customer_trx_all.CUSTOMER_TRX_ID%TYPE;
     ln_receipt_num         ar_cash_receipts_all.RECEIPT_NUMBER%TYPE;
     ld_receipt_date        ar_cash_receipts_all.RECEIPT_DATE%TYPE;
     ln_receipt_amt         ar_cash_receipts_all.AMOUNT%TYPE;
     ln_receipt_id          ar_cash_receipts_all.CASH_RECEIPT_ID%TYPE;
     lc_cust_acct_num       hz_cust_accounts.ACCOUNT_NUMBER%TYPE;
     lc_cust_acct_name      hz_cust_accounts.ACCOUNT_NAME%TYPE;
     lc_receipt_status      ar_payment_schedules_all.STATUS%TYPE;
     
     lc_print_header        VARCHAR2 (300) := NULL;
     lc_print_line          VARCHAR2 (300) := NULL;
	 ln_request_id           NUMBER(20);  -- Added by Ankit
   
BEGIN

  fnd_file.put_line (fnd_file.LOG,'*** QC Defect # 24465 - Lockbox Cash Application Issue - Full Dollar Amount Applied to First Trx and Zero Dollar Applied to Remaining Transactions ***');
  fnd_file.put_line (fnd_file.OUTPUT,'Office Depot INC ');
  fnd_file.put_line (fnd_file.OUTPUT,'Accounts Receivable                 Zero Dollar Application  '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MI:SS'));
  
    ln_request_id := fnd_global.conc_request_id;  -- Added by Ankit
	
    lc_print_header        :=           rpad('CUSTOMER_NAME', 30, ' ')
                               ||'|'||  rpad('CUSTOMER_NUMBER', 15, ' ')
                               ||'|'||  rpad('RECEIPT_NUMBER', 15, ' ') 
                               ||'|'||  rpad('RECEIPT_DATE', 15, ' ')
                               ||'|'||  rpad('RECEIPT_AMOUNT' , 15, ' ')
                               ||'|'|| rpad('APPLIED_TRX_NUMBER', 20, ' ');
                               
   
    fnd_file.put_line (fnd_file.OUTPUT,' '||(lc_print_header));
     
    ln_prob_rcpt_count  := 0;
    
    FOR id_receipt_rec IN lcu_identify_receipts
    LOOP
            BEGIN

            ln_cust_trx_id  := 0;
            
            SELECT DISTINCT arps.customer_trx_id
              INTO ln_cust_trx_id
              FROM ra_customer_trx_all ract,
                   ar_payment_schedules_all arps
             WHERE arps.customer_trx_id = ract.customer_trx_id
               AND arps.status          = 'OP'
               AND arps.amount_applied  > arps.amount_due_original
               AND ract.customer_trx_id IN ( SELECT arra.applied_customer_trx_id
                                               FROM ar_receivable_applications_all arra
                                              WHERE arra.display          = 'Y'
                                                AND arra.status           = 'APP'
                                                AND arra.application_type = 'CASH'
                                                AND arra.cash_receipt_id  = id_receipt_rec.cash_receipt_id
                                            );        
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_cust_trx_id  := 0;
        
            WHEN OTHERS THEN
                ln_cust_trx_id  := 0;
        END;

        IF ln_cust_trx_id <> 0 THEN
        
            BEGIN
            
                ln_receipt_num      := 0;
                ld_receipt_date     := NULL;
                ln_receipt_amt      := 0;
                lc_cust_acct_num    := NULL;
                lc_cust_acct_name   := NULL;
                lc_receipt_status   := NULL;
                ln_receipt_id       := 0;
                
                SELECT acra.receipt_number,
                       acra.receipt_date,
                       acra.amount,
                       hca.account_number,
                       hca.account_name,
                       arps.status,
                       acra.cash_receipt_id
                  INTO ln_receipt_num,
                       ld_receipt_date,
                       ln_receipt_amt,
                       lc_cust_acct_num,
                       lc_cust_acct_name,
                       lc_receipt_status,
                       ln_receipt_id
                  FROM ar_cash_receipts_all acra,
                       ar_payment_schedules_all arps,
                       hz_cust_accounts hca 
                 WHERE arps.cash_receipt_id      = acra.cash_receipt_id
                   AND hca.cust_account_id       = acra.pay_from_customer
                   AND hca.status                = 'A'
                   AND acra.cash_receipt_id      = id_receipt_rec.cash_receipt_id
                   AND EXISTS ( SELECT arra.cash_receipt_id
                                  FROM ar_receivable_applications_all arra
                                 WHERE arra.display          = 'Y'
                                   AND arra.status           = 'APP'
                                   AND arra.application_type = 'CASH'
                                   AND arra.cash_receipt_id  = acra.cash_receipt_id
                                   AND arra.applied_customer_trx_id = ln_cust_trx_id
                              )  ;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ln_receipt_num      := 0;
                    ld_receipt_date     := NULL;
                    ln_receipt_amt      := 0;
                    lc_cust_acct_num    := NULL;
                    lc_cust_acct_name   := NULL;
                    lc_receipt_status   := NULL;
                    ln_receipt_id       := 0;
                    
                WHEN OTHERS THEN
                    ln_receipt_num      := 0;
                    ld_receipt_date     := NULL;
                    ln_receipt_amt      := 0;
                    lc_cust_acct_num    := NULL;
                    lc_cust_acct_name   := NULL;
                    lc_receipt_status   := NULL;
                    ln_receipt_id       := 0;

            END;
        
        END IF;

        IF ln_receipt_id <> 0 THEN
        
            BEGIN

                ln_rcpt_appl_count  := 0;
                lc_status_flag      := 'N';

                FOR rcpt_appl_rec IN lcu_rec_appl_detail (ln_receipt_id)
                LOOP
            --     fnd_file.put_line (fnd_file.output,'ln_receipt_id  => '|| ln_receipt_id);
                  BEGIN

                      ln_rcpt_appl_count    := ln_rcpt_appl_count + 1;
                      lc_status_flag        := 'N'; 

                      IF (ln_rcpt_appl_count = 1 AND 
                      rcpt_appl_rec.amount_applied = ln_receipt_amt and id_receipt_rec.cash_Receipt_id=ln_receipt_id) THEN   

                          lc_print_line    :=           rpad(lc_cust_acct_name, 30, ' ')
                                                ||'|'|| rpad(lc_cust_acct_num, 15, ' ')
                                                ||'|'|| rpad(ln_receipt_num, 15, ' ') 
                                                ||'|'|| rpad(ld_receipt_date, 15, ' ')
                                                ||'|'|| rpad(ln_receipt_amt, 15, ' ')
                                                ||'|'|| rpad(rcpt_appl_rec.trx_number, 20, ' '); 
                                                
                              fnd_file.put_line (fnd_file.OUTPUT,' '|| (lc_print_line));
							 
							 --Inserting into table for Excel Output Formatting -- Added by Ankit
							  INSERT into XX_AR_ZERO_DOLLAR_APP values ( lc_cust_acct_name,
							   lc_cust_acct_num,
							   ln_receipt_num,
							   ld_receipt_date,
							   ln_receipt_amt,
							   rcpt_appl_rec.trx_number,
							   ln_request_id
							   );
                            
                           lc_status_flag   := 'Y';
                           
                     /* ELSIF (ln_rcpt_appl_count <> 1 AND rcpt_appl_rec.amount_applied = 0 
                      ) THEN 

                            lc_print_line    :=          rpad(lc_cust_acct_name, 20, ' ')
                                                ||','|| rpad(lc_cust_acct_num, 15, ' ')
                                                ||','|| rpad(ln_receipt_num, 15, ' ') 
                                                ||','|| rpad(ld_receipt_date, 15, ' ')
                                                ||','|| rpad(ln_receipt_amt, 15, ' ')
                                                ||','|| rpad(rcpt_appl_rec.trx_number, 20, ' '); 
                                                lc_print_line    :=           rpad(' ', 20, ' ')
                                                ||','|| rpad(' ', 15, ' ')
                                                ||','|| rpad(' ', 15, ' ') 
                                                ||','|| rpad(ln_receipt_amt, 15, ' ')
                                                ||','|| rpad(rcpt_appl_rec.trx_number, 20, ' ');
                                                    

                           lc_status_flag   := 'Y';*/
                            
                      ELSE

                           lc_print_line    := NULL;
                           lc_status_flag   := 'N';     
                      
                      END IF;

                   --   IF lc_status_flag = 'Y' THEN 
                   --     fnd_file.put_line (fnd_file.OUTPUT,' '|| (lc_print_line));
                 --     END IF;

                  EXCEPTION
                  WHEN OTHERS THEN
                      fnd_file.put_line (fnd_file.LOG,'Exception while getting transactions applied to a receipt : ' || SQLERRM);

                  END;
                 IF lc_status_flag = 'Y' THEN 
                    ln_prob_rcpt_count  := ln_prob_rcpt_count + 1;
                  --  fnd_file.put_line (fnd_file.OUTPUT,' '|| (rpad('-', 150, '-')));
                END IF;

                END LOOP;
                
               /* IF lc_status_flag = 'Y' THEN 
                    ln_prob_rcpt_count  := ln_prob_rcpt_count + 1;
                    fnd_file.put_line (fnd_file.OUTPUT,' '|| (rpad('-', 150, '-')));
                END IF;*/

            EXCEPTION
                WHEN OTHERS THEN
                    ln_rcpt_appl_count  := ln_rcpt_appl_count - 1;
                    fnd_file.put_line (fnd_file.LOG,' '||'Exception : ' || SQLERRM);

            END;
        
        END IF;
        
    END LOOP;
    
    fnd_file.put_line (fnd_file.LOG,' ');
    fnd_file.put_line (fnd_file.LOG,' Total Number of Receipts with Incorrect Application : ' || ln_prob_rcpt_count);
    fnd_file.put_line (fnd_file.LOG,' ');

	-- Calling PUBLISH_REPORT procedure to submit OD AR Zero Dollar Application Notification Program - Excel -- Added by Ankit
	fnd_file.put_line (fnd_file.LOG,'Calling - PUBLISH_REPORT procedure');
	PUBLISH_REPORT ( ln_request_id );
	fnd_file.put_line (fnd_file.LOG,'Completed - PUBLISH_REPORT procedure');

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Error  ' || SQLERRM);
  END;
  
  

END XX_AR_ZERO_DOLLAR_PKG;
/
SHOW ERR