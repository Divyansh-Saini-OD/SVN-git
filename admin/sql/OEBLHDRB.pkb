--
--  Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--
--  FILENAME
--
--      OEBLHDRB.pls
--
--  DESCRIPTION
--
--      Body of package OE_BULK_PROCESS_HEADER
--
--  NOTES
--
--     Order Headers utility API to be used in BULK import 
--
--
--  HISTORY
--
--  30-Apr-02 Created        Nithya Lakshmanan
--

SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE

CREATE or REPLACE PACKAGE BODY OE_BULK_PROCESS_HEADER AS
/* $Header: OEBLHDRB.pls 115.20.11510.2 2004/12/16 17:54:15 mvijayku ship $ */

G_PKG_NAME         CONSTANT     VARCHAR2(30):='OE_BULK_PROCESS_HEADER';


-----------------------------------------------------------------------
-- LOCAL PROCEDURES/FUNCTIONS
-----------------------------------------------------------------------

-- Pass sold_to_org_id on the order or line in the related_customer_id
-- parameter.

FUNCTION Is_Related_Customer
  (p_related_customer_id       IN NUMBER
  ,p_customer_id               IN NUMBER
  )
RETURN BOOLEAN
IS
  l_dummy           VARCHAR2(1);
BEGIN

     SELECT 'VALID'
       INTO l_dummy
       FROM hz_cust_acct_relate
      WHERE RELATED_CUST_ACCOUNT_ID = p_related_customer_id
        AND CUST_ACCOUNT_ID = p_customer_id AND STATUS='A'
        AND ROWNUM = 1; 

     RETURN TRUE;

EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;

END Is_Related_Customer;


FUNCTION Get_Order_Number(p_order_type_id IN NUMBER,
                           p_order_number IN OUT NUMBER)
RETURN BOOLEAN 
IS

x_result NUMBER;
x_doc_sequence_value NUMBER;
x_doc_category_code  VARCHAR(30):= p_order_type_id;
x_doc_sequence_id    NUMBER;
x_db_sequence_name   VARCHAR2(50);
x_doc_sequence_type  CHAR(1);
x_doc_sequence_name  VARCHAR2(240);
x_Prd_Tbl_Name       VARCHAR2(240) ;
x_Aud_Tbl_Name       VARCHAR2(240);
x_Msg_Flag           VARCHAR2(240);
x_seqassid           INTEGER;


BEGIN

-- Check whether order type exists in global table

   IF G_SEQ_INFO_TBL.EXISTS(p_order_type_id) THEN

     x_doc_sequence_type := G_SEQ_INFO_TBL(p_order_type_id);

   ELSE --  Get sequence type from AOL
       
     x_result :=   fnd_seqnum.get_seq_info( 660,
                                          x_doc_category_code,
                                          OE_Bulk_Order_Pvt.G_SOB_ID,
                                          null,
                                          sysdate,
                                          x_doc_sequence_id,
                                          x_doc_sequence_type,
                                          x_doc_sequence_name,
                                          x_db_sequence_name,
                                          x_seqassid,
                                          x_Prd_Tbl_Name,
                                          x_Aud_Tbl_Name,
                                          x_Msg_Flag
                                          );

    
     IF (x_result <>  FND_SEQNUM.SEQSUCC)THEN

         IF (x_result = FND_SEQNUM.NOTUSED) THEN
                 fnd_message.set_name('ONT','OE_MISS_DOC_SEQ');
                 oe_bulk_msg_pub.Add('Y', 'ERROR');
                 RAISE FND_API.G_EXC_ERROR;
         END IF;

     END IF;

     -- Add entry to global table

     G_SEQ_INFO_TBL(p_order_type_id) := x_doc_sequence_type;
 
  END IF;  -- Order Type exists in Global table

 -- For manual sequences Caller needs to pass the Order Number.
  IF (x_doc_sequence_type = 'M') THEN
     IF (p_order_number IS NULL) THEN 
        FND_MESSAGE.SET_NAME('ONT','OE_ATTRIBUTE_REQUIRED');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                  OE_Order_Util.Get_Attribute_Name('ORDER_NUMBER'));
        oe_bulk_msg_pub.Add('Y', 'ERROR');
        return FALSE;
     ELSE 
        return TRUE;
     END IF;
  -- Gapless sequence not supported for BULK
  ELSIF x_doc_sequence_type = 'G' THEN
     fnd_message.set_name('ONT','OE_BULK_GAPLESS_DOC_SEQ');
     oe_bulk_msg_pub.Add('Y', 'ERROR');
     RETURN FALSE;
  END IF;

  X_result := fnd_seqnum.get_seq_val(660,
                                     x_doc_category_code,
                                     OE_Bulk_Order_Pvt.G_SOB_ID,
                                     null,
                                     sysdate,
                                     x_doc_sequence_value,
                                     x_doc_sequence_id,
                                     'Y',
                                     'Y');

  IF (x_result <> 0)THEN
     RAISE FND_API.G_EXC_ERROR;
  END IF;

  p_order_number := x_doc_sequence_value;
  RETURN TRUE;

EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE; 
END Get_Order_Number;


--
-- This FUNCTION returns the Price List Type Code
--

FUNCTION Get_Price_List_Type
( p_price_list_id IN  NUMBER)
RETURN VARCHAR2
IS
  l_c_index        NUMBER;
BEGIN
  
   l_c_index := OE_Bulk_Cache.Load_Price_List(p_price_list_id); 
  
   RETURN OE_Bulk_Cache.G_PRICE_LIST_TBL(l_c_index).list_type_code;

END Get_Price_List_Type;


--
-- This FUNCTION validates Tax Exempt Reason against the lookup
--

FUNCTION Valid_Tax_Exempt_Reason
 (p_tax_exempt_reason_code          VARCHAR2
 )
RETURN BOOLEAN
IS
  l_dummy          VARCHAR2(1);
BEGIN

  SELECT 'Y'
  INTO l_dummy
  FROM OE_AR_LOOKUPS_V l
  WHERE l.LOOKUP_CODE = p_tax_exempt_reason_code
    AND l.LOOKUP_TYPE = 'TAX_REASON'
    AND l.ENABLED_FLAG = 'Y'
    AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
        AND NVL(END_DATE_ACTIVE, SYSDATE)
    ;
  RETURN TRUE;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Valid_Tax_Exempt_Reason;

--
-- This FUNCTION validates Tax Exemptions against Customer, Sites
--

FUNCTION Valid_Tax_Exemptions
 (p_tax_exempt_number               VARCHAR2
 ,p_tax_exempt_reason_code          VARCHAR2
 ,p_ship_to_org_id                  NUMBER
 ,p_invoice_to_org_id               NUMBER
 ,p_sold_to_org_id                  NUMBER
 ,p_request_date                    DATE
 )
RETURN BOOLEAN
IS
  l_dummy       VARCHAR2(10);
BEGIN

  SELECT 'VALID'
    INTO l_dummy
    FROM TAX_EXEMPTIONS_V
   WHERE TAX_EXEMPT_NUMBER = p_tax_exempt_number
     AND TAX_EXEMPT_REASON_CODE=p_tax_exempt_reason_code
     AND SHIP_TO_SITE_USE_ID = nvl(p_ship_to_org_id,p_invoice_to_org_id)
     AND BILL_TO_CUSTOMER_ID = p_sold_to_org_id
     AND STATUS_CODE = 'PRIMARY'
     AND TRUNC(NVL(p_request_date,sysdate))
          BETWEEN TRUNC(START_DATE)
               AND TRUNC(NVL(END_DATE,NVL(p_request_date,sysdate)))
     AND ROWNUM = 1;
 
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Valid_Tax_Exemptions;

-- End customer changes 
FUNCTION validate_end_customer(p_end_customer_id IN NUMBER) RETURN BOOLEAN
IS
l_dummy   VARCHAR2(10);
BEGIN
   IF p_end_customer_id IS NULL OR
      p_end_customer_id = FND_API.G_MISS_NUM THEN
      RETURN TRUE;
   END IF;
   
     SELECT  'VALID' INTO l_dummy
       FROM OE_SOLD_TO_ORGS_V
      WHERE   ORGANIZATION_ID =p_end_customer_id    AND
      STATUS = 'A' AND
    SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
	AND NVL(END_DATE_ACTIVE, SYSDATE);
   RETURN TRUE;
 EXCEPTION
    WHEN NO_DATA_FOUND THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN

	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'END_CUSTOMER_ID');

            fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('END_CUSTOMER_ID')||':validation:'||to_char(p_end_customer_id));
            OE_MSG_PUB.Add;
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);

        END IF;
        
        RETURN FALSE;

    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'END_CUSOTMER'
            );
        END IF;

         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   null;
  
END validate_end_customer;

FUNCTION validate_end_customer_contact(p_end_customer_contact_id IN NUMBER) RETURN BOOLEAN
IS
l_dummy   VARCHAR2(10);
BEGIN
 IF p_end_customer_contact_id IS NULL OR
    p_end_customer_contact_id = FND_API.G_MISS_NUM THEN
    RETURN TRUE;
 END IF;
 
   SELECT  'VALID'  INTO  l_dummy
     FROM  OE_RA_CONTACTS_V CON
    WHERE   CON.CONTACT_ID = p_end_customer_contact_id
      AND     CON.STATUS = 'A';
 RETURN TRUE;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN

	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'END_CUSTOMER_CONTACT_ID');

            fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('end_customer_contact_id'));
            OE_MSG_PUB.Add;
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);

        END IF;

        
        RETURN FALSE;

    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'End_Customer_Contact'
            );
        END IF;

        
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   null;
END validate_end_customer_contact;


FUNCTION validate_END_CUSTOMER_SITE_USE (
					 p_end_customer_site_use_id IN NUMBER,
					 p_end_customer_id IN NUMBER)RETURN BOOLEAN
   IS
   l_dummy    VARCHAR2(10);
     l_c_index        NUMBER;
BEGIN
   IF p_end_customer_site_use_id IS NULL OR p_end_customer_site_use_id = FND_API.G_MISS_NUM  THEN
      RETURN TRUE;
   END IF;

