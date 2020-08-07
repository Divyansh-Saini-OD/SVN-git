--  Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--
--  FILENAME
--
--      OEXVPPYB.pls
--
--  DESCRIPTION
--
--      Body of package OE_PrePayment_PVT
--
--  NOTES
--      This package body contains  the  procedures to process prepayment
--      for prepaid orders. AR's prepayment ARI will be called to either
--      create receipt or refund depending on the pending amount of the
--      order.
--
--  HISTORY
--      Created              		08-FEB-2002  Linda Xu 

SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE

CREATE OR REPLACE PACKAGE BODY OE_PrePayment_PVT AS
/* $Header: OEXVPPYB.pls 115.69.11510.18 2007/04/17 17:23:03 vybhatia ship $ */

G_PKG_NAME    CONSTANT VARCHAR2(30) := 'OE_PrePayment_PVT';

/*--------------------------------------------------------------------
Function Total_Invoiced_Amount
Returns the invoiced amount for the order. Added for Bug 4938104   
---------------------------------------------------------------------*/
FUNCTION Total_Invoiced_Amount 
(
 p_header_id     IN NUMBER
) RETURN NUMBER
IS
l_order_total     NUMBER;
l_tax_total       NUMBER;
l_charges         NUMBER;
l_invoice_total   NUMBER;
l_commitment_total NUMBER;
l_chgs_w_line_id   NUMBER := 0;
l_chgs_wo_line_id  NUMBER := 0;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
	
  IF OE_ORDER_UTIL.G_Precision IS NULL THEN
     OE_ORDER_UTIL.G_Precision:=2;
  END IF;	

  -- Select the Tax Total and Outbound Extended Price
  SELECT 
    SUM(ROUND(nvl(ool.tax_value,0), OE_ORDER_UTIL.G_Precision))
  , SUM(ROUND(nvl(ool.Ordered_Quantity,0)
	   *(ool.unit_selling_price), OE_ORDER_UTIL.G_Precision))
  INTO   
    l_tax_total
  , l_order_total 
  FROM  oe_order_lines_all ool
  WHERE ool.header_id      = p_header_id
  AND   ool.open_flag = 'N'
  AND   ool.cancelled_flag = 'N'
  AND   ool.line_category_code <> 'RETURN'
  AND   NOT EXISTS 
       (SELECT 'Non Invoiceable Item Line'
        FROM   mtl_system_items mti
        WHERE  mti.inventory_item_id = ool.inventory_item_id
        AND    mti.organization_id   = nvl(ool.ship_from_org_id, 
                         oe_sys_parameters.value('MASTER_ORGANIZATION_ID'))
        AND   (mti.invoiceable_item_flag = 'N'
           OR  mti.invoice_enabled_flag  = 'N'));

  IF OE_Commitment_Pvt.Do_Commitment_Sequencing THEN
    -- Select the committment applied amount if Commitment Sequencing "On"
    SELECT SUM(ROUND(nvl(op.commitment_applied_amount,0), OE_ORDER_UTIL.G_Precision))
    INTO   l_commitment_total 
    FROM   oe_payments op
    WHERE  op.header_id = p_header_id
    AND    NOT EXISTS 
          (SELECT 'Non Invoiceable Item Line'
           FROM   mtl_system_items mti, oe_order_lines_all ool
           WHERE  ool.line_id           = op.line_id
           AND    mti.inventory_item_id = ool.inventory_item_id
           AND    mti.organization_id   = nvl(ool.ship_from_org_id, 
                          oe_sys_parameters.value('MASTER_ORGANIZATION_ID'))
           AND   (mti.invoiceable_item_flag = 'N'
              OR  mti.invoice_enabled_flag  = 'N'));
  ELSE
   -- Select the Outbound Extended Price for lines that have committment
  SELECT SUM(ROUND(nvl(ool.Ordered_Quantity,0) *(ool.unit_selling_price), OE_ORDER_UTIL.G_Precision))
  INTO   l_commitment_total 
  FROM   oe_order_lines_all ool
  WHERE  ool.header_id      = p_header_id
  AND    ool.commitment_id is not null
  AND    ool.open_flag = 'N'
  AND    ool.cancelled_flag = 'N'
  AND    ool.line_category_code <> 'RETURN'
  AND   NOT EXISTS 
       (SELECT 'Non Invoiceable Item Line'
        FROM   mtl_system_items mti
        WHERE  mti.inventory_item_id = ool.inventory_item_id
        AND    mti.organization_id   = nvl(ool.ship_from_org_id, 
                         oe_sys_parameters.value('MASTER_ORGANIZATION_ID'))
        AND   (mti.invoiceable_item_flag = 'N'
           OR  mti.invoice_enabled_flag  = 'N'));
  END IF;

  -- Select the Outbound Charges Total
     SELECT SUM(
                ROUND(
                      DECODE(P.CREDIT_OR_CHARGE_FLAG,'C',-P.OPERAND,P.OPERAND), OE_ORDER_UTIL.G_Precision
				)
             )
     INTO l_chgs_wo_line_id
     FROM OE_PRICE_ADJUSTMENTS P
     WHERE P.HEADER_ID = p_header_id
     AND   P.LINE_ID IS NULL
     AND   P.LIST_LINE_TYPE_CODE = 'FREIGHT_CHARGE'
     AND   P.APPLIED_FLAG = 'Y'
     AND   NVL(P.INVOICED_FLAG, 'N') = 'N';

     SELECT SUM(
		ROUND(		
			DECODE(P.CREDIT_OR_CHARGE_FLAG,'C',
				DECODE(P.ARITHMETIC_OPERATOR, 'LUMPSUM',
					   -P.OPERAND,
					   (-L.ORDERED_QUANTITY*P.ADJUSTED_AMOUNT)),
				DECODE(P.ARITHMETIC_OPERATOR, 'LUMPSUM',
					   P.OPERAND,
					   (L.ORDERED_QUANTITY*P.ADJUSTED_AMOUNT))
			  )
		,OE_ORDER_UTIL.G_Precision
		)
              )
     INTO l_chgs_w_line_id
     FROM OE_PRICE_ADJUSTMENTS P,
          OE_ORDER_LINES_ALL L
     WHERE P.HEADER_ID = p_header_id
     AND   P.LINE_ID = L.LINE_ID
     AND   P.LIST_LINE_TYPE_CODE = 'FREIGHT_CHARGE'
     AND   P.APPLIED_FLAG = 'Y'
     AND   L.header_id      = p_header_id
	 AND   L.open_flag = 'N'
	 AND   L.cancelled_flag = 'N'
     AND   L.line_category_code <> 'RETURN'
     AND   NOT EXISTS 
          (SELECT 'Non Invoiceable Item Line'
           FROM   MTL_SYSTEM_ITEMS MTI
           WHERE  MTI.INVENTORY_ITEM_ID = L.INVENTORY_ITEM_ID
           AND    MTI.ORGANIZATION_ID   = NVL(L.SHIP_FROM_ORG_ID, 
                         oe_sys_parameters.value('MASTER_ORGANIZATION_ID'))
           AND   (MTI.INVOICEABLE_ITEM_FLAG = 'N'
              OR  MTI.INVOICE_ENABLED_FLAG  = 'N'));

    l_charges := nvl(l_chgs_wo_line_id,0) + nvl(l_chgs_w_line_id,0);

    l_invoice_total := nvl(l_order_total, 0) + nvl(l_tax_total, 0) 
				+ nvl(l_charges, 0) - nvl(l_commitment_total,0);

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: CALCULATING THE TOTAL INVOICED AMOUNT FOR THIS ORDER ' , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: TOTAL INVOICED AMOUNT ORDER : '||TO_CHAR ( L_ORDER_TOTAL ) , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: TOTAL INVOICED AMOUNT TAX : '||TO_CHAR ( L_TAX_TOTAL ) , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: TOTAL INVOICED AMOUNT COMMITMENTS : '||TO_CHAR ( L_COMMITMENT_TOTAL ) , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: TOTAL INVOICED AMOUNT OTHER CHARGES : '||TO_CHAR ( L_CHARGES ) , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: TOTAL_INVOICED_AMOUNT : '||TO_CHAR ( l_invoice_total ) , 1 ) ;
  END IF;
  RETURN (l_invoice_total);

  EXCEPTION 
    WHEN OTHERS THEN
	 IF l_debug_level  > 0 THEN
	     oe_debug_pub.add(  'FROM Total_Invoiced_Amount OTHERS' ) ;
	 END IF;
     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
	 
END Total_Invoiced_Amount;

/*--------------------------------------------------------------------------
Function Calculate_Pending_Amount
Returns the pending amount to be processed 
---------------------------------------------------------------------*/

FUNCTION Calculate_Pending_Amount
(  p_header_rec      IN   OE_Order_PUB.Header_Rec_Type)
RETURN NUMBER
IS
l_prepaid_amount    	NUMBER := 0;
l_pending_amount    	NUMBER := 0;
l_threshold         	NUMBER := 0;
l_outbound_total    	NUMBER := 0;
l_balance_on_prepaid_amount NUMBER := 0; --Bug 4938104

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: IN CALCULATE PENDING AMOUNT' , 1 ) ;
  END IF;

  -- Fetch the Order Total Amount
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: FETCH OUTBOUND LINES TOTAL' , 3 ) ;
  END IF;

  l_outbound_total := OE_OE_TOTALS_SUMMARY.Outbound_Order_Total(p_header_rec.header_id);

                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'OEXVPPYB: TOTAL VALUE OF OUTBOUND LINES : '|| L_OUTBOUND_TOTAL , 3 ) ;
                    END IF;

  BEGIN
    SELECT nvl(prepaid_amount, 0)
    INTO   l_prepaid_amount
    FROM   oe_payments
    WHERE  header_id= p_header_rec.header_id
    AND    payment_type_code = 'CREDIT_CARD';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    null;
  END;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: PREPAID_AMOUNT FOR THE ORDER IS: '||L_PREPAID_AMOUNT , 1 ) ;
  END IF;

  --Start Bug# 4938104
  l_balance_on_prepaid_amount := l_prepaid_amount - Total_Invoiced_Amount(p_header_rec.header_id);

  IF l_balance_on_prepaid_amount < 0 THEN
        l_balance_on_prepaid_amount := 0;
  END IF;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: BALANCE ON PREPAID_AMOUNT FOR THE ORDER IS: '||l_balance_on_prepaid_amount , 1 ) ;
  END IF;

  l_pending_amount := l_outbound_total - l_balance_on_prepaid_amount ;
  --End Bug# 4938104

  RETURN l_pending_amount;

END Calculate_Pending_Amount;

/*--------------------------------------------------------------------------
Procedure Create_Receipt 
This procedure calls AR API to create a new receipt for the amount specified.
----------------------------------------------------------------------------*/
PROCEDURE Create_Receipt 
(  p_header_rec      			IN   OE_Order_PUB.Header_Rec_Type
,  p_amount          			IN   NUMBER
,  p_receipt_method_id			IN   NUMBER
,  p_bank_acct_id			IN   NUMBER
,  p_bank_acct_uses_id			IN   NUMBER
,  p_payment_set_id			IN   OUT NOCOPY NUMBER
,  p_receipt_number                     IN   VARCHAR2             -- bug 4599773
,  x_payment_response_error_code	OUT  NOCOPY VARCHAR2
,  p_approval_code			IN   OUT  NOCOPY VARCHAR2
,  x_msg_count       			OUT  NOCOPY NUMBER
,  x_msg_data        			OUT  NOCOPY VARCHAR2
,  x_return_status   			OUT  NOCOPY VARCHAR2
,  x_result_out      			OUT  NOCOPY VARCHAR2
)
IS
l_bank_acct_id      		NUMBER ;
l_bank_acct_uses_id 		NUMBER ;
l_application_ref_id           	NUMBER := p_header_rec.header_id;
l_application_ref_num          	NUMBER := p_header_rec.order_number;
l_msg_count          		NUMBER := 0 ;
l_msg_data           		VARCHAR2(2000) := NULL ;
l_return_status      		VARCHAR2(30) := NULL ;
l_result_out         		VARCHAR2(30) := NULL ;
l_hold_exists        		VARCHAR2(1);
l_receipt_method_id  		NUMBER;
p_customer_id	     		NUMBER;
l_site_use_id	     		NUMBER;
l_payment_set_id                NUMBER;
l_application_ref_type 		VARCHAR2(30);
l_cr_id				NUMBER;
l_receivable_application_id	NUMBER;
l_call_payment_processor        VARCHAR2(30);
l_remittance_bank_account_id	NUMBER;
l_called_from			VARCHAR2(30);
l_secondary_application_ref_id 	NUMBER;
l_receipt_number		VARCHAR2(30);
p_bank_account_id		NUMBER;
l_payment_server_order_num	VARCHAR2(80);
l_trxn_id			NUMBER;
l_exchange_rate_type            VARCHAR2(30);
l_exchange_rate                 NUMBER;
l_exchange_rate_date            DATE; 
l_set_of_books_rec              OE_Order_Cache.Set_Of_Books_Rec_Type;
l_msg_text                        VARCHAR2(2000);

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ENTERING OE_PREPAYMENT_PV.CREATE_RECEIPT.' , 1 ) ;
  END IF;
  x_result_out := 'PASS' ;
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: CALLING AR CREATE RECEIPT API ' , 3 ) ;
  END IF;
  l_payment_set_id := p_payment_set_id;

  -- To get the remittance bank account id. 
  BEGIN
    SELECT ba.bank_account_id
    INTO   l_remittance_bank_account_id
    FROM   ar_receipt_methods rm,
           ap_bank_accounts ba,
           ar_receipt_method_accounts rma ,
           ar_receipt_classes rc
    WHERE  rm.receipt_method_id = p_receipt_method_id
    and    rm.receipt_method_id = rma.receipt_method_id
    and    rc.receipt_class_id = rm.receipt_class_id
    and    rc.creation_method_code = 'AUTOMATIC'
    and    rma.bank_account_id = ba.bank_account_id
    and    ba.account_type = 'INTERNAL'
    and    ba.currency_code = decode(ba.receipt_multi_currency_flag, 'Y'
                                    ,ba.currency_code 
                                    ,p_header_rec.transactional_curr_code)
    and    rma.primary_flag = 'Y';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    null;
  END;

  -- to get the p_payment_server_order_num (i.e. tangible_id) for
  -- the credit_card_approval_code
  IF p_approval_code IS NOT NULL THEN

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: FETCHING THE TANGIBLE ID.' , 3 ) ;
    END IF;
    OE_Verify_Payment_PUB.Fetch_Current_Auth
			( p_header_rec  => p_header_rec
			, p_trxn_id     => l_trxn_id
			, p_tangible_id => l_payment_server_order_num
			);
  END IF;

  l_set_of_books_rec := OE_Order_Cache.Load_Set_Of_Books;
  IF p_header_rec.transactional_curr_code
                  = l_set_of_books_rec.currency_code THEN
     l_exchange_rate_type := null;
     l_exchange_rate := null;
     l_exchange_rate_date := null;
  ELSE
     l_exchange_rate_type := p_header_rec.conversion_type_code;
     l_exchange_rate := p_header_rec.conversion_rate;
     l_exchange_rate_date := p_header_rec.conversion_rate_date;

  END IF;


  -- seeded lookup_code for AR lookup_type 'AR_PREPAYMENT_TYPE' is 'OM'.
  l_application_ref_type := 'OM';
  l_application_ref_num  := p_header_rec.order_number;
  l_application_ref_id   := p_header_rec.header_id;

  p_bank_account_id := null;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: before calling AR Create_Prepayment: '||p_header_rec.header_id , 3 ) ;
      oe_debug_pub.add(  'OEXVPPYB: p_approval_code is: '||p_approval_code , 3 ) ;
      oe_debug_pub.add(  'OEXVPPYB: tangible_id is: '||l_payment_server_order_num , 3 ) ;
  END IF;

  AR_PREPAYMENTS.create_prepayment(
            p_api_version       	=> 1.0,
            p_commit            	=> FND_API.G_FALSE,
            p_validation_level		=> FND_API.G_VALID_LEVEL_FULL,
            x_return_status     	=> x_return_status,
            x_msg_count         	=> x_msg_count,
            x_msg_data          	=> x_msg_data,
            p_init_msg_list     	=> FND_API.G_TRUE,
            p_receipt_number    	=> p_receipt_number,  -- bug 4599773
            p_amount            	=> p_amount, -- pending_amount,
            p_receipt_method_id 	=> p_receipt_method_id,
            p_customer_id       	=> p_header_rec.sold_to_org_id,
            p_customer_site_use_id 	=> p_header_rec.invoice_to_org_id,
            p_customer_bank_account_id 	=> p_bank_acct_id,
            p_currency_code     	=> p_header_rec.transactional_curr_code,
            p_exchange_rate     	=> l_exchange_rate,
            p_exchange_rate_type 	=> l_exchange_rate_type,
            p_exchange_rate_date 	=> l_exchange_rate_date,
            p_applied_payment_schedule_id => -7,  -- hard coded.
            p_application_ref_type      => l_application_ref_type ,
            p_application_ref_num 	=> l_application_ref_num, --Order Number
            p_application_ref_id 	=> l_application_ref_id, --Order Id
            p_cr_id             	=> l_cr_id, --OUT
            p_receivable_application_id => l_receivable_application_id, --OUT
            p_call_payment_processor 	=> FND_API.G_TRUE,
            p_remittance_bank_account_id => l_remittance_bank_account_id,
            p_called_from	        => 'OM',
            p_payment_server_order_num  => l_payment_server_order_num,
            p_approval_code	        => p_approval_code,
            p_secondary_application_ref_id => l_secondary_application_ref_id,
            p_payment_response_error_code  => x_payment_response_error_code,
            p_payment_set_id  		   => p_payment_set_id
            );


  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT CASH_RECEIPT_ID IS: '||L_CR_ID , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT PAYMENT_SET_ID IS: '||P_PAYMENT_SET_ID , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT CHECK NUMBER IS: '||P_RECEIPT_NUMBER , 1 ) ; -- bug 4599773
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT x_payment_response_error_code IS: '||x_payment_response_error_code , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT approval_code IS: '||p_approval_code , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: AFTER AR CREATE_PREPAYMENT RETURN STATUS IS: '||X_RETURN_STATUS , 1 ) ;
  END IF;

   IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
    IF x_msg_count = 1 THEN
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add('Error message after calling Create_Prepayment API: '||x_msg_data , 3 ) ;
      END IF;
      oe_msg_pub.add_text(p_message_text => x_msg_data);
    ELSIF ( FND_MSG_PUB.Count_Msg > 0 ) THEN
       arp_util.enable_debug;
       FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
        -- l_msg_text := FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE);
         l_msg_text := FND_MSG_PUB.Get(i,'F');
         IF l_msg_text IS NOT NULL THEN
           IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  L_MSG_TEXT , 3 ) ;
           END IF;
           oe_msg_pub.add_text(p_message_text => l_msg_text);
         END IF;
       END LOOP;
    END IF;

    x_result_out := 'FAIL';

    -- RETURN;
  END IF;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'EXITING OE_PREPAYMENT_PV.CREATE_RECEIPT.' , 1 ) ;
  END IF;

  EXCEPTION WHEN OTHERS THEN
    x_result_out := 'FAIL';
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF l_debug_level  > 0 THEN
      oe_debug_pub.add('Unexpected error in Create_Prepayment API: '||sqlerrm , 3 ) ;
    END IF;

    IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
      FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME , 'Create_Receipt');
    END IF;

  OE_MSG_PUB.Count_And_Get
     ( p_count => l_msg_count,
       p_data  => l_msg_data
      );      

