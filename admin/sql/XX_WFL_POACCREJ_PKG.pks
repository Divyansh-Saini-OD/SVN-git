SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_WFL_POACCREJ_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name       : XX_WFL_POACCREJ_PKG                                  |
-- | Rice ID    : E0274                                                |
-- | Description: This package contains procedures that perform the    |
-- |              following activities                                 |
-- |              1.FILL_KILL_PROC - Checks the backorder eligible flag|
-- |                If flag is 'Y' then Fill process is followed       |
-- |                Else Kill path is taken.                           |
-- |              2.CANCEL_OE_LINE_PROC - Cancel the original Sales    |
-- |                Order line using CANCEL_LINE procedure.            |
-- |              3.CREATE_OE_LINE_PROC - creates and updates a new    |
-- |                sales order line using CREATE_LINE.                |
-- |              4.CREATE_LINE - Create a new sales order line        |
-- |                copying the existing line's attributes.            |
-- |              5.CANCEL_LINE - Cancel the original Sales Order      |
-- |                line using PROCESSORDER procedure.                 |
-- |              6.PROCESSORDER - Modifies/Creates order line using   |
-- |                OE_ORDER_PUB.PROCESS_ORDER API.                    |
-- |              7.SPLIT_LINE - Splits the sales order line based on  |
-- |                quantity received and quantity cancelled.          |
-- |              8.UPDATE_OE_LINE_DFF - Updates the custom table sales|
-- |                 order line attributes.                            |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  25-JUL-2007 Christina S        Initial draft version     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
    --Declaring global variables

    gc_err_code              xxom.xx_om_global_exceptions.error_code%TYPE;
    gc_err_desc              xxom.xx_om_global_exceptions.description%TYPE;
    gc_entity_ref            xxom.xx_om_global_exceptions.entity_ref%TYPE;
    gn_entity_ref_id         xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
    gc_exception_header      xxom.xx_om_global_exceptions.exception_header%TYPE  := 'OTHERS';
    gc_exception_track       xxom.xx_om_global_exceptions.track_code%TYPE        := 'OTC';
    gc_exception_sol_dom     xxom.xx_om_global_exceptions.solution_domain%TYPE   := 'Order Management';
    gc_error_function        xxom.xx_om_global_exceptions.function_name%TYPE     := 'E0274 PO ACC REJ';
    gc_err_report_type       xx_om_report_exception_t;
    gn_qty_cancelled         po_line_locations_all.quantity_cancelled%TYPE;
    gn_qty_received          po_line_locations_all.quantity_received%TYPE;
    gc_dropship_meaning      fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE     DEFAULT 'DropShip';
    gc_nc_dropship_meaning   fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE     DEFAULT 'Non-Code DropShip';
    gc_backtoback_meaning    fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE     DEFAULT 'BackToBack';
    gc_nc_backtoback_meaning fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE     DEFAULT 'Non-Code BackToBack';
    gc_desc_flexfield_name   fnd_descr_flex_contexts.descriptive_flexfield_name%TYPE        DEFAULT 'PO_HEADERS';
    gc_change_reason         fnd_lookup_values.meaning%TYPE                                 DEFAULT 'Related PO changes';
    gn_line_Id               oe_order_lines_all.line_id%TYPE;
    gc_split_flag            VARCHAR2(1);
    gn_po_line_id            po_lines_all.po_Line_id%TYPE;

    TYPE line_rec_type IS RECORD( line_id  VARCHAR2(100) );

    TYPE line_tbl_type IS TABLE OF line_rec_type INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name           : FILL_KILL_PROC                                   |
-- | Description    : Checks the backorder eligible flag.If flag is 'Y'|
-- |                  then Fill process is followed                    |
-- |                  Else Kill path is taken.                         |
-- |                                                                   |
-- | Parameters     : p_item_type                                      |
-- |                  p_item_key                                       |
-- |                  p_actid                                          |
-- |                  p_funcmode                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns        : x_result                                         |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE FILL_KILL_PROC(
                                p_item_type  IN  VARCHAR2
                               ,p_item_key   IN  VARCHAR2
                               ,p_actid      IN  NUMBER
                               ,p_funcmode   IN  VARCHAR2
                               ,x_result     OUT VARCHAR2
                            );


-- +===================================================================+
-- | Name             : PROCESSORDER                                   |
-- | Description      : This program process the order and cancels     |
-- |                    the line using the API                         |
-- |                    OE_ORDER_PUB.PROCESS_ORDER                     |
-- |                                                                   |
-- | Parameters       : p_process_type                                 |
-- |                    x_header_rec                                   |
-- |                    x_header_adj_tbl                               |
-- |                    x_order_lines_tbl                              |
-- |                    x_line_adj_tbl                                 |
-- |                    p_request_tbl                                  |
-- |                                                                   |
-- | Returns          : x_order_lines_tbl_out                          |
-- |                    x_return_status                                |
-- |                    x_return_message                               |
-- +===================================================================+

    PROCEDURE PROCESSORDER (
                             p_process_type          IN              VARCHAR2 DEFAULT 'API'
                            ,x_header_rec            IN OUT NOCOPY   OE_ORDER_PUB.HEADER_REC_TYPE
                            ,x_header_adj_tbl        IN OUT NOCOPY   OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE
                            ,x_order_lines_tbl       IN OUT NOCOPY   OE_ORDER_PUB.LINE_TBL_TYPE
                            ,x_line_adj_tbl          IN OUT NOCOPY   OE_ORDER_PUB.LINE_ADJ_TBL_TYPE
                            ,p_request_tbl           IN              OE_ORDER_PUB.REQUEST_TBL_TYPE
                            ,x_order_lines_tbl_out   OUT             OE_ORDER_PUB.LINE_TBL_TYPE
                            ,x_return_status         OUT             VARCHAR2
                            ,x_return_message        OUT             VARCHAR2
                            );

