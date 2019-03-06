create or replace
Procedure XX_OM_DEPO_RELEASEHOLD ( x_retcode OUT NOCOPY NUMBER
                                                   , x_errbuf  OUT NOCOPY VARCHAR2
                                                   , p_order_number_from IN NUMBER
                                                   , P_ORDER_NUMBER_TO   IN NUMBER
                                                   , P_date_FROM        IN VARCHAR2
                                                   , p_date_to          IN VARCHAR2
                                                   ) AS
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |                  Office Depot                                                |
-- +==============================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG                                                 |
-- | Description      : This Program will create a payment record and release     |
-- |                    hold aganist a deposit were i1025 status = CREATED_DEPOSIT|
-- |                                                                              |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version    Date          Author            Remarks                            |
-- |=======    ==========    =============     ===================================|
-- |DRAFT 1A   30-JUL-2009   Bapuji Nanapaneni Initial draft version              |
-- |DRAFT 1B   17-NOV-2011   Oracle AMS Team   Modified c_order_number and 	  |
-- |                                           c_payment cursors to fetch deposits|
-- |                                           data from xx_om_legacy_dep_dtls    |
-- |					       table.	                          |
-- |DRAFT 1C   20-JAN-2012   Bapuji Nanapaneni Modified the code to release hold  |
-- |                                           for single payment POS transactions|
-- |                                           and unapply the pre-payment and    |
-- |                                           apply to the sales order           |
-- |DRAFT 1D   16-APR-2012   Oracle AMS Team   Modified c_order_number introducing|
-- |                                           date range as parameter            |
-- |DRAFT 1E   23-NOV-2015   Vasu Raparla    Removed Schema Refernces for R12.2    |
-- |DRAFT 1F   18-DEC-2017   Venkata Battu   Added calling book_order procedure Defect#43798|
-- +==============================================================================+

  l_hold_source_rec   OE_HOLDS_PVT.hold_source_rec_type;
  l_hold_release_rec  OE_HOLDS_PVT.Hold_Release_Rec_Type;
  l_header_rec        XX_OM_SACCT_CONC_PKG.header_match_rec;
  i                   BINARY_INTEGER;
  ln_header_id        OE_ORDER_HEADERS_ALL.HEADER_ID%TYPE;
  lc_return_status    VARCHAR2(30);
  ln_msg_count        NUMBER;
  ln_sucess_count     NUMBER := 0;
  ln_fetch_count      NUMBER := 0;
  ln_total_fetch      NUMBER := 0;
  ln_failed_count     NUMBER := 0;
  lc_msg_data         VARCHAR2(2000);
  ln_prepaid_amount   NUMBER := 0;
  ln_order_total      NUMBER := 0;
  ln_avail_balance    NUMBER := 0;
  ln_hold_id          NUMBER := 0;
  ln_r_msg_count      NUMBER := 0;
  ln_payment_set_id   NUMBER;
  ln_amount           NUMBER;
  ln_ord_due_balance  NUMBER;
  ln_sent_amt         NUMBER;
  ln_amount_applied   NUMBER;
  LN_OSR_LENGTH       NUMBER := 0;
  L_DATE_TO           DATE   := FND_CONC_DATE.STRING_TO_DATE(P_DATE_TO) + 1 -1/(24*60*60);
  l_date_from         DATE   := fnd_conc_date.string_to_date(p_date_from) ;

  -- this cursor pulls up all orders in entered and invoice hold status which has
  -- a deposit with status as "CREATED_DEPOSIT".
  CURSOR c_order_number IS
    SELECT DISTINCT h.header_id
      FROM oe_order_headers_all h
         , oe_order_holds_all oh
         , oe_hold_sources_all hs
         , oe_hold_definitions hd
         , xx_om_legacy_deposits d
         , xx_om_legacy_dep_dtls dd
     WHERE h.header_id = oh.header_id
       AND oh.hold_source_id  = hs.hold_source_id
       AND hs.hold_id         = hd.hold_id
       AND oh.hold_release_id IS NULL
       AND hd.name            = 'OD: SAS Pending deposit hold'
       AND d.i1025_status     IN ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
       AND d.cash_receipt_id is not null
       AND substr(h.orig_sys_document_ref,1,9) = substr(dd.orig_sys_document_ref,1,9)
       AND LENGTH(dd.orig_sys_document_ref) = 12
       AND dd.transaction_number  = d.transaction_number
       AND h.flow_status_code   IN ('ENTERED','INVOICE_HOLD')
       AND h.order_number BETWEEN NVL(p_order_number_from,h.order_number)
                          AND NVL(P_ORDER_NUMBER_TO, H.ORDER_NUMBER)
       AND h.creation_date BETWEEN NVL(L_DATE_from,h.creation_date)
                          AND NVL(L_DATE_TO, H.creation_date)