END Create_Receipt;

/*--------------------------------------------------------------------------
Procedure Refund_Request
This procedure calls AR API to submit refund request for the amount specified.
----------------------------------------------------------------------------*/
PROCEDURE Refund_Request 
(  p_header_rec      IN   OE_Order_PUB.Header_Rec_Type
,  p_amount          IN   NUMBER
,  p_payment_set_id  IN   NUMBER
,  x_msg_count       OUT  NOCOPY NUMBER
,  x_msg_data        OUT  NOCOPY VARCHAR2
,  x_return_status   OUT  NOCOPY VARCHAR2
,  x_result_out      OUT  NOCOPY VARCHAR2
)
IS

l_return_status			VARCHAR2(30);
l_prepay_application_id		NUMBER;
l_number_of_refund_receipts	NUMBER;
l_receipt_number		VARCHAR2(30);
l_payment_set_id		NUMBER;
l_refund_amount			NUMBER;
l_format_mask			VARCHAR2(500);
l_msg_count          		NUMBER := 0 ;
l_msg_data           		VARCHAR2(2000) := NULL ;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'ENTERING OE_PREPAYMENT_PV.REFUND_REQUEST.' , 1 ) ;
    oe_debug_pub.add(  'BEFORE CALLING REFUND_PREPAYMENTS PAYMENT_SET_ID IS: '||P_PAYMENT_SET_ID , 1 ) ;
END IF;

AR_PREPAYMENTS.refund_prepayments(
            p_api_version       	=> 1.0,
            p_commit            	=> FND_API.G_FALSE,
            p_validation_level		=> FND_API.G_VALID_LEVEL_FULL,
            x_return_status     	=> l_return_status,
            x_msg_count         	=> x_msg_count,
            x_msg_data          	=> x_msg_data,
            p_init_msg_list     	=> FND_API.G_TRUE,
            p_prepay_application_id     => l_prepay_application_id, -- OUT
            p_number_of_refund_receipts => l_number_of_refund_receipts,
--          p_receipt_number		=> l_receipt_number,
            p_receivables_trx_id	=> null,
            p_refund_amount		=> p_amount * (-1),
            p_payment_set_id		=> p_payment_set_id
            );

     x_return_status := l_return_status;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: RECEIPT_NUMBER AFTER CALLING AR REFUND_PREPAYMENTS IS: '||L_RECEIPT_NUMBER , 1 ) ;
         oe_debug_pub.add(  'OEXVPPYB: NUMBER_OF_REFUND AFTER CALLING AR REFUND_PREPAYMENT IS: '||L_NUMBER_OF_REFUND_RECEIPTS , 1 ) ;
     END IF;

     l_format_mask := get_format_mask(p_header_rec.transactional_curr_code);

     IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
       fnd_message.Set_Name('ONT', 'ONT_REFUND_PROCESS_SUCCESS');
       FND_MESSAGE.SET_TOKEN('AMOUNT' , TO_CHAR(p_amount * -1, l_format_mask));
       FND_MESSAGE.SET_TOKEN('NUMBER' , l_number_of_refund_receipts);
       oe_msg_pub.add;
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: REFUND REQUEST OF ' ||P_AMOUNT||' HAS BEEN PROCESSED SUCCESSFULLY.' , 3 ) ;
       END IF;
     ELSE
       fnd_message.Set_Name('ONT', 'ONT_REFUND_PROCESS_FAILED');
       FND_MESSAGE.SET_TOKEN('AMOUNT', TO_CHAR(p_amount, l_format_mask));
       oe_msg_pub.add;
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: REFUND PROCESSING FOR ' ||P_AMOUNT||' FAILED.' , 3 ) ;
       END IF;
     END IF;

   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'EXITING OE_PREPAYMENT_PV.REFUND_REQUEST.' , 1 ) ;
   END IF;

  EXCEPTION WHEN OTHERS THEN
    x_result_out := 'FAIL';
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

  IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
    FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME , 'Refund_Request');
  END IF;

  OE_MSG_PUB.Count_And_Get
     ( p_count => l_msg_count,
       p_data  => l_msg_data
      );      

END Refund_Request;

/*--------------------------------------------------------------------------
Procedure Process_PrePayment_Order
This is the main procedure for PrePayment. It is called from 
OE_Verify_Payment_PUB.Verify_Payment for those prepaid orders.
----------------------------------------------------------------------------*/
PROCEDURE Process_PrePayment_Order
(  p_header_rec      		IN   OE_Order_PUB.Header_Rec_Type
,  p_calling_action  		IN   VARCHAR2
,  p_delayed_request 		IN   VARCHAR2
,  x_msg_count       		OUT  NOCOPY NUMBER
,  x_msg_data        		OUT  NOCOPY VARCHAR2
,  x_return_status   		OUT  NOCOPY VARCHAR2 
)
IS

-- get all the lines for those haven't got INVOICE_INTERFACE_STATUS_CODE
-- populated.
CURSOR line_csr(p_header_id IN NUMBER) IS
  SELECT line_id 
  FROM   oe_order_lines
  WHERE  NVL(INVOICE_INTERFACE_STATUS_CODE, 'N') <> 'PREPAID'
  AND    header_id = p_header_id;


l_calling_action    		VARCHAR2(30) := p_calling_action;
l_header_rec        		OE_Order_PUB.Header_Rec_Type := p_header_rec;
l_pending_amount    		NUMBER := 0;
l_create_receipt    		VARCHAR2(1)   := 'N';
l_request_refund    		VARCHAR2(1)   := 'N';
l_apply_ppp_hold    		VARCHAR2(1)   := 'N';
l_epayment_failure_hold 	VARCHAR2(1)   := 'N';
l_ppp_hold_exists    		VARCHAR2(1)   := 'N';
l_process_payment   		VARCHAR2(1)   := 'N';
l_hold_exists       		VARCHAR2(1);
l_hold_source_rec   		OE_Holds_PVT.Hold_Source_REC_type;
l_threshold_amount  		NUMBER := 0;
l_bank_acct_id	    		NUMBER;
l_bank_acct_uses_id 		NUMBER;
l_payment_response_error_code	VARCHAR2(80);
l_approval_code			VARCHAR2(80);
l_pay_method_id			NUMBER;
l_exists_prepay			VARCHAR2(1) := 'N';
l_line_id		        NUMBER;
l_payment_set_id		NUMBER;
l_receipt_number		VARCHAR2(30);  -- bug 4599773
l_payment_types_rec             OE_PAYMENTS_UTIL.Payment_Types_Rec_Type;
l_hold_result   		VARCHAR2(30);
l_msg_count         		NUMBER := 0 ;
l_msg_data          		VARCHAR2(2000):= NULL ;
l_result_out        		VARCHAR2(30)   := NULL ;
l_return_status     		VARCHAR2(30)   := NULL ;
l_fnd_profile_value 		VARCHAR2(1);
l_format_mask			VARCHAR2(500);
l_trx_date			DATE;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: ENTERING PROCESS PREPAYMENT ORDER' , 1 ) ;
  END IF;
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  -- calculate pending amount to be processed 
  l_pending_amount := OE_PrePayment_PVT.Calculate_Pending_Amount(l_header_rec);
  
  -- START :This is customised for OD so that no out of the BOX pre-payment is triggered from Order Import
  l_pending_amount := 0;
  -- END of customization

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: PENDING AMOUNT IS: '||L_PENDING_AMOUNT , 3 ) ;
  END IF;
  IF l_pending_amount = 0 THEN 
    -- no payment processing needed
    Release_Prepayment_Hold ( p_header_id     => p_header_rec.header_id
                            , p_msg_count     => l_msg_count
                            , p_msg_data      => l_msg_data
                            , p_return_status => l_return_status
                            );

    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    RETURN;   
  END IF;

  /**************************************************************** 
  if calling_action is NULL (this is coming from user action), then
     if there is delta, then process payment.
  if calling action is UPDATE (this is coming from delayed request), 
     or p_delayed_request is true, then
     - if delta <> 0, apply PPP hold.(at this point order has been booked)
     - else return.
  if calling action is BOOKING, then
     - if there is no ppp hold on the order(first time booking), 
          and profile option is set to be immediate at booking, then
	  process payment.
     - else (there is ppp hold on the order, this comes from commit changes)
          return.
  else for other calling action, just return.

  Error handler:
  if AR API returns with error, apply credit card failure hold.
  if AR API returns with success, release PPP hold and credit card failure hl.
  *******************************************************************/
  
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: CALLING ACTION IS: '||L_CALLING_ACTION , 3 ) ;

  END IF;

  IF l_calling_action = 'UPDATE' THEN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'IN OEXVPPYB.PLS: THIS IS COMING FROM DELAYED REQUEST.' , 1 ) ;
     END IF;
     -- Need to apply PPP hold if there is change to order line after booking.

     l_apply_ppp_hold := 'Y';

  ELSIF l_calling_action = 'BOOKING' THEN
    -- check if there is any ppp hold exists
    OE_Verify_Payment_PUB.Hold_Exists
                        ( p_header_id   => p_header_rec.header_id
                        , p_hold_id     => 13   -- Seeded id for ppp hold
                        , p_hold_exists => l_ppp_hold_exists
                        );

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: VALUE FOR L_PPP_HOLD_EXISTS IS: '||L_PPP_HOLD_EXISTS , 1 ) ;
    END IF;
  
    l_fnd_profile_value := fnd_profile.value('ONT_PROCESS_PAYMENT_IMMEDIATELY');

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: VALUE FOR PREPAYMENT PROFILE OPTION IS : '||L_FND_PROFILE_VALUE , 1 ) ;
    END IF;

    IF l_ppp_hold_exists = 'N' THEN  
      IF l_fnd_profile_value= 'Y' THEN
        l_process_payment := 'Y';
      ELSE 
        l_apply_ppp_hold := 'Y';
      END IF;
    ELSE 
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'NO ACTION REQUIRED AS HOLD ALREADY EXISTS FOR HEADER: '||P_HEADER_REC.HEADER_ID , 3 ) ;
      END IF;
      RETURN;
    END IF;
     
  ELSIF l_calling_action is NULL THEN 
     -- this is coming from Action Process Payment or Concurrent Program.
     l_process_payment := 'Y';
 
     IF p_delayed_request is NULL THEN
       -- this is coming from concurrent manager, need to release all prepayment holds.
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'OEXVPPYB: RELEASING ALL PREPAYMENT HOLDS AS THIS IS FROM CONCURRENT MANAGER.' , 1 ) ;
       END IF;
       Release_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

       IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         RAISE FND_API.G_EXC_ERROR;
       ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;
     END IF;
     
  ELSE 
    -- no processing for other calling action
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO ACTION REQUIRED AS CALLING_ACTION IS INVALID.' , 3 ) ;
    END IF;
    RETURN; 
  END IF;


  IF l_process_payment = 'Y' THEN
    IF l_pending_amount < 0 THEN
      l_request_refund := 'Y';
    ELSE
      -- to get bank account id.
      BEGIN

        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: CURRENCY_CODE IS: '||P_HEADER_REC.TRANSACTIONAL_CURR_CODE , 3 ) ;
            oe_debug_pub.add(  'OEXVPPYB: SOLD_TO_ORG_ID IS: '||P_HEADER_REC.SOLD_TO_ORG_ID , 3 ) ;
            oe_debug_pub.add(  'OEXVPPYB: INVOICE_TO_ORG_ID IS: '||P_HEADER_REC.INVOICE_TO_ORG_ID , 3 ) ;
