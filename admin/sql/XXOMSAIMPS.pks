CREATE OR REPLACE
PACKAGE XX_OM_SACCT_CONC_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG (XXOMSAIMPS.PKS)                     |
-- | Description      : This Program will load all sales orders from   |
-- |                    Legacy System(SACCT) into EBIZ                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author            Remarks                 |
-- |=======    ==========    =============     ======================= |
-- |DRAFT 1A   06-APR-2007   Bapuji Nanapaneni Initial draft version   |
-- |                                                                   |
-- +===================================================================+

-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------

--Convert all to index by binary_integer;
TYPE T_DATE  IS TABLE OF DATE           INDEX BY BINARY_INTEGER;
TYPE T_NUM   IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER ;
TYPE T_NUM_2 IS TABLE OF NUMBER(10,2)   INDEX BY BINARY_INTEGER;
TYPE T_V1    IS TABLE OF VARCHAR2(01)   INDEX BY BINARY_INTEGER;
TYPE T_V3    IS TABLE OF VARCHAR2(03)   INDEX BY BINARY_INTEGER;
TYPE T_V4    IS TABLE OF VARCHAR2(04)   INDEX BY BINARY_INTEGER;
TYPE T_V10   IS TABLE OF VARCHAR2(10)   INDEX BY BINARY_INTEGER;
TYPE T_V11   IS TABLE OF VARCHAR2(11)   INDEX BY BINARY_INTEGER;
TYPE T_V15   IS TABLE OF VARCHAR2(15)   INDEX BY BINARY_INTEGER;
TYPE T_V25   IS TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
TYPE T_V30   IS TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
TYPE T_V40   IS TABLE OF VARCHAR2(40)   INDEX BY BINARY_INTEGER;
TYPE T_V50   IS TABLE OF VARCHAR2(50)   INDEX BY BINARY_INTEGER;
TYPE T_V80   IS TABLE OF VARCHAR2(80)   INDEX BY BINARY_INTEGER;
TYPE T_V100  IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
TYPE T_V150  IS TABLE OF VARCHAR2(150)  INDEX BY BINARY_INTEGER;
TYPE T_V240  IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
TYPE T_V250  IS TABLE OF VARCHAR2(250)  INDEX BY BINARY_INTEGER;
TYPE T_V360  IS TABLE OF VARCHAR2(360)  INDEX BY BINARY_INTEGER;
TYPE T_V1000 IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
TYPE T_V2000 IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
TYPE T_BI    IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;

TYPE order_source_tbl_type      IS TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(50);
TYPE sales_rep_tbl_type         IS TABLE OF VARCHAR2(7)  INDEX BY BINARY_INTEGER;
TYPE sales_channel_tbl_type     IS TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(50);
TYPE payment_term_tbl_type      IS TABLE OF NUMBER       INDEX BY BINARY_INTEGER;
TYPE ship_from_org_id_tbl_type  IS TABLE OF NUMBER       INDEX BY BINARY_INTEGER;
TYPE store_id_tbl_type          IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;
TYPE pay_method_code_tbl_type   IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(30);
TYPE cc_code_tbl_type           IS TABLE OF VARCHAR2(80) INDEX BY VARCHAR2(30);
TYPE return_reason_tbl_type     IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(30);
TYPE ship_method_Tbl_Type       IS TABLE OF VARCHAR2(30)  INDEX BY VARCHAR2(30);
TYPE Ret_ActCatReason_Tbl_Type  IS TABLE OF VARCHAR2(30)  INDEX BY VARCHAR2(30);

-- Define all globals
g_batch_counter         BINARY_INTEGER ;
g_org_id       CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');
g_list_header_id        NUMBER;
g_list_line_id          NUMBER;
g_request_id            NUMBER;
g_batch_id              NUMBER;
g_def_return__line_type NUMBER;
g_std_return_line_type  NUMBER;
g_accounting_rule_id    NUMBER;
g_header_counter       BINARY_INTEGER := 0;
g_line_counter         BINARY_INTEGER := 0;
g_header_count         BINARY_INTEGER := 0;
g_line_count           BINARY_INTEGER := 0;
g_adj_count            BINARY_INTEGER := 0;
g_payment_count        BINARY_INTEGER := 0;
g_header_tot_amt       NUMBER := 0;
g_tax_tot_amt          NUMBER := 0;
g_line_tot_amt         NUMBER := 0;
g_adj_tot_amt          NUMBER := 0;
g_payment_tot_amt      NUMBER := 0;
g_line_nbr_counter     BINARY_INTEGER;

