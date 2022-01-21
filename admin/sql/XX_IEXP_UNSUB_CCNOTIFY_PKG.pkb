SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET DEFINE OFF;
set serveroutput on;

CREATE OR REPLACE PACKAGE BODY APPS.XX_IEXP_UNSUB_CCNOTIFY_PKG
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- +============================================================================+
-- | Name        :  XX_IEXP_UNSUB_CCNOTIFY_PKG.pkb		                |
-- | Description :  Plsql package for Iexpenses Unsubmitted CC Txns Notification|
-- | RICE ID     : E3117                                                        |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author             Remarks                            |
-- |========  =========== ================== ===================================|
-- |1.0       05-May-2015 Paddy Sanjeevi     Initial version                    |
-- |1.1       20-May-2015 Paddy Sanjeevi     Modified to send mail in HTML      |
-- |1.2       30-Dec-2015 Harvinder Rakhra   Retrofit R12.2                     |
-- |1.3       03-JUN-2018 Dinesh Nagapuri    Replaced V$INSTANCE with DB_Name for LNS|
-- +============================================================================+
AS


-- +======================================================================+
-- | Name        :  get_address                                           |
-- | Description :  This function returns valid email address to be used  |
-- |                in smtp conn                                          |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+


FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
    addr VARCHAR2(256);
    i    pls_integer;
    FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                  chrs IN VARCHAR2) RETURN pls_integer AS
      c            VARCHAR2(5);
      i            pls_integer;
      len          pls_integer;
      inside_quote BOOLEAN;
    BEGIN
       inside_quote := false;
       i := 1;
       len := length(str);
       WHILE (i <= len) LOOP
     c := substr(str, i, 1);
     IF (inside_quote) THEN
       IF (c = '"') THEN
         inside_quote := false;
       ELSIF (c = '\') THEN
         i := i + 1; -- Skip the quote character
       END IF;
       GOTO next_char;
     END IF;
     IF (c = '"') THEN
       inside_quote := true;
       GOTO next_char;
     END IF;
     IF (instr(chrs, c) >= 1) THEN
        RETURN i;
     END IF;
     <<next_char>>
     i := i + 1;
       END LOOP;
       RETURN 0;
    END;
  BEGIN
    addr_list := ltrim(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr := addr_list;
      addr_list := '';
    END IF;
    i := lookup_unquoted_char(addr, '<');
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
    addr := substr(addr, 1, i - 1);
      END IF;
    END IF;
    RETURN addr;
  END get_address;


-- +======================================================================+
-- | Name        :  get_distribution_list                                 |
-- | Description :  This function gets email distribution list from       |
-- |                the translation                                       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

FUNCTION get_distribution_list 
RETURN VARCHAR2
IS

  lc_first_rec  	VARCHAR2(1);
  lc_temp_email 	VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;

  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL 		TYPE_TAB_EMAIL;

BEGIN

     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_IEXP_EMAIL_LIST'
       AND   source_value1    = 'DELETE_ER';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..10 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
	
       IF lc_temp_email IS NULL THEN

	  lc_temp_email:='iexpense-admin@officedepot.com';

       END IF;

       RETURN(lc_temp_email);
     EXCEPTION
       WHEN others then
         lc_temp_email:='iexpense-admin@officedepot.com';
         RETURN(lc_temp_email);
     END;
END get_distribution_list;

-- +======================================================================+
-- | Name        :  get_supervisor_email                                  |
-- | Description :  This function gets supervisor id and email            |
-- |                                                                      |
-- | Parameters  :  p_person_id                                           |
-- |                                                                      |
-- | Returns     :  p_manager_id                                          |
-- |                p_mrg_email                                           |
-- |                                                                      |
-- +======================================================================+

FUNCTION get_supervisor_email(p_person_id IN NUMBER,p_manager_id OUT NUMBER,p_mgr_email OUT VARCHAR2)
RETURN BOOLEAN
IS

BEGIN
  SELECT c.person_id,c.email_address
    INTO p_manager_id,p_mgr_email
    FROM per_all_people_f c, 
         PER_ASSIGNMENTS_V7 b,
         per_all_people_f a
   WHERE a.person_id=p_person_id
     AND sysdate between a.effective_start_date and a.effective_end_date
     AND b.person_id=a.person_id
     AND sysdate between b.effective_start_date and b.effective_end_date
     AND c.person_id=b.supervisor_id
     AND sysdate between c.effective_start_date and c.effective_end_date
     AND NOT EXISTS (SELECT 'x'
		     FROM per_jobs job,
			  PER_ASSIGNMENTS_V7 asn
		    WHERE asn.person_id=c.person_id
		      AND job.job_id=asn.job_id
		      AND job.approval_authority=180
	    	  );
     RETURN(TRUE);
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'When others in getting supervisor email : '||TO_CHAR(p_person_id)||','|| SQLERRM);    
    RETURN(TRUE);
END get_supervisor_email;
 

-- +======================================================================+
-- | Name        :  xx_iexp_unsub_ccntfy_emp                              |
-- | Description :  This procedure will be called from the concurrent prog|
-- |               "OD: Iexpenses Unsubmitted Txns Employee Notification" |
-- |                to send notification to emp who have unsubmitted cc   |
-- |                txns which are more than 14 days old                  |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_iexp_unsub_ccntfy_emp ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
  		                   )
