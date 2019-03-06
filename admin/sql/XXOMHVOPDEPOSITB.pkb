CREATE OR REPLACE
PACKAGE BODY XX_OM_HVOP_DEPOSIT_CONC_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                          |
-- |                Office Depot                                                                                                      |
-- +===================================================================+
-- | Name  : XX_OM_HVOP_DEPOSIT_CONC_PKG                                                                       |
-- | Description      : Package Body                                                                               | 
-- |                                                                                                                                        |
-- |                                                                                                                                        |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                          |
-- |Version    Date          Author           Remarks                                                                       |
-- |=======    ==========    =============    ========================                |
-- |DRAFT 1A   06-MAR-2007   Visalakshi          Initial draft version                                                  |
-- |                                                                                                                                        |
-- +===================================================================+

PROCEDURE Process_Deposit (
                           x_retcode           OUT NOCOPY  NUMBER
                         , x_errbuf            OUT NOCOPY  VARCHAR2 
                         , p_debug_level       IN          NUMBER
                         , p_filedate          IN          VARCHAR2
                         , p_feednumber        IN          NUMBER
                         , x_return_status     OUT NOCOPY  VARCHAR2
                         ) IS
                           
    lc_input_file_handle    UTL_FILE.file_type;
    lc_curr_line            VARCHAR2 (1000);
    lc_o_unit               VARCHAR2(50);
    lc_return_status        VARCHAR2(100);
    ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(2000);
    ln_retcode              NUMBER;
    ln_request_id           NUMBER;
    lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');  
    lb_has_records          BOOLEAN;
    i                      BINARY_INTEGER;
    lc_orig_sys_document_ref       oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_curr_orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_record_type          VARCHAR2(10);
    l_order_tbl            order_tbl_type;
    lc_error_flag           VARCHAR2(1);
    lc_filename             VARCHAR2(100);
    lc_filedate             VARCHAR2(30);