/*   SELECT  'VALID'
	    INTO
	    l_dummy
	    FROM 
	    hz_cust_site_uses site_use,
	    hz_cust_acct_sites acct_site
	    WHERE
	    site_use.site_use_id=p_end_customer_site_use_id
	    and site_use.cust_acct_site_id=acct_site.cust_acct_site_id
	    and acct_site.cust_account_id=p_end_customer_id;

    RETURN TRUE; */

 l_c_index := OE_Bulk_Cache.Load_End_customer_site
                    (p_key          => p_end_customer_site_use_id);

  IF OE_Bulk_Cache.G_END_CUSTOMER_SITE_TBL(l_c_index).customer_id 
      = p_end_customer_id
  THEN
     RETURN TRUE;
  ELSE 
     RETURN FALSE;
  END IF; 

    EXCEPTION
  WHEN NO_DATA_FOUND THEN
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN

	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'END_CUSTOMER_SITE_USE_ID');

            fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('end_customer_site_use_id'));
            OE_MSG_PUB.Add;
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);

        END IF;

        
        RETURN FALSE;

    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'END_CUSTOMER_SITE_USE_ID'
            );
        END IF;

        
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      null;
 END validate_END_CUSTOMER_SITE_USE;

 FUNCTION validate_IB_OWNER ( p_ib_owner IN VARCHAR2 )RETURN BOOLEAN
    IS l_dummy    VARCHAR2(10);
  l_lookup_type1     VARCHAR2(80) :='ITEM_OWNER';

 BEGIN
    IF p_ib_owner IS NULL OR
       p_ib_owner = FND_API.G_MISS_CHAR  THEN
       RETURN TRUE;
    END IF;
      SELECT  'VALID'      INTO
       l_dummy      FROM     OE_LOOKUPS
       WHERE    lookup_code = p_ib_owner AND
       ( lookup_type = l_lookup_type1);

        RETURN TRUE;
	EXCEPTION
        WHEN NO_DATA_FOUND THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN

           OE_DEBUG_PUB.ADD('Validation failed for IB_INSTALLED_AT_LOCATION in OEBLHDRB.pls');
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'IB_INSTALLED_AT_LOCATION');

            fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('ib_installed_at_location'));
            OE_MSG_PUB.Add;
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);

        END IF;

        
        RETURN FALSE;

    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'IB_INSTALLED_AT_LOCATION'
            );
        END IF;

        
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

          null;	   

     END validate_IB_OWNER;
     

     FUNCTION validate_IB_INST_LOC( p_ib_installed_at_location IN VARCHAR2 )RETURN BOOLEAN
	IS
	l_dummy                       VARCHAR2(10);
	l_lookup_type1   VARCHAR2(80) :='ITEM_INSTALL_LOCATION';

     BEGIN
	IF p_ib_installed_at_location IS NULL OR p_ib_installed_at_location = FND_API.G_MISS_CHAR  THEN
	   RETURN TRUE;
	END IF;
	  SELECT  'VALID'  INTO  l_dummy FROM OE_LOOKUPS
	   WHERE    lookup_code = p_ib_installed_at_location AND
	   (lookup_type = l_lookup_type1);

      RETURN TRUE;
	EXCEPTION
	       WHEN NO_DATA_FOUND THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN

           OE_DEBUG_PUB.ADD('Validation failed for IB_INSTALLED_AT_LOCATION in OEBLHDRB.pls');
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'IB_INSTALLED_AT_LOCATION');

            fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('ib_installed_at_location'));
            OE_MSG_PUB.Add;
	      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);

        END IF;

        
        RETURN FALSE;

    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'IB_INSTALLED_AT_LOCATION'
            );
        END IF;

        
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          null;

	END validate_IB_INST_LOC;
	
	FUNCTION validate_IB_CURRENT_LOCATION ( p_ib_current_location IN VARCHAR2 )
	   RETURN BOOLEAN
     IS
	l_dummy                       VARCHAR2(10);
	l_lookup_type1      	      VARCHAR2(80) :='ITEM_CURRENT_LOCATION';

     BEGIN
	IF p_ib_current_location IS NULL OR
        p_ib_current_location = FND_API.G_MISS_CHAR
	   THEN
	   
        RETURN TRUE;
     END IF;
     
      SELECT  'VALID'
	INTO     l_dummy
	FROM     OE_LOOKUPS 
       WHERE    lookup_code = p_ib_current_location AND
       (lookup_type = l_lookup_type1 );

        RETURN TRUE;
     EXCEPTION
	WHEN NO_DATA_FOUND THEN
	   
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_ERROR)
        THEN
	   
           OE_DEBUG_PUB.ADD('Validation failed for IB_CURRENT_LOCATION in OEBLHDRB.pls');
	   OE_MSG_PUB.Update_Msg_Context(p_attribute_code => 'IB_CURRENT_LOCATION');
	   
	   fnd_message.set_name('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
				OE_Order_Util.Get_Attribute_Name('ib_current_location'));
            OE_MSG_PUB.Add;
	    OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);
	    
     END IF;
     
     
     RETURN FALSE;
     
     WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
	   OE_MSG_PUB.Add_Exc_Msg
	      (   G_PKG_NAME
		  ,   'IB_CURRENT_LOCATION'
		  );
        END IF;
	
        
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

          null;
       END validate_IB_CURRENT_LOCATION;
     
     
 

PROCEDURE Check_Book_Reqd_Attributes
( p_header_rec            IN OE_Bulk_Order_Pvt.HEADER_REC_TYPE
, p_index                 IN NUMBER
, x_return_status         IN OUT VARCHAR2
)
IS
  l_set_of_books_rec    OE_Order_Cache.Set_Of_Books_Rec_Type;
  l_c_index             NUMBER;
BEGIN

    oe_debug_pub.add('Enter OE_VALIDATE_HEADER.CHECK_BOOK_REQD',1);

  -- Check for the following required fields on a booked order:
  -- Order Number, Sold To Org, Invoice To Org,
  -- Price List, Tax Exempt Flag, Sales Person, Order Date

  IF p_header_rec.sold_to_org_id(p_index) IS NULL 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
    OE_Order_UTIL.Get_Attribute_Name('SOLD_TO_ORG_ID'));
    oe_bulk_msg_pub.ADD;
  END IF;

  IF p_header_rec.salesrep_id(p_index) IS NULL 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
    OE_Order_UTIL.Get_Attribute_Name('SALESREP_ID'));
    oe_bulk_msg_pub.ADD;
  END IF;

  IF p_header_rec.ordered_date(p_index) IS NULL 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
    OE_Order_UTIL.Get_Attribute_Name('ORDERED_DATE'));
    oe_bulk_msg_pub.ADD;
  END IF;

  IF p_header_rec.invoice_to_org_id(p_index) IS NULL 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
      OE_Order_UTIL.Get_Attribute_Name('INVOICE_TO_ORG_ID'));
    oe_bulk_msg_pub.ADD;
  END IF;

  IF p_header_rec.tax_exempt_flag(p_index) IS NULL 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
      OE_Order_UTIL.Get_Attribute_Name('TAX_EXEMPT_FLAG'));
    oe_bulk_msg_pub.ADD;
  END IF;


  -- Fix bug 1262790
  -- Ship To Org and Payment Term are required only on regular or
  -- MIXED orders, NOT on RETURN orders

  IF p_header_rec.order_category_code(p_index) <>
               OE_GLOBALS.G_RETURN_CATEGORY_CODE THEN

    IF p_header_rec.ship_to_org_id(p_index) IS NULL 
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
        OE_Order_UTIL.Get_Attribute_Name('SHIP_TO_ORG_ID'));
      oe_bulk_msg_pub.ADD;
    END IF;

    IF p_header_rec.payment_term_id(p_index) IS NULL 
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
        OE_Order_UTIL.Get_Attribute_Name('PAYMENT_TERM_ID'));
      oe_bulk_msg_pub.ADD;
    END IF;

  END IF;


  -- Check for additional required fields based on flags set 
  -- at the order type: agreement, customer po number

  l_c_index := OE_Bulk_Cache.Load_Order_Type(p_header_rec.order_type_id(p_index));

  IF ( OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).agreement_required_flag = 'Y' AND
       p_header_rec.agreement_id(p_index) IS NULL) 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
    OE_Order_UTIL.Get_Attribute_Name('AGREEMENT_ID'));
    oe_bulk_msg_pub.ADD;
  END IF;  

  IF ( OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).require_po_flag = 'Y' AND
       p_header_rec.cust_po_number(p_index) IS NULL) 
  THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
    OE_Order_UTIL.Get_Attribute_Name('CUST_PO_NUMBER'));
    oe_bulk_msg_pub.ADD;
  END IF;  


  -- Conversion Type Related Checks

  -- IF SOB currency is dIFferent from order currency, 
  -- conversion type is required
  
  IF p_header_rec.conversion_type_code(p_index) IS NULL 
  THEN
     l_set_of_books_rec := OE_Order_Cache.Load_Set_Of_Books;

     IF ( l_set_of_books_rec.currency_code <> 
      p_header_rec.transactional_curr_code(p_index)) THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_VAL_REQ_NON_BASE_CURRENCY');
      FND_MESSAGE.SET_TOKEN
      ('ORDER_CURRENCY',p_header_rec.transactional_curr_code(p_index));
      FND_MESSAGE.SET_TOKEN('SOB_CURRENCY',l_set_of_books_rec.currency_code);
      oe_bulk_msg_pub.ADD;
     END IF;

  -- IF conversion type is 'User', conversion rate AND conversion rate date
  -- required.
  
  ELSIF p_header_rec.conversion_type_code(p_index) = 'User' 
  THEN

    IF p_header_rec.conversion_rate(p_index) IS NULL OR 
       p_header_rec.conversion_rate_date(p_index) IS NULL
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_VAL_USER_CONVERSION_TYPE');
      oe_bulk_msg_pub.ADD;
    END IF;

  END IF; -- END of checks based on conversion type


  -- Checks based on payment type attached to the order

  IF p_header_rec.payment_type_code(p_index) IS NOT NULL THEN

    -- payment amount should be specIFied
    -- only IF Payment Type is NOT Credit Card
    
    IF  p_header_rec.payment_type_code(p_index) <> 'CREDIT_CARD' AND 
        p_header_rec.payment_amount(p_index) IS NULL 
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_BOOK_REQUIRED_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
      OE_Order_UTIL.Get_Attribute_Name('PAYMENT_AMOUNT'));
      oe_bulk_msg_pub.ADD;
    END IF;

    -- check number required IF payment type is Check
    
    IF (p_header_rec.payment_type_code(p_index) = 'CHECK' AND 
        p_header_rec.check_number(p_index) IS NULL ) 
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_VAL_CHECK_NUM_REQD');
      oe_bulk_msg_pub.ADD;
    END IF;

    -- credit card holder name, number AND expiration date 
    -- required for payment type of Credit Card
    
    /*
    ** Following Validation Moved to Authorize Credit Card
    ** Payment Routine. Not required anymore at BOOKING.
    IF p_header_rec.payment_type_code = 'CREDIT_CARD' THEN
      IF p_header_rec.credit_card_holder_name IS NULL
      OR p_header_rec.credit_card_number IS NULL
      OR p_header_rec.credit_card_expiration_date IS NULL
      THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ONT','OE_VAL_CREDIT_CARD_REQD');
      oe_bulk_msg_pub.ADD;
      END IF;
    END IF;
    */
   
  END IF; -- END of checks related to payment type

    oe_debug_pub.add('Exiting OE_VALIDATE_HEADER.CHECK_BOOK_REQD',1);
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF oe_bulk_msg_pub.check_msg_level (oe_bulk_msg_pub.G_MSG_LVL_UNEXP_ERROR)
    THEN
      oe_bulk_msg_pub.add_exc_msg
      (  G_PKG_NAME ,
        'Check_Book_Reqd_Attributes'
      );
    END IF;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Check_Book_Reqd_Attributes;


PROCEDURE Default_Record
     (p_header_rec      IN OUT NOCOPY OE_Bulk_Order_Pvt.HEADER_REC_TYPE
     ,p_index           IN NUMBER
     ,x_return_status   OUT VARCHAR2
     )
