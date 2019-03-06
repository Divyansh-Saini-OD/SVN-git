CREATE OR REPLACE PACKAGE BODY XX_OM_SA_HOLDS_PKG AS 
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- +============================================================================================+ 
-- |  Name:  XX_OM_SA_HOLDS_PKG                                                                 | 
-- |  Description:                                                                              |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author             Remarks                                        | 
-- | =========   ===========  =================  ===============================================| 
-- | 1.0         26-Feb-2008  Brian Looman and   Initial version                                |
-- |                          Bapuji Nanapaneni                                                 |
-- | 1.1         20-MAY-2011  Bapuji Nanapaneni  update xx_ar_order_receipt_dtl tbl with rct_num|
-- |                                             payment_set_id on status "S" SDR changes       |
-- | 1.2         09-AUG-2011  Bapuji Nanapaneni  FOR ORDER SOURCE POE calling ORDER_RELEASE     |
-- |                                             Directly no need to create receipt DEFECT 13009|
-- | 1.3         19-NOV-2012  AMS Offshore Team  Added data fix for defect 19643  to release    |
-- |                                                  hold  through script                      |
-- | 1.4         23-JUL-2013  Darshini           E2044 - Modified for R12 Upgrade Retrofit.     |
-- | 1.5         09-11-2015   Shubashree R       R12.2  Compliance changes Defect# 36354        |
-- +============================================================================================+

G_PKG_NAME         CONSTANT VARCHAR2(30)  := 'XX_OM_SA_HOLDS_PKG';

-- ==========================================================================
-- procedure for printing to the output
-- ==========================================================================
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
END;


-- ==========================================================================
-- This procedure releases epayment holds on an order.
-- ==========================================================================
PROCEDURE release_payment_holds
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_order_number      IN      NUMBER      DEFAULT NULL,
  p_to_order_number        IN      NUMBER      DEFAULT NULL )