--            oe_debug_pub.add(  'OEXVPPYB: CREDIT_CARD_NUMBER IS: '||P_HEADER_REC.CREDIT_CARD_NUMBER , 3 ) ; --Commenting for 11i CC Encryption project
            oe_debug_pub.add(  'OEXVPPYB: CREDIT_CARD_HOLDER IS: '||P_HEADER_REC.CREDIT_CARD_HOLDER_NAME , 3 ) ;
            oe_debug_pub.add(  'OEXVPPYB: CREDIT_CARD_EXP IS: '||P_HEADER_REC.CREDIT_CARD_EXPIRATION_DATE , 3 ) ;
        END IF;

       -- bug 3486808
       l_trx_date := nvl(p_header_rec.ordered_date, sysdate) 
                    - nvl( to_number(fnd_profile.value('ONT_DAYS_TO_BACKDATE_BANK_ACCT')), 0);

       arp_bank_pkg.process_cust_bank_account
	             ( p_trx_date         => l_trx_date
	             , p_currency_code    => p_header_rec.transactional_curr_code
      	             , p_cust_id          => p_header_rec.sold_to_org_id
	             , p_site_use_id      => p_header_rec.invoice_to_org_id
	             , p_credit_card_num  => p_header_rec.credit_card_number
	             , p_acct_name        => p_header_rec.credit_card_holder_name 
	             , p_exp_date         => p_header_rec.credit_card_expiration_date
	             , p_bank_account_id      => l_bank_acct_id
	             , p_bank_account_uses_id => l_bank_acct_uses_id
	             ) ;

      EXCEPTION WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('ONT','OE_VPM_CC_ACCT_NOT_SET');
        OE_MSG_PUB.ADD;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: ERROR IN ARP_BANK_PKG.PROCESS_CUST_BANK_ACCOUNT' , 3 ) ;
        END IF;
        -- apply epayment failure hold due to incorrect credit card information.
        l_epayment_failure_hold := 'Y';
        l_create_receipt := 'N';
      END;

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: BANK ACCOUNT ID IS : '||L_BANK_ACCT_ID , 3 ) ;
      END IF;

      l_pay_method_id := OE_Verify_Payment_PUB.Get_Primary_Pay_Method
                         (p_header_rec => p_header_rec );

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: THE PRIMARY PAYMENT METHOD ID IS: '||L_PAY_METHOD_ID , 3 ) ;
      END IF;

      -- to validate the pay_method_id.
      IF l_pay_method_id <= 0 THEN

        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: THE PAYMENT METHOD ID IS INVALID: '||L_PAY_METHOD_ID , 3 ) ;
        END IF;
        FND_MESSAGE.SET_NAME('ONT','OE_VPM_NO_PAY_METHOD');
        OE_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        RETURN;
      END IF;

      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: L_RECEIPT_METHOD_ID IS: '||L_PAY_METHOD_ID , 1 ) ;
      END IF;

      l_create_receipt := 'Y';
    END IF;
  END IF;   -- end of checking if l_process_payment is 'Y'.

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: L_PROCESS_PAYMENT IS: '||L_PROCESS_PAYMENT , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: L_CREATE_RECEIPT IS: '||L_CREATE_RECEIPT , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: L_APPLY_PPP_HOLD IS: '||L_APPLY_PPP_HOLD , 1 ) ;
  END IF;

  -- at this point, either apply hold or process payment.
  IF l_apply_ppp_hold = 'Y' THEN

   
    -- check for existing hold and apply hold if it doesn't exist already.
    Apply_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                          , p_hold_id       => 13   -- Seed Id for PPP Hold
                          , p_msg_count     => l_msg_count
                          , p_msg_data      => l_msg_data
                          , p_return_status => l_return_status
                          );
  
    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN

      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: ORDER IS PLACED ON PPP HOLD.' , 3 ) ;
      END IF;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
 
  ELSIF l_epayment_failure_hold = 'Y' THEN
     Apply_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                          , p_hold_id       => 14   --  Seed Id for PPP Hold
                          , p_msg_count     => l_msg_count
                          , p_msg_data      => l_msg_data
                          , p_return_status => l_return_status
                          );
     IF l_return_status = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
     ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;
  ELSE
    -- otherwise, call AR API to either create receipt or request refund.
    -- check the installation status of IPayment
    IF OE_GLOBALS.G_IPAYMENT_INSTALLED IS NULL THEN
      OE_GLOBALS.G_IPAYMENT_INSTALLED := OE_GLOBALS.CHECK_PRODUCT_INSTALLED(673);
    END IF;

    IF OE_GLOBALS.G_IPAYMENT_INSTALLED <> 'Y' THEN
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: IPAYMENT IS NOT INSTALLED!' , 3 ) ;
      END IF;
      RETURN;
    END IF;

    IF l_create_receipt = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: BEFORE CALLING AR API TO CREATE RECEIPT.' , 2 ) ;
          oe_debug_pub.add(  'OEXVPPYB: BEFORE CHECKING THE TRANSACTION TYPE' , 3 ) ;
          oe_debug_pub.add(  'OEXVPPYB: CALLING CREATE RECEIPT' , 3 ) ;
      END IF;

      -- call create receipt API
      BEGIN
        SELECT payment_set_id, check_number  -- bug 4599773
        INTO   l_payment_set_id, l_receipt_number
        FROM   oe_payments
        WHERE  header_id = l_header_rec.header_id
        AND    payment_type_code = 'CREDIT_CARD';
      EXCEPTION WHEN NO_DATA_FOUND THEN
        l_payment_set_id := null;
      END;

      l_approval_code := p_header_rec.credit_card_approval_code;

      OE_PrePayment_PVT.Create_Receipt
         ( p_header_rec   	    	=> p_header_rec
         , p_amount     	    	=> l_pending_amount
         , p_receipt_method_id 		=> l_pay_method_id
         , p_bank_acct_id 		=> l_bank_acct_id
         , p_bank_acct_uses_id 		=> l_bank_acct_uses_id
         , p_payment_set_id	        => l_payment_set_id
         , p_receipt_number	        => l_receipt_number  -- bug 4599773
         , x_payment_response_error_code=> l_payment_response_error_code
         , p_approval_code		=> l_approval_code
         , x_msg_count    	    	=> l_msg_count
         , x_msg_data     	    	=> l_msg_data
         , x_result_out        		=> l_result_out
         , x_return_status	    	=> l_return_status
         );

      IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: PAYMENT_SET_ID AFTER CREATE_RECEIPT: '||L_PAYMENT_SET_ID , 3 ) ;
         oe_debug_pub.add(  'OEXVPPYB: RECEIPT NUMBER AFTER CREATE_RECEIPT: '||L_RECEIPT_NUMBER , 3 ) ; -- bug 4599773
         oe_debug_pub.add(  'OEXVPPYB: RETURN_STATUS AFTER CALLING CREATE RECEIPT: '||L_RETURN_STATUS , 3 ) ;
      END IF;

      IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
        -- If no error occurred in processing the payment, release any existing
        -- prepayment holds.
        l_format_mask := get_format_mask(p_header_rec.transactional_curr_code);

        FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_PROCESS_SUCESS');
        FND_MESSAGE.SET_TOKEN('AMOUNT' , TO_CHAR(l_pending_amount, l_format_mask));
        OE_MSG_PUB.ADD;
  
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: RELEASING PREPAYMENT HOLD' , 3 ) ;
        END IF;
        Release_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

        IF l_return_status = FND_API.G_RET_STS_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- to either insert or update the prepaid amount to oe_payments.
        BEGIN
          SELECT 'Y'
          INTO   l_exists_prepay
          FROM   oe_payments
          WHERE  header_id = l_header_rec.header_id
          AND    payment_type_code = 'CREDIT_CARD';
        EXCEPTION WHEN NO_DATA_FOUND THEN
          l_exists_prepay := 'N';
        END;

        IF l_exists_prepay = 'Y' THEN
          -- update prepaid_amount on oe_order_headers
          UPDATE oe_payments
          SET    prepaid_amount = nvl(prepaid_amount,0) + l_pending_amount
          WHERE  header_id = l_header_rec.header_id
          AND   payment_type_code = 'CREDIT_CARD';
        ELSE
          l_payment_types_rec.header_id := l_header_rec.header_id;
          l_payment_types_rec.payment_set_id := l_payment_set_id;
          l_payment_types_rec.payment_type_code := 'CREDIT_CARD';
          l_payment_types_rec.payment_trx_id := l_bank_acct_id;
          l_payment_types_rec.payment_level_code := 'ORDER';
          l_payment_types_rec.prepaid_amount := l_pending_amount;
          l_payment_types_rec.credit_card_number := l_header_rec.credit_card_number;
          l_payment_types_rec.credit_card_code := l_header_rec.credit_card_code;
          l_payment_types_rec.credit_card_holder_name 
                              := l_header_rec.credit_card_holder_name;
          l_payment_types_rec.credit_card_expiration_date 
                              := l_header_rec.credit_card_expiration_date;
          l_payment_types_rec.creation_date := SYSDATE;
          l_payment_types_rec.created_by := FND_GLOBAL.USER_ID;
          l_payment_types_rec.last_update_date := SYSDATE;
          l_payment_types_rec.last_updated_by := FND_GLOBAL.USER_ID;

          oe_payments_util.insert_row(p_payment_types_rec => l_payment_types_rec);

        END IF;

        -- to update line information
        OPEN line_csr(l_header_rec.header_id);
        LOOP

          FETCH line_csr INTO l_line_id;
          UPDATE oe_order_lines
          SET    INVOICE_INTERFACE_STATUS_CODE = 'PREPAID'
          WHERE  line_id = l_line_id;
   
          EXIT WHEN line_csr%NOTFOUND;
        END LOOP;
        CLOSE line_csr;

      ELSE 
        -- if l_return_status is not FND_API.G_RET_STS_SUCCESS 
        -- decode the error code return from AR, and apply the necessary holds.
        -- check for the existing holds, and apply the holds if non-existance.
        -- what is the seed id for ppp hold?
   
        -- get the message count here, as we do not want to append
        -- the message ONT_PAYMENT_PROCESS_FAILED to the hold comments.
        l_msg_count:=OE_MSG_PUB.COUNT_MSG;

        l_format_mask := get_format_mask(p_header_rec.transactional_curr_code);

        FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_PROCESS_FAILED');
        FND_MESSAGE.SET_TOKEN('AMOUNT' , TO_CHAR(l_pending_amount, l_format_mask));
        OE_MSG_PUB.ADD;

        -- 4201622
        -- to pass the message to apply_prepayment_hold so that hold comments
        -- gets populated with the error messages from AR/iPayment.
        l_msg_data := null;
        FOR I IN 1..l_msg_count LOOP
          l_msg_data := l_msg_data||' '|| OE_MSG_PUB.Get(I,'F');
          IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  L_MSG_DATA , 1 ) ;
          END IF;
        END LOOP;

        -- check for existing hold and apply hold if it doesn't exist already.
        IF l_payment_response_error_code IN ('IBY_0001', 'IBY_0008')  THEN
          -- need to apply epayment server failure hold (seeded id is 15).
          IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: applying epayment server failure hold.' , 3 ) ;
          END IF;

          Apply_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                                , p_hold_id       => 15
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

          IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            RAISE FND_API.G_EXC_ERROR;
          ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
        ELSE
          -- for any other payment_response_error_code, need to apply epayment 
          -- failure hold (seeded hold id is 14).
          IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: applying epayment failure hold.' , 3 ) ;
          END IF;
          Apply_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                                , p_hold_id       => 14
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

          IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            RAISE FND_API.G_EXC_ERROR;
          ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;


        END IF;  -- end of checking l_payment_response_error_code.

      END IF;  -- end of checking AR API return status.

    ELSIF l_request_refund = 'Y' THEN

      BEGIN
        SELECT payment_set_id
        INTO   l_payment_set_id
        FROM   oe_payments
        WHERE  header_id = l_header_rec.header_id
        AND    payment_type_code = 'CREDIT_CARD';
      EXCEPTION WHEN NO_DATA_FOUND THEN
        l_payment_set_id := null;
      END;

      IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: PAYMENT_SET_ID PASSED TO REFUND_REQUEST IS: '||L_PAYMENT_SET_ID , 1 ) ;
         oe_debug_pub.add(  'OEXVPPYB: CALLING REFUND REQUEST.' , 3 ) ;
      END IF;
      OE_PrePayment_PVT.Refund_Request( p_header_rec   	=> p_header_rec
                                      , p_amount     	=> l_pending_amount
                                      , p_payment_set_id=> l_payment_set_id
                                      , x_msg_count    	=> l_msg_count
                                      , x_msg_data     	=> l_msg_data
                                      , x_result_out   	=> l_result_out
                                      , x_return_status	=> l_return_status
                                      );

     
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: RETURN STATUS AFTER CALLING REFUND IS: '||L_RETURN_STATUS , 1 ) ;
     END IF;

     IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
       IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: RELEASING PREPAYMENT HOLD AFTER REFUND PROCESS.' , 3 ) ;
        END IF;
        Release_Prepayment_Hold ( p_header_id     => l_header_rec.header_id
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

        IF l_return_status = FND_API.G_RET_STS_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       UPDATE oe_payments
       SET    prepaid_amount = nvl(prepaid_amount,0) + l_pending_amount
       WHERE  header_id = p_header_rec.header_id
       AND    payment_type_code = 'CREDIT_CARD';

       -- to update line information
       OPEN line_csr(l_header_rec.header_id);
       LOOP

         FETCH line_csr INTO l_line_id;
         UPDATE oe_order_lines
         SET    INVOICE_INTERFACE_STATUS_CODE = 'PREPAID'
         WHERE  line_id = l_line_id;
   
         EXIT WHEN line_csr%NOTFOUND;
       END LOOP;
       CLOSE line_csr;

     ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
     ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

   END IF;   
 END IF;
  
  x_return_status := l_return_status;

 IF l_debug_level  > 0 THEN
     oe_debug_pub.add(  'OEXVPPYB: EXITING PROCESS PREPAYMENT ORDER: '||x_return_status , 1 ) ;
 END IF;

EXCEPTION
  
    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_PrePayment_Order'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

END Process_PrePayment_Order;

/*----------------------------------------------------------------------
Returns 'Y' if  any type of prepayment hold exists for the order.
----------------------------------------------------------------------*/
PROCEDURE Any_Prepayment_Hold_Exists
(  p_header_id      IN   NUMBER
,  p_hold_exists    OUT  NOCOPY VARCHAR2
)
IS
l_hold_result   VARCHAR2(30);
l_return_status VARCHAR2(30);
l_msg_count     NUMBER;
l_msg_data      VARCHAR2(2000);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: IN CHECK FOR PREPAYMENT HOLD' , 3 ) ;
  END IF;

  --  Checking existense of unreleased holds on this order
  OE_HOLDS_PUB.Check_Holds
		      ( p_api_version    => 1.0
		      , p_header_id      => p_header_id
		      , p_hold_id        => 13
		      , p_entity_code    => 'O'
		      , p_entity_id      => p_header_id
		      , x_result_out     => l_hold_result
		      , x_msg_count      => l_msg_count
		      , x_msg_data       => l_msg_data
		      , x_return_status  => l_return_status
		      );

  -- Check the Result 
  IF l_hold_result = FND_API.G_TRUE THEN
    p_hold_exists := 'Y';
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: PREPAYMENT HOLD 13 EXISTS ON ORDER' , 3 ) ;
    END IF;
    return;
  ELSE
    OE_HOLDS_PUB.Check_Holds
		      ( p_api_version    => 1.0
		      , p_header_id      => p_header_id
		      , p_hold_id        => 14
		      , p_entity_code    => 'O'
		      , p_entity_id      => p_header_id
		      , x_result_out     => l_hold_result
		      , x_msg_count      => l_msg_count
		      , x_msg_data       => l_msg_data
		      , x_return_status  => l_return_status
		      );
    IF l_hold_result = FND_API.G_TRUE THEN
      p_hold_exists := 'Y';
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: PREPAYMENT HOLD 14 EXISTS ON ORDER' , 3 ) ;
      END IF;
      return;
    ELSE
      OE_HOLDS_PUB.Check_Holds
		      ( p_api_version    => 1.0
		      , p_header_id      => p_header_id
		      , p_hold_id        => 15
		      , p_entity_code    => 'O'
		      , p_entity_id      => p_header_id
		      , x_result_out     => l_hold_result
		      , x_msg_count      => l_msg_count
		      , x_msg_data       => l_msg_data
		      , x_return_status  => l_return_status
		      );
      IF l_hold_result = FND_API.G_TRUE THEN
        p_hold_exists := 'Y';
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: PREPAYMENT HOLD 15 EXISTS ON ORDER' , 3 ) ;
        END IF;
      ELSE
        p_hold_exists := 'N';
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OEXVPPYB: NO PREPAYMENT HOLD ON ORDER' , 3 ) ;
        END IF;
      END IF;
    END IF;
  END IF;

  EXCEPTION
   
    WHEN OTHERS THEN
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Any_Prepayment_Hold_Exists'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

END Any_Prepayment_Hold_Exists;

/*----------------------------------------------------------------------
Applies a prepayment hold which based on the hold id passed in, uses 
standard Hold APIs.
----------------------------------------------------------------------*/
PROCEDURE Apply_Prepayment_Hold
(   p_header_id       IN   NUMBER
,   p_hold_id         IN   NUMBER
,   p_msg_count       IN OUT  NOCOPY NUMBER
,   p_msg_data	      IN OUT  NOCOPY VARCHAR2
,   p_return_status   OUT  NOCOPY VARCHAR2
)
IS

l_hold_exists     VARCHAR2(1) := NULL ;
l_msg_count       NUMBER := 0;
l_msg_data        VARCHAR2(2000);
l_return_status   VARCHAR2(30);

l_hold_source_rec   OE_Holds_PVT.Hold_Source_REC_type;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  p_return_status := FND_API.G_RET_STS_SUCCESS;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: IN APPLY PREPAYMENT HOLDS' , 3 ) ;
      oe_debug_pub.add(  'OEXVPPYB: HEADER ID : '||P_HEADER_ID , 3 ) ;
      oe_debug_pub.add(  'OEXVPPYB: HOLD ID : '||P_HOLD_ID , 3 ) ;
  END IF;

  -- Check if Hold already exists on this order
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: CHECKING IF REQUESTED PREPAYMENT HOLD ALREADY APPLIED' , 3 ) ;
  END IF;
  Any_Prepayment_Hold_Exists ( p_header_id   => p_header_id 
                        , p_hold_exists => l_hold_exists 
                        );
 
  -- Return with Success if this Hold Already exists on the order
  IF l_hold_exists = 'Y' THEN 
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: HOLD ALREADY APPLIED ON HEADER ID : ' || P_HEADER_ID , 3 ) ;
    END IF;
    RETURN ; 
  END IF ;

  -- Apply Prepayment Hold on Header
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: APPLYING PREPAYMENT HOLD ON HEADER ID : ' || P_HEADER_ID , 3 ) ;
  END IF;

  l_hold_source_rec.hold_id         := p_hold_id ;  -- Requested Hold
  l_hold_source_rec.hold_entity_code:= 'O';         -- Order Hold
  l_hold_source_rec.hold_entity_id  := p_header_id; -- Order Header

  IF p_hold_id in (14, 15) THEN
    l_hold_source_rec.hold_comment := SUBSTR(p_msg_data,1,2000);
  END IF;

  OE_Holds_PUB.Apply_Holds
                (   p_api_version       =>      1.0
                ,   p_validation_level  =>      FND_API.G_VALID_LEVEL_NONE
                ,   p_hold_source_rec   =>      l_hold_source_rec
                ,   x_msg_count         =>      l_msg_count
                ,   x_msg_data          =>      l_msg_data
                ,   x_return_status     =>      l_return_status
                );

  IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
    IF p_hold_id = 13 THEN
      FND_MESSAGE.SET_NAME('ONT','ONT_PPP_HOLD_APPLIED');
      OE_MSG_PUB.ADD;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: PPP Hold has been applied on order.', 3 ) ;
      END IF;
    ELSIF p_hold_id = 14 THEN
      FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_FAILURE_HOLD');
      OE_MSG_PUB.ADD;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: payment failure hold has been applied on order.', 3 ) ;
      END IF;
    ELSIF p_hold_id = 15 THEN
      FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_SERVER_FAIL_HOLD');
      OE_MSG_PUB.ADD;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: payment server failure hold has been applied on order.', 3 ) ;
      END IF;
    END IF;

  ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
    RAISE FND_API.G_EXC_ERROR;
  ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: APPLIED PREPAYMENT HOLD ON HEADER ID:' || P_HEADER_ID , 3 ) ;
  END IF;

  EXCEPTION
   
    WHEN FND_API.G_EXC_ERROR THEN
      p_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      
 
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

    WHEN OTHERS THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Apply_Prepayment_Hold'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

END Apply_Prepayment_Hold;

/*----------------------------------------------------------------------
Releases all Prepayment Holds on the Order, uses standard Hold APIs.
----------------------------------------------------------------------*/

PROCEDURE Release_Prepayment_Hold
(  p_header_id       IN   NUMBER 
,  p_msg_count       OUT  NOCOPY NUMBER
,  p_msg_data        OUT  NOCOPY VARCHAR2
,  p_return_status   OUT  NOCOPY VARCHAR2
)
IS

l_hold_entity_id    NUMBER := p_header_id;
l_hold_id	    NUMBER;
l_hold_exists       VARCHAR2(1);
l_msg_count         NUMBER := 0;
l_msg_data          VARCHAR2(2000);
l_return_status     VARCHAR2(30);
l_release_reason    VARCHAR2(30);
l_hold_source_rec   OE_HOLDS_PVT.Hold_Source_Rec_Type;
l_hold_release_rec  OE_HOLDS_PVT.Hold_Release_Rec_Type;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  p_return_status := FND_API.G_RET_STS_SUCCESS;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: IN RELEASE PREPAYMENT HOLD' , 3 ) ;
  END IF;

  -- Check What type of Holds to Release
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: RELEASE PREPAYMENT HOLDS FOR HEADER ID : ' || L_HOLD_ENTITY_ID , 3 ) ;
    END IF;

    -- check for PPP hold.
    l_hold_id := 13 ; 

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: CHECKING EXISTENCE OF HOLD ID : '||L_HOLD_ID , 3 ) ;
    END IF;
    OE_Verify_Payment_PUB.Hold_Exists
                          ( p_header_id   => l_hold_entity_id
                          , p_hold_id     => l_hold_id
                          , p_hold_exists => l_hold_exists
                          ) ;

    IF l_hold_exists = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: RELEASING CC RISK HOLD ON ORDER HEADER ID:' || L_HOLD_ENTITY_ID , 3 ) ;
      END IF;
      l_hold_source_rec.hold_id          := l_hold_id;
      l_hold_source_rec.HOLD_ENTITY_CODE := 'O';
      l_hold_source_rec.HOLD_ENTITY_ID   := l_hold_entity_id;

      l_hold_release_rec.release_reason_code := 'PREPAYMENT'; 
      l_hold_release_rec.release_comment := 'Prepayment has been processed. Hold released automatically.';

      OE_Holds_PUB.Release_Holds
                (   p_api_version       =>   1.0
                ,   p_hold_source_rec   =>   l_hold_source_rec
                ,   p_hold_release_rec  =>   l_hold_release_rec
                ,   x_msg_count         =>   l_msg_count
                ,   x_msg_data          =>   l_msg_data
                ,   x_return_status     =>   l_return_status
                );

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
      --bug3599715 start
      fnd_message.Set_Name('ONT', 'ONT_PPP_HOLD_RELEASED');
      oe_msg_pub.add;
      --bug3599715 end		          
    END IF;

    -- check for epayment failure hold.
    l_hold_id := 14 ; 

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: CHECKING EXISTENCE OF HOLD ID : '||L_HOLD_ID , 3 ) ;
    END IF;
    OE_Verify_Payment_PUB.Hold_Exists
                          ( p_header_id   => l_hold_entity_id
                          , p_hold_id     => l_hold_id
                          , p_hold_exists => l_hold_exists
                          ) ;

    IF l_hold_exists = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: RELEASING PAYMENT FAILURE HOLD ON ORDER HEADER ID:' || L_HOLD_ENTITY_ID , 3 ) ;
      END IF;
      l_hold_source_rec.hold_id          := l_hold_id;
      l_hold_source_rec.HOLD_ENTITY_CODE := 'O';
      l_hold_source_rec.HOLD_ENTITY_ID   := l_hold_entity_id;

      l_hold_release_rec.release_reason_code := 'PREPAYMENT'; 
      l_hold_release_rec.release_comment := 'Prepayment has been processed. Hold released automatically.';

      OE_Holds_PUB.Release_Holds
                (   p_api_version       =>   1.0
                ,   p_hold_source_rec   =>   l_hold_source_rec
                ,   p_hold_release_rec  =>   l_hold_release_rec
                ,   x_msg_count         =>   l_msg_count
                ,   x_msg_data          =>   l_msg_data
                ,   x_return_status     =>   l_return_status
                );

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
      fnd_message.Set_Name('ONT', 'ONT_PMNT_FAIL_HOLD_RELEASED');
      oe_msg_pub.add;
    END IF;

    -- check for epayment server failure hold.
    l_hold_id := 15 ; 

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: CHECKING EXISTENCE OF HOLD ID : '||L_HOLD_ID , 3 ) ;
    END IF;
    OE_Verify_Payment_PUB.Hold_Exists
                          ( p_header_id   => l_hold_entity_id
                          , p_hold_id     => l_hold_id
                          , p_hold_exists => l_hold_exists
                          ) ;

    IF l_hold_exists = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: RELEASING PAYMENT SERVER FAILURE HOLD ON ORDER HEADER ID:' || L_HOLD_ENTITY_ID , 3 ) ;
      END IF;
      l_hold_source_rec.hold_id          := l_hold_id;
      l_hold_source_rec.HOLD_ENTITY_CODE := 'O';
      l_hold_source_rec.HOLD_ENTITY_ID   := l_hold_entity_id;

      l_hold_release_rec.release_reason_code := 'PREPAYMENT'; 
      l_hold_release_rec.release_comment := 'Prepayment has been processed. Hold released automatically.';

      OE_Holds_PUB.Release_Holds
                (   p_api_version       =>   1.0
                ,   p_hold_source_rec   =>   l_hold_source_rec
                ,   p_hold_release_rec  =>   l_hold_release_rec
                ,   x_msg_count         =>   l_msg_count
                ,   x_msg_data          =>   l_msg_data
                ,   x_return_status     =>   l_return_status
                );

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
      fnd_message.Set_Name('ONT', 'ONT_PMNT_SERVER_HOLD_RELEASED');
      oe_msg_pub.add;
    END IF;

  EXCEPTION
   
    WHEN FND_API.G_EXC_ERROR THEN
      p_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      
 
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

    WHEN OTHERS THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Release_Prepayment_Hold'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

END Release_Prepayment_Hold;

/*----------------------------------------------------------------------
Releases Payment Hold on the Order, uses standard Hold APIs.
----------------------------------------------------------------------*/

PROCEDURE Release_Payment_Hold
(  p_header_id       IN   NUMBER 
,  p_hold_id	     IN   NUMBER
,  p_msg_count       OUT  NOCOPY NUMBER
,  p_msg_data        OUT  NOCOPY VARCHAR2
,  p_return_status   OUT  NOCOPY VARCHAR2
)
IS

l_hold_entity_id    NUMBER := p_header_id;
l_hold_id	    NUMBER;
l_hold_exists       VARCHAR2(1);
l_msg_count         NUMBER := 0;
l_msg_data          VARCHAR2(2000);
l_return_status     VARCHAR2(30);
l_release_reason    VARCHAR2(30);
l_hold_source_rec   OE_HOLDS_PVT.Hold_Source_Rec_Type;
l_hold_release_rec  OE_HOLDS_PVT.Hold_Release_Rec_Type;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  p_return_status := FND_API.G_RET_STS_SUCCESS;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: IN RELEASE PAYMENT HOLD' , 3 ) ;
  END IF;

  -- Check What type of Holds to Release
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: RELEASE PAYMENT HOLDS FOR HEADER ID : ' || L_HOLD_ENTITY_ID , 3 ) ;
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: CHECKING EXISTENCE OF HOLD ID : '||P_HOLD_ID , 3 ) ;
    END IF;
    OE_Verify_Payment_PUB.Hold_Exists
                          ( p_header_id   => l_hold_entity_id
                          , p_hold_id     => p_hold_id
                          , p_hold_exists => l_hold_exists
                          ) ;

    IF l_hold_exists = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: RELEASING PAYMENT HOLD ON ORDER HEADER ID:' || L_HOLD_ENTITY_ID , 3 ) ;
      END IF;
      l_hold_source_rec.hold_id          := p_hold_id;
      l_hold_source_rec.HOLD_ENTITY_CODE := 'O';
      l_hold_source_rec.HOLD_ENTITY_ID   := l_hold_entity_id;

      IF p_hold_id in(13, 14, 15) THEN
        l_hold_release_rec.release_reason_code := 'PREPAYMENT'; 
        l_hold_release_rec.release_comment := 'Prepayment has been processed. Hold released automatically.';
      ELSIF p_hold_id = 16 THEN
        l_hold_release_rec.release_reason_code := 'AUTH_EPAYMENT'; 
        l_hold_release_rec.release_comment := 'Payment has been processed. Hold released automatically.';
      END IF;
  

      OE_Holds_PUB.Release_Holds
                (   p_api_version       =>   1.0
                ,   p_hold_source_rec   =>   l_hold_source_rec
                ,   p_hold_release_rec  =>   l_hold_release_rec
                ,   x_msg_count         =>   l_msg_count
                ,   x_msg_data          =>   l_msg_data
                ,   x_return_status     =>   l_return_status
                );

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
    END IF;


  EXCEPTION
   
    WHEN FND_API.G_EXC_ERROR THEN
      p_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      
 
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

    WHEN OTHERS THEN
      p_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Release_Payment_Hold'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

END Release_Payment_Hold;

FUNCTION Get_Format_Mask(p_currency_code IN VARCHAR2)
RETURN  VARCHAR2
IS

l_precision         	NUMBER;
l_ext_precision     	NUMBER;
l_min_acct_unit     	NUMBER;
l_format_mask	        VARCHAR2(500);
 
 --
 l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
 --
BEGIN
  FND_CURRENCY.Get_Info(p_currency_code,  -- IN variable
		l_precision,
		l_ext_precision,
		l_min_acct_unit);

  FND_CURRENCY.Build_Format_Mask(l_format_mask, 20, l_precision,
                                       l_min_acct_unit, TRUE
                                      ); 
  
  RETURN l_format_mask;
END Get_Format_Mask;

-- New procedure for pack J multiple payments project.
PROCEDURE Process_Payments
(  p_header_id                	IN   NUMBER
,  p_line_id                    IN   NUMBER DEFAULT null --bug3524209
,  p_calling_action            	IN   VARCHAR2
,  p_amount			IN   NUMBER
,  p_delayed_request            IN   VARCHAR2
,  p_process_prepayment         IN VARCHAR2 DEFAULT 'Y'
,  p_process_authorization      IN VARCHAR2 DEFAULT 'Y'
,  x_msg_count                  OUT  NOCOPY NUMBER
,  x_msg_data                   OUT  NOCOPY VARCHAR2
,  x_return_status              OUT  NOCOPY VARCHAR2
) IS

l_header_rec			OE_ORDER_PUB.Header_Rec_Type;
l_line_id			NUMBER;
l_payment_set_id      		NUMBER := NULL;
l_bank_acct_id      		NUMBER := NULL;
l_bank_acct_uses_id 		NUMBER := NULL;
l_application_ref_id           	NUMBER := p_header_id;
l_application_ref_num          	NUMBER;
l_payment_response_error_code   VARCHAR2(80);
l_approval_code		        VARCHAR2(80);
l_header_payment_rec		OE_Order_PUB.Header_Payment_Rec_Type;
l_insert			VARCHAR2(1) := 'N';
l_msg_count          		NUMBER := 0;
l_msg_data           		VARCHAR2(2000) := NULL;
l_return_status      		VARCHAR2(30) := NULL;
l_result_out                    VARCHAR2(30) := NULL;
l_pending_amount                NUMBER := 0;
l_calling_action    		VARCHAR2(30) := p_calling_action;
l_apply_ppp_hold                VARCHAR2(1) := 'N';
l_ppp_hold_exists               VARCHAR2(1) := 'N';
l_process_payment               VARCHAR2(1) := 'N';
l_receipt_method_id             NUMBER := 0;
prev_receipt_method_id          NUMBER := 0;
l_orig_cc_approval_code         VARCHAR2(80) := NULL;
l_prepaid_amount number := 0;
l_exists_cc_payment		VARCHAR2(1) := 'N';
l_prepay_application_id		NUMBER;
l_number_of_refund_receipts	NUMBER;
l_receipt_number		VARCHAR2(30);
l_cash_receipt_id		NUMBER;
l_receivable_application_id	NUMBER;
l_receivables_trx_id		NUMBER;
l_do_cc_authorization		VARCHAR2(1) := 'N';
l_msg_text                      VARCHAR2(2000);
l_exists_prepay			VARCHAR2(1) := 'N';
l_rule_defined      		VARCHAR2(1);
l_exists_prepay_lines           VARCHAR2(1) := 'N';
l_operand			number;
l_amount			number;
l_code				varchar2(80);
l_payment_exists		VARCHAR2(1) := 'N';
l_payment_type_code     	VARCHAR2(30);
l_pf_receipt_method_id		NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--

CURSOR hdr_payments_cur (p_header_id IN NUMBER) IS
SELECT 	Opt.credit_check_flag,
	Op.receipt_method_id,
	Op.payment_type_code,
        op.defer_payment_processing_flag, 
	Op.payment_set_id,
	Op.payment_trx_id,
	Op.payment_collection_event,
	Op.prepaid_amount,
	Op.credit_card_code,
	Op.credit_card_approval_code,
	Op.check_number,
        Op.payment_number,
        Op.payment_amount
FROM	oe_payment_types_all opt,
	Oe_payments	 op
WHERE	opt.payment_type_code = op.payment_type_code
AND     op.payment_collection_event = 'PREPAY'
AND     op.payment_type_code <> 'COMMITMENT'
AND     op.line_id is null
AND	op.header_id =p_header_id
And     NVL(opt.org_id,NVL(TO_NUMBER(
            DECODE(SUBSTRB(USERENV('CLIENT_INFO'), 1,1),' ',NULL,
            SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) =
            NVL(TO_NUMBER(DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1),
            ' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99);

cursor payment_count is
select count(payment_type_code)
from oe_payments
where header_id = p_header_id
and line_id is null;

BEGIN

    IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: Entering Process_Payments procedure.' , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: l_calling_action is: '||l_calling_action , 1 ) ;
      oe_debug_pub.add(  'OEXVPPYB: p_delayed_request is: '||p_delayed_request , 1 ) ;
    END IF;
    x_return_status := FND_API.G_RET_STS_SUCCESS;


    oe_Header_util.query_row (p_header_id => p_Header_id
                             ,x_header_rec=> l_header_rec );

  --bug3524209
  IF p_line_id IS NULL THEN
    -- to create payment records when needed.
 
    BEGIN
      SELECT 'Y'
      INTO l_payment_exists
      FROM oe_payments
      WHERE header_id = p_header_id
      AND   rownum = 1;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        l_payment_exists := 'N';
    END;

    IF l_payment_exists = 'N' THEN
      -- call this procedure to create payment record only when there
      -- does not exist any payment.
      update_hdr_payment(p_header_id      => p_header_id
                      ,p_action         => 'ACTIONS_PAYMENTS'
                      ,x_return_status  => l_return_status
                      ,x_msg_data       => l_msg_data
                      ,x_msg_count      => l_msg_count
                      );
    END IF;

    update_payment_numbers(p_header_id     => p_header_id
                         ,p_line_id        => p_line_id
                         ,x_return_status  => l_return_status
                         ,x_msg_data       => l_msg_data
                         ,x_msg_count      => l_msg_count
                         );
  ELSE
    update_payment_numbers(p_header_id     => p_header_id
                         ,p_line_id        => p_line_id
                         ,x_return_status  => l_return_status
                         ,x_msg_data       => l_msg_data
                         ,x_msg_count      => l_msg_count
                         );
  END IF;

  --bug3524209
  IF p_line_id IS NULL THEN
    BEGIN
      SELECT 'Y'
      INTO   l_exists_prepay
      FROM   oe_payments
      WHERE  payment_collection_event = 'PREPAY'
      AND    header_id = p_header_id
      AND    rownum=1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      l_exists_prepay := 'N';
    END;

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'OEXVPPYB: l_exists_prepay flag is: '||l_exists_prepay , 3 ) ;
  END IF;
  -- Prepayment Processing 
  IF l_exists_prepay = 'Y' 
    AND nvl(l_calling_action,'X') NOT IN ('SHIPPING','PACKING' ,'PICKING')
    AND p_process_prepayment = 'Y' THEN

    IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: start prepayment processing.' , 3 ) ;
    END IF;

    l_orig_cc_approval_code := l_header_rec.credit_card_approval_code;

    -- get the payment_set_id if exists for the order.
    BEGIN
      SELECT payment_set_id
      INTO   l_payment_set_id
      FROM   oe_payments
      WHERE  header_id = p_header_id
      AND    payment_set_id IS NOT NULL
      AND    rownum = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      null;
    END;
  

      -- call AR API to create receipt for each payment method.
      -- l_insert should be set to 'Y' if there are no payment records
      -- in oe_payments table
      -- and payment information is only present in headers.

	    For c_payment_rec IN hdr_payments_cur (p_header_id) LOOP

              IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'OEXVPPYB: Entering LOOP of the payment records. ', 3 ) ;
                oe_debug_pub.add(  'OEXVPPYB: defer payment processing flag is: '||c_payment_rec.defer_payment_processing_flag , 3 ) ;
                oe_debug_pub.add(  'OEXVPPYB: payment type is: '||c_payment_rec.payment_type_code , 1 ) ;
                oe_debug_pub.add(  'OEXVPPYB: check number is: '||c_payment_rec.check_number , 1 ) ;  -- bug 4599773
              END IF;

              -- 5852633 l_approval_code := null;  -- initialize for each record.
              l_approval_code := nvl(c_payment_rec.credit_card_approval_code,l_header_rec.credit_card_approval_code); -- 5852633
              l_prepaid_amount := nvl(c_payment_rec.prepaid_amount,0);
              l_pending_amount := nvl(c_payment_rec.payment_amount,0) - l_prepaid_amount;

              IF ((nvl(c_payment_rec.defer_payment_processing_flag, 'N') = 'Y' 
                  AND l_calling_action = 'BOOKING')
                  --bug3507871 
	          OR (l_calling_action='UPDATE' AND p_delayed_request=FND_API.G_TRUE))
                  AND l_pending_amount <> 0 THEN
                  -- if calling action is null, this is invoked from action, we
                  -- need to process payments regardless of the defer flag.
                  -- Apply PPP prepayment hold (hold id 13) on the order;

                  IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'OEXVPPYB: l_calling_action is: '||l_calling_action , 1 ) ;
                    oe_debug_pub.add(  'OEXVPPYB: place order on PPP hold.' , 1 ) ;
                  END IF;
                  Apply_Prepayment_Hold 
		        ( p_header_id     => p_header_id
                         ,p_hold_id       => 13   --  Seed Id for PPP Hold
                         ,p_msg_count     => l_msg_count
                         ,p_msg_data      => l_msg_data
                         ,p_return_status => l_return_status
                        );

                  IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'OEXVPPYB: ORDER IS PLACED ON PPP HOLD.' , 3 ) ;
                    END IF;
                  ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
                    RAISE FND_API.G_EXC_ERROR;
                  ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                  END IF;
               ELSE
                 -- process the payments.

                 IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'OEXVPPYB: l_pending_amount is: '||l_pending_amount, 3 ) ;
                 END IF;

                 l_bank_acct_id := c_payment_rec.payment_trx_id;

                 l_receipt_method_id := c_payment_rec.receipt_method_id;

		 l_receipt_number := c_payment_rec.check_number;   -- bug 4599773
                 IF l_receipt_method_id is null then
                  Begin  -- receipt_method_id selection
                    select receipt_method_id into l_receipt_method_id
                    from oe_payment_types_vl
                    where payment_type_code = c_payment_rec.payment_type_code
                    and rownum = 1;
                  exception
                     when others then
                        l_receipt_method_id := null;
                  end; -- receipt_method_id selection

                  IF l_receipt_method_id is null THEN
                   IF c_payment_rec.payment_type_code = 'CREDIT_CARD' 
                      OR c_payment_rec.payment_type_code = 'ACH'
                      OR c_payment_rec.payment_type_code = 'DEBIT_CARD' THEN

                      IF l_debug_level  > 0 THEN
                        oe_debug_pub.add('OEXVPPYB: Calling OE_Verify_Payment_PUB.Get_Primary_Pay_Method');
                        oe_debug_pub.add('OEXVPPYB: Sold To Org ID :'||l_header_rec.sold_to_org_id);
                        oe_debug_pub.add('OEXVPPYB: Invoice To Org ID :'||l_header_rec.invoice_to_org_id);
                      END IF;

                      l_receipt_method_id := OE_Verify_Payment_PUB.Get_Primary_Pay_Method
                                         ( p_header_rec      => l_header_rec ) ;

                      IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'OEXVPPYB: After Getting primary payment method'||l_receipt_method_id , 5 ) ;
                      END IF;
                    END IF; -- if payment_type_code is CREDIT_CARD etc.
                  END IF; -- if l_receipt_method_id is null for credit card etc.
                END IF; -- if l_receipt_method_id is null

              IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'OEXVPPYB: l_receipt_method_id is: '||l_receipt_method_id, 3 ) ;
              END IF;

              IF l_receipt_method_id IS NULL THEN
                 FND_MESSAGE.SET_NAME('ONT','OE_ATTRIBUTE_REQUIRED');
                 FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Receipt Method');
                 oe_debug_pub.add('OEXVPPYB: receipt method is null.',3);
                 oe_msg_pub.Add;
                 RAISE FND_API.G_EXC_ERROR;

              ELSE
                -- receipt method is not null

                IF l_pending_amount > 0 then

                   /* ideally create_receipt api signature should have payment_rec 
                      as input instead of l_header_rec - however since prepayments 
                      is only at the header level, we are okay in pack J. 
                      In future, this needs to be done */

                    l_header_rec.credit_card_approval_code := c_payment_rec.credit_card_approval_code;

                    IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'OEXVPPYB: Before calling Create_Receipt API.', 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: amount is: '||l_pending_amount, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: receipt_method_id is: '||l_receipt_method_id, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: payment_set_id is: '||l_payment_set_id, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: bank_acct_id is: '||l_bank_acct_id, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: check number is: '||l_receipt_number, 3 ) ; -- bug 4599773
                    END IF;

     		    OE_PrePayment_PVT.Create_Receipt
         	    ( p_header_rec                 => l_header_rec
         	    , p_amount                     => l_pending_amount
         	    , p_receipt_method_id          => l_receipt_method_id
         	    , p_bank_acct_id               => l_bank_acct_id
         	    , p_bank_acct_uses_id          => l_bank_acct_uses_id
         	    , p_payment_set_id             => l_payment_set_id
         	    , p_receipt_number             => l_receipt_number   -- bug 4599773
		    , x_payment_response_error_code=> l_payment_response_error_code
         	    , p_approval_code		   => l_approval_code
         	    , x_msg_count                  => l_msg_count
         	    , x_msg_data                   => l_msg_data
         	    , x_result_out                 => l_result_out
         	    , x_return_status              => l_return_status
         	    );

                  l_header_rec.credit_card_approval_code := l_orig_cc_approval_code;

                  IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'OEXVPPYB: After calling Create_Receipt API, return status is: '||l_return_status, 3) ;
                  END IF;

		  IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
   
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'OEXVPPYB: update oe_payments for payment_set_id: '||l_payment_set_id, 3) ;
                      END IF;

                      UPDATE oe_payments
                      SET    payment_set_id = l_payment_set_id,
                             prepaid_amount = l_pending_amount + l_prepaid_amount,
                             credit_card_approval_code = l_approval_code
                      WHERE  header_id = p_header_id
                      and    nvl(payment_number, -1) = nvl(c_payment_rec.payment_number, -1);

                    BEGIN
                       SELECT 'Y'
                       INTO   l_exists_prepay_lines
                       FROM   oe_payments
                       WHERE  payment_collection_event = 'PREPAY'
                       AND    payment_set_id is NULL
                       AND    header_id = p_header_id
                       AND    payment_type_code <> 'COMMITMENT'
                       AND    line_id is null
                       AND    rownum=1;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                       l_exists_prepay_lines := 'N';
                    END;
      
                    IF l_exists_prepay_lines = 'N' THEN
		    -- Release all Prepayment holds;
                    Release_Prepayment_Hold ( p_header_id     => p_header_id
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

       		    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         	      RAISE FND_API.G_EXC_ERROR;
       		    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
         	      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           	    END IF;
                    END IF;
                       
                    -- END IF;  -- if l_insert = 'Y'


		  ELSE
		    IF l_payment_response_error_code IN ('IBY_0001', 'IBY_0008') THEN
		       -- apply epayment server failure hold (seeded id is 15).;
                       IF l_debug_level  > 0 THEN
                         oe_debug_pub.add(  'after create_receipt, error code is: '||l_payment_response_error_code, 3 ) ;
                       END IF;

                      -- 4201622
                      -- to pass the message to apply_prepayment_hold so that hold comments
                      -- gets populated with the error messages from AR/iPayment.
                      l_msg_data := null;
                      FOR I IN 1..l_msg_count LOOP
                        l_msg_data := l_msg_data||' '|| OE_MSG_PUB.Get(I,'F');
                        IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  L_MSG_DATA , 1 ) ;
                        END IF;
                      END LOOP;

	  	      Apply_Prepayment_Hold 
			( p_header_id     => p_header_id
                 	,p_hold_id        => 15
                 	 ,p_msg_count     => l_msg_count
                 	 ,p_msg_data      => l_msg_data
                 	 ,p_return_status => l_return_status
                	 );
          	      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            		RAISE FND_API.G_EXC_ERROR;
          	      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            	        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          	      END IF;

	 	    ELSE
	 	      -- Apply payment failure hold (seeded hold id is 14);
                      IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'after create_receipt, applying payment failure hold.',  3 ) ;
                      END IF;
	  	      Apply_Prepayment_Hold 
			( p_header_id     => p_header_id
                 	,p_hold_id        => 14   --   payment failure Hold
                 	 ,p_msg_count     => l_msg_count
                 	 ,p_msg_data      => l_msg_data
                 	 ,p_return_status => l_return_status
                	 );
          	      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            		RAISE FND_API.G_EXC_ERROR;
          	      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            	        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          	      END IF;

		    END IF; -- if l_payment_response_error_code...
	   	  END IF; -- if l_return status...
          
                ELSIF l_pending_amount < 0 THEN 
                    IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'OEXVPPYB Process_Payments: Before calling create_refund.', 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: amount is: '||l_pending_amount, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: receipt_method_id is: '||l_receipt_method_id, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: payment_set_id is: '||l_payment_set_id, 3 ) ;
                      oe_debug_pub.add(  'OEXVPPYB: bank_acct_id is: '||l_bank_acct_id, 3 ) ;
                    END IF;

                   Create_Refund(
                     p_header_rec		=> l_header_rec,
                     p_refund_amount            => l_pending_amount* (-1), 
                     p_payment_set_id		=> l_payment_set_id,
                     p_bank_account_id   	=> l_bank_acct_id,
                     p_receipt_method_id 	=> l_receipt_method_id,
                     x_return_status     	=> l_return_status
                    );

                    IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'OEXVPPYB Process_Payments:  after calling create_refund, return status is: '||l_return_status, 3 ) ;
                    END IF;

                    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
                       UPDATE oe_payments
                       SET    prepaid_amount = nvl(prepaid_amount,0) + l_pending_amount
                       WHERE  header_id = p_header_id
                       AND    nvl(payment_number, -1) = nvl(c_payment_rec.payment_number, -1);

                    ELSIF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                      -- Apply payment failure hold (seeded hold id is 14);
                      IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'after create_refund, applying payment failure hold.',  3 ) ;
                      END IF;

                      -- 4201622
                      -- to pass the message to apply_prepayment_hold so that hold comments
                      -- gets populated with the error messages from AR/iPayment.
                      l_msg_data := null;
                      FOR I IN 1..l_msg_count LOOP
                        l_msg_data := l_msg_data||' '|| OE_MSG_PUB.Get(I,'F');
                        IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  L_MSG_DATA , 1 ) ;
                        END IF;
                      END LOOP;

                      Apply_Prepayment_Hold
                        ( p_header_id     => p_header_id
                        ,p_hold_id        => 14   --   payment failure Hold
                         ,p_msg_count     => l_msg_count
                         ,p_msg_data      => l_msg_data
                         ,p_return_status => l_return_status
                         );
                      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                        RAISE FND_API.G_EXC_ERROR;
                      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                      END IF;

                    END IF;
                ELSIF l_pending_amount = 0 THEN
                  Release_Prepayment_Hold ( p_header_id     => p_header_id
                                          , p_msg_count     => l_msg_count
                                          , p_msg_data      => l_msg_data
                                          , p_return_status => l_return_status
                                          );

                  IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                    RAISE FND_API.G_EXC_ERROR;
                  ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                  END IF;

                END IF;  -- if l_pending_amount > 0 ...

             END IF; -- if l_receipt_method_id is not null
            END IF;  -- whether or not to apply prepayment hold

	   END LOOP;

	      -- Update INVOICE_INTERFACE_STATUS_CODE of the line to 'PREPAID';
              -- for now do not update invoice interface status code
              -- check if there are no payments at line level
              -- if there are no payments at line level then check if 
              -- payment_terms at the header level has prepaid_flag ='Y'
              -- and if there are no invoice payments at the header level.
              -- things can change - so , I am not sure whether this is a good
              -- idea or not. 


    END IF; -- end l_exists_prepay
    -- End of Prepayment Processing.
  END IF; --bug3524209

   /* Processing CC Authorization */
   -- call verify_payment for credit card authorization
   -- if exists credit card payment on the order.
     BEGIN
       -- if there exists line level credit card payments.
       SELECT 'Y' 
       INTO   l_do_cc_authorization
       FROM   oe_payments
       WHERE  payment_type_code = 'CREDIT_CARD'
       AND    payment_collection_event = 'INVOICE'
       AND    header_id = p_header_id
       AND    rownum = 1;
     EXCEPTION WHEN NO_DATA_FOUND THEN
       l_do_cc_authorization := 'N';
     END;

  IF l_do_cc_authorization = 'Y' AND p_process_authorization = 'Y' THEN

    -- no need to check for any rules if calling action is null, which means 
    -- this is invoked from on-line.
    IF l_calling_action IS NOT NULL THEN
       l_rule_defined := OE_Verify_Payment_PUB.Check_Rule_Defined
				( p_header_rec     => l_header_rec 
				, p_calling_action => l_calling_action
				) ;

       IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: RULE DEFINED FOR AUTHORIZATION: '|| L_RULE_DEFINED ) ;
       END IF;

       IF l_rule_defined = 'N' THEN
         IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'OEXVPPYB: No rule defined for authorization. ' ) ;
         END IF;
	 --bug3511992
         x_msg_count := OE_MSG_PUB.Count_Msg;
            
         oe_debug_pub.add('pviprana: x_msg_count in OEXVPPYB.pls = ' || x_msg_count);
         RETURN;
       END IF;
     END IF;

     IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'OEXVPPYB: Calling Credit Card Authorization for Multiple Payments.' ) ;
     END IF;

    -- bug 5192725
    -- do not need to validate credit card if the AR payment type code for the
    -- receipt method defined in the profile option is not 'CREDIT_CARD'.
    l_pf_receipt_method_id := to_number(nvl(fnd_profile.value('ONT_RECEIPT_METHOD_ID'), '0')) ;
    BEGIN
      SELECT payment_type_code
      INTO   l_payment_type_code
      FROM   ar_receipt_methods
      WHERE  receipt_method_id = l_pf_receipt_method_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      null;
    END;

    IF nvl(l_payment_type_code, 'NULL') = 'CREDIT_CARD' THEN

     OE_Verify_Payment_PUB.Authorize_MultiPayments
                            ( p_header_rec          => l_header_rec
			    , p_line_id             => p_line_id --bug3524209
                            , p_calling_action      => l_calling_action
                            , p_msg_count           => l_msg_count
                            , p_msg_data            => l_msg_data
                            , p_result_out          => l_result_out
                            , p_return_status       => l_return_status
                            );

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: After calling OE_Verify_Payment_PUB.Authorize_MultiPayments, return status is: '||l_return_status, 3) ; 
     END IF;
 

     IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
     ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;
     
     END IF;  -- bug 5192725

  END IF;  -- end of CC authorization.

   -- to set the calling action.
   IF l_calling_action IS NULL THEN
     l_calling_action := OE_Verify_Payment_PUB.Which_Rule
                       (p_header_id => p_header_id);
   END IF;

    -- Check rule defined before going to credit checking engine.
   IF l_calling_action IS NOT NULL THEN
     l_rule_defined := OE_Verify_Payment_PUB.Check_Rule_Defined
				( p_header_rec     => l_header_rec 
				, p_calling_action => l_calling_action
				) ;

     IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'OEXVPPYB: RULE DEFINED : '|| L_RULE_DEFINED ) ;
     END IF;

     IF l_rule_defined = 'N' THEN
     --bug3511992
     x_msg_count := OE_MSG_PUB.Count_Msg;
            
      oe_debug_pub.add('pviprana: x_msg_count in OEXVPPYB.pls = ' || x_msg_count);

       return;
     END IF;
   END IF;

   -- Do not need to call Credit Checking redundantly when pressing
   -- Process Payment button right after Save button is pressed when
   -- changing payment type code for Invoice payment, as changing
   -- payment type code would result in g_process_payment getting 
   -- logged and executed, which would already have called
   -- Credit Checking, thus no need to call again when Process Payment
   -- button is pressesd in this case.