IS

v_mgr_id 		NUMBER;
v_mgr_email 		VARCHAR2(100);
v_emp_email		VARCHAR2(2000);
v_check 		BOOLEAN;
v_person_id		NUMBER;
v_instance		VARCHAR2(25);

v_email_list    	VARCHAR2(2000);
v_subject		VARCHAR2(500);
conn 			utl_smtp.connection;
v_text			VARCHAR2(2000);
v_dtotal_amt		VARCHAR2(50);
v_emp_reminder		NUMBER;
v_debug			VARCHAR2(1);

CURSOR C1(p_days NUMBER) IS
SELECT COUNT(txn.trx_id) Total_Txn,
       NVL(sum(txn.transaction_amount),0) Total_Amt,
       MIN(txn.transaction_date) txn_date,
       per.employee_number,
       per.full_name,
       per.email_address,
       per.person_id
  FROM per_all_people_f per,
       ap_credit_card_trxns_all txn,
       ap_cards_all crd
 WHERE txn.validate_code = 'Y'
   AND txn.payment_flag <> 'Y'
   AND txn.billed_amount IS NOT NULL
   AND txn.card_id=crd.card_id
   AND txn.card_program_id = crd.card_program_id
   AND txn.card_id = crd.card_id
   AND (NVL (txn.CATEGORY, 'BUSINESS') NOT IN ('DISPUTED', 'CREDIT', 'MATCHED', 'DEACTIVATED'))
   AND TRUNC (NVL (txn.trx_available_date,TO_DATE ('01-01-1952 00:00:00','DD-MM-YYYY HH24:MI:SS'))) <= TRUNC (SYSDATE)
   AND txn.report_header_id IS NULL
   AND per.person_id=crd.employee_id
   AND sysdate between per.effective_start_date and per.effective_end_date
   AND NOT EXISTS (SELECT 'x'
		     FROM per_jobs job,
			  PER_ASSIGNMENTS_V7 asn
		    WHERE asn.person_id=per.person_id
		      AND job.job_id=asn.job_id
		      AND job.approval_authority=180
	    	  )
   AND txn.transaction_date<(SYSDATE-p_days)
 GROUP BY per.employee_number,per.full_name,per.email_address,per.person_id;