IS
  --ln_debug_level            CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  ln_debug_level            CONSTANT NUMBER := 5;
  
  ln_header_id                       OE_ORDER_HEADERS_ALL.HEADER_ID%TYPE;
  lc_orig_sys_document_ref           OE_ORDER_HEADERS_ALL.ORIG_SYS_DOCUMENT_REF%TYPE;
  lc_payment_rec                     XX_OM_SACCT_CONC_PKG.Payment_Rec_Type;
  
  lc_return_status                   VARCHAR2(30); 
  ln_request_id                      NUMBER;
  l_hold_source_rec                  OE_HOLDS_PVT.hold_source_rec_type;
  l_hold_release_rec                 OE_HOLDS_PVT.Hold_Release_Rec_Type;
  l_order_rec                        OE_HOLDS_PVT.order_rec_type;
  l_header_rec                       XX_OM_SACCT_CONC_PKG.header_match_rec;
  lc_msg_data                        VARCHAR2(2000);
  ln_msg_count                       NUMBER;
  ln_count                           NUMBER;
  lc_flow_status_code                VARCHAR2(80);  
  lc_order_source                    VARCHAR2(80); 

  ln_order_total                     NUMBER     DEFAULT 0;
  ln_payment_total                   NUMBER     DEFAULT 0;
  ln_processed_success               NUMBER     DEFAULT 0;
  ln_processed_failed                NUMBER     DEFAULT 0;
  l_hold_release_id                  NUMBER;
  
  CURSOR c_order_number IS
    SELECT ooh.header_id,
           ooh.order_number,
           ooh.flow_status_code,
           oos.name order_source
      FROM oe_order_headers_all ooh
         , oe_order_sources oos
     WHERE ooh.order_source_id = oos.order_source_id
       AND EXISTS
           (SELECT 1
              FROM oe_payments
             WHERE header_id = ooh.header_id)
       AND ooh.org_id = p_org_id
       AND ooh.order_number BETWEEN p_from_order_number
                                AND p_to_order_number; 
                                
  TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE
    INDEX BY PLS_INTEGER;
  
  l_order_tab        t_order_tab;

  CURSOR c_hold(p_header_id IN NUMBER) IS
     SELECT h.header_id
          , hs.hold_id
          , hs.hold_source_id
          , oh.order_hold_id
      FROM  oe_order_headers_all h
          , oe_order_holds_all oh
          , oe_hold_sources_all hs
          , oe_hold_definitions hd
      WHERE h.header_id = oh.header_id
        AND oh.hold_source_id = hs.hold_source_id
        AND hs.hold_id = hd.hold_id
        AND oh.hold_release_id IS NULL
        AND UPPER(hd.name) = UPPER('Epayment Failure Hold')
        AND h.header_id = p_header_id
      ORDER BY h.header_id;


  CURSOR c_payments(p_header_id IN NUMBER) IS
    SELECT h.header_id
         , i.payment_type_code
         , i.credit_card_code
         , i.credit_card_number
         , i.credit_card_holder_name
         , i.credit_card_expiration_date
         , i.credit_card_approval_code
         , i.credit_card_approval_date
         , i.check_number
         , i.prepaid_amount
         , i.payment_amount
         , i.orig_sys_payment_ref
         , i.payment_number
         , i.receipt_method_id
         , h.transactional_curr_code
         , h.sold_to_org_id
         , h.invoice_to_org_id
         , NULL
         , h.order_number
         , i.context
         , i.attribute6
         , i.attribute7
         , i.attribute8
         , i.attribute9
         , i.attribute10
         , i.attribute11
         , i.attribute12
         , i.attribute13
         , i.payment_set_id
         , NULL
         , i.attribute15
         , h.ship_from_org_id
         , ha.paid_at_store_id
         , h.orig_sys_document_ref
         , (SELECT actual_shipment_date 
              FROM oe_order_lines_all 
             WHERE header_id = h.header_id
               AND rownum = 1) ship_date 
      FROM oe_payments i
               , oe_order_headers_all h
               , xx_om_header_attributes_all ha
           WHERE h.header_id = p_header_id
             AND h.header_id = i.header_id
             AND h.header_id = ha.header_id
             AND h.flow_status_code IN ('ENTERED','INVOICE_HOLD')
             AND NOT EXISTS
                 (SELECT 1
                    FROM ar_cash_receipts_all acr,
                         ar_receivable_applications_all ara
                   WHERE acr.cash_receipt_id = ara.cash_receipt_id
                     AND acr.receipt_method_id = i.receipt_method_id
                     AND acr.amount = i.prepaid_amount
                     AND ara.payment_set_id = i.payment_set_id
                     AND i.credit_card_number IS NULL
                  UNION ALL
                  SELECT 1
                    FROM ar_cash_receipts_all acr,
                         ar_receivable_applications_all ara,
                         --Commented and added by Darshini for R12 Upgarde Retrofit
						 --apps.ap_bank_accounts_all aba
						 iby_ext_bank_accounts ieba
                   WHERE acr.cash_receipt_id = ara.cash_receipt_id
                     --AND acr.customer_bank_account_id = aba.bank_account_id 
					 AND acr.customer_bank_account_id = ieba.ext_bank_account_id 
					 --end of addition
                     AND ieba.bank_account_num = i.credit_card_number
                     AND acr.receipt_method_id = i.receipt_method_id
                     AND acr.amount = i.prepaid_amount
                     AND ara.payment_set_id = i.payment_set_id)
        ORDER BY h.header_id, 
                 i.payment_number;