IS
l_c_index      NUMBER;
BEGIN
   
     x_return_status := FND_API.G_RET_STS_SUCCESS;

     -- Validation of defaulted attributes - when to do this, within the
     -- cache for each source? YES!

     -- Default Order Type from 1.Invoice To 2.Ship To

     IF p_header_rec.order_type_id(p_index) IS NULL THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Invoice_To
                          (p_key => p_header_rec.invoice_to_org_id(p_index)
                          ,p_default_attributes => 'Y');
        p_header_rec.order_type_id(p_index) 
          := OE_Bulk_Cache.G_INVOICE_TO_TBL(l_c_index).order_type_id;

        -- Invalid invoice to - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Invoice To cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     IF p_header_rec.order_type_id(p_index) IS NULL THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Ship_To
                          (p_key => p_header_rec.ship_to_org_id(p_index)
                          ,p_default_attributes => 'Y');
        p_header_rec.order_type_id(p_index) 
          := OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).order_type_id;

        -- Invalid ship to - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Ship To cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     -- ASSUMPTION: The hierarchy for defaulting sources for each of the
     -- attributes can only be 1.Agreement 2.Ship To 3.Invoice To 4.Order Type

     -- Default attributes that have agreement as the first source

     IF p_header_rec.agreement_id(p_index) IS NOT NULL
        AND ( p_header_rec.price_list_id(p_index) IS NULL
             OR p_header_rec.payment_term_id(p_index) IS NULL
             OR p_header_rec.accounting_rule_id(p_index) IS NULL
             OR p_header_rec.invoicing_rule_id(p_index) IS NULL )
     THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Agreement
                          (p_key => p_header_rec.agreement_id(p_index)
                          ,p_default_attributes => 'Y');

        p_header_rec.price_list_id(p_index) := nvl(p_header_rec.price_list_id(p_index)
                              ,OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).price_list_id);
        p_header_rec.payment_term_id(p_index) := nvl(p_header_rec.payment_term_id(p_index)
                              ,OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).payment_term_id);
        p_header_rec.accounting_rule_id(p_index) := nvl(p_header_rec.accounting_rule_id(p_index)
                              ,OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).accounting_rule_id);
        p_header_rec.invoicing_rule_id(p_index) := nvl(p_header_rec.invoicing_rule_id(p_index)
                              ,OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).invoicing_rule_id);

        -- Invalid agreement - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Agreement cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     -- Default attributes that have ship to as the first source
     -- or is the next source after agreement.

     oe_debug_pub.add('load ship to cache');
     IF p_header_rec.ship_to_org_id(p_index) IS NOT NULL
        AND ( p_header_rec.fob_point_code(p_index) IS NULL
             OR p_header_rec.freight_terms_code(p_index) IS NULL
             OR p_header_rec.demand_class_code(p_index) IS NULL
             OR p_header_rec.shipping_method_code(p_index) IS NULL
             OR p_header_rec.ship_tolerance_above(p_index) IS NULL
             OR p_header_rec.ship_tolerance_below(p_index) IS NULL
             OR p_header_rec.latest_schedule_limit(p_index) IS NULL
             OR p_header_rec.order_date_type_code(p_index) IS NULL )
     THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Ship_To
                          (p_key => p_header_rec.ship_to_org_id(p_index)
                          ,p_default_attributes => 'Y');

        p_header_rec.fob_point_code(p_index) := nvl(p_header_rec.fob_point_code(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).fob_point_code);
        p_header_rec.freight_terms_code(p_index) := nvl(p_header_rec.freight_terms_code(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).freight_terms_code);
        p_header_rec.demand_class_code(p_index) := nvl(p_header_rec.demand_class_code(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).demand_class_code);
        p_header_rec.shipping_method_code(p_index) := nvl(p_header_rec.shipping_method_code(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).shipping_method_code);
        p_header_rec.ship_tolerance_above(p_index) := nvl(p_header_rec.ship_tolerance_above(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).ship_tolerance_above);
        p_header_rec.ship_tolerance_below(p_index) := nvl(p_header_rec.ship_tolerance_below(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).ship_tolerance_below);
        p_header_rec.latest_schedule_limit(p_index) := nvl(p_header_rec.latest_schedule_limit(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).latest_schedule_limit);
        p_header_rec.order_date_type_code(p_index) := nvl(p_header_rec.order_date_type_code(p_index)
                              ,OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).order_date_type_code);

        -- Invalid ship to - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Ship To cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     -- Default attributes that have invoice to as the first source
     -- or is the next source after agreement, ship to.

     oe_debug_pub.add('load invoice to cache');
     IF p_header_rec.invoice_to_org_id(p_index) IS NOT NULL
        AND ( p_header_rec.price_list_id(p_index) IS NULL
             OR p_header_rec.payment_term_id(p_index) IS NULL )
     THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Invoice_To
                          (p_key => p_header_rec.invoice_to_org_id(p_index)
                          ,p_default_attributes => 'Y');

        p_header_rec.price_list_id(p_index) := nvl(p_header_rec.price_list_id(p_index)
                              ,OE_Bulk_Cache.G_INVOICE_TO_TBL(l_c_index).price_list_id);
        p_header_rec.payment_term_id(p_index) := nvl(p_header_rec.payment_term_id(p_index)
                              ,OE_Bulk_Cache.G_INVOICE_TO_TBL(l_c_index).payment_term_id);

        -- Invalid invoice to - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Invoice to cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     -- Default remaining attributes from order type

     IF p_header_rec.order_type_id(p_index) IS NOT NULL
        AND (p_header_rec.fob_point_code(p_index) IS NULL
             OR p_header_rec.freight_terms_code(p_index) IS NULL
             OR p_header_rec.demand_class_code(p_index) IS NULL
             OR p_header_rec.shipping_method_code(p_index) IS NULL
             OR p_header_rec.shipment_priority_code(p_index) IS NULL
             OR p_header_rec.accounting_rule_id(p_index) IS NULL
             OR p_header_rec.invoicing_rule_id(p_index) IS NULL 
             OR p_header_rec.conversion_type_code(p_index) IS NULL )
     THEN

        BEGIN

        l_c_index := OE_Bulk_Cache.Load_Order_Type
                          (p_key => p_header_rec.order_type_id(p_index)
                          ,p_default_attributes => 'Y');

        p_header_rec.accounting_rule_id(p_index) := nvl(p_header_rec.accounting_rule_id(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).accounting_rule_id);
        p_header_rec.invoicing_rule_id(p_index) := nvl(p_header_rec.invoicing_rule_id(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).invoicing_rule_id);
        p_header_rec.fob_point_code(p_index) := nvl(p_header_rec.fob_point_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).fob_point_code);
        p_header_rec.freight_terms_code(p_index) := nvl(p_header_rec.freight_terms_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).freight_terms_code);
        p_header_rec.demand_class_code(p_index) := nvl(p_header_rec.demand_class_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).demand_class_code);
        p_header_rec.shipping_method_code(p_index) := nvl(p_header_rec.shipping_method_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).shipping_method_code);
        p_header_rec.shipment_priority_code(p_index) := nvl(p_header_rec.shipment_priority_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).shipment_priority_code);
        p_header_rec.conversion_type_code(p_index) := nvl(p_header_rec.conversion_type_code(p_index)
                              ,OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).conversion_type_code);

        -- Invalid order type - error message populated during validation
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('Order Type cache returns no data found');
            x_return_status := FND_API.G_RET_STS_ERROR;
        END;

     END IF;

     -- Constant Value Defaults

     IF p_header_rec.pricing_date(p_index) IS NULL THEN
        p_header_rec.pricing_date(p_index) := sysdate;
     END IF;

     IF p_header_rec.ordered_date(p_index) IS NULL THEN
        p_header_rec.ordered_date(p_index) := sysdate;
     END IF;

     IF p_header_rec.request_date(p_index) IS NULL THEN
        p_header_rec.request_date(p_index) := sysdate;
     END IF;

     IF p_header_rec.tax_exempt_flag(p_index) IS NULL THEN
        p_header_rec.tax_exempt_flag(p_index) := 'S';      -- 'Standard'
     END IF;

EXCEPTION
  WHEN OTHERS THEN
    IF oe_bulk_msg_pub.check_msg_level(oe_bulk_msg_pub.G_MSG_LVL_UNEXP_ERROR)
    THEN
       oe_bulk_msg_pub.add_exc_msg
       (   G_PKG_NAME
        ,   'Default_Record'
        );
    END IF;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Default_Record;

PROCEDURE Populate_Internal_Fields
     (p_header_rec      IN  OUT NOCOPY OE_Bulk_Order_Pvt.HEADER_REC_TYPE
     ,p_index           IN  NUMBER
     ,x_return_status   OUT VARCHAR2
     )
IS
l_c_index            NUMBER;
l_set_of_books_rec   OE_Order_Cache.Set_of_Books_Rec_Type;
l_is_fixed_rate      VARCHAR2(1);
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN

   -- Header_ID is pre-generated and read from interface tables
   -- This is to reduce DB block contention as sequential ids will
   -- be assigned to each parallel thread by master import program.
   -- (Refer OEBVIMNB.pls)
 
   BEGIN
      If l_debug_level > 0 Then
            oe_debug_pub.add('Insider Populate_Internal_Fields : ');
      End If;

   l_c_index := OE_Bulk_Cache.Load_Order_Type
                       (p_key => p_header_rec.order_type_id(p_index));
      If l_debug_level > 0 Then
            oe_debug_pub.add('after OE_Bulk_Cache.Load_Order_Type : ');
      End If;

   IF OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).order_category_code
      = 'RETURN' 
   THEN
      FND_MESSAGE.SET_NAME('ONT','OE_BULK_NOT_SUPP_RETURN');
      oe_bulk_msg_pub.Add('Y', 'ERROR');
      x_return_status := FND_API.G_RET_STS_ERROR;
   ELSE
      p_header_rec.order_category_code(p_index) := OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).order_category_code;
   END IF;

   -- Invalid order type - error message populated during validation
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       oe_debug_pub.add('Order Type cache returns no data found');
       -- Set order category for insert to succeed
       p_header_rec.order_category_code(p_index) := 'ORDER';
       x_return_status := FND_API.G_RET_STS_ERROR;
   END;

   IF p_header_rec.shipping_method_code(p_index) IS NOT NULL
      AND p_header_rec.ship_from_org_id(p_index) IS NOT NULL
   THEN
      If l_debug_level > 0 Then
            oe_debug_pub.add('Before Get Freight Carrier');
      End If;
      p_header_rec.freight_carrier_code(p_index) := 
          Get_Freight_Carrier
          (p_shipping_method_code  => p_header_rec.shipping_method_code(p_index)
           ,p_ship_from_org_id     => p_header_rec.ship_from_org_id(p_index)
          );
      If l_debug_level > 0 Then
            oe_debug_pub.add('After Get Freight Carrier');
      End If;
   END IF;

   l_set_of_books_rec :=  OE_Order_Cache.Load_Set_Of_Books;
   IF p_header_rec.transactional_curr_code(p_index) 
      <> l_set_of_books_rec.currency_code
   THEN

      l_Is_Fixed_Rate :=  
         GL_CURRENCY_API.IS_FIXED_RATE(
           p_header_rec.transactional_curr_code(p_index),
           l_set_of_books_rec.currency_code,
	   nvl(p_header_rec.Ordered_Date(p_index),Sysdate));

      IF (L_Is_Fixed_Rate = 'Y') THEN
	  p_header_rec.Conversion_Type_Code(p_index) := 'EMU FIXED';
      END IF;

   END IF;

   -- QUOTING changes
   -- Version number should be initialized to 0 starting 11i10
   IF p_header_rec.version_number(p_index) IS NULL THEN
      IF OE_Code_Control.Get_Code_Release_Level >= '110510' THEN
         p_header_rec.version_number(p_index) := 0;
      ELSE
         p_header_rec.version_number(p_index) := 1;
      END IF;
   END IF;

EXCEPTION
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
  WHEN OTHERS THEN
    oe_debug_pub.add('others errors, Populate_Internal_Fields');
    oe_debug_pub.add(substr(sqlerrm,1,200));
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF oe_bulk_msg_pub.check_msg_level(oe_bulk_msg_pub.G_MSG_LVL_UNEXP_ERROR)
    THEN
       oe_bulk_msg_pub.add_exc_msg
       (   G_PKG_NAME
        ,   'Populate_Internal_Fields'
        );
    END IF;
