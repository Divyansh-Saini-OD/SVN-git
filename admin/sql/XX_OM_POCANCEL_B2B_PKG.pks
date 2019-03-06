SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE ;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


 CREATE OR REPLACE PACKAGE XX_OM_POCANCEL_B2B_PKG 
 IS
   -- + ======================================================================================+     
    -- | Name        : PO_VAL_CANCEL_PROC                                                    |
    -- | Description : Procedure PO_VAL_CANCEL_PROC will perform the                         |
    -- |               following:                                                            |
    -- |               1. Gets the sales order IDs as parameters                             |
    -- |                  through table type.                                                |
    -- |               2. Fetches the po_header_id and distribution ID                       |
    -- |               3. Fetches the po_line_id, doc_subtype for all                        |
    -- |                  approved and open purchase orders                                  |
    -- |               4. Call the PO cancel API for cancelling the PO                       |
    -- |                  lines                                                              |
    -- | Parameters  : p_user_id                 IN parameter user id                        |
    -- |               p_responsibility_id       IN parameter Resp Id                        |
    -- |               px_sales_order_line_id_tbl IN OUT table type parameter with            |
    -- |                                         SO line id --  line id                      |
    -- |                                         PO cancel line  status - values 'E' OR 'S'  |
    -- |                                                                                     |
    -- |               x_status                  OUT program execution status                |
    -- |                                         it can return values 'E' or'S'              |
    -- |					 E --> program errored intermittently        | 
    -- |				         S --> program completed successful          |
    -- |                                                                                     |
    -- |                                                                                     |
    -- + ====================================================================================+

    TYPE line_id_rec_type IS RECORD(sales_order_line_id oe_order_lines_all.line_id%TYPE 
                                   ,status  VARCHAR2(100)); 
    TYPE line_id_tbl_type IS TABLE OF line_id_rec_type INDEX BY BINARY_INTEGER;

    gc_auth_status        po_headers_all.authorization_status%TYPE      := 'APPROVED' ;
    gc_po_type            po_document_types_all.document_type_code%TYPE := 'PO' ;
    gc_po_closed_code     po_lines_all.closed_code%TYPE                 := 'OPEN' ;

    gn_sql_point  NUMBER ;

   gc_exception_header     VARCHAR2(100) := 'OTHERS';
   gc_exception_track      VARCHAR2(100) := 'OTC';
   gc_exception_sol_dom    VARCHAR2(100) := 'Internal Fulfillment';
   gc_error_function       VARCHAR2(100) := 'Purchasing ';
   gc_line_id              oe_order_lines_all.line_id%TYPE ;

    --Value for PO source type, it is a seeded value , hence can be harcoded
    GN_SUPP_SOURCE_TYPE_ID mtl_reservations.supply_source_type_id%TYPE := 1 ;

   
  PROCEDURE PO_VAL_CANCEL_PROC  ( p_user_id                 IN  NUMBER 
                                 ,p_responsibility_id       IN NUMBER 
                                 ,px_sales_order_line_id_tbl IN OUT line_id_tbl_type
				 ,x_status                  OUT VARCHAR2  
                                 ); 
    -- + =========================================================================+
    -- | Name        : PO_VAL_CANCEL_PROC                                         |
    -- | Description : Procedure PO_VAL_CANCEL_PROC will perform the              |
    -- |               following:                                                 |
    -- |               1. Gets the sales order IDs as parameters                  |
    -- |                  through table type.                                     |
    -- |               2. Fetches the po_header_id and distribution ID            |
    -- |               3. Fetches the po_line_id, doc_subtype for all             |
    -- |                  approved and open purchase orders                       |
    -- |               4. Call the PO cancel API for cancelling the PO            |
    -- |                  lines                                                   |
    -- | Parameters  : p_user_id                 IN parameter user id             |
    -- |               p_responsibility_id       IN parameter Resp Id             |
    -- |               px_sales_order_line_id_tbl IN OUT parameter                 |
    -- |                                         with SO line id and status       |
    -- |               x_status                  OUT program eexecution status    | 
    -- |                                                                          |
    -- |                                                                          |
    -- + =========================================================================+
 END XX_OM_POCANCEL_B2B_PKG;

/
SHOW ERROR