BEGIN  
    FND_FILE.Put_Line(FND_FILE.OUTPUT,'Debug Level: '||nvl(p_debug_level,0));

    IF nvl(p_debug_level, 0) > 0 THEN
        FND_PROFILE.PUT('ONT_DEBUG_LEVEL',p_debug_level);
        lc_filename := oe_debug_pub.set_debug_mode ('CONC');
    END IF;

    BEGIN
       
          SELECT SUBSTR(name,(INSTR(name,'_',1,1) +1),2) name
          INTo  lc_o_unit 
          FROM hr_operating_units
          WHERE organization_id = g_org_id;
        fnd_file.put_line(FND_FILE.LOG,'The OU is '||lc_o_unit);
        fnd_file.put_line(FND_FILE.LOG,'File Name is '||lc_filename);
        
        IF NVL(p_feednumber,-1) NOT IN  (1,2,3,4,5)
         THEN
           fnd_file.put_line(FND_FILE.LOG,'Valid values for feed number are 1,2,3,4,5');
         RAISE FND_API.G_EXC_ERROR;
        END IF;
    
    lc_filedate := TO_CHAR(NVL(TO_DATE(p_filedate,'YYYY/MM/DD HH24:MI:SS'),sysdate),'DDMONYYYY');
    lc_filename := 'SASDEP'||lc_filedate||'_'||lc_o_unit||'_'||p_feednumber||'.txt';
    
        oe_debug_pub.add('Entering Process_Deposit');
        FND_PROFILE.GET('CONC_REQUEST_ID',G_request_id);
        fnd_file.put_line (fnd_file.LOG, 'Start Procedure ');
        fnd_file.put_line (fnd_file.LOG, 'File Path : ' || lc_file_path);
        fnd_file.put_line (fnd_file.LOG, 'File Name : ' || lc_filename);
        lc_input_file_handle := UTL_FILE.fopen(lc_file_path, lc_filename, 'R');
    EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         oe_debug_pub.add ('Invalid Path: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid Path: ' || SQLERRM);
    WHEN UTL_FILE.invalid_mode THEN
         oe_debug_pub.add ('Invalid Mode: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode: ' || SQLERRM);
    WHEN UTL_FILE.invalid_filehandle THEN
         oe_debug_pub.add ('Invalid file handle: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid file handle: ' || SQLERRM);
    WHEN UTL_FILE.invalid_operation THEN
         oe_debug_pub.add ('Invalid operation: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid operation: ' || SQLERRM);
    WHEN UTL_FILE.read_error THEN
         oe_debug_pub.add ('Read Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Read Error: ' || SQLERRM);
    WHEN UTL_FILE.write_error THEN
         oe_debug_pub.add ('Write Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Write Error: ' || SQLERRM);
    WHEN UTL_FILE.internal_error THEN
         oe_debug_pub.add ('Internal Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Internal Error: ' || SQLERRM);
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add ('No data found: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'No data found: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
         oe_debug_pub.add ('Value Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Value Error: ' || SQLERRM);
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE;
        
    END;

    lb_has_records := TRUE;
    i := 0;
    oe_debug_pub.add('After opening the file');
BEGIN
    LOOP
        BEGIN
             lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fnd_file.put_line (fnd_file.LOG, 'NO MORE RECORD TO READ');
            oe_debug_pub.add('Failure in Get Line :'|| i);
            lb_has_records := FALSE;
            IF l_order_tbl.count = 0 THEN 
               fnd_file.put_line (fnd_file.LOG, 'THE FILE IS EMPTY NO RECORDS');
               RAISE FND_API.G_EXC_ERROR;
            END IF;
        WHEN OTHERS THEN
          x_retcode := 2;
          fnd_file.put_line(FND_FILE.OUTPUT,'Unexpected error '||substr(sqlerrm,1,200));
          fnd_file.put_line(FND_FILE.OUTPUT,'');
          x_errbuf := 'Please check the log file for error messages';  
          lb_has_records := FALSE;
           RAISE FND_API.G_EXC_ERROR;
        END;
        
        -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
        lc_curr_line := substr(lc_curr_line,1,310);
        
        oe_debug_pub.add('My Line Is :'||lc_curr_line);
        lc_orig_sys_document_ref := substr(lc_curr_line,1 ,20);
        IF lc_curr_orig_sys_document_ref IS NULL THEN
           lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;
        END IF;
   
        -- IF Order has changed or we are at the last record of the file
        IF lc_curr_orig_sys_document_ref <> lc_orig_sys_document_ref  OR
           NOT lb_has_records 
        THEN
            oe_debug_pub.add('Before Process Current Order :');
            Process_current_deposit( p_order_tbl  => l_order_tbl
                                 );
            oe_debug_pub.add('After Process Current Order :');                     
            l_order_tbl.DELETE;
            i := 0;
        END IF;
    
        IF NOT lb_has_records THEN
            -- nothing to process
            Exit;
        END IF;

        lc_record_type := substr(lc_curr_line,21,2);
    
        IF lc_record_type = '10' THEN
            i := i + 1;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '40' THEN
            i := i + 1;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '99' THEN -- Trailer Record
            i := i + 1;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('The Trailer Rec is '|| lc_curr_line);
            END IF;    
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        END IF;
    
    END LOOP;

    -- After reading the whole file insert into the custom payments table
    insert_data; 
EXCEPTION
    WHEN OTHERS THEN
    lc_error_flag := 'Y';
    rollback;
END;
      
     -- Create log into the File History Table
    INSERT INTO xx_om_sacct_file_history (
                    file_name
                  , file_type  
                  , request_id
                  , process_date
                  , total_orders
                  , error_flag
                  , creation_date
                  , created_by
                  , last_update_date
                  , last_updated_by
                  ) 
    VALUES (
                     lc_filename
                   , 'DEPOSIT'
                   , ln_request_id
                   , SYSDATE
                   , ''
                   , lc_error_flag
                   , SYSDATE
                   , FND_GLOBAL.USER_ID
                   , SYSDATE
                   , FND_GLOBAL.USER_ID);
  
END Process_Deposit;

PROCEDURE Process_Current_Deposit(
p_order_tbl  IN order_tbl_type
 ) 
IS

BEGIN
    oe_debug_pub.add('In Process Current Deposit :');
    FOR k IN 1..p_order_tbl.COUNT LOOP
     
        IF p_order_tbl(k).record_type = '10' THEN
            oe_debug_pub.add('Calling  Process Header');
            process_header(p_order_tbl(k));
        ELSIF p_order_tbl(k).record_type = '40' THEN
            oe_debug_pub.add('Calling  Process PAyment');
            process_payment(p_order_tbl(k)); 
        END IF;
        
    END LOOP;

END Process_Current_Deposit;

PROCEDURE process_header(
  p_order_rec IN order_rec_type
) 
IS
i BINARY_INTEGER;
lc_order_source            VARCHAR2(20);
lc_orig_sys_customer_ref   VARCHAR2(50);
lc_order_category          VARCHAR2(2);
lc_paid_at_store_id        VARCHAR2(20);
lc_err_msg                 VARCHAR2(240);
ln_debug_level             NUMBER;
lc_return_status           VARCHAR2(80);
lb_store_customer          BOOLEAN;



BEGIN
    oe_debug_pub.add('Entering  Process Header');
    i := G_Header_Rec.Orig_sys_document_ref.COUNT + 1;
    oe_debug_pub.add('G_Header_Rec count is :'|| to_char(i-1));
    G_Header_Rec.error_flag(i) := NULL;
    
    G_header_rec.orig_sys_document_ref(i)   := RTRIM(SUBSTR(p_order_rec.file_line, 1,  20));
    lc_paid_at_store_id                     := LTRIM(SUBSTR (p_order_rec.file_line, 135,  4));
    lc_order_source                          := LTRIM(SUBSTR (p_order_rec.file_line, 143,  1));
    lc_orig_sys_customer_ref                 := SUBSTR (p_order_rec.file_line, 218,   8);
    G_header_rec.spc_card_number(i)        := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 196, 20)));
    oe_debug_pub.add('Entering  Process Header 7');
    lc_order_category                        := SUBSTR (p_order_rec.file_line, 217,   1);
    g_header_rec.sold_to_org(i)             := NULL;
    g_header_rec.sold_to_org_id(i)          := NULL;
    
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_header_rec.orig_sys_document_ref(i));
        oe_debug_pub.add('After reading header record ');
    
    -- to get order source id
    IF lc_order_source IS NOT NULL THEN
        g_header_rec.order_source_id(i) := order_source(lc_order_source);
        
        IF g_header_rec.order_source_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'ORDER_SOURCE_ID NOT FOUND FOR Order Source : ' || lc_order_source;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','ORDER SOURCE');
            OE_MSG_PUB.Add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.order_source_id(i) := NULL;
    END IF;
    oe_debug_pub.add('Order Source is '||g_header_rec.order_source_id(i));
    
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Request_id '||g_request_id);
        
    END IF;

    IF lc_paid_at_store_id IS NOT NULL THEN
        g_header_rec.paid_at_store_id(i) := store_id(lc_paid_at_store_id);
        g_header_rec.paid_at_store_no(i) := lc_paid_at_store_id;
        g_header_rec.created_by_store_id(i) := g_header_rec.paid_at_store_id(i);
    ELSE    
        g_header_rec.paid_at_store_id(i) := NULL;
        g_header_rec.paid_at_store_no(i) := NULL;
        g_header_rec.created_by_store_id(i) := NULL;
    END IF;
    
    /* to get customer_id */
    IF lc_orig_sys_customer_ref IS NULL THEN
        G_Header_Rec.Sold_to_org_id(i) := NULL;
        IF G_Header_Rec.Paid_At_Store_No(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_orig_sys_customer_ref;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Customer Reference');
            OE_MSG_PUB.Add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        ELSE
            lc_orig_sys_customer_ref := '00'||G_Header_Rec.Paid_At_Store_No(i); 
            lb_store_customer := TRUE;
        END IF;
    END IF;
  
     IF lc_orig_sys_customer_ref IS NOT NULL THEN
        HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id( 
                               p_orig_system => 'A0',
                               p_orig_system_reference => lc_orig_sys_customer_ref||'-00001-A0',
                               p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                               x_owner_table_id => g_header_rec.sold_to_org_id(i),
                               x_return_status =>  lc_return_status );
        IF (lc_return_status <> fnd_api.g_ret_sts_success ) THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_orig_sys_customer_ref;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SOLD_TO_ORG_ID');
            OE_MSG_PUB.Add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    END IF;     
      
    IF g_header_rec.sold_to_org_id(i) IS NOT NULL
    THEN
        g_header_rec.payment_term_id(i) := payment_term(g_header_rec.sold_to_org_id(i));
        IF g_header_rec.payment_term_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y'; 
            set_msg_context( p_entity_code  => 'HEADER');
            lc_err_msg := 'PAYMENT_TERM_ID NOT FOUND FOR Customer ID : ' || g_header_rec.sold_to_org_id(i);
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','PAYMENT_TYPE_ID');
            OE_MSG_PUB.Add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.payment_term_id(i) := NULL;
    END IF;
    
    END process_header;

PROCEDURE process_payment(p_order_rec IN order_rec_type) IS
i                BINARY_INTEGER;
lc_pay_type       VARCHAR2(10);
ln_org_id         NUMBER := fnd_profile.value('ORG_ID');
ln_sold_to_org_id NUMBER;
ln_payment_number NUMBER := 0;
lc_err_msg        VARCHAR2(200);
ln_debug_level    NUMBER;
ln_hdr_ind        NUMBER;
lc_payment_type_code  VARCHAR2(30);
lc_cc_code        VARCHAR2(80);
lc_cc_name        VARCHAR2(80);
lc_cc_number      VARCHAR2(80);

BEGIN

oe_debug_pub.add('Entering Process_Payment');
ln_hdr_ind := g_header_rec.orig_sys_document_ref.count;
lc_pay_type := SUBSTR(p_order_rec.file_line, 36,  2);
oe_debug_pub.add('Pay Type ' || lc_pay_type);

IF lc_pay_type IS NULL THEN
    set_msg_context( p_entity_code => 'HEADER_PAYMENT');
    G_Header_Rec.error_flag(ln_hdr_ind) := 'Y';                            
    lc_err_msg := 'PAYMENT METHOD Missing  ';
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Tender Type');
    OE_MSG_PUB.Add;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(lc_err_msg, 1);
    END IF;

END IF;
oe_debug_pub.add('After Pay Type ' );
IF lc_pay_type IS NOT NULL THEN
    Get_Pay_Method( p_payment_instrument => lc_pay_type
                  , p_payment_type_code  => lc_payment_type_code
                  , p_credit_card_code   => lc_cc_code);
        
    IF lc_payment_type_code IS NULL THEN
        set_msg_context( p_entity_code => 'HEADER_PAYMENT');
        G_Header_Rec.error_flag(ln_hdr_ind) := 'Y';                            
        lc_err_msg := 'INVALID PAYMENT METHOD :' ||lc_pay_type;
        FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE','PAYMENT TYPE');
        OE_MSG_PUB.Add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(lc_err_msg, 1);
        END IF;
    END IF;
END IF;
oe_debug_pub.add('After Pay method ' );
IF g_header_rec.sold_to_org_id(ln_hdr_ind) IS NOT NULL THEN
    lc_cc_name := credit_card_name(g_header_rec.sold_to_org_id(ln_hdr_ind));
END IF;
oe_debug_pub.add('cc name '|| lc_cc_name );

    oe_debug_pub.add('Start reading Payment Record ');
    i :=g_payment_rec.orig_sys_document_ref.count+1;
    G_payment_rec.payment_type_code(i)          := lc_payment_type_code;
    G_payment_rec.receipt_method_id(i)          := receipt_method_code(lc_pay_type,g_org_id,ln_hdr_ind);
    G_payment_rec.orig_sys_document_ref(i)      := G_header_rec.orig_sys_document_ref(ln_hdr_ind);
    G_payment_rec.order_source_id(i)            := G_header_rec.order_source_id(ln_hdr_ind);
    G_payment_rec.orig_sys_payment_ref(i)       := SUBSTR(p_order_rec.file_line, 33,  3);
    G_payment_rec.payment_amount(i)             := SUBSTR(p_order_rec.file_line, 39, 10);
    lc_cc_number                                 := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 49, 20)));
    
    IF lc_cc_number IS NOT NULL THEN
        G_payment_rec.credit_card_number(i)          := iby_cc_security_pub.secure_card_number('T', lc_cc_number);
        G_payment_rec.credit_card_expiration_date(i) := TO_DATE(SUBSTR(p_order_rec.file_line, 69,  4),'MMYY');
        G_payment_rec.credit_card_code(i)            := lc_cc_code;
        G_payment_rec.credit_card_approval_code(i)   := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 75,  6)));
        oe_debug_pub.add('CC apr date '|| SUBSTR(p_order_rec.file_line, 80, 10));
        G_payment_rec.credit_card_approval_date(i)   := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 81, 10)),'YYYY-MM-DD');
    ELSE 
        G_payment_rec.credit_card_number(i)          := NULL;
        G_payment_rec.credit_card_expiration_date(i) := NULL;
        G_payment_rec.credit_card_code(i)            := NULL;
        G_payment_rec.credit_card_approval_code(i)   := NULL;
        G_payment_rec.credit_card_approval_date(i)   := NULL;
    END IF;
    G_payment_rec.check_number(i)               := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 91, 20)));
    G_payment_rec.payment_number(i)             := G_payment_rec.orig_sys_payment_ref(i);
    G_payment_rec.attribute6(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  111, 1)));
    G_payment_rec.attribute7(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 112, 11)));
    G_payment_rec.attribute8(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 123, 50))); 
    G_payment_rec.attribute9(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  173, 1)));
    G_payment_rec.credit_card_holder_name(i)    := lc_cc_name;
    
    oe_debug_pub.ADD('lc_pay_type = '||lc_pay_type);
    oe_debug_pub.ADD('receipt_method = '||G_payment_rec.receipt_method_id(i));
    oe_debug_pub.ADD('orig_sys_document_ref = '||G_payment_rec.orig_sys_document_ref(i));
    oe_debug_pub.ADD('order_source_id = '||G_payment_rec.order_source_id(i));
    oe_debug_pub.ADD('orig_sys_payment_ref = '||G_payment_rec.orig_sys_payment_ref(i));
    oe_debug_pub.ADD('payment_amount = '||G_payment_rec.payment_amount(i));
    oe_debug_pub.ADD('lc_cc_number = '||lc_cc_number);
    oe_debug_pub.ADD('credit_card_expiration_date = '||G_payment_rec.credit_card_expiration_date(i));
    oe_debug_pub.ADD('credit_card_approval_code = '||G_payment_rec.credit_card_approval_code(i));
    oe_debug_pub.ADD('credit_card_approval_date = '||G_payment_rec.credit_card_approval_date(i));
    oe_debug_pub.ADD('check_number = '||G_payment_rec.check_number(i));
    oe_debug_pub.ADD('attribute6 = '||G_payment_rec.attribute6(i));
    oe_debug_pub.ADD('attribute7 = '||G_payment_rec.attribute7(i));
    oe_debug_pub.ADD('attribute8 = '||G_payment_rec.attribute8(i));
    oe_debug_pub.ADD('attribute9 = '||G_payment_rec.attribute9(i));
    oe_debug_pub.ADD('credit_card_holder_name = '||G_payment_rec.credit_card_holder_name(i));