/* Removed the following if condition to fix the bug 5946910
   IF NOT (g_process_pmt_req_logged = 'Y'
           AND NOT OE_Delayed_Requests_Pvt.Check_For_Request
                      (p_entity_code => OE_GLOBALS.G_ENTITY_HEADER_PAYMENT
                      ,p_entity_id => p_header_id
                      ,p_request_type => OE_GLOBALS.G_PROCESS_PAYMENT
                      )
           AND p_delayed_request = 'N') THEN
*/

   IF (1=1) THEN
    ------------- Begin Multi currency credit checking changes ----
    ----------------------------------------------------------------
    -- The credit checking code 
     -- ( NON- Electronic, NON iPayment )
    -- code is now maintained, developed, enhanced
    --  and Bug fixed in the new MUlti currency API's.
    -- including customers prior to OM patch set G will
    -- get the new  API's

    --  For clarifications, please contact
    --  Global Manufacturing
    ----------------------------------------------------------------

    BEGIN
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: BEGIN CHECK FOR MCC CODE. ' , 1 ) ;
          oe_debug_pub.add(  'P_HEADER_ID = '|| P_HEADER_ID , 1 ) ;
      END IF;

      BEGIN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'OEXVPPYB:INTO MULTI CREDIT CHECKING FLOW ' , 1 ) ;
              oe_debug_pub.add(  'OEXVPPYB: CALL OE_CREDIT_ENGINE_GRP' , 1 ) ;
          END IF;

          OE_Credit_Engine_GRP.Credit_check_with_payment_typ
           (  p_header_id            => p_header_id
           ,  p_calling_action       => l_calling_action
           ,  p_delayed_request      => p_delayed_request
           ,  p_credit_check_rule_id => NULL
           ,  x_msg_count            => l_msg_count
           ,  x_msg_data             => l_msg_data
           ,  x_return_status        => l_return_status
           );

          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'OEXVPPYB: OUT OF OE_CREDIT_ENGINE_GRP' , 1 ) ;
              oe_debug_pub.add(  'X_RETURN_STATUS = ' || L_RETURN_STATUS , 1 ) ;
          END IF;

        END ;
      END ; -- End MCC Block
    END IF;

    -- set the value back to N.
    IF g_process_pmt_req_logged = 'Y'
       AND p_delayed_request = 'N'
       AND p_calling_action is NULL
       THEN
       g_process_pmt_req_logged := 'N';
    END IF;

    --bug3511992  
    x_msg_count := OE_MSG_PUB.Count_Msg;
            
    oe_debug_pub.add('pviprana: x_msg_count in OEXVPPYB.pls = ' || x_msg_count);

    x_return_status := l_return_status;

    IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: Exiting Process_Payments procedure: '||x_return_status , 1 ) ;
    END IF;

EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'Unexpected error in Process_Payments: ' || SQLERRM , 3 ) ;
      END IF;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_Payments'
            );
      END IF;

      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'Oracle error in others in process_payments: '||SQLERRM , 3 ) ;
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );
	
END Process_Payments;
procedure Split_Payment 
(p_line_id 	        IN   NUMBER
,p_header_id		IN   NUMBER
,p_split_from_line_id   IN   NUMBER
,x_return_status        OUT NOCOPY VARCHAR2
,x_msg_count            OUT NOCOPY NUMBER
,x_msg_data             OUT NOCOPY VARCHAR2
 ) IS

l_line_payment_tbl	OE_ORDER_PUB.Line_Payment_Tbl_Type;
l_x_old_Line_Payment_tbl	OE_ORDER_PUB.Line_Payment_Tbl_Type;
l_from_line_payment_tbl	OE_ORDER_PUB.Line_Payment_Tbl_Type;
l_control_rec               OE_GLOBALS.Control_Rec_Type;
l_return_status         VARCHAR2(2000);
i			NUMBER;
j			NUMBER;
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
	
BEGIN

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add('Entering OE_Prepayment_PVT.split_payment ', 1);
    oe_debug_pub.add('p_split_from_line_id is: '||p_split_from_line_id, 1);
    oe_debug_pub.add('p_header_id is: '||p_header_id, 1);
    oe_debug_pub.add('p_line_id is: '||p_line_id, 1);
  END IF;

  /* Line Level payments for FROM Line */
  OE_Line_Payment_Util.Query_Rows(p_line_id  =>  p_split_from_line_id,
                                  p_header_id => p_header_id,
                                  x_line_payment_tbl =>  l_from_line_payment_tbl);


  i := l_from_line_payment_tbl.First;
  j := 1;
  While i is not null Loop
    IF l_debug_level  > 0 THEN
      oe_debug_pub.add('Inside split payment loop '||l_from_line_payment_tbl(i).payment_type_code,3);
      oe_debug_pub.add('Inside split payment loop I is: '||i, 1);
    END IF;

    IF l_from_line_payment_tbl(i).payment_type_code = 'COMMITMENT' THEN
      -- commitment is handled by delayed request for commitment.
     goto next_in_loop;
   END IF;

    l_line_payment_tbl(j).operation           := OE_GLOBALS.G_OPR_CREATE;
    l_line_payment_tbl(j).header_id           := p_header_id;
    l_line_payment_tbl(j).line_id             := p_line_id;
    l_line_payment_tbl(j).payment_type_code := l_from_line_payment_tbl(i).payment_type_code;
    l_line_payment_tbl(j).payment_collection_event := l_from_line_payment_tbl(i).payment_collection_event;
    l_line_payment_tbl(j).payment_level_code := l_from_line_payment_tbl(i).payment_level_code;
    l_line_payment_tbl(j).payment_trx_id := l_from_line_payment_tbl(i).payment_trx_id;
    l_line_payment_tbl(j).credit_card_code := l_from_line_payment_tbl(i).credit_card_code;
    l_line_payment_tbl(j).credit_card_number := l_from_line_payment_tbl(i).credit_card_number;
    l_line_payment_tbl(j).credit_card_holder_name := l_from_line_payment_tbl(i).credit_card_holder_name;
    l_line_payment_tbl(j).credit_card_expiration_date := l_from_line_payment_tbl(i).credit_card_expiration_date;
    l_line_payment_tbl(j).credit_card_approval_code := l_from_line_payment_tbl(i).credit_card_approval_code;
    l_line_payment_tbl(j).receipt_method_id := l_from_line_payment_tbl(i).receipt_method_id;
    l_line_payment_tbl(j).check_number := l_from_line_payment_tbl(i).check_number;
    -- l_line_payment_tbl(j).payment_number := l_from_line_payment_tbl(i).payment_number;

    j := j + 1;
    <<next_in_loop>>
    i:= l_from_line_payment_tbl.Next(i);
  End Loop;

  If l_line_payment_tbl.count > 0 Then

    -- set control record
    l_control_rec.controlled_operation := TRUE;
    l_control_rec.write_to_DB          := TRUE;
    l_control_rec.change_attributes    := TRUE;
    l_control_rec.default_attributes   := TRUE;
    l_control_rec.validate_entity      := TRUE;
    l_control_rec.clear_dependents     := TRUE;
    
    l_control_rec.process              := FALSE;
    l_control_rec.clear_api_cache      := FALSE;
    l_control_rec.clear_api_requests   := FALSE;

    IF l_debug_level  > 0 THEN
      oe_debug_pub.add('OEXVPPYB: before OE_Order_PVT.Line_Payments',3);
    END IF;

     OE_Order_PVT.Line_Payments
    (   p_validation_level          => FND_API.G_VALID_LEVEL_NONE
    ,   p_init_msg_list             => FND_API.G_TRUE
    ,   p_control_rec               => l_control_rec
    ,   p_x_Line_Payment_tbl        => l_Line_Payment_tbl
    ,   p_x_old_Line_Payment_tbl    => l_x_old_Line_Payment_tbl
    ,   x_return_Status             => l_return_status
    );

    IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;

  End If;

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add('Exiting OE_Prepayment_PVT.split_payment ', 1);
  END IF;

  EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      oe_debug_pub.add(G_PKG_NAME||':split_payment :'||SQLERRM);

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      If FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) Then
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Split_Payment '
            );
      End If;
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Split_Payment;

