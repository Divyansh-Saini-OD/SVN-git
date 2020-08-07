create or replace 
PACKAGE BODY XX_CE_CC_CHARGE_BACK_PKG
AS
  -- +===================================================================================+
  -- |                            Office Depot - Project Simplify                        |
  -- +===================================================================================+
  -- | Name       : XX_CE_CC_CHARGE_BACK_PKG.PKB                                         |
  -- | Description: Cash Management AJB Creditcard Charge Back Program                   |
  -- | CM: E2080 (CR898) - OD: CM AJB Credit Card Chageback's                            |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record                                                                      |
  -- |==============                                                                     |
  -- |Version   Date         Authors              Remarks                                |
  -- |========  ===========  ===============      ============================           |
  -- |Draft 1A  31-Mar-2011  Ritch Hartman        Intial Draft Version - Defect 10856    |
  -- | 1.0      24-Jul-2013  Veronica M           E2080-Modified for R12 Upgrade Retrofit|
  -- | 1.1      28-Feb-2014  Jay Gupta            Defect#28427 and 28430                 |
  -- | 1.2      14-May-2014  Arun Gannarapu       Made changes to replace the status_1295|
  -- |                                            with attribute2 for status update in DM |
  -- |                                            creation exception                     |
  -- | 1.3      17-FEB-2014  JohnWIllson           Code has modified for the QC-33444 
  -- +===================================================================================+
  -- Global Variables
  -- ----------------------------------------------
  gn_request_id              NUMBER := fnd_global.conc_request_id;
  gn_user_id                 NUMBER := fnd_global.user_id;
  gn_org_id                  NUMBER := fnd_profile.VALUE ('ORG_ID');
  v_cash_receipt_num         VARCHAR2 (20);
  v_cash_receipt_id          NUMBER;
  v_print_line               VARCHAR2 (2000);
  v_error_loc                VARCHAR2 (50);
  v_error_sub_loc            VARCHAR2 (50);
  v_exception_create_dm      EXCEPTION;
  v_exception_create_receipt EXCEPTION;
  v_exception_apply_receipt  EXCEPTION;
  le_invalid_batch_info      EXCEPTION;
  le_invalid_header_id       EXCEPTION;
  v_error_msg                VARCHAR2 (2000);
  v_oracle_error_msg         VARCHAR2 (1000);
  v_996_all_ok               VARCHAR2 (1);
  v_user_id                  NUMBER         := fnd_global.login_id;
  g_line                     VARCHAR2 (150) := RPAD ('-', 120, '-');
  gn_batch_id                NUMBER;
  recon_batches_rec xx_ce_ajb996_v%ROWTYPE;
  v_ce_dm_rec xx_ce_chargeback_dm%ROWTYPE;
  gn_error   NUMBER := 2;
  gn_warning NUMBER := 1;
  gn_normal  NUMBER := 0;
PROCEDURE lp_print(
    lp_line IN VARCHAR2,
    lp_both IN VARCHAR2)
IS
BEGIN
  IF fnd_global.conc_request_id () > 0 THEN
    CASE
    WHEN UPPER (lp_both) = 'BOTH' THEN
      fnd_file.put_line (fnd_file.LOG, lp_line);
      fnd_file.put_line (fnd_file.output, lp_line);
    WHEN UPPER (lp_both) = 'LOG' THEN
      fnd_file.put_line (fnd_file.LOG, lp_line);
    ELSE
      fnd_file.put_line (fnd_file.output, lp_line);
    END CASE;
  ELSE
    DBMS_OUTPUT.put_line (lp_line);
  END IF;
END;
PROCEDURE lp_get_dm_trx_type_ids(
    p_header_id    IN NUMBER ,
    p_processor_id IN VARCHAR2 ,
    p_trx_date     IN DATE ,
    x_cust_trx_type_id OUT NUMBER ,
    x_memo_line_id OUT NUMBER ,
    x_receipt_method_id OUT NUMBER ,
    x_dflt_customer_id OUT NUMBER )
  --  --------------------------------------------------------------
  --  -    Procedure to determine the AR Customer Transaction Type -
  --  -    and memo line type for the Debit Memo being created     -
  --  -    based on data in the AJB 996 row being processed.       -
  --  -    Also returns receipt_method_id.                         -
  --  -    Use defaults that are defined by processor when chbk    -
  --  -    cannot be matched to AR.                                -
  --  --------------------------------------------------------------
IS
BEGIN
  IF p_header_id IS NOT NULL THEN
    SELECT a.dm_cust_trx_type_id,
      a.dm_memo_line_id,
      a.receipt_method_id
      --, NULL Commented for PROD Defect 2046,1716
      ,
      a.default_customer_id -- Added for PROD Defect 2046,1716
    INTO x_cust_trx_type_id,
      x_memo_line_id,
      x_receipt_method_id ,
      x_dflt_customer_id
    FROM xx_ce_recon_glact_hdr a
    WHERE header_id = p_header_id;
  ELSE
    SELECT a.default_dm_cust_trx_type_id,
      a.default_dm_memo_line_id ,
      a.default_receipt_method_id,
      a.default_customer_id
    INTO x_cust_trx_type_id,
      x_memo_line_id ,
      x_receipt_method_id,
      x_dflt_customer_id
    FROM xx_ce_recon_glact_hdr a
    WHERE p_trx_date BETWEEN a.effective_from_date AND NVL (a.effective_to_date, SYSDATE)
    AND a.org_id        = fnd_profile.VALUE ('ORG_ID')
    AND a.provider_code = p_processor_id
    AND ROWNUM          = 1;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_cust_trx_type_id  := NULL;
  x_memo_line_id      := NULL;
  x_receipt_method_id := NULL;
  x_dflt_customer_id  := NULL;
  v_print_line        := '***** Error retrieving DM and Receipt Types and Defaults.';
  lp_print (v_print_line, 'BOTH');
  raise le_invalid_header_id;
  --  End of getting id values
