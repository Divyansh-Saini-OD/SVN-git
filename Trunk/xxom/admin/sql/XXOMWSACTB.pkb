CREATE OR REPLACE
PACKAGE BODY XX_OM_SALES_ACCT_PKG as
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Office Depot                                       |
-- +===================================================================+
-- | Name  : XX_OM_SALES_ACCT_PKG (XXOMWSACTB.pkb)                      |
-- | Description  : This package contains procedures related to the    | 
-- | HVOP Sales Accounting Data processing. It includes pulling KFF    |
-- | data from interface tables, processing Payments, Creating TAX     |
-- | records and pulling return tenders data from interface tables     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |1.0        06-APR-2007   Manish Chavan    Initial version          |
-- |                                                                   |
-- +===================================================================+


G_PKG_NAME         CONSTANT     VARCHAR2(30):='XX_OM_SALES_ACCT_PKG';

FUNCTION Get_rem_bank_acct_id
(p_receipt_method_id    IN     NUMBER
, p_curr_code           IN     VARCHAR2
) RETURN NUMBER;


PROCEDURE Get_Payment_Data(
  p_header_id   IN  NUMBER
, p_batch_id    IN NUMBER
, x_return_status  OUT VARCHAR2
);

PROCEDURE Apply_Hold
(   p_header_id       IN   NUMBER
,   p_hold_id         IN   NUMBER
,   p_msg_count       IN OUT  NOCOPY NUMBER
,   p_msg_data        IN OUT  NOCOPY VARCHAR2
,   x_return_status   OUT  NOCOPY VARCHAR2
);

PROCEDURE  Create_Sales_Credits
( p_batch_id    IN NUMBER
, x_return_status  OUT VARCHAR2
);

PROCEDURE  Get_KFF_DFF_Data
(   p_header_id IN NUMBER
,   p_mode      IN VARCHAR2
,   p_batch_id  IN NUMBER
,   x_return_status OUT VARCHAR2
);

PROCEDURE  Create_Tax_Records
(   p_header_id IN NUMBER
,   p_mode      IN VARCHAR2
,   p_batch_id  IN NUMBER
,   x_return_status OUT VARCHAR2
);

PROCEDURE  Get_Return_Tenders
(   p_header_id     IN NUMBER
,   x_return_status OUT VARCHAR2
);


PROCEDURE  Update_Actual_Shipment_Date
(   p_header_id     IN NUMBER );

-- +===================================================================+
-- | Name  : PROCESS_BULK                                              |
-- | Description  : This Procedure will be used to process data in     |
-- |                BULK mode -> Orders being imported by HVOP         |
-- |                                                                   |
-- | Parameters :  p_header_id    IN  -> Current Order in the workflow |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_BULK(
  p_header_id   IN  NUMBER)
IS
ln_header_id		NUMBER;
ln_batch_id		NUMBER;
lc_return_status	VARCHAR2(30) := 'S';
ln_msg_count		NUMBER;
lc_msg_data		VARCHAR2(100);
lc_mode                  VARCHAR2(10);
lc_tax_failure_flag      VARCHAR2(1) ;
lc_KFF_failure_flag      VARCHAR2(1) ;
lc_scredit_failure_flag  VARCHAR2(1) ;
lc_payment_failure_flag  VARCHAR2(1) ;
BEGIN

    oe_debug_pub.add('Entering Process Bulk :');

    -- Get the Batch_Id so that we process all records in a batch at a time.
    SELECT batch_id
    INTO ln_batch_id
    FROM OE_ORDER_HEADERS
    WHERE header_id = p_header_id;

    oe_debug_pub.add('Batch_id is :' || ln_batch_id);

    IF NOT G_HVOP_PAYMENT_PROCESSED.EXISTS(ln_batch_id) THEN
        G_HVOP_PAYMENT_PROCESSED(ln_batch_id) := NULL;
    END IF;

    IF NOT G_HVOP_TAX_PROCESSED.EXISTS(ln_batch_id) THEN
        G_HVOP_TAX_PROCESSED(ln_batch_id) := NULL;
    END IF;

    IF NOT G_HVOP_SCREDIT_PROCESSED.EXISTS(ln_batch_id) THEN
        G_HVOP_SCREDIT_PROCESSED(ln_batch_id) := NULL;
    END IF;

    IF NOT G_HVOP_KFF_PROCESSED.EXISTS(ln_batch_id) THEN
        G_HVOP_KFF_PROCESSED(ln_batch_id) := NULL;
    END IF;

    IF G_HVOP_PAYMENT_PROCESSED(ln_batch_id) = 'Y'
    AND G_HVOP_TAX_PROCESSED(ln_batch_id) = 'Y'
    AND G_HVOP_SCREDIT_PROCESSED(ln_batch_id) = 'Y'
    AND G_HVOP_KFF_PROCESSED(ln_batch_id) = 'Y'
    THEN
        RETURN;
    END IF;

    oe_debug_pub.add(' After Batch_id is :' || ln_batch_id);

    IF G_HVOP_TAX_PROCESSED(ln_batch_id) IS NULL THEN
        oe_debug_pub.add('Creating TAX Records :');
        Create_Tax_Records(
                          p_header_id     => p_header_id
                        , p_mode          => 'HVOP'
                        , p_batch_id      => ln_batch_id
                        , x_return_status => lc_return_status
                        );
        oe_debug_pub.add(' After Creating TAX Records :');
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            oe_debug_pub.add('Failed to create Tax Records :'||ln_batch_id );
            G_HVOP_TAX_PROCESSED(ln_batch_id) := 'E';
        ELSE
            G_HVOP_TAX_PROCESSED(ln_batch_id) := 'Y';
        END IF;
    END IF;

    -- Put the order on hold if the processing failed.

    IF G_HVOP_TAX_PROCESSED(ln_batch_id) = 'E' THEN

          IF G_TAX_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_TAX_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: Tax Processing Failure';
          END IF;

          Apply_Hold( p_header_id  => p_header_id
                    , p_hold_id    => G_TAX_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );
    END IF;

    IF G_HVOP_KFF_PROCESSED(ln_batch_id) IS NULL THEN
        oe_debug_pub.add('Creating KFF DATA  :'||ln_batch_id );
        Get_KFF_DFF_Data(
                          p_header_id     => p_header_id
                        , p_mode          => 'HVOP'
                        , p_batch_id      => ln_batch_id
                        , x_return_status => lc_return_status
                        );
        oe_debug_pub.add(' After Creating KFF DATA  :'||ln_batch_id );
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            oe_debug_pub.add('Failed to create DFF/KFF data :'||ln_batch_id );
            G_HVOP_KFF_PROCESSED(ln_batch_id) := 'E';
        ELSE
            G_HVOP_KFF_PROCESSED(ln_batch_id) := 'Y';
        END IF;
    END IF;

    -- Put the order on hold if the processing failed.

    IF G_HVOP_KFF_PROCESSED(ln_batch_id) = 'E' THEN

          IF G_KFF_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_KFF_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: KFF Data Processing Failure';
          END IF;

          Apply_Hold( p_header_id  => p_header_id
                    , p_hold_id    => G_KFF_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );
    END IF;

    IF G_HVOP_SCREDIT_PROCESSED(ln_batch_id) IS NULL THEN

        oe_debug_pub.add(' Creating Sales Credit  :'||ln_batch_id );
        Create_Sales_Credits(  p_batch_id      => ln_batch_id
                             , x_return_status => lc_return_status
                            );
        oe_debug_pub.add(' After Sales Credit  :'||ln_batch_id );
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            oe_debug_pub.add('Failed to create Sales Credits '||ln_batch_id);
            G_HVOP_SCREDIT_PROCESSED(ln_batch_id) := 'E';
        ELSE
            G_HVOP_SCREDIT_PROCESSED(ln_batch_id) := 'Y';
        END IF;
    END IF;

    -- Put the order on hold if the processing failed.

    IF G_HVOP_SCREDIT_PROCESSED(ln_batch_id) = 'E' THEN

          IF G_SCREDIT_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_SCREDIT_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: Sales Credit Processing Failure';
          END IF;

          Apply_Hold( p_header_id  => p_header_id
                    , p_hold_id    => G_SCREDIT_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );
    END IF;

    IF G_HVOP_PAYMENT_PROCESSED(ln_batch_id) IS NULL THEN
        oe_debug_pub.add(' Creating Payments  :'||ln_batch_id );
	Get_Payment_Data(
                          p_header_id => ln_header_id
                        , p_batch_id => ln_batch_id
                        , x_return_status => lc_return_status
                        );
        oe_debug_pub.add(' After Creating Payments  :'||ln_batch_id );
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                    oe_debug_pub.add('Failed to Get Payment Data '||ln_batch_id);
            G_HVOP_PAYMENT_PROCESSED(ln_batch_id) := 'E';
        ELSE
            G_HVOP_PAYMENT_PROCESSED(ln_batch_id) := 'Y';
        END IF;
    END IF;

    -- Put the order on hold if the processing failed.

    IF G_HVOP_PAYMENT_PROCESSED(ln_batch_id) = 'E' THEN

          IF G_PAYMENT_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_PAYMENT_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: Payment Processing Failure';
          END IF;

          Apply_Hold( p_header_id  => p_header_id
                    , p_hold_id    => G_PAYMENT_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );

    END IF;
    
    -- Update the Actual_Shipment_Date on all lines of the order
    Update_Actual_Shipment_Date( p_header_id => p_header_id);


EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Failed In Process_Bulk - In Others :'||ln_batch_id );

        -- Put the order on Generic hold
        IF G_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: SA Processing Failure';
        END IF;
        ln_msg_count := 1;
        lc_msg_data := 'Generic Processing Failure in XX_OM_SALES_ACCT_PKG.Process_Bulk';
        Apply_Hold( p_header_id  => ln_header_id
                    , p_hold_id    => G_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );

END PROCESS_BULK;

-- +===================================================================+
-- | Name  : PROCESS_NORMAL                                            |
-- | Description  : This Procedure will be used to process data in     |
-- |                SOI mode -> Orders being imported by SOI           |
-- |                                                                   |
-- | Parameters :  p_header_id    IN  -> Current Order in the workflow |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PROCESS_NORMAL(
  p_header_id   IN  NUMBER
  )
IS
ln_header_id		NUMBER;
ln_batch_id		NUMBER;
lc_return_status	        VARCHAR2(30) := 'S';
ln_msg_count		NUMBER;
lc_msg_data		VARCHAR2(2000);
lc_mode                  VARCHAR2(10);
lc_tax_failure_flag      VARCHAR2(1) ;
lc_KFF_failure_flag      VARCHAR2(1) ;
lc_scredit_failure_flag  VARCHAR2(1) ;
lc_payment_failure_flag  VARCHAR2(1) ;
BEGIN

    oe_debug_pub.add('XXCalling Create TAX Records :'||p_header_id);
    -- Need to happen for all Sales Accounting orders
    Create_Tax_Records(
                          p_header_id     => p_header_id
                        , p_mode          => 'NORMAL'
                        , p_batch_id      => NULL
                        , x_return_status => lc_return_status
                        );
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        oe_debug_pub.add('Failed to create Tax Records :'||ln_header_id);
        lc_tax_failure_flag := 'Y';

        IF G_TAX_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_TAX_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: Tax Processing Failure';
        END IF;

        Apply_Hold( p_header_id  => p_header_id
                  , p_hold_id    => G_TAX_PROCESSING_HOLD
                  , p_msg_count  => ln_msg_count
                  , p_msg_data   => lc_msg_data
                  , x_return_status => lc_return_status
                  );

    END IF;

    -- Need to happen for all Sales Accounting orders
    oe_debug_pub.add('XXCalling Create KFF Records :'||p_header_id);
    Get_KFF_DFF_Data(
                      p_header_id     => p_header_id
                    , p_mode          => 'NORMAL'
                    , p_batch_id      => NULL
                    , x_return_status => lc_return_status
                    );
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        oe_debug_pub.add('Failed to create DFF/KFF data :'||ln_header_id);
        IF G_KFF_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_KFF_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: KFF Data Processing Failure';
        END IF;

        Apply_Hold( p_header_id  => p_header_id
                  , p_hold_id    => G_KFF_PROCESSING_HOLD
                  , p_msg_count  => ln_msg_count
                  , p_msg_data   => lc_msg_data
                  , x_return_status => lc_return_status
                  );

    END IF;

    -- Need to get Return Tender Info from iface tables
    oe_debug_pub.add('XXCalling Create KFF Records :'||p_header_id);
    Get_Return_Tenders(
                      p_header_id     => p_header_id
                    , x_return_status => lc_return_status
                    );
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        oe_debug_pub.add('Failed to create DFF/KFF data :'||ln_header_id);
        IF G_RET_TENDERS_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_RET_TENDERS_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: Return Tender Data Failure';
        END IF;

        Apply_Hold( p_header_id  => p_header_id
                  , p_hold_id    => G_RET_TENDERS_HOLD
                  , p_msg_count  => ln_msg_count
                  , p_msg_data   => lc_msg_data
                  , x_return_status => lc_return_status
                  );

    END IF;
    -- Update the Actual_Shipment_Date on all lines of the order
    Update_Actual_Shipment_Date( p_header_id => p_header_id);

EXCEPTION
      WHEN OTHERS THEN
        oe_debug_pub.add('Failed In Process_Normal - In Others :'||ln_batch_id );
        -- Put the order on Generic hold
        IF G_PROCESSING_HOLD IS NULL THEN
              SELECT HOLD_ID
              INTO G_PROCESSING_HOLD
              FROM oe_hold_definitions
              WHERE NAME = 'OD: SA Processing Failure';
        END IF;
        ln_msg_count := 1;
        lc_msg_data := 'Generic Processing Failure in XX_OM_SALES_ACCT_PKG.Process_Normal';
        Apply_Hold( p_header_id  => ln_header_id
                    , p_hold_id    => G_PROCESSING_HOLD
                    , p_msg_count  => ln_msg_count
                    , p_msg_data   => lc_msg_data
                    , x_return_status => lc_return_status
                    );

END PROCESS_NORMAL;

-- +=====================================================================+
-- | Name  : PULL_DATA                                                   |
-- | Description  : This Procedure will be called by the custom workflow |
-- | activity that will be invoked for each order header.                |
-- |                                                                     |
-- | Parameters :  itemtype  IN  -> 'OEOH'                               |
-- |               itemtype  IN  -> header_id                            |
-- |               actid     IN  -> activity id                          |
-- |               funcmode  IN  -> workflow running mode                |
-- |               resultout OUT -> Activity Result                      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE Pull_Data(
    itemtype  in varchar2,
    itemkey   in varchar2,
    actid     in number,
    funcmode  in varchar2,
    resultout in out varchar2)
IS
ln_header_id		NUMBER;
ln_batch_id		NUMBER;
lc_return_status	VARCHAR2(30) := 'S';
ln_msg_count		NUMBER;
lc_msg_data		VARCHAR2(2000);
lc_mode                  VARCHAR2(10);
lc_tax_failure_flag      VARCHAR2(1) ;
lc_KFF_failure_flag      VARCHAR2(1) ;
lc_scredit_failure_flag  VARCHAR2(1) ;
lc_payment_failure_flag  VARCHAR2(1) ;
BEGIN

  --
  -- RUN mode - normal process execution
  --
  IF (funcmode = 'RUN') THEN

	OE_STANDARD_WF.Set_Msg_Context(actid);

	ln_header_id := to_number(itemkey);

        IF OE_BULK_WF_UTIL.G_HEADER_INDEX IS NULL THEN
           lc_mode := 'NORMAL';
           oe_debug_pub.add('Calling Process Normal');
           process_normal( p_header_id => ln_header_id );
        ELSE
           lc_mode := 'HVOP';
           process_bulk( p_header_id => ln_header_id );
        END IF;

      resultout := 'COMPLETE';
      OE_STANDARD_WF.Clear_Msg_Context;

  END IF; -- End for 'RUN' mode

  --
  -- CANCEL mode - activity 'compensation'
  --
  -- This is an event point is called with the effect of the activity must
  -- be undone, for example when a process is reset to an earlier point
  -- due to a loop back.
  --
  if (funcmode = 'CANCEL') then

    -- your cancel code goes here
    null;

    -- no result needed
    resultout := 'COMPLETE';
    return;
  end if;

exception
  when others then
    -- The line below records this function call in the error system
    -- in the case of an exception.
    wf_core.context('XX_OM_SALES_ACCT_PKG', 'Pull_Data',
                    itemtype, itemkey, to_char(actid), funcmode);
    -- start data fix project
    OE_STANDARD_WF.Add_Error_Activity_Msg(p_actid => actid,
                                          p_itemtype => itemtype,
                                          p_itemkey => itemkey);
    OE_STANDARD_WF.Save_Messages;
    OE_STANDARD_WF.Clear_Msg_Context;
    -- end data fix project
    raise;
