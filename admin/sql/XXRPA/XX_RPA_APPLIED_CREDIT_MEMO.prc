CREATE OR REPLACE PROCEDURE XX_RPA_APPLIED_CREDIT_MEMO
(
 p_trx_num IN ra_customer_trx_all.trx_number%TYPE
)
AS
CURSOR id_cur IS SELECT rcta2.trx_number,
         araa.application_type,
         araa.apply_date,
         araa.status,
         araa.AMOUNT_APPLIED,
         APSA.ACCTD_AMOUNT_DUE_REMAINING BALANCE_DUE,
         CUST.ACCOUNT_NUMBER CUSTOMER_NUMBER,
         araa.GL_DATE,
         CTT.NAME INVOICE_TYPE
    FROM RA_CUSTOMER_TRX_ALL rcta1,
         RA_CUSTOMER_TRX_ALL rcta2,
         AR_RECEIVABLE_APPLICATIONS_ALL araa,
         AR_PAYMENT_SCHEDULES_ALL APSA,
         hz_cust_accounts_all CUST,
         ra_cust_trx_types_ALL CTT
   WHERE rcta1.trx_number = P_TRX_NUM 
     AND araa.status = 'APP' -- 'APP'/'UNAPP'(Applied/Unapplied)
     AND araa.display = 'Y'  
     AND rcta1.customer_trx_id = araa.customer_trx_id
     AND rcta2.customer_trx_id = araa.APPLIED_CUSTOMER_TRX_ID
     AND APSA.Payment_schedule_id = ARAA.APPLIED_PAYMENT_SCHEDULE_ID
     AND cust.cust_account_id = APSA.customer_id
     AND ctt.cust_trx_type_id = APSA.cust_trx_type_id
ORDER BY apply_date desc;

BEGIN
DBMS_OUTPUT.PUT_LINE(
						       RPAD('TRX_NUMBER',10)
						||'|'||RPAD('APPLICATION_TYPE',17)
						||'|'||RPAD('APPLY_DATE',11)
						||'|'||RPAD('STATUS',8)
						||'|'||RPAD('AMOUNT_APPLIED',10)
						||'|'||RPAD('BALANCE_DUE',12)
						||'|'||RPAD('CUSTOMER_NUMBER',15)
						||'|'||RPAD('GL_DATE',10)
						||'|'||RPAD('INVOICE_TYPE',15)
						);

FOR Trx_rec in id_cur
		 LOOP
			DBMS_OUTPUT.PUT_LINE(
						        RPAD(Trx_rec.trx_number,10)
						||'|'||RPAD(Trx_rec.application_type,17)
						||'|'||RPAD(Trx_rec.apply_date,11)
						||'|'||RPAD(Trx_rec.status,8)
						||'|'||RPAD(Trx_rec.AMOUNT_APPLIED,10)
						||'|'||RPAD(Trx_rec.BALANCE_DUE,12)
						||'|'||RPAD(Trx_rec.CUSTOMER_NUMBER,15)
						||'|'||RPAD(Trx_rec.GL_DATE,10)
						||'|'||RPAD(Trx_rec.INVOICE_TYPE,15)
						);
			
		 END LOOP;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN  
	DBMS_OUTPUT.PUT_LINE('There is no Credit Memo Applied for this TRX number');
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Error code - '||SQLCODE||
						 'Error message - '||SQLERRM);

END XX_RPA_APPLIED_CREDIT_MEMO;
/