BEGIN

  BEGIN
    SELECT  TV.target_value1,tv.target_value3
      INTO  v_emp_reminder,v_debug
      FROM  XX_FIN_TRANSLATEVALUES TV
           ,XX_FIN_TRANSLATEDEFINITION TD
     WHERE  TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND  TRANSLATION_NAME = 'XX_IEXP_UNSUB_TXN_NTFY';
  EXCEPTION
    WHEN others THEN
      v_emp_reminder:=14;
      v_debug:='N';
  END;

	--SELECT name INTO v_instance from v$database;
  
	SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from V$database to DB_NAME
	INTO v_instance
	FROM dual;

  FOR cur IN C1(v_emp_reminder) LOOP

    v_text:=NULL;
   
    v_emp_email:=cur.email_address;

    IF cur.email_address like 'ods%' THEN

       v_person_id:=cur.person_id; 

       FOR i IN 1..5 LOOP

         v_check:=get_supervisor_email(v_person_id,v_mgr_id,v_mgr_email);

         IF v_debug='Y' THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'In the LOOP ODS, '||TO_CHAR(i)||', '||TO_CHAR(v_mgr_id)||','||v_mgr_email);

         END IF;

         IF v_mgr_email NOT LIKE 'ods%' THEN
	    EXIT;
         END IF;

          v_person_id	:=v_mgr_id;

       END LOOP;

       v_emp_email:=v_mgr_email;

    END IF;
	
    IF ( v_emp_email IS NULL OR v_emp_email like 'ods%') THEN
 
         v_emp_email:='iexpense-admin@officedepot.com';
    
    END IF;

    v_subject   :='Action Required: Unsubmitted credit card transactions awaiting submission';

    IF v_instance<>'GSIPRDGB' THEN

       v_email_list:=get_distribution_list;
       v_emp_email:=v_email_list;
       v_subject:=v_instance||' Please Ignore this mail :'||v_subject;  
 
    END IF;

    v_dtotal_amt  :=TRIM(TO_CHAR(cur.Total_Amt, '$999G999G999D99'));


    v_text := 'Cardholder Name: '||cur.full_name ||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'You are receiving this email because the cardholder above has outstanding Credit Card transaction(s)';
    v_text   :=v_text ||' older than 2 weeks that have not been submitted on an expense report.'||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'The cardholder must log in to iExpense and submit an Expense Report(s) with all unsubmitted credit card ';
    v_text   :=v_text ||'transactions and include all required receipts. Late fees are not reimbursable by Office Depot. ';
    v_text   :=v_text ||'Late fees must be categorized as personal on your Expense Report and personally paid to JPMorgan.'||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'If an Expense Report is not submitted this week, aged transactions will be escalated for resolution.'||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Per the Global Travel Policy, located on the Indirect Procurement Travel site, personal spend is prohibited on the Corporate Travel card. The JP Morgan Chase MasterCard ';
    v_text   :=v_text ||'is to be used for Business Purposes Only. If any of these transactions were for personal charges, the cardholder ';
    v_text   :=v_text ||'is required to submit an expense report and categorize these as personal in order to clear these from iExpense. ';
    v_text   :=v_text ||'For all personal charges, the cardholder must pay JP Morgan directly.'||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Unsubmitted # of credit card transactions: '||TO_CHAR(cur.Total_Txn)||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Total Transactions: '||v_dtotal_amt||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Oldest Transaction Date: '||TO_CHAR(cur.txn_date,'DD-MON-RR')||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Please direct any inquires to iexpense-admin@officedepot.com.'||chr(10);


    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address :'||v_emp_email);

    conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_emp_email,
			cc_recipients=>NULL,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

    xx_pa_pb_mail.attach_text( conn => conn,
  		               data => v_text
			     );

    xx_pa_pb_mail.end_mail( conn => conn );

  END LOOP;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in the procedure xx_iexp_unsub_ccntfy_emp : '||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_iexp_unsub_ccntfy_emp;



-- +======================================================================+
-- | Name        :  xx_iexp_unsub_ccntfy_mgr                              |
-- | Description :  This procedure will be called from the concurrent prog|
-- |               "OD: Iexpenses Unsubmitted Txns Manager Notification"  |
-- |                to send notification to employee's supervisor who have|
-- |                unsubmitted cc txns which are more than 14 days old   |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_iexp_unsub_ccntfy_mgr ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
    		                   )
IS

v_mgr_id 		NUMBER;
v_mgr_email 		VARCHAR2(100);
v_emp_email		VARCHAR2(2000);
v_check 		BOOLEAN;
v_person_id		NUMBER;
v_instance		VARCHAR2(25);

