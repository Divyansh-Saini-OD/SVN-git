-- +============================================================================================+
-- |  Office Depot - SDR project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- | Name         : XX_AR_E055_11546_MAILCHECKHOLD.sql                                          |
-- | Rice Id      : I1380                                                                       |
-- | Description  : Update of Table XX_AR_MAIL_CHECK_HOLDS                                      |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   18-MAY-2011   Jay Gupta            Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
SET SERVEROUTPUT        ON

PROMPT
PROMPT Updating the Table XX_AR_MAIL_CHECK_HOLDS for 1380 Holds
PROMPT

DECLARE

BEGIN
UPDATE xx_ar_mail_check_holds
   SET process_code = '1380HOLD'
 WHERE ref_mailcheck_id IN (
          SELECT a.ref_mailcheck_id
            FROM apps.xx_ar_mail_check_holds a
               , apps.ar_cash_receipts_all b
           WHERE 1 = 1
             AND a.process_code = 'PENDING'
             AND a.pos_transaction_number IS NOT NULL
             AND NOT EXISTS (SELECT 1
                               FROM apps.xx_ar_order_receipt_dtl
                              WHERE orig_sys_document_ref = a.pos_transaction_number)
             AND a.pos_transaction_number = b.customer_receipt_reference(+)
             AND (   b.receipt_number IS NULL
                  OR a.creation_date < '01-JAN-2010') );


DBMS_OUTPUT.PUT_LINE('Rows Updated ='||SQL%ROWCOUNT);

EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line ('XX_AR_MAIL_CHECK_HOLDS  ERROR:'||SUBSTR(SQLERRM,1,249));

END;
/
SET FEEDBACK ON

--EXIT;