END process_payment;


FUNCTION order_source(p_order_source IN VARCHAR2 ) RETURN VARCHAR2 IS
BEGIN
IF NOT g_order_source.exists  (p_order_source)  THEN
      SELECT attribute6
        INTO g_order_source(p_order_source)
        FROM apps.fnd_lookup_values
       WHERE lookup_type = 'OD_LEGACY_ORD_SOURCES'
          AND lookup_code = UPPER(p_order_source);

END IF;
RETURN(g_order_source(p_order_source));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END order_source;

FUNCTION store_id (p_store_no IN VARCHAR2) RETURN NUMBER IS

BEGIN
IF g_store_id.exists (p_store_no) THEN
    RETURN(g_store_id(p_store_no));
ELSE
    SELECT organization_id  
      INTO g_store_id(p_store_no)
      FROM hr_all_organization_units 
     WHERE attribute1 = p_store_no;
    RETURN(g_store_id(p_store_no));
END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END store_id;

FUNCTION payment_term (p_sold_to_org_id IN NUMBER) RETURN VARCHAR2 IS

BEGIN
IF NOT g_payment_term.exists(p_sold_to_org_id) THEN
    SELECT payment_term_id
      INTO g_payment_term(p_sold_to_org_id)
      FROM hz_cust_accounts
     WHERE cust_account_id = p_sold_to_org_id;