v_email_list    	VARCHAR2(2000);
v_subject		VARCHAR2(500);
conn 			utl_smtp.connection;
v_text			VARCHAR2(2000);
v_dtotal_amt		VARCHAR2(50);
v_manager_esc		NUMBER;
v_debug			VARCHAR2(1);

CURSOR C1(p_days NUMBER) IS
SELECT COUNT(txn.trx_id) Total_Txn,
       NVL(sum(txn.transaction_amount),0) Total_Amt,
       MIN(txn.transaction_date) txn_date,
       per.employee_number,
       per.full_name,
       per.email_address,
       per.person_id
  FROM per_all_people_f per,
       ap_credit_card_trxns_all txn,
       ap_cards_all crd
 WHERE txn.validate_code = 'Y'
   AND txn.payment_flag <> 'Y'
   AND txn.billed_amount IS NOT NULL
   AND txn.card_id=crd.card_id
   AND txn.card_program_id = crd.card_program_id
   AND txn.card_id = crd.card_id
   AND (NVL (txn.CATEGORY, 'BUSINESS') NOT IN ('DISPUTED', 'CREDIT', 'MATCHED', 'DEACTIVATED'))
   AND TRUNC (NVL (txn.trx_available_date,TO_DATE ('01-01-1952 00:00:00','DD-MM-YYYY HH24:MI:SS'))) <= TRUNC (SYSDATE)
   AND txn.report_header_id IS NULL
   AND per.person_id=crd.employee_id
   AND sysdate between per.effective_start_date and per.effective_end_date
   AND NOT EXISTS (SELECT 'x'
		     FROM per_jobs job,
			  PER_ASSIGNMENTS_V7 asn
		    WHERE asn.person_id=per.person_id
		      AND job.job_id=asn.job_id
		      AND job.approval_authority=180
	    	  )
   AND txn.transaction_date<(SYSDATE-p_days)
 GROUP BY per.employee_number,per.full_name,per.email_address,per.person_id;