PROCEDURE Process_Payment_Assurance
(p_api_version_number	IN	NUMBER
,p_line_id		IN	NUMBER
,p_activity_id		IN	NUMBER
,x_result_out		OUT NOCOPY VARCHAR2
,x_return_status	OUT NOCOPY VARCHAR2
,x_msg_count		OUT NOCOPY VARCHAR2
,x_msg_data		OUT NOCOPY VARCHAR2
) IS

Type ReceiptsCurType IS REF CURSOR;
ar_receipts_cur		ReceiptsCurType;

/**
CURSOR AR_RECEIPTS_CUR(p_payment_set_id IN NUMBER) IS
SELECT rc.creation_status creation_status, 
       nvl(rm.payment_type_code, 'CHECK') payment_type_code
FROM   ar_cash_receipts cr, 
       ar_receipt_classes rc,
       ar_receipt_methods rm,
       ar_receivable_applications ar
WHERE  rm.receipt_class_id = rc.receipt_class_id
AND    cr.receipt_method_id = rm.receipt_method_id
AND    cr.cash_receipt_id = ar.cash_receipt_id
AND    ar.display = 'Y'
AND    ar.applied_payment_schedule_id = -7 
AND    ar.payment_set_id = p_payment_set_id;
**/


l_line_payment_tbl	OE_ORDER_PUB.Line_Payment_Tbl_Type;
l_receipt_status	VARCHAR2(30);
l_payment_type_code	VARCHAR2(30);
l_payment_set_id	NUMBER;
l_payment_not_assured	VARCHAR2(1) := 'N';
l_return_status		VARCHAR2(2000);
l_sql_stmt		VARCHAR2(2000);
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN
        IF l_debug_level  > 0 THEN
          oe_debug_pub.add('Entering OE_Prepayment_PVT.Process_Payment_Assurance for line: '||p_line_id, 1);
        END IF;

        x_return_status := FND_API.G_RET_STS_SUCCESS;
 	x_result_out := 'COMPLETE:COMPLETE';

        BEGIN
          SELECT payment_set_id
          INTO   l_payment_set_id
          FROM   oe_payments op
                ,oe_order_lines_all ool
          WHERE  op.header_id = ool.header_id
          AND    ool.line_id = p_line_id
          AND    rownum = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          null;
        END;

	-- to check payment assurance for the payment_set_id.
	-- set the status to 'complete:incomplete' so that process control
	-- will go to Eligible block and retry later.
      IF l_payment_set_id IS NOT NULL THEN

         IF l_debug_level  > 0 THEN
           oe_debug_pub.add('Checking payment assurance for payment_set_id: '||l_payment_set_id,3);
         END IF;

        -- if there exists one receipt that is neither REMITTED nor CLEARED.
        --bug5350340 Modified the query to check that the receipt should be cleared and not just remitted for all the payment types other than  credit card
        l_sql_stmt := '
        SELECT ''Y''
        FROM   dual
        WHERE
        (
          EXISTS
          (
             SELECT distinct ra.cash_receipt_id, crh.status
             FROM   AR_CASH_RECEIPT_HISTORY crh , ar_cash_receipts cr, ar_receivable_applications ra
             WHERE  crh.cash_receipt_id = ra.cash_receipt_id
             AND    cr.cash_receipt_id = crh.cash_receipt_id
             AND    ra.payment_set_id = :payment_set_id
             AND    ((cr.payment_server_order_num IS NOT NULL AND
                      cr.approval_code IS NOT NULL AND
                      crh.status NOT IN (''REMITTED'',''CLEARED'')) OR
                     ((cr.payment_server_order_num IS NULL OR
                       cr.approval_code IS NULL) AND
                       crh.status <> ''CLEARED''))                   
             AND    nvl(current_record_flag, ''N'') = ''Y''
           )
         )';

         BEGIN
           EXECUTE IMMEDIATE l_sql_stmt
           INTO l_payment_not_assured
           USING l_payment_set_id ;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             l_payment_not_assured := 'N';
         END;

         IF l_debug_level  > 0 THEN
           oe_debug_pub.add('payment_set_id is: '||l_payment_set_id,3);
           oe_debug_pub.add('l_payment_not_assured flag is: '||l_payment_not_assured,3);
         END IF;

         IF l_payment_not_assured = 'Y' THEN
           x_result_out := 'COMPLETE:INCOMPLETE';
         ELSE
           x_result_out := 'COMPLETE:COMPLETE';
         END IF;

     ELSE
       -- payment set id is null, fund has been collected yet.
        x_result_out := 'COMPLETE:INCOMPLETE';
      END IF;

      IF x_result_out = 'COMPLETE:COMPLETE' THEN
        OE_Order_WF_Util.Update_Flow_Status_Code
		(p_line_id  => p_line_id,
		 p_flow_status_code  => 'PAYMENT_ASSURANCE_COMPLETE',
	 	 x_return_status  => l_return_status);

        IF l_debug_level  > 0 THEN
          oe_debug_pub.add('Return status 1 from update_flow_status_code: '||l_return_status , 3 ) ;
        END IF;
        IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      ELSIF x_result_out =  'COMPLETE:INCOMPLETE' THEN
        OE_Order_WF_Util.Update_Flow_Status_Code
             (p_line_id  => p_line_id,
              p_flow_status_code  => 'PAYMENT_ASSURANCE_NOT_ASSURED',
              x_return_status  => l_return_status);

        IF l_debug_level  > 0 THEN
          oe_debug_pub.add('Return status 2 from update_flow_status_code: '||l_return_status , 3 ) ;
        END IF;
        IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;

      x_return_status := l_return_status;

      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'Process_Payment_Assurance , result_out is: '||x_result_out, 3);        
        oe_debug_pub.add('Exiting OE_Prepayment_PVT.Process_Payment_Assurance for line: '||p_line_id, 1);
      END IF;

EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    WHEN OTHERS THEN
        IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'ORACLE ERROR: ' || SQLERRM , 1 ) ;
        END IF;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Payment Assurance'
            );
        END IF;

END Process_Payment_Assurance;

Procedure Print_Payment_Receipt(p_header_id in Number,
                                x_result_out out varchar2,
                                x_return_status out varchar2)
is

l_organization_id Number;
l_sob_id          Number;
l_new_request_id  Number;
errbuf            Varchar2(200);
l_request_id      Number;
l_order_source_id NUMBER;
l_orig_sys_document_ref  VARCHAR2(50);
l_change_sequence        VARCHAR2(50);
l_source_document_type_id  NUMBER;
l_source_document_id       NUMBER;

l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

begin
        If l_debug_level > 0 Then
           oe_debug_pub.add('entering OE_PrePayment_PVT.print_payment_receipt');
        End If;
        x_return_status := FND_API.G_RET_STS_SUCCESS;
        x_result_out := 'COMPLETE:COMPLETE';
        select order_source_id, orig_sys_document_ref, change_sequence
              ,source_document_type_id, source_document_id
        into   l_order_source_id, l_orig_sys_document_ref, l_change_sequence,
               l_source_document_type_id, l_source_document_id
        from oe_order_headers where header_id = p_header_id;
        -- Set message context
    OE_MSG_PUB.set_msg_context(
           p_entity_code           => 'HEADER'
          ,p_entity_id                  => p_header_id
          ,p_header_id                  => p_header_id
          ,p_order_source_id            => l_order_source_id
          ,p_orig_sys_document_ref      => l_orig_sys_document_ref
          ,p_change_sequence            => l_change_sequence
          ,p_source_document_type_id    => l_source_document_type_id
          ,p_source_document_id         => l_source_document_id);

        select to_number(oe_sys_parameters.value ('SET_OF_BOOKS_ID')) into l_sob_id from dual;
        select fnd_profile.value('ORG_ID') into l_organization_id from DUAL;
        l_new_request_id := FND_REQUEST.SUBMIT_REQUEST('ONT','OEXPMTRC',
            null,null,FALSE,l_sob_id,l_organization_id,NULL,NULL,p_header_id,
            chr(0)); 
            If l_debug_level > 0 Then
               oe_debug_pub.add('l_new_request_id = '||l_new_request_id);
            End If;
            FND_MESSAGE.SET_NAME('ONT','ONT_CONCURRENT_REQUEST_ID');
            fnd_message.set_token('REQUEST_ID',l_new_request_id);
            OE_MSG_PUB.Add;

            IF (l_new_request_id = 0) THEN
               errbuf := FND_MESSAGE.GET;
               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