END IF;          
RETURN(g_payment_term(p_sold_to_org_id));

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END payment_term;

                 
PROCEDURE Get_Pay_Method(
  p_payment_instrument IN VARCHAR2
, p_payment_type_code IN OUT NOCOPY VARCHAR2
, p_credit_card_code  IN OUT NOCOPY VARCHAR2)
IS
BEGIN
    IF NOT g_pay_method_code.exists(p_payment_instrument) THEN
        SELECT attribute7, attribute6
        INTO g_pay_method_code(p_payment_instrument), g_cc_code(p_payment_instrument)
        FROM fnd_lookup_values
        WHERE lookup_type = 'OD_PAYMENT_TYPES'
        AND lookup_code = p_payment_instrument;

    END IF;
    p_payment_type_code := g_pay_method_code(p_payment_instrument);
    p_credit_card_code := g_cc_code(p_payment_instrument);
EXCEPTION
    WHEN OTHERS THEN
        p_payment_type_code := NULL;
        p_credit_card_code := NULL;
END Get_pay_method;

FUNCTION receipt_method_code(
 p_pay_method_code IN VARCHAR2,
 p_org_id IN NUMBER,
 p_hdr_idx IN BINARY_INTEGER
 ) RETURN VARCHAR2 IS
l_receipt_method_id   NUMBER;
l_store_no            VARCHAR2(10);
BEGIN
    l_store_no := G_Header_Rec.paid_at_store_no(p_hdr_idx);
    IF p_pay_method_code IN ('01','51','81') THEN
        
        SELECT receipt_method_id
        INTO l_receipt_method_id
        FROM AR_RECEIPT_METHODS
        WHERE NAME = 'US_OM CASH'||'00'||l_store_no;
        
    ELSIF  p_pay_method_code IN ('10','31','80') THEN
        
        SELECT receipt_method_id
        INTO l_receipt_method_id
        FROM AR_RECEIPT_METHODS
        WHERE NAME = 'US_OM CHECK'||'00'||l_store_no;
        
    ELSE
      
        SELECT flv.attribute8
        INTO l_receipt_method_id
        FROM fnd_lookup_values flv,
             oe_payment_types_all opt          
        WHERE flv.lookup_type = 'OD_PAYMENT_TYPES'
        AND flv.lookup_code = p_pay_method_code
        AND flv.attribute6 = opt.payment_type_code
        AND opt.org_id     = p_org_id;
        
    END IF;
    
    RETURN l_receipt_method_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END receipt_method_code;

