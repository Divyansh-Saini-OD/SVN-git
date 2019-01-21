create or replace
PACKAGE BODY      XX_AP_IEXP_CREDIT_ALERT
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                             ORACLE                                                |
-- +===================================================================================+
-- | Name        : XX_AP_IEXP_CREDIT_ALERT                                             |
-- | Description : This Package will be executable code for the Daily processing report|                                   
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Kirubha Samuel     Initial draft version                    |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                           ORACLE                                                  |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Package is used to generate the iExpense Credit statement alert| 
-- |                and also to purge them.                                            |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Kirubha Samuel     Initial draft version                    |
-- |2.0       20-FEB-2014  Jay Gupta               R12 Retrofit for Defect# 28403      |
-- |2.1       27-OCT-2015  Harvinder Rakhra        R12.2 Retrofit                      |
-- |2.2       04-OCT-2018  Bhargavi Ankolekar      Added DESCRIPTION 'CREDIT BALANCE   |
-- |                                               REFUND'as per jira #50787           |
-- +===================================================================================+


PROCEDURE  CREDIT_MAIN ( x_errbuff OUT VARCHAR2,
                           x_retcode OUT NUMBER,
                           P_MODE VARCHAR2,
                           P_START_DATE VARCHAR2, -- Added as per jira #50787
						   p_end_date varchar2, ---- Added as per jira #50787
						   p_mail VARCHAR2)
IS
L_MODE  VARCHAR2(20) := P_MODE;
L_START_DATE VARCHAR2(20):=P_START_DATE; ---- Added as per jira #50787
l_end_date varchar2(30) :=p_end_date; ---- Added as per jira #50787
l_mail VARCHAR2(30) :=p_mail;


BEGIN

if l_mode = 'ALERT' THEN
CREDIT_ALERT(l_start_date,l_end_date,l_mail);
ELSIF l_mode = 'PURGE' THEN
CREDIT_PURGE(l_start_date,l_end_date);
ELSE
CREDIT_PURGE_ALERT(l_end_date,l_mail);
END IF;
FND_FILE.PUT_LINE(FND_FILE.LOG,l_start_date);
FND_FILE.PUT_LINE(FND_FILE.LOG,l_end_date);
END CREDIT_MAIN;

PROCEDURE CREDIT_ALERT(p_start_date varchar2,p_end_date varchar2,p_mail varchar2)

IS

ln_request_id NUMBER;
lb_wait       BOOLEAN;
lb_layout     BOOLEAN;
lc_dev_phase  VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message    VARCHAR2(1000);
lc_status    VARCHAR2(1000);
lb_printer   BOOLEAN;
LC_PHASE     VARCHAR2(1000);
L_START_DATE VARCHAR2(30):= P_START_DATE; ---- Added as per jira #50787
l_end_date varchar2(30):= p_end_date;


BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
IF p_mail = 'Y' THEN
lb_printer := FND_REQUEST.add_printer ('XPTR',1);
END IF;

lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXAPIEXPCRDALERTREPORTT'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

                 ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                             ,'XXAPIEXPCRDALERTREPORT'
                                                             ,NULL
                                                             ,NULL
                                                             ,FALSE
															 ,l_start_date
															 ,l_end_date
                                                              );
                 COMMIT;
                 lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                             ,10
                                                             ,NULL
                                                             ,lc_phase
                                                             ,lc_status
                                                             ,lc_dev_phase
                                                             ,lc_dev_status
                                                             ,lc_message
                                                             );



EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;

END;

PROCEDURE CREDIT_PURGE_ALERT(p_end_date varchar2,p_mail varchar2)
IS
ln_request_id NUMBER;
lb_wait       BOOLEAN;
lb_layout     BOOLEAN;
lc_dev_phase  VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message    VARCHAR2(1000);
lc_status    VARCHAR2(1000);
lb_printer   BOOLEAN;
LC_PHASE     VARCHAR2(1000);
l_end_date varchar2(30) := p_end_date; --- Added as per jira #50787


BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
IF p_mail = 'Y' THEN
lb_printer := FND_REQUEST.add_printer ('XPTR',1);
END IF;


lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXAPIEXPPURGEREPORTT'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

                 ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                             ,'XXAPIEXPPURGEREPORT'
                                                             ,NULL
                                                             ,NULL
                                                             ,FALSE
                                                             ,l_end_date);
                 COMMIT;
                 lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                             ,10
                                                             ,NULL
                                                             ,lc_phase
                                                             ,lc_status
                                                             ,lc_dev_phase
                                                             ,lc_dev_status
                                                             ,lc_message
                                                             );



EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;

END;


PROCEDURE CREDIT_PURGE(p_start_date varchar2,p_end_date varchar2)


