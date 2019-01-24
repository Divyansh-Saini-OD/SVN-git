SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY xx_ar_ebl_cons_invoices

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE BODY XX_AR_EBL_RENDER_STUB_PKG AS

/*
-- +======================================================================================================+
-- |                                Office Depot - Project Simplify                                       |
-- +======================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_STUB_PKG                                                              |
-- | Description : Package body for eBilling remittance stub generation                                   |
-- |                                                                                                      |
-- |                                                                                                      |
-- |Change Record:                                                                                        |
-- |===============                                                                                       |
-- |Version   Date        Author               Remarks                                                    |
-- |========  =========== ==================   ===========================================================|
-- |1.0       15-Apr-2010 Bushrod Thomas       Initial draft version.      			 	                  |
-- |1.1       22-Jun-2015 Suresh Naragam	   Done Changes to get the additional  					      |
-- |                                           Columns data (Module 4B Release 1)(Proc : GET_STUB_XML)    |
-- |1.2       14-Mar-2017 Thilak Kumar(CG)	   Added condition to restrict FTP type remit for Defect#40073|
-- |                                                                                                      |
-- |1.3       14-Nov-2018 Sangita Deshmukh(CG) Added Logic blurb message for Remit Page                   |
-- |                                           Defect : NAIT-65564                                        |        
-- |1.4       01-Dec-2018 Thilak Kumar (CG)    Added to capture POD details in remit output               |
-- |                                           Defects : NAIT-70500 and NAIT-75181                        |        												|
-- +======================================================================================================+
*/

  -- ===========================================================================
  -- procedure for printing to the output
  -- ===========================================================================
 PROCEDURE put_out_line
  ( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
  IS
  BEGIN
    -- if in concurrent program, print to output file
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
      FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
    -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
  END put_out_line;


  -- ===========================================================================
  -- procedure for printing to the log
  -- ===========================================================================
  PROCEDURE put_log_line
  ( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
  IS
  BEGIN
    -- if in concurrent program, print to log file
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
      FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
    -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
  END put_log_line;

  -- ===========================================================================
  -- procedure for logging errors
  -- ===========================================================================
  PROCEDURE PUT_ERR_LINE (
    p_error_message IN VARCHAR2 := ' '
   ,p_attribute1   IN VARCHAR2 := null
   ,p_attribute2   IN VARCHAR2 := null
   ,p_attribute3   IN VARCHAR2 := null
  ) IS
  BEGIN
    XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'AR'
                                  ,p_program_name  => 'XX_AR_EBL_RENDER_STUB_PKG'
                                  ,p_attribute1    => p_attribute1
                                  ,p_attribute2    => p_attribute2
                                  ,p_attribute3    => p_attribute3
                                  ,p_attribute4    => fnd_global.user_name
                                  ,p_error_message => p_error_message
                                  ,p_created_by    => fnd_global.user_id);
  END PUT_ERR_LINE;


  -- ===========================================================================
  -- procedure for retrieving config translations
  -- ===========================================================================
  PROCEDURE GET_TRANSLATION(
    p_translation_name IN VARCHAR2
   ,p_source_value1    IN VARCHAR2
   ,p_source_value2    IN VARCHAR2
   ,x_target_value1    IN OUT NOCOPY VARCHAR2
  )
  IS
    ls_target_value1  VARCHAR2(240);
    ls_target_value2  VARCHAR2(240);
    ls_target_value3  VARCHAR2(240);
    ls_target_value4  VARCHAR2(240);
    ls_target_value5  VARCHAR2(240);
    ls_target_value6  VARCHAR2(240);
    ls_target_value7  VARCHAR2(240);
    ls_target_value8  VARCHAR2(240);
    ls_target_value9  VARCHAR2(240);
    ls_target_value10 VARCHAR2(240);
    ls_target_value11 VARCHAR2(240);
    ls_target_value12 VARCHAR2(240);
    ls_target_value13 VARCHAR2(240);
    ls_target_value14 VARCHAR2(240);
    ls_target_value15 VARCHAR2(240);
    ls_target_value16 VARCHAR2(240);
    ls_target_value17 VARCHAR2(240);
    ls_target_value18 VARCHAR2(240);
    ls_target_value19 VARCHAR2(240);
    ls_target_value20 VARCHAR2(240);
    ls_error_message  VARCHAR2(240);
  BEGIN
    xx_fin_translate_pkg.xx_fin_translatevalue_proc(
      p_translation_name => p_translation_name
     ,p_source_value1    => p_source_value1
     ,p_source_value2    => p_source_value2
     ,x_target_value1    => x_target_value1
     ,x_target_value2    => ls_target_value2
     ,x_target_value3    => ls_target_value3
     ,x_target_value4    => ls_target_value4
     ,x_target_value5    => ls_target_value5
     ,x_target_value6    => ls_target_value6
     ,x_target_value7    => ls_target_value7
     ,x_target_value8    => ls_target_value8
     ,x_target_value9    => ls_target_value9
     ,x_target_value10   => ls_target_value10
     ,x_target_value11   => ls_target_value11
     ,x_target_value12   => ls_target_value12
     ,x_target_value13   => ls_target_value13
     ,x_target_value14   => ls_target_value14
     ,x_target_value15   => ls_target_value15
     ,x_target_value16   => ls_target_value16
     ,x_target_value17   => ls_target_value17
     ,x_target_value18   => ls_target_value18
     ,x_target_value19   => ls_target_value19
     ,x_target_value20   => ls_target_value20
     ,x_error_message    => ls_error_message
    );
  END GET_TRANSLATION;


  -- ===========================================================================
  -- procedure for checking completion status of child concurrent programs
  -- ===========================================================================
  PROCEDURE CHECK_CHILD_REQUEST (
     p_request_id  IN OUT  NOCOPY  NUMBER
  ) IS
    call_status     boolean;
    rphase          varchar2(80);
    rstatus         varchar2(80);
    dphase          varchar2(30);
    dstatus         varchar2(30);
    message         varchar2(240);
  BEGIN
    call_status := FND_CONCURRENT.get_request_status(
                        p_request_id,
                        '',
                        '',
                        rphase,
                        rstatus,
                        dphase,
                        dstatus,
                        message);
    IF ((dphase = 'COMPLETE') and (dstatus = 'NORMAL')) THEN
      put_log_line( 'child request id: ' || p_request_id || ' completed successfully');
    ELSE
      put_log_line( 'child request id: ' || p_request_id || ' did not complete successfully');
    END IF;
  END CHECK_CHILD_REQUEST;


  PROCEDURE RENDER_STUB_P (
     Errbuf            OUT NOCOPY VARCHAR2
    ,Retcode           OUT NOCOPY VARCHAR2
  )
  IS
    ln_thread_count     NUMBER;
    n_conc_request_id   NUMBER := NULL;
    ls_req_data         VARCHAR2(240);
    ln_request_id       NUMBER;        -- parent request id
    cnt_warnings        INTEGER := 0;
    cnt_errors          INTEGER := 0;
    request_status      BOOLEAN;  
  BEGIN
    ls_req_data := fnd_conc_global.request_data;
    ln_request_id := fnd_global.conc_request_id;

    IF ls_req_data IS NOT NULL THEN
      put_log_line( ' Back at beginning after spawing ' || ls_req_data || ' threads.');
      ln_thread_count := ls_req_data;

      IF ln_thread_count > 0 THEN
        put_log_line ( 'Checking child threads...');

        -- Check all child requests to see how they finished...
        FOR child_request_rec IN (SELECT request_id, status_code
                                    FROM fnd_concurrent_requests
                                   WHERE parent_request_id = ln_request_id) LOOP
           check_child_request(child_request_rec.request_id);
          IF ( child_request_rec.status_code = 'G' OR child_request_rec.status_code = 'X'
            OR child_request_rec.status_code ='D' OR child_request_rec.status_code ='T'  ) THEN
              cnt_warnings := cnt_warnings + 1;
          ELSIF ( child_request_rec.status_code = 'E' ) THEN
              cnt_errors := cnt_errors + 1;
          END IF;
        END LOOP; -- FOR child_request_rec

        IF cnt_errors > 0 THEN
          put_log_line( 'Setting completion status to ERROR.');
          request_status := fnd_concurrent.set_completion_status('ERROR', '');
        ELSIF cnt_warnings > 0 THEN
          put_log_line( 'Setting completion status to WARNING.');      
          request_status := fnd_concurrent.set_completion_status('WARNING', '');  
        ELSE
          put_log_line( 'Setting completion status to NORMAL.');
          request_status := fnd_concurrent.set_completion_status('NORMAL', '');
        END IF;
      END IF;

      RETURN; -- end of parent
    END IF;

    get_translation('AR_EBL_CONFIG','RENDER_STUB','N_THREADS',ln_thread_count);
    IF ln_thread_count IS NULL THEN
      ln_thread_count := 1;
    END IF;

    put_log_line('spawning ' || ln_thread_count || ' thread(s)');

    FOR i IN 1..ln_thread_count LOOP
      put_log_line('thread: ' || i);

      n_conc_request_id :=
        FND_REQUEST.submit_request
        ( application    => 'XXFIN'                      -- application short name
         ,program        => 'XX_AR_EBL_RENDER_STUB_C'    -- concurrent program name
         ,sub_request    => TRUE                         -- is this a sub-request?
         ,argument1      => i                            -- thread_id
         ,argument2      => ln_thread_count);

      -- ===========================================================================
      -- if request was successful
      -- ===========================================================================
      IF (n_conc_request_id > 0) THEN
        -- ===========================================================================
        -- if a child request, then update it for concurrent mgr to process
        -- ===========================================================================
  /*    -- Instead of doing the following Update, use FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count)) -- See below
        -- This program will then restart when the child programs are done, so if fnd_conc_global.request_data is NOT NULL at start of proc, check child statuses and end.
        -- If either this Update, or the set_req_globals approach, is not done, the child programs will hang in Invalid, No Manager status.

          UPDATE fnd_concurrent_requests
             SET phase_code = 'P',
                 status_code = 'I'
           WHERE request_id = n_conc_request_id;
  */
        -- ===========================================================================
        -- must commit work so that the concurrent manager polls the request
        -- ===========================================================================
        COMMIT;

        put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

      -- ===========================================================================
      -- else errors have occured for request
      -- ===========================================================================
      ELSE
        -- ===========================================================================
        -- retrieve and raise any errors
        -- ===========================================================================
        FND_MESSAGE.raise_error;
      END IF;

    END LOOP;
  
    FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count));
  
  END RENDER_STUB_P;


  -- ===========================================================================
  -- procedure used by Java threads to determine which stubs need rendering
  -- ===========================================================================
  PROCEDURE STUBS_TO_RENDER (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER
   ,X_CURSOR      OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN X_CURSOR FOR

    SELECT F.file_id
      FROM XX_AR_EBL_FILE F
     WHERE F.status='RENDER'
       AND F.file_type='STUB'
       AND MOD(F.file_id,P_TREAD_COUNT)=P_TREAD_ID
       AND F.org_id=FND_GLOBAL.org_id
       AND NOT EXISTS (SELECT 1 
                         FROM XX_AR_EBL_TRANSMISSION
                        WHERE TRANSMISSION_ID = F.TRANSMISSION_ID
                          AND TRANSMISSION_TYPE = 'FTP') -- Added not exists condition for Defect#40073 by Thilak CG on 14-MAR-2017
     ORDER BY file_id;

  END STUBS_TO_RENDER;


  -- ===========================================================================
  -- procedure used by Java threads to get stub XML for a given file_id
  -- Note, this will throw an exception if any required attributes are null.
  -- ===========================================================================
  PROCEDURE GET_STUB_XML (
    P_FILE_ID IN NUMBER
   ,X_XML     OUT CLOB
  ) IS
    doc xmldom.DOMDocument;
    main_node xmldom.DOMNode;
    root_node xmldom.DOMNode;
    list_node xmldom.DOMNode;
    stub_node xmldom.DOMNode;
    item_node xmldom.DOMNode;
    root_elmt xmldom.DOMElement;
    item_elmt xmldom.DOMElement;
    item_text xmldom.DOMText;
--    l_loc NUMBER := 0;
--    l_anc NUMBER := 1;
--    l_text VARCHAR2(300);
  
    ls_bill_to_date             VARCHAR2(30);
    ls_invoice_amount           VARCHAR2(100);
	ls_message_bcc              VARCHAR2(1000):=NULL;  --Added for NAIT-65564
    ls_account_number           XX_AR_EBL_FILE.account_number%TYPE;
	ls_aops_customer_num	    XX_AR_EBL_FILE.aops_customer_number%TYPE;
    ls_customer_name            XX_AR_EBL_FILE.customer_name%TYPE;
    ls_cons_bill_number         XX_AR_EBL_FILE.cons_billing_number%TYPE;
    ls_remit_to_address         XX_AR_EBL_FILE.remit_address%TYPE;
    ls_flo_code                 XX_AR_EBL_FILE.flo_code%TYPE;
    ls_watermark                VARCHAR2(1000); -- := 'Please return the remittance stub below with your payment to ensure prompt credit to your account.';
	ld_bill_due_date		    DATE := NULL;
	lc_payment_terms		    VARCHAR2(150) := NULL;
	ld_payment_term_disc_date   VARCHAR2(30) := NULL;
	ln_total_merchandise_amt	NUMBER := 0;
	ln_total_salestax_amt		NUMBER := 0;
	ln_total_misc_amt		 	NUMBER := 0;
	ln_total_gift_card_amt		NUMBER := 0;
	-- Added below variables for Defect#NAIT-70500 by Thilak
    lc_invoice_num              VARCHAR2(30)  := NULL;
	lc_delivery_date            VARCHAR2(30)  := NULL;
    lc_consignee                VARCHAR2(200) := NULL;
	lc_pod_text                 VARCHAR2(100) := NULL;	
    lc_pod_image                CLOB := NULL;
	ln_pod_cnt                  NUMBER := 0;
	ln_customer_id              NUMBER := 0;
	ln_transmission_id          NUMBER := 0;


  -- Added below cursor for Defect#NAIT-70500 by Thilak 	 
  CURSOR lcu_pod_details(p_cons_inv VARCHAR2,p_customer_id NUMBER,p_transmission_id NUMBER)
  IS
    SELECT customer_trx_id
	  FROM XX_AR_EBL_CONS_HDR_HIST 
	 WHERE transmission_id = p_transmission_id 
	   AND consolidated_bill_number = p_cons_inv
       AND cust_account_id = p_customer_id;
	     
  BEGIN
--  SELECT TO_CHAR(SYSDATE,'DD-MON-RR'), '46078', 'ARCH COAL INC', '379169', '8360.68', 'PO Box 88040' || utl_tcp.CRLF || 'Chicago IL  60680-1040', '000460782 0000003791696 00000007178 1 1'
--  SELECT TO_CHAR(T.billing_dt,'RRRR-MM-DD') billing_dt,F.account_number,F.customer_name,F.cons_billing_number,F.total_due,F.remit_address,F.flo_code
    SELECT TO_CHAR(T.billing_dt,'DD-MON-RR') billing_dt,T.customer_id,T.transmission_id,F.account_number,F.customer_name,F.cons_billing_number,F.total_due,F.remit_address,F.flo_code,
			AOPS_CUSTOMER_NUMBER, TO_CHAR(F.bill_due_dt,'DD-MON-RR') bill_due_dt,
			--F.payment_terms, 
			T.pay_terms, TO_CHAR(F.discount_due_date,'DD-MON-RR') discount_due_date, nvl(F.total_merchandise_amt,0), nvl(F.total_sales_tax_amt,0), nvl(F.total_misc_amt,0), nvl(F.total_gift_card_amt,0)	--Module 4B Release 1
			,DECODE(xx_ar_ebl_common_util_pkg.get_cons_msg_bcc(t.customer_doc_id,f.cust_account_id,f.cons_billing_number),'X',NULL,xx_ar_ebl_common_util_pkg.get_cons_msg_bcc(t.customer_doc_id,f.cust_account_id,f.cons_billing_number)) cons_msg_bcc -- Added for NAIT-65564
      INTO ls_bill_to_date, ln_customer_id, ln_transmission_id, ls_account_number, ls_customer_name, ls_cons_bill_number, ls_invoice_amount, ls_remit_to_address, ls_flo_code,
		   ls_aops_customer_num, ld_bill_due_date, lc_payment_terms, ld_payment_term_disc_date, ln_total_merchandise_amt, ln_total_salestax_amt, ln_total_misc_amt, ln_total_gift_card_amt	--Module 4B Release 1
		   ,ls_message_bcc
      FROM XX_AR_EBL_TRANSMISSION T
      JOIN XX_AR_EBL_FILE F
        ON T.transmission_id = F.transmission_id
     WHERE F.file_id = P_FILE_ID AND F.file_type = 'STUB';

    get_translation('AR_EBL_CONFIG','RENDER_STUB','WATERMARK',ls_watermark);

    doc := xmldom.newDOMDocument;
  
    xmldom.setversion(doc, '1.0');
--  xmldom.setCharset(doc, 'UTF-8'); -- doesn't seem to do anything

    main_node := xmldom.makeNode(doc);

    root_elmt := xmldom.createElement(doc, 'XXAREBLREM');
    root_node := xmldom.appendChild(main_node, xmldom.makeNode(root_elmt)); 

    item_elmt := xmldom.createElement(doc,'LIST_G_CONS_INV_ID');
    list_node := xmldom.appendChild(root_node,xmldom.makeNode(item_elmt));

    item_elmt := xmldom.createElement(doc,'G_CONS_INV_ID');
    stub_node := xmldom.appendChild(list_node,xmldom.makeNode(item_elmt));

    item_elmt := xmldom.createElement(doc,'BILL_TO_DATE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_bill_to_date);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));

    item_elmt := xmldom.createElement(doc,'ORACLE_ACCOUNT_NUMBER');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_account_number);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));

    item_elmt := xmldom.createElement(doc,'CUSTOMER_NAME');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_customer_name);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));

    item_elmt := xmldom.createElement(doc,'CONSOLIDATED_BILL_NUMBER');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_cons_bill_number);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
  
    item_elmt := xmldom.createElement(doc,'CS_INVOICE_AMOUNT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_invoice_amount);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	--Added for NAIT-65564
    item_elmt := xmldom.createElement(doc,'CONS_MSG_BCC');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,ls_message_bcc); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text)); 	
  
    item_elmt := xmldom.createElement(doc,'CF_REMIT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_remit_to_address);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));

    item_elmt := xmldom.createElement(doc,'CF_FLO_CODE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_flo_code);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'BILL_DUE_DATE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ld_bill_due_date);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	--Module 4B Release 1 Start
	item_elmt := xmldom.createElement(doc,'AOPS_CUSTOMER_NUMBER');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ls_aops_customer_num);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'PAYMENT_TERMS');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,lc_payment_terms);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'PAYMENT_DISC_DUE_DATE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ld_payment_term_disc_date);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'TOTAL_MERCHANDISE_AMT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ln_total_merchandise_amt);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'TOTAL_SALESTAX_AMT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ln_total_salestax_amt);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'TOTAL_MISC_AMT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ln_total_misc_amt);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	
	item_elmt := xmldom.createElement(doc,'TOTAL_GIFT_CARD_AMT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt));
    item_text := xmldom.createTextNode(doc,ln_total_gift_card_amt);
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
	--Module 4B Release 1 End
	
   -- Added below loop for Defect#NAIT-70500 by Thilak	
   ln_pod_cnt := 0;
   FOR fetch_pod_details_rec IN lcu_pod_details(ls_cons_bill_number,ln_customer_id,ln_transmission_id)
   LOOP
    lc_invoice_num     := NULL;
	lc_pod_image       := NULL;
	lc_pod_text        := NULL;
	lc_delivery_date   := NULL;
    lc_consignee       := NULL;
	
	BEGIN
		SELECT xx_ar_ebl_pod_invoices_pkg.getbase64string(NVL(xx_ar_ebl_pod_invoices_pkg.resize_image(fetch_pod_details_rec.customer_trx_id),pod_image)),
			   TO_CHAR(delivery_date,'DD-MON-YYYY HH24:MI:SS'),
			   consignee
		  INTO lc_pod_image,
			   lc_delivery_date,
			   lc_consignee	  
		  FROM xx_ar_ebl_pod_dtl
		 WHERE customer_trx_id = fetch_pod_details_rec.customer_trx_id;
	EXCEPTION
     WHEN OTHERS THEN
       NULL;
    END;
	
	BEGIN
		SELECT trx_number
		  INTO lc_invoice_num 
	      FROM ra_customer_trx_all
		 WHERE customer_trx_id = fetch_pod_details_rec.customer_trx_id;
	EXCEPTION
     WHEN OTHERS THEN
       NULL;
    END;	

    -- Added below condition for Defect#NAIT-75181 by Thilak		
    IF lc_pod_image IS NULL 
    THEN
	  lc_pod_text := 'Signature Not Available';
	END IF;
	
    IF lc_pod_image IS NULL AND lc_delivery_date IS NULL AND lc_consignee IS NULL 
	THEN
	  lc_pod_text := 'Delivery Details Not Available';
	END IF;
	-- End of Defect#NAIT-75181
	
	IF lc_invoice_num IS NOT NULL
    THEN	
	item_elmt := xmldom.createElement(doc,'POD_INVOICE_LOOP');
    stub_node := xmldom.appendChild(list_node,xmldom.makeNode(item_elmt));	
	
    item_elmt := xmldom.createElement(doc,'POD_INVOICE_NUM');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,lc_invoice_num); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text)); 

    item_elmt := xmldom.createElement(doc,'POD_IMAGE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,lc_pod_image); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));

    -- Added below element for Defect#NAIT-75181 by Thilak	
    item_elmt := xmldom.createElement(doc,'POD_TEXT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,lc_pod_text); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));	
    -- End of Defect#NAIT-75181
	
    item_elmt := xmldom.createElement(doc,'POD_DELIVERY_DATE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,lc_delivery_date); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text)); 	

    item_elmt := xmldom.createElement(doc,'POD_CONSIGNEE');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,lc_consignee); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text)); 	

	ln_pod_cnt := 1;
	END IF;
    END LOOP;
   
    item_elmt := xmldom.createElement(doc,'POD_COUNT');
    item_node := xmldom.appendChild(stub_node,xmldom.makeNode(item_elmt)); 
    item_text := xmldom.createTextNode(doc,ln_pod_cnt); 
    item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));	
   -- End loop for Defect#NAIT-70500 by Thilak
   
    item_elmt := xmldom.createElement(doc,'CP_WATERMARK_MSG');
    item_node := xmldom.appendChild(root_node,xmldom.makeNode(item_elmt));
    IF ls_watermark IS NOT NULL THEN 
      item_text := xmldom.createTextNode(doc,ls_watermark); 
      item_node := xmldom.appendChild(item_node,xmldom.makeNode(item_text));
    END IF;
	
    DBMS_LOB.CreateTemporary(X_XML, TRUE);