UNION
    SELECT DISTINCT h.header_id
      FROM oe_order_headers_all h
         , oe_order_holds_all oh
         , oe_hold_sources_all hs
         , oe_hold_definitions hd
         , xx_om_legacy_deposits d
         , xx_om_legacy_dep_dtls dd
     WHERE h.header_id = oh.header_id
       AND oh.hold_source_id  = hs.hold_source_id
       AND hs.hold_id         = hd.hold_id
       AND oh.hold_release_id IS NULL
       AND hd.name            = 'OD: SAS Pending deposit hold'
       AND d.i1025_status     IN ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
       AND d.cash_receipt_id is not null
       AND h.orig_sys_document_ref = dd.orig_sys_document_ref
       AND LENGTH(dd.orig_sys_document_ref) = 20
       AND dd.transaction_number  = d.transaction_number
       AND h.flow_status_code  IN ('ENTERED','INVOICE_HOLD')
       AND h.order_number BETWEEN NVL(p_order_number_from,h.order_number)
                          AND NVL(P_ORDER_NUMBER_TO, H.ORDER_NUMBER)
       AND h.creation_date BETWEEN NVL(L_DATE_from,h.creation_date)
                          AND NVL(L_DATE_TO, H.creation_date);
                          
  -- This cursor pulls required info from deposit record to insert into payments table
  CURSOR c_PAYMENT (p_header_id IN NUMBER) IS
    SELECT DISTINCT h.header_id                      header_id
                  , h.request_id                     request_id
                  , d.payment_type_code              payment_type_code
                  , d.credit_card_code               credit_card_code
                  , d.credit_card_number             credit_card_number
                  , d.credit_card_holder_name        credit_card_holder_name
                  , d.credit_card_expiration_date    credit_card_expiration_date
                  , d.payment_set_id                 payment_set_id
                  , d.receipt_method_id              receipt_method_id
                  , d.payment_collection_event       payment_collection_event
                  , d.credit_card_approval_code      credit_card_approval_code
                  , d.credit_card_approval_date      credit_card_approval_date
                  , d.check_number                   check_number
                  , d.orig_sys_payment_ref           orig_sys_payment_ref
                  , to_number(d.orig_sys_payment_ref) payment_number
                  , dd.orig_sys_document_ref          orig_sys_document_ref
                  , d.avail_balance                  avail_balance
                  , d.prepaid_amount                 prepaid_amount
                  , d.cc_auth_manual                 attribute6
                  , d.merchant_number                attribute7
                  , d.cc_auth_ps2000                 attribute8
                  , d.allied_ind                     attribute9
                  , d.cc_mask_number                 attribute10
                  , d.od_payment_type                attribute11
                  , d.debit_card_approval_ref        attribute12
                  , d.CC_ENTRY_MODE||':'||
                    d.CVV_RESP_CODE||':'||
                    d.AVS_RESP_CODE||':'||
                    d.AUTH_ENTRY_MODE                attribute13
                  , d.cash_receipt_id                attribute15
                  , d.transaction_number             tran_number /* Added by NB */
               FROM oe_order_headers_all  h
                  , xx_om_legacy_deposits d
                  , xx_om_legacy_dep_dtls dd
              WHERE LENGTH(dd.orig_sys_document_ref)    = 12
                AND substr(h.orig_sys_document_ref,1,9) = substr(dd.orig_sys_document_ref(+),1,9)
                AND NVL(d.error_flag,'N')               = 'N'
                AND dd.transaction_number               = d.transaction_number
                AND d.avail_balance                     > 0
                AND h.header_id                         = p_header_id