FUNCTION credit_card_name(p_sold_to_org_id IN NUMBER) RETURN VARCHAR2 IS
lc_cc_name VARCHAR2(80);
BEGIN
    SELECT party_name
    INTO lc_cc_name
    FROM hz_parties p, 
         hz_cust_accounts a
    WHERE a.cust_account_id = p_sold_to_org_id
    AND a.party_id = p.party_id;
    
    RETURN lc_cc_name;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END credit_card_name;
 
PROCEDURE insert_data IS
 BEGIN
  
FORALL i_pay IN G_payment_rec.orig_sys_document_ref.FIRST.. G_payment_rec.orig_sys_document_ref.LAST
                        INSERT INTO xx_om_legacy_deposits ( 
                                                            orig_sys_document_ref
 							  , order_source_id
 							  , orig_sys_payment_ref
 							  , org_id
 							  , payment_type_code
 							  , payment_collection_event
 							  , prepaid_amount
 							  , credit_card_number
 							  , credit_card_holder_name
 							  , credit_card_expiration_date
 							  , credit_card_code
 							  , credit_card_approval_code
 							  , credit_card_approval_date
 							  , check_number
 							  , payment_amount
 							  , operation_code
 							  , error_flag
 							  , receipt_method_id
 							  , payment_number
 							  , created_by
 							  , creation_date
 							  , last_update_date
 							  , last_updated_by
 							  , request_id
                                                          , cc_auth_manual
                                                          , merchant_number
                                                          , cc_auth_ps2000
                                                          , allied_ind
 							  ) VALUES (
 							    G_payment_rec.orig_sys_document_ref(i_pay)
 							  , G_payment_rec.order_source_id(i_pay)
 							  , G_payment_rec.orig_sys_payment_ref(i_pay)
 							  , G_org_id
 							  , G_payment_rec.payment_type_code(i_pay)
 							  , G_payment_rec.payment_collection_event(i_pay)
 							  , G_payment_rec.prepaid_amount(i_pay)
 							  , G_payment_rec.credit_card_number(i_pay)
 							  , G_payment_rec.credit_card_holder_name(i_pay)
 							  , G_payment_rec.credit_card_expiration_date(i_pay)
 							  , G_payment_rec.credit_card_code(i_pay)
 							  , G_payment_rec.credit_card_approval_code(i_pay)
 							  , G_payment_rec.credit_card_approval_date(i_pay)
 							  , G_payment_rec.check_number(i_pay)
 							  , G_payment_rec.payment_amount(i_pay)
 							  , G_payment_rec.operation_code(i_pay)
 							  , 'N'
 							  , G_payment_rec.receipt_method_id(i_pay)
 							  , G_payment_rec.payment_number(i_pay)
 							  , FND_GLOBAL.USER_ID
 							  , SYSDATE
 							  , SYSDATE
 							  , FND_GLOBAL.USER_ID
 							  , G_request_id
                                                          , G_payment_rec.attribute6(i_pay)
                                                          , G_payment_rec.attribute7(i_pay)
                                                          , G_payment_rec.attribute8(i_pay)
                                                          , G_payment_rec.attribute9(i_pay)
 							  );