--  xmldom.writeToCLOB(doc,clobStub,'UTF-8');
    xmldom.writeToCLOB(doc,X_XML);
/*
    LOOP
      l_loc := dbms_lob.instr(clobStub, chr(10), l_anc);
      l_text := dbms_lob.substr(clobStub, l_loc - l_anc, l_anc);
      l_anc := l_loc + 1;
      DBMS_OUTPUT.PUT_LINE(l_text);
      EXIT WHEN l_loc = 0;
    END LOOP;
*/
    xmldom.freeDocument(doc);
  END GET_STUB_XML;

  -- ===========================================================================
  -- procedure to show XML output from GET_STUB_XML (for debugging)
  -- ===========================================================================
  PROCEDURE SHOW_STUB_XML (
    P_FILE_ID IN NUMBER
  ) IS
    clobStub CLOB;
    l_loc NUMBER := 0;
    l_anc NUMBER := 1;
    l_text VARCHAR2(300);
  BEGIN
    XX_AR_EBL_RENDER_STUB_PKG.get_stub_xml(P_FILE_ID,clobStub);

    LOOP
      l_loc := dbms_lob.instr(clobStub, chr(10), l_anc);
      l_text := dbms_lob.substr(clobStub, l_loc - l_anc, l_anc);
      l_anc := l_loc + 1;
      DBMS_OUTPUT.PUT_LINE(l_text);
      EXIT WHEN l_loc = 0;
    END LOOP;
    DBMS_LOB.FREETEMPORARY(clobStub);
  END SHOW_STUB_XML;
  
  
  -- ===========================================================================
  -- procedure to show list of file id's from STUBS_TO_RENDER (for debugging)
  -- ===========================================================================  
  PROCEDURE SHOW_STUBS_TO_RENDER (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER
  ) IS
    lc_files           SYS_REFCURSOR;
    ln_file_id         XX_AR_EBL_FILE.file_id%TYPE;
  BEGIN
    STUBS_TO_RENDER(P_TREAD_ID,P_TREAD_COUNT,lc_files);
    LOOP
      FETCH lc_files INTO ln_file_id;
      EXIT WHEN lc_files%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('file_id ' || ln_file_id);
    END LOOP;
    CLOSE lc_files;
  END SHOW_STUBS_TO_RENDER;

END XX_AR_EBL_RENDER_STUB_PKG;

/

SHOW ERR