BEGIN
  OE_DEBUG_PUB.g_debug_level := ln_debug_level;

  OPEN c_order_number;
  FETCH c_order_number 
   BULK COLLECT
   INTO l_order_tab;
  CLOSE c_order_number;
  
  OE_DEBUG_PUB.add('Fetched ' || l_order_tab.COUNT || ' order records.');
  
  IF (l_order_tab.COUNT > 0) THEN
    FOR i IN l_order_tab.FIRST..l_order_tab.LAST LOOP
      l_header_rec := NULL;
      
      ln_header_id := l_order_tab(i).header_id;
      lc_flow_status_code := l_order_tab(i).flow_status_code;
      lc_order_source     := l_order_tab(i).order_source;

      OE_DEBUG_PUB.add('header_id = ' || ln_header_id );
      OE_DEBUG_PUB.add('flow_status_code = ' || lc_flow_status_code);
          
      OPEN c_payments(ln_header_id);
      FETCH c_payments 
       BULK COLLECT 
       INTO lc_payment_rec.header_id
          , lc_payment_rec.payment_type_code
          , lc_payment_rec.credit_card_code
          , lc_payment_rec.credit_card_number
          , lc_payment_rec.credit_card_holder_name
          , lc_payment_rec.credit_card_expiration_date
          , lc_payment_rec.credit_card_approval_code
          , lc_payment_rec.credit_card_approval_date
          , lc_payment_rec.check_number
          , lc_payment_rec.prepaid_amount
          , lc_payment_rec.payment_amount
          , lc_payment_rec.orig_sys_payment_ref
          , lc_payment_rec.payment_number
          , lc_payment_rec.receipt_method_id
          , lc_payment_rec.order_curr_code
          , lc_payment_rec.sold_to_org_id
          , lc_payment_rec.invoice_to_org_id
          , lc_payment_rec.payment_set_id
          , lc_payment_rec.order_number
          , lc_payment_rec.context
          , lc_payment_rec.attribute6
          , lc_payment_rec.attribute7
          , lc_payment_rec.attribute8
          , lc_payment_rec.attribute9
          , lc_payment_rec.attribute10
          , lc_payment_rec.attribute11
          , lc_payment_rec.attribute12
          , lc_payment_rec.attribute13
          , lc_payment_rec.payment_set_id
          , lc_payment_rec.tangible_id
          , lc_payment_rec.attribute15
          , lc_payment_rec.ship_from_org_id
          , lc_payment_rec.paid_at_store_id
          , lc_payment_rec.orig_sys_document_ref
          , lc_payment_rec.receipt_date;
      CLOSE c_payments;
          
      OE_DEBUG_PUB.add('Order has ' || lc_payment_rec.header_id.COUNT
         || ' payments without payment_set_id. or payment_set_id exists with E-PAYMENT HOLD');

      IF (lc_payment_rec.header_id.COUNT > 0) THEN
        ln_order_total := ln_order_total + 1;
        
        ln_payment_total := ln_payment_total + lc_payment_rec.header_id.COUNT;

        SELECT COUNT(*) 
          INTO ln_count
          FROM oe_order_holds_all
         WHERE header_id               = ln_header_id
           AND NVL(released_flag,'N') != 'Y'
           AND hold_release_id IS NULL;

        OE_DEBUG_PUB.add('Order has ' || ln_count || ' order holds.');

        IF ln_count > 0 THEN
          OPEN c_hold(ln_header_id);
          FETCH c_hold 
           BULK COLLECT 
           INTO l_header_rec.header_id
              , l_header_rec.hold_id
              , l_header_rec.hold_source_id
              , l_header_rec.order_hold_id;
          CLOSE c_hold;
 
        END IF;
      
        OE_DEBUG_PUB.add('payment_amount::'||lc_payment_rec.payment_amount(1));
        IF lc_payment_rec.payment_set_id(1) IS NULL AND lc_order_source <> 'POE' THEN

            XX_OM_SALES_ACCT_PKG.Create_Receipt_payment
               ( p_payment_rec   => lc_payment_rec
               , p_request_id    => NULL
               , p_run_mode      => 'SOI'
               , x_return_status => lc_return_status);

        ELSIF lc_payment_rec.payment_set_id(1) IS NOT NULL THEN
            OE_DEBUG_PUB.add('payment_set_id:::'||lc_payment_rec.payment_set_id(1));
            lc_return_status := 'S';
        
        ELSIF lc_order_source = 'POE' AND lc_payment_rec.payment_set_id(1) IS NULL THEN 
	    OE_DEBUG_PUB.add('Order source IS :::'||lc_order_source || '  No Need to create Receipt');
            lc_return_status := 'S';
            
        ELSE
            lc_return_status := 'E';

        END IF;
              
        IF ln_debug_level > 0 THEN
          OE_DEBUG_PUB.add('Return Status from SOI Mode: '|| lc_return_status);
        END IF; 
                                                       
        IF (lc_return_status = 'S')
        AND (lc_payment_rec.payment_set_id(1) IS NOT NULL OR lc_order_source = 'POE')  THEN
            
            IF lc_payment_rec.payment_set_id(1) IS NOT NULL THEN       
                /* SDM Changes */
                UPDATE xx_ar_order_receipt_dtl
	           SET cash_receipt_id = TO_NUMBER(lc_payment_rec.attribute15(1))
	             , receipt_number  = (SELECT receipt_number 
	                                    FROM ar_cash_receipts_all 
	                                   WHERE cash_receipt_id = TO_NUMBER(lc_payment_rec.attribute15(1))
	                                 )
	             , payment_set_id  = lc_payment_rec.payment_set_id(1)
	         WHERE header_id       = lc_payment_rec.header_id(1)
	           AND payment_number  = lc_payment_rec.payment_number(1);
            END IF;
            
            ln_processed_success := ln_processed_success + lc_payment_rec.header_id.COUNT;
        
            IF l_header_rec.header_id(1) IS NOT NULL THEN
                -- Now Remove the hold on the order
                l_hold_source_rec.hold_source_id := l_header_rec.hold_source_id(1);
                l_hold_source_rec.hold_id        := l_header_rec.hold_id(1);

                l_hold_release_rec.release_reason_code := 'PREPAYMENT';
                l_hold_release_rec.release_comment     := 'Manually Fixed By User';
                l_hold_release_rec.hold_source_id      := l_header_rec.hold_source_id(1);
                l_hold_release_rec.order_hold_id       := l_header_rec.order_hold_id(1);
                
                l_order_rec.header_id                  := l_header_rec.header_id(1);

                OE_DEBUG_PUB.add('HEADER_ID      : ' ||l_header_rec.header_id(1));
                OE_DEBUG_PUB.add('HOLD_SOURCE_ID : ' ||l_header_rec.hold_source_id(1));
                OE_DEBUG_PUB.add('HOLD_ID        : ' ||l_header_rec.hold_id(1));
                
                IF lc_order_source = 'POE' THEN
                    OE_Holds_Pvt.release_orders ( p_hold_release_rec   => l_hold_release_rec
		                                , p_order_rec          => l_order_rec
		                                , p_hold_source_rec    => l_hold_source_rec
		                                , x_return_status      => lc_return_status
		                                , x_msg_count          => ln_msg_count
		                                , x_msg_data           => lc_msg_data
                                                );
                    OE_DEBUG_PUB.add('Hold Return Status FOR POE ORD::'||lc_return_status);                                
                ELSE 
                    OE_HOLDS_PUB.Release_Holds
                        ( p_hold_source_rec  => l_hold_source_rec
                        , p_hold_release_rec => l_hold_release_rec
                        , x_return_status    => lc_return_status
                        , x_msg_count        => ln_msg_count
                        , x_msg_data         => lc_msg_data);
          
                    OE_DEBUG_PUB.add('Hold Return Status::'||lc_return_status);
                    
                END IF;
                COMMIT;
				
				IF lc_return_status = 'E' AND lc_msg_data not like '%hold not authorized%' THEN--As per Ver 1.3
          
                                                                                
                                                                                
                      --this insert script will generate the hold release id                                                          
                     INSERT INTO OE_HOLD_RELEASES(HOLD_RELEASE_ID,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,HOLD_SOURCE_ID,RELEASE_REASON_CODE,RELEASE_COMMENT) 
                     VALUES (OE_HOLD_RELEASES_S.NEXTVAL,SYSDATE,fnd_global.user_id,SYSDATE,fnd_global.user_id,l_header_rec.hold_source_id(1),'PREPAYMENT','Manually Fixed By User');
                      COMMIT;
                                                                                
                      SELECT hold_release_id INTO l_hold_release_id FROM OE_HOLD_RELEASES WHERE hold_source_id = l_header_rec.hold_source_id(1);
                                                                                
                     OE_DEBUG_PUB.add('Hold Release Id : ' || l_hold_release_id);
                                                                                
                                                                                 
                     UPDATE OE_ORDER_HOLDS_ALL SET hold_release_id = l_hold_release_id ,released_flag='Y' WHERE header_id = ln_header_id 
                     AND hold_source_id=l_header_rec.hold_source_id(1) AND order_hold_id=l_header_rec.order_hold_id(1);

                
                     UPDATE OE_HOLD_SOURCES_ALL SET released_flag='Y',hold_release_id = l_hold_release_id  WHERE hold_source_id=l_header_rec.hold_source_id(1);
                                                                                
          
                     COMMIT; 
					 lc_return_status := 'S';
					 OE_DEBUG_PUB.add('Hold Return Status::'||lc_return_status);
					 
					 
					 
                                                                                 
                     END IF;----End of Ver 1.3  
          
            ELSE
                OE_DEBUG_PUB.add('NO Hold is Applied');   
          
            END IF;

               IF lc_return_status = 'S' THEN
               IF lc_flow_status_code = 'INVOICE_HOLD' THEN 
               -- IF Hold is release and receipt is created sucessful then progress the order
                 WF_ENGINE.CompleteActivityInternalName
                      ( itemtype              => 'OEOH'
                      , itemkey               => l_header_rec.header_id(1)
                      , activity              => 'HDR_INVOICE_INTERFACE_ELIGIBLE'
                      , result                => NULL
                      );
               ELSIF lc_flow_status_code = 'ENTERED' THEN
               -- IF hold is released and receipt is created then progress order
                 WF_ENGINE.CompleteActivityInternalName
                               ( itemtype  => 'OEOH'
                               , itemkey   => l_header_rec.header_id(1)
                               , activity  => 'BOOK_ELIGIBLE'
                               , result    => NULL
                               );
               ELSE
                 OE_DEBUG_PUB.add('Flow Status Code Not in Invoice Hold');
               END IF;
               END IF;
        ELSE
          ln_processed_failed := ln_processed_failed + lc_payment_rec.header_id.COUNT;
          
          x_return_code := 1;
          x_error_buffer := SQLERRM;
          
          FOR idx IN 1.. FND_MSG_PUB.count_msg() LOOP
            OE_DEBUG_PUB.add( idx || ': ' || FND_MSG_PUB.get(idx,'F') );
          END LOOP;          
          
        END IF;
    
      END IF;
         
      COMMIT;
  
    END LOOP;
  END IF;
  
  put_out_line('OD: Release Payment Holds');
  put_out_line();
  put_out_line('  Found ' || NVL(ln_order_total,0) || ' orders with a Payment Hold.');
  put_out_line('  Found ' || NVL(ln_payment_total,0) || ' payments for these orders.');
  put_out_line();
  put_out_line('  Payments successfully processed: ' || NVL(ln_processed_success,0) );
  put_out_line('  Payments that failed: ' || NVL(ln_processed_failed,0) );

EXCEPTION
  WHEN OTHERS THEN
    x_return_code := 2;
    x_error_buffer := SQLERRM;
    XX_COM_ERROR_LOG_PUB.log_error 
    ( p_program_type            => 'CONCURRENT PROGRAM',
      p_program_name            => 'XX_OM_SA_HOLDS_PKG',
      p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID,
      p_module_name             => 'OM',
      p_error_location          => 'Error in Release Payment Holds',
      p_error_message_count     => 1,
      p_error_message_code      => 'E',
      p_error_message           => SQLERRM,
      p_error_message_severity  => 'Major',
      p_notify_flag             => 'N',
      p_object_type             => 'Release_Payment_Holds' );
    RAISE;    
END;

END;
/
SHOW ERRORS;
EXIT;