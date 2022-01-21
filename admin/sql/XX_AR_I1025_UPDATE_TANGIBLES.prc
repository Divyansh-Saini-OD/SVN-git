DECLARE
  v_err    VARCHAR2(8000);  
  
  b_good   BOOLEAN;

  CURSOR c_rcpt 
  ( cp_org_id   IN   NUMBER )
  IS
    SELECT acr.cash_receipt_id,
           acr.receipt_method_id,
           acr.receipt_number,
           acr.currency_code,
           acr.amount,
           acr.attribute7,
           acr.payment_server_order_num,
           op.payment_number,
           op.credit_card_code,
           op.credit_card_holder_name,
           op.credit_card_number,
           op.credit_card_expiration_date,
           op.credit_card_approval_code,
           op.credit_card_approval_date
      FROM ar_cash_receipts_all acr,
           apps.xx_ar_cash_receipts_ext cext,
           oe_order_headers_all ooh,
           oe_payments op
     WHERE ooh.orig_sys_document_ref = acr.attribute7
       AND ooh.header_id = op.header_id
       AND op.prepaid_amount = acr.amount
       AND acr.cash_receipt_id = cext.cash_receipt_id
       AND op.payment_number = cext.payment_number
       AND acr.org_id = cp_org_id
       --AND acr.receipt_method_id IN (2005,2017)
       --AND acr.receipt_date BETWEEN '22-MAY-2008' AND '24-MAY-2008'
       AND acr.payment_server_order_num LIKE 'ARI%'
       --AND ( acr.cc_error_text LIKE 'Pre2 should contain 6%' 
       --    OR acr.cc_error_text IS NULL ) 
       AND (SELECT status
              FROM apps.ar_cash_receipt_history_all
             WHERE cash_receipt_id = acr.cash_receipt_id
               AND current_record_flag = 'Y') = 'CONFIRMED'
       AND op.receipt_method_id = acr.receipt_method_id;
       
  TYPE t_rcpt IS TABLE OF c_rcpt%ROWTYPE
    INDEX BY PLS_INTEGER;
    
  a_rcpt            t_rcpt;
       
  x_cash_receipt_rec       AR_CASH_RECEIPTS%ROWTYPE;