BEGIN

  BEGIN
    SELECT  TV.target_value2,tv.target_value3
      INTO  v_manager_esc,v_debug
      FROM  XX_FIN_TRANSLATEVALUES TV
           ,XX_FIN_TRANSLATEDEFINITION TD
     WHERE  TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND  TRANSLATION_NAME = 'XX_IEXP_UNSUB_TXN_NTFY';
  EXCEPTION
    WHEN others THEN
      v_manager_esc:=21;
      v_debug:='N';
  END;

 	--SELECT name INTO v_instance from v$database;
  
	SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from V$database to DB_NAME
	INTO v_instance
	FROM dual;

  FOR cur IN C1(v_manager_esc) LOOP

    v_text:=NULL;
   
    v_check:=get_supervisor_email(cur.person_id,v_mgr_id,v_mgr_email);

    IF v_mgr_email LIKE 'ods%' THEN

       FOR i IN 1..5 LOOP

  	    v_person_id	:=v_mgr_id;

            v_check:=get_supervisor_email(v_person_id,v_mgr_id,v_mgr_email);

	    IF v_debug='Y' THEN

	       FND_FILE.PUT_LINE(FND_FILE.LOG,'In the LOOP ODS, '||TO_CHAR(i)||', '||TO_CHAR(v_mgr_id)||','||v_mgr_email);

	    END IF;

            IF v_mgr_email NOT LIKE 'ods%' THEN
	       EXIT;
            END IF;
 
       END LOOP;

       v_emp_email:=v_mgr_email;

    ELSE

       v_emp_email:=v_mgr_email;

    END IF;

    IF ( v_emp_email IS NULL OR v_emp_email like 'ods%') THEN
 
         v_emp_email:='iexpense-admin@officedepot.com';
    
    END IF;

    v_subject   :='***ACTION REQUIRED*** T & E Transactions for Your Employee';

    IF v_instance<>'GSIPRDGB' THEN

       v_email_list:=get_distribution_list;
       v_emp_email:=v_email_list;
       v_subject:=v_instance||' Please Ignore this mail :'||v_subject;  
 
    END IF;

    v_dtotal_amt  :=TRIM(TO_CHAR(cur.Total_Amt, '$999G999G999D99'));

    v_text   :=v_text ||chr(10);
    v_text := 'Employee Name: '||cur.full_name ||chr(10);
    v_text   :=v_text ||chr(10);


    v_text   :=v_text ||'Your employee listed above has aged transactions in iExpense that are 21 days or older and have not';
    v_text   :=v_text ||' been submitted on an expense report. Prior notification was sent to your employee; however,';
    v_text   :=v_text ||' sufficient action has not been taken to get these transactions processed. Please review with your';
    v_text   :=v_text ||' employee and have them submit the expense report(s) this week to clear these transactions. All';
    v_text   :=v_text ||' charges for late fees are not reimbursable and your employee must categorize as personal and pay JP Morgan directly.'||chr(10);
    v_text   :=v_text ||chr(10);

    v_text   :=v_text ||'If you have previously rejected the expense report(s), please follow up with your employee to ensure';
    v_text   :=v_text ||' the expense report is resubmitted for your approval.'||chr(10);
    v_text   :=v_text ||chr(10);

    v_text   :=v_text ||'Per the Global Travel Policy, located on the Indirect Procurement Travel site, personal spend is prohibited on the Corporate Travel card. The JP Morgan Chase MasterCard ';
    v_text   :=v_text ||'is to be used for Business Purposes Only. If any of these transactions were for personal charges, the cardholder ';
    v_text   :=v_text ||'is required to submit an expense report and categorize these as personal in order to clear these from iExpense. ';
    v_text   :=v_text ||'For all personal charges, the cardholder must pay JP Morgan directly.'||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Unsubmitted # of credit card transactions: '||TO_CHAR(cur.Total_Txn)||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Total Transactions: '||v_dtotal_amt||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Oldest Transaction Date: '||TO_CHAR(cur.txn_date,'DD-MON-RR')||chr(10);
    v_text   :=v_text ||chr(10);
    v_text   :=v_text ||'Please direct any inquires to iexpense-admin@officedepot.com.'||chr(10);


    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address :'||v_emp_email);

    conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_emp_email,
			cc_recipients=>NULL,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

    xx_pa_pb_mail.attach_text( conn => conn,
  		               data => v_text
			     );

    xx_pa_pb_mail.end_mail( conn => conn );

  END LOOP;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in the procedure xx_iexp_unsub_ccntfy_mgr : '||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_iexp_unsub_ccntfy_mgr;
 

-- +======================================================================+
-- | Name        :  xx_iexp_unaprv_mgr_ntfy                               |
-- | Description :  This procedure will be called from the concurrent prog|
-- |               "OD: Iexpenses Unapproved Expense Report Notification" |
-- |                to send notification to employee's supervisor who have|
-- |                expense report which are Pending Manager Status and   |
-- |                are more than 3 days old                              |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_iexp_unaprv_mgr_ntfy ( x_errbuf      	OUT NOCOPY VARCHAR2
                                   ,x_retcode     	OUT NOCOPY VARCHAR2
                		  )
IS

CURSOR C1(p_esc_days NUMBER) IS
SELECT distinct emp.person_id,emp.full_name,emp.email_address
  FROM per_jobs job,
       per_assignments_v7 asn,
       per_all_people_f emp
 where SYSDATE BETWEEN emp.effective_start_date AND emp.effective_end_date
   AND asn.person_id=emp.person_id
   AND SYSDATE BETWEEN asn.effective_start_date AND asn.effective_end_date
   AND job.job_id=asn.job_id
   AND job.approval_authority<>180
   AND EXISTS (SELECT 'x'
                 FROM ap_expense_report_headers_all
                WHERE override_approver_id=emp.person_id
                  AND expense_status_code='PENDMGR'
		  AND report_submitted_date<(SYSDATE-p_esc_days)
              );