EXCEPTION

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
          If l_debug_level > 0 Then
             oe_debug_pub.add(  'UNEXPECTED ERROR. EXITING FROM PAYMENT RECEIPT: '||SQLERRM , 1 ) ;
          End If;
          oe_msg_pub.Add_Text(errbuf);
          x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    WHEN OTHERS THEN
          If l_debug_level > 0 Then
             oe_debug_pub.add(  'EXCEPTION , OTHERS. EXITING FROM PAYMENT RECEIPT: '||SQLERRM , 1 ) ;
          End If;
          IF      FND_MSG_PUB.Check_Msg_Level
                (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
          THEN
                OE_MSG_PUB.Add_Exc_Msg
                        (   G_PKG_NAME
                        ,   'Print_Payment_Receipt'
                        );
          END IF;
          x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

END Print_Payment_Receipt;

Procedure Update_Hdr_Payment(p_header_id in number,
                             p_action in varchar2,
                             p_line_id in number,
                            x_return_status out nocopy varchar2,
                            x_msg_count out nocopy number,
                            x_msg_data out nocopy varchar2) is

l_return_status varchar2(1) := FND_API.G_RET_STS_SUCCESS;
l_msg_count number := 0;
l_msg_data varchar2(2000) := NULL;
l_del_payment number := 0; -- 0 means do not delete, 1 means delete.

cursor payment_count is 
select count(payment_type_code)
from oe_payments
where header_id = p_header_id
and line_id is null;

cursor payment_cur is 
select payment_type_code,
       payment_amount,
       check_number,
       credit_card_code,
       credit_card_holder_name,
       credit_card_number,
       credit_card_expiration_date,
       credit_card_approval_code
from oe_payments
where header_id = p_header_id
and payment_collection_event = 'INVOICE'
and line_id is null;

cursor prepay_cur is 
select payment_type_code,
       payment_amount,
       check_number,
       credit_card_code,
       credit_card_holder_name,
       credit_card_number,
       credit_card_expiration_date,
       credit_card_approval_code
from oe_payments
where header_id = p_header_id
and ( payment_collection_event = 'PREPAY'
      or prepaid_amount is not null )
and line_id is null;

cursor prepay_count is
select count(payment_type_code)
from oe_payments
where header_id = p_header_id
and (payment_collection_event = 'PREPAY'
     or prepaid_amount is not null )
and line_id is null;

/*
and exists ( select null
             from ra_terms rat, oe_order_headers_all oeh
             where oeh.header_id = p_header_id
             and oeh.payment_term_id = rat.term_id
             and rat.prepayment_flag = 'Y' );
*/

cursor header_payment_cur is 
select payment_type_code,
       payment_amount,
       check_number,
       credit_card_code,
       credit_card_holder_name,
       credit_card_number,
       credit_card_expiration_date,
       credit_card_approval_code,
       credit_card_approval_date, --bug3589581 
       payment_term_id,
       transactional_curr_code
from oe_order_headers_all
where header_id = p_header_id;

l_payment_type_code varchar2(30) := NULL;
l_payment_amount NUMBER := NULL;
l_check_number varchar2(50) := NULL;
l_credit_card_code varchar2(80) := NULL;
l_credit_card_holder_name varchar2(80) := NULL;
l_credit_card_number varchar2(80) := NULL;
l_credit_card_approval_code varchar2(80) := NULL;
l_credit_card_expiration_date DATE := NULL;
p_payment_type_code varchar2(30) := NULL;
p_payment_amount NUMBER := NULL;
p_check_number varchar2(50) := NULL;
p_credit_card_code varchar2(80) := NULL;
p_credit_card_holder_name varchar2(80) := NULL;
p_credit_card_number varchar2(80) := NULL;
p_credit_card_approval_code varchar2(80) := NULL;
p_credit_card_approval_date DATE := NULL; --bug3589581
p_credit_card_expiration_date DATE := NULL;
p_count number := 0;
p_payment_event varchar2(30) := 'INVOICE';
l_prepay_count number := 0;
p_payment_term_id number;
l_downpayment number;
l_prepayment_flag varchar2(1) := NULL;
p_currency_code varchar2(30) := NULL;
l_order_total number;
l_subtotal number;
l_discount number;
l_charges number;
l_tax number;
l_lock_line_id number;
line_payment_type varchar2(30) := NULL;


l_control_rec                 OE_GLOBALS.Control_Rec_Type;
l_x_Header_Payment_tbl        OE_Order_PUB.Header_Payment_Tbl_Type;
l_x_Old_Header_Payment_tbl        OE_Order_PUB.Header_Payment_Tbl_Type;
l_commitment_id number;
line_commitment_id number;
l_pmt_changed varchar2(1) := 'N';
--bug3733877 start
l_invoice_payment_exists VARCHAR2(1) := 'N';
l_max_payment_number NUMBER := 0;
--bug3733877 end
--bug3781675 start
l_inv_payment_number NUMBER;
l_old_header_rec OE_Order_Pub.Header_Rec_Type;
l_header_rec     OE_Order_Pub.Header_Rec_Type;
l_index NUMBER;
--bug3781675 end

--bug3589581
l_trxn_id NUMBER;

cursor line_payments is
select payment_type_code, payment_trx_id
from oe_payments
where line_id = l_lock_line_id
and   header_id = p_header_id;

--bug3733877
--Cursor to find out if there is an invoice payment in oe_payments
cursor invoice_payment_check is 
select 'Y',payment_number --bug3781675
from oe_payments
where header_id = p_header_id
and line_id is null
and nvl(payment_collection_event,'PREPAY') = 'INVOICE';

Begin

 oe_debug_pub.add('entering update_hdr_payment ');
     x_return_status := l_return_status;

   if p_action = 'UPDATE_LINE' then 

      if p_line_id is null then

         x_return_status := FND_API.G_RET_STS_ERROR;
         oe_debug_pub.add('failed because line_id is null ');
         return;

      else

        Savepoint update_line;

        select line_id, payment_type_code, commitment_id 
        into l_lock_line_id, line_payment_type, line_commitment_id 
        from oe_order_lines_all
        where line_id = p_line_id
        for update nowait;
       
        if l_lock_line_id is null then
            x_return_status := FND_API.G_RET_STS_ERROR;
            oe_debug_pub.add('failed to lock the line with line_id : ' || l_lock_line_id);
            return;
        end if;

        l_pmt_changed := 'N';

        open line_payments;
        loop
           fetch line_payments 
                 into l_payment_type_code, l_commitment_id;
           exit when line_payments%notfound;

           if l_payment_type_code = 'COMMITMENT'and
              l_commitment_id is not null and
              nvl(line_commitment_id, -1) <> l_commitment_id 
           then
                 line_commitment_id := l_commitment_id;
                 l_pmt_changed := 'Y';
           elsif l_payment_type_code is not null and
                 ( line_payment_type is null or 
                   line_payment_type <> l_payment_type_code)
           then
                 line_payment_type := l_payment_type_code;
                 l_pmt_changed := 'Y';
           end if;

        end loop;

        if l_pmt_changed = 'Y' then
          Begin
           update oe_order_lines_all
           set payment_type_code = line_payment_type,
               commitment_id = line_commitment_id
           where line_id = l_lock_line_id;

          exception
            when others then
             x_return_status := FND_API.G_RET_STS_ERROR;
             oe_debug_pub.add('failed to update line payment type: ' || substr(sqlerrm,1,300));
             rollback to savepoint update_line;
             return;
          End; 
        else
           rollback to savepoint update_line;
        end if; -- if l_pmt_changed

      end if;  -- if p_line_id is null
    return;
    end if;  -- if p_action = 'UPDATE_LINE'
          

   /* get the count of records in oe_payments for this order header */
     p_count := 0;

     open payment_count;
     fetch payment_count into p_count;
     close payment_count;

    /* get the count of prepayment records in oe_payments */
    open prepay_count;
    fetch prepay_count into l_prepay_count;
    close prepay_count;

    --bug3733877 start
    --Checking if there exists an invoice payment
    open invoice_payment_check;
    fetch invoice_payment_check into l_invoice_payment_exists, l_inv_payment_number; --bug3781675
    close invoice_payment_check;
    --bug3733877 end

    /* get header payment info and payment_term_id */
    open header_payment_cur;
    fetch header_payment_cur into p_payment_type_code, 
                                       p_payment_amount,
                                       p_check_number,
                                       p_credit_card_code,
                                       p_credit_card_holder_name,
                                       p_credit_card_number,
                                       p_credit_card_expiration_date,
                                       p_credit_card_approval_code,
                                       p_credit_card_approval_date, --bug3589581
                                       p_payment_term_id,
                                       p_currency_code;
    close header_payment_cur;

    --bug3733877 start
    BEGIN
       SELECT nvl(MAX(payment_number),0) INTO l_max_payment_number
       FROM oe_payments
       WHERE header_id = p_header_id
       AND   line_id IS NULL;
    EXCEPTION
       WHEN OTHERS THEN
	  l_max_payment_number := 0;
    END;
    --bug3733877 end

    if p_payment_term_id is not null then
          oe_debug_pub.add('OEXVPPYB: term id : ' || p_payment_term_id);

          l_prepayment_flag := AR_PUBLIC_UTILS.Check_Prepay_Payment_Term(p_payment_term_id);

          oe_debug_pub.add('prepayment_flag is : ' || l_prepayment_flag );
    end if;

    
  IF p_action = 'UPDATE_HEADER' THEN
       --bug3733877 commenting the following condition and checking if invoice payment exists.
       --if (l_prepay_count = 1 and p_count = 1) then
       if nvl(l_invoice_payment_exists,'N') = 'N' then 
         l_payment_type_code := null; 
         l_payment_amount := null;
         l_check_number := null;
         l_credit_card_code := null;
         l_credit_card_holder_name := null;
         l_credit_card_number := null;
         l_credit_card_expiration_date := null;
         l_credit_card_approval_code := null;
         l_del_payment := 1; --delete payment info at the header

	--bug3733877 commenting the following condition
        --elsif p_count > 0 then
        else

           open payment_cur;
           loop
              oe_debug_pub.add('before payment_cur fetching ');
              fetch payment_cur into l_payment_type_code, 
                           l_payment_amount,
                           l_check_number,
                           l_credit_card_code,
                           l_credit_card_holder_name,
                           l_credit_card_number,
                           l_credit_card_expiration_date,
                           l_credit_card_approval_code ;
              exit when payment_cur%NOTFOUND;
              oe_debug_pub.add('payment_type_code is : ' || l_payment_type_code );
            end loop; -- loop for payment_cur
            close payment_cur;
        --commenting the elsif part for bug3733877
/*        elsif p_count = 0 then
              return;   */

        end if; -- if nvl(l_invoice_payment_exists,'N') = 'N'

    if l_payment_type_code is not null or l_del_payment = 1 then
         --bug3781675 start
       
         -- Set up the Header record
         OE_Header_Util.Lock_Row
                (p_header_id                    => p_header_id
                ,p_x_header_rec                 => l_old_header_rec
                ,x_return_status                => l_return_status
                );
         IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            RAISE FND_API.G_EXC_ERROR;
         ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

	 l_header_rec := l_old_header_rec;
	 l_header_rec.payment_type_code             := l_payment_type_code;
	 l_header_rec.payment_amount                := l_payment_amount;
	 l_header_rec.check_number                  := l_check_number;
	 l_header_rec.credit_card_code              := l_credit_card_code;
	 l_header_rec.credit_card_holder_name       := l_credit_card_holder_name;
	 l_header_rec.credit_card_number            := l_credit_card_number;
	 l_header_rec.credit_card_expiration_date   := l_credit_card_expiration_date;
	 l_header_rec.credit_card_approval_code     := l_credit_card_approval_code;
	 --bug3781675 end                   

       oe_debug_pub.add('before updating oe_order_headers_all ');
       
       oe_debug_pub.add('PVIPRANA: l_del_payment is '|| l_del_payment);

      update oe_order_headers_all
      set payment_type_code = l_payment_type_code,
          payment_amount    = l_payment_amount,
          check_number      = l_check_number,
          credit_card_code  = l_credit_card_code,
          credit_card_holder_name = l_credit_card_holder_name,
          credit_card_number      = l_credit_card_number,
          credit_card_expiration_date = l_credit_card_expiration_date,
          credit_card_approval_code   = l_credit_card_approval_code,
	  lock_control      = lock_control + 1 --bug3781675
          where header_id = p_header_id;

       oe_debug_pub.add('after updating oe_order_headers_all');
       --bug3781675 start

       IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110508' THEN

	  -- call notification framework to get header index position
	  OE_ORDER_UTIL.Update_Global_Picture
	     (p_Upd_New_Rec_If_Exists =>FALSE
	      , p_header_rec		=> l_header_rec
	      , p_old_header_rec	=> l_old_header_rec
	      , p_header_id 		=> l_header_rec.header_id
	      , x_index 		=> l_index
	      , x_return_status 	=> l_return_status);
	  	 
	     oe_debug_pub.add(  'UPDATE_GLOBAL RETURN STATUS FOR HDR IS: ' || L_RETURN_STATUS ) ;	 	  
	     oe_debug_pub.add(  'HDR INDEX IS: ' || L_INDEX , 1 ) ;

	     IF l_index is not null then
		-- modify Global Picture
                
		OE_ORDER_UTIL.g_header_rec.payment_type_code:=	
		                                 l_header_rec.payment_type_code;
		OE_ORDER_UTIL.g_header_rec.payment_amount:=	
		                                 l_header_rec.payment_amount;
		OE_ORDER_UTIL.g_header_rec.check_number:=	
		                                 l_header_rec.check_number;
		OE_ORDER_UTIL.g_header_rec.credit_card_code:=	
		                                 l_header_rec.credit_card_code;
		OE_ORDER_UTIL.g_header_rec.credit_card_holder_name:=	
		                                 l_header_rec.credit_card_holder_name;
		OE_ORDER_UTIL.g_header_rec.credit_card_number:=	
		                                 l_header_rec.credit_card_number;
		OE_ORDER_UTIL.g_header_rec.credit_card_expiration_date:=	
		                                 l_header_rec.credit_card_expiration_date;
		OE_ORDER_UTIL.g_header_rec.credit_card_approval_code:=	
		                                 l_header_rec.credit_card_approval_code;
	        OE_ORDER_UTIL.g_header_rec.lock_control:=	
		                                 l_header_rec.lock_control;

		IF l_return_status = FND_API.G_RET_STS_ERROR THEN
		   RAISE FND_API.G_EXC_ERROR;
		ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
		   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
		END IF;
		
		oe_debug_pub.add(  'OEXPVPMB: BEFORE CALLING PROCESS_REQUESTS_AND_NOTIFY' ) ;

		OE_Order_PVT.Process_Requests_And_Notify
		   ( p_process_requests		=> TRUE
		     , p_notify			=> FALSE
		     , p_header_rec		=> l_header_rec
		     , p_old_header_rec		=> l_old_header_rec
		     , x_return_status		=> l_return_status
		   );

		IF l_return_status = FND_API.G_RET_STS_ERROR THEN
		   RAISE FND_API.G_EXC_ERROR;
		ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
		   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
		END IF;

	     END IF ; /* global entity index null check */
	  END IF; --code_release_level check
   --bug3781675 end

   end if; -- if l_payment_type_code is not null

  elsif p_action in ('UPDATE_PAYMENT', 'ACTIONS_LINE_PAYMENTS', 'ACTIONS_PAYMENTS') then

     if p_action = 'ACTIONS_LINE_PAYMENTS' then

        if l_prepay_count > 0 then

           oe_debug_pub.add('cannot do this as there exists prepayments ');

            return;
        end if;
     end if;  -- if p_action = 'ACTIONS_LINE_PAYMENTS'
 
           
     oe_debug_pub.add('p_count is : ' || p_count );
     oe_debug_pub.add('payment_type_code is : ' || nvl(p_payment_type_code, 'null' ));

     if p_action = 'ACTIONS_PAYMENTS' then

        if p_count > 0 then

           oe_debug_pub.add('no need to do this as there exists payments ');

            return;
        end if;
     end if;  -- if p_action = 'ACTIONS_PAYMENTS'

     --bug3781675 using the same l_x_header_payment_tbl for both create and update operations

     if   p_payment_type_code is not null 
     and (p_credit_card_number is not null
     or p_check_number is not null
     or p_payment_type_code = 'CASH' )
     then  -- insert payment record into oe_payments

            if nvl(l_prepayment_flag, 'N') = 'Y' and
	    --bug3733877 adding the following condition so that prepayment record gets insterted only when there are no payment record in oe_payments.
	      p_count = 0 then

               OE_OE_TOTALS_SUMMARY.Order_Totals
                               (
                               p_header_id=>p_header_id,
                               p_subtotal =>l_subtotal,
                               p_discount =>l_discount,
                               p_charges  =>l_charges,
                               p_tax      =>l_tax
                               );

               l_order_total := nvl(l_subtotal,0) + nvl(l_charges,0) + nvl(l_tax,0);

       oe_debug_pub.add('order total is : ' || l_order_total);

               l_downpayment := oe_prepayment_util.get_downpayment_amount(
                 p_header_id => p_header_id,
                 p_term_id => p_payment_term_id,
                 p_curr_code => p_currency_code,
                 p_order_total => l_order_total);

               p_payment_event := 'PREPAY';
               p_payment_amount := l_downpayment;
 
            end if; -- if nvl(l_prepayment_flag,'N') = 'Y'

         oe_debug_pub.add('before calling BO ' );
           l_control_rec.controlled_operation := TRUE;
           l_control_rec.check_security       := TRUE;
           l_control_rec.default_attributes   := TRUE;
           l_control_rec.change_attributes    := TRUE;

	   --bug3733877 setting the clear_dependents to FALSE as we pass all the values
           l_control_rec.clear_dependents     := FALSE; 
	   
           l_control_rec.validate_entity      := TRUE;
           l_control_rec.write_to_DB          := TRUE;
           l_control_rec.process              := FALSE;

            --  Instruct API to retain its caches

           l_control_rec.clear_api_cache      := FALSE;
           l_control_rec.clear_api_requests   := FALSE;

           --  Load IN parameters if any exist
           l_x_Header_Payment_tbl(1):=OE_ORDER_PUB.G_MISS_HEADER_PAYMENT_REC;
           l_x_old_Header_Payment_Tbl(1):=OE_ORDER_PUB.G_MISS_HEADER_PAYMENT_REC;
           l_x_Header_Payment_tbl(1).header_id                := p_header_id;

          --bug3781675 adding an IF-ELSE condition for create and update operations 
           IF nvl(l_invoice_payment_exists,'N') = 'N' THEN
	      l_x_Header_Payment_tbl(1).payment_number           := l_max_payment_number+1;
	      l_x_Header_Payment_tbl(1).operation := OE_GLOBALS.G_OPR_CREATE;
	   
	      --  Defaulting of flex values is currently done by the form.
	      --  Set flex attributes to NULL in order to avoid defaulting them.

	      l_x_header_Payment_tbl(1).attribute1               := NULL;
	      l_x_header_Payment_tbl(1).attribute2               := NULL;
	      l_x_header_Payment_tbl(1).attribute3               := NULL;
	      l_x_header_Payment_tbl(1).attribute4               := NULL;
	      l_x_header_Payment_tbl(1).attribute5               := NULL;
	      l_x_header_Payment_tbl(1).attribute6               := NULL;
	      l_x_header_Payment_tbl(1).attribute7               := NULL;
	      l_x_header_Payment_tbl(1).attribute8               := NULL;
	      l_x_header_Payment_tbl(1).attribute9               := NULL;
	      l_x_header_Payment_tbl(1).attribute10              := NULL;
	      l_x_header_Payment_tbl(1).attribute11              := NULL;
	      l_x_header_Payment_tbl(1).attribute12              := NULL;
	      l_x_header_Payment_tbl(1).attribute13              := NULL;
	      l_x_header_Payment_tbl(1).attribute14              := NULL;
	      l_x_header_Payment_tbl(1).attribute15              := NULL;
	      l_x_header_Payment_tbl(1).context                  := NULL;
           ELSE
	      l_x_Header_Payment_tbl(1).payment_number           := l_inv_payment_number;
	      l_x_Header_Payment_tbl(1).operation := OE_GLOBALS.G_OPR_UPDATE;
	   END IF;	   

	   oe_debug_pub.add('PVIPRANA: l_x_Header_Payment_tbl(1).operation is '||l_x_Header_Payment_tbl(1).operation);
           l_x_Header_Payment_tbl(1).payment_type_code := p_payment_type_code;
           l_x_Header_Payment_tbl(1).payment_collection_event := 'INVOICE';
           l_x_Header_Payment_tbl(1).payment_amount := NULL;
	   
           l_x_Header_Payment_tbl(1).check_number   := p_check_number;
           l_x_Header_Payment_tbl(1).credit_card_code  := p_credit_card_code;
           l_x_Header_Payment_tbl(1).credit_card_holder_name := p_credit_card_holder_name;
           l_x_Header_Payment_tbl(1).credit_card_number      := p_credit_card_number;
           l_x_Header_Payment_tbl(1).credit_card_expiration_date := p_credit_card_expiration_date;
           l_x_Header_Payment_tbl(1).credit_card_approval_code   := p_credit_card_approval_code;
	    --bug3589581 start
	   l_x_Header_Payment_tbl(1).credit_card_approval_date   := p_credit_card_approval_date;	   
	  
           IF l_x_Header_Payment_tbl(1).credit_card_approval_code IS NOT NULL THEN
	      oe_debug_pub.add('Credit Card Approval Code exists.... Fetching current auth code');
	      oe_header_util.query_row
		 ( p_header_id  => p_header_id
		 , x_header_rec => l_header_rec); 
   	         
	      OE_Verify_Payment_PUB.Fetch_Current_Auth
                  ( p_header_rec  => l_header_rec
                   , p_trxn_id     => l_trxn_id
		    , p_tangible_id => l_x_Header_Payment_tbl(1).tangible_id
                  ) ;

	      oe_debug_pub.add(  ' AFTER CALLING FETCH_CURRENT_AUTH' ) ;
        	
              oe_debug_pub.add(  'TANGIBLE ID IS : '||l_x_Header_Payment_tbl(1).tangible_id ) ;
	    END IF;
	    --bug3589581 end
--  Load IN parameters if any exist

         if nvl(l_prepayment_flag, 'N') = 'Y' AND
	 --bug3733877 Adding the following condition so that the prepayment record is inserted only when p_count = 0
           p_count = 0 THEN

           l_x_Header_Payment_tbl(2):=OE_ORDER_PUB.G_MISS_HEADER_PAYMENT_REC;
           l_x_old_Header_Payment_Tbl(2):=OE_ORDER_PUB.G_MISS_HEADER_PAYMENT_REC;
           l_x_Header_Payment_tbl(2).header_id                := p_header_id;
           l_x_Header_Payment_tbl(2).payment_number           := l_max_payment_number+2; --bug3733877

    --  Defaulting of flex values is currently done by the form.
    --  Set flex attributes to NULL in order to avoid defaulting them.

           l_x_header_Payment_tbl(2).attribute1               := NULL;
           l_x_header_Payment_tbl(2).attribute2               := NULL;
           l_x_header_Payment_tbl(2).attribute3               := NULL;
           l_x_header_Payment_tbl(2).attribute4               := NULL;
           l_x_header_Payment_tbl(2).attribute5               := NULL;
           l_x_header_Payment_tbl(2).attribute6               := NULL;
           l_x_header_Payment_tbl(2).attribute7               := NULL;
           l_x_header_Payment_tbl(2).attribute8               := NULL;
           l_x_header_Payment_tbl(2).attribute9               := NULL;
           l_x_header_Payment_tbl(2).attribute10              := NULL;
           l_x_header_Payment_tbl(2).attribute11              := NULL;
           l_x_header_Payment_tbl(2).attribute12              := NULL;
           l_x_header_Payment_tbl(2).attribute13              := NULL;
           l_x_header_Payment_tbl(2).attribute14              := NULL;
           l_x_header_Payment_tbl(2).attribute15              := NULL;
           l_x_header_Payment_tbl(2).context                  := NULL;

    --  Set Operation to Create

           l_x_Header_Payment_tbl(2).operation := OE_GLOBALS.G_OPR_CREATE;
           l_x_Header_Payment_tbl(2).payment_type_code := p_payment_type_code;
           l_x_Header_Payment_tbl(2).payment_collection_event := p_payment_event;
           l_x_Header_Payment_tbl(2).payment_amount := p_payment_amount;
           l_x_Header_Payment_tbl(2).check_number   := p_check_number;
           l_x_Header_Payment_tbl(2).credit_card_code  := p_credit_card_code;
           l_x_Header_Payment_tbl(2).credit_card_holder_name := p_credit_card_holder_name;
           l_x_Header_Payment_tbl(2).credit_card_number      := p_credit_card_number;
           l_x_Header_Payment_tbl(2).credit_card_expiration_date := p_credit_card_expiration_date;
           l_x_Header_Payment_tbl(2).credit_card_approval_code   := p_credit_card_approval_code;

	      

         END IF; -- if prepayment_flag = 'Y'

        oe_debug_pub.add('l_x_header_payment_tbl ' || l_x_header_payment_tbl.count);
        oe_debug_pub.add('l_x_old_header_payment_tbl ' || l_x_old_header_payment_tbl.count);
	
    --  Call OE_Order_PVT.Header_Payments
          OE_Order_PVT.Header_Payments
          (   p_validation_level            => FND_API.G_VALID_LEVEL_NONE
          ,   p_init_msg_list               => FND_API.G_TRUE
          ,   p_control_rec                 => l_control_rec
          ,   p_x_Header_Payment_tbl        => l_x_Header_Payment_tbl
          ,   p_x_old_Header_Payment_tbl    => l_x_old_Header_Payment_tbl
          ,   x_return_Status               => l_return_status
          );

          IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
             RAISE FND_API.G_EXC_ERROR;
          END IF;

	  
   else --if p_payment_type_code is null
     --bug3733877 start
       BEGIN
         DELETE FROM oe_payments
	 WHERE header_id = p_header_id
	 AND line_id IS NULL
	 AND nvl(payment_collection_event,'PREPAY') = 'INVOICE';
       EXCEPTION
	 WHEN OTHERS THEN
	    null;
       END;
     --bug3733877 end
                
   end if; -- if p_payment_type_code is not null


  END IF; -- if p_action in ('UPDATE_HEADER', 'DELETE_PAYMENT')

  oe_debug_pub.add('before end ');
   x_return_status := l_return_status;
   oe_debug_pub.add('return status w no error is : ' || x_return_status);

EXCEPTION

   WHEN others then
       x_return_status := FND_API.G_RET_STS_ERROR;
    oe_debug_pub.add('when others error ');
       RAISE;
    

END Update_Hdr_Payment;

/*--------------------------------------------------------------------------
Procedure Create_Refund
This procedure calls AR Refund Wrapper API to create refund for prepayments.
----------------------------------------------------------------------------*/
PROCEDURE Create_Refund 
(  p_header_rec        IN   OE_Order_PUB.Header_Rec_Type
,  p_refund_amount            IN   NUMBER
,  p_payment_set_id    IN   NUMBER
,  p_bank_account_id   IN   NUMBER   
,  p_receipt_method_id IN   NUMBER   
,  x_return_status     OUT  NOCOPY VARCHAR2
)
IS

l_return_status			VARCHAR2(30);
l_prepay_application_id		NUMBER;
l_number_of_refund_receipts	NUMBER;
l_receipt_number		VARCHAR2(30);
l_cash_receipt_id		NUMBER;
l_receivable_application_id	NUMBER;
l_receivables_trx_id		NUMBER;
l_refund_amount			NUMBER;
l_format_mask			VARCHAR2(500);
l_msg_count          		NUMBER := 0 ;
l_msg_data           		VARCHAR2(2000) := NULL ;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'ENTERING OE_PREPAYMENT_PV.CREATE_REFUND.' , 1 ) ;
    oe_debug_pub.add(  'Before calling refund wrapper API refund amount IS: '||p_refund_amount , 1 ) ;
    oe_debug_pub.add(  'Before calling refund wrapper API payment_set_id IS: '||p_payment_set_id , 1 ) ;
    oe_debug_pub.add(  'OEXVPPYB: receipt_method_id is: '||p_receipt_method_id, 3 ) ;
    oe_debug_pub.add(  'OEXVPPYB: bank_account_id is: '||p_bank_account_id, 3 ) ;