END Populate_Internal_Fields;

-----------------------------------------------------------------------
-- PUBLIC PROCEDURES/FUNCTIONS
-----------------------------------------------------------------------

FUNCTION Get_Freight_Carrier
  (p_shipping_method_code   IN VARCHAR2
  ,p_ship_from_org_id       IN VARCHAR2
  )
RETURN VARCHAR2
IS
  l_freight_code VARCHAR2(80);
BEGIN

  IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110509' THEN

    SELECT freight_code
    INTO   l_freight_code
    FROM   wsh_carriers wsh_ca,wsh_carrier_services wsh,
           wsh_org_carrier_services wsh_org
    WHERE  wsh_org.organization_id   = p_ship_from_org_id
      AND  wsh.carrier_service_id    = wsh_org.carrier_service_id
      AND  wsh_ca.carrier_id         = wsh.carrier_id
      AND  wsh.ship_method_code      = p_shipping_method_code
      AND  wsh_org.enabled_flag='Y';
  ELSE

    SELECT freight_code
    INTO l_freight_code
    FROM wsh_carrier_ship_methods
    WHERE ship_method_code = p_shipping_method_code
      AND ORGANIZATION_ID = p_ship_from_org_id;

  END IF;

  RETURN l_freight_code;

EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN NULL;
WHEN OTHERS THEN
  IF oe_bulk_msg_pub.check_msg_level (oe_bulk_msg_pub.G_MSG_LVL_UNEXP_ERROR)
  THEN
    oe_bulk_msg_pub.add_exc_msg
    ( G_PKG_NAME
     ,'Get_Freight_Carrier'
     );
  END IF;
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Freight_Carrier;

--
-- This FUNCTION is used for all agreement related validations.
--

FUNCTION Validate_Agreement
  (p_agreement_id         IN NUMBER
  ,p_pricing_date         IN DATE
  ,p_price_list_id        IN NUMBER
  ,p_sold_to_org_id       IN NUMBER
  )
RETURN BOOLEAN
IS
  l_c_index          NUMBER;
BEGIN

   -- Load agreement in the cache
   l_c_index := OE_Bulk_Cache.Load_Agreement(p_agreement_id);

   -- Verify that agreement is effective for the valid dates
   IF NOT trunc(nvl(p_pricing_date,sysdate))
      BETWEEN trunc(nvl(OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).start_date_active
                             ,add_months(sysdate,-10000)))
              AND trunc(nvl(OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).end_date_active
                             ,add_months(sysdate,+10000)))
   THEN

      fnd_message.set_name('ONT', 'ONT_INVALID_AGREEMENT');
      fnd_message.set_Token('AGREEMENT_NAME',
               OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).name);
      fnd_message.set_Token('REVISION',
               OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).revision);
      oe_bulk_msg_pub.Add('Y', 'ERROR');

      RETURN FALSE;

   END IF;

   -- Verify that price list on header matches price list on agreement
   IF p_price_list_id IS NOT NULL 
      AND Get_Price_List_Type(p_price_list_id) <> 'PRL'
   THEN

     IF (OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).price_list_id
         <> p_price_list_id) THEN

        fnd_message.set_name('ONT', 'OE_INVALID_AGREEMENT_PLIST');
        fnd_message.set_Token('AGREEMENT_NAME',
            OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).name);
        fnd_message.set_Token('PRICE_LIST1',
            OE_Bulk_Cache.G_PRICE_LIST_TBL(p_price_list_id).name);
        fnd_message.set_Token('PRICE_LIST2',
            OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).price_list_id);
        oe_bulk_msg_pub.Add('Y', 'ERROR');

        RETURN FALSE;

     END IF;
 
   END IF;

   -- Verify that customer on agreement matches the customer on order or
   -- is a related customer if customer relationships is ON.
   IF NOT OE_GLOBALS.EQUAL
            (OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).sold_to_org_id
            ,p_sold_to_org_id)
   THEN

      IF OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'N'
         OR (OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'Y' 
             AND NOT Is_Related_Customer(p_sold_to_org_id
                      ,OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).sold_to_org_id))
      THEN

        fnd_message.set_name('ONT', 'OE_INVALID_AGREEMENT');
        fnd_message.set_Token('AGREEMENT_ID',p_agreement_id);
        fnd_message.set_Token('AGREEMENT_NAME',
                OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).name);
        fnd_message.set_Token('CUSTOMER_ID',
                OE_Bulk_Cache.G_AGREEMENT_TBL(l_c_index).sold_to_org_id);
        oe_bulk_msg_pub.Add('Y', 'ERROR');

        RETURN FALSE;

      END IF;

   END IF;

   RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Validate_Agreement;


-- This FUNCTION consists of all price list related validations.

FUNCTION Validate_Price_List
  (p_price_list_id      IN NUMBER
  ,p_curr_code          IN VARCHAR2
  ,p_pricing_date       IN DATE
  ,p_calculate_price    IN VARCHAR2
  )
RETURN BOOLEAN
IS

  l_validate_result         VARCHAR2(1);
  l_c_index                 NUMBER;

BEGIN

   -- For order header, this check is NOT needed if any one line exists
   -- with calculate_price_flag of 'N' or 'P' - where to do this?

   -- For line, price list validations not needed if calculate price is 
   -- frozen or partial

   IF p_calculate_price IN ('P','N') THEN
      RETURN TRUE;
   END IF;

   -- Cache price list

   l_c_index := OE_Bulk_Cache.Load_Price_List(p_price_list_id);

   -- Verify that price list is effective for the valid dates

   IF NOT trunc(nvl(p_pricing_date,sysdate))
          BETWEEN trunc(nvl(OE_Bulk_Cache.G_PRICE_LIST_TBL(l_c_index).start_date_active
                              ,add_months(sysdate,-10000)))
              AND  trunc(nvl(OE_Bulk_Cache.G_PRICE_LIST_TBL(l_c_index).end_date_active
                               ,add_months(sysdate,+10000)))
   THEN

      fnd_message.set_name('ONT', 'OE_INVALID_NONAGR_PLIST');
      fnd_message.set_Token('PRICE_LIST1', p_price_list_id);
      fnd_message.set_Token('PRICING_DATE', p_pricing_date);
      oe_bulk_msg_pub.Add('Y', 'ERROR');
   
      RETURN FALSE;

   END IF;

   -- Validate currency against the price list 

   QP_UTIL_PUB.Validate_Price_list_Curr_code(p_price_list_id
                           ,p_curr_code
                           ,p_pricing_date
                           ,l_validate_result);

   IF l_validate_result = 'N' THEN 

      FND_MESSAGE.SET_NAME('ONT','OE_CURRENCY_MISMATCH');
      FND_MESSAGE.SET_TOKEN('LINE_CURR_CODE',
          OE_Bulk_Cache.G_PRICE_LIST_TBL(l_c_index).currency_code);
      FND_MESSAGE.SET_TOKEN('PRICE_LIST_NAME',
          OE_Bulk_Cache.G_PRICE_LIST_TBL(l_c_index).name);
      FND_MESSAGE.SET_TOKEN('HEADER_CURR_CODE',p_curr_code);
      oe_bulk_msg_pub.Add('Y', 'ERROR');

      RETURN FALSE;

   END IF;

   RETURN TRUE;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     oe_debug_pub.add('no data found in validate price list');
     RETURN FALSE;
END Validate_Price_List;


FUNCTION Validate_Ship_to(p_sold_to IN  NUMBER,
                          p_Ship_to IN  NUMBER)
RETURN BOOLEAN
IS
  l_dummy       VARCHAR2(10);
  l_c_index     NUMBER;
BEGIN

  --
  -- Validations here account for all customer relationships
  --
  -- If ship_to_org_id is not valid for any customer,
  -- then Cache FUNCTION Load_<Entity> will raise no data found
  -- so for all relationship values including G_CUST_RELATIONS = 'A'
  -- , it will return FALSE.
  --
  -- If customer relationships = 'N' but customer does not match 
  -- ship to customer, it will return FALSE.
  --
  -- If customer relationships = 'Y', it will also check if ship 
  -- to customer is a related customer and if not, return FALSE.
  --
 
  l_c_index := OE_Bulk_Cache.Load_Ship_To
                    (p_key          => p_ship_to);

  IF OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).customer_id 
      = p_sold_to
  THEN
     RETURN TRUE;
  END IF;

  IF OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'N' THEN

     RETURN FALSE;

  ELSIF OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'Y' THEN

     SELECT 'VALID'
       INTO l_dummy
       FROM HZ_CUST_ACCT_RELATE
      WHERE RELATED_CUST_ACCOUNT_ID = p_sold_to
        AND CUST_ACCOUNT_ID = OE_Bulk_Cache.G_SHIP_TO_TBL(l_c_index).customer_id
        AND ship_to_flag = 'Y' AND STATUS='A';

  END IF;

  RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Validate_Ship_to;

--abghosh

FUNCTION Validate_Sold_to_site(p_sold_to IN  NUMBER,
                          p_Sold_to_site_use_id IN  NUMBER)
RETURN BOOLEAN
IS
  l_dummy       VARCHAR2(10);
  l_c_index     NUMBER;
BEGIN

  --
  --
  -- If sold_to_site_use_id is not valid for any customer,
  -- then Cache FUNCTION Load_<Entity> will raise no data found
  -- , it will return FALSE.
  --
  --
  --
 
  l_c_index := OE_Bulk_Cache.Load_Sold_to_site
                    (p_key          => p_sold_to_site_use_id);

  IF OE_Bulk_Cache.G_SOLD_TO_SITE_TBL(l_c_index).customer_id 
      = p_sold_to
  THEN
     RETURN TRUE;
  ELSE 
     RETURN FALSE;
  END IF;


EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Validate_Sold_to_site;


FUNCTION Validate_Bill_to(p_sold_to IN NUMBER,
                          p_bill_to IN NUMBER)
RETURN BOOLEAN
IS
  l_dummy       VARCHAR2(10);
  l_c_index     NUMBER;
BEGIN

  --
  -- Validations here account for all customer relationships
  --
  -- If invoice_to_org_id is not valid for any customer,
  -- then Cache FUNCTION Load_<Entity> will raise no data found
  -- so for all relationship values including G_CUST_RELATIONS = 'A'
  -- , it will return FALSE.
  --
  -- If customer relationships = 'N' but customer does not match 
  -- invoice to customer, it will return FALSE.
  --
  -- If customer relationships = 'Y', it will also check if invoice
  -- to customer is a related customer and if not, return FALSE.
  --
 
  l_c_index := OE_Bulk_Cache.Load_Invoice_To
                    (p_key          => p_bill_to);

  IF OE_Bulk_Cache.G_INVOICE_TO_TBL(l_c_index).customer_id 
      = p_sold_to
  THEN
     RETURN TRUE;
  END IF;

  IF OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'N' THEN

     RETURN FALSE;

  ELSIF OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'Y' THEN

     SELECT 'VALID'
       INTO l_dummy
       FROM HZ_CUST_ACCT_RELATE
      WHERE RELATED_CUST_ACCOUNT_ID = p_sold_to
        AND CUST_ACCOUNT_ID = OE_Bulk_Cache.G_INVOICE_TO_TBL(l_c_index).customer_id
        AND bill_to_flag = 'Y' AND STATUS='A';

  END IF;

  RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Validate_Bill_to;


FUNCTION Validate_Deliver_to(p_sold_to IN NUMBER,
                             p_deliver_to IN NUMBER)