END lp_get_dm_trx_type_ids; -- Procedure lp_get_dm_trx_type_ids
PROCEDURE lp_apply_receipt(
    lp_dm_trx_id       IN NUMBER ,
    lp_apply_amount    IN NUMBER ,
    lp_cash_receipt_id IN NUMBER )
IS
  l_return_status VARCHAR2 (200);
  l_msg_count     NUMBER;
  l_msg_data      VARCHAR2 (200);
  lc_err_msg      VARCHAR2 (2000);
BEGIN
  v_error_sub_loc := 'lp_apply_receipt ';
  v_print_line    := 'Start lp_apply_receipt, DM id / Amt / Receipt id: ' || lp_dm_trx_id || ' / ' || lp_apply_amount || ' / ' || lp_cash_receipt_id;
  lp_print (v_print_line, 'LOG');
  ar_receipt_api_pub.APPLY (p_api_version => 1.0 , p_init_msg_list => fnd_api.g_true , p_validation_level => fnd_api.g_valid_level_full , p_customer_trx_id => lp_dm_trx_id , p_amount_applied => lp_apply_amount , p_cash_receipt_id => lp_cash_receipt_id , x_return_status => l_return_status , x_msg_count => l_msg_count , x_msg_data => l_msg_data );
  IF l_return_status <> 'S' --  no success
    THEN
    v_error_sub_loc := 'API NOT Successful. Receipt Not Applied';
    RAISE v_exception_apply_receipt;
  END IF;
EXCEPTION
WHEN v_exception_apply_receipt THEN
  v_error_msg  := 'Other Error on Apply receipt: ';
  v_print_line := NVL (v_oracle_error_msg, v_error_msg) || ' in ' || v_error_loc || v_error_sub_loc || ' for ' || 'ChgBk ' || lp_cash_receipt_id || ' FAILED  ****** ';
  lp_print (v_print_line, 'BOTH');
  FOR i IN 1 .. l_msg_count
  LOOP
    lc_err_msg   := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
    v_print_line := 'M' || '*** ' || i || '.' || SUBSTR (lc_err_msg, 1, 255);
    lp_print (v_print_line, 'BOTH');
    IF l_msg_data  IS NOT NULL THEN
      v_print_line := SUBSTR (l_msg_data || '/' || i || '.' || lc_err_msg, 1, 2000);
      lp_print (v_print_line, 'BOTH');
    ELSE
      v_print_line := SUBSTR (i || '.' || lc_err_msg, 1, 2000);
      lp_print (v_print_line, 'BOTH');
    END IF;
  END LOOP;
WHEN OTHERS THEN
  v_error_msg  := 'Other Error on Apply receipt: ';
  v_print_line := NVL (v_oracle_error_msg, v_error_msg) || ' in ' || v_error_loc || v_error_sub_loc || ' for ' || 'ChgBk ' || lp_cash_receipt_id || ' FAILED  ****** ';
  lp_print (v_print_line, 'BOTH');
  FOR i IN 1 .. l_msg_count
  LOOP
    lc_err_msg   := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
    v_print_line := 'M' || '*** ' || i || '.' || SUBSTR (lc_err_msg, 1, 255);
    lp_print (v_print_line, 'BOTH');
    IF l_msg_data  IS NOT NULL THEN
      v_print_line := SUBSTR (l_msg_data || '/' || i || '.' || lc_err_msg, 1, 2000);
      lp_print (v_print_line, 'BOTH');
    ELSE
      v_print_line := SUBSTR (i || '.' || lc_err_msg, 1, 2000);
      lp_print (v_print_line, 'BOTH');
    END IF;
  END LOOP;
END lp_apply_receipt;
PROCEDURE lp_create_debit_memo(
    p_996_rec IN xx_ce_ajb996_v%ROWTYPE )
IS
  l_cust_trx_type_id NUMBER;
  l_return_status    VARCHAR2 (1);
  l_msg_count        NUMBER;
  l_msg_data         VARCHAR2 (2000);
  l_memo_line_id     NUMBER;
  l_batch_id         NUMBER;
  l_cnt              NUMBER := 0;
  l_batch_source_rec ar_invoice_api_pub.batch_source_rec_type;
  l_receipt_counter   NUMBER;
  l_receipt_method_id NUMBER;
  l_trx_header_tbl ar_invoice_api_pub.trx_header_tbl_type;
  l_trx_lines_tbl ar_invoice_api_pub.trx_line_tbl_type;
  l_trx_dist_tbl ar_invoice_api_pub.trx_dist_tbl_type;
  l_trx_salescredits_tbl ar_invoice_api_pub.trx_salescredits_tbl_type;
  l_customer_trx_id  NUMBER;
  l_currency_code    VARCHAR2 (3);
  l_seq              NUMBER;
  l_dflt_customer_id NUMBER;
  lc_trx_number      VARCHAR2 (20);
  x_dm_id_out        NUMBER;
  v_status      varchar2(10):=null;
