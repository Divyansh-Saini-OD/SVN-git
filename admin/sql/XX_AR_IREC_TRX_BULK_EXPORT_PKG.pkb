CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_IREC_TRX_BULK_EXPORT_PKG
AS
-- +======================================================================================+
-- |                        Office Depot                                                  |
-- +======================================================================================+
-- | Name  : XX_AR_IREC_TRX_BULK_EXPORT_PKG                                               |
-- | Rice ID:                                                                             |
-- | Description :                                                                        |
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version Date        Author            Remarks                                         |
-- |======= =========== =============== ==================================================|
-- |1.0     28-MAR-2017 Havish Kasina   Initial draft version                             |
-- +======================================================================================+

  PROCEDURE EXTRACT(x_errbuf                    OUT NOCOPY    VARCHAR2,
                    x_retcode                   OUT NOCOPY    NUMBER,                    
					p_trx_date_from             IN            DATE,
                    p_trx_date_to               IN            DATE,
					p_due_date_from             IN            DATE,
					p_due_date_to               IN            DATE,
					p_amount_due_original_from  IN            NUMBER,
					p_amount_due_original_to    IN            NUMBER,
                    p_session_id                IN            NUMBER,
                    p_ship_to_site_use_id       IN            NUMBER,
					p_customer_number           IN            VARCHAR2,
					p_cust_account_id           IN            NUMBER,
					p_status                    IN            VARCHAR2,
					p_transaction_type          IN            VARCHAR2,
					p_template_type             IN            VARCHAR2,
                    p_mail_to                   IN            VARCHAR2 				   
				   )
  IS  
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  ln_request_id             NUMBER;
  lb_complete               BOOLEAN;
  lc_phase                  VARCHAR2 (100);
  lc_status                 VARCHAR2 (100);
  lc_dev_phase              VARCHAR2 (100);
  lc_dev_status             VARCHAR2 (100);
  lc_message                VARCHAR2 (100);
  ln_request                NUMBER;
  lc_smtp_server            VARCHAR2(100); 
  lc_email_from             VARCHAR2(100);
  lc_ar_pmt_status          VARCHAR2(10);
  lc_trx_date_from          VARCHAR2(11);
  lc_trx_date_to            VARCHAR2(11);
  lc_due_date_from          VARCHAR2(11);
  lc_due_date_to            VARCHAR2(11);
  lb_layout                 BOOLEAN;
  
  BEGIN
     -- Local varibales intialization
      ln_request_id     := NULL;
	  lb_complete       := NULL;
	  lc_phase          := NULL;
	  lc_status         := NULL;
	  lc_dev_phase      := NULL;
	  lc_dev_status     := NULL;
	  lc_message        := NULL;
	  ln_request        := NULL;
	  lc_smtp_server    := NULL; 
	  lc_email_from     := NULL;
	  lc_ar_pmt_status  := NULL;
	  lc_trx_date_from  := NULL;
      lc_trx_date_to    := NULL;
      lc_due_date_from  := NULL;
      lc_due_date_to    := NULL;
	  lb_layout         := NULL;
	  
     -- To get the SMTP server
      select FND_PROFILE.VALUE('XX_COMN_SMTP_MAIL_SERVER') 
	    into lc_smtp_server
		from dual;
		
	 -- To get the e-mail from	
	  SELECT (SELECT INSTANCE_NAME  FROM v$instance)||'@officedepot.com' 
	    INTO lc_email_from
		FROM dual;
		
	 -- To get the AR Payment Schedules status
	 
	  IF p_status = 'OPEN'
	  THEN
	     lc_ar_pmt_status := 'OP';
	  ELSIF p_status = 'CLOSED'
	   THEN 
	     lc_ar_pmt_status := 'CL';
	  ELSIF p_status = 'ANY_STATUS'
	   THEN
	     lc_ar_pmt_status := NULL;
	  END IF;
	  
	  -- To convert from Date to String for the Date Parameters
	  IF p_trx_date_from IS NOT NULL
	  THEN
		  SELECT TO_CHAR(p_trx_date_from,'DD-MON-YYYY') 
			INTO lc_trx_date_from 
			FROM dual;
	  ELSE 
	      lc_trx_date_from:= NULL;
	  END IF;
	  
	  IF p_trx_date_to IS NOT NULL
	  THEN
		  SELECT TO_CHAR(p_trx_date_to,'DD-MON-YYYY') 
			INTO lc_trx_date_to 
			FROM dual;
	  ELSE 
	      lc_trx_date_to:= NULL;
	  END IF;
	  
	  IF p_due_date_from IS NOT NULL
	  THEN
		  SELECT TO_CHAR(p_due_date_from,'DD-MON-YYYY') 
			INTO lc_due_date_from 
			FROM dual;
	  ELSE 
	      lc_due_date_from:= NULL;
	  END IF;
	  
	  IF p_due_date_to IS NOT NULL
	  THEN
		  SELECT TO_CHAR(p_due_date_to,'DD-MON-YYYY') 
			INTO lc_due_date_to
			FROM dual;
	  ELSE 
	      lc_due_date_to:= NULL;
	  END IF;
       
      fnd_file.put_line (fnd_file.log,'Input parameters .....:');
	  fnd_file.put_line (fnd_file.log,'Transaction Date from :' || lc_trx_date_from);
      fnd_file.put_line (fnd_file.log,'Transaction Date to :' || lc_trx_date_to);
	  fnd_file.put_line (fnd_file.log,'Due Date from :' || lc_due_date_from);
      fnd_file.put_line (fnd_file.log,'Due Date to :' || lc_due_date_to);
	  fnd_file.put_line (fnd_file.log,'Transaction amount from :' || p_amount_due_original_from);
      fnd_file.put_line (fnd_file.log,'Transaction amount to :' || p_amount_due_original_to);
	  fnd_file.put_line (fnd_file.log,'Customer Number :'|| p_customer_number);
	  fnd_file.put_line (fnd_file.log,'Status :' || p_status);
	  fnd_file.put_line (fnd_file.log,'Transaction type :' || p_transaction_type);
	  fnd_file.put_line (fnd_file.log,'Template type :' || p_template_type);
      fnd_file.put_line (fnd_file.log,'Mail from :'||lc_email_from);
      fnd_file.put_line (fnd_file.log,'Mail to :'|| p_mail_to);
	  fnd_file.put_line (fnd_file.log,'Mail cc :'|| p_mail_to);
	  
	IF p_transaction_type = 'INVOICES'
	THEN
        IF p_template_type = 'ARIINVHDR'   -- Invoice Header
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables Invoice Headers Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIINVHDR',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIINVHDR', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
							
		ELSIF p_template_type = 'ARIINVLI'  --Invoice Lines
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables Invoice Lines Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIINVLI',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIINVLI', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
		END IF;
	
	ELSIF  p_transaction_type = 'ALL_TRX'
	THEN
	    
		IF p_template_type = 'ARIALTXHDR'  --All Transactions Header
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables All Transactions Headers Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIALTXHDR',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIALTXHDR', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
	
        ELSIF p_template_type = 'ARIALTXLI' --All Transactions Lines
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables All Transactions Lines Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIALTXLI',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIALTXLI', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
							
		ELSIF p_template_type = 'XXARIALTXHDRLI' -- All Transactions Header And Lines
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables All Transactions Headers and Lines Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIALTXHDRLI',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIALTXHDRLI', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
		END IF;
		
	ELSIF p_transaction_type = 'ALL_DEBIT_TRX'
	THEN
	    IF p_template_type = 'ARIADBHDR' -- All Receivable Transactions Header
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables All Receivables Headers Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIADBHDR',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIADBHDR', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
							
		ELSIF p_template_type = 'ARIADBLI' -- All Receivable Transactions Lines
		THEN
		   fnd_file.put_line (fnd_file.log,'Submitting the OD: iReceivables All Receivables Lines Export Program to generate the Excel File :');
		   
		   lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXARIADBLI',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout 
			THEN
                 fnd_file.put_line (fnd_file.log,'successfully added the layout:');
            ELSE
                 fnd_file.put_line (fnd_file.log,'unsuccessfully added the layout:');
            END IF;
			
		   ln_request_id :=
						 fnd_request.submit_request (
							application   => 'XXFIN',     -- Application short name
							program       => 'XXARIADBLI', --- conc program short name
							description   => NULL,
							start_time    => NULL,
							sub_request   => FALSE,
							argument1     => lc_trx_date_from,
							argument2     => lc_trx_date_to,
							argument3     => lc_due_date_from,
							argument4     => lc_due_date_to,
							argument5     => p_amount_due_original_from,
							argument6     => p_amount_due_original_to,
							argument7     => p_session_id,
							argument8     => p_ship_to_site_use_id,
							argument9     => p_customer_number,
							argument10    => p_cust_account_id,
							argument11    => lc_ar_pmt_status,
							argument12    => lc_smtp_server,
							argument13    => lc_email_from,
							argument14    => p_mail_to,
							argument15    => p_mail_to);
		END IF;
    END IF;	
	 DBMS_OUTPUT.PUT_LINE(' Concurrent Request is :'|| ln_request_id);
     IF ln_request_id > 0
     THEN
     COMMIT;
	   fnd_file.put_line(fnd_file.log,'Able to submit the Report Program');
     ELSE
       fnd_file.put_line(fnd_file.log,'Failed to submit the Report Program to generate the output file - ' || SQLERRM);
	   x_retcode := 2;
	   x_errbuf  := 'FAIL';
     END IF;
	 
	 IF p_mail_to IS NOT NULL AND ln_request_id > 0
	 THEN
	    LOOP
	 
	      fnd_file.put_line (fnd_file.LOG, 'While Waiting Report Request to Finish');

		 -- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
							   request_id   => ln_request_id,
							   interval     => 5, --interval Number of seconds to wait between checks
							   max_wait     => 60, --Maximum number of seconds to wait for the request completion
							   phase        => lc_phase,
							   status       => lc_status,
							   dev_phase    => lc_dev_phase,
							   dev_status   => lc_dev_status,
							   message      => lc_message);
			EXIT
			WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
        END LOOP;
		
		IF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'ERROR' 
		THEN
           fnd_file.put_line (fnd_file.LOG,'The Report program completed in error. Oracle request id: '||ln_request_id ||' '||SQLERRM);
        ELSIF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'NORMAL' 
		THEN
           fnd_file.put_line (fnd_file.LOG, 'The Report program request successful for request id: ' || ln_request_id);

			fnd_file.put_line (fnd_file.LOG,'Submitting XML Bursting Program to email the output file');
            BEGIN				 
				ln_request :=fnd_request.submit_request (
							application   => 'XDO',     -- Application short name
							program       => 'XDOBURSTREP', --- conc program short name
							description   => NULL,
							start_time    => SYSDATE,
							sub_request   => FALSE,
							argument1     => NULL,
							argument2     => ln_request_id,
							argument3     => NULL);    
			COMMIT;				
			EXCEPTION
                WHEN OTHERS 
				THEN
                  dbms_output.put_line( 'OTHERS exception while submitting the Bursting Program: ' || SQLERRM);
            END;
			
        ELSE
			x_retcode := 2;
			x_errbuf  := 'FAIL';
        END IF;
			IF ln_request > 0
			THEN
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Able to submit the XML Bursting Program to e-mail the output file');
				DBMS_OUTPUT.PUT_LINE('Able to submit the XML Bursting Program to e-mail the output file');
			ELSE				
				DBMS_OUTPUT.PUT_LINE('Failed to submit the XML Bursting Program to e-mail the file - ' || SQLERRM);
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to submit the XML Bursting Program to e-mail the file - ' || SQLERRM);
				
			END IF;
     END IF; 
	  	  
	x_retcode := 0;
	x_errbuf  := 'SUCCESS';
		
    EXCEPTION
      WHEN OTHERS
       THEN
	      x_retcode := 2;
		  x_errbuf  := 'FAIL';
         fnd_file.put_line(fnd_file.log,'Unable to run the Report'|| SQLERRM);
   END EXTRACT;
END XX_AR_IREC_TRX_BULK_EXPORT_PKG;
/
SHOW ERRORS;