BEGIN
  -- login (US Org)
  FND_GLOBAL.apps_initialize(40688,50896,222);
  
  -- get all receipts
  OPEN c_rcpt
  ( cp_org_id => FND_GLOBAL.ORG_ID );
  FETCH c_rcpt
   BULK COLLECT
   INTO a_rcpt;
  CLOSE c_rcpt;
  
  IF (a_rcpt.COUNT > 0) THEN
    FOR i IN a_rcpt.FIRST..a_rcpt.LAST LOOP
      x_cash_receipt_rec := NULL;
      b_good := TRUE;
      
      x_cash_receipt_rec.cash_receipt_id   := a_rcpt(i).cash_receipt_id;
      x_cash_receipt_rec.receipt_method_id := a_rcpt(i).receipt_method_id;
  
      BEGIN
        XX_AR_PREPAYMENTS_PKG.request_iby_cc_voice_auth
        ( p_currency_code                => a_rcpt(i).currency_code,
          p_amount                       => a_rcpt(i).amount,
          p_payment_server_order_prefix  => 'XXO',
          p_credit_card_code             => a_rcpt(i).credit_card_code,
          p_credit_card_number           => a_rcpt(i).credit_card_number,
          p_credit_card_holder_name      => a_rcpt(i).credit_card_holder_name,
          p_credit_card_expiration_date  => LAST_DAY(a_rcpt(i).credit_card_expiration_date),
          p_credit_card_approval_code    => a_rcpt(i).credit_card_approval_code,
          p_credit_card_approval_date    => a_rcpt(i).credit_card_approval_date,
          p_iby_ref_info                 => a_rcpt(i).receipt_number,
          x_cash_receipt_rec             => x_cash_receipt_rec );
      EXCEPTION
        WHEN OTHERS THEN
          v_err := SQLERRM;
          ROLLBACK;
          b_good := FALSE;
          INSERT INTO xx_ar_i1025_messages VALUES
          ( 'M', a_rcpt(i).attribute7, a_rcpt(i).payment_number, SYSDATE, -1, 'Y', 1, 'E', 'MANUAL_TANGIBLE_FIX', 
            'ERRORS - Rcpt: ' || a_rcpt(i).receipt_number || ', Old Tangible: ' 
              || a_rcpt(i).payment_server_order_num || ', ERROR = ' || v_err,
            'REQUEST_IBY_CC_VOICE_AUTH', SYSDATE, -1, SYSDATE, -1, -1 );
          COMMIT;
      END;
        
      IF (b_good) THEN
        UPDATE ar_cash_receipts_all
           SET cc_error_code = NULL, 
               cc_error_text = NULL,
               cc_error_flag = NULL
         WHERE cash_receipt_id = a_rcpt(i).cash_receipt_id
           AND cc_error_text IS NOT NULL;
        
        INSERT INTO xx_ar_i1025_messages VALUES
        ( 'M', a_rcpt(i).attribute7, a_rcpt(i).payment_number, SYSDATE, -1, 'Y', 1, 'I', 'MANUAL_TANGIBLE_FIX', 
          'SUCCESS - Rcpt: ' || a_rcpt(i).receipt_number || ', Old Tangible: ' 
                || a_rcpt(i).payment_server_order_num || ', New Tangible: ' 
                || x_cash_receipt_rec.payment_server_order_num,
          'REQUEST_IBY_CC_VOICE_AUTH', SYSDATE, -1, SYSDATE, -1, -1 );
        
        COMMIT;
      END IF;
    END LOOP;
  END IF;
  
  
  -- login (CA Org)
  FND_GLOBAL.apps_initialize(40688,50897,222);
  
  -- get all receipts
  OPEN c_rcpt
  ( cp_org_id => FND_GLOBAL.ORG_ID );
  FETCH c_rcpt
   BULK COLLECT
   INTO a_rcpt;
  CLOSE c_rcpt;
  
  IF (a_rcpt.COUNT > 0) THEN
    FOR i IN a_rcpt.FIRST..a_rcpt.LAST LOOP
      x_cash_receipt_rec := NULL;
      b_good := TRUE;
      
      x_cash_receipt_rec.cash_receipt_id   := a_rcpt(i).cash_receipt_id;
      x_cash_receipt_rec.receipt_method_id := a_rcpt(i).receipt_method_id;
  
      BEGIN
        XX_AR_PREPAYMENTS_PKG.request_iby_cc_voice_auth
        ( p_currency_code                => a_rcpt(i).currency_code,
          p_amount                       => a_rcpt(i).amount,
          p_payment_server_order_prefix  => 'XXO',
          p_credit_card_code             => a_rcpt(i).credit_card_code,
          p_credit_card_number           => a_rcpt(i).credit_card_number,
          p_credit_card_holder_name      => a_rcpt(i).credit_card_holder_name,
          p_credit_card_expiration_date  => LAST_DAY(a_rcpt(i).credit_card_expiration_date),
          p_credit_card_approval_code    => a_rcpt(i).credit_card_approval_code,
          p_credit_card_approval_date    => a_rcpt(i).credit_card_approval_date,
          p_iby_ref_info                 => a_rcpt(i).receipt_number,
          x_cash_receipt_rec             => x_cash_receipt_rec );
      EXCEPTION
        WHEN OTHERS THEN
          v_err := SQLERRM;
          ROLLBACK;
          b_good := FALSE;
          INSERT INTO xx_ar_i1025_messages VALUES
          ( 'M', a_rcpt(i).attribute7, a_rcpt(i).payment_number, SYSDATE, -1, 'Y', 1, 'E', 'MANUAL_TANGIBLE_FIX', 
            'ERRORS - Rcpt: ' || a_rcpt(i).receipt_number || ', Old Tangible: ' 
              || a_rcpt(i).payment_server_order_num || ', ERROR = ' || v_err,
            'REQUEST_IBY_CC_VOICE_AUTH', SYSDATE, -1, SYSDATE, -1, -1 );
          COMMIT;
      END;
        
      IF (b_good) THEN
        UPDATE ar_cash_receipts_all
           SET cc_error_code = NULL, 
               cc_error_text = NULL,
               cc_error_flag = NULL
         WHERE cash_receipt_id = a_rcpt(i).cash_receipt_id
           AND cc_error_text IS NOT NULL;
        
        INSERT INTO xx_ar_i1025_messages VALUES
        ( 'M', a_rcpt(i).attribute7, a_rcpt(i).payment_number, SYSDATE, -1, 'Y', 1, 'I', 'MANUAL_TANGIBLE_FIX', 
          'SUCCESS - Rcpt: ' || a_rcpt(i).receipt_number || ', Old Tangible: ' 
                || a_rcpt(i).payment_server_order_num || ', New Tangible: ' 
                || x_cash_receipt_rec.payment_server_order_num,
          'REQUEST_IBY_CC_VOICE_AUTH', SYSDATE, -1, SYSDATE, -1, -1 );
        
        COMMIT;
      END IF;
    END LOOP;
  END IF;
END;
/