g_pay_method_code      pay_method_code_tbl_type;
g_cc_code              cc_code_tbl_type;
g_store_id             store_id_tbl_type;
g_ship_from_org_id     ship_from_org_id_tbl_type;
g_payment_term         payment_term_tbl_type;
g_return_reason        return_reason_tbl_type;
g_sales_channel        sales_channel_tbl_type;
g_sales_rep            sales_rep_tbl_type;
g_order_source         order_source_tbl_type;
g_ship_method          ship_method_tbl_type;
g_Ret_ActCatReason     Ret_ActCatReason_Tbl_Type;



-----------------------------------------------------------------
-- HEADER RECORD
-----------------------------------------------------------------

TYPE Header_Rec_Type IS RECORD (
      orig_sys_document_ref        T_V50
    , order_source_id              T_NUM
    , change_sequence              T_V50
    , order_category               T_V50
    , org_id                       T_NUM 
    , ordered_date                 T_DATE
    , order_type_id                T_NUM 
    , legacy_order_type            T_V1
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
    , spc_card_number               T_V240
    , placement_method_code          T_V30
    , advantage_card_number         T_V240
    , created_by_id                 T_V30
    , delivery_code                 T_V30
    , delivery_method               T_V30
    , release_number                T_v240
    , cust_dept_no                  T_V240
    , desk_top_no                   T_V240
    , comments                      T_V240
 -- Header Attributes End    
    , start_line_index             T_BI    
    , paid_at_store_no             T_V50
    , accounting_rule_id           T_NUM
    , sold_to_contact              T_V360
    , header_id                    T_NUM
    , org_order_creation_date      T_DATE
    , return_act_cat_code          T_V100
    , salesrep                     T_V240
    , order_source                 T_V240   
    , sales_channel                T_V80
    , shipping_method              T_V80
    , deposit_amount               T_NUM
    );

/* Global Record  Declaration for Header */
G_header_rec  Header_rec_type;

-----------------------------------------------------------------
-- LINE RECORD
-----------------------------------------------------------------

TYPE line_Rec_Type IS RECORD (
      orig_sys_document_ref        T_V50 
    , order_source_id              T_NUM 
    , change_sequence              T_V50 
    , org_id                       T_NUM  
    , orig_sys_line_ref            T_V50 
    , ordered_date                 T_DATE
    , line_number                  T_NUM 
    , line_type_id                 T_NUM 
    , inventory_item_id            T_NUM 
    , source_type_code             T_V30 
    , schedule_ship_date           T_DATE
    , actual_ship_date             T_DATE
    , schedule_arrival_date        T_DATE
    , actual_arrival_date          T_DATE
    , ordered_quantity             T_NUM
    , order_quantity_uom           T_V3   
    , shipped_quantity             T_NUM 
    , sold_to_org_id               T_NUM 
    , ship_from_org_id             T_NUM 
    , ship_to_org_id               T_NUM 
    , invoice_to_org_id            T_NUM 
    , ship_to_contact_id           T_NUM 
    , sold_to_contact_id           T_NUM 
    , invoice_to_contact_id        T_NUM 
    , drop_ship_flag               T_v1  
    , price_list_id                T_NUM 
    , unit_list_price              T_NUM 
    , unit_selling_price           T_NUM 
    , calculate_price_flag         T_V1  
    , tax_code                     T_V50 
    , tax_date                     T_DATE
    , tax_value                    T_NUM 
    , shipping_method_code         T_V30 
    , salesrep_id                  T_NUM 
    , return_reason_code           T_V30 
    , customer_po_number           T_V50 
    , operation_code               T_V30 
    , error_flag                   T_V1  
    , shipping_instructions        T_V2000
    , return_context               T_V30  
    , return_attribute1            T_V240 
    , return_attribute2            T_V240 
    , customer_item_name           T_V2000
    , customer_item_id             T_NUM  
    , customer_item_id_type        T_V30  
    , line_category_code           T_V30  
    , tot_tax_value                T_NUM_2
    , customer_line_number         T_V50
    , context                      T_V30  
    , attribute6                   T_V240
    , attribute7                   T_V240
    , created_by                   T_NUM  
    , creation_date                T_DATE 
    , last_update_date             T_DATE 
    , last_updated_by              T_NUM  
    , request_id                   T_NUM  
    , batch_id                     T_NUM
    , legacy_list_price            T_NUM_2
    , vendor_product_code          T_V240
    , contract_details             T_V240
    , item_comments                T_V240
    , line_comments                T_V240
    , taxable_flag                 T_V1
    , sku_dept                     T_V240
    , item_source                  T_V240
    , average_cost                 T_NUM
    , po_cost                      T_NUM
    , canada_pst                   T_V50
    , return_act_cat_code          T_V100
    , return_reference_no          T_V50
    , back_ordered_qty             T_NUM
    , return_ref_line_no           T_NUM
    , org_order_creation_date      T_DATE
    , whole_seller_item            T_V240
    , header_id                    T_NUM
    , line_id                      T_NUM
    , payment_term_id              T_NUM
    , inventory_item               T_V2000
    , schedule_status_code         T_V30
    );