BEGIN
  v_error_sub_loc := 'lp_create_debit_memo';
  l_cnt           := 0;
  lc_trx_number   := NULL;
  SELECT ra_customer_trx_s.NEXTVAL INTO l_seq FROM DUAL;
  --  ------------------------------------------------------------------ -
  --  -   Get customer trx type and memo line id and receipt_method_id   -
  --  ------------------------------------------------------------------ -
  lp_get_dm_trx_type_ids (p_996_rec.recon_header_id , p_996_rec.processor_id , p_996_rec.trx_date , l_cust_trx_type_id , l_memo_line_id , l_receipt_method_id , l_dflt_customer_id );
  l_trx_header_tbl (1).trx_header_id        := l_seq;
  
  v_status :=null;
  -- Below code has added for the defect QC-33444
  -- validating the customer account
  If p_996_rec.customer_id is not null then
  BEGIN
    select status 
	 into v_status 
	 from hz_cust_accounts
	 where cust_account_id =p_996_rec.customer_id;

  exception 
    when others then
	v_status :=null;
    END;
  end if;
  
  If v_status  = 'I' then
   l_trx_header_tbl (1).bill_to_customer_id  := l_dflt_customer_id;
  else
  l_trx_header_tbl (1).bill_to_customer_id  := NVL (p_996_rec.customer_id, l_dflt_customer_id);
  end if;
    -- End of the code changes for defect QC-33444
  --fnd_file.put_line(fnd_file.logfile,l_trx_header_tbl (1).bill_to_customer_id)
  l_trx_header_tbl (1).cust_trx_type_id     := l_cust_trx_type_id;
  l_trx_header_tbl (1).trx_currency         := p_996_rec.currency;
  IF (recon_batches_rec.chbk_amt             <= p_996_rec.trx_amount or nvl(p_996_rec.trx_amount,0) = 0)  THEN
    l_trx_header_tbl (1).attribute_category := 'CC_DEBIT_MEMO';
    l_trx_header_tbl (1).attribute1         := NVL(p_996_rec.invoice_num, p_996_rec.receipt_num);
  END IF;
  --c. Populate batch source information.
  l_batch_source_rec.batch_source_id := gn_batch_id;
  --d. Populate line 1 information.
  l_trx_lines_tbl (1).trx_header_id      := l_seq;
  l_trx_lines_tbl (1).trx_line_id        := 101;
  l_trx_lines_tbl (1).line_number        := 1;
  l_trx_lines_tbl (1).memo_line_id       := l_memo_line_id;
  l_trx_lines_tbl (1).description        := 'Chargeback from ' || p_996_rec.processor_id || '/Receipt#:' || p_996_rec.receipt_num || '/Invoice#:' || p_996_rec.invoice_num || '/Chbk Code:' || NVL (p_996_rec.chbk_action_code , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code ) || '/Ref:' || p_996_rec.chbk_ref_num || '/Ret Ref:' || p_996_rec.ret_ref_num || '/Store:' || p_996_rec.store_num || '/Batch:' || p_996_rec.bank_rec_id || '/Seq:' || p_996_rec.sequence_id_996;
  l_trx_lines_tbl (1).quantity_invoiced  := 1;
  l_trx_lines_tbl (1).unit_selling_price := p_996_rec.chbk_amt;
  l_trx_lines_tbl (1).line_type          := 'LINE';
  l_return_status                        := NULL;
  l_msg_data                             := NULL;
  l_msg_count                            := NULL;
  arp_standard.enable_debug;
  ar_invoice_api_pub.create_single_invoice (p_api_version => 1.0 , p_batch_source_rec => l_batch_source_rec , p_trx_header_tbl => l_trx_header_tbl , p_trx_lines_tbl => l_trx_lines_tbl , p_trx_dist_tbl => l_trx_dist_tbl , p_trx_salescredits_tbl => l_trx_salescredits_tbl , x_customer_trx_id => l_customer_trx_id , x_return_status => l_return_status , x_msg_count => l_msg_count , x_msg_data => l_msg_data );
  /* ---------------------------------------------------------------------
  --   NOTE:  An error here will require that this chargeback's
  --          debit memo will have to be created manually.  The
  --          remainder of this AJB996-Chargeback file will still
  --          (attempt to) be processed.
  -- -------------------------------------------------------------------*/
  IF l_return_status <> fnd_api.g_ret_sts_success THEN
    x_dm_id_out      := -99;
    lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (NVL (lc_trx_number, ' '), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (' * * Error * * ', 30, ' ') , 'BOTH' );
    v_error_msg := LPAD (' ', 12, ' ') || 'Error Creating DM for Chbk ' || p_996_rec.processor_id || '/ Chbk Code:' || NVL (p_996_rec.chbk_action_code , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code ) || '/ Ref:' || NVL (p_996_rec.chbk_ref_num, 'NONE') || '/ Ret Ref:' || NVL (p_996_rec.ret_ref_num, 0) || '/ Store:' || p_996_rec.store_num;
    lp_print (v_error_msg, 'LOG');
    IF l_msg_data  IS NOT NULL OR fnd_msg_pub.get (p_encoded => fnd_api.g_false) IS NOT NULL THEN
      v_print_line := LPAD (' ', 12, ' ') || LTRIM (RTRIM (fnd_msg_pub.get (p_encoded => fnd_api.g_false)));
      lp_print (v_print_line, 'LOG');
    END IF;
    RAISE v_exception_create_dm;
  ELSE
     SELECT COUNT (*)
       INTO l_cnt FROM ar_trx_errors_gt
      WHERE trx_header_id = l_customer_trx_id; --V1.1, Added where condition
     --V1.1, Added below condition for error display
     if l_cnt > 0 then
     FOR i IN (SELECT * FROM ar_trx_errors_gt WHERE trx_header_id = l_customer_trx_id)
     LOOP
        lp_print (i.error_message, 'LOG');
     END LOOP;
     end if;
     --V1.1, end
     IF l_cnt = 0 THEN
      x_dm_id_out := l_customer_trx_id;
      v_error_msg := NULL;
      BEGIN
        SELECT trx_number
        INTO lc_trx_number
        FROM ra_customer_trx
        WHERE customer_trx_id = l_customer_trx_id;
        IF x_dm_id_out        > 0 THEN
          UPDATE ra_customer_trx_all
          SET ct_reference = SUBSTR ( p_996_rec.processor_id
            || '/'
            || p_996_rec.receipt_num
            || '/'
            || p_996_rec.bank_rec_id
            || '/'
            || p_996_rec.sequence_id_996 , 1 , 30 ) ,
            special_instructions = ( 'CB-'
            || p_996_rec.processor_id
            || '/Receipt#:'
            || p_996_rec.receipt_num
            || '/Invoice#:'
            || p_996_rec.invoice_num
            || '/Chbk Code:'
            || NVL (p_996_rec.chbk_action_code , p_996_rec.chbk_alpha_code
            || '-'
            || p_996_rec.chbk_numeric_code )
            || '/Ref:'
            || p_996_rec.chbk_ref_num
            || '/Ret Ref:'
            || p_996_rec.ret_ref_num
            || '/Store:'
            || p_996_rec.store_num
            || '/Batch:'
            || p_996_rec.bank_rec_id
            || '/Seq:'
            || p_996_rec.sequence_id_996 )
          WHERE customer_trx_id = x_dm_id_out;
          INSERT
          INTO xx_ce_chargeback_dm
            (
              seq_id ,
              cash_receipt_id ,
              debit_memo_trx_id ,
              receipt_number ,
              debit_memo_number ,
              customer_id ,
              sequence_id_996 ,
              ORDER_PAYMENT_ID ,
              INVOICE_NUM ,
              creation_date ,
              created_by,
              last_update_date ,
              last_updated_by
            )
            VALUES
            (
              xx_ce_chargeback_dm_s.NEXTVAL ,
              p_996_rec.ar_cash_receipt_id ,
              x_dm_id_out ,
              p_996_rec.receipt_num ,
              lc_trx_number ,
              NVL( p_996_rec.customer_id, l_dflt_customer_id) ,
              p_996_rec.sequence_id_996 ,
              p_996_rec.order_payment_id ,
              p_996_rec.invoice_num ,
              SYSDATE ,
              v_user_id ,
              SYSDATE ,
              v_user_id
            );
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_YES' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = p_996_rec.sequence_id_996;
        END IF;
        lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (NVL (lc_trx_number, ' '), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD ('Created Debit Memo', 30, ' ') , 'BOTH' );
      EXCEPTION
      WHEN OTHERS THEN
        IF l_cnt > 0 THEN
          SELECT error_message
            || NVL2 (invalid_value, ':'
            || invalid_value, NULL)
          INTO v_print_line
          FROM ar_trx_errors_gt
          WHERE ROWNUM = 1;
          lp_print (LPAD (' ', 12, ' ') || v_print_line, 'LOG');
        END IF;
        v_oracle_error_msg := SQLERRM;
        lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (NVL (lc_trx_number, ' '), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (' * * Error * * ', 30, ' ') , 'BOTH' );
        RAISE v_exception_create_dm;
      END;

    END IF;
  END IF;