-- +======================================================================+
-- | Name             : CREATE_OE_LINE_PROC                               |
-- | Description      : This program creates a new order line along with  |
-- |                    line attributes create_line procedure.            |
-- |                    Cancels the existing order line using             |
-- |                    cancel_line procedure.                            |
-- |                                                                      |
-- | Parameters       : p_item_type                                       |
-- |                   p_item_key                                         |
-- |                   p_actid                                            |
-- |                   p_funcmode                                         |
-- |                                                                      |
-- |                                                                      |
-- | Returns          : x_result                                          |
-- |                                                                      |
-- +======================================================================+

    PROCEDURE CREATE_OE_LINE_PROC (
                                p_item_type  IN  VARCHAR2
                               ,p_item_key   IN  VARCHAR2
                               ,p_actid      IN  NUMBER
                               ,p_funcmode   IN  VARCHAR2
                               ,x_result     OUT VARCHAR2
                                          );

-- +======================================================================+
-- | Name             : CREATE_LINE                                       |
-- | Description      : This procedure creates a new sales order line     |
-- |                    along with the line attributes and pricing details|
-- |                                                                      |
-- | Parameters       : p_line_id                                         |
-- |                                                                      |
-- | Returns          : x_return_status                                   |
-- |                    x_return_message                                  |
-- +======================================================================+

    PROCEDURE CREATE_LINE(
                                p_line_id          IN       oe_order_lines_all.line_id%TYPE
                               ,x_return_status    OUT      VARCHAR2
                               ,x_return_message   OUT      VARCHAR2
                         );

-- +======================================================================+
-- | Name         :  CANCEL_LINE                                          |
-- | Description  :  This program cancels the sales order line using      |
-- |                 the OE_ORDER_PUB.PROCESS_ORDER API                   |
-- |                                                                      |
-- | Parameters   :  p_line_id                                            |
-- |                                                                      |
-- | Returns      :  x_return_status                                      |
-- |                 x_return_message                                     |
-- |                                                                      |
-- +======================================================================+

    PROCEDURE CANCEL_LINE (
                         p_line_id          IN       oe_order_lines_all.line_id%TYPE
                        ,x_return_status    OUT      VARCHAR2
                        ,x_return_message   OUT      VARCHAR2
                      );

-- +======================================================================+
-- | Name             : CANCEL_OE_LINE_PROC                               |
-- | Description      : This program cancels the order line using the     |
-- |                    cancel_line procedure                             |
-- |                                                                      |
-- | Parameters       : p_item_type                                       |
-- |                    p_item_key                                        |
-- |                    p_actid                                           |
-- |                    p_funcmode                                        |
-- |                                                                      |
-- |                                                                      |
-- | Returns          : x_result                                          |
-- |                                                                      |
-- +======================================================================+

    PROCEDURE CANCEL_OE_LINE_PROC (
                                p_item_type  IN  VARCHAR2
                               ,p_item_key   IN  VARCHAR2
                               ,p_actid      IN  NUMBER
                               ,p_funcmode   IN  VARCHAR2
                               ,x_result     OUT VARCHAR2
                                          );

-- +======================================================================+
-- | Name             : SPLIT_LINE                                        |
-- | Description      : This procedure splits the sales order line        |
-- |                    based on the ordered quantity and quantity        |
-- |                    quantity received                                 |
-- | Parameters       : p_line_id                                         |
-- |                                                                      |
-- | Returns          : x_return_status                                   |
-- |                    x_return_message                                  |
-- +======================================================================+

    PROCEDURE SPLIT_LINE (
                        p_line_id          IN       oe_order_lines_all.line_id%TYPE
                       ,x_return_status    OUT      VARCHAR2
                       ,x_return_message   OUT      VARCHAR2
                     );

-- +===================================================================+
-- | Name           : UPDATE_OE_LINE_DFF                               |
-- | Description    : Updates the custom table sales order line        |
-- |                  attributes.                                      |
-- | Parameters     : p_line_id                                        |
-- |                                                                   |
-- | Returns        : x_return_status                                  |
-- |                  x_return_message                                 |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE UPDATE_OE_LINE_DFF (
                               p_line_id         IN  oe_order_lines_all.line_id%TYPE
                              ,x_return_status   OUT VARCHAR2
                              ,x_return_message  OUT VARCHAR2
                             );
-- +===================================================================+
-- | Name           : REQ_DIST                                         |
-- | Description    : Gets the requsition distribution Id of the newly |
-- |                  created requisition in a partial receipt         |
-- |                  scenario.                                        |
-- | Parameters     : p_req_dist_id                                    |
-- |                                                                   |
-- | Returns        : NUMBER                                           |
-- |                                                                   |
-- +===================================================================+

    FUNCTION REQ_DIST ( p_req_dist_id IN po_req_distributions_all.distribution_id%TYPE ) 
    RETURN NUMBER;

END XX_WFL_POACCREJ_PKG;

/
SHOW ERROR