/* Global Recodr Declaration for  Line */
G_line_Rec line_Rec_Type;

-----------------------------------------------------------------
-- LINE ADJUSTMENTS RECORD
-----------------------------------------------------------------
TYPE Line_Adj_Rec_Type IS RECORD (
      orig_sys_document_ref                   T_V50 
    , order_source_id                         T_NUM 
    , org_id                                  T_NUM 
    , orig_sys_line_ref                       T_V50 
    , orig_sys_discount_ref                   T_V50 
    , sold_to_org_id                          T_NUM 
    , change_sequence                         T_V50 
    , automatic_flag                          T_V1  
    , list_header_id                          T_NUM 
    , list_line_id                            T_NUM 
    , list_line_type_code                     T_V30 
    , applied_flag                            T_V1  
    , operand                                 T_NUM 
    , arithmetic_operator                     T_V30 
    , pricing_phase_id                        T_NUM 
    , adjusted_amount                         T_NUM 
    , inc_in_sales_performance                T_V1  
    , operation_code                          T_V30 
    , error_flag                              T_V1  
    , request_id                              T_NUM
    , context                                 T_V30 
    , attribute6                              T_V240
    , attribute7                              T_V240
    , attribute8                              T_V240
    , attribute9                              T_V240
    , attribute10                             T_V240
    );

/* Global Record Declaration   Line Adjustments*/
G_Line_Adj_Rec  Line_Adj_Rec_Type;

-----------------------------------------------------------------
-- PAYMENTS RECORD
-----------------------------------------------------------------

TYPE Payment_Rec_Type IS RECORD (
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
    , sold_to_org_id              T_NUM
    );

/* Payment Global Record Declaration */
G_payment_rec  payment_rec_type;

-----------------------------------------------------------------
-- Tender RECORD
-----------------------------------------------------------------

TYPE Return_Tender_Rec_Type IS RECORD (
      orig_sys_document_ref                   T_V50
    , orig_sys_payment_ref                    T_V50
    , order_source_id                         T_NUM
    , payment_number                          T_NUM
    , payment_type_code                       T_V30
    , credit_card_code                        T_V80
    , credit_card_number                      T_V80
    , credit_card_holder_name                 T_V80
    , credit_card_expiration_date             T_DATE
    , credit_amount                           T_NUM 
    , request_id                              T_NUM 
    , sold_to_org_id                          T_NUM 
    , cc_auth_manual                          T_V1
    , merchant_nbr                            T_V11
    , cc_auth_ps2000                          T_V50
    , allied_ind                              T_V1
    , receipt_method_id                       T_NUM  
    );

/* Tender Global Record Declaration */

G_Return_Tender_Rec  Return_Tender_Rec_Type;
---------------------------------------------------------------
-- Sales Credits RECORD
-----------------------------------------------------------------

TYPE Sale_Credits_Rec_Type IS RECORD (  
      orig_sys_document_ref       T_V50 
    , order_source_id             T_NUM  
    , change_sequence_code        T_V50  
    , org_id                      T_NUM  
    , orig_sys_credit_ref         T_V50  
    , salesrep_id                 T_NUM  
    , sales_credit_type_id        T_NUM  
    , quota_flag                  T_V1   
    , percent                     T_NUM  
    , operation_code              T_V30  
    , sales_group_id              T_NUM  
    , sold_to_org_id              T_NUM  
    , request_id                  T_NUM  
    , sales_group_updated_flag    T_V1   
    );

