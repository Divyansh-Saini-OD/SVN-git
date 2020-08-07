-- +============================================================================================+
-- |  Office Depot - SDR project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- | Name         : XX_AR_E055_11546_REFUNDTRXTMP.sql                                           |
-- | Rice Id      : I1380                                                                       |
-- | Description  : Update of Table xx_ar_refund_trx_tmp                                        |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   03-JUN-2011   Gaurav Agarwal       Initial Version                               |
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
PROMPT Updating the Table xx_ar_refund_trx_tmp for 1380 Ref mail check id and Payment Method
PROMPT

DECLARE
  CURSOR update_cur
  IS 
  SELECT a.refund_header_id,c.ref_mailcheck_id
  FROM APPS.xx_ar_refund_trx_tmp A,
  apps.ar_cash_receipts_all b,
  apps.xx_ar_mail_check_holds c
  WHERE 1=1
  and ADJ_CREATED_FLAG ='N'
  AND NVL(ERROR_FLAG,'N') != 'Y'
  and identification_type ='OM'
  and a.trx_id = b.cash_receipt_id
  and a.activity_type !='US_ESCHEAT_REC_WRITEOFF_OD'
  and (  b.attribute7  = c.aops_order_number )
  and b.attribute9 like 'Send Refund%'
  and a.ref_mailcheck_id is null;
  ln_cnt   number := 0 ; 

BEGIN

  FOR rec IN update_cur
  LOOP
      UPDATE APPS.xx_ar_refund_trx_tmp a
      SET a.payment_method_name = 'US_MAILCHECK_OD'
         ,a.ref_mailcheck_id = rec.ref_mailcheck_id
      WHERE a.refund_header_id = rec.refund_header_id;
      ln_cnt := ln_cnt +1 ;
  END LOOP;


DBMS_OUTPUT.PUT_LINE('Total Rows Updated ='||ln_cnt);


EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line ('XX_AR_REFUND_TRX_TMP ERROR:'||SUBSTR(SQLERRM,1,249));

END;
/
SET FEEDBACK ON