create or replace PACKAGE XX_OM_HVOP_DEPOSIT_CONC_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                          |
-- |                Office Depot                                                                                                      |
-- +===================================================================+
-- | Name  : XX_OM_HVOP_DEPOSIT_CONC_PKG                                                                       |
-- | Description      : Package Specification                                                                               | 
-- |                                                                                                                                        |
-- |                                                                                                                                        |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                          |
-- |Version    Date          Author           Remarks                                                                       |
-- |=======    ==========    =============    ========================                |
-- |DRAFT 1A   06-MAR-2007   Visalakshi          Initial draft version                                                  |
-- |                                                                                                                                        |
-- +===================================================================+
-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------
--Convert all to index by binary_integer;
TYPE T_DATE  is TABLE OF DATE           INDEX BY BINARY_INTEGER;
TYPE T_NUM   is TABLE OF NUMBER         INDEX BY BINARY_INTEGER ;
TYPE T_NUM_2 is TABLE OF NUMBER(10,2)   INDEX BY BINARY_INTEGER;
TYPE T_V1    is TABLE OF VARCHAR2(01)   INDEX BY BINARY_INTEGER;
TYPE T_V3    is TABLE OF VARCHAR2(03)   INDEX BY BINARY_INTEGER;
TYPE T_V4    is TABLE OF VARCHAR2(04)   INDEX BY BINARY_INTEGER;
TYPE T_V10   is TABLE OF VARCHAR2(10)   INDEX BY BINARY_INTEGER;
TYPE T_V15   is TABLE OF VARCHAR2(15)   INDEX BY BINARY_INTEGER;
TYPE T_V25   is TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
TYPE T_V30   is TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
TYPE T_V40   is TABLE OF VARCHAR2(40)   INDEX BY BINARY_INTEGER;
TYPE T_V50   is TABLE OF VARCHAR2(50)   INDEX BY BINARY_INTEGER;
TYPE T_V80   is TABLE OF VARCHAR2(80)   INDEX BY BINARY_INTEGER;
TYPE T_V100  is TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
TYPE T_V150  is TABLE OF VARCHAR2(150)  INDEX BY BINARY_INTEGER;
TYPE T_V240  is TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
TYPE T_V250  is TABLE OF VARCHAR2(250)  INDEX BY BINARY_INTEGER;
TYPE T_V360  is TABLE OF VARCHAR2(360)  INDEX BY BINARY_INTEGER;
TYPE T_V1000 is TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
TYPE T_V2000 is TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
TYPE T_BI    IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;

TYPE order_source_type        IS TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(50);
TYPE payment_term_type        IS TABLE OF NUMBER       INDEX BY BINARY_INTEGER;
TYPE store_id_type            IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;
TYPE pay_method_code_type     IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(30);
TYPE cc_code_type             IS TABLE OF VARCHAR2(80) INDEX BY VARCHAR2(30);
g_org_id       CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');
g_request_id            NUMBER;
g_pay_method_code      pay_method_code_type;
g_cc_code              cc_code_type;
g_store_id             store_id_type;
g_payment_term         payment_term_type;
g_order_source         order_source_type;
-----------------------------------------------------------------
-- HEADER RECORD
-----------------------------------------------------------------

TYPE Header_Rec_Type IS RECORD
(

  orig_sys_document_ref        T_V50
, order_source_id              T_NUM
, change_sequence              T_V50
, order_category               T_V50
, org_id                       T_NUM 
, ordered_date                 T_DATE
, order_type_id                T_NUM 
, legacy_order_type            T_NUM
, price_list_id                T_NUM
, transactional_curr_code      T_v3 
, salesrep_id                  T_NUM
, sales_channel_code           T_V30
, shipping_method_code         T_V30
, shipping_instructions        T_V2000
, customer_po_number           T_V50
, sold_to_org_id               T_NUM
, ship_from_org_id             T_NUM
, invoice_to_org_id            T_NUM
, sold_to_contact_id           T_NUM
, ship_to_org_id               T_NUM
, ship_to_org                  T_V360
, ship_from_org                T_V360
, sold_to_org                  T_V360
, invoice_to_org               T_V240
, drop_ship_flag               T_V1  
, booked_flag                  T_V1 
, operation_code               T_V30
, error_flag                   T_V1 
, ready_flag                   T_V1 
, context                      T_V30
, payment_term_id              T_NUM
, tax_value                    T_NUM_2
, customer_po_line_num         T_V50  
, category_code                T_V30  
, ship_date                    T_DATE
, return_reason                T_V30
, pst_tax_value                T_NUM_2
, return_orig_sys_doc_ref      T_V50
, attribute6                   T_V240 
, attribute7                   T_V240
, created_by                   T_NUM 
, creation_date                T_DATE
, last_update_date             T_DATE
, last_updated_by              T_NUM 
, batch_id                     T_NUM 
, request_id                   T_NUM 
/* Header Attributes  */
, created_by_store_id          T_NUM
, paid_at_store_id             T_NUM
,spc_card_number               T_V240
,placement_method_code          T_V30
,advantage_card_number         T_V240
,created_by_id                 T_V30
,delivery_code                 T_V30
,delivery_method               T_V30
,release_number                T_v240
,cust_dept_no                  T_V240
,desk_top_no                   T_V240
,comments                      T_V240
, start_line_index             T_BI    
, paid_at_store_no             T_V50
, accounting_rule_id           T_NUM
);