/* Tender Global Record Declaration */
G_Sale_Credits_Rec  Sale_Credits_Rec_Type;

/* Record Type Declaration */

TYPE order_rec_type IS RECORD (
                                record_type        VARCHAR2(5)
                              , file_line          VARCHAR2(1000));

G_rec_type order_rec_type;

TYPE order_tbl_type IS TABLE OF order_rec_type INDEX BY BINARY_INTEGER;

/* RECODR TYPE DECLARATION FOR HEADER INFO TO CHILD */

TYPE Header_to_child_type IS RECORD (
      orig_sys_document_ref    T_V50
    , order_source_id          T_NUM
    , sold_to_org_id           T_NUM);

g_header_to_child  header_to_child_type;

-- +===================================================================+
-- | Name  : Process_Child                                             |
-- | Description     : The Process Child is called by Upload Data      |
-- |                   Multiple Childs request are submitted depend on |
-- |                   p_file_count                                    |
-- |                   Each order is read order by order from flat file|
-- |                   and stored in file_line rec type                |
-- |                  process header reads header info , process line  |
-- |                  reads line info process adjustments reads        |
-- |                  adjustments & process_payments reads payment info|
-- |                                                                   |
-- | Parameters      : p_file_name   IN -> DEFAULT 'SAS'               |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5      |
-- |                   P_batch_size  IN -> Size of Batch ex. 1500      |
-- |                   p_file_sequence_num IN -> seq no                |
-- |                   p_file_count        IN -> No of file to process |
-- |                                             i.e 1 to 20           |
-- |                   x_return_status     OUT                         |                                                |
-- +===================================================================+

