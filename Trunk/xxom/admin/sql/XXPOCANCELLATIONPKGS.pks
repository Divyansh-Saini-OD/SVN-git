SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


 CREATE OR REPLACE PACKAGE XX_OM_POCANCEL_B2B_PKG 
 IS
 -- +================================================================+
 -- |                  Office Depot - Project Simplify               |
 -- |                              WIPRO                             |
 -- +================================================================+
 -- | Name  :    XX_OM_POCANCEL_B2B_PKG				     |
 -- | RICE ID :   E0275	PO cancel B2B                                |
 -- | Description: Custom package which cancels the PO line when     |
 -- |              the sales order line ID is passed                 |
 -- |                                                                |
 -- |                                                                |
 -- |                                                                |
 -- |Change Record:                                                  |
 -- |===============                                                 |
 -- |Version   Date          Author              Remarks             |
 -- |=======   ==========  =============    =========================|
 -- |Draft 1A  27-MAR-2007   Niharika          Initial draft Version |
 -- +================================================================+
    TYPE line_id_rec_type IS RECORD(sale_order_line_id NUMBER
                                   ,status  VARCHAR2(100)); 
    TYPE line_id_tbl_type IS TABLE OF line_id_rec_type INDEX BY BINARY_INTEGER;
   
    PROCEDURE PO_VAL_CANCEL_PROC(p_user_id IN NUMBER
                                 ,p_responsibility_id IN NUMBER
                                 ,pt_sale_order_line_id IN line_id_tbl_type 
				 ,xt_return_status OUT line_id_tbl_type
                                 ,x_ret_code OUT VARCHAR2
                                 ,x_err_buff OUT VARCHAR2
                                 );
    -- + ==============================================================+
    -- | Name        : PO_VAL_CANCEL_PROC                              |
    -- | Description : Procedure PO_VAL_CANCEL_PROC will perform the   |
    -- |               following:                                      |
    -- |               1. Gets the sales order IDs as parameters       |
    -- |                  through table type.                          |
    -- |               2. Fetches the po_header_id and distribution ID |
    -- |               3. Fetches the po_line_id, doc_subtype for all  |
    -- |                  approved and open purchase orders            |
    -- |               4. Call the PO cancel API for cancelling the PO |
    -- |                  lines                                        |
    -- | Parameters  : p_user_id                                       |
    -- |               p_responsibility_id                             |
    -- |               p_sale_order_line_id                            |
    -- |                                                               |
    -- |                                                               |
    -- | Returns     :    --                                           |
    -- |                                                               |
    -- |                                                               |
    -- + ==============================================================+
 END XX_OM_POCANCEL_B2B_PKG;

/
SHOW ERROR