/* Global Record  Declaration for Header */
G_header_rec  Header_rec_type;

-----------------------------------------------------------------
-- PAYMENTS RECORD
-----------------------------------------------------------------

TYPE Payment_Rec_Type IS RECORD
(
  orig_sys_document_ref       T_V50 
, order_source_id             T_NUM  
, orig_sys_payment_ref        T_V50 
, org_id                      T_NUM 
, payment_type_code           T_V30 
, payment_collection_event    T_V30 
, prepaid_amount              T_NUM 
, credit_card_number          T_V80 
, credit_card_holder_name     T_V80 
, credit_card_expiration_date T_DATE
, credit_card_code            T_V80 
, credit_card_approval_code   T_V80 
, credit_card_approval_date   T_DATE
, check_number                T_V80 
, payment_amount              T_NUM 
, operation_code              T_V30 
, error_flag                  T_V1  
, receipt_method_id           T_NUM  
, payment_number              T_NUM
, attribute6                  T_V240
, attribute7                  T_V240
, attribute8                  T_V240
, attribute9                  T_V240
, attribute10                 T_V240
);

/* Payment Global Record Declaration */
G_payment_rec  payment_rec_type;

/* Record Type Declaration */

TYPE order_rec_type IS RECORD (
                                record_type        VARCHAR2(5)
                              , file_line          VARCHAR2(1000));

G_rec_type order_rec_type;

TYPE order_tbl_type IS TABLE OF order_rec_type INDEX BY BINARY_INTEGER;

/* RECODR TYPE DECLARATION FOR HEADER INFO TO CHILD */

PROCEDURE Process_Deposit(
      x_retcode           OUT NOCOPY  NUMBER
    , x_errbuf            OUT NOCOPY  VARCHAR2 
    , p_debug_level       IN          NUMBER
    , p_filedate          IN          VARCHAR2
    , p_feednumber        IN          NUMBER
    , x_return_status     OUT NOCOPY  VARCHAR2
    );
PROCEDURE process_header(
  p_order_rec IN order_rec_type
) ;

PROCEDURE process_payment(p_order_rec IN order_rec_type);

PROCEDURE Process_Current_Deposit(
p_order_tbl  IN order_tbl_type
) ;

PROCEDURE insert_data;


PROCEDURE SET_MSG_CONTEXT(p_entity_code IN VARCHAR2,
                          p_line_ref IN VARCHAR2 DEFAULT NULL);
                          
FUNCTION store_id (p_store_no IN VARCHAR2) RETURN NUMBER ;

G_CREATED_BY_MODULE   CONSTANT VARCHAR2(30) := 'XXOM_HVOP_ADD_SHIPTO';
TYPE T_VCHAR50 IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;

/* FOR HEADERS */  
FUNCTION order_source(p_order_source IN VARCHAR2 ) RETURN VARCHAR2;
FUNCTION payment_term (p_sold_to_org_id IN NUMBER) RETURN VARCHAR2;  

/*FOR PAYMENTS */

FUNCTION receipt_method_code( p_pay_method_code IN VARCHAR2
    , p_org_id IN NUMBER
    , p_hdr_idx IN BINARY_INTEGER) RETURN VARCHAR2;

PROCEDURE Get_Pay_Method(
  p_payment_instrument IN VARCHAR2
, p_payment_type_code IN OUT NOCOPY VARCHAR2
, p_credit_card_code  IN OUT NOCOPY VARCHAR2);

FUNCTION credit_card_name(p_sold_to_org_id IN NUMBER) RETURN VARCHAR2;

END XX_OM_HVOP_DEPOSIT_CONC_PKG;