RETURN BOOLEAN
IS
l_dummy VARCHAR2(10);
BEGIN

  IF (OE_Bulk_Order_Pvt.G_CUST_RELATIONS = 'N') THEN

     SELECT 'VALID'
        INTO   l_dummy
        FROM   oe_deliver_to_orgs_v
        WHERE  customer_id = p_sold_to
        AND    site_use_id = p_deliver_to
        AND    status = 'A';

  ELSE

     SELECT 'VALID'
       INTO l_dummy
       FROM oe_deliver_to_orgs_v
      WHERE site_use_id = p_deliver_to
        AND    status = 'A'
        AND customer_id IN (
                    Select p_sold_to from dual
                    union
                    SELECT CUST_ACCOUNT_ID
                    FROM HZ_CUST_ACCT_RELATE
                    WHERE RELATED_CUST_ACCOUNT_ID = p_sold_to
                      AND ship_to_flag = 'Y' AND STATUS ='A'
                    );

  END IF;

     return TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     return FALSE;

END Validate_Deliver_to;


-- Validate that contact is valid for given (site)customer and usage.
-- Validate Active status, since contact does NOT go thru attribute
-- validation.

FUNCTION Validate_Site_Contact
  (p_site_use_id       IN NUMBER
  ,p_contact_id        IN NUMBER
  )
RETURN BOOLEAN
IS
  l_dummy VARCHAR2(10);
BEGIN

    SELECT  'VALID'
      INTO  l_dummy
      FROM  HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
            HZ_CUST_SITE_USES SITE,
            HZ_CUST_ACCT_SITES  ADDR
     WHERE  ACCT_ROLE.CUST_ACCOUNT_ROLE_ID = p_contact_id
       AND  ACCT_ROLE.CUST_ACCOUNT_ID = ADDR.CUST_ACCOUNT_ID
       AND  ACCT_ROLE.ROLE_TYPE = 'CONTACT'
       AND  ADDR.CUST_ACCT_SITE_ID = SITE.CUST_ACCT_SITE_ID
       AND  SITE.SITE_USE_ID  = p_site_use_id
       AND  SITE.STATUS = 'A'
       AND  ACCT_ROLE.STATUS = 'A'
       AND  ADDR.STATUS ='A' ;-- added for bug 2752321

     RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN FALSE;
END Validate_Site_Contact; 


---------------------------------------------------------------------
-- PROCEDURE Entity
--
-- Main processing procedure used to process headers in a batch.
-- IN parameters -
-- p_header_rec : order headers in this batch
-- p_defaulting_mode : 'Y' if fixed defaulting is needed, 'N' if
-- defaulting is to be completely bypassed
-- OUT parameters -
-- x_header_scredit_rec : sales credits for headers processed
--
-- Processing steps include:
-- 1. Restricted defaulting on p_header_rec if defaulting_mode is 'Y'
-- 2. Populate all internal fields on p_header_rec 
-- 3. All entity validations
-- 4. Other misc processing like holds evaluation, sales credits.
---------------------------------------------------------------------