END insert_data;
 
PROCEDURE SET_MSG_CONTEXT(p_entity_code IN VARCHAR2,
                          p_line_ref IN VARCHAR2 DEFAULT NULL)
IS
    ln_hdr_ind BINARY_INTEGER := g_header_rec.orig_sys_document_ref.COUNT;
BEGIN
    oe_bulk_msg_pub.set_msg_context( p_entity_code                 =>  p_entity_code
                                ,p_entity_ref                      =>  NULL
                                ,p_entity_id                       =>  NULL
                                ,p_header_id                       =>  NULL
                                ,p_line_id                         =>  NULL
                                ,p_order_source_id                 =>  g_header_rec.order_source_id(ln_hdr_ind)
                                ,p_orig_sys_document_ref	   =>  g_header_rec.orig_sys_document_ref(ln_hdr_ind)
                                ,p_orig_sys_document_line_ref      =>  NULL
                                ,p_orig_sys_shipment_ref   	   => NULL
                                ,p_change_sequence   	           => NULL
                                ,p_source_document_type_id         => NULL
                                ,p_source_document_id	           => NULL
                                ,p_source_document_line_id	   => NULL
                                ,p_attribute_code       	   => NULL
                                ,p_constraint_id		   => NULL );

END SET_MSG_CONTEXT;

END XX_OM_HVOP_DEPOSIT_CONC_PKG;
