SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating function XX_IEXP_OPEN_NOTIF_FUNC
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE FUNCTION XX_IEXP_OPEN_NOTIF_FUNC(P_PERSON_ID NUMBER) RETURN Varchar2
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- +==========================================================================+
  -- | Name :  XX_IEXP_OPEN_NOTIF_FUNC                                          |
  -- | Description :  This function is used to calculate unused amount for      |
  -- |                person                                                    |
  -- | RICEID      :                                                            |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date              Author              Remarks                   |
  -- |======   ==========     =============        =======================      |
  -- |1.0       29-May-2017    praveen vanga       Initial version              |
  -- |                                                                          |
  -- +==========================================================================+
  
  v_unused_amt varchar2(20);
BEGIN
               SELECT NVL(sum(txn.transaction_amount),0)
                 INTO v_unused_amt
                 FROM ap_credit_card_trxns_all txn,
                      AP_CARDS_ALL CRD
                WHERE crd.employee_id = P_PERSON_ID
                  AND txn.validate_code = 'Y'
                  AND txn.payment_flag <> 'Y'
                  AND TXN.BILLED_AMOUNT IS NOT NULL
                  AND txn.card_id = crd.card_id
                  AND txn.card_program_id = crd.card_program_id
                  AND txn.card_id = crd.card_id
                  AND (NVL (txn.CATEGORY, 'BUSINESS') NOT IN ('DISPUTED', 'CREDIT', 'MATCHED', 'DEACTIVATED'))
                  AND TRUNC (NVL (txn.trx_available_date,TO_DATE ('01-01-1952 00:00:00','DD-MM-YYYY HH24:MI:SS'))) <= TRUNC (SYSDATE)
                  AND report_header_id IS NULL;
 
                v_unused_amt :=TRIM(TO_CHAR(v_unused_amt, '$999G999G999D99'));

     return v_unused_amt;

EXCEPTION
 WHEN OTHERS THEN
   v_unused_amt:=NULL;
   return v_unused_amt;
END XX_IEXP_OPEN_NOTIF_FUNC;  
/