PROCEDURE Process_Child  (
      p_file_name         IN          VARCHAR2
    , p_debug_level       IN          NUMBER
    , p_batch_size        IN          NUMBER
    , p_file_sequence_num IN          NUMBER
    , p_file_count        IN          NUMBER 
    , x_return_status     OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name  : get_def_shipto                                            |
-- | Description     : To get ship to org id by passing customer id    |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   P_ship_to_org_id   OUT -> get ship_to_org_id    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE get_def_shipto( 
      p_cust_account_id  IN       NUMBER
    , p_ship_to_org_id  OUT NOCOPY NUMBER
    );
                               
-- +===================================================================+
-- | Name  : get_def_billto                                            |
-- | Description     : To get bill to org id by passing customer id    |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   P_bill_to_org_id   OUT -> get bill_to_org_id    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE get_def_billto( 
      p_cust_account_id  IN       NUMBER
    , p_bill_to_org_id  OUT NOCOPY NUMBER
    );


G_CREATED_BY_MODULE   CONSTANT VARCHAR2(30) := 'XXOM_HVOP_ADD_SHIPTO';
TYPE T_VCHAR50 IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name  : derive_ship_to                                            |
-- | Description     : To derive ship_to_org_id for each legacy order  |
-- |                   IF multiple ship_to_org_id's are found we pass  |
-- |                   the address and validated                       |  
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer_id         |
-- |                  P_orig_sys_document_ref IN -> pass orig order ref|
-- |                  p_order_source_id IN -> pass order_source_id     |
-- |                  p_orig_sys_ship_ref IN -> pass orig_ship_ref     |
-- |                  p_ordered_date      IN -> pass ordered date      |
-- |                  p_address_line1     IN -> pass address1          |
-- |                  p_address_line2     IN -> pass address2          |
-- |                  p_city              IN -> pass city              |
-- |                  p_state             In -> pass state             |
-- |                  p_country           IN -> pass country           |
-- |                  p_province          IN -> pass province          |
-- |                  x_ship_to_org_id   OUT -> get ship_to_org_id     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Derive_Ship_To(
    p_sold_to_org_id        IN NUMBER,
    p_orig_sys_document_ref IN VARCHAR2,
    p_order_source_id       IN NUMBER,
    p_orig_sys_ship_ref     IN VARCHAR2,
    p_ordered_date          IN DATE,
    p_address_line1         IN VARCHAR2,
    p_address_line2         IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_postal_code           IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_country               IN VARCHAR2,
    p_province              IN VARCHAR2,
    x_ship_to_org_id        IN OUT NOCOPY VARCHAR2
    );

-- +===================================================================+
-- | Name  : Upload_data                                               |
-- | Description     : The Upload_data procedure is the main procedure |
-- |                   depend on no of file count it generate that many|
-- |                   child concurrent programs                       |
-- |                                                                   |
-- | Parameters      : p_file_name   IN -> DEFAULT 'SAS'               |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5      |
-- |                   P_batch_size  IN -> Size of Batch ex. 1500      |
-- |                   p_file_sequence_num IN -> seq no                |
-- |                   p_file_count        IN -> No of file to process |
-- |                                             i.e 1 to 20           |
-- |                   p_file_date         IN -> DEFAULT SYSDATE       |   
-- |                   p_feed_number       IN -> No of feed  1 to 5    |
-- |                   retcode           OUT                           |
-- |                   errbuf            OUT                           |
-- +===================================================================+

PROCEDURE Upload_Data (
      retcode            OUT NOCOPY   NUMBER
    , errbuf             OUT NOCOPY   VARCHAR2
    , p_file_name         IN          VARCHAR2
    , p_debug_level       IN          NUMBER DEFAULT 0
    , p_batch_size        IN          NUMBER DEFAULT 1500
    , p_file_sequence_num IN          NUMBER
    , p_file_count        IN          NUMBER DEFAULT 1
    , p_file_date         IN          VARCHAR2
    , p_feed_number       IN          NUMBER 
    );
                        
-- +===================================================================+
-- | Name  : create_ship_to                                            |
-- | Description     : To create ship_to_org_id which does not match   |
-- |                   EBIZ ship_to which are comming from legacy      |
-- |                    orders                                         |  
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer_id         |
-- |                  P_orig_sys_document_ref IN -> pass orig order ref|
-- |                  p_order_source_id IN -> pass order_source_id     |
-- |                  p_orig_sys_ship_ref IN -> pass orig_ship_ref     |
-- |                  p_ordered_date      IN -> pass ordered date      |
-- |                  p_address_line1     IN -> pass address1          |
-- |                  p_address_line2     IN -> pass address2          |
-- |                  p_city              IN -> pass city              |
-- |                  p_state             In -> pass state             |
-- |                  p_country           IN -> pass country           |
-- |                  p_province          IN -> pass province          |
-- |                  x_ship_to_org_id   OUT -> get ship_to_org_id     |
-- |                  x_return_status    OUT -> return_status S or E   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE CREATE_SHIP_TO(
    p_sold_to_org_id        IN NUMBER   ,
    p_orig_sys_document_ref IN VARCHAR2 ,
    p_order_source_id       IN NUMBER   ,
    p_orig_sys_shipto_ref   IN VARCHAR2 ,
    p_address1              IN VARCHAR2 ,
    p_address2              IN VARCHAR2 ,
    p_city                  IN VARCHAR2 ,
    p_postal_code           IN VARCHAR2 ,
    p_state                 IN VARCHAR2 ,
    p_county                IN VARCHAR2 ,
    p_country               IN VARCHAR2 ,
    p_province              IN VARCHAR2 ,
    x_ship_to_org_id        IN OUT NOCOPY VARCHAR2,
    x_return_status         IN OUT NOCOPY VARCHAR2);
    
/* FOR HEADERS */  
-- +===================================================================+
-- | Name  : order_source                                              |
-- | Description     : To derive order_source_id by passing order      |
-- |                   source                                          |
-- |                                                                   |
-- | Parameters     : p_order_source  IN -> pass order source          |
-- |                                                                   |
-- +===================================================================+

FUNCTION order_source(p_order_source IN VARCHAR2 ) RETURN VARCHAR2;
-- +===================================================================+
-- | Name  : sales_rep                                                 |
-- | Description     : To derive salesrep_id by passing salesrep       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters     : p_sales_rep  IN -> pass salesrep                 |
-- |                                                                   |
-- | Return         : order_source_id                                  |
-- +===================================================================+
FUNCTION sales_rep (p_sales_rep IN VARCHAR2) RETURN NUMBER;
-- +===================================================================+
-- | Name  : sales_channel                                             |
-- | Description     : To validate sales_channel_code by passing       |
-- |                   sales channel                                   |
-- |                                                                   |
-- | Parameters     : p_sales_channel  IN -> pass sales channel        |
-- |                                                                   |
-- | Return         : sales_channel_code                               |
-- +===================================================================+
FUNCTION sales_channel (p_sales_channel IN VARCHAR2) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : payment_term                                              |
-- | Description     : To derive payment_term_id by passing            |
-- |                   customer_id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : payment_term_id                                  |
-- +===================================================================+
FUNCTION payment_term (p_sold_to_org_id IN NUMBER) RETURN NUMBER;  

-- +===================================================================+
-- | Name  : ship_from_org                                             |
-- | Description     : To derive ship_from_org_id by passing           |
-- |                   warehouse code                                  |
-- |                                                                   |
-- | Parameters     : p_ship_from_org  IN -> pass warehouse code       |
-- |                                                                   |
-- | Return         : ship_from_org_id                                 |
-- +===================================================================+
FUNCTION ship_from_org (p_ship_from IN VARCHAR2) RETURN NUMBER;

-- +===================================================================+
-- | Name  : store_id                                                  |
-- | Description     : To derive store_id by passing                   |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_store_no  IN -> pass store location            |
-- |                                                                   |
-- | Return         : store_id for KFF DFF                             |
-- +===================================================================+
FUNCTION store_id(p_store_no IN VARCHAR2) RETURN NUMBER;

-- +===================================================================+
-- | Name  : return_reason                                             |
-- | Description     : To derive return_reason_code by passing         |
-- |                   return reason                                   |
-- |                                                                   |
-- | Parameters     : p_return_reason  IN -> pass return reason        |
-- |                                                                   |
-- | Return         : return_reason_code                               |
-- +===================================================================+
FUNCTION return_reason (p_return_reason IN VARCHAR2) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : get_ship_method                                           |
-- | Description     : To derive ship_method_code by passing           |
-- |                   delivery code                                   |
-- |                                                                   |
-- | Parameters     : p_ship_method  IN -> pass delivery code          |
-- |                                                                   |
-- | Return         : ship_method_code                                 |
-- +===================================================================+
FUNCTION Get_Ship_Method (p_ship_method IN VARCHAR2) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : Get_Ret_ActCatReason_Code                                 |
-- | Description     : To  derive return_act_cat_code by passing       |
-- |                   action,category,reason                          |
-- |                                                                   |
-- | Parameters     : p_code  IN -> pass code                          |
-- |                                                                   |
-- | Return         : account_category_code                            |
-- +===================================================================+
FUNCTION Get_Ret_ActCatReason_Code (p_code IN VARCHAR2) RETURN VARCHAR2;

/* FOR LINES */
-- +===================================================================+
-- | Name  : inventory_item_id                                         |
-- | Description     : To derive inventory_item_id  by passing         |
-- |                   legacy item number                              |
-- |                                                                   |
-- | Parameters     : p_item  IN -> pass sku number                    |
-- |                                                                   |
-- | Return         : inventory_item_id                                |
-- +===================================================================+
FUNCTION inventory_item_id ( p_item IN VARCHAR2) RETURN NUMBER;

-- +===================================================================+
-- | Name  : customer_item_id                                          |
-- | Description     : To derive customer_item_id  by passing          |
-- |                   legacy customer product_code                    |
-- |                                                                   |
-- | Parameters     : p_cust_item  IN -> pass customer sku number      |
--|                   p_customer_id IN -> pass customer_id             |
-- |                                                                   |
-- | Return         : customer_item_id                                 |
-- +===================================================================+
FUNCTION customer_item_id (p_cust_item IN VARCHAR2
                         , p_customer_id IN NUMBER) RETURN NUMBER;


/*FOR PAYMENTS */
-- +===================================================================+
-- | Name  : receipt_method_code                                       |
-- | Description     : To derive receipt_method_id  by passing         |
-- |                   legacy payment_method_code, org_id, current     |
-- |                    header index                                   |
-- | Parameters     : p_pay_method_code  IN -> pass pay method code    |
-- |                  p_org_id           IN -> operating unit id       |
-- |                  p_hdr_idx          IN -> current header index    |
-- |                                                                   |
-- | Return         : receipt_method_id                                |
-- +===================================================================+
FUNCTION receipt_method_code( p_pay_method_code IN VARCHAR2
    , p_org_id IN NUMBER
    , p_hdr_idx IN BINARY_INTEGER) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : credit_card_name                                          |
-- | Description     : To derive credit_card_name  by passing          |
-- |                   customer id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : credit_card_name                                 |
-- +===================================================================+
FUNCTION credit_card_name(p_sold_to_org_id IN NUMBER) RETURN VARCHAR2;

END XX_OM_SACCT_CONC_PKG;
