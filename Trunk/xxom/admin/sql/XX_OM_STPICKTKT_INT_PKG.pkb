SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_stpicktkt_int_pkg

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
                              )
    IS

        lc_errbuf    VARCHAR2(4000);

        ln_retcode   NUMBER;

    BEGIN                               -- Procedure Block

        ge_exception.p_error_code        := p_error_code;
        ge_exception.p_error_description := p_error_description;
        ge_exception.p_entity_ref        := p_entity_reference;
        ge_exception.p_entity_ref_id     := p_entity_ref_id;

        xx_om_global_exception_pkg.Insert_Exception (
                                                      ge_exception
                                                     ,lc_errbuf
                                                     ,ln_retcode
                                                    );

    END Write_Exception;                -- End Procedure Block

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
                        )
    IS
    BEGIN

        INSERT INTO VVT_ORDPOS_TEST VALUES( xx_om_stpicktkt_int_pkg.gc_step_number , p_mesg );

        xx_om_stpicktkt_int_pkg.gc_step_number := xx_om_stpicktkt_int_pkg.gc_step_number + 1;

        COMMIT;

/*
        IF ( xx_om_stpicktkt_int_pkg.gc_debug_flag = 'Y' ) THEN

            INSERT INTO VVT_ORDPOS_TEST VALUES( xx_om_stpicktkt_int_pkg.gc_step_number , p_mesg );

            xx_om_stpicktkt_int_pkg.gc_step_number := xx_om_stpicktkt_int_pkg.gc_step_number + 1;

            COMMIT;

            NULL;

        END IF;
*/
    END Write_Log;

    -- +===================================================================+
    -- | Name  : Process_Pick_Ticket                                       |
    -- | Description : This procedure is to fetch all the delivery detail  |
    -- |               information for a given delivery detail id to create|
    -- |               a 'Pick List OAG 9.0 XML' to be sent to ' OD Notify |
    -- |               Application' by the custom BPEL Process             |
    -- |                                                                   |
    -- | Parameters :       Delivery_Detail_Id                             |
    -- |                    Cancelled_Order                                |
    -- |                                                                   |
    -- | Returns :          Delivery_Details_Rec                           |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Process_Pick_Ticket (
                                    p_delivery_detail_id    IN     NUMBER
                                   ,p_cancelled_order       IN     VARCHAR2
                                   ,x_delivery_details_rec  IN OUT NOCOPY wsh_del_det_rec_type
                                   ,p_debug_flag            IN     VARCHAR2 DEFAULT 'N'
                                  )
    IS
    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------

        lc_entity        VARCHAR2(100) := NULL;
        lc_err_buf       VARCHAR2(1000):= NULL;
        lc_err_code      VARCHAR2(240) := NULL;

        ln_entity_ref_id NUMBER := 0;

     -- -------------------
    -- Cursor Declarations
    -- -------------------

      -- --------------------------------------------
      -- Cursor to fetch the delivery detail lines
      -- information for the given delivery detail id
      -- --------------------------------------------
        CURSOR lcu_get_valid_line ( p_delivery_detail_id NUMBER )
        IS
        SELECT 'VALID'                       is_valid
        FROM   wsh_delivery_details          WDD
              ,oe_order_lines_all            OOLA
              ,oe_order_headers_all          OOHA
              ,xx_wsh_delivery_det_att_all   XWDDAA
        WHERE  WDD.source_line_id          = OOLA.line_id
        AND    WDD.source_header_id        = OOHA.header_id
        AND    OOHA.header_id              = OOLA.header_id
        AND    WDD.delivery_detail_id      = XWDDAA.delivery_detail_id
        AND (  (    WDD.delivery_detail_id = p_delivery_detail_id
                AND p_cancelled_order      = 'N' )
             OR
               (    OOHA.header_id         = p_delivery_detail_id
                AND p_cancelled_order      = 'Y' ) )
        AND (  (    p_cancelled_order      = 'N'
                AND OOLA.flow_status_code  = 'RELEASED_TO_WAREHOUSE'
                AND XWDDAA.old_delivery_number   IS NULL
                AND XWDDAA.pkt_transmission_ind  IS NULL )
             OR
               (    p_cancelled_order      = 'Y'
                AND OOLA.flow_status_code  = 'CANCELLED'
                AND OOHA.flow_status_code  = 'CANCELLED'
                AND XWDDAA.old_delivery_number   IS NOT NULL ) );

      -- --------------------------------------------
      -- Cursor to fetch the delivery detail lines
      -- information for the given delivery detail id
      -- --------------------------------------------
        CURSOR lcu_get_delivery_info ( p_delivery_detail_id NUMBER )
        IS
        SELECT WND.name                            delivery_number
              ,OOD.organization_code               inv_org_code
              ,OOD.organization_name               inv_org_name
              ,OOHA.ordered_date                   ordered_date
              ,OOLA.schedule_ship_date             sched_ship_date
              ,OOLA.line_number                    order_line_number
              ,WDD.delivery_detail_id              delivery_detail_id
              ,MSIB.segment1                       segment1
              ,WDD.requested_quantity              ordered_quantity
              ,MSIB.description                    item_description
              ,OOLA.unit_selling_price             unit_selling_price
              ,MTRH.request_number                 move_order_number
              ,MTRL.line_number                    move_order_line_number
        FROM   wsh_delivery_details                WDD
              ,wsh_new_deliveries                  WND
              ,wsh_delivery_assignments            WDA
              ,oe_order_headers_all                OOHA
              ,oe_transaction_types_tl             OTT
              ,ra_terms_tl                         RTT
              ,mtl_system_items_b                  MSIB
              ,mtl_customer_item_xrefs             MCIX
              ,mtl_customer_items                  MCI
              ,org_organization_definitions        OOD
              ,mtl_txn_request_lines               MTRL
              ,mtl_txn_request_headers             MTRH
              ,oe_order_lines_all                  OOLA
        WHERE  WND.delivery_id                 =   WDA.delivery_id
        AND    WDA.delivery_detail_id          =   WDD.delivery_detail_id
        AND    OOHA.order_type_id              =   OTT.transaction_type_id
        AND    OOHA.payment_term_id            =   RTT.term_id
        AND    OOHA.header_id                  =   WDD.source_header_id
        AND    MSIB.inventory_item_id          =   OOLA.inventory_item_id
        AND    MSIB.organization_id            =   WDD.organization_id
        AND    MSIB.inventory_item_id          =   MCIX.inventory_item_id (+)
        AND    NVL(MCIX.inactive_flag,'N')    <>   'Y'
        AND    NVL(MCIX.customer_item_id,-99)  =   MCI.customer_item_id (+)
        AND    OOLA.header_id                  =   WDD.source_header_id
        AND    OOLA.line_id                    =   WDD.source_line_id
        AND    OOD.organization_id             =   WDD.organization_id
        AND    WDD.move_order_line_id          =   MTRL.line_id
        AND    MTRL.header_id                  =   MTRH.header_id
        AND    OOLA.header_id                  =   WDD.source_header_id
        AND    OOLA.line_id                    =   WDD.source_line_id
        AND    WDD.delivery_detail_id          =   p_delivery_detail_id;

      -- ----------------------------------------
      -- Cursor to fetch the customer information
      -- for the given delivery detail id
      -- ----------------------------------------
        CURSOR lcu_get_cust_info ( p_delivery_detail_id NUMBER )
        IS
        SELECT HPS.party_site_number     ship_to_party_site_number
              ,HP.party_name             ship_to_party_name
              ,HCP.raw_phone_number      bill_to_tel_number
        FROM   wsh_delivery_details      WDD
              ,oe_order_lines_all        OOLA
              ,hz_cust_site_uses_all     HCSU
              ,hz_cust_site_uses_all     HCSU1
              ,hz_cust_acct_sites_all    HCAS
              ,hz_cust_acct_sites_all    HCAS1
              ,hz_party_sites            HPS
              ,hz_party_sites            HPS1
              ,hz_parties                HP
              ,hz_parties                HP1
              ,hz_locations              HZ
              ,hz_locations              HZ1
              ,hz_contact_points         HCP
        WHERE  WDD.source_header_id    = OOLA.header_id
        AND    WDD.source_line_id      = OOLA.line_id
        AND    OOLA.ship_to_org_id     = HCSU.site_use_id
        AND    OOLA.invoice_to_org_id  = HCSU1.site_use_id
        AND    HCSU.site_use_code      = 'SHIP_TO'
        AND    HCSU.status             = 'A'
        AND    HCSU1.site_use_code     = 'BILL_TO'
        AND    HCSU1.status            = 'A'
        AND    HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
        AND    HCSU1.cust_acct_site_id = HCAS1.cust_acct_site_id
        AND    HCAS.party_site_id      = HPS.party_site_id
        AND    HCAS1.party_site_id     = HPS1.party_site_id
        AND    HPS1.party_site_id      = HCP.owner_table_id
        AND    HCP.owner_table_name    = 'HZ_PARTY_SITES'
        AND    HCP.status              = 'A'
        AND    HCP.contact_point_type  = 'PHONE'
        AND    HPS.party_id            = HP.party_id
        AND    HPS1.party_id           = HP1.party_id
        AND    HPS.location_id         = HZ.location_id
        AND    HPS1.location_id        = HZ1.location_id
        AND    WDD.delivery_detail_id  = p_delivery_detail_id;

    BEGIN

    -- -------------------------------
    -- Global Variable Initializations
    -- -------------------------------

        xx_om_stpicktkt_int_pkg.gc_debug_flag := p_debug_flag;

    -- -----------------------------
    -- Process Pick Ticket Procedure
    -- -----------------------------

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Start of Process_Pick_Ticket Procedure' );

        FOR get_valid_line_rec IN lcu_get_valid_line ( p_delivery_detail_id )
        LOOP

            IF ( get_valid_line_rec.is_valid <> 'VALID' OR get_valid_line_rec.is_valid IS NULL ) THEN

                 xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Invalid Delivery Detail Line' );

                 x_delivery_details_rec.status := 'INVALID';
                 RETURN;

            END IF;

        END LOOP;

        IF ( p_cancelled_order = 'N' ) THEN

            FOR get_delivery_info_rec IN lcu_get_delivery_info ( p_delivery_detail_id )
            LOOP

                x_delivery_details_rec.delivery_number        := get_delivery_info_rec.delivery_number;
                x_delivery_details_rec.inv_org_code           := get_delivery_info_rec.inv_org_code;
                x_delivery_details_rec.inv_org                := get_delivery_info_rec.inv_org_name;
                x_delivery_details_rec.status                 := 'NEW';
                x_delivery_details_rec.ordered_date           := get_delivery_info_rec.ordered_date;
                x_delivery_details_rec.schedule_ship_date     := get_delivery_info_rec.sched_ship_date;
                x_delivery_details_rec.order_line_number      := get_delivery_info_rec.order_line_number;
                x_delivery_details_rec.delivery_detail_id     := get_delivery_info_rec.delivery_detail_id;
                x_delivery_details_rec.item_sku               := get_delivery_info_rec.segment1;
                x_delivery_details_rec.order_quantity         := get_delivery_info_rec.ordered_quantity;
                x_delivery_details_rec.item_description       := get_delivery_info_rec.item_description;
                x_delivery_details_rec.unit_selling_price     := get_delivery_info_rec.unit_selling_price;
                x_delivery_details_rec.move_order_number      := get_delivery_info_rec.move_order_number;
                x_delivery_details_rec.move_order_line_number := get_delivery_info_rec.move_order_line_number;

            END LOOP;

            FOR get_cust_info_rec IN lcu_get_cust_info ( p_delivery_detail_id )
            LOOP

                x_delivery_details_rec.ship_to_id            := get_cust_info_rec.ship_to_party_site_number;
                x_delivery_details_rec.ship_to_name          := get_cust_info_rec.ship_to_party_name;
                x_delivery_details_rec.telephone_number      := get_cust_info_rec.bill_to_tel_number;

            END LOOP;

            x_delivery_details_rec.total_units               := 0;
            x_delivery_details_rec.email                     := '';
            x_delivery_details_rec.prepaid_flag              := 'Pre Flag';
            x_delivery_details_rec.order_source              := 'Order Source';
            x_delivery_details_rec.seq_number                := 0;

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , ' Obtained the delivery detail record successfully ' );

        ELSIF ( p_cancelled_order = 'Y' ) THEN

            x_delivery_details_rec.status                    := 'CANCELLED';

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , ' Obtained the cancelled delivery detail record successfully ' );

        END IF;

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'End of Process_Pick_Ticket Procedure' );

    EXCEPTION

    WHEN OTHERS THEN

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Exception in procedure xx_om_stpicktkt_int_pkg.Process_Pick_Ticket due to : ' || SQLERRM );

        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');

        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        lc_err_buf           := FND_MESSAGE.GET;
        lc_err_code          := 'XX_OM_65100_UNEXPECTED_ERR1';

        IF ( p_cancelled_order = 'N' ) THEN

            lc_entity := 'DELIVERY_DETAIL_ID';

        ELSIF ( p_cancelled_order = 'Y' ) THEN

            lc_entity := 'ORDER_HEADER_ID';

        END IF;

        -- -------------------------------------
        -- Call the Write_Exception procedure to
        -- insert into Global Exception Table
        -- -------------------------------------

        Write_Exception (
                            p_error_code        => lc_err_code
                           ,p_error_description => lc_err_buf
                           ,p_entity_reference  => lc_entity
                           ,p_entity_ref_id     => p_delivery_detail_id
                        );

    END Process_Pick_Ticket;

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
                                   )
    IS

    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------

        lc_entity        VARCHAR2(100) := NULL;
        lc_err_buf       VARCHAR2(1000):= NULL;
        lc_err_code      VARCHAR2(240) := NULL;

        ln_entity_ref_id NUMBER := 0;

        paramNames   xx_om_bpel_paramlist_t  := xx_om_bpel_paramlist_t('input');
        paramValues  xx_om_bpel_paramlist_t  := xx_om_bpel_paramlist_t('World');

    BEGIN

    -- -------------------------------
    -- Global Variable Initializations
    -- -------------------------------

        xx_om_stpicktkt_int_pkg.gc_debug_flag := p_debug_flag;

    -- ------------------------------
    -- Local Variable Initializations
    -- ------------------------------

        x_status := 'SUCCESS';

    -- ------------------------------
    -- Invoke BPEL Process
    --
    -- Needs to be changed to invoke
    -- the correct BPEL Process
    -- ------------------------------

        xx_om_bpel_utility_pkg.Bpel_Process_Caller(
                    p_bpel_name        => 'FirstBPELProcess'
                   ,p_target_namespace => 'http://xmlns.oracle.com/FirstBPELProcess'
                   ,p_param_names      => paramNames
                   ,p_param_values     => paramValues
                   ,p_bpel_url         => 'http://vtamilma-pc:8888/orabpel/default/FirstBPELProcess/1.0'
                   ,p_action           => 'process'
                   ,p_bpel_output      => x_status
        );

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , ' Invoked BPEL Process Successfully ' );

    EXCEPTION

    WHEN OTHERS THEN

        x_status := 'Exception in procedure xx_om_stpicktkt_int_pkg.Invoke_OrdToPOS_BPEL due to : ' || SQLERRM;

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , x_status );

        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');

        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        lc_err_buf           := FND_MESSAGE.GET;
        lc_err_code          := 'XX_OM_65100_UNEXPECTED_ERR2';

        -- -------------------------------------
        -- Call the Write_Exception procedure to
        -- insert into Global Exception Table
        -- -------------------------------------

        Write_Exception (
                            p_error_code        => lc_err_code
                           ,p_error_description => lc_err_buf
                           ,p_entity_reference  => 'DELIVERY_DETAIL_ID'
                           ,p_entity_ref_id     => p_delivery_details_rec.delivery_detail_id
                        );

    END Invoke_OrdToPOS_BPEL;

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
                                      )
    IS

    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------

        lc_bpel_response    VARCHAR2(100);
        lc_entity           VARCHAR2(100) := NULL;
        lc_err_buf          VARCHAR2(1000):= NULL;
        lc_err_code         VARCHAR2(240) := NULL;
        lc_msg_data         VARCHAR2(4000);
        lc_msg_details      VARCHAR2(4000);
        lc_msg_summary      VARCHAR2(4000);
        lc_pick_phase       VARCHAR2(100);
        lc_pick_result      VARCHAR2(1);
        lc_pick_slip        VARCHAR2(1);
        lc_return_status    VARCHAR2(1);

        ln_batch_id         NUMBER;
        ln_entity_ref_id    NUMBER := 0;
        ln_msg_count        NUMBER;
        ln_ord_num          oe_order_headers_all.order_number%TYPE;

    -- ---------------------------------
    -- Record Type Variable Declarations
    -- ---------------------------------

        lr_batch_rec             WSH_PICKING_BATCHES_PUB.Batch_Info_Rec;
        lr_delivery_details_rec  wsh_del_det_rec_type;

    -- -------------------
    -- Cursor Declarations
    -- -------------------

      -- -----------------------------------------------------
      -- Cursor to fetch the delivery detail lines information
      -- for the given order header id and organization id
      -- -----------------------------------------------------
        CURSOR lcu_deldtllin_info ( p_src_hdr_id NUMBER
                                   ,p_orgn_id    NUMBER )
        IS
        SELECT OOH.order_number
              ,OOH.header_id
              ,OOH.order_type_id
              ,WDD.delivery_detail_id
              ,WDD.customer_id
              ,WDD.inventory_item_id
              ,WDD.organization_id
        FROM   wsh_delivery_details          WDD
              ,oe_order_headers              OOH
              ,xx_wsh_delivery_det_att_all   XWDDAA
        WHERE  WDD.source_header_id        = p_src_hdr_id
        AND    WDD.organization_id         = p_orgn_id
        AND    WDD.source_header_id        = OOH.header_id
        AND    WDD.delivery_detail_id      = XWDDAA.delivery_detail_id
        AND (  (    p_cancelled_order      = 'N'
                AND XWDDAA.old_delivery_number  IS NULL
                AND XWDDAA.pkt_transmission_ind IS NULL )
             OR
               (    p_cancelled_order      = 'Y'
                AND XWDDAA.old_delivery_number  IS NOT NULL ) )
        AND    EXISTS (
                        SELECT 1
                        FROM   hr_organization_units_v  HOUV
                        WHERE  HOUV.organization_id   = WDD.organization_id
                        AND    HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
                        AND    TRUNC (SYSDATE) BETWEEN NVL(HOUV.date_from, TRUNC (SYSDATE))
                                                   AND NVL(HOUV.date_to  , TRUNC (SYSDATE))
                      )
        AND    NOT EXISTS (
                            SELECT 1
                            FROM   oe_order_holds       OH
                                  ,oe_hold_definitions  HO
                                  ,oe_hold_sources      HS
                            WHERE  OH.header_id       = WDD.source_header_id
                            AND    OH.hold_source_id  = HS.hold_source_id
                            AND    HS.hold_id         = HO.hold_id
                            AND    OH.hold_release_id IS NULL
                            AND    OH.released_flag   = 'N'
                            AND    OH.line_id IS NOT NULL
                            AND    OH.line_id         = WDD.source_line_id
                          );

      -- --------------------------------------------
      -- Cursor to fetch the picking rule information
      -- for the given picking rule id
      -- --------------------------------------------
        CURSOR lcu_pickrule_info ( p_pk_rule_id NUMBER
                                  ,p_orgn_id    NUMBER )
        IS
        SELECT WPR.picking_rule_id
              ,WPR.name
              ,WPR.backorders_only_flag
              ,WPR.organization_id
              ,WPR.default_stage_subinventory
              ,WPR.pick_from_subinventory
              ,WPR.auto_pick_confirm_flag
              ,WPR.pick_grouping_rule_id
              ,WPR.pick_sequence_rule_id
              ,WPR.autocreate_delivery_flag
        FROM   wsh_picking_rules                WPR
        WHERE  WPR.picking_rule_id            = p_pk_rule_id
        AND    WPR.organization_id            = p_orgn_id
        AND    rownum                         = 1;

    BEGIN                                 -- Procedure Block

    -- -------------------------------
    -- Global Variable Initializations
    -- -------------------------------

        xx_om_stpicktkt_int_pkg.gc_debug_flag  := p_debug_flag;

    -- ------------------------------
    -- Local Variable Initializations
    -- ------------------------------

       lc_bpel_response    := NULL;
       lc_msg_data         := NULL;
       lc_msg_details      := NULL;
       lc_msg_summary      := NULL;
       lc_pick_phase       := NULL;
       lc_pick_result      := NULL;
       lc_pick_slip        := NULL;
       lc_return_status    := NULL;
       ln_batch_id         := 0;
       ln_msg_count        := 0;
       ln_ord_num          := 0;

       xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Start of Store_Pick_Release_Main Procedure' );

      -- --------------------------------------
      -- Check if the call to the procedure is
      -- to process for the new sales order
      -- --------------------------------------
        IF ( p_cancelled_order = 'N' ) THEN

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Processing a new sales order.');

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Processing every delivery detail line for order : ' || p_order_header_id );

          -- -----------------------------------
          -- Fetch the delivery detail line info
          -- for the given order header id
          -- -----------------------------------
            FOR deldtllin_info_rec IN lcu_deldtllin_info ( p_src_hdr_id => p_order_header_id
                                                          ,p_orgn_id    => p_inv_org_id )
            LOOP

                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Processing delivery detail line : ' || deldtllin_info_rec.delivery_detail_id );

              -- ----------------------------------
              -- Fetch the picking rule information
              -- for the given organization id
              -- ----------------------------------
                FOR pickrule_info_rec IN lcu_pickrule_info ( p_pk_rule_id => p_picking_rule_id
                                                            ,p_orgn_id    => deldtllin_info_rec.organization_id )
                LOOP

                  -- ------------------------
                  -- Create batch record type
                  -- ------------------------
                    lr_batch_rec.order_number               := deldtllin_info_rec.order_number;
                    lr_batch_rec.order_header_id            := deldtllin_info_rec.header_id;
                    lr_batch_rec.delivery_detail_id         := deldtllin_info_rec.delivery_detail_id;
                    lr_batch_rec.organization_id            := deldtllin_info_rec.organization_id;
                    lr_batch_rec.pick_from_subinventory     := pickrule_info_rec.pick_from_subinventory;
                    lr_batch_rec.autocreate_delivery_flag   := pickrule_info_rec.autocreate_delivery_flag;
                    lr_batch_rec.auto_pick_confirm_flag     := pickrule_info_rec.auto_pick_confirm_flag;
                    lr_batch_rec.pick_grouping_rule_id      := pickrule_info_rec.pick_grouping_rule_id;
                    lr_batch_rec.pick_sequence_rule_id      := pickrule_info_rec.pick_sequence_rule_id;
                    lr_batch_rec.default_stage_subinventory := pickrule_info_rec.default_stage_subinventory;
                    lr_batch_rec.backorders_only_flag       := pickrule_info_rec.backorders_only_flag;

                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Creating the pick batch release record by calling API' );

                  -- -----------------------------------
                  -- Create batch using API and populate
                  -- the pick release batch table
                  -- -----------------------------------
                    WSH_PICKING_BATCHES_PUB.Create_Batch (
                                                           p_api_version      =>  1.0
                                                          ,p_init_msg_list    =>  fnd_api.g_false
                                                          ,p_commit           =>  fnd_api.g_false
                                                          ,x_return_status    =>  lc_return_status
                                                          ,x_msg_count        =>  ln_msg_count
                                                          ,x_msg_data         =>  lc_msg_data
                                                          ,p_batch_rec        =>  lr_batch_rec
                                                          ,x_batch_id         =>  ln_batch_id
                                                         );

                    IF ( lc_return_status <> fnd_api.g_ret_sts_success ) THEN

                        WSH_UTIL_CORE.get_messages(
                                                    p_init_msg_list  =>  'Y'
                                                   ,x_summary        =>  lc_msg_summary
                                                   ,x_details        =>  lc_msg_details
                                                   ,x_count          =>  ln_msg_count
                                                  );
                        IF ln_msg_count > 1 THEN

                            x_err_buf := lc_msg_summary || CHR(10) || lc_msg_details;

                        ELSE

                            x_err_buf := lc_msg_summary;

                        END IF;

                        x_ret_code:= 1;
                        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'API FAILED: WSH_PICKING_BATCHES_PUB.Create_Batch. Unexpected Error due to : ' || x_err_buf );
                        RETURN;

                    ELSE

                        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'API SUCCESS: WSH_PICKING_BATCHES_PUB.Create_Batch. Batch Created with Id : ' || ln_batch_id );

                      -- -----------------------------------
                      -- Call the "Pick Selection List Generation Program
                      -- the pick release batch table
                      -- -----------------------------------
                        WSH_PICK_LIST.Online_Release (
                                                       p_batch_id    => ln_batch_id
                                                      ,p_pick_result => lc_pick_result
                                                      ,p_pick_phase  => lc_pick_phase
                                                      ,p_pick_skip   => lc_pick_slip
                                                     );

                        IF ( lc_pick_result <> fnd_api.g_ret_sts_success ) THEN

                            WSH_UTIL_CORE.get_messages(
                                                        p_init_msg_list  =>  'Y'
                                                       ,x_summary        =>  lc_msg_summary
                                                       ,x_details        =>  lc_msg_details
                                                       ,x_count          =>  ln_msg_count
                                                      );
                            IF ln_msg_count > 1 THEN

                                x_err_buf := lc_msg_summary ||CHR(10) || lc_msg_details;

                            ELSE

                                x_err_buf := lc_msg_summary;

                            END IF;

                            x_ret_code:= 1;
                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'API FAILED: WSH_PICK_LIST.Online_Release. Unexpected Error due to : ' || x_err_buf );
                            RETURN;

                        ELSE

                            x_ret_code:= 0;
                            x_err_buf := 'Pick Release Generation Completed Successfully';

                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'API SUCCESS: WSH_PICK_LIST.Online_Release. ' || x_err_buf );

                          -- -----------------------------------------
                          -- Call internal procedure to raise business
                          -- event 'Pick Ticket' for new sales order
                          -- -----------------------------------------

                            Process_Pick_Ticket (
                                                  p_delivery_detail_id   => deldtllin_info_rec.delivery_detail_id
                                                 ,p_cancelled_order      => p_cancelled_order
                                                 ,x_delivery_details_rec => lr_delivery_details_rec
                                                );

                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Delivery Details Record Status ' || lr_delivery_details_rec.status );

                            IF ( lr_delivery_details_rec.status <> 'INVALID' ) THEN

                                Invoke_OrdToPOS_BPEL (
                                                       x_status               => lc_bpel_response
                                                      ,p_delivery_details_rec => lr_delivery_details_rec
                                                     );

                                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'BPEL Response ' || lc_bpel_response );

                                IF ( lc_bpel_response = 'SUCCESS' ) THEN

                                    UPDATE xx_wsh_delivery_det_att_all   XWDDAA
                                    SET    XWDDAA.pkt_transmission_ind = TO_CHAR(TO_DATE(SYSDATE,'DD-MON-RRRR HH24:MI:SS'))
                                    WHERE  XWDDAA.delivery_detail_id   = ( SELECT WDD.delivery_detail_id
                                                                           FROM   wsh_delivery_details    WDD
                                                                           WHERE  WDD.source_line_id  = ( SELECT OOLA.line_id
                                                                                                          FROM   wsh_delivery_details     WDD
                                                                                                                ,oe_order_lines_all       OOLA
                                                                                                                ,oe_order_headers_all     OOHA
                                                                                                          WHERE  OOLA.header_id         = OOHA.header_id
                                                                                                          AND    OOHA.header_id         = WDD.source_header_id
                                                                                                          AND    OOLA.line_id           = WDD.source_line_id
                                                                                                          AND    WDD.delivery_detail_id = deldtllin_info_rec.delivery_detail_id
                                                                                                          AND    OOLA.flow_status_code  = 'RELEASED_TO_WAREHOUSE' )

                                                                           AND    WDD.delivery_detail_id      = deldtllin_info_rec.delivery_detail_id )
                                    AND    XWDDAA.pkt_transmission_ind IS NULL
                                    AND    XWDDAA.old_delivery_number  IS NULL;

                                    IF SQL%NOTFOUND THEN

                                        ROLLBACK;

                                    END IF;

                                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Sent ''Pick Ticket'' to OD Notify Application' );

                                ELSE

                                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Error in sending ''Pick Ticket'' to OD Notify Application' );

                                END IF;

                            ELSE

                                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Invalid Delivery Detail Line' );

                            END IF;

                        END IF;

                    END IF;

                END LOOP;                 -- End Loop for lcu_pickrule_info

            END LOOP;                     -- End Loop for lcu_deldtllin_info

      -- --------------------------------------
      -- Check if the call to the procedure is
      -- to process for cancelled sales order
      -- --------------------------------------
        ELSE

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Processing a cancelled sales order.');

          -- -----------------------------------------
          -- Call internal procedure to raise business
          -- event 'Pick Ticket' for cancelled orders
          -- -----------------------------------------
            Process_Pick_Ticket (
                                  p_delivery_detail_id   => p_order_header_id
                                 ,p_cancelled_order      => p_cancelled_order
                                 ,x_delivery_details_rec => lr_delivery_details_rec
                                );

            IF ( lr_delivery_details_rec.status <> 'INVALID' ) THEN

                Invoke_OrdToPOS_BPEL (
                                       x_status               => lc_bpel_response
                                      ,p_delivery_details_rec => lr_delivery_details_rec
                                     );

                IF ( lc_bpel_response = 'SUCCESS' ) THEN

                    UPDATE xx_wsh_delivery_det_att_all   XWDDAA
                    SET    XWDDAA.pkt_transmission_ind = TO_CHAR(TO_DATE(SYSDATE,'DD-MON-RRRR HH24:MI:SS'))
                          ,XWDDAA.old_delivery_number  = NULL
                    WHERE  XWDDAA.delivery_detail_id   = ( SELECT WDD.delivery_detail_id
                                                           FROM   wsh_delivery_details      WDD
                                                           WHERE  WDD.source_line_id    = ( SELECT OOLA.line_id
                                                                                            FROM   wsh_delivery_details     WDD
                                                                                                  ,oe_order_lines_all       OOLA
                                                                                                  ,oe_order_headers_all     OOHA
                                                                                            WHERE  OOLA.header_id         = OOHA.header_id
                                                                                            AND    OOHA.header_id         = WDD.source_header_id
                                                                                            AND    OOLA.line_id           = WDD.source_line_id
                                                                                            AND    OOHA.header_id         = p_order_header_id
                                                                                            AND    OOLA.flow_status_code  = 'RELEASED_TO_WAREHOUSE' )
                                                           AND    WDD.source_header_id  = p_order_header_id )
                    AND    XWDDAA.pkt_transmission_ind IS NULL
                    AND    XWDDAA.old_delivery_number  IS NOT NULL;

                    IF SQL%NOTFOUND THEN

                        ROLLBACK;

                    END IF;

                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Sent ''Pick Ticket'' to OD Notify Application' );

                ELSE

                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Error in sending ''Pick Ticket'' to OD Notify Application' );

                END IF;

            ELSE

                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Invalid Delivery Detail Line' );

            END IF;

        END IF;

       xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'End of Store_Pick_Release_Main Procedure' );

    EXCEPTION

    WHEN OTHERS THEN

        x_ret_code:= 2;
        x_err_buf := 'Exception in procedure xx_om_stpicktkt_int_pkg.Store_Pick_Release_Main due to : ' || SQLERRM;

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , x_err_buf );

        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');

        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        lc_err_buf           := FND_MESSAGE.GET;
        lc_err_code          := 'XX_OM_65100_UNEXPECTED_ERR3';

        -- -------------------------------------
        -- Call the Write_Exception procedure to
        -- insert into Global Exception Table
        -- -------------------------------------

        Write_Exception (
                          p_error_code        => lc_err_code
                         ,p_error_description => lc_err_buf
                         ,p_entity_reference  => 'ORDER_HEADER_ID'
                         ,p_entity_ref_id     => p_order_header_id
                        );

    END Store_Pick_Release_Main;          -- End Procedure Block

END xx_om_stpicktkt_int_pkg;              -- End Package Block
/

SHOW ERRORS;