UNION
    SELECT DISTINCT h.header_id                      header_id
                  , h.request_id                     request_id
                  , d.payment_type_code              payment_type_code
                  , d.credit_card_code               credit_card_code
                  , d.credit_card_number             credit_card_number
                  , d.credit_card_holder_name        credit_card_holder_name
                  , d.credit_card_expiration_date    credit_card_expiration_date
                  , d.payment_set_id                 payment_set_id
                  , d.receipt_method_id              receipt_method_id
                  , d.payment_collection_event       payment_collection_event
                  , d.credit_card_approval_code      credit_card_approval_code
                  , d.credit_card_approval_date      credit_card_approval_date
                  , d.check_number                   check_number
                  , d.orig_sys_payment_ref           orig_sys_payment_ref
                  , to_number(d.orig_sys_payment_ref) payment_number
                  , dd.orig_sys_document_ref          orig_sys_document_ref
                  , d.avail_balance                  avail_balance
                  , d.prepaid_amount                 prepaid_amount
                  , d.cc_auth_manual                 attribute6
                  , d.merchant_number                attribute7
                  , d.cc_auth_ps2000                 attribute8
                  , d.allied_ind                     attribute9
                  , d.cc_mask_number                 attribute10
                  , d.od_payment_type                attribute11
                  , d.debit_card_approval_ref        attribute12
                  , d.CC_ENTRY_MODE||':'||
                    d.CVV_RESP_CODE||':'||
                    d.AVS_RESP_CODE||':'||
                    d.AUTH_ENTRY_MODE                attribute13
                  , d.cash_receipt_id                attribute15
                  , d.transaction_number             tran_number /* Added by NB */
               FROM oe_order_headers_all h
                  , xx_om_legacy_deposits d
                  , xx_om_legacy_dep_dtls dd
              WHERE h.orig_sys_document_ref                 = dd.orig_sys_document_ref
                AND NVL(d.error_flag,'N')               = 'N'
                AND LENGTH(dd.orig_sys_document_ref)    = 20
                AND d.avail_balance                     > 0
                AND dd.transaction_number               = d.transaction_number
                AND h.header_id                         = p_header_id ;


    TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE INDEX BY PLS_INTEGER;
    l_order_tab      t_order_tab;

  -- reterives the holds info
  CURSOR c_hold (p_header_id IN NUMBER ) IS
    SELECT oh.header_id
         , hs.hold_id
         , hs.hold_source_id
         , oh.order_hold_id
     FROM  oe_order_holds_all oh
         , oe_hold_sources_all hs
     WHERE oh.hold_source_id  = hs.hold_source_id
       AND oh.hold_release_id IS NULL
       AND oh.header_id = p_header_id;