END Pull_Data;

-- +=====================================================================+
-- | Name  : Get_Payment_Data                                            |
-- | Description  : This Procedure will look at interface data and will  |
-- | creat PAYMENT records in oe_payments table. This will be called only|
-- | in HVOP mode where payment import is not supported                  |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE Get_Payment_Data(
  p_header_id   IN  NUMBER
, p_batch_id    IN NUMBER
, x_return_status  OUT VARCHAR2)
IS

ln_request_id    NUMBER;
CURSOR C_PAYMENTS IS
    SELECT h.HEADER_ID
          ,i.PAYMENT_TYPE_CODE
          ,i.CREDIT_CARD_CODE
          ,i.CREDIT_CARD_NUMBER
          ,i.CREDIT_CARD_HOLDER_NAME
          ,i.CREDIT_CARD_EXPIRATION_DATE
          ,i.CREDIT_CARD_APPROVAL_CODE
          ,i.CREDIT_CARD_APPROVAL_DATE
          ,i.CHECK_NUMBER
          ,i.PREPAID_AMOUNT
          ,i.PAYMENT_AMOUNT
          ,i.ORIG_SYS_PAYMENT_REF
          ,i.PAYMENT_NUMBER
          ,i.RECEIPT_METHOD_ID
          ,h.TRANSACTIONAL_CURR_CODE
          ,h.SOLD_TO_ORG_ID
          ,h.INVOICE_TO_ORG_ID
          ,i.PAYMENT_SET_ID
          ,h.ORDER_NUMBER
     FROM oe_payments_interface i,
          oe_order_headers h,
          oe_payment_types_vl pt
     WHERE h.batch_id = p_Batch_Id
     AND h.orig_sys_document_ref = i.orig_sys_document_ref
     AND h.order_source_id = i.order_source_id
     AND i.payment_type_code = pt.payment_type_code
     ORDER BY h.header_id, i.PAYMENT_NUMBER;

lc_payment_rec   Payment_Rec_Type;
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
lc_return_status VARCHAR2(1);
ln_msg_count     NUMBER;
lc_msg_data      VARCHAR2(2000);
ln_cr_id         NUMBER;
ln_rec_appl_id   NUMBER;
ln_remittance_bank_account_id    NUMBER;
ln_payment_server_order_num      NUMBER;
ln_sec_application_ref_id  NUMBER;
lc_pay_response_error_code   VARCHAR2(80);
j  BINARY_INTEGER;
l_error_headers err_tbl_type;
l_success_header T_NUM;
lc_msg_text     VARCHAR2(10000);
ln_hold_id      NUMBER;
ln_app_ref_id   NUMBER;
lc_approval_code VARCHAR2(120);
lc_app_ref_num   VARCHAR2(80);

BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    ln_request_id := OE_Bulk_Order_PVT.G_REQUEST_ID;
    OPEN C_PAYMENTS;
    FETCH C_PAYMENTS BULK COLLECT INTO
           lc_payment_rec.HEADER_ID
          ,lc_payment_rec.PAYMENT_TYPE_CODE
          ,lc_payment_rec.CREDIT_CARD_CODE
          ,lc_payment_rec.CREDIT_CARD_NUMBER
          ,lc_payment_rec.CREDIT_CARD_HOLDER_NAME
          ,lc_payment_rec.CREDIT_CARD_EXPIRATION_DATE
          ,lc_payment_rec.CREDIT_CARD_APPROVAL_CODE
          ,lc_payment_rec.CREDIT_CARD_APPROVAL_DATE
          ,lc_payment_rec.CHECK_NUMBER
          ,lc_payment_rec.PREPAID_AMOUNT
          ,lc_payment_rec.PAYMENT_AMOUNT
          ,lc_payment_rec.ORIG_SYS_PAYMENT_REF
          ,lc_payment_rec.PAYMENT_NUMBER
          ,lc_payment_rec.RECEIPT_METHOD_ID
          ,lc_payment_rec.ORDER_CURR_CODE
          ,lc_payment_rec.SOLD_TO_ORG_ID
          ,lc_payment_rec.INVOICE_TO_ORG_ID
          ,lc_payment_rec.PAYMENT_SET_ID
          ,lc_payment_rec.ORDER_NUMBER;

    CLOSE C_PAYMENTS;

    IF lc_payment_rec.header_id.COUNT = 0 THEN
       -- No records created for Account Billing
       IF ln_debug_level  > 0 THEN
          oe_debug_pub.add('No Payment records found :' || p_batch_id);
       END IF;
       RETURN;
    END IF;

    -- For each of the payment record fetched we will need to create
    -- pre-payment record in AR.

    IF ln_debug_level  > 0 THEN
        oe_debug_pub.add('No of Payment record :' || lc_payment_rec.header_id.COUNT);
    END IF;
    j := 0;
    FOR i IN 1..lc_payment_rec.header_id.COUNT LOOP

        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add(  'Before calling AR Create_Prepayment: '||lc_payment_rec.header_id(i),3);
        END IF;
        lc_return_status := FND_API.G_RET_STS_SUCCESS;

        -- Set the Error Global
        IF NOT l_error_headers.EXISTS(lc_payment_rec.header_id(i)) THEN
            l_error_headers(lc_payment_rec.header_id(i)) := 'S';
        END IF;

        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add('The Error global is set to :'||l_error_headers(lc_payment_rec.header_id(i)));
        END IF;

        -- Check if the Payment record is a Deposit record.
        IF lc_payment_rec.payment_set_id(i) IS NOT NULL THEN
             Goto SKIP_RECEIPT;
        END IF;     
        
        -- Get the Remittance bank account id from cache
        ln_remittance_bank_account_id := Get_rem_bank_acct_id(
                                            lc_payment_rec.RECEIPT_METHOD_ID(i)
                                          , lc_payment_rec.ORDER_CURR_CODE(i));

        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add('Bank Acct Id :' || ln_remittance_bank_account_id);
        END IF;
        ln_msg_count := NULL;
        lc_msg_data := NULL;
        ln_app_ref_id := lc_payment_rec.header_id(i);
        lc_approval_code := lc_payment_rec.CREDIT_CARD_APPROVAL_CODE(i);
        lc_app_ref_num := lc_payment_rec.ORDER_NUMBER(i);

        BEGIN
        oe_debug_pub.add('BEfore calling create_prepayment ' );
            AR_PREPAYMENTS.create_prepayment(
            p_api_version               => 1.0,
            p_commit                    => FND_API.G_FALSE,
            p_validation_level          => FND_API.G_VALID_LEVEL_FULL,
            x_return_status             => lc_return_status,
            x_msg_count                 => ln_msg_count,
            x_msg_data                  => lc_msg_data,
            p_init_msg_list             => FND_API.G_TRUE,
       --   p_receipt_number            => l_receipt_number,
            p_amount                    => lc_payment_rec.PAYMENT_AMOUNT(i),
            p_receipt_method_id         => lc_payment_rec.RECEIPT_METHOD_ID(i),
            p_customer_id               => lc_payment_rec.SOLD_TO_ORG_ID(i),
            p_customer_site_use_id      => lc_payment_rec.INVOICE_TO_ORG_ID(i),
            p_customer_bank_account_id  => NULL,
            p_currency_code             => lc_payment_rec.ORDER_CURR_CODE(i),
            p_exchange_rate             => NULL,
            p_exchange_rate_type        => NULL,
            p_exchange_rate_date        => NULL,
            p_applied_payment_schedule_id => -7,  -- hard coded.
            p_application_ref_type      => 'OM' ,
            p_application_ref_num       => lc_app_ref_num,
            p_application_ref_id        => ln_app_ref_id,
            p_cr_id                     => ln_cr_id, --OUT
            p_receivable_application_id => ln_rec_appl_id, --OUT
            p_call_payment_processor    => FND_API.G_TRUE,
            p_remittance_bank_account_id => ln_remittance_bank_account_id,
            p_called_from               => 'OM',
            p_payment_server_order_num  => ln_payment_server_order_num,
            p_approval_code             => lc_approval_code,
            p_secondary_application_ref_id => ln_sec_application_ref_id,
            p_payment_response_error_code  => lc_pay_response_error_code,
            p_payment_set_id               => lc_payment_rec.PAYMENT_SET_ID(i)
            );
            IF ln_debug_level  > 0 THEN
              oe_debug_pub.add(  'AFTER AR CREATE_PREPAYMENT' ||lc_payment_rec.HEADER_ID(i), 1 ) ;
              oe_debug_pub.add(  'CASH_RECEIPT_ID IS: '||ln_cr_id , 1 ) ;
              oe_debug_pub.add(  'PAYMENT_SET_ID IS: '||lc_payment_rec.PAYMENT_SET_ID(i) , 1 ) ;
              oe_debug_pub.add(  'Payment_response_error_code IS: '||lc_pay_response_error_code , 1 ) ;
              oe_debug_pub.add(  'Approval_code IS: '||lc_payment_rec.CREDIT_CARD_APPROVAL_CODE(i) , 1 ) ;
              oe_debug_pub.add(  'STATUS IS: '||lc_return_status , 1 ) ;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            -- For Any Error, we will still need to create records in oe_payment table.
            -- So catch all raised exceptions and still create records.
            IF ln_debug_level  > 0 THEN
              oe_debug_pub.add('In Others for AR_PREPAYMENTS.create_prepayment ', 1 ) ;
            END IF;
            lc_return_status := FND_API.G_RET_STS_ERROR;
        END;
        -- For errors
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           IF ln_msg_count = 1 THEN
             IF ln_debug_level  > 0 THEN
                oe_debug_pub.add('Error message after calling Create_Prepayment API: '||lc_msg_data , 3 ) ;
             END IF;
             oe_msg_pub.add_text(p_message_text => lc_msg_data);
           ELSIF ( FND_MSG_PUB.Count_Msg > 0 ) THEN
             arp_util.enable_debug;
             FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
               lc_msg_text := FND_MSG_PUB.Get(i,'F');
               IF lc_msg_text IS NOT NULL THEN
                 IF ln_debug_level  > 0 THEN
                    oe_debug_pub.add(  lc_msg_text , 3 ) ;
                 END IF;
                 oe_msg_pub.add_text(p_message_text => lc_msg_text);
               END IF;
             END LOOP;
           END IF;

           -- Apply hold if it doesn't exist already.
           IF NOT NVL(l_error_headers(lc_payment_rec.header_id(i)),'Y') = 'E'
           THEN

              IF lc_pay_response_error_code IN ('IBY_0001', 'IBY_0008')  THEN
                 -- need to apply epayment server failure hold
                 IF ln_debug_level  > 0 THEN
                    oe_debug_pub.add(  'applying epayment server failure hold.',3);
                 END IF;
                 ln_hold_id := 15;
              ELSE
                 -- for any other payment_response_error_code,  apply epayment
                 -- failure hold (seeded hold id is 14).
                 IF ln_debug_level  > 0 THEN
                   oe_debug_pub.add(  'Applying epayment failure hold.',3);
                 END IF;
                 ln_hold_id := 14;

              END IF;  -- end of checking lc_pay_response_error_code.
              Apply_Hold( p_header_id     => lc_payment_rec.header_id(i)
                        , p_hold_id       => ln_hold_id
                        , p_msg_count     => ln_msg_count
                        , p_msg_data      => lc_msg_data
                        , x_return_status => lc_return_status
                        );
              IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                  x_return_status := FND_API.G_RET_STS_ERROR;
                  oe_debug_pub.add('Failed to apply epayment failure hold.'|| lc_payment_rec.header_id(i),3);
              END IF;

           END IF; -- Apply hold if it doesn't exist already
           -- Add Error Processing here.
           l_error_headers(lc_payment_rec.header_id(i)) := 'E';

        END IF; -- For errors

        <<SKIP_RECEIPT>>
        
        IF l_error_headers(lc_payment_rec.header_id(i)) <> 'E' THEN
              j := j + 1;
              l_success_header(j):= lc_payment_rec.header_id(i);
              IF ln_debug_level > 0 THEN
                 oe_debug_pub.add(' Deposit success record count ' || j);
              END IF;
        END IF;
    
    END LOOP;

    -- FOR ALL Orders with successful Pre-Payment records update Lines
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(' Success_header count is :' || l_success_header.COUNT );
    END IF;

    IF l_success_header.COUNT > 0 THEN
    BEGIN
        FORALL I IN l_success_header.FIRST..l_success_header.LAST
            UPDATE OE_ORDER_LINES
            SET INVOICE_INTERFACE_STATUS_CODE = 'PREPAID'
            WHERE header_id = l_success_header(I)
            AND NVL(INVOICE_INTERFACE_STATUS_CODE, 'N') <> 'PREPAID';
    EXCEPTION
        WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        oe_debug_pub.add('Failed to Update INVOICE_INTERFACE_STATUS_CODE '|| p_batch_id,3);
    END;
    END IF;

    -- Need to create payment records in oe_payments table from
    -- oe_payment_iface_all

    IF ln_debug_level > 0 THEN
       oe_debug_pub.add(' Creating Payment Records ');
    END IF;

    FORALL I IN 1..lc_payment_rec.header_id.COUNT
    INSERT INTO OE_PAYMENTS
        (
           PAYMENT_LEVEL_CODE
         , HEADER_ID
         , CREATION_DATE
         , CREATED_BY
         , LAST_UPDATE_DATE
         , LAST_UPDATED_BY
         , REQUEST_ID
         , PAYMENT_TYPE_CODE
         , CREDIT_CARD_CODE
         , CREDIT_CARD_NUMBER
         , CREDIT_CARD_HOLDER_NAME
         , CREDIT_CARD_EXPIRATION_DATE
         , PREPAID_AMOUNT
         , PAYMENT_SET_ID
         , RECEIPT_METHOD_ID
         , PAYMENT_COLLECTION_EVENT
         , CREDIT_CARD_APPROVAL_CODE
         , CREDIT_CARD_APPROVAL_DATE
         , CHECK_NUMBER
         , PAYMENT_AMOUNT
         , PAYMENT_NUMBER
         , LOCK_CONTROL
         , ORIG_SYS_PAYMENT_REF
        )
    VALUES
        (
          'ORDER'
         ,lc_payment_rec.header_id(i)
         ,SYSDATE
         ,FND_GLOBAL.USER_ID
         ,SYSDATE
         ,FND_GLOBAL.USER_ID
         ,ln_request_id
         ,lc_payment_rec.payment_type_code(i)
         ,lc_payment_rec.CREDIT_CARD_CODE(i)
         ,lc_payment_rec.CREDIT_CARD_NUMBER(i)
         ,lc_payment_rec.CREDIT_CARD_HOLDER_NAME(i)
         ,lc_payment_rec.CREDIT_CARD_EXPIRATION_DATE(i)
         ,lc_payment_rec.PAYMENT_AMOUNT(i)
         ,lc_payment_rec.PAYMENT_SET_ID(i)
         ,lc_payment_rec.RECEIPT_METHOD_ID(i)
         ,'PREPAY'
         ,lc_payment_rec.CREDIT_CARD_APPROVAL_CODE(i)
         ,lc_payment_rec.CREDIT_CARD_APPROVAL_DATE(i)
         ,lc_payment_rec.CHECK_NUMBER(i)
         ,lc_payment_rec.PAYMENT_AMOUNT(i)
         ,lc_payment_rec.PAYMENT_NUMBER(i)
         ,1
         ,lc_payment_rec.ORIG_SYS_PAYMENT_REF(i)
        );
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(' After Creating Payment Records ');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
    IF ln_debug_level  > 0 THEN
        oe_debug_pub.add(  'OTHERS ERROR , Get_Payment_Data' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
    END IF;
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    OE_BULK_MSG_PUB.Add_Exc_Msg
       (   G_PKG_NAME
        ,   'Get_Payment_Data'
        );

END Get_Payment_Data;

-- +=====================================================================+
-- | Name  : Get_rem_bank_acct_id                                        |
-- | Description  : This function will return bank account id for a given|
-- | receipt method id.                                                  |
-- |                                                                     |
-- | Parameters :  p_receipt_method_id  IN                               |
-- |               p_curr_code     IN  -> currency code for the order    |
-- |                                                                     |
-- | Return     :  bank_account_id                                       |
-- +=====================================================================+

FUNCTION Get_rem_bank_acct_id
(p_receipt_method_id    IN     NUMBER
, p_curr_code           IN     VARCHAR2
) RETURN NUMBER
IS
lc_key  VARCHAR2(50);
BEGIN
    lc_key := p_curr_code ||'-'||p_receipt_method_id;
    IF G_Bank_Account_Id(lc_key) IS NULL THEN

        SELECT ba.bank_account_id
        INTO G_Bank_Account_Id(lc_key)
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
                                    ,p_curr_code)
        and    rma.primary_flag = 'Y';
    END IF;
    return G_Bank_Account_Id(lc_key);