CURSOR C2(p_mgr_id NUMBER) IS
SELECT RPAD(emp.full_name,50,' ') full_name,
       RPAD(emp.employee_number,11,' ') emp_no,
       RPAD(b.invoice_num,16,' ') invoice_no,
       RPAD(TO_CHAR(b.total, '$999G999G999D99'),16,' ') total,
       b.report_submitted_date
  FROM per_all_people_f emp,
       ap_expense_report_headers_all b
 WHERE b.override_approver_id=p_mgr_id
   AND b.expense_status_code='PENDMGR'
   AND emp.person_id=b.employee_id
   AND SYSDATE BETWEEN emp.effective_start_date AND emp.effective_end_date
   order by 1,3;


v_mgr_id 		NUMBER;
v_mgr_email 		VARCHAR2(100);
v_emp_email		VARCHAR2(2000);
v_check 		BOOLEAN;
v_person_id		NUMBER;
v_instance		VARCHAR2(25);

v_email_list    	VARCHAR2(2000);
v_subject		VARCHAR2(500);
conn 			utl_smtp.connection;
v_text			VARCHAR2(2000);
v_dtotal_amt		VARCHAR2(50);
v_debug			VARCHAR2(1);
v_mgr_esc		NUMBER;
v_smtp_hostname    	VARCHAR2 (120):=FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
l_body             	VARCHAR2 (32767);
l_new_line         	VARCHAR2 (1) := fnd_global.newline;
lc_body_hdr_html 	VARCHAR2(2000);
v_html             	VARCHAR2(32767);
v_from VARCHAR2 (140) := 'ODIexpenses@officedepot.com';
v_send_mail_list	VARCHAR2(2000);

