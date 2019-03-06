SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_stpicktkt_int_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_OM_STPICKTKT_INT_PKG                                    |
-- | Rice ID     : I0215_OrdtoPOS                                             |
-- | Description : Custom Package to contain internal procedures to store the |
-- |               Pick Ticket and other procedures to raise custom business  |
-- |               events as well to send the Pick Ticket generated           |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |DRAFT 1A 07-Feb-2007 Vidhya Valantina T     Initial draft version         |
-- |DRAFT 1B 18-Jun-2007 Vidhya Valantina T     Changes as per new standards  |
-- |1.0      DD-MON-YYYY Vidhya Valantina T     Baselined after testing       |
-- |                                                                          |
-- +==========================================================================+

AS                                      -- Package Block

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

    gc_debug_flag          VARCHAR2(1);

    gc_step_number         NUMBER;

    gc_store               VARCHAR2(100) := 'Store';

    ge_exception           xx_om_report_exception_t := xx_om_report_exception_t(
                                                                                 'OTHERS'
                                                                                ,'OTC'
                                                                                ,'Order Cycle'
                                                                                ,'Order To POS'
                                                                                ,null
                                                                                ,null
                                                                                ,null
                                                                                ,null
                                                                               );
-- ----------------------------------
-- Record and Table Type Declarations
-- ----------------------------------

    TYPE wsh_del_det_rec_type IS RECORD (
                                          delivery_number            wsh_new_deliveries.name%TYPE
                                         ,inv_org_code               org_organization_definitions.organization_code%TYPE
                                         ,inv_org                    org_organization_definitions.organization_name%TYPE
                                         ,status                     VARCHAR2(20)
                                         ,ship_to_id                 hz_party_sites.party_site_number%TYPE
                                         ,ship_to_name               hz_parties.party_name%TYPE
                                         ,telephone_number           hz_contact_points.raw_phone_number%TYPE
                                         ,ordered_date               DATE
                                         ,schedule_ship_date         DATE
                                         ,total_units                NUMBER
                                         ,email                      ra_contacts.email_address%TYPE
                                         ,prepaid_flag               VARCHAR2(10)
                                         ,order_source               VARCHAR2(100)
                                         ,seq_number                 NUMBER
                                         ,order_line_number          oe_order_lines_all.line_number%TYPE
                                         ,delivery_detail_id         wsh_delivery_details.delivery_detail_id%TYPE
                                         ,item_sku                   mtl_system_items_b.segment1%TYPE
                                         ,order_quantity             wsh_delivery_details.requested_quantity%TYPE
                                         ,item_description           mtl_system_items_b.description%TYPE
                                         ,unit_selling_price         oe_order_lines_all.unit_selling_price%TYPE
                                         ,move_order_number          mtl_txn_request_headers.request_number%TYPE
                                         ,move_order_line_number     mtl_txn_request_lines.line_number%TYPE );

-- -----------------------------------
-- Function and Procedure Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference                               |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                              );

    -- +===================================================================+
    -- | Name  : Write_Log                                                 |
    -- | Description : Procedure to log messages from this package and/or  |
    -- |               online messages in the log file based on debug flag |
    -- |                                                                   |
    -- | Parameters :       Code                                           |
    -- |                    Mesg                                           |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Log (
                          p_code       IN  NUMBER
                         ,p_mesg       IN  VARCHAR2
                        );

    -- +===================================================================+
    -- | Name  : Process_Pick_Ticket                                       |
    -- | Description : This procedure is to fetch all the delivery detail  |
    -- |               information for a given delivery detail id to create|
    -- |               a 'Pick List OAG 9.0 XML' to be sent to ' OD Notify |
    -- |               Application' by the custom BPEL Process             |
    -- |                                                                   |
    -- | Parameters :       Delivery_Detail_Id                             |
    -- |                                                                   |
    -- | Returns :          Delivery_Details_Rec                           |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Process_Pick_Ticket (
                                    p_delivery_detail_id    IN     NUMBER
                                   ,p_cancelled_order       IN     VARCHAR2
                                   ,x_delivery_details_rec  IN OUT NOCOPY wsh_del_det_rec_type
                                   ,p_debug_flag            IN     VARCHAR2 DEFAULT 'N'
                                  );

    -- +===================================================================+
    -- | Name  : Invoke_OrdToPOS_BPEL                                      |
    -- | Description : This procedure is to invoke the BPEL process for    |
    -- |               Order to POS, and send the 'Pick Ticket' to the "OD |
    -- |               Notify Application" which will capture all the      |
    -- |               delivery detail line information having the status  |
    -- |               of "Release to Warehouse".                          |
    -- |                                                                   |
    -- | Parameters :       Delivery_Details_Rec                           |
    -- |                                                                   |
    -- | Returns :          Status                                         |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Invoke_OrdToPOS_BPEL (
                                     x_status               OUT  NOCOPY VARCHAR2
                                    ,p_delivery_details_rec IN   wsh_del_det_rec_type
                                    ,p_debug_flag           IN   VARCHAR2 DEFAULT 'N'
                                   );

    -- +===================================================================+
    -- | Name  : Store_Pick_Release_Main                                   |
    -- | Description : This procedure is to fetch all delivery detail lines|
    -- |               and all the release rule information based on the   |
    -- |               arguments passed in order to populate the pick      |
    -- |               release batch table.                                |
    -- |                                                                   |
    -- | Parameters :       Inv_Org_Id                                     |
    -- |                    Picking_Rule_Id                                |
    -- |                    Order_Header_Id                                |
    -- |                    Cancelled_Order                                |
    -- |                                                                   |
    -- | Returns :          Err_Buf                                        |
    -- |                    Ret_Code                                       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Store_Pick_Release_Main (
                                        x_err_buf          OUT  NOCOPY VARCHAR2
                                       ,x_ret_code         OUT  NOCOPY NUMBER
                                       ,p_inv_org_id       IN   NUMBER
                                       ,p_picking_rule_id  IN   NUMBER
                                       ,p_order_header_id  IN   NUMBER
                                       ,p_cancelled_order  IN   VARCHAR2
                                       ,p_debug_flag       IN   VARCHAR2 DEFAULT 'N'
                                      );

END xx_om_stpicktkt_int_pkg;             -- End Package Block
/

SHOW ERRORS;