BEGIN

    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: OM Release Deposit Holds (i1025 Status "CREATED_DEPOSIT")'||CHR(10));
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Program Parameters:::' ||CHR(10));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Number From   :::'|| '  ' || P_ORDER_NUMBER_FROM ||CHR(10));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Number To     :::'|| '  ' || P_ORDER_NUMBER_TO ||CHR(10));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Date From     :::'|| '  ' || L_DATE_FROM ||CHR(10));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Date To       :::'|| '  ' || L_DATE_to ||CHR(10));
    




    FND_FILE.PUT_LINE(FND_FILE.LOG,':::BEGIN:::');
    OPEN c_order_number;
   FETCH c_order_number
    BULK COLLECT
     INTO l_order_tab;
    CLOSE c_order_number;

    ln_fetch_count := ln_fetch_count+1;
    ln_total_fetch := l_order_tab.COUNT;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Fetched Orders::: ' || l_order_tab.COUNT);


    IF (l_order_tab.COUNT > 0) THEN
        FOR i IN l_order_tab.FIRST..l_order_tab.LAST LOOP
            ln_header_id := l_order_tab(i).header_id;
            l_header_rec := NULL;

            OPEN c_hold(ln_header_id);
           FETCH c_hold
            BULK COLLECT
            INTO l_header_rec.header_id
               , l_header_rec.hold_id
               , l_header_rec.hold_source_id
               , l_header_rec.order_hold_id;
           CLOSE c_hold;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'l_header_rec.header_id:::'||l_header_rec.header_id(1));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_header_id:::'||ln_header_id);

            IF l_header_rec.header_id(1) IS NOT NULL THEN

                -- Now Remove the hold on the order
                l_hold_source_rec.hold_source_id := l_header_rec.hold_source_id(1);
                l_hold_source_rec.hold_id        := l_header_rec.hold_id(1);

                l_hold_release_rec.release_reason_code := 'MANUAL_RELEASE_MARGIN_HOLD';
                l_hold_release_rec.release_comment     := 'Post Production Cleanup';
                l_hold_release_rec.hold_source_id      := l_header_rec.hold_source_id(1);
                l_hold_release_rec.order_hold_id       := l_header_rec.order_hold_id(1);

                FND_FILE.PUT_LINE(FND_FILE.LOG,'HEADER_ID      : ' ||l_header_rec.header_id(1));
                FND_FILE.PUT_LINE(FND_FILE.LOG,'HOLD_SOURCE_ID : ' ||l_header_rec.hold_source_id(1));
                FND_FILE.PUT_LINE(FND_FILE.LOG,'HOLD_ID        : ' ||l_header_rec.hold_id(1));

                         OE_HOLDS_PUB.Release_Holds
                                     ( p_hold_source_rec  => l_hold_source_rec
                                     , p_hold_release_rec => l_hold_release_rec
                                     , x_return_status    => lc_return_status
                                     , x_msg_count        => ln_msg_count
                                     , x_msg_data         => lc_msg_data);

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Hold Return Status::'||LC_RETURN_STATUS);
                        -- COMMIT;  Defect#13407. The commit statement is stopping the ENTERED records from getting inserted into OE_PAYMENTS table.
            ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Hold is Applied');
            END IF;

        IF lc_return_status = 'S' THEN
            ln_ord_due_balance := NULL;


            FND_FILE.PUT_LINE(FND_FILE.LOG,'before r_payment loop ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_header_id '||ln_header_id );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'l_header_rec.header_id(1) '||l_header_rec.header_id(1) );
            ln_payment_set_id := NULL;
            FOR r_payment  IN c_payment(l_header_rec.header_id(1)) LOOP

                IF r_payment.prepaid_amount > 0 THEN
                    ln_header_id := r_payment.header_id;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'r_payment.prepaid_amount : '||r_payment.prepaid_amount);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'header_id : '||ln_header_id);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'r_payment.header_id : '||r_payment.header_id);
                      -- DBMS_OUTPUT.PUT_LINE('created_by : '||ln_user);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'orig_sys_payment_ref : '||r_payment.orig_sys_payment_ref);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'payment_number : '||r_payment.payment_number);
                    SELECT order_total
                      INTO ln_amount
                      FROM xx_om_header_attributes_all
                     WHERE header_id = r_payment.header_id;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_amount '||ln_amount );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'avail_balance '||r_payment.avail_balance );

                    BEGIN

                    SELECT amount_applied
                      INTO ln_amount_applied
                      FROM ar_receivable_applications_all
                     WHERE cash_receipt_id       = r_payment.attribute15
                       AND application_ref_num   = r_payment.tran_number
                       AND application_ref_type  = 'SA'
                       AND display               = 'Y';

                     EXCEPTION

                       WHEN OTHERS THEN
                         ln_amount_applied := 0;

                     END;

                    IF ln_amount <= r_payment.avail_balance THEN
                        IF ln_ord_due_balance IS NULL THEN
                            ln_ord_due_balance := (ln_amount - r_payment.avail_balance);
                            ln_sent_amt        := ln_amount;
                        ELSE
                            ln_sent_amt        := ln_ord_due_balance;
                        END IF;
                    ELSE
                        IF ln_ord_due_balance IS NULL THEN
                            ln_sent_amt        := r_payment.avail_balance;
                            ln_ord_due_balance := (NVL(ln_ord_due_balance,ln_amount) - r_payment.avail_balance);
                        ELSE
                        ln_sent_amt        := ln_ord_due_balance;
                        ln_ord_due_balance := (NVL(ln_ord_due_balance,ln_amount) - r_payment.avail_balance);
                        END IF;
                    END IF;

                    IF ln_amount_applied < ln_sent_amt THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Amount to Apply is less then send amount ');
                        GOTO END_OF_LOOP;
                    END IF;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_sent_amt '||ln_sent_amt);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_ord_due_balance '||ln_ord_due_balance);
                    IF ln_sent_amt <=0 THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Order total is less then avaliable balance :  '||r_payment.attribute15);
                        GOTO END_OF_LOOP;
                    ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'UNAPPLY APPLY TRANSACTION RECEIPT ID :  '||r_payment.attribute15);
                    END IF;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'r_payment.orig_sys_document_ref  '||r_payment.orig_sys_document_ref);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'cash receipt id '||r_payment.attribute15 );

                   XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment( p_init_msg_list     => FND_API.G_TRUE
                                                                    , p_commit            => FND_API.G_FALSE
                                                                    , p_validation_level  => FND_API.G_VALID_LEVEL_FULL
                                                                    , p_cash_receipt_id   => r_payment.attribute15
                                                                    , p_header_id         => r_payment.header_id
                                                                    , p_order_number      => r_payment.orig_sys_document_ref
                                                                    , p_apply_amount      => ln_sent_amt
                                                                    , x_payment_set_id    => ln_payment_set_id
                                                                    , x_return_status     => lc_return_status
                                                                    , x_msg_count         => ln_r_msg_count
                                                                    , x_msg_data          => lc_msg_data
                                                                    );

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'after calling XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment ');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_return_status '||lc_return_status );

                    IF lc_return_status = 'S' THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_payment_set_id : '||ln_payment_set_id);
                    ELSE
                        IF ln_r_msg_count >= 1 THEN
                            FOR I IN 1..ln_msg_count LOOP
                                DBMS_OUTPUT.PUT_LINE(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255));
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'raised error and skipping the payment ');
                                GOTO SKIP_PAYMENT;
                            END LOOP;
                        END IF;
                    END IF;
                    BEGIN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'before inserting into oe_payments ');

                        INSERT INTO OE_PAYMENTS
                                   (
                                     payment_level_code
                                   , header_id
                                   , creation_date
                                   , created_by
                                   , last_update_date
                                   , last_updated_by
                                   , request_id
                                   , payment_type_code
                                   , credit_card_code
                                   , credit_card_number
                                   , credit_card_holder_name
                                   , credit_card_expiration_date
                                   , prepaid_amount
                                   , payment_set_id
                                   , receipt_method_id
                                   , payment_collection_event
                                   , credit_card_approval_code
                                   , credit_card_approval_date
                                   , check_number
                                   , payment_amount
                                   , payment_number
                                   , lock_control
                                   , orig_sys_payment_Ref
                                   , context
                                   , attribute6
                                   , attribute7
                                   , attribute8
                                   , attribute9
                                   , attribute10
                                   , attribute11
                                   , attribute12
                                   , attribute13
                                   , tangible_id
                                  )
                                  VALUES
                                  (  'ORDER'
                                   , ln_header_id
                                   , SYSDATE
                                   , FND_GLOBAL.USER_ID
                                   , SYSDATE
                                   , FND_GLOBAL.USER_ID
                                   , r_payment.request_id
                                   , r_payment.payment_type_code
                                   , r_payment.credit_card_code
                                   , r_payment.credit_card_number
                                   , r_payment.credit_card_holder_name
                                   , r_payment.credit_card_expiration_date
                                   , ln_sent_amt
                                   , ln_payment_set_id
                                   , r_payment.receipt_method_id
                                   , 'PREPAY'
                                   , r_payment.credit_card_approval_code
                                   , r_payment.credit_card_approval_date
                                   , r_payment.check_number
                                   , ln_sent_amt
                                   , r_payment.payment_number
                                   , 1
                                   , r_payment.orig_sys_payment_ref
                                   , 'SALES_ACCT_HVOP'
                                   , r_payment.attribute6
                                   , r_payment.attribute7
                                   , r_payment.attribute8
                                   , r_payment.attribute9
                                   , r_payment.attribute10
                                   , r_payment.attribute11
                                   , r_payment.attribute12
                                   , r_payment.attribute13
                                   , r_payment.attribute15
                                   );

                        DBMS_OUTPUT.PUT_LINE('after insertion ');
                    COMMIT;
                    EXCEPTION
                        WHEN OTHERS THEN

                            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Trying to insert Duplicate Payment:::'|| r_payment.orig_sys_document_ref||SQLERRM);
                            GOTO SKIP_PAYMENT;
                    END;

                END IF;
                <<END_OF_LOOP>>
                FND_FILE.PUT_LINE(FND_FILE.LOG,'END OF LOOP ');
            END LOOP;
        <<SKIP_PAYMENT>>

        SELECT SUM(prepaid_amount)
          INTO ln_prepaid_amount
          FROM oe_payments
         WHERE header_id = ln_header_id
           AND prepaid_amount >0;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_prepaid_amount '||ln_prepaid_amount);

        SELECT LENGTH(orig_sys_document_ref)
	          INTO ln_osr_length
	          FROM oe_order_headers_all
	         WHERE header_id = ln_header_id;

        SELECT round(order_total,2) order_total
          INTO ln_order_total
          FROM xx_om_header_attributes_all
         WHERE header_id = ln_header_id;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_order_total '||ln_order_total );

            IF ln_prepaid_amount = ln_order_total THEN
                DBMS_OUTPUT.PUT_LINE('Avail Balance IS 0 ');

             IF ln_osr_length = 12 THEN

                UPDATE xx_om_legacy_deposits d
                   SET avail_balance = 0
                 WHERE prepaid_amount > 0
                   AND EXISTS (SELECT 1 FROM oe_order_headers_all h
                                           , xx_om_legacy_dep_dtls dd
                                       WHERE h.header_id                          = ln_header_id
                                         AND SUBSTR(h.orig_sys_document_ref,1,9)  = SUBSTR(dd.orig_sys_document_ref,1,9)
                                        AND LENGTH(dd.orig_sys_document_ref)     = 12
                                        AND dd.transaction_number                = d.transaction_number);

               ELSIF ln_osr_length = 20 THEN

                  UPDATE xx_om_legacy_deposits d
                   SET avail_balance = 0
                 WHERE prepaid_amount > 0
                   AND EXISTS (SELECT 1 FROM oe_order_headers_all h
                                           ,xx_om_legacy_dep_dtls dd
                                       WHERE h.header_id                          = ln_header_id
                                         AND h.orig_sys_document_ref              = dd.orig_sys_document_ref
                                         AND LENGTH(dd.orig_sys_document_ref)     = 20
                                         AND dd.transaction_number                = d.transaction_number);

               END IF;


                COMMIT;
                WF_ENGINE.CompleteActivityInternalName( itemtype  => 'OEOH'
                                                      , itemkey   => l_header_rec.header_id(1)
                                                      , activity  => 'BOOK_ELIGIBLE'
                                                      , result    => NULL
                                                      );
                ln_sucess_count := ln_sucess_count+1;
            COMMIT;
			    --Added for Defect# 43798 
			    xx_om_releasehold.book_order( p_header_id =>l_header_rec.header_id(1)
				                             ,p_debug_flag => 'Y'
                                             );											 
            ELSE
                ln_avail_balance := ln_order_total - ln_prepaid_amount;
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_avail_balance : '||ln_avail_balance);
                IF ln_avail_balance > 0 THEN

                --
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_avail_balance 2: '||ln_avail_balance);

                    IF ln_osr_length = 12 THEN

                    UPDATE xx_om_legacy_deposits d
                       SET avail_balance = ln_avail_balance
                     WHERE prepaid_amount > 0
                       AND EXISTS (SELECT 1 FROM oe_order_headers_all h
                                               , xx_om_legacy_dep_dtls dd
                                           WHERE h.header_id                          = ln_header_id
                                             AND SUBSTR(h.orig_sys_document_ref,1,9)  = SUBSTR(dd.orig_sys_document_ref,1,9)
                                             AND LENGTH(dd.orig_sys_document_ref)     = 12
                                             AND dd.transaction_number                = d.transaction_number);

                    ELSIF ln_osr_length = 20 THEN

                     UPDATE xx_om_legacy_deposits d
                       SET avail_balance = ln_avail_balance
                     WHERE prepaid_amount > 0
                       AND EXISTS (SELECT 1 FROM oe_order_headers_all h
                                               , xx_om_legacy_dep_dtls dd
                                            WHERE h.header_id                          = ln_header_id
                                              AND h.orig_sys_document_ref              = dd.orig_sys_document_ref
                                              AND LENGTH(dd.orig_sys_document_ref)     = 20
                                              AND dd.transaction_number                = d.transaction_number);

                 END IF;

                    SELECT hold_id INTO ln_hold_id
                    FROM oe_hold_definitions
                    WHERE name = 'OD: SAS Pending deposit hold';
                    l_hold_source_rec.hold_id := ln_hold_id;
                    l_hold_source_rec.hold_entity_code:= 'O';
                    l_hold_source_rec.hold_entity_id  := ln_header_id;
                    l_hold_source_rec.hold_comment := SUBSTR(lc_msg_data,1,2000);

                    OE_Holds_PUB.Apply_Holds( p_api_version       =>      1.0
                                            , p_validation_level  =>      FND_API.G_VALID_LEVEL_NONE
                                            , p_hold_source_rec   =>      l_hold_source_rec
                                            , x_msg_count         =>      ln_msg_count
                                            , x_msg_data          =>      lc_msg_data
                                            , x_return_status     =>      lc_return_status
                                            );
                END IF;

            END IF;
        END IF;

    COMMIT;
    END LOOP;
    END IF;
        ln_failed_count := ln_total_fetch - ln_sucess_count;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Sucessfully processed order Count:::'|| ln_sucess_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process order Count:::'|| ln_failed_count);

        dbms_output.put_line( ':::End of Program:::');
EXCEPTION
WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' No Data Found To Process:::');
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'When Others Raised: ' ||SQLERRM);

END;
/