IS
CURSOR credit_trxns(l_start_date varchar2 , l_end_date varchar2) IS
SELECT reference_number,INVOICE_ID
  FROM
    (SELECT APC.CARD_NUMBER,
      Aca.CARDMEMBER_NAME,
      ppf.employee_number,
      AIA.INVOICE_NUM as INVOICE_NUM,
	  AIA.INVOICE_ID as INVOICE_ID,
      APC.DESCRIPTION DESCRIPTION_SENT_FROM_BANK,
      AIA.INVOICE_AMOUNT,
      TRANSACTION_AMOUNT,
      apc.payment_flag,
      apc.reference_number reference_number,
      apc.trx_id trx_id
    FROM AP_INVOICES_ALL AIA,
      AP_CREDIT_CARD_TRXNS_ALL APC,
      ap_cards_all aca,
      per_people_f ppf
    WHERE INVOICE_AMOUNT <'0'
    AND APC.DESCRIPTION  = AIA.INVOICE_NUM
  --V2.0  AND APC.CARD_NUMBER  = ACA.CARD_NUMBER
    AND APC.CARD_ID  = ACA.CARD_ID
    AND aca.employee_id  = ppf.person_id
    AND apc.payment_flag = 'N'
 ---AND AND trunc(APC.creation_date) <= trunc(fnd_conc_date.string_to_date(l_as_of_date))
 AND trunc(APC.creation_date) BETWEEN trunc(fnd_conc_date.string_to_date(l_start_date)) AND trunc(fnd_conc_date.string_to_date(l_end_date))--- Added as per jira #50787
    UNION
    SELECT APC.CARD_NUMBER ,
      ACA.CARDMEMBER_NAME ,
      ppf.employee_number ,
      (SELECT aia.INVOICE_NUM
      FROM AP_INVOICES_ALL AIA,
        ap_expense_report_headers_all aer
      WHERE AIA.VENDOR_ID         = 162007
      AND AIA.INVOICE_AMOUNT      <'0'
      AND aia.invoice_num         = aer.invoice_num
      AND ABS(AIA.INVOICE_AMOUNT) = apc.TRANSACTION_AMOUNT
      AND aer.employee_id         = aca.employee_id
      )INVOICE_NUM ,
	  (SELECT aia.INVOICE_ID
      FROM AP_INVOICES_ALL AIA,
        ap_expense_report_headers_all aer
      WHERE AIA.VENDOR_ID         = 162007
      AND AIA.INVOICE_AMOUNT      <'0'
      AND aia.invoice_num         = aer.invoice_num
      AND ABS(AIA.INVOICE_AMOUNT) = apc.TRANSACTION_AMOUNT
      AND aer.employee_id         = aca.employee_id
      )INVOICE_ID ,
      APC.DESCRIPTION DESCRIPTION_SENT_FROM_BANK ,
      (SELECT aia.INVOICE_amount
      FROM AP_INVOICES_ALL AIA,
        ap_expense_report_headers_all aer
      WHERE AIA.VENDOR_ID         = 162007
      AND AIA.INVOICE_AMOUNT      <'0'
      AND aia.invoice_num         = aer.invoice_num
      AND ABS(AIA.INVOICE_AMOUNT) = apc.TRANSACTION_AMOUNT
      AND aer.employee_id         = aca.employee_id
      )INVOICE_amount ,
      apc.TRANSACTION_AMOUNT ,
      apc.payment_Flag ,
      apc.reference_number reference_number ,
      apc.trx_id
    FROM AP_CREDIT_CARD_TRXNS_ALL APC,
      ap_cards_all aca,
      per_people_f ppf
    WHERE APC.DESCRIPTION in ('CREDIT BALANCE REFUND','DEBIT PER COMPANY') -- Added description 'Credit Balance Refund' as per jira #50787
  --V2.0  AND APC.CARD_NUMBER  = ACA.CARD_NUMBER
    AND APC.CARD_ID  = ACA.CARD_ID
    AND aca.employee_id   = ppf.person_id
    AND apc.payment_flag  = 'N'
 --AND AND trunc(APC.creation_date) <= trunc(fnd_conc_date.string_to_date(l_as_of_date))
  AND trunc(APC.creation_date) BETWEEN trunc(fnd_conc_date.string_to_date(l_start_date)) AND trunc(fnd_conc_date.string_to_date(l_end_date)) --- Added as per jira #50787
 )   
  WHERE invoice_num IS NOT NULL ;
  l_reference_number varchar2(60); 
  l_invoice_id NUMBER(15);
  l_start_date varchar2(30) :=p_start_date;
l_end_date varchar2(30) :=p_end_date;
  l_count number :=0;
  
BEGIN
OPEN credit_trxns(l_start_date,l_end_date);
LOOP
FETCH  credit_trxns INTO l_reference_number,l_invoice_id;
EXIT WHEN credit_trxns%NOTFOUND;
UPDATE ap_credit_card_trxns_all set payment_flag = 'Y' where reference_number = l_reference_number;
UPDATE ap_invoices_all set Attribute15 = trunc(sysdate) where invoice_id = l_invoice_id;
COMMIT;
l_count:=l_count+1;
END LOOP;

CLOSE Credit_trxns;

FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Transactions purged: '||l_count);

EXCEPTION WHEN OTHERS THEN
CLOSE Credit_trxns;
FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Puging the transactions :' || SQLERRM);  
END;
END;
/