END lp_create_debit_memo; -- Procedure Create_Debit_Memo
PROCEDURE lp_create_receipt(
    p_996_rec IN xx_ce_ajb996_v%ROWTYPE ,
    x_trx_id_out OUT NUMBER )
IS
  ln_cust_trx_type_id  NUMBER;
  lc_currency_code     VARCHAR2 (5);
  ln_memo_line_id      NUMBER;
  lc_receipt_number    VARCHAR2 (30);
  lc_return_status     VARCHAR2 (200);
  ln_msg_count         NUMBER;
  ln_receipt_method_id NUMBER;
  lc_msg_data          VARCHAR2 (2000);
  lc_mesg              VARCHAR2 (2000);
  lc_err_msg           VARCHAR2 (2000);
  ln_cr_id             NUMBER;
  ln_count             NUMBER := 0;
  ln_dflt_customer_id  NUMBER;
  ln_customer_id       NUMBER;
  lc_search_receipt    VARCHAR2 (200);
  lc_comments ar_cash_receipts_all.comments%TYPE;
  x_attribute_rec AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;
BEGIN
  v_error_sub_loc := 'Create Receipt';
  --  ------------------------------------------------------------------ -
  --  -   Get customer trx type and memo line id and receipt_method_id   -
  --  ------------------------------------------------------------------ -
  lp_get_dm_trx_type_ids (p_996_rec.recon_header_id , p_996_rec.processor_id , p_996_rec.trx_date , ln_cust_trx_type_id , ln_memo_line_id , ln_receipt_method_id , ln_dflt_customer_id );
  v_error_sub_loc   := 'Set Search Receipt Number';
  lc_search_receipt := NVL (NVL (p_996_rec.receipt_num, p_996_rec.invoice_num), 'CB');
  ln_customer_id    := NVL (p_996_rec.customer_id, ln_dflt_customer_id);
  --if p_996_rec.invoice_num is not null then
  SELECT COUNT (*)
  INTO ln_count
  FROM ar_cash_receipts
  WHERE pay_from_customer = ln_customer_id
  AND receipt_number LIKE lc_search_receipt
    || '%';
  IF ln_count                                               > 0 THEN
    v_error_sub_loc                                        := 'Receipt# Null:Count > 0';
    IF (LENGTH (lc_search_receipt)                                                            + LENGTH (ln_count) + 1) > 30 THEN
      lc_receipt_number                                    := SUBSTR (lc_search_receipt , (30 - LENGTH (ln_count) - 1) * -1 , (30 - LENGTH (ln_count) - 1 ) --Length of counter and seperator "-"".
      ) || '-' || (ln_count                                                                   + 1);
    ELSE
      lc_receipt_number := lc_search_receipt || '-' || (ln_count + 1);
    END IF;
  ELSE
    v_error_sub_loc   := 'Receipt# Null:Count = 0';
    lc_receipt_number := NVL (SUBSTR (lc_search_receipt, -30, 30) , lc_search_receipt || '-' || (ln_count + 1) );
  END IF;
  v_error_sub_loc  := 'Call create cash receipt API.';
  lc_return_status := NULL;
  lc_msg_data      := NULL;
  ln_msg_count     := NULL;
  lc_comments      := 'Chargeback Reversal from ' || p_996_rec.processor_id || '/Receipt#:' || p_996_rec.receipt_num || '/Invoice#:' || p_996_rec.invoice_num || '/Chbk Code:' || NVL (p_996_rec.chbk_action_code , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code ) || '/Ref:' || p_996_rec.chbk_ref_num || '/Ret Ref:' || p_996_rec.ret_ref_num || '/Store:' || p_996_rec.store_num || '/Batch:' || p_996_rec.bank_rec_id || '/Seq:' || p_996_rec.sequence_id_996;
  arp_standard.enable_debug;
  x_attribute_rec.attribute_category := 'CHARGEBACK_DETAILS';
  x_attribute_rec.attribute1         := 'DM Reversal';
  x_attribute_rec.attribute2         := p_996_rec.processor_id;
  x_attribute_rec.attribute3         := p_996_rec.order_payment_id;
  x_attribute_rec.attribute4         := p_996_rec.bank_rec_id;
  ar_receipt_api_pub.create_cash (p_api_version => 1.0 , p_init_msg_list => fnd_api.g_true , p_validation_level => fnd_api.g_valid_level_full , p_receipt_number => lc_receipt_number , p_amount => p_996_rec.chbk_amt * -1 , p_receipt_method_id => ln_receipt_method_id , p_receipt_date => SYSDATE , p_currency_code => p_996_rec.currency , p_customer_id => NVL(p_996_rec.customer_id, ln_dflt_customer_id) , p_comments => lc_comments , p_cr_id => x_trx_id_out , p_attribute_rec => x_attribute_rec , x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data );
  IF lc_return_status <> 'S' --  no success
    THEN
    v_error_sub_loc := 'API NOT Successful. Receipt Not Created';
    lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (lc_receipt_number, 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ') || ' ' || RPAD (' * * Error * * ', 30, ' ') , 'BOTH' );
    v_print_line := LPAD (' ', 12, ' ') || 'Error Creating Receipt for Chargeback ' || p_996_rec.processor_id || '/ Chbk Code:' || NVL (p_996_rec.chbk_action_code , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code ) || '/ Ref:' || NVL (p_996_rec.chbk_ref_num, 'None') || '/ Ret Ref:' || NVL (p_996_rec.ret_ref_num, 0) || '/ Store:' || p_996_rec.store_num;
    lp_print (v_print_line, 'LOG');
    IF NVL (ln_msg_count, 0) > 0 THEN
      FOR i                 IN 1 .. ln_msg_count
      LOOP
        lc_err_msg   := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
        v_print_line := LPAD (' ', 15, ' ') || 'Msg ' || i || ': ' || SUBSTR (lc_err_msg, 1, 255);
        lp_print (v_print_line, 'LOG');
        IF lc_msg_data IS NOT NULL THEN
          v_print_line := LPAD (' ', 15, ' ') || SUBSTR (lc_msg_data || '/' || i || ':' || lc_err_msg , 1 , 2000 );
          lp_print (v_print_line, 'LOG');
        ELSE
          lc_msg_data := LPAD (' ', 15, ' ') || SUBSTR (i || ':' || lc_err_msg, 1, 2000);
          lp_print (v_print_line, 'LOG');
        END IF;
      END LOOP;
    END IF;
    RAISE v_exception_create_receipt;
  ELSE
    v_error_sub_loc := 'API Success. Receipt Created';
    lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (lc_receipt_number, 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ') || ' ' || RPAD ('Created Receipt', 30, ' ') , 'BOTH' );
    UPDATE xx_ce_ajb996 a6
    SET a6.attribute2        = 'CB_YES' ,
      last_update_date       = SYSDATE
    WHERE a6.sequence_id_996 = p_996_rec.sequence_id_996;
  END IF; -- Check of return_status.
EXCEPTION
WHEN OTHERS THEN
  IF (v_error_sub_loc <> 'API NOT Successful. Receipt Not Created' ) THEN
    lp_print ( LPAD (p_996_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (p_996_rec.receipt_num, '- NULL -') , 30 , ' ' ) || ' ' || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (lc_receipt_number, 30, ' ') || ' ' || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ') || ' ' || RPAD (' * * Error * * ', 30, ' ') , 'BOTH' );
    v_oracle_error_msg := SQLCODE || ':' || SQLERRM;
    v_print_line       := LPAD (' ', 12, ' ') || 'Other Error creating Receipt:' || NVL (v_oracle_error_msg, v_error_msg) || ' @ loc:' || v_error_loc || v_error_sub_loc;
    lp_print (v_print_line, 'LOG');
  END IF;
  RAISE v_exception_create_receipt;
END lp_create_receipt;
PROCEDURE process_charge_backs(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER ,
    p_provider_code IN VARCHAR2 ,
    p_bank_rec_id   IN VARCHAR2 )
IS
  CURSOR lcu_get_intf_batches ( lp_processor_id VARCHAR2 , lp_bank_rec_id VARCHAR2 )
  IS
    SELECT xc9i.bank_rec_id ,
      xc9i.processor_id
    FROM XX_CE_999_INTERFACE xc9i
    WHERE 1                                  = 1
    AND record_type                          = 'AJB'
    AND xc9i.deposits_matched                = 'Y'
    AND NVL (xc9i.chargebacks_complete, 'N') = 'N'
    AND processor_id                         = NVL (lp_processor_id, xc9i.processor_id)
    AND xc9i.bank_rec_id                     = NVL(lp_bank_rec_id,xc9i.bank_rec_id)
    AND ( (EXISTS
      (SELECT 1
      FROM xx_ce_ajb996_v xca9
      WHERE NVL (xca9.attribute2, 'CB_NO') != 'CB_YES'
      AND xca9.bank_rec_id                  = xc9i.bank_rec_id
      AND xca9.processor_id                 = xc9i.processor_id
      ) ) );
    CURSOR lcu_get_recon_batches ( p_processor_id VARCHAR2 , p_bank_rec_id VARCHAR2 )
    IS
      SELECT *
      FROM xx_ce_ajb996_v xcan
      WHERE 1                             = 1
      AND xcan.bank_rec_id                = p_bank_rec_id
      AND xcan.processor_id               = p_processor_id
      AND NVL (xcan.attribute2, 'CB_NO') != 'CB_YES';
    CURSOR lcu_get_order_receipt_dtl ( p_order_payment_id NUMBER)
    IS
      SELECT *
      FROM xx_ar_order_receipt_dtl xcan
      WHERE 1                   = 1
      AND xcan.order_payment_id = p_order_payment_id;
    CURSOR lcu_get_ar_receipt_dtl (p_processor_id VARCHAR2 , p_bank_rec_id VARCHAR2)
    IS
      SELECT *
      FROM xx_ce_ajb996_ar_v --xx_ce_ajb996_v
      WHERE NVL (attribute2, '~')                   != 'CB_YES'
      AND processor_id                               = p_processor_id
      AND bank_rec_id                                = p_bank_rec_id;
    CURSOR lcu_get_chargeback_dm (p_cash_receipt_id IN NUMBER, p_receipt_number IN VARCHAR2)
    IS
      SELECT a.*
      FROM xx_ce_chargeback_dm a
      WHERE (a.cash_receipt_id = p_cash_receipt_id
      OR receipt_number        = p_receipt_number )
      AND a.creation_date      =
        (SELECT MAX (b.creation_date)
        FROM xx_ce_chargeback_dm b
        WHERE (b.cash_receipt_id = a.cash_receipt_id
        OR b.receipt_number      = p_receipt_number )
        );
   CURSOR get_dm (p_cash_receipt_id IN NUMBER, p_receipt_number IN VARCHAR2, p_invoice_number IN VARCHAR2)
    IS
      SELECT a.*
      FROM xx_ce_chargeback_dm a
      WHERE (a.cash_receipt_id = p_cash_receipt_id
      OR receipt_number        = p_receipt_number
      OR invoice_num        = p_invoice_number)
      AND a.creation_date      =
        (SELECT MAX (b.creation_date)
        FROM xx_ce_chargeback_dm b
        WHERE (b.cash_receipt_id = a.cash_receipt_id
        OR b.receipt_number      = p_receipt_number
        OR b.invoice_num      = p_invoice_number)
        );
    -- -------------------------------------------
    -- Local Variable Declaration
    -- -------------------------------------------
    intf_batches_rec lcu_get_intf_batches%ROWTYPE;
    recon_batches_rec lcu_get_recon_batches%ROWTYPE;
    order_receipt_dtl_rec lcu_get_order_receipt_dtl%ROWTYPE;
    ar_receipt_dtl_rec lcu_get_ar_receipt_dtl%ROWTYPE;
    ce_dm_rec lcu_get_chargeback_dm%ROWTYPE;
    ln_996_count       NUMBER;
    ln_996_err_count   NUMBER;
    ln_996_success     NUMBER;
    ln_error_rec       NUMBER := 0;
    lv_dm_id           NUMBER;
    lv_dm_bal          NUMBER;
    lv_dm_id           NUMBER;
    ln_mail_request_id NUMBER;
    lc_mail_address    VARCHAR2 (1000);  -- Added for the Defect 6138
    lc_errored_store   VARCHAR2 (10000); -- Added for the Defect 6138
    lc_err_store_num   VARCHAR2 (10000); -- Added for the Defect 6138
    lc_count_flag      VARCHAR2 (1);
  BEGIN
    mo_global.set_policy_context('S',gn_org_id);        -- Added for R12 Upgrade Retrofit By Veronica on 24-Jul-13
    -- --------------------------------------------
    --  Get all Unreconciled Batches
    -- --------------------------------------------
    FOR intf_batches_rec IN lcu_get_intf_batches (p_provider_code, p_bank_rec_id)
    LOOP
      ln_996_count     := 0;
      ln_996_err_count := 0;
      ln_996_success   := 0;
      lp_print (' ', 'BOTH');
      v_print_line := 'Processing Chargebacks for BankRecID:' || intf_batches_rec.bank_rec_id || ' / Processor:' || intf_batches_rec.processor_id || '(Review log for error details)';
      lp_print (v_print_line, 'BOTH');
      lp_print (g_line, 'BOTH');
      lp_print ( RPAD ('996 Seq ID', 10, ' ') || ' ' || RPAD ('Receipt#', 30, ' ') || ' ' || RPAD ('Invoice#', 30, ' ') || ' ' || LPAD ('Chbk Amt', 15, ' ') || ' ' || RPAD ('DM/Receipt#', 30, ' ') || ' ' || LPAD ('DM/Receipt Amt', 15, ' ') || ' ' || RPAD ('Status', 30, ' ') , 'BOTH' );
      lp_print ( RPAD ('-', 10, '-') || ' ' || RPAD ('-', 30, '-') || ' ' || RPAD ('-', 30, '-') || ' ' || RPAD ('-', 15, '-') || ' ' || RPAD ('-', 30, '-') || ' ' || RPAD ('-', 15, '-') || ' ' || RPAD ('-', 30, '-') , 'BOTH' );
      OPEN lcu_get_recon_batches (intf_batches_rec.processor_id, intf_batches_rec.bank_rec_id);
      LOOP
        BEGIN
          FETCH lcu_get_recon_batches INTO recon_batches_rec;
          EXIT
        WHEN lcu_get_recon_batches%NOTFOUND;
        END;
        BEGIN
          SAVEPOINT save_996_row;
          ln_996_count                 := ln_996_count + 1;
          IF recon_batches_rec.chbk_amt > 0
            --  Chargeback reduces net deposit amount so create DM.
            THEN
            BEGIN
              SELECT batch_source_id
              INTO gn_batch_id
              FROM ra_batch_sources
              WHERE NAME LIKE 'MISC_CBDM%'
              AND status = 'A'
              AND SYSDATE BETWEEN start_date AND NVL (end_date, SYSDATE + 1)
              AND ROWNUM = 1;
            EXCEPTION
            WHEN OTHERS THEN
              v_error_sub_loc := 'Find Debit Memo Batch Source';
              v_print_line    := LPAD (' ', 12, ' ') || '* * Error: Transaction Batch source is not defined! * * .';
              lp_print (v_print_line, 'BOTH');
              IF SQLCODE IS NOT NULL OR SQLERRM IS NOT NULL THEN
                lp_print (LPAD (' ', 12, ' ') || SQLCODE || ':' || SQLERRM , 'LOG' );
              END IF;
              RAISE le_invalid_batch_info;
            END;
            lp_create_debit_memo (recon_batches_rec);
            --  Chargeback increases net deposit amount so create Receipt.
          ELSIF recon_batches_rec.chbk_amt < 0 THEN
            v_cash_receipt_id             := 0;
            lp_create_receipt (recon_batches_rec, v_cash_receipt_id);
            IF v_cash_receipt_id > 0 THEN
              BEGIN
                -- -----------------------------------------------
                -- - Look for DM with a balance greater than -
                -- - this new receipt.  If found, then apply it. -
                -- -----------------------------------------------
                v_ce_dm_rec     := NULL;
                v_error_sub_loc := 'Receipt Created - Check for DM';
                BEGIN
                  OPEN get_dm (recon_batches_rec.ar_cash_receipt_id , recon_batches_rec.receipt_num , recon_batches_rec.invoice_num  );
                  FETCH get_dm INTO v_ce_dm_rec;
                  CLOSE get_dm;
                EXCEPTION
                WHEN OTHERS THEN
                  v_ce_dm_rec := NULL;
                END;
                --  Get the debit memo balance  --
                lv_dm_bal                                  := 0;
                IF NVL (v_ce_dm_rec.debit_memo_trx_id, -99) > 0 THEN
                  lv_dm_bal                                := arp_bal_util.get_trx_balance (p_customer_trx_id => v_ce_dm_rec.debit_memo_trx_id , p_open_receivables_flag => NULL );
                END IF;
                -- Apply receipt to DM if DM balance > chargeback amount
                IF NVL (lv_dm_bal, 0) >= (NVL (recon_batches_rec.chbk_amt, 0) * -1 )
                  --  Remember, chbk_amt is negative here so
                  --  we have to change the sign for comparing
                  --  to the DM amount.
                  THEN
                  lp_apply_receipt (v_ce_dm_rec.debit_memo_trx_id , (NVL (recon_batches_rec.chbk_amt, 0) * -1 ) , v_cash_receipt_id );
                END IF; -- lv_dm_bal >=
              EXCEPTION
              WHEN OTHERS THEN
                v_error_sub_loc := 'Find DM: Exception-When Others';
                v_print_line    := LPAD (' ', 12, ' ') || '** Error finding/applying Receipt to DM. Review Log for details.';
                lp_print (v_print_line, 'BOTH');
                lp_print (SQLCODE || '-' || SQLERRM, 'LOG');
              END; --Look for DM to apply receipt.
            END IF;
            --Look for DM to apply receipt.
          END IF; -- END IF for IF recon_batches_rec.chbk_amt > 0 and ELSIF recon_batches_rec.chbk_amt < 0
        EXCEPTION
        WHEN le_invalid_batch_info THEN
          v_996_all_ok     := 'N';
          ln_996_err_count := ln_996_err_count + 1;
          x_retcode        := gn_warning;
          ROLLBACK TO save_996_row;
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;
          --END IF;
           WHEN le_invalid_header_id THEN
          v_996_all_ok     := 'N';
          ln_996_err_count := ln_996_err_count + 1;
          x_retcode        := gn_warning;
          ROLLBACK TO save_996_row;
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;
          --END IF;

        WHEN v_exception_create_dm THEN
          v_996_all_ok     := 'N';
          ln_996_err_count := ln_996_err_count + 1;
          x_retcode        := gn_warning;
          ROLLBACK TO save_996_row;
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2       = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;

        WHEN v_exception_create_receipt THEN
          v_996_all_ok     := 'N';
          ln_996_err_count := ln_996_err_count + 1;
          x_retcode        := gn_warning;
          ROLLBACK TO save_996_row;
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;

        WHEN OTHERS THEN
          v_996_all_ok     := 'N';
          ln_996_err_count := ln_996_err_count + 1;
          x_retcode        := gn_warning;
          lp_print ( LPAD (recon_batches_rec.sequence_id_996, 10, ' ') || ' ' || RPAD (NVL (recon_batches_rec.receipt_num , '- NULL -' ) , 30 , ' ' ) || ' ' || RPAD (NVL (recon_batches_rec.invoice_num, '- NULL -') , 30 , ' ' ) || ' ' || LPAD (NVL (recon_batches_rec.chbk_amt, 0), 15, ' ') || ' ' || RPAD (' ', 30, ' ') || ' ' || LPAD (' ', 15, ' ') || ' ' || RPAD (' * * Error * * ', 30, ' ') , 'BOTH' );
           ROLLBACK TO save_996_row;
          UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;

          IF SQLCODE      = -54 THEN
            v_print_line := LPAD (' ', 12, ' ') || '** Provider batches are locked by other request/user';
            lp_print (v_print_line, 'BOTH');
            ROLLBACK TO save_996_row;
            UPDATE xx_ce_ajb996 a6
          SET a6.attribute2        = 'CB_NO' ,
            last_update_date       = SYSDATE
          WHERE a6.sequence_id_996 = recon_batches_rec.sequence_id_996;
          END IF;
          IF SQLCODE IS NOT NULL OR SQLERRM IS NOT NULL THEN
            lp_print (LPAD (' ', 12, ' ') || SQLCODE || ':' || SQLERRM , 'LOG' );
          END IF;
        END;
      END LOOP;
      CLOSE lcu_get_recon_batches;
      lp_print (' ', 'BOTH');
      lp_print (g_line, 'BOTH');
      lp_print ( LPAD (' ', 30, ' ') || '996 Chargeback Process Summary (Bank Rec ID:' || recon_batches_rec.bank_rec_id || ' Processor:' || recon_batches_rec.processor_id || ')' , 'BOTH' );
      lp_print (g_line, 'BOTH');
      ln_996_success := ln_996_count - ln_996_err_count;
      IF ln_996_count > 0 THEN
        lp_print ( LPAD ('Successfully Processed', 29, ' ') || ':' || LPAD (ln_996_success, 15, ' ') , 'BOTH' );
      ELSE
        lp_print (' - - No 996 transactions to clear - -', 'BOTH');
      END IF;
      lp_print ( LPAD ('Error Processing', 29, ' ') || ':' || LPAD (ln_996_err_count, 15, ' ') , 'BOTH' );
      lp_print (' ', 'BOTH');
      lp_print (g_line, 'BOTH');
      lp_print (' ', 'BOTH');
      BEGIN
        --Update 999 interface row if all expenses for provider
        -- and batch were sucessfully processed.
        IF v_996_all_ok = 'N' Then
        UPDATE xx_ce_999_interface xc9i1
        SET chargebacks_complete            = 'N' ,
          concurrent_pgm_last               = gn_request_id ,
          last_update_date                  = SYSDATE
        WHERE bank_rec_id                   = intf_batches_rec.bank_rec_id
        AND processor_id                    = intf_batches_rec.processor_id
        AND NVL (deposits_matched, 'N')     = 'Y'
        AND NVL (chargebacks_complete, 'N') = 'N'
        AND EXISTS
          (SELECT 1
          FROM xx_ce_ajb996_v xcan
          WHERE NVL (xcan.attribute2, 'CB_NO') = 'CB_NO'
          AND bank_rec_id                      = xc9i1.bank_rec_id
          AND processor_id                     = xc9i1.processor_id );
        else
        UPDATE xx_ce_999_interface xc9i1
        SET chargebacks_complete            = 'Y' ,
          concurrent_pgm_last               = gn_request_id ,
          last_update_date                  = SYSDATE
        WHERE bank_rec_id                   = intf_batches_rec.bank_rec_id
        AND processor_id                    = intf_batches_rec.processor_id
        AND NVL (deposits_matched, 'N')     = 'Y'
        AND NVL (chargebacks_complete, 'N') = 'N'
        AND NOT EXISTS
          (SELECT 1
          FROM xx_ce_ajb996_v xcan
          WHERE NVL (xcan.attribute2, 'CB_NO') = 'CB_NO'
          AND bank_rec_id                      = xc9i1.bank_rec_id
          AND processor_id                     = xc9i1.processor_id
          );
          end if;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        v_print_line := LPAD (' ', 12, ' ') || ' * * * Error Updating 999 Interface:' || SQLCODE || '-' || SQLERRM;
        lp_print (v_print_line, 'BOTH');
        x_retcode := gn_warning;
      END;
      IF ln_996_err_count > 0 THEN
        ln_error_rec     := ln_error_rec + 1;
      END IF;
    END LOOP;
    IF ln_996_count = 0 THEN
      v_print_line := LPAD (' ', 12, ' ') || ' ----------   NO MATCHED BATCHES FOUND FOR PROCESSING Chargebacks  ----------';
      lp_print (v_print_line, 'BOTH');
    END IF;
    IF ln_error_rec > 0 THEN
      v_print_line := LPAD (' ', 12, ' ') || ' The program ends in warning until the errored rows are corrected.';
      lp_print (v_print_line, 'BOTH');
    END IF;
    IF ln_error_rec     > 0 THEN
      x_retcode        := gn_warning;
      lc_errored_store := 'Program Name - OD: CE AJB CreditCard Chargeback ' || ' have errored due to setup issues. Please refer the attachment for error details. The program ends in warning until it is corrected.';
      -- Mail Body
      SELECT xftv.target_value1
      INTO lc_mail_address
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv
      WHERE xftv.translate_id          = xftd.translate_id
      AND xftd.translation_name        = 'XX_CE_FEE_RECON_MAIL_ADDR'
      AND NVL (xftv.enabled_flag, 'N') = 'Y';
      ln_mail_request_id              := fnd_request.submit_request (application => 'xxfin' , program => 'XXODROEMAILER' , description => '' , sub_request => FALSE , start_time => TO_CHAR (SYSDATE, 'DD-MON-YY HH:MI:SS') , argument1 => '' , argument2 => lc_mail_address , argument3 => 'AJB Chargeback Process - ' || TRUNC (SYSDATE) , argument4 => lc_errored_store , argument5 => 'Y' , argument6 => gn_request_id );
    ELSIF ln_error_rec                 = 0 THEN
      x_retcode                       := gn_normal;
    END IF;

--Update 999 interface column chargebacks_complete to 'Y', if main loop does not find any 996 data.
 BEGIN
    UPDATE xx_ce_999_interface xc9i
SET chargebacks_complete                 = 'Y',
last_update_date = sysdate ,
last_updated_by = fnd_global.user_id
  WHERE nvl(chargebacks_complete, 'N')          != 'Y'
AND record_type                      = 'AJB'
AND processor_id                     =  p_provider_code
AND bank_rec_id                      = NVL ( p_bank_rec_id ,bank_rec_id)
AND xc9i.deposits_matched            = 'Y'
AND NOT EXISTS
  (
     SELECT 1
       FROM xx_ce_ajb996 xca
      WHERE 1            = 1
    AND xca.bank_rec_id  = xc9i.bank_rec_id
    AND xca.processor_id = xc9i.processor_id
  );
  EXCEPTION
      WHEN OTHERS THEN
        v_print_line := LPAD (' ', 12, ' ') || ' * * * Error Updating 999 Interface:' || SQLCODE || '-' || SQLERRM;
        lp_print (v_print_line, 'BOTH');
  end;

  END process_charge_backs;
END XX_CE_CC_CHARGE_BACK_PKG;
/