END IF;

                  AR_OM_PREPAY_REFUND_PVT.refund_prepayment_wrapper(
                     p_api_version       	=> 1.0,
                     p_init_msg_list     	=> FND_API.G_TRUE,
                     p_commit            	=> FND_API.G_FALSE,
                     p_validation_level		=> FND_API.G_VALID_LEVEL_FULL,
                     x_return_status     	=> l_return_status,
                     x_msg_count         	=> l_msg_count,
                     x_msg_data          	=> l_msg_data,
                     p_prepay_application_id	=> l_prepay_application_id,
                     p_number_of_refund_receipts=> l_number_of_refund_receipts,
                     p_bank_account_id   	=> p_bank_account_id,
                     p_receipt_method_id 	=> p_receipt_method_id,
                     p_receipt_number		=> l_receipt_number,
                     p_cash_receipt_id		=> l_cash_receipt_id,
                     p_receivable_application_id=> l_receivable_application_id, --OUT
                     p_receivables_trx_id       => l_receivables_trx_id, --OUT
                     p_refund_amount            => p_refund_amount, 
                     p_refund_date		=> sysdate,
                     p_refund_gl_date		=> null,
                     p_ussgl_transaction_code	=> null,
                     p_attribute_rec		=> null,
                     p_global_attribute_rec	=> null,
                     p_comments			=> null,
                     p_payment_set_id		=> p_payment_set_id
                    );


     x_return_status := l_return_status;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXVPPYB: after calling refund_prepayment_wrapper API, return status is: '||l_return_status, 3 ) ;
         oe_debug_pub.add(  'OEXVPPYB: RECEIPT_NUMBER AFTER CALLING AR REFUND_PREPAYMENTS IS: '||L_RECEIPT_NUMBER , 1 ) ;
         oe_debug_pub.add(  'OEXVPPYB: NUMBER_OF_REFUND AFTER CALLING AR REFUND_PREPAYMENT IS: '||L_NUMBER_OF_REFUND_RECEIPTS , 1 ) ;
     END IF;

     l_format_mask := get_format_mask(p_header_rec.transactional_curr_code);

     IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
       fnd_message.Set_Name('ONT', 'ONT_REFUND_PROCESS_SUCCESS');
       FND_MESSAGE.SET_TOKEN('AMOUNT' , TO_CHAR(p_refund_amount, l_format_mask));
       FND_MESSAGE.SET_TOKEN('NUMBER' , l_number_of_refund_receipts);
       oe_msg_pub.add;
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: REFUND REQUEST OF ' ||P_REFUND_AMOUNT||' HAS BEEN PROCESSED SUCCESSFULLY.' , 3 ) ;
	  oe_debug_pub.add('pviprana: Releasing Prepayment Hold');
       END IF;
       --bug3507871       
       Release_Prepayment_Hold ( p_header_id     => p_header_rec.header_id
                                , p_msg_count     => l_msg_count
                                , p_msg_data      => l_msg_data
                                , p_return_status => l_return_status
                                );

       		    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         	      RAISE FND_API.G_EXC_ERROR;
       		    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
         	      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           	    END IF;
     ELSE
       fnd_message.Set_Name('ONT', 'ONT_REFUND_PROCESS_FAILED');
       FND_MESSAGE.SET_TOKEN('AMOUNT', TO_CHAR(p_refund_amount, l_format_mask));
       oe_msg_pub.add;
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: REFUND PROCESSING FOR ' ||P_REFUND_AMOUNT||' FAILED.' , 3 ) ;
       END IF;

       IF l_msg_count = 1 THEN
         IF l_debug_level  > 0 THEN
           oe_debug_pub.add('Error message after calling Create_Prepayment API: '||l_msg_data , 3 ) ;
         END IF;
         oe_msg_pub.add_text(p_message_text => l_msg_data);
       ELSIF ( FND_MSG_PUB.Count_Msg > 0 ) THEN
         arp_util.enable_debug;
         FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
           -- l_msg_text := FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE);
           l_msg_data := FND_MSG_PUB.Get(i,'F');
           IF l_debug_level  > 0 THEN
              oe_debug_pub.Add( 'Error message from AR API: '|| L_MSG_DATA , 3 ) ;
           END IF;
           oe_msg_pub.add_text(p_message_text => l_msg_data);
         END LOOP;
       END IF;
       IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         RAISE FND_API.G_EXC_ERROR;
       ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;
     END IF;

   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'EXITING OE_PREPAYMENT_PV.Create_Refund.' , 1 ) ;
   END IF;

  EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'Unexpected error in Create_Refund: ' || SQLERRM , 3 ) ;
      END IF;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Create_Refund'
            );
      END IF;
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'Other oracle error in Create_Refund: ' || SQLERRM , 3 ) ;
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

END Create_Refund;

PROCEDURE Process_Payment_Refund
(  p_header_rec        IN   OE_Order_PUB.Header_Rec_Type
,  x_msg_count         OUT  NUMBER   
,  x_msg_data          OUT  VARCHAR2 
,  x_return_status     OUT  VARCHAR2
) IS

l_bank_account_id		NUMBER;
l_receipt_method_id		NUMBER;
l_refund_amount			NUMBER;
l_payment_set_id		NUMBER;
l_return_status			VARCHAR2(30);
l_msg_count          		NUMBER := 0 ;
l_msg_data           		VARCHAR2(2000) := NULL ;
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'ENTERING OE_PREPAYMENT_PV.Process_Payment_Refund.' , 1 ) ;
  END IF;

  OE_Prepayment_Util.Get_PrePayment_Info
    ( p_header_id      => p_header_rec.header_id 
    , x_payment_set_id => l_payment_set_id
    , x_prepaid_amount => l_refund_amount
    );

  -- no need to process payment refund.
  IF nvl(l_refund_amount, 0) <= 0 THEN
    return;
  END IF;

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add('In Process_Payment_Refund, refund amount is: '||l_refund_amount, 3);
    oe_debug_pub.add('In Process_Payment_Refund, payment_set_id is: '||l_payment_set_id,3) ;
  END IF;

  Create_Refund
   (p_header_rec		=> p_header_rec,
    p_refund_amount             => l_refund_amount, 
    p_payment_set_id		=> l_payment_set_id,
    p_bank_account_id   	=> l_bank_account_id,
    p_receipt_method_id 	=> l_receipt_method_id,
    x_return_status     	=> l_return_status
   );

   IF l_debug_level  > 0 THEN
     oe_debug_pub.add(  'In Process_Payment_Refund, after calling create_refund return status is: '||l_return_status, 3 ) ;
   END IF;


   IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
     UPDATE oe_payments
     SET    payment_amount = 0, prepaid_amount = 0
     WHERE  payment_collection_event = 'PREPAY'
     AND    header_id = p_header_rec.header_id;

   ELSIF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
     IF l_return_status = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
     ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;
   END IF;

   x_return_status := l_return_status;

  IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'EXITING OE_PREPAYMENT_PV.Process_Payment_Refund. '||x_return_status , 1 ) ;
  END IF;

  EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_Payment_Refund'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );


END Process_Payment_Refund;

/*----------------------------------------------------------------------
Returns 'Y' if  any type of payment hold exists for the order.
This is introduced for multiple payments project, to check if hold id
16 exists on order or line in addition to any prepayment holds 
(13, 14, 15).
----------------------------------------------------------------------*/
PROCEDURE Any_Payment_Hold_Exists
(  p_header_id      IN   NUMBER
,  p_hold_exists    OUT  NOCOPY VARCHAR2
)
IS
l_hold_result   VARCHAR2(30);
p_hold_rec      OE_HOLDS_PUB.any_line_hold_rec;
l_return_status VARCHAR2(30);
l_msg_count     NUMBER;
l_msg_data      VARCHAR2(2000);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: Entering OE_PREPAYMENT_PVT.Any_Payment_Hold_Exists.' , 3 ) ;
  END IF;

  -- First check if there is any prepayment hold (hold id 13,14,15).
  Any_Prepayment_Hold_Exists ( p_header_id   => p_header_id
                             , p_hold_exists => p_hold_exists
                             );

  IF p_hold_exists = 'Y' THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: PREPAYMENT HOLD EXISTS ON HEADER ID : ' ||
P_HEADER_ID , 3 ) ;
    END IF;
    RETURN ;
  ELSE
    -- check if there exists header level pending authorization hold.
    OE_HOLDS_PUB.Check_Holds
		      ( p_api_version    => 1.0
		      , p_header_id      => p_header_id
		      , p_hold_id        => 16
		      , p_entity_code    => 'O'
		      , p_entity_id      => p_header_id
		      , x_result_out     => l_hold_result
		      , x_msg_count      => l_msg_count
		      , x_msg_data       => l_msg_data
		      , x_return_status  => l_return_status
		      );

    IF l_hold_result = FND_API.G_TRUE THEN
      p_hold_exists := 'Y';
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXVPPYB: PAYMENT HOLD 16 EXISTS ON ORDER.' , 3 ) ;
      END IF;
      return;
    ELSE
      -- check if there exists line level pending authorization hold.
      p_hold_rec.header_id := p_header_id;
      p_hold_rec.hold_id := 16;
      OE_HOLDS_PUB.Check_Any_Line_Hold
                       (x_hold_rec             => p_hold_rec
                       ,x_return_status        => l_return_status
                       ,x_msg_count            => l_msg_count
                       ,x_msg_data             => l_msg_data
                       );

      IF ( l_return_status = FND_API.G_RET_STS_SUCCESS AND
           p_hold_rec.x_result_out = FND_API.G_TRUE )
      THEN
        p_hold_exists := 'Y';
        IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: PAYMENT HOLD 16 EXISTS ON ORDER LINE.' , 3 ) ;
        END IF;
      ELSE
        p_hold_exists := 'N';
        IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'OEXVPPYB: NO PAYMENT HOLD ON ORDER.' , 3 ) ;
        END IF;
      END IF;
    END IF;
  END IF;

  EXCEPTION
   
    WHEN OTHERS THEN
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Any_Payment_Hold_Exists'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );      

END Any_Payment_Hold_Exists;

PROCEDURE Update_Payment_Numbers(p_header_id in number,
                             p_line_id in number := NULL,
                            x_return_status out nocopy varchar2,
                            x_msg_count out nocopy number,
                            x_msg_data out nocopy varchar2) IS

CURSOR lock_lin_Payments(p_header_id in number,
                         p_line_id in NUMBER) IS
  SELECT payment_type_code
  FROM   oe_payments
  WHERE  header_id = p_header_id
  AND    line_id = p_line_id
  AND    payment_number is null
    FOR UPDATE NOWAIT;

CURSOR lock_hdr_Payments(p_header_id  NUMBER) IS
  SELECT payment_type_code
  FROM   oe_payments
  WHERE  header_id = p_header_id
  AND    payment_number is null
    FOR UPDATE NOWAIT;

l_payment_type varchar2(30) := null;
l_payment_trx_id number := -1;
Begin

 x_return_status := FND_API.G_RET_STS_SUCCESS;
 x_msg_count := 0;
 x_msg_data := null;

 if p_line_id is not null then

    Begin
      SAVEPOINT LOCK_LINE_PAYMENTS;
       OPEN lock_lin_Payments(p_header_id, p_line_id);
       FETCH lock_lin_Payments INTO l_payment_type;
       CLOSE lock_lin_Payments;

    Exception

      when no_data_found then
            IF lock_lin_Payments%ISOPEN Then
               close lock_lin_Payments;
            END IF;
            oe_debug_pub.add('no line payments exist');
            x_return_status := FND_API.G_RET_STS_SUCCESS;
            return;
      when others then
            ROLLBACK TO LINE_PAYMENTS;
            IF lock_lin_Payments%ISOPEN Then
               close lock_lin_Payments;
            END IF;
            oe_debug_pub.add('locking the row failed');
            -- issue an error message saying that lock row failed.
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
            RAISE;
    End;
    -- was able to lock the row. so, go ahead and update oe_payments.
    Begin

     if l_payment_type is not null then

        update oe_payments
        set payment_number = 1
        where header_id = p_header_id
        and line_id = p_line_id
        and payment_number is null
        and payment_type_code = l_payment_type;

     end if;

    Exception
      when no_data_found then
           --oe_msg_pub.add(  ); --
           x_return_status := FND_API.G_RET_STS_ERROR;
           RAISE;
           
      when others then
           --oe_msg_pub.add(); --
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    End;

 elsif p_header_id is not null then

    Begin
      SAVEPOINT LOCK_HEADER_PAYMENTS;
      OPEN lock_hdr_Payments(p_header_id);
      LOOP
        FETCH lock_hdr_Payments INTO l_payment_type;
        EXIT WHEN lock_hdr_Payments%NOTFOUND;
      END LOOP;
      CLOSE lock_hdr_Payments;

    Exception

      when no_data_found then
            IF lock_hdr_Payments%ISOPEN Then
               close lock_hdr_Payments;
            END IF;
            oe_debug_pub.add('no header payments exist');
            x_return_status := FND_API.G_RET_STS_SUCCESS;
            return;
      when others then
            ROLLBACK TO LOCK_HEADER_PAYMENTS;
            IF lock_hdr_Payments%ISOPEN Then
               close lock_hdr_Payments;
            END IF;
            oe_debug_pub.add('locking the row failed');
            -- issue an error message saying that lock row failed.
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    End;
    -- was able to lock the row. so, go ahead and update oe_payments.
    Begin

        update oe_payments
        set payment_number = 1
        where header_id = p_header_id
        and payment_number is null;

    Exception
      when no_data_found then
           --oe_msg_pub.add(  ); --
           x_return_status := FND_API.G_RET_STS_ERROR;
           RAISE;
      when others then
           --oe_msg_pub.add(); --
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    End;

 end if;

END Update_Payment_Numbers;

PROCEDURE Delete_Payment_Hold 
(p_line_id           	IN   NUMBER
,p_header_id		IN   NUMBER
,p_hold_type 		IN   VARCHAR2
,x_return_status      	OUT  NOCOPY VARCHAR2
,x_msg_count          	OUT  NOCOPY NUMBER
,x_msg_data           	OUT  NOCOPY VARCHAR2
) IS

l_prepay_exists		VARCHAR2(1) := 'N';
l_msg_count         NUMBER := 0;
l_msg_data          VARCHAR2(2000);
l_return_status     VARCHAR2(30);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--

BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXVPPYB: Entering OE_PREPAYMENT_PVT.Delete_Payment_Hold.' , 3 ) ;
  END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF p_line_id IS NOT NULL THEN
    OE_Verify_Payment_PUB.Release_Verify_Line_Hold
       ( p_header_id     => p_header_id
       , p_line_id       => p_line_id
       , p_epayment_hold => 'Y'
       , p_msg_count     => l_msg_count
       , p_msg_data      => l_msg_data
       , p_return_status => l_return_status
       );

    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

  ELSE
    IF p_hold_type = 'PREPAYMENT' THEN
      OE_Prepayment_PVT.Release_Prepayment_Hold 
            ( p_header_id     => p_header_id
            , p_msg_count     => l_msg_count
            , p_msg_data      => l_msg_data
            , p_return_status => l_return_status
            );

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

    ELSE
      OE_Verify_Payment_PUB.Release_Verify_Hold
         ( p_header_id     => p_header_id
         , p_epayment_hold => 'Y'
         , p_msg_count     => l_msg_count
         , p_msg_data      => l_msg_data
         , p_return_status => l_return_status
         );
      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         RAISE FND_API.G_EXC_ERROR;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF; 
    END IF;
  END IF;
 
EXCEPTION
   WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Delete_Prepayment_Hold'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => l_msg_count,
              p_data  => l_msg_data
            );

END Delete_Payment_Hold;
  
END OE_PrePayment_PVT ;
/

--show errors package body OE_PrePayment_PVT;
COMMIT;
EXIT;