EXCEPTION
    WHEN OTHERS THEN
        Return NULL;
END Get_rem_bank_acct_id;

-- +=====================================================================+
-- | Name  : Apply_Hold                                                  |
-- | Description  : This procedure will be used to put the order on hold |
-- | if it fails in any of the DATA_PULL processing                      |
-- |                                                                     |
-- | Parameters :  p_header_id   IN                                      |
-- |               p_hold_id     IN  -> Hold Id of the hold tobe used    |
-- |               p_msg_count   IN  -> message count                    |
-- |               p_msg_data    IN  -> Any messages added before        |
-- |               x_return_status OUT  -> Return status                 |
-- |                                       'S' -> success                |
-- |                                       'E' -> expected error         | 
-- |                                       'U' -> Unexpected error       |
-- +=====================================================================+

PROCEDURE Apply_Hold
(   p_header_id       IN   NUMBER
,   p_hold_id         IN   NUMBER
,   p_msg_count       IN OUT  NOCOPY NUMBER
,   p_msg_data	      IN OUT  NOCOPY VARCHAR2
,   x_return_status   OUT  NOCOPY VARCHAR2
)
IS

lc_hold_exists     VARCHAR2(1) := 'N';
ln_msg_count       NUMBER := 0;
lc_msg_data        VARCHAR2(2000);
lc_return_status   VARCHAR2(30);

l_hold_source_rec   OE_Holds_PVT.Hold_Source_REC_type;

--
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF ln_debug_level  > 0 THEN
      oe_debug_pub.add(  'XXOMSACTB: IN APPLY PREPAYMENT HOLDS',3);
      oe_debug_pub.add(  'HEADER ID : '||P_HEADER_ID,3);
  END IF;


  -- Apply Prepayment Hold on Header
  IF ln_debug_level  > 0 THEN
      oe_debug_pub.add(  'XXOMSACTB: APPLYING HOLD ON HEADER ID : '||P_HEADER_ID,3);
  END IF;

  l_hold_source_rec.hold_id         := p_hold_id ;  -- Requested Hold
  l_hold_source_rec.hold_entity_code:= 'O';         -- Order Hold
  l_hold_source_rec.hold_entity_id  := p_header_id; -- Order Header
  l_hold_source_rec.hold_comment := SUBSTR(p_msg_data,1,2000);


  OE_Holds_PUB.Apply_Holds
                (   p_api_version       =>      1.0
                ,   p_validation_level  =>      FND_API.G_VALID_LEVEL_NONE
                ,   p_hold_source_rec   =>      l_hold_source_rec
                ,   x_msg_count         =>      ln_msg_count
                ,   x_msg_data          =>      lc_msg_data
                ,   x_return_status     =>      lc_return_status
                );

  IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
    IF p_hold_id = 14 THEN
      FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_FAILURE_HOLD');
      OE_MSG_PUB.ADD;
      IF ln_debug_level  > 0 THEN
        oe_debug_pub.add(  'XXOMSACTB: payment failure hold has been applied on order.', 3 ) ;
      END IF;
    ELSIF p_hold_id = 15 THEN
      FND_MESSAGE.SET_NAME('ONT','ONT_PAYMENT_SERVER_FAIL_HOLD');
      OE_MSG_PUB.ADD;
      IF ln_debug_level  > 0 THEN
        oe_debug_pub.add(  'XXOMSACTB: payment server failure hold has been applied on order.', 3 ) ;
      END IF;
    ELSE
      FND_MESSAGE.SET_NAME('XXOM','XXOM_SA_PROCESSING_HOLD_APPLIED');
      OE_MSG_PUB.ADD;
      IF ln_debug_level  > 0 THEN
        oe_debug_pub.add('OD Sales Accounting Processing Hold Applied.', 3 ) ;
      END IF;
    END IF;

  ELSIF lc_return_status = FND_API.G_RET_STS_ERROR THEN
    RAISE FND_API.G_EXC_ERROR;
  ELSIF lc_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  IF ln_debug_level  > 0 THEN
      oe_debug_pub.add(  'XXOMSACTB: APPLIED PREPAYMENT HOLD ON HEADER ID:' || P_HEADER_ID , 3 ) ;
  END IF;

  EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => ln_msg_count,
              p_data  => lc_msg_data
            );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      OE_MSG_PUB.Count_And_Get
            ( p_count => ln_msg_count,
              p_data  => lc_msg_data
            );

    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
      THEN
        FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Apply_Hold'
            );
      END IF;

      OE_MSG_PUB.Count_And_Get
            ( p_count => ln_msg_count,
              p_data  => lc_msg_data
            );

END Apply_Hold;

-- +=====================================================================+
-- | Name  : Create_Sales_Credits                                        |
-- | Description  : May not be needed...                                 |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE  Create_Sales_Credits
( p_header_id   IN NUMBER
, p_batch_id    IN NUMBER
, x_return_status  OUT VARCHAR2)
IS
l_scredit_rec  Scredit_Rec_Type;
l_new_scredit_rec Scredit_Rec_Type;
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

CURSOR C_SALESREP IS
    SELECT H.SALESREP_ID,
           H.HEADER_ID,
           A.PARTY_ID,
           CA.PARTY_SITE_ID,
           'N'
    FROM OE_ORDER_HEADERS_ALL H,
         HZ_CUST_ACCOUNTS A,
         HZ_CUST_SITE_USES_ALL S,
         HZ_CUST_ACCT_SITES_ALL CA
    WHERE H.BATCH_ID = p_batch_id
    AND H.SALESREP_ID <> -3
    AND H.sold_to_org_id = A.CUST_ACCOUNT_ID
    AND H.SHIP_TO_ORG_ID = S.SITE_USE_ID
    AND S.CUST_ACCT_SITE_ID = CA.CUST_ACCT_SITE_ID
    ORDER BY H.HEADER_ID;

l_trans_rec_type       jtf_terr_lookup_pub.trans_rec_type;
lc_return_status        varchar2(10);
ln_msg_count            number;
lc_msg_data             varchar2(255);
l_winners_tbl          jtf_terr_lookup_pub.winners_tbl_type;
ln_salesrep_id          number;
ln_org_id               number := to_number(FND_PROFILE.VALUE('ORG_ID'));
j                      binary_integer;

BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    oe_debug_pub.add('Entering Sales Credit Processing '||p_batch_id);

    -- Check if a Valid Sales Rep exists for the orders.
    OPEN C_SALESREP;
    FETCH C_SALESREP BULK COLLECT INTO
             l_scredit_rec.salesrep_id,
             l_scredit_rec.header_id,
             l_scredit_rec.party_id,
             l_scredit_rec.party_site_id,
             l_scredit_rec.match_flag;
    CLOSE C_SALESREP;

    -- If no orders with valid salesrep then skip
    IF l_scredit_rec.header_id.COUNT = 0 Then
        oe_debug_pub.add('No Sales Credit to process '||p_batch_id);
        RETURN;
    END IF;

    IF G_Sales_Credit_Type_Id IS NULL THEN
        BEGIN
            SELECT SALES_CREDIT_TYPE_ID
            INTO G_Sales_Credit_Type_Id
            FROM OE_SALES_CREDIT_TYPES
            WHERE NAME = 'Non-quota Sales Credit';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            G_Sales_Credit_Type_Id := NULL;
        END;

    END IF;

    -- Call the JTF_TERR_LOOKUP_PUB.Get_Winners API to get the salesreps.

    j := 0; -- Counter for l_new_scredit_rec

    FOR i IN 1..l_scredit_rec.header_id.COUNT LOOP
        -- This 'use_type will provide more resource details in l_winners_tbl
        -- Other valid values
        -- 'LOOKUP' gives basic territory and resource details
        -- 'TERRITORY' gives more details of the territory definition
        l_trans_rec_type.use_type := 'RESOURCE';



        -- This is the transactional data you should provide from each order/line.
        l_trans_rec_type.SQUAL_NUM01 := l_scredit_rec.party_id(i);
        l_trans_rec_type.SQUAL_NUM02 := l_scredit_rec.party_site_id(i);


        -- For sales and telesales/account set these two values for
        -- p_source_id = -1001 and p_trans_id = -1002
        -- We should be focusing on Sales and Telesales for Accounts
        -- in the context of HVOP
        oe_debug_pub.add('Calling Get Winners ');
        oe_debug_pub.add('Party_id '||l_scredit_rec.party_id(i));
        oe_debug_pub.add('Party Site Id '||l_scredit_rec.party_site_id(i));

        JTF_TERR_LOOKUP_PUB.Get_Winners
        (   p_api_version_number       => 1.0,
            p_init_msg_list            => fnd_api.g_false,
            p_trans_rec                => l_trans_rec_type,
            p_source_id                => -1001,
            p_trans_id                 => -1002,
            p_Resource_Type            => FND_API.G_MISS_CHAR,
            p_Role                     => FND_API.G_MISS_CHAR,
            x_return_status            => lc_return_status,
            x_msg_count                => ln_msg_count,
            x_msg_data                 => lc_msg_data,
            x_winners_tbl              => l_winners_tbl
        );

        IF ln_debug_level > 0 Then
           oe_debug_pub.add('For header_id : ' || l_scredit_rec.header_id(i));
           oe_debug_pub.add('No of salesreps returned by Get_Winners : ' || l_winners_tbl.count);
        END IF;

        -- If no winners found then set the match_flag on l_scredit_rec
        IF l_winners_tbl.count = 0 THEN
            oe_debug_pub.add('Setting the match flag for index :' ||i);
            l_scredit_rec.match_flag(i) := 'Y';
        END IF;

        FOR i in 1..l_winners_tbl.count LOOP
           IF ln_debug_level > 0 Then
           oe_debug_pub.add(' Get_Winners Result ' || l_winners_tbl(i).resource_name);
           END IF;

           ln_salesrep_id := NULL;

           SELECT salesrep_id
           INTO ln_salesrep_id
           FROM jtf_rs_salesreps jrs
           WHERE jrs.resource_id = l_winners_tbl(i).resource_id
           AND org_id = ln_org_id
           AND rownum = 1;

           IF ln_debug_level > 0 Then
             oe_debug_pub.add(' Winner Salesrep id is ' || ln_salesrep_id);
           END IF;

           IF l_scredit_rec.salesrep_id(i) <> ln_salesrep_id THEN
             oe_debug_pub.add(' Winner Salesrep id Is New');
               j := j + 1;
               l_new_scredit_rec.salesrep_id(j) := ln_salesrep_id;
               l_new_scredit_rec.header_id(j) := l_scredit_rec.header_id(i);
           ELSE
             oe_debug_pub.add(' Winner Salesrep id Matches the one on header');
               l_scredit_rec.match_flag(i) := 'Y';
           END IF;
        END LOOP;

    END LOOP;

    -- Delete the records for which no match was found
        oe_debug_pub.add('Deleting sales credit records for not found');
    FORALL I IN 1..l_scredit_rec.salesrep_id.COUNT
        DELETE FROM  OE_SALES_CREDITS
        WHERE header_id = l_scredit_rec.header_id(i)
        AND salesrep_id = l_scredit_rec.salesrep_id(i)
        AND l_scredit_rec.match_flag(i) = 'N';

    -- If the API returns the same Salesrep as the one on order or returns
    -- none then no need to create new sales credit records.
    -- Update the records for non-quote sales credit type.

    oe_debug_pub.add(' Updating sales credit type ');
    FORALL I IN 1..l_scredit_rec.salesrep_id.COUNT
        UPDATE OE_SALES_CREDITS
        SET SALES_CREDIT_TYPE_ID = G_Sales_Credit_Type_Id
        WHERE header_id = l_scredit_rec.header_id(i)
        AND salesrep_id = l_scredit_rec.salesrep_id(i)
        AND l_scredit_rec.match_flag(i) = 'Y';

    IF l_new_scredit_rec.salesrep_id.COUNT > 0 THEN
        -- Create new entries for the extra SalesReps..
        oe_debug_pub.add('Creating new sales credit records for New');
        FORALL I IN 1..l_new_scredit_rec.salesrep_id.COUNT
        INSERT INTO OE_SALES_CREDITS(
          SALES_CREDIT_ID
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , HEADER_ID
        , SALESREP_ID
        , PERCENT
        , SALES_CREDIT_TYPE_ID
        , SALES_GROUP_ID
        , LOCK_CONTROL
        )
        VALUES
        (
          OE_SALES_CREDITS_S.NEXTVAL
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , l_scredit_rec.header_id(i)
        , l_scredit_rec.salesrep_id(i)
        , 100
        , G_Sales_Credit_Type_Id
        , -1
        , 1
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        oe_debug_pub.add(  'OTHERS ERROR , Create_Sales_Credits' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
END Create_Sales_Credits;

-- +=====================================================================+
-- | Name  : Get_KFF_DFF_Data                                            |
-- | Description  : This Procedure will look at interface data and will  |
-- | creat KFF-DFF records in KFF tables. This can get called in SOI or  |
-- | in HVOP mode.                                                       |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_mode       IN  -> BULK or NORMAL
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE  Get_KFF_DFF_Data
(   p_header_id IN NUMBER
,   p_mode      IN VARCHAR2
,   p_batch_id  IN NUMBER
,   x_return_status OUT VARCHAR2
)
IS
BEGIN
    -- Check if the mode is BULK..
    IF G_HEADER_ATTR6 IS NULL THEN
        SELECT ID_FLEX_NUM
        INTO G_HEADER_ATTR6
        FROM FND_ID_FLEX_STRUCTURES
        WHERE ID_FLEX_STRUCTURE_CODE = 'XX_OM_HEADER_ATTRIBUTE6'
        AND ID_FLEX_CODE = 'XXOH';
    END IF;

    IF G_HEADER_ATTR7 IS NULL THEN
        SELECT ID_FLEX_NUM
        INTO G_HEADER_ATTR7
        FROM FND_ID_FLEX_STRUCTURES
        WHERE ID_FLEX_STRUCTURE_CODE = 'XX_OM_HEADER_ATTRIBUTE7'
        AND ID_FLEX_CODE = 'XXOH';
    END IF;

    IF G_LINE_ATTR6 IS NULL THEN
        SELECT ID_FLEX_NUM
        INTO G_LINE_ATTR6
        FROM FND_ID_FLEX_STRUCTURES
        WHERE ID_FLEX_STRUCTURE_CODE = 'XX_OM_LINE_ATTRIBUTE6'
        AND ID_FLEX_CODE = 'XXOL';
    END IF;

    IF G_LINE_ATTR7 IS NULL THEN
        SELECT ID_FLEX_NUM
        INTO G_LINE_ATTR7
        FROM FND_ID_FLEX_STRUCTURES
        WHERE ID_FLEX_STRUCTURE_CODE = 'XX_OM_LINE_ATTRIBUTE7'
        AND ID_FLEX_CODE = 'XXOL';
    END IF;


    IF p_mode = 'NORMAL' THEN

        oe_debug_pub.add('KFF INsert1') ;
        -- This is SOI mode. Which means process one record at a time.
        -- Get Line KFF data first
        INSERT INTO XX_OM_LINES_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT21
        , SEGMENT22
        , SEGMENT3
        , SEGMENT1
        , SEGMENT27
        , SEGMENT31
        , SEGMENT32
        , SEGMENT34
        , SEGMENT33
        , SEGMENT35
        , SEGMENT38
        , SEGMENT23
        , SEGMENT40
        , SEGMENT26
        , SEGMENT25
        , SEGMENT39
        , SEGMENT37
        )
        SELECT
        LI.attribute6
        , G_LINE_ATTR6
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , Vendor_product_code
        , I.contract_details
        , I.item_comments
        , I.line_comments
        , I.taxable_flag
        , I.sku_dept
        , I.item_source
        , I.canada_pst
        , I.Average_cost
        , I.PO_cost
        , I.Return_Act_Cat_Code
        , I.Return_Reference_No
        , I.Return_ref_Line_No
        , I.Back_Ordered_Qty
        , I.Org_Order_Creation_Date
        , I.legacy_List_Price
        , I.Whole_seller_item
        FROM XX_OM_LINES_ATTR_IFACE_ALL I,
             OE_ORDER_LINES_ALL LI
        WHERE LI.header_id = p_header_id
        AND I.orig_sys_document_ref = LI.ORIG_SYS_DOCUMENT_REF
        AND I.orig_sys_line_ref = LI.ORIG_SYS_LINE_REF
        AND I.order_source_id = LI.order_source_id;

        oe_debug_pub.add('KFF INsert2') ;
        -- Get Attribute 7 Data
        /* Not needed any more as not using attribute 7 */
        /*
        INSERT INTO XX_OM_LINES_ATTRIBUTES_ALL
        ( COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT21
        )
        SELECT
        LI.attribute7
        , G_LINE_ATTR7
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , vendor_site_id
        FROM XX_OM_LINES_ATTR_IFACE_ALL I,
             OE_ORDER_LINES_ALL LI
        WHERE LI.header_id = p_header_id
        AND I.orig_sys_document_ref = LI.ORIG_SYS_DOCUMENT_REF
        AND I.orig_sys_line_ref = LI.ORIG_SYS_LINE_REF
        AND I.order_source_id = LI.order_source_id;
        */
        -- Get Header KFF data

        oe_debug_pub.add('KFF INsert3') ;
        -- Get Attribute 6 Data
        INSERT INTO XX_OM_HEADERS_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT13
        , SEGMENT12
        , SEGMENT14
        , SEGMENT15
        , SEGMENT17
        , SEGMENT21
        , SEGMENT8
        , SEGMENT7
        , SEGMENT3
        , SEGMENT2
        , SEGMENT4
        )
        SELECT
          H.attribute6
        , G_HEADER_ATTR6
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , Created_by_store_id
        , paid_at_store_id
        , SPC_Card_Number
        , Placement_Method_code
        , delivery_code
        , delivery_method
        , advantage_card_number
        , created_by_id
        , release_no
        , cust_dept_no
        , desk_top_no
        FROM XX_OM_HEADERS_ATTR_IFACE_ALL I,
             OE_ORDER_HEADERS_ALL H
        WHERE H.header_id = p_header_id
        AND I.orig_sys_document_ref = H.ORIG_SYS_DOCUMENT_REF
        AND I.order_source_id = H.order_source_id;

        oe_debug_pub.add('KFF INsert4') ;
        -- Get Attribute 7 Data
        INSERT INTO XX_OM_HEADERS_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT1
        )
        SELECT
          H.attribute7
        , G_HEADER_ATTR7
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , comments
        FROM XX_OM_HEADERS_ATTR_IFACE_ALL I,
             OE_ORDER_HEADERS_ALL H
        WHERE H.header_id = p_header_id
        AND I.orig_sys_document_ref = H.ORIG_SYS_DOCUMENT_REF
        AND I.order_source_id = H.order_source_id;

    ELSE
        -- This is BULK Mode and we can insert data for all of the batch
        oe_debug_pub.add('KFF INsert1') ;

        -- Get Line KFF data first
        INSERT INTO XX_OM_LINES_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT21
        , SEGMENT22
        , SEGMENT3
        , SEGMENT1
        , SEGMENT27
        , SEGMENT31
        , SEGMENT32
        , SEGMENT34
        , SEGMENT33
        , SEGMENT35
        , SEGMENT38
        , SEGMENT23
        , SEGMENT40
        , SEGMENT26
        , SEGMENT25
        , SEGMENT39
        , SEGMENT37
        )
        SELECT
          LI.attribute6
        , G_LINE_ATTR6
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , Vendor_product_code
        , contract_details
        , item_comments
        , line_comments
        , taxable_flag
        , sku_dept
        , item_source
        , canada_pst
        , Average_cost
        , PO_cost
        , Return_Act_Cat_Code
        , Return_Reference_No
        , Return_ref_Line_No
        , Back_Ordered_Qty
        , Org_Order_Creation_Date
        , Legacy_List_Price
        , Whole_seller_item
        FROM XX_OM_LINES_ATTR_IFACE_ALL I,
             OE_ORDER_LINES_ALL LI,
             OE_ORDER_HEADERS_ALL H
        WHERE H.batch_id = p_batch_id
        AND I.orig_sys_document_ref = LI.ORIG_SYS_DOCUMENT_REF
        AND I.orig_sys_line_ref = LI.ORIG_SYS_LINE_REF
        AND I.order_source_id = LI.order_source_id
        AND H.header_id = LI.header_id;

        oe_debug_pub.add('KFF INsert2') ;
        -- Get Attribute 7 Data
        /* Not needed any more as not using attribute 7 */
        /*
        INSERT INTO XX_OM_LINES_ATTRIBUTES_ALL
        ( COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT21
        )
        SELECT
          LI.attribute7
        , G_LINE_ATTR7
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , vendor_site_id
        FROM XX_OM_LINES_ATTR_IFACE_ALL I,
             OE_ORDER_LINES_ALL LI,
             OE_ORDER_HEADERS_ALL H
        WHERE H.batch_id = p_batch_id
        AND I.orig_sys_document_ref = LI.ORIG_SYS_DOCUMENT_REF
        AND I.orig_sys_line_ref = LI.ORIG_SYS_LINE_REF
        AND I.order_source_id = LI.order_source_id
        AND H.header_id = LI.header_id;
        */
        -- Get Header KFF data

        oe_debug_pub.add('KFF INsert3') ;
        -- Get Attribute 6 Data
        INSERT INTO XX_OM_HEADERS_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT13
        , SEGMENT12
        , SEGMENT14
        , SEGMENT15
        , SEGMENT17
        , SEGMENT21
        , SEGMENT8
        , SEGMENT7
        , SEGMENT3
        , SEGMENT2
        , SEGMENT4
        )
        SELECT
          H.attribute6
        , G_HEADER_ATTR6
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , Created_by_store_id
        , paid_at_store_id
        , SPC_Card_Number
        , Placement_Method_code
        , delivery_code
        , delivery_method
        , advantage_card_number
        , created_by_id
        , release_no
        , cust_dept_no
        , desk_top_no
        FROM XX_OM_HEADERS_ATTR_IFACE_ALL I,
             OE_ORDER_HEADERS_ALL H
        WHERE H.batch_id = p_batch_id
        AND I.orig_sys_document_ref = H.ORIG_SYS_DOCUMENT_REF
        AND I.order_source_id = H.order_source_id;

        oe_debug_pub.add('KFF INsert4') ;
        -- Get Attribute 7 Data
        INSERT INTO XX_OM_HEADERS_ATTRIBUTES_ALL(
          COMBINATION_ID
        , STRUCTURE_ID
        , ENABLED_FLAG
        , SUMMARY_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , SEGMENT1
        )
        SELECT
          H.attribute7
        , G_HEADER_ATTR7
        , 'Y'
        , 'Y'
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , comments
        FROM XX_OM_HEADERS_ATTR_IFACE_ALL I,
             OE_ORDER_HEADERS_ALL H
        WHERE H.batch_id = p_batch_id
        AND I.orig_sys_document_ref = H.ORIG_SYS_DOCUMENT_REF
        AND I.order_source_id = H.order_source_id;

    END iF;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        oe_debug_pub.add(  'OTHERS ERROR , Get_KFF_DFF_Data' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;

END Get_KFF_DFF_Data;

-- +=====================================================================+
-- | Name  : Create_Tax_Records                                          |
-- | Description  : This Procedure will look at interface data and will  |
-- | create TAX records in oe_price_adjustments table. This can get called|
-- | in SOI or in HVOP mode.                                             |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_mode       IN  -> BULK or NORMAL
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE  Create_Tax_Records
(   p_header_id IN NUMBER
,   p_mode      IN VARCHAR2
,   p_batch_id  IN NUMBER
,   x_return_status OUT VARCHAR2
)
IS
BEGIN
     -- Check if the mode is BULK..
    IF p_mode = 'NORMAL' THEN
        -- For non-bulk mode create TAX record for the current order
        oe_debug_pub.add('Inside Create_Tax_Records for '||p_header_id);

	    INSERT INTO OE_PRICE_ADJUSTMENTS
	    (  PRICE_ADJUSTMENT_ID
	     , CREATION_DATE
	     , CREATED_BY
	     , LAST_UPDATE_DATE
	     , LAST_UPDATED_BY
	     , HEADER_ID
	     , LINE_ID
	     , AUTOMATIC_FLAG
	     , LIST_LINE_TYPE_CODE
	     , OPERAND
	     , ARITHMETIC_OPERATOR
	     , TAX_CODE
	     , ADJUSTED_AMOUNT
	    )
	    SELECT OE_PRICE_ADJUSTMENTS_S.NEXTVAL
	     , SYSDATE
	     , FND_GLOBAL.USER_ID
	     , SYSDATE
	     , FND_GLOBAL.USER_ID
	     , L.HEADER_ID
	     , L.LINE_ID
	     , 'Y'
	     , 'TAX'
	     , L.TAX_RATE
	     , 'AMT'
	     , I.TAX_CODE
	     , I.TAX_VALUE
	    FROM OE_ORDER_LINES_ALL L,
                 OE_LINES_IFACE_ALL I
	    WHERE L.header_id = p_header_id
	    AND   L.line_number = 1
            AND   L.shipment_number = 1
            AND   L.orig_sys_document_ref = I.orig_sys_document_ref
            AND   L.orig_sys_line_ref = I.orig_sys_line_ref
            AND   L.order_source_id = I.order_source_id;

            -- Update the TAX Value For First Line Of the Order.
            UPDATE OE_ORDER_LINES_ALL L
            SET tax_value = (select ADJUSTED_AMOUNT
                             from oe_price_adjustments adj
                             WHERE L.line_id = adj.line_id
                             AND L.header_id = adj.header_id
                             AND adj.list_line_type_code = 'TAX'
                             AND ROWNUM = 1)
            WHERE header_id = p_header_id
            AND   L.line_number = 1
            AND   L.shipment_number = 1;


    ELSE
            -- For bulk mode create TAX records for all orders in the batch

	    INSERT INTO OE_PRICE_ADJUSTMENTS
	    (  PRICE_ADJUSTMENT_ID
	     , CREATION_DATE
	     , CREATED_BY
	     , LAST_UPDATE_DATE
	     , LAST_UPDATED_BY
	     , HEADER_ID
	     , LINE_ID
	     , AUTOMATIC_FLAG
	     , LIST_LINE_TYPE_CODE
	     , OPERAND
	     , ARITHMETIC_OPERATOR
	     , TAX_CODE
	     , ADJUSTED_AMOUNT
	    )
	    SELECT OE_PRICE_ADJUSTMENTS_S.NEXTVAL
	     , SYSDATE
	     , FND_GLOBAL.USER_ID
	     , SYSDATE
	     , FND_GLOBAL.USER_ID
	     , L.HEADER_ID
	     , L.LINE_ID
	     , 'Y'
	     , 'TAX'
	     , L.TAX_RATE
	     , 'AMT'
	     , L.TAX_CODE
	     , L.TAX_VALUE
	    FROM OE_ORDER_HEADERS_ALL H,
		 OE_ORDER_LINES_ALL L
	    WHERE H.header_id = L.header_id
	    AND   H.batch_id =  p_batch_id
	    AND   L.line_number = 1
            AND   L.shipment_number = 1;

    END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        oe_debug_pub.add(  'OTHERS ERROR , Create_Tax_Records' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
END Create_Tax_Records;

-- +=====================================================================+
-- | Name  : Create_Sales_Credits                                        |
-- | Description  : This Procedure will look at interface data and will  |
-- | create sales credit records in oe_sales_credits table. It will only  |
-- | get called in HVOP mode                                             |
-- |                                                                     |
-- | Parameters :  p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE  Create_Sales_Credits
( p_batch_id    IN NUMBER
, x_return_status  OUT VARCHAR2)
IS
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
lc_return_status        varchar2(10);
ln_msg_count            number;
lc_msg_data             varchar2(255);
ln_salesrep_id          number;

BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    INSERT INTO OE_SALES_CREDITS(
          SALES_CREDIT_ID
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , HEADER_ID
        , SALESREP_ID
        , PERCENT
        , SALES_CREDIT_TYPE_ID
        , LOCK_CONTROL
        )
    SELECT
          OE_SALES_CREDITS_S.NEXTVAL
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , h.header_id
        , i.salesrep_id
        , 100
        , i.Sales_Credit_Type_Id
        , 1
     FROM oe_credits_iface_all i,
          oe_order_headers_all h
     WHERE i.orig_sys_document_ref = h.orig_sys_document_ref
     AND   i.order_source_id = h.order_source_id
     AND   i.sold_to_org_id = h.sold_to_org_id
     AND   h.batch_id = p_batch_id
     AND   NOT EXISTS (select SALES_CREDIT_ID
                       FROM oe_sales_credits s
                       WHERE s.header_id = h.header_id
                       AND s.salesrep_id = i.salesrep_id);

EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        oe_debug_pub.add(  'OTHERS ERROR , Create_Sales_Credits' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
END Create_Sales_Credits;

-- +=========================================================================+
-- | Name  : Get_Return_Tenders                                              |
-- | Description  : This Procedure will look at interface data and will      |
-- | create return tender records in XX_OM_RETURN_TENDERS_ALL table. It will |
-- | only get called in NORMAL mode                                          |
-- |                                                                         |
-- | Parameters :  p_batch_id   IN  -> batch_id of the current HVOP batch    |
-- |               x_return_status OUT -> Return Result 'S','E','U'          |
-- |                                                                         |
-- |                                                                         |
-- +=========================================================================+

PROCEDURE  Get_Return_Tenders
(   p_header_id     IN NUMBER
,   x_return_status OUT VARCHAR2
)
IS
BEGIN
    INSERT INTO XX_OM_RETURN_TENDERS_ALL
    (
       Orig_sys_document_ref
     , Orig_sys_payment_ref
     , Request_Id
     , Header_id
     , Payment_Number
     , PAYMENT_TYPE_CODE
     , CREDIT_CARD_CODE
     , CREDIT_CARD_NUMBER
     , CREDIT_CARD_HOLDER_NAME
     , CREDIT_CARD_EXPIRATION_DATE
     , CREDIT_AMOUNT
     , CREATION_DATE
     , CREATED_BY
     , LAST_UPDATE_DATE
     , LAST_UPDATED_BY
     , ORG_ID
     , CC_AUTH_MANUAL
     , MERCHANT_NUMBER 
     , CC_AUTH_PS2000 
     , ALLIED_IND
     , RECEIPT_METHOD_ID  
    )
    SELECT
       h.Orig_sys_document_ref
     , i.Orig_sys_payment_ref
     , h.Request_Id
     , h.Header_id
     , i.Payment_Number
     , i.PAYMENT_TYPE_CODE
     , i.CREDIT_CARD_CODE
     , i.CREDIT_CARD_NUMBER
     , i.CREDIT_CARD_HOLDER_NAME
     , i.CREDIT_CARD_EXPIRATION_DATE
     , i.CREDIT_AMOUNT
     , SYSDATE
     , FND_GLOBAL.USER_ID
     , SYSDATE
     , FND_GLOBAL.USER_ID
     , h.org_id
     , i.CC_AUTH_MANUAL
     , i.MERCHANT_NUMBER 
     , i.CC_AUTH_PS2000 
     , i.ALLIED_IND
     , i.RECEIPT_METHOD_ID  
    FROM XX_OM_RET_TENDERS_IFACE_ALL i ,
         OE_ORDER_HEADERS_ALL H
    WHERE h.header_id = p_header_id
    AND h.orig_sys_document_ref = i.orig_sys_document_ref
    AND h.order_source_id = i.order_source_id
    AND h.sold_to_org_id = i.sold_to_org_id;

EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        oe_debug_pub.add(  'OTHERS ERROR , Get_Return_Tenders' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
END Get_Return_Tenders;

-- +=====================================================================+
-- | Name  : Update_Actual_Shipment_Date                                 |
-- | Description  : This Procedure will look at interface table and will |
-- | update OE_ORDER_LINES_ALL table with actual_shipment_date.  It will |
-- | get called in NORMAL mode as well as in BULK mode                   |
-- |                                                                     |
-- | Parameters :  p_header_id   IN  ->current header_id                 |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE  Update_Actual_Shipment_Date
(   p_header_id     IN NUMBER )
IS
BEGIN
    -- Get the actual shipment date from line interface table
    UPDATE OE_ORDER_LINES_ALL l
    SET l.ACTUAL_SHIPMENT_DATE = 
             ( SELECT li.actual_shipment_date
               FROM OE_LINES_IFACE_ALL LI
               WHERE l.orig_sys_document_ref = LI.ORIG_SYS_DOCUMENT_REF
               AND l.orig_sys_line_ref = LI.ORIG_SYS_LINE_REF
               AND l.order_source_id = LI.order_source_id
               AND l.request_id  = LI.request_id)
    WHERE l.header_id = p_header_id;
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add(  'OTHERS ERROR , Get_Return_Tenders' ) ;
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
END Update_Actual_Shipment_Date;


END XX_OM_SALES_ACCT_PKG;