PROCEDURE Entity 
( p_header_rec             IN OUT NOCOPY OE_Bulk_Order_Pvt.HEADER_REC_TYPE
, x_header_scredit_rec     IN OUT NOCOPY OE_Bulk_Order_Pvt.SCREDIT_REC_TYPE
, p_defaulting_mode        IN VARCHAR2
, p_validate_desc_flex     IN VARCHAR2
)
IS

  ctr                     NUMBER;
  error_count             NUMBER := 0;
  l_dummy                 VARCHAR2(10);
  l_return_status         VARCHAR2(30);
  l_c_index               NUMBER;
  l_order_type_id         NUMBER;
  l_on_generic_hold       BOOLEAN;
  l_on_booking_hold       BOOLEAN;
  l_on_scheduling_hold    BOOLEAN;
  l_scredit_index         NUMBER := 1;
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN

   ctr := p_header_rec.header_id.COUNT;

   FOR i IN 1..ctr LOOP

      -- Set Context for messags
  
     oe_bulk_msg_pub.set_msg_context
        ( p_entity_code                 => 'HEADER'
         ,p_entity_id                   => p_header_rec.header_id(i)
         ,p_header_id                   => p_header_rec.header_id(i)
         ,p_line_id                     => null
         ,p_orig_sys_document_ref       => p_header_rec.orig_sys_document_ref(i)
         ,p_orig_sys_document_line_ref  => null
         ,p_order_source_id             => p_header_rec.order_source_id(i)
         ,p_source_document_type_id     => null
         ,p_source_document_id          => null
         ,p_source_document_line_id     => null);

      --PIB
        IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
          p_header_rec.header_index.extend(1);
          p_header_rec.header_index(i) := i;
          p_header_rec.event_code.extend(1);
          IF p_header_rec.booked_flag(i) = 'Y' THEN
            p_header_rec.event_code(i) := 'BATCH,BOOK';
          ELSE
            p_header_rec.event_code(i) := 'BATCH';
          END IF;
          If l_debug_level > 0 Then
            oe_debug_pub.add('event code : '||p_header_rec.event_code(i));
          End If;
        END IF;
      --PIB

      ---------------------------------------------------------
      -- CALL THE FIXED DEFAULTING PROCEDURE IF NEEDED
      ---------------------------------------------------------

      IF p_defaulting_mode = 'Y' THEN

         Default_Record
              ( p_header_rec         => p_header_rec
               ,p_index              => i
               ,x_return_status      => l_return_status
               );

         IF l_return_status = FND_API.G_RET_STS_ERROR THEN
            p_header_rec.lock_control(i) := -99;
         ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

      END IF;

      ---------------------------------------------------------
      -- POPULATE INTERNAL FIELDS 
      -- Hardcoded Defaulting From OEXDHDRB.pls
      ---------------------------------------------------------

      If l_debug_level > 0 Then
            oe_debug_pub.add('Calling Populate_Internal_Fields : ');
      End If;
      Populate_Internal_Fields
        ( p_header_rec         => p_header_rec
         ,p_index              => i
         ,x_return_status      => l_return_status
         );
      If l_debug_level > 0 Then
            oe_debug_pub.add(' After Calling Populate_Internal_Fields : ');
      End If;

      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         p_header_rec.lock_control(i) := -99;
      ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;


      ---------------------------------------------------------
      -- START ENTITY VALIDATIONS
      ---------------------------------------------------------

      -- Validate Required Attributes

      -- Order Type is required                     

      IF (p_header_rec.order_type_id(i) IS NOT NULL) THEN

      If l_debug_level > 0 Then
            oe_debug_pub.add(' Validating Order Type : ');
      End If;
         l_order_type_id := p_header_rec.order_type_id(i);

         -- Get Order Number - will return FALSE IF
         -- 1. Doc Sequence type is 'Manual' and order number not specified
         -- 2. If gapless sequence
         -- Error messages are populated in Get_Order_Number

         IF NOT Get_order_number(p_header_rec.order_type_id(i),
                                 p_header_rec.order_number(i)) THEN 

            p_header_rec.lock_control(i) := -99;

            -- Order Number is a required column hence put a dummy value
            -- for the insert to succeed.
            p_header_rec.order_number(i) := -1 * p_header_rec.header_id(i);
                         
         END IF;
      If l_debug_level > 0 Then
            oe_debug_pub.add(' After getting order number  ');
      End If;
                          
         -- Do other order type related validations

         -- Cache order type, if order type is not valid caching will fail
         -- with no data found error.
         l_c_index := OE_Bulk_Cache.Load_Order_Type
                         (p_key   => l_order_type_id);

         -- Check if Order Type is valid for ordered date
         
         IF p_header_rec.ordered_date(i) IS NOT NULL
            AND NOT (p_header_rec.ordered_date(i) BETWEEN
                     nvl(OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_order_type_id).start_date_active,sysdate)
                     AND nvl(OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_order_type_id).end_date_active,sysdate))
         THEN
             p_header_rec.lock_control(i) := -99;
             FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
             FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                  OE_Order_Util.Get_Attribute_Name('ORDER_TYPE_ID'));
             oe_bulk_msg_pub.Add('Y', 'ERROR');
         END IF;
      If l_debug_level > 0 Then
            oe_debug_pub.add(' After validating Ordered Date - Order Type ');
      End If;

          -- Validate that Order Type has valid WF assignment

         IF NOT OE_BULK_WF_UTIL.Validate_OT_WF_Assignment
                          (p_header_rec.order_type_id(i)
                           ,p_header_rec.wf_process_name(i)) THEN
            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_MISS_FLOW');
            oe_bulk_msg_pub.Add('Y', 'ERROR');
         END IF;

      If l_debug_level > 0 Then
            oe_debug_pub.add(' After validating WF Assignment ');
      End If;
         -- Populate order type name, this is denormalized onto header
         -- record as it will be used in insert into mtl_sales_orders

         p_header_rec.order_type_name(i) := 
                  OE_Bulk_Cache.G_ORDER_TYPE_TBL(l_c_index).NAME;
         
      ELSE 
         
         p_header_rec.lock_control(i) := -99;
         FND_MESSAGE.SET_NAME('ONT','OE_ATTRIBUTE_REQUIRED');
         FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
            OE_Order_UTIL.Get_Attribute_Name('ORDER_TYPE_ID'));
         oe_bulk_msg_pub.Add('Y', 'ERROR');

         -- To avoid Insert failure, populate not null column.
         -- This record will be deleted later.

         p_header_rec.order_type_id(i) := -99;
         
      END IF;  -- Order Type is not null


      -- Check that Transactional currency exists
      -- If it does validate Price List currency against it.

      IF (p_header_rec.transactional_curr_code(i) IS NULL) THEN

         p_header_rec.lock_control(i) := -99;

         -- To avoid Insert failure, populate not null column.
         -- This record will be deleted later.
         p_header_rec.transactional_curr_code(i) := '-99';

         FND_MESSAGE.SET_NAME('ONT','OE_ATTRIBUTE_REQUIRED');
         FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
            OE_Order_UTIL.Get_Attribute_Name('TRANSACTIONAL_CURR_CODE'));
         oe_bulk_msg_pub.Add('Y', 'ERROR');

      END IF;
      If l_debug_level > 0 Then
        oe_debug_pub.add(' After validating curr ');
      End If;


      -- Price List Validations

      IF  (p_header_rec.price_list_id(i) IS NOT NULL) THEN

        IF NOT Validate_Price_List(p_header_rec.price_list_id(i)
                 ,p_header_rec.transactional_curr_code(i)
                 ,p_header_rec.pricing_date(i)
                 ,'Y'
                 ) 
        THEN
                
          p_header_rec.lock_control(i) := -99 ;

        END IF;

      END IF;

      If l_debug_level > 0 Then
        oe_debug_pub.add(' After validating Price List ');
      End If;

      -- Conversion rate, date should be null when conversion type is null.

      IF (p_header_rec.conversion_type_code(i) IS NULL) THEN
           IF p_header_rec.conversion_rate(i) IS NOT NULL
              OR p_header_rec.conversion_rate_date(i) IS NOT NULL
           THEN
               p_header_rec.lock_control(i) := -99;
               FND_MESSAGE.SET_NAME('ONT','OE_VAL_CONVERSION_TYPE');
               oe_bulk_msg_pub.Add('Y', 'ERROR');
           END IF;
      END IF;

     -- Conversion rate and date must be Null if coversion type is not User

   IF p_header_rec.conversion_type_code(i) <> 'User' AND
        (p_header_rec.conversion_rate(i) IS NOT NULL OR
         p_header_rec.conversion_rate_date(i) IS NOT NULL)
     THEN
        l_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.SET_NAME('ONT','OE_VALIDATION_CONV_TYPE');
        OE_MSG_PUB.ADD;

   END IF; -- END of checks based on conversion type


      -- Agreement related validations 

      IF  (p_header_rec.agreement_id(i) IS NOT NULL) THEN

        -- Error messages are populated in Validate_Agreement

        IF NOT Validate_Agreement(p_header_rec.agreement_id(i)
                         ,p_header_rec.pricing_date(i)
                         ,p_header_rec.price_list_id(i)
                         ,p_header_rec.sold_to_org_id(i)
                         ) 
        THEN

             p_header_rec.lock_control(i) := -99;
              
         END IF;

      END IF;

       
      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before sold to contact validation ');
      End If;
      -- BEGIN: Site, Contact Validations

      -- Validate Sold-to Contact
      -- Validate Active status, since contact does go thru attribute
      -- validation.
      IF (p_header_rec.sold_to_contact_id(i) IS NOT NULL) THEN
         BEGIN

           SELECT  'VALID'
           INTO  l_dummy
           FROM  HZ_CUST_ACCOUNT_ROLES ACCT_ROLE
           WHERE  ACCT_ROLE.CUST_ACCOUNT_ROLE_ID = p_header_rec.sold_to_contact_id(i)
             AND  ACCT_ROLE.CUST_ACCOUNT_ID = p_header_rec.sold_to_org_id(i)
             AND  ROWNUM = 1
             AND  ACCT_ROLE.ROLE_TYPE = 'CONTACT'
             AND  STATUS = 'A';

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             p_header_rec.lock_control(i) := -99;
             FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
             FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                       OE_Order_Util.Get_Attribute_Name('SOLD_TO_CONTACT_ID'));
             oe_bulk_msg_pub.Add('Y', 'ERROR');
         END;
      END IF; -- End sold to contact validation

      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Bill To validation ');
      End If;
      -- Validate Bill-to for customer
      IF (p_header_rec.invoice_to_org_id(i) IS NOT NULL) THEN

          IF NOT Validate_Bill_To(p_header_rec.sold_to_org_id(i),
                                     p_header_rec.invoice_to_org_id(i)) 
          THEN

             p_header_rec.lock_control(i) := -99;
             FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
             FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                 OE_Order_Util.Get_Attribute_Name('invoice_to_org_id'));
             oe_bulk_msg_pub.Add('Y', 'ERROR');

          END IF;

      END IF; -- Invoice to is not null

      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Ship To validation ');
      End If;
      -- Validate Ship To for customer
      IF (p_header_rec.ship_to_org_id(i) IS NOT NULL) THEN

         IF NOT Validate_Ship_To(p_header_rec.sold_to_org_id(i),
                                 p_header_rec.ship_to_org_id(i)) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('SHIP_TO_ORG_ID'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

          END IF;

      END IF; -- Ship to is not null

      --abghosh
      -- Validate sold_to_site_use_id for customer
      IF (p_header_rec.sold_to_site_use_id(i) IS NOT NULL) THEN

         IF NOT Validate_Sold_to_site(p_header_rec.sold_to_org_id(i),
                                 p_header_rec.sold_to_site_use_id(i)) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('SOLD_TO_SITE_USE_ID'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

          END IF;

      END IF;
    -- end customer

      IF (p_header_rec.end_Customer_id(i) IS NOT NULL) THEN
		    IF NOT Validate_End_Customer( p_header_rec.end_Customer_id(i)) THEN
	       p_header_rec.lock_control(i) := -99;
	       FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
	       FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('end_customer_id'));
	       oe_bulk_msg_pub.Add('Y', 'ERROR');
	    END IF;
	 End IF;
	 
	 IF (p_header_rec.end_Customer_contact_id(i) IS NOT NULL) THEN
	    IF NOT Validate_End_Customer_contact( p_header_rec.end_Customer_contact_id(i)) THEN
		  p_header_rec.lock_control(i) := -99;
		  FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
		  FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('end_customer_contact_id'));
		  oe_bulk_msg_pub.Add('Y', 'ERROR');
	       END IF;
	    END IF;
	    
	    IF (p_header_rec.end_Customer_site_use_id(i) IS NOT NULL) THEN
	       IF NOT Validate_End_Customer_site_use(p_header_rec.end_Customer_site_use_id(i),p_header_rec.end_customer_id(i)) THEN
		      p_header_rec.lock_control(i) := -99;
		      FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
		      FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('end_customer_site_use_id'));
		      oe_bulk_msg_pub.Add('Y', 'ERROR');
		   END IF;
		END IF; 
		
		IF (p_header_rec.IB_owner(i) IS NOT NULL) THEN
		   IF NOT validate_IB_Owner(p_header_rec.IB_Owner(i)) THEN
		      p_header_rec.lock_control(i) := -99;
		      FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
			    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('IB_Owner'));
			    oe_bulk_msg_pub.Add('Y', 'ERROR');
			 END IF;
		      END IF;
		      
			IF (p_header_rec.IB_current_location(i) IS NOT NULL) THEN
			   IF NOT Validate_IB_current_location( p_header_rec.IB_current_Location(i)) THEN
				 p_header_rec.lock_control(i) := -99;
				 FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
				 FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('IB_location'));
				 oe_bulk_msg_pub.Add('Y', 'ERROR');
			      END IF;
                             END IF;
			     
			     IF (p_header_rec.IB_Installed_at_location(i) IS NOT NULL) THEN
				IF NOT Validate_IB_Inst_loc( p_header_rec.IB_Installed_at_location(i)) THEN
				   p_header_rec.lock_control(i) := -99;
				      FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
				      FND_MESSAGE.SET_TOKEN('ATTRIBUTE',OE_Order_Util.Get_Attribute_Name('end_customer_site_use_id'));
				      oe_bulk_msg_pub.Add('Y', 'ERROR');
				   END IF;
				END IF;

				
				-- Validate Deliver-to for customer
      IF (p_header_rec.deliver_to_org_id(i) IS NOT NULL) THEN

         IF NOT Validate_Deliver_To(p_header_rec.sold_to_org_id(i)
                         ,p_header_rec.deliver_to_org_id(i)) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('DELIVER_TO_ORG_ID'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

          END IF;

      END IF; -- deliver to is not null

      -- Validate Bill to contact
      IF (p_header_rec.invoice_to_contact_id(i) IS NOT NULL) THEN

         IF NOT Validate_Site_Contact(p_header_rec.invoice_to_org_id(i)
                      ,p_header_rec.invoice_to_contact_id(i)
                      ) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('invoice_to_contact_id'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

         END IF;

      END IF;

      -- Validate ship to contact
      IF (p_header_rec.ship_to_contact_id(i) IS NOT NULL) THEN

         IF NOT Validate_Site_Contact(p_header_rec.ship_to_org_id(i)
                      ,p_header_rec.ship_to_contact_id(i)
                      ) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('SHIP_TO_CONTACT_ID'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

         END IF;

      END IF;

      -- Validate deliver to contact
      IF (p_header_rec.deliver_to_contact_id(i) IS NOT NULL) THEN

         IF NOT Validate_Site_Contact(p_header_rec.deliver_to_org_id(i)
                      ,p_header_rec.deliver_to_contact_id(i)
                      ) 
         THEN

            p_header_rec.lock_control(i) := -99;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                OE_Order_Util.Get_Attribute_Name('DELIVER_TO_CONTACT_ID'));
            oe_bulk_msg_pub.Add('Y', 'ERROR');

         END IF;

      END IF;

      -- END: Site, Contact Validations
      

      -- BEGIN: Check for Tax Exemption attributes
      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Tax  validation ');
      End If;

      IF (p_header_rec.tax_exempt_flag(i) = 'E') THEN
          
           -- Tax exempt reason code is required
           IF (p_header_rec.tax_exempt_reason_code(i) IS NULL) THEN
               
               p_header_rec.lock_control(i) := -99; 
               FND_MESSAGE.SET_NAME('ONT','OE_ATTRIBUTE_REQUIRED');
               FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                      OE_Order_UTIL.Get_Attribute_Name('TAX_EXEMPT_REASON_CODE'));
               oe_bulk_msg_pub.Add('Y', 'ERROR');

           ELSIF NOT Valid_Tax_Exempt_Reason
                    (p_header_rec.tax_exempt_reason_code(i)) THEN

               p_header_rec.lock_control(i) := -99; 
               FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
               FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                      OE_Order_UTIL.Get_Attribute_Name('TAX_EXEMPT_REASON_CODE'));
               oe_bulk_msg_pub.Add('Y', 'ERROR');

           END IF;
      If l_debug_level > 0 Then
        oe_debug_pub.add(' After Tax  validation ');
      End If;

      ELSIF (p_header_rec.tax_exempt_flag(i) = 'R') THEN

          IF (p_header_rec.tax_exempt_number(i) IS NOT NULL)
             OR (p_header_rec.tax_exempt_reason_code(i) IS NOT NULL) 
          THEN
           
              p_header_rec.lock_control(i) := -99; 
              FND_MESSAGE.SET_NAME('ONT','OE_TAX_EXEMPTION_NOT_ALLOWED');
              oe_bulk_msg_pub.Add('Y', 'ERROR');

          END IF;

      -- Validate Tax Exempt # and reason for this customer and site
      ELSIF (p_header_rec.tax_exempt_flag(i) = 'S')
            AND (p_header_rec.tax_exempt_number(i) IS NOT NULL) 
            AND(p_header_rec.tax_exempt_reason_code(i) IS NOT NULL)
      THEN
          
         IF NOT Valid_Tax_Exemptions(p_header_rec.tax_exempt_number(i)
                          ,p_header_rec.tax_exempt_reason_code(i)
                          ,p_header_rec.ship_to_org_id(i)
                          ,p_header_rec.invoice_to_org_id(i)
                          ,p_header_rec.sold_to_org_id(i)
                          ,p_header_rec.request_date(i)
                          )
         THEN

              p_header_rec.lock_control(i) := -99;
              FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
              FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                  OE_Order_Util.Get_Attribute_Name('tax_exempt_number'));
              oe_bulk_msg_pub.Add('Y', 'ERROR');

         END IF;    

      END IF;

      -- END: Check for Tax Exemption attributes
      

      -- Duplicate PO Number Validation

      IF p_header_rec.cust_po_number(i) IS NOT NULL THEN

         IF OE_Validate_Header.Is_Duplicate_PO_Number
           (p_header_rec.cust_po_number(i)
           ,p_header_rec.sold_to_org_id(i)
           ,p_header_rec.header_id(i) 
           )
         THEN
           FND_MESSAGE.SET_NAME('ONT','OE_VAL_DUP_PO_NUMBER');
           oe_bulk_msg_pub.ADD;
         END IF;

       END IF;


      -- BEGIN: Desc Flex Validation

      IF p_validate_desc_flex = 'Y' THEN

      IF OE_Bulk_Order_Pvt.G_OE_HEADER_ATTRIBUTES = 'Y' THEN

         IF NOT OE_VALIDATE.Header_Desc_Flex
               (p_context            => p_header_rec.context(i)
               ,p_attribute1         => p_header_rec.attribute1(i)
               ,p_attribute2         => p_header_rec.attribute2(i)
               ,p_attribute3         => p_header_rec.attribute3(i)
               ,p_attribute4         => p_header_rec.attribute4(i)
               ,p_attribute5         => p_header_rec.attribute5(i)
               ,p_attribute6         => p_header_rec.attribute6(i)
               ,p_attribute7         => p_header_rec.attribute7(i)
               ,p_attribute8         => p_header_rec.attribute8(i)
               ,p_attribute9         => p_header_rec.attribute9(i)
               ,p_attribute10        => p_header_rec.attribute10(i)
               ,p_attribute11        => p_header_rec.attribute11(i)
               ,p_attribute12        => p_header_rec.attribute12(i)
               ,p_attribute13        => p_header_rec.attribute13(i)
               ,p_attribute14        => p_header_rec.attribute14(i)
               ,p_attribute15        => p_header_rec.attribute15(i)
               ,p_attribute16        => p_header_rec.attribute16(i)  -- for bug 2184255
               ,p_attribute17        => p_header_rec.attribute17(i)
               ,p_attribute18        => p_header_rec.attribute18(i)
               ,p_attribute19        => p_header_rec.attribute19(i)
               ,p_attribute20        => p_header_rec.attribute20(i))
             THEN
                 p_header_rec.lock_control(i) := -99;
                 -- Log Error Message
                 FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
                 FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                                       'Entity:Flexfield:Header_Desc_Flex');
                 oe_bulk_msg_pub.Add('Y', 'ERROR');
	  ELSE -- if the flex validation is successfull
	    -- For bug 2511313
	    IF p_header_rec.context(i) IS NULL 
	      OR p_header_rec.context(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.context(i)    := oe_validate.g_context;
	    END IF;
	    
	    IF p_header_rec.attribute1(i) IS NULL  
	      OR p_header_rec.attribute1(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute1(i) := oe_validate.g_attribute1;
	    END IF;
	    
	    IF p_header_rec.attribute2(i) IS NULL
	      OR p_header_rec.attribute2(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute2(i) := oe_validate.g_attribute2;
	    END IF;
	    
	    IF p_header_rec.attribute3(i) IS NULL
	      OR p_header_rec.attribute3(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute3(i) := oe_validate.g_attribute3;
	    END IF;
	    
	    IF p_header_rec.attribute4(i) IS NULL
	      OR p_header_rec.attribute4(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute4(i) := oe_validate.g_attribute4;
	    END IF;
	    
	    IF p_header_rec.attribute5(i) IS NULL
	      OR p_header_rec.attribute5(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute5(i) := oe_validate.g_attribute5;
	    END IF;
	    
	    IF p_header_rec.attribute6(i) IS NULL
	      OR p_header_rec.attribute6(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute6(i) := oe_validate.g_attribute6;
	    END IF;
	    
	    IF p_header_rec.attribute7(i) IS NULL
	      OR p_header_rec.attribute7(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute7(i) := oe_validate.g_attribute7;
	    END IF;
	    
	    IF p_header_rec.attribute8(i) IS NULL
	      OR p_header_rec.attribute8(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute8(i) := oe_validate.g_attribute8;
	    END IF;
	    
	    IF p_header_rec.attribute9(i) IS NULL
	      OR p_header_rec.attribute9(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute9(i) := oe_validate.g_attribute9;
	    END IF;
	    
	    IF p_header_rec.attribute10(i) IS NULL
	      OR p_header_rec.attribute10(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute10(i) := Oe_validate.G_attribute10;
	    End IF;
	    
	    IF p_header_rec.attribute11(i) IS NULL
	      OR p_header_rec.attribute11(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute11(i) := oe_validate.g_attribute11;
	    END IF;
	    
	    IF p_header_rec.attribute12(i) IS NULL
	      OR p_header_rec.attribute12(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute12(i) := oe_validate.g_attribute12;
	    END IF;
	    
	    IF p_header_rec.attribute13(i) IS NULL
	      OR p_header_rec.attribute13(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute13(i) := oe_validate.g_attribute13;
	    END IF;
	    
	    IF p_header_rec.attribute14(i) IS NULL
	      OR p_header_rec.attribute14(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute14(i) := oe_validate.g_attribute14;
	    END IF;
	    
	    IF p_header_rec.attribute15(i) IS NULL
	      OR p_header_rec.attribute15(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute15(i) := oe_validate.g_attribute15;
	    END IF;

	    IF p_header_rec.attribute16(i) IS NULL  -- For bug 2184255
	      OR p_header_rec.attribute16(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute16(i) := oe_validate.g_attribute16;
	    END IF;

	    IF p_header_rec.attribute17(i) IS NULL
	      OR p_header_rec.attribute17(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute17(i) := oe_validate.g_attribute17;
	    END IF;

	    IF p_header_rec.attribute18(i) IS NULL
	      OR p_header_rec.attribute18(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute18(i) := oe_validate.g_attribute18;
	    END IF;

	    IF p_header_rec.attribute19(i) IS NULL
	      OR p_header_rec.attribute19(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute19(i) := oe_validate.g_attribute19;
	    END IF;

	    IF p_header_rec.attribute20(i) IS NULL
	      OR p_header_rec.attribute20(i) = FND_API.G_MISS_CHAR THEN
	       p_header_rec.attribute20(i) := oe_validate.g_attribute20;
	    END IF;

	    -- end of assignments, bug 2511313

	 END IF;
      END IF;

      IF OE_Bulk_Order_Pvt.G_OE_HEADER_GLOBAL_ATTRIBUTE = 'Y' THEN

             IF NOT OE_VALIDATE.G_Header_Desc_Flex
              (p_context            => p_header_rec.global_attribute_category(i)
              ,p_attribute1         => p_header_rec.global_attribute1(i)
              ,p_attribute2         => p_header_rec.global_attribute2(i)
              ,p_attribute3         => p_header_rec.global_attribute3(i)
              ,p_attribute4         => p_header_rec.global_attribute4(i)
              ,p_attribute5         => p_header_rec.global_attribute5(i)
              ,p_attribute6         => p_header_rec.global_attribute6(i)
              ,p_attribute7         => p_header_rec.global_attribute7(i)
              ,p_attribute8         => p_header_rec.global_attribute8(i)
              ,p_attribute9         => p_header_rec.global_attribute9(i)
              ,p_attribute10        => p_header_rec.global_attribute10(i)
              ,p_attribute11        => p_header_rec.global_attribute11(i)
              ,p_attribute12        => p_header_rec.global_attribute12(i)
              ,p_attribute13        => p_header_rec.global_attribute13(i)
              ,p_attribute14        => p_header_rec.global_attribute13(i)
              ,p_attribute15        => p_header_rec.global_attribute14(i)
              ,p_attribute16        => p_header_rec.global_attribute16(i)
              ,p_attribute17        => p_header_rec.global_attribute17(i)
              ,p_attribute18        => p_header_rec.global_attribute18(i)
              ,p_attribute19        => p_header_rec.global_attribute19(i)
              ,p_attribute20        => p_header_rec.global_attribute20(i))
             THEN
                 p_header_rec.lock_control(i) := -99;
                 -- Log Error Message
                 FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
                 FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                                       'Entity:Flexfield:G_Header_Desc_Flex');
                 oe_bulk_msg_pub.Add('Y', 'ERROR');
		 
	      ELSE -- for bug 2511313
	        IF p_header_rec.global_attribute_category(i) IS NULL 
		  OR p_header_rec.global_attribute_category(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute_category(i) := oe_validate.g_context;
		END IF;
		
		IF p_header_rec.global_attribute1(i) IS NULL  
		  OR p_header_rec.global_attribute1(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute1(i) := oe_validate.g_attribute1;
		END IF;
		
		IF p_header_rec.global_attribute2(i) IS NULL
		  OR p_header_rec.global_attribute2(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute2(i) := oe_validate.g_attribute2;
		END IF;
		
		IF p_header_rec.global_attribute3(i) IS NULL
		  OR p_header_rec.global_attribute3(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute3(i) := oe_validate.g_attribute3;
		END IF;
		
		IF p_header_rec.global_attribute4(i) IS NULL
		  OR p_header_rec.global_attribute4(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute4(i) := oe_validate.g_attribute4;
		END IF;
		
		IF p_header_rec.global_attribute5(i) IS NULL
		  OR p_header_rec.global_attribute5(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute5(i) := oe_validate.g_attribute5;
		END IF;
		
		IF p_header_rec.global_attribute6(i) IS NULL
		  OR p_header_rec.global_attribute6(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute6(i) := oe_validate.g_attribute6;
		END IF;
		
		IF p_header_rec.global_attribute7(i) IS NULL
		  OR p_header_rec.global_attribute7(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute7(i) := oe_validate.g_attribute7;
		END IF;
		
		IF p_header_rec.global_attribute8(i) IS NULL
		  OR p_header_rec.global_attribute8(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute8(i) := oe_validate.g_attribute8;
		END IF;
		
		IF p_header_rec.global_attribute9(i) IS NULL
		  OR p_header_rec.global_attribute9(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute9(i) := oe_validate.g_attribute9;
		END IF;

		IF p_header_rec.global_attribute10(i) IS NULL
		  OR p_header_rec.global_attribute10(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute10(i) := oe_validate.g_attribute10;
		END IF;
		
		IF p_header_rec.global_attribute11(i) IS NULL
		  OR p_header_rec.global_attribute11(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute11(i) := oe_validate.g_attribute11;
		END IF;
		
		IF p_header_rec.global_attribute12(i) IS NULL
		  OR p_header_rec.global_attribute12(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute12(i) := oe_validate.g_attribute12;
		END IF;
		
		IF p_header_rec.global_attribute13(i) IS NULL
		  OR p_header_rec.global_attribute13(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute13(i) := oe_validate.g_attribute13;
		END IF;
		
		IF p_header_rec.global_attribute14(i) IS NULL
		  OR p_header_rec.global_attribute14(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute14(i) := oe_validate.g_attribute14;
		END IF;
		
		IF p_header_rec.global_attribute15(i) IS NULL
		  OR p_header_rec.global_attribute15(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute15(i) := oe_validate.g_attribute15;
		END IF;
		
		IF p_header_rec.global_attribute16(i) IS NULL
		  OR p_header_rec.global_attribute16(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute16(i) := oe_validate.g_attribute16;
		END IF;
		
		IF p_header_rec.global_attribute17(i) IS NULL
		  OR p_header_rec.global_attribute17(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute17(i) := oe_validate.g_attribute17;
		END IF;
		
		IF p_header_rec.global_attribute18(i) IS NULL
		  OR p_header_rec.global_attribute18(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute18(i) := oe_validate.g_attribute18;
		END IF;
		
		IF p_header_rec.global_attribute19(i) IS NULL
		  OR p_header_rec.global_attribute19(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute19(i) := oe_validate.g_attribute19;
		END IF;
		
		IF p_header_rec.global_attribute20(i) IS NULL
		  OR p_header_rec.global_attribute20(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.global_attribute20(i) := oe_validate.g_attribute20;
		END IF;
		-- end of bug 2511313

             END IF;
      END IF;

      IF OE_Bulk_Order_Pvt.G_OE_HEADER_TP_ATTRIBUTES = 'Y' THEN

             IF NOT OE_VALIDATE.TP_Header_Desc_Flex
               (p_context            => p_header_rec.tp_context(i)
               ,p_attribute1         => p_header_rec.tp_attribute1(i)
               ,p_attribute2         => p_header_rec.tp_attribute2(i)
               ,p_attribute3         => p_header_rec.tp_attribute3(i)
               ,p_attribute4         => p_header_rec.tp_attribute4(i)
               ,p_attribute5         => p_header_rec.tp_attribute5(i)
               ,p_attribute6         => p_header_rec.tp_attribute6(i)
               ,p_attribute7         => p_header_rec.tp_attribute7(i)
               ,p_attribute8         => p_header_rec.tp_attribute8(i)
               ,p_attribute9         => p_header_rec.tp_attribute9(i)
               ,p_attribute10        => p_header_rec.tp_attribute10(i)
               ,p_attribute11        => p_header_rec.tp_attribute11(i)
               ,p_attribute12        => p_header_rec.tp_attribute12(i)
               ,p_attribute13        => p_header_rec.tp_attribute13(i)
               ,p_attribute14        => p_header_rec.tp_attribute14(i)
               ,p_attribute15        => p_header_rec.tp_attribute15(i))
             THEN
                 p_header_rec.lock_control(i) := -99;
                 -- Log Error Message
                 FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
                 FND_MESSAGE.SET_TOKEN('ATTRIBUTE',
                                       'Entity:Flexfield:TP_Header_Desc_Flex');
                 oe_bulk_msg_pub.Add('Y', 'ERROR');
	      ELSE  -- for bug 2511313

		IF p_header_rec.tp_context(i) IS NULL 
		  OR p_header_rec.tp_context(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_context(i)    := oe_validate.g_context;
		END IF;
	    
		IF p_header_rec.tp_attribute1(i) IS NULL  
		  OR p_header_rec.tp_attribute1(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute1(i) := oe_validate.g_attribute1;
		END IF;
	    
		IF p_header_rec.tp_attribute2(i) IS NULL
		  OR p_header_rec.tp_attribute2(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute2(i) := oe_validate.g_attribute2;
		END IF;
	    
		IF p_header_rec.tp_attribute3(i) IS NULL
		  OR p_header_rec.tp_attribute3(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute3(i) := oe_validate.g_attribute3;
		END IF;
	    
		IF p_header_rec.tp_attribute4(i) IS NULL
		  OR p_header_rec.tp_attribute4(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute4(i) := oe_validate.g_attribute4;
		END IF;
	    
		IF p_header_rec.tp_attribute5(i) IS NULL
		  OR p_header_rec.tp_attribute5(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute5(i) := oe_validate.g_attribute5;
		END IF;
	    
		IF p_header_rec.tp_attribute6(i) IS NULL
		  OR p_header_rec.tp_attribute6(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute6(i) := oe_validate.g_attribute6;
		END IF;
	    
		IF p_header_rec.tp_attribute7(i) IS NULL
		  OR p_header_rec.tp_attribute7(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute7(i) := oe_validate.g_attribute7;
		END IF;
	    
		IF p_header_rec.tp_attribute8(i) IS NULL
		  OR p_header_rec.tp_attribute8(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute8(i) := oe_validate.g_attribute8;
		END IF;
	    
		IF p_header_rec.tp_attribute9(i) IS NULL
		  OR p_header_rec.tp_attribute9(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute9(i) := oe_validate.g_attribute9;
		END IF;
	    
		IF p_header_rec.tp_attribute10(i) IS NULL
		  OR p_header_rec.tp_attribute10(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute10(i) := Oe_validate.G_attribute10;
		End IF;
	    
		IF p_header_rec.tp_attribute11(i) IS NULL
		  OR p_header_rec.tp_attribute11(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute11(i) := oe_validate.g_attribute11;
		END IF;
	    
		IF p_header_rec.tp_attribute12(i) IS NULL
		  OR p_header_rec.tp_attribute12(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute12(i) := oe_validate.g_attribute12;
		END IF;
	    
		IF p_header_rec.tp_attribute13(i) IS NULL
		  OR p_header_rec.tp_attribute13(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute13(i) := oe_validate.g_attribute13;
		END IF;
	    
		IF p_header_rec.tp_attribute14(i) IS NULL
		  OR p_header_rec.tp_attribute14(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute14(i) := oe_validate.g_attribute14;
		END IF;
	    
		IF p_header_rec.tp_attribute15(i) IS NULL
		  OR p_header_rec.tp_attribute15(i) = FND_API.G_MISS_CHAR THEN
		   p_header_rec.tp_attribute15(i) := oe_validate.g_attribute15;
		END IF;

             END IF;
      END IF;
      
      END IF; -- End if p_validate_desc_flex is 'Y'

      -- END: Desc Flex Validations


      ---------------------------------------------------------------
      -- Add a 100% default sales credit record for this salesperson
      ---------------------------------------------------------------
      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Salesrep  validation ');
      End If;

      IF p_header_rec.salesrep_id(i) IS NOT NULL THEN

          x_header_scredit_rec.header_id.extend(1);
          x_header_scredit_rec.salesrep_id.extend(1);
          x_header_scredit_rec.sales_credit_type_id.extend(1);

          l_c_index := OE_Bulk_Cache.Load_Salesrep
                          (p_key => p_header_rec.salesrep_id(i));

          x_header_scredit_rec.header_id(l_scredit_index) 
                  := p_header_rec.header_id(i);
          x_header_scredit_rec.salesrep_id(l_scredit_index) 
                  := p_header_rec.salesrep_id(i);
          x_header_scredit_rec.sales_credit_type_id(l_scredit_index) 
                  := OE_Bulk_Cache.G_SALESREP_TBL(l_c_index).sales_credit_type_id;

          l_scredit_index := l_scredit_index + 1;

      END IF;

      ---------------------------------------------------------------
      -- Load EDI attributes if sold to customer is an EDI customer
      ---------------------------------------------------------------

      IF OE_GLOBALS.G_EC_INSTALLED = 'Y' 
         AND p_header_rec.booked_flag(i) = 'Y'
         AND nvl(p_header_rec.lock_control(i),0) <> -99
      THEN
      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before EDI  validation ');
      End If;

         l_c_index := OE_Bulk_Cache.Load_Sold_To
                        (p_key => p_header_rec.sold_to_org_id(i)
                        ,p_edi_attributes => 'Y'
                        );

         IF OE_Bulk_Cache.G_SOLD_TO_TBL(l_c_index).tp_setup THEN

            OE_Bulk_Order_Pvt.G_ACK_NEEDED := 'Y';
            p_header_rec.first_ack_code(i) := 'X';
            
            -- Cache EDI attributes as these will be used in creating
            -- the acknowledgment records later.

            IF p_header_rec.invoice_to_org_id(i) IS NOT NULL THEN
               l_c_index := OE_Bulk_Cache.Load_Invoice_To
                        (p_key => p_header_rec.invoice_to_org_id(i)
                        ,p_edi_attributes => 'Y'
                        );
            END IF;

            IF p_header_rec.ship_to_org_id(i) IS NOT NULL THEN
               l_c_index := OE_Bulk_Cache.Load_Ship_To
                        (p_key => p_header_rec.ship_to_org_id(i)
                        ,p_edi_attributes => 'Y'
                        );
            END IF;

            IF p_header_rec.ship_from_org_id(i) IS NOT NULL THEN
               l_c_index := OE_Bulk_Cache.Load_Ship_From
                        (p_key => p_header_rec.ship_from_org_id(i)
                        );
            END IF;

	    -- added for end customer changes

	    IF p_header_rec.end_customer_id(i) IS NOT NULL THEN
               l_c_index := OE_Bulk_Cache.Load_End_customer
                        (p_key => p_header_rec.end_customer_id(i)
                        ,p_edi_attributes => 'Y'
                        );
            END IF;

	    IF p_header_rec.End_customer_site_use_id(i) IS NOT NULL THEN
               l_c_index := OE_Bulk_Cache.Load_end_customer_site
                        (p_key => p_header_rec.end_customer_site_use_id(i)
                        ,p_edi_attributes => 'Y'
                        );
            END IF; 

         END IF;

      END IF;

      ---------------------------------------------------------------
      -- Evaluate Holds for header
      ---------------------------------------------------------------

      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Evaluate Holds ');
      End If;
      IF p_header_rec.lock_control(i) <> -99 THEN

            -- Check Header Level Holds
            OE_Bulk_Holds_PVT.Evaluate_Holds(
               p_header_id  => p_header_rec.header_id(i),
               p_line_id => NULL,
               p_line_number => NULL,
               p_sold_to_org_id => p_header_rec.sold_to_org_id(i), 
               p_inventory_item_id => NULL,
               p_ship_from_org_id => NULL,
               p_invoice_to_org_id => NULL,
               p_ship_to_org_id => NULL,
               p_top_model_line_id => NULL,
               p_ship_set_name  => NULL,
               p_arrival_set_name => NULL,
               p_on_generic_hold  => l_on_generic_hold,
               p_on_booking_hold  => l_on_booking_hold,
               p_on_scheduling_hold => l_on_scheduling_hold
               );

       END IF;

       ---------------------------------------------------------------
       -- BOOKING VALIDATIONS
       ---------------------------------------------------------------
       IF p_header_rec.booked_flag(i) = 'Y' THEN

          -- Do not book the Order if the header is on HOLD.

          IF l_on_generic_hold OR l_on_booking_hold THEN

              FND_MESSAGE.SET_NAME('ONT','OE_BOOKING_HOLD_EXISTS');
              oe_bulk_msg_pub.ADD;
              p_header_rec.booked_flag(i) := 'N';
          --PIB
              IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' Then
                 p_header_rec.event_code(i) := 'BATCH';
                 If l_debug_level > 0 Then
                    oe_debug_pub.add('event code1 : '||p_header_rec.event_code(i));
                 End If;
              END IF;    
          --PIB

          ELSE

      If l_debug_level > 0 Then
        oe_debug_pub.add(' Before Check Book Required ');
      End If;
            Check_Book_Reqd_Attributes(p_header_rec => p_header_rec
                                     ,p_index   => i 
                                     ,x_return_status => l_return_status);

            IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               p_header_rec.booked_flag(i) := 'N'; 
          --PIB
              IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' Then
                 p_header_rec.event_code(i) := 'BATCH';
                 If l_debug_level > 0 Then
                    oe_debug_pub.add('event code2 : '||p_header_rec.event_code(i));
                 End If;
              END IF;    
          --PIB
            END IF;

          END IF;

       END IF;

         -- Update Global table with pointers to Erroneous record

         IF (p_header_rec.lock_control(i) = -99) THEN

             error_count := error_count + 1;

             OE_Bulk_Order_Pvt.G_ERROR_REC.order_source_id.EXTEND(1);
             OE_Bulk_Order_Pvt.G_ERROR_REC.order_source_id(error_count)
                        := p_header_rec.order_source_id(i);

             OE_Bulk_Order_Pvt.G_ERROR_REC.orig_sys_document_ref.EXTEND(1);
             OE_Bulk_Order_Pvt.G_ERROR_REC.orig_sys_document_ref(error_count)
                        := p_header_rec.orig_sys_document_ref(i);

             OE_Bulk_Order_Pvt.G_ERROR_REC.header_id.EXTEND(1);
             OE_Bulk_Order_Pvt.G_ERROR_REC.header_id(error_count)
                        := p_header_rec.header_id(i);
         END IF;

   END LOOP;


EXCEPTION
    WHEN OTHERS THEN
      If l_debug_level > 0 Then
            oe_debug_pub.add('In others of ENTITY : ' || SUBSTR(SQLERRM,1,250));
      End If;
    IF oe_bulk_msg_pub.check_msg_level(oe_bulk_msg_pub.G_MSG_LVL_UNEXP_ERROR)
    THEN
       oe_bulk_msg_pub.add_exc_msg
       (   G_PKG_NAME
        ,   'Entity'
        );
    END IF;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Entity;


END OE_BULK_PROCESS_HEADER;
/
--show errors package body OE_BULK_PROCESS_HEADER;
commit;
exit;