BEGIN

  BEGIN
    SELECT  tv.target_value3,tv.target_value4
      INTO  v_debug,v_mgr_esc
      FROM  XX_FIN_TRANSLATEVALUES TV
           ,XX_FIN_TRANSLATEDEFINITION TD
     WHERE  TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND  TRANSLATION_NAME = 'XX_IEXP_UNSUB_TXN_NTFY';
  EXCEPTION
    WHEN others THEN
      v_debug:='N';
      v_mgr_esc:=3;
  END;

  	--SELECT name INTO v_instance from v$database;
  
	SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from V$database to DB_NAME
	INTO v_instance
	FROM dual;

  lc_body_hdr_html := '<p>Your employee(s) shown below has submitted expense reports in iExpense that have not been approved or rejected by you. 
 	                    Please review the list below and either approve or reject the expense report(s) this week to clear these transactions.
	                    As a reminder, late fees are not reimbursable by Office Depot and must be paid directly to JPMorgan by your employee.
  	                 </p>
	   	         <p>If you reject the expense report(s), please follow up with your employee to ensure the expense report is resubmitted
	                    for your approval in a timely manner.
 	                 </p>';

  FOR cur IN C1(v_mgr_esc) LOOP

    l_body	:=NULL;
    v_emp_email	:=NULL;
    v_send_mail_list:=NULL;
   
    IF cur.email_address LIKE 'ods%' THEN

       v_person_id:=cur.person_id;

       FOR i IN 1..5 LOOP

          v_check:=get_supervisor_email(v_person_id,v_mgr_id,v_mgr_email);

	    IF v_debug='Y' THEN

	       FND_FILE.PUT_LINE(FND_FILE.LOG,'In the LOOP ODS, '||TO_CHAR(i)||', '||TO_CHAR(v_mgr_id)||','||v_mgr_email);

	    END IF;


          IF v_mgr_email NOT LIKE 'ods%' THEN
             EXIT;
          END IF;

	  v_person_id:=v_mgr_id;

       END LOOP;

       v_emp_email:=v_mgr_email;

    ELSE

       v_emp_email:=cur.email_address;

    END IF;

    IF ( v_emp_email IS NULL OR v_emp_email like 'ods%') THEN
 
         v_emp_email:='iexpense-admin@officedepot.com';
    
    END IF;

    v_subject   :='Action Required - You have Expense Report(s) pending your approval';

    IF v_instance<>'GSIPRDGB' THEN

       v_email_list:=get_distribution_list;
       v_emp_email:=v_email_list;
       v_subject:=v_instance||' Please Ignore this mail :'||v_subject;  
 
    END IF;

    v_send_mail_list:=v_emp_email;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address :'||v_emp_email);

    l_body :='<HTML> <CENTER>  <small> <FONT size="3" face="Arial">'
            || '<B>'
            || 'Expense Report(s) pending your approval'
            || '</B>'
            || '</small> </CENTER>';
    l_body := l_body || '<BR />';

    l_body :=l_body
            || '<TABLE BORDER=1 BGCOLOR="#D8D8D8" CELLPADDING=2 CELLSPACING=2>'
            || CHR (10);

    l_body := l_body || '<TR BGCOLOR="SkyBlue">' || CHR (10);
    l_body := l_body
            || '<TH WIDTH="15%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Employee Name</FONT>'
            || CHR (10);

    l_body := l_body
            || '<TH WIDTH="8%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Employee ID</FONT>'
            || CHR (10);
    l_body := l_body
            || '<TH WIDTH="10%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Expense Report#</FONT>'
            || CHR (10);

    l_body := l_body
            || '<TH WIDTH="10%" ALIGN="RIGHT"><FONT size="2" face="verdana" COLOR="BLACK">Report Amount</FONT>'
            || CHR (10);

    l_body := l_body
            || '<TH WIDTH="8%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Report Date</FONT>'
            || CHR (10);

    l_body := l_body || '</TR>' || CHR (10);

    FOR cr IN C2(cur.person_id) LOOP

           -- Print First Table

            l_body := l_body || '<TR>';
            l_body := l_body || '<TR BGCOLOR="WhiteSmoke">' || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || cr.full_name
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || cr.emp_no
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || cr.invoice_no
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD ALIGN="RIGHT" >'
                || '<FONT size="2" face="verdana">'
                || cr.total
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || TO_CHAR(cr.report_submitted_date,'DD-MON-RR')
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body := l_body || '</TR>' || CHR (10);
    
    END LOOP;

    l_body := l_body || '</TABLE>' || CHR (10);
    l_body := l_body || l_new_line || '<BR />' || CHR (10);
    l_body := l_body || '</TABLE>' || CHR (10);
    v_html := l_body;

    conn := utl_smtp.open_connection(v_smtp_hostname,25);
    utl_smtp.helo(conn,v_smtp_hostname);
    utl_smtp.mail(conn,v_from);

    WHILE (v_emp_email IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(v_emp_email));
    END LOOP;

    utl_smtp.data(conn,'Return-Path: ' || v_from || utl_tcp.crlf ||
                'Sent: ' || TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') || utl_tcp.crlf ||
                'From: ' || v_from || utl_tcp.crlf ||
                'Subject: ' || v_subject  ||utl_tcp.crlf ||
                'To: ' || v_send_mail_list || utl_tcp.crlf ||
                'Content-Type: multipart/mixed; boundary="MIME.Bound"' ||utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound' || utl_tcp.crlf ||
                'Content-Type: multipart/alternative; boundary="MIME.Bound2"' || utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound2' || utl_tcp.crlf ||
                'Content-Type: text/html; ' || utl_tcp.crlf ||
                'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf ||utl_tcp.crlf ||
                 utl_tcp.crlf ||'<html><head><title>'||'Expense Report(s) pending your approval'||'</title></head>
                <body> <font face = "verdana" size = "2" color="#336699">'||lc_body_hdr_html||'<br><br>
                '||v_html||'
	        <br>Please direct any inquires to iexpense-admin@officedepot.com.<br>
                <br><hr>
                </font></body></html>' ||
                utl_tcp.crlf || '--MIME.Bound2--' || utl_tcp.crlf || utl_tcp.crlf);
            utl_smtp.quit(conn);

  END LOOP; 

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in the procedure xx_iexp_unaprv_mgr_ntfy : '||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_iexp_unaprv_mgr_ntfy;

END;
/
