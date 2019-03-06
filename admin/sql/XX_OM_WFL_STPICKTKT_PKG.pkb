SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_wfl_stpicktkt_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_OM_WFL_STPICKTKT_PKG                                    |
-- | Rice ID     : I0215_OrdtoPOS                                             |
-- | Description : Custom Package to contain internal procedures to launch the|
-- |               Pick Ticket Generation Program and to launch Pick Ticket   |
-- |               Custom Business Event                                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |DRAFT 1A 20-Feb-2007 Vidhya Valantina T     Initial draft version         |
-- |DRAFT 1B 18-Jun-2007 Vidhya Valantina T     Changes as per new standards  |
-- |1.0      02-Aug-2007 Vidhya Valantina T     Baselined after testing       |
-- |                                                                          |
-- +==========================================================================+

AS                                                     -- Package Block
-- --------------------
-- Procedure Definition
-- --------------------

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
    -- | Name  : Raise_Picktkt_Busevent                                    |
    -- | Description : This procedure is to raise a custom business event  |
    -- |               from the Order Line Workflow for every line that is |
    -- |               scheduled or booked.                                |
    -- |                                                                   |
    -- | Parameters :       ItemType                                       |
    -- |                    ItemKey                                        |
    -- |                    ActId                                          |
    -- |                    FuncMode                                       |
    -- |                                                                   |
    -- | Returns :          Result                                         |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Raise_Picktkt_Busevent ( p_itemtype        IN  VARCHAR2
                                      ,p_itemkey         IN  VARCHAR2
                                      ,p_actid           IN  NUMBER
                                      ,p_funcmode        IN  VARCHAR2
                                      ,x_result         OUT  NOCOPY VARCHAR2 )
    IS

    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------

        l_parameter_list    wf_parameter_list_t;

        lc_err_buf          VARCHAR2(1000):= NULL;
        lc_err_code         VARCHAR2(240) := NULL;
        lc_event_key        VARCHAR2(100);

        ld_sysdate          DATE := SYSDATE;

    BEGIN

    -- -------------------------------
    -- Global Variable Initializations
    -- -------------------------------

        xx_om_stpicktkt_int_pkg.gc_step_number := 0;

    -- ------------------------------
    -- Local Variable Initializations
    -- ------------------------------

        l_parameter_list    := wf_parameter_list_t();

        lc_event_key        := 'ORDERTOPOS';

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Start of Raise_Picktkt_Busevent Procedure.' );

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Raising the custom business event oracle.apps.ont.ordlin.pos.schlin ' );


    -- -------------------------
    -- Initialize Parameter List
    -- -------------------------

        WF_EVENT.Addparametertolist('Item_Type'
                                    ,p_itemtype
                                    ,l_parameter_list
                                   );

        WF_EVENT.Addparametertolist('Item_Key'
                                    ,p_itemkey
                                    ,l_parameter_list
                                   );

        WF_EVENT.Addparametertolist('Func_Mode'
                                    ,p_funcmode
                                    ,l_parameter_list
                                   );

    -- -----------------------------
    -- Call to raise outbound custom
    -- business event "Pick Ticket"
    -- -----------------------------

        WF_EVENT.Raise ( p_event_name => 'oracle.apps.ont.ordlin.pos.schlin'
                        ,p_event_key  => lc_event_key
                        ,p_parameters => l_parameter_list
                        ,p_send_date  => ld_sysdate + 0.01
                       );

        l_parameter_list.DELETE;

        COMMIT;

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Business Event Launched Successfully ' );
        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'End of Raise_Picktkt_Busevent Procedure.' );

    EXCEPTION

    WHEN OTHERS THEN

        x_result := 'Exception in procedure xx_om_stpicktkt_int_pkg.Raise_Picktkt_Busevent due to : ' || SQLERRM;
        xx_om_stpicktkt_int_pkg.Write_Log( 0 , x_result );

        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');

        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        lc_err_buf           := FND_MESSAGE.GET;
        lc_err_code          := 'XX_OM_65100_UNEXPECTED_ERR1';

        -- -------------------------------------
        -- Call the Write_Exception procedure to
        -- insert into Global Exception Table
        -- -------------------------------------

        Write_Exception (
                            p_error_code        => lc_err_code
                           ,p_error_description => lc_err_buf
                           ,p_entity_reference  => 'ORDER_LINE_ID'
                           ,p_entity_ref_id     => p_itemkey
                        );

    END Raise_Picktkt_Busevent;

    -- +===================================================================+
    -- | Name  : Validate_Order_Line                                       |
    -- | Description : This function is the PL/SQL Rule Function for the   |
    -- |               business event subscription defined for the business|
    -- |               event "oracle.apps.ont.ordlin.pos.schlin".          |
    -- |                                                                   |
    -- |               This function will validate the population of       |
    -- |               delivery detail lines and launch a custom concurrent|
    -- |               program, namely,"OD OM Store Pick Up Pick Release", |
    -- |               upon successful completion of the Pick Release the  |
    -- |               function will invoke a BPEL Process to send the     |
    -- |               "Pick Ticket" to the "OD Notify Application".       |
    -- |                                                                   |
    -- | Parameters :       Subscription_Guid                              |
    -- |                    Event                                          |
    -- |                                                                   |
    -- | Returns :          Varchar2                                       |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION Validate_Order_Line ( p_subscription_guid IN RAW
                                  ,p_event             IN OUT WF_EVENT_T )
    RETURN VARCHAR2
    IS

    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------
        l_parameter_list    wf_parameter_list_t;

        lc_booked_flag      VARCHAR2(1);
        lc_err_buf          VARCHAR2(2000):= NULL;
        lc_err_code         VARCHAR2(240) := NULL;
        lc_funcmode         VARCHAR2(100);
        lc_itemtype         VARCHAR2(2000);
        lc_itemkey          VARCHAR2(2000);
        lc_pk_rule_name     wsh_picking_rules.name%TYPE;
        lc_result           VARCHAR2(100);

        ln_appl_id          NUMBER;
        ln_cnt_del_lines    NUMBER;
        ln_cnt_ord_lines    NUMBER;
        ln_cnt_val_orgn     NUMBER;
        ln_ord_num          oe_order_headers_all.order_number%TYPE;
        ln_orgn_id          wsh_delivery_details.organization_id%TYPE;
        ln_pk_rule_id       wsh_picking_rules.picking_rule_id%TYPE;
        ln_resp_id          NUMBER;
        ln_ret_code         NUMBER;
        ln_src_hdr_id       wsh_delivery_details.source_header_id%TYPE;
        ln_src_lin_id       wsh_delivery_details.source_line_id%TYPE;
        ln_user_id          NUMBER;
        ln_val_orgn         NUMBER;
        ln_val_orgn_id      NUMBER;

    -- -------------------
    -- Cursor Declarations
    -- -------------------

      -- -------------------------------------------------------------
      -- Cursor to fetch the order number for a given source header id
      -- -------------------------------------------------------------
        CURSOR lcu_ord_num ( p_src_lin_id NUMBER )
        IS
        SELECT OOH.order_number
              ,OOH.header_id
              ,OOH.booked_flag
              ,OOH.flow_status_code
              ,OOL.ship_from_org_id
        FROM   oe_order_headers        OOH
              ,oe_order_lines          OOL
        WHERE  OOL.line_id           = p_src_lin_id
        AND    OOH.header_id         = OOL.header_id
        AND    OOH.flow_status_code  = 'BOOKED'
        AND    OOH.booked_flag       = 'Y';

      -- --------------------------------------------------------------
      -- Cursor to derive the count of records in OM base tables having
      -- no holds applied on the lines for the given header id
      -- --------------------------------------------------------------
        CURSOR lcu_cnt_ord_lines ( p_src_hdr_id NUMBER
                                  ,p_orgn_id    NUMBER )
        IS
        SELECT COUNT(1)               cnt_ord_lines
        FROM   oe_order_lines         OOL
        WHERE  OOL.header_id        = p_src_hdr_id
        AND    OOL.ship_from_org_id = p_orgn_id
        AND    EXISTS (
                        SELECT 1
                        FROM   hr_organization_units_v  HOUV
                        WHERE  HOUV.organization_id   = OOL.ship_from_org_id
                        AND    HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
                        AND    TRUNC (SYSDATE) BETWEEN NVL(HOUV.date_from, TRUNC (SYSDATE))
                                                   AND NVL(HOUV.date_to  , TRUNC (SYSDATE))
                      )
        AND    NOT EXISTS (
                            SELECT 1
                            FROM   oe_order_holds         OH
                                  ,oe_hold_definitions    HO
                                  ,oe_hold_sources        HS
                            WHERE  OH.header_id        = OOL.header_id
                            AND    OH.hold_source_id   = HS.hold_source_id
                            AND    HS.hold_id          = HO.hold_id
                            AND    OH.hold_release_id IS NULL
                            AND    OH.released_flag    = 'N'
                            AND    OH.line_id IS NOT NULL
                            AND    OH.line_id          = OOL.line_id
                          );

      -- -----------------------------------------------------
      -- Cursor to validate the type of Inventory Organization
      -- -----------------------------------------------------
        CURSOR lcu_val_orgn ( p_orgn_id NUMBER )
        IS
        SELECT  COUNT(1)                 val_orgn
        FROM    hr_organization_units_v  HOUV
        WHERE   HOUV.organization_id   = p_orgn_id
        AND     HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
        AND     TRUNC (SYSDATE) BETWEEN NVL(HOUV.date_from, TRUNC (SYSDATE))
                                    AND NVL(HOUV.date_to  , TRUNC (SYSDATE));

      -- --------------------------------------------------------------
      -- Cursor to derive the count of records in OM base tables having
      -- no holds applied on the lines for the given header id
      -- --------------------------------------------------------------
        CURSOR lcu_cnt_del_lines ( p_src_hdr_id NUMBER
                                  ,p_orgn_id    NUMBER )
        IS
        SELECT COUNT (1)               cnt_del_lines
        FROM   wsh_delivery_details    WDL
        WHERE  WDL.source_header_id  = p_src_hdr_id
        AND    WDL.organization_id   = p_orgn_id
        AND    EXISTS (
                        SELECT 1
                        FROM   hr_organization_units_v  HOUV
                        WHERE  HOUV.organization_id   = WDL.organization_id
                        AND    HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
                        AND    TRUNC (SYSDATE) BETWEEN NVL(HOUV.date_from, TRUNC (SYSDATE))
                                                   AND NVL(HOUV.date_to  , TRUNC (SYSDATE))
                      )
        AND    NOT EXISTS (
                            SELECT 1
                            FROM   oe_order_holds       OH
                                  ,oe_hold_definitions  HO
                                  ,oe_hold_sources      HS
                            WHERE OH.header_id       = WDL.source_header_id
                            AND   OH.hold_source_id  = HS.hold_source_id
                            AND   HS.hold_id         = HO.hold_id
                            AND   OH.hold_release_id IS NULL
                            AND   OH.released_flag   = 'N'
                            AND   OH.line_id IS NOT NULL
                            AND   OH.line_id         = WDL.source_line_id
                          );

      -- --------------------------------------------------------------
      -- Cursor to derive the count of valid inventory organizations
      -- available on the delivery detail lines for the given header id
      -- --------------------------------------------------------------
        CURSOR lcu_cnt_val_orgn ( p_src_hdr_id NUMBER )
        IS
        SELECT COUNT (*) cnt_val_orgn
        FROM (
               SELECT COUNT (WDL.organization_id)
               FROM   wsh_delivery_details    WDL
               WHERE  WDL.source_header_id = p_src_hdr_id
               AND    EXISTS (
                               SELECT 1
                               FROM   hr_organization_units_v  HOUV
                               WHERE  HOUV.organization_id   = WDL.organization_id
                               AND    HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
                               AND    TRUNC (SYSDATE) BETWEEN NVL (HOUV.date_from, TRUNC (SYSDATE))
                                                          AND NVL (HOUV.date_to  , TRUNC (SYSDATE))
                             )
               AND    NOT EXISTS (
                                   SELECT 1
                                   FROM   oe_order_holds         OH
                                         ,oe_hold_definitions    HO
                                         ,oe_hold_sources        HS
                                   WHERE  OH.header_id        = WDL.source_header_id
                                   AND    OH.hold_source_id   = HS.hold_source_id
                                   AND    HS.hold_id          = HO.hold_id
                                   AND    OH.hold_release_id IS NULL
                                   AND    OH.released_flag    = 'N'
                                   AND    OH.line_id IS NOT NULL
                                   AND    OH.line_id          = WDL.source_line_id
                                 )
               GROUP BY WDL.organization_id
             ) WDTL;

      -- ------------------------------------------------------
      -- Cursor to derive the release rule name / release id
      -- based on the combination of the inventory organization
      -- and the ship method which should be 'PICKUP'
      -- ------------------------------------------------------
        CURSOR lcu_rel_rule ( p_orgn_id NUMBER )
        IS
        SELECT WPRV.picking_rule_name
              ,WPRV.picking_rule_id
        FROM   wsh_picking_rules_v WPRV
        WHERE  WPRV.organization_id = p_orgn_id
        AND    ROWNUM               = 1
        AND    EXISTS (
                        SELECT 1
                        FROM   hr_organization_units_v  HOUV
                        WHERE  HOUV.organization_id   = WPRV.organization_id
                        AND    HOUV.organization_type = xx_om_stpicktkt_int_pkg.gc_store
                        AND    TRUNC (SYSDATE) BETWEEN NVL(HOUV.date_from, TRUNC (SYSDATE))
                                                   AND NVL(HOUV.date_to  , TRUNC (SYSDATE))
                      )
        AND    EXISTS (
                        SELECT 1
                        FROM   fnd_lookup_values_vl   FLV
                        WHERE  FLV.lookup_type      = 'SHIP_METHOD'
                        AND    FLV.lookup_code      LIKE '%PICKUP%'
                        AND    FLV.lookup_code      = WPRV.ship_method_code
                        AND    EXISTS (
                                        SELECT 1
                                        FROM   wsh_carriers                 WC
                                              ,wsh_carrier_services         WCS
                                        WHERE  WC.carrier_id              = WCS.carrier_id
                                        AND    NVL (WC.generic_flag, 'N') = 'N'
                                        AND    WCS.ship_method_code       = FLV.lookup_code
                                      )
                      );

      -- ---------------------------------------------
      -- Cursor to fetch all the delivery detail lines
      -- grouped by the header id and organization id
      -- ---------------------------------------------
        CURSOR lcu_ord_val_orgn ( p_src_hdr_id NUMBER
                                 ,p_orgn_id    NUMBER )
        IS
        SELECT OOH.header_id
              ,WDD.organization_id
        FROM   wsh_delivery_details   WDD
              ,oe_order_headers_all   OOH
        WHERE  WDD.source_header_id = p_src_hdr_id
        AND    WDD.organization_id  = p_orgn_id
        AND    WDD.source_header_id = OOH.header_id
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
                          )
        GROUP BY OOH.header_id
                ,WDD.organization_id;

    BEGIN                                          -- Begin Procedure Block

    -- -------------------------------
    -- Global Variable Initializations
    -- -------------------------------

        xx_om_stpicktkt_int_pkg.gc_step_number := 0;

    -- ------------------------------
    -- Local Variable Initializations
    -- ------------------------------
        l_parameter_list    := wf_parameter_list_t();

        lc_booked_flag      := NULL;
        lc_err_buf          := NULL;
        lc_funcmode         := NULL;
        lc_itemtype         := NULL;
        lc_itemkey          := NULL;
        lc_pk_rule_name     := NULL;
        lc_result           := NULL;

        ln_appl_id          := 0;
        ln_cnt_del_lines    := 0;
        ln_cnt_ord_lines    := 0;
        ln_cnt_val_orgn     := 0;
        ln_ord_num          := 0;
        ln_orgn_id          := 0;
        ln_pk_rule_id       := 0;
        ln_resp_id          := 0;
        ln_ret_code         := 0;
        ln_src_hdr_id       := 0;
        ln_src_lin_id       := 0;
        ln_val_orgn         := 0;
        ln_val_orgn_id      := 0;
        ln_user_id          := 0;

        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Start of Validate Order Line' );


        l_parameter_list    := p_event.getParameterList();

        lc_funcmode         := WF_EVENT.GetValueForParameter( 'Func_Mode'
                                                             ,l_parameter_list );

        lc_itemtype         := WF_EVENT.GetValueForParameter( 'Item_Type'
                                                             ,l_parameter_list );

        lc_itemkey          := WF_EVENT.GetValueForParameter( 'Item_Key'
                                                             ,l_parameter_list);

      -- ---------------------------
      -- Check if Func Mode is 'RUN'
      -- ---------------------------
        IF ( lc_funcmode = 'RUN' ) THEN

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Func Mode is ''RUN''' );

        -- ----------------
        -- Set Apps Context
        -- ----------------

            ln_user_id := wf_engine.GetItemAttrNumber(
                                                       itemtype => lc_itemtype
                                                      ,itemkey  => lc_itemkey
                                                      ,aname    => 'USER_ID'
                                                     );
            ln_resp_id := wf_engine.GetItemAttrNumber(
                                                       itemtype => lc_itemtype
                                                      ,itemkey  => lc_itemkey
                                                      ,aname    => 'RESPONSIBILITY_ID'
                                                     );
            ln_appl_id := wf_engine.GetItemAttrNumber(
                                                       itemtype => lc_itemtype
                                                      ,itemkey  => lc_itemkey
                                                      ,aname    => 'APPLICATION_ID'
                                                     );
            fnd_global.apps_initialize(
                                        user_id      => ln_user_id
                                       ,resp_id      => ln_resp_id
                                       ,resp_appl_id => ln_appl_id
                                      );


            ln_src_lin_id := TO_NUMBER( lc_itemkey );

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Src Lin Id is ' || ln_src_lin_id );

          -- ---------------------------------------------------
          -- Fetch the order number for a given source header id
          -- ---------------------------------------------------
            FOR ord_num_rec IN lcu_ord_num ( p_src_lin_id => ln_src_lin_id )
            LOOP

                ln_ord_num     := ord_num_rec.order_number;
                ln_src_hdr_id  := ord_num_rec.header_id;
                lc_booked_flag := ord_num_rec.booked_flag;
                ln_orgn_id     := ord_num_rec.ship_from_org_id;

            END LOOP;

            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Orgn Id is '    || ln_orgn_id    );
            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Src Hdr Id is ' || ln_src_hdr_id );
            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Ord Number is ' || ln_ord_num    );

          -- ------------------------
          -- Check if Order is Booked
          -- ------------------------
            IF ( lc_booked_flag = 'Y' ) THEN

                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Order is Booked' );

              -- ------------------------------------------------------
              -- Derive the count of records in OE_ORDER_LINES having
              -- no holds applied on the lines for the given header id
              -- ------------------------------------------------------
                FOR cnt_ord_lines_rec IN lcu_cnt_ord_lines ( p_src_hdr_id => ln_src_hdr_id
                                                            ,p_orgn_id    => ln_orgn_id )
                LOOP

                    ln_cnt_ord_lines := cnt_ord_lines_rec.cnt_ord_lines;

                END LOOP;

                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Count of Order Lines is ' || ln_cnt_ord_lines );

              -- --------------------------------
              -- Check if Order Lines are present
              -- --------------------------------
                IF ( ln_cnt_ord_lines > 0 ) THEN

                  -- -------------------------------------------
                  -- Validate the type of Inventory Organization
                  -- -------------------------------------------
                    FOR val_orgn_rec IN lcu_val_orgn ( p_orgn_id => ln_orgn_id )
                    LOOP

                        ln_val_orgn := val_orgn_rec.val_orgn;

                    END LOOP;

                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Valid Organization ' || ln_val_orgn );

                  -- ------------------------------------
                  -- If type of Inventory Organization is
                  -- "Store - Inventory Organization"
                  -- ------------------------------------
                    IF ( ln_val_orgn = 1 ) THEN

                      -- ----------------------------------------------------------
                      -- Derive the count of records in WSH_DELIVERY_DETAILS having
                      -- no holds applied on the lines for the given header id
                      -- ----------------------------------------------------------
                        FOR cnt_del_lines_rec IN lcu_cnt_del_lines ( p_src_hdr_id => ln_src_hdr_id
                                                                    ,p_orgn_id    => ln_orgn_id )
                        LOOP

                            ln_cnt_del_lines := cnt_del_lines_rec.cnt_del_lines;

                        END LOOP;

                        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Count of Delivery Lines is ' || ln_cnt_del_lines );

                  -- -------------------------------------------
                  -- If type of Inventory Organization is
                  -- other than "Store - Inventory Organization"
                  -- -------------------------------------------
                    ELSE

                        -- ------------------------------------------------------
                        -- Record should not be picked for Pick Ticket generation
                        --
                        -- Report record details into standard log output file
                        -- ------------------------------------------------------

                        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Not a valid organization and hence not eligible for Pick Ticket Generation' );

                    END IF;

                  -- ----------------------------------------------------------------
                  -- Check if all the order lines from OE_ORDER_HEADERS are available
                  -- as delivery detail lines in WSH_DELIVERY_DETAILS table
                  -- ----------------------------------------------------------------
                    IF ( ln_cnt_ord_lines = ln_cnt_del_lines ) THEN

                        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Equal Order and Delivery Lines ' );

                      -- -------------------------------------------------
                      -- Derive the count of valid inventory organizations
                      -- available for the given header id
                      -- -------------------------------------------------
                        FOR cnt_val_orgn_rec IN lcu_cnt_val_orgn ( p_src_hdr_id => ln_src_hdr_id )
                        LOOP

                            ln_cnt_val_orgn := cnt_val_orgn_rec.cnt_val_orgn;

                        END LOOP;

                      -- --------------------------------------------
                      -- If only one valid inventory organization for
                      -- all the delivery detail lines is available
                      -- --------------------------------------------
                        IF ( ln_cnt_val_orgn = 1 ) THEN

                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Only one Valid Orgn' );

                          -- ------------------------------------------------
                          -- Derive the release rule name / release id based
                          -- on the combination of the inventory organization
                          -- and the ship method which should be 'PICKUP'
                          -- ------------------------------------------------
                            FOR rel_rule_rec IN lcu_rel_rule ( p_orgn_id => ln_orgn_id )
                            LOOP

                                lc_pk_rule_name := rel_rule_rec.picking_rule_name;
                                ln_pk_rule_id   := rel_rule_rec.picking_rule_id;

                            END LOOP;

                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Pick Rule Name is ' || lc_pk_rule_name );
                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Pick Rule Id is '   || ln_pk_rule_id );

                          -- ------------------------------------------------------
                          -- Call the custom procedure to populate the pick release
                          -- batch table and then call the concurrent program to
                          -- pick release the delivery detail lines for this order
                          -- ------------------------------------------------------
                            xx_om_stpicktkt_int_pkg.Store_Pick_Release_Main (
                                                                              x_err_buf          => lc_err_buf
                                                                             ,x_ret_code         => ln_ret_code
                                                                             ,p_inv_org_id       => ln_orgn_id
                                                                             ,p_picking_rule_id  => ln_pk_rule_id
                                                                             ,p_order_header_id  => ln_src_hdr_id
                                                                             ,p_cancelled_order  => 'N'
                                                                            );

                      -- -----------------------------------------------
                      -- If more than one valid inventory organizations
                      -- for all the delivery detail lines are available
                      -- -----------------------------------------------
                        ELSE

                            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'More than one Valid Orgn' );

                          -- ------------------------------------------
                          -- Loop for each valid inventory organization
                          -- ------------------------------------------
                            FOR ord_val_orgn_rec IN  lcu_ord_val_orgn ( p_src_hdr_id => ln_src_hdr_id
                                                                       ,p_orgn_id    => ln_orgn_id )
                            LOOP

                                ln_val_orgn_id := ord_val_orgn_rec.organization_id;

                              -- ------------------------------------------------
                              -- Derive the release rule name / release id based
                              -- on the combination of the inventory organization
                              -- and the ship method which should be 'PICKUP'
                              -- ------------------------------------------------
                                FOR rel_rule_rec IN lcu_rel_rule ( p_orgn_id => ln_val_orgn_id )
                                LOOP

                                    lc_pk_rule_name := rel_rule_rec.picking_rule_name;
                                    ln_pk_rule_id   := rel_rule_rec.picking_rule_id;

                                END LOOP;

                                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Pick Rule Name is ' || lc_pk_rule_name );
                                xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Pick Rule Id is '   || ln_pk_rule_id );

                              -- ------------------------------------------------------
                              -- Call the custom procedure to populate the pick release
                              -- batch table and then call the concurrent program to
                              -- pick release the delivery detail lines for this order
                              -- ------------------------------------------------------
                                xx_om_stpicktkt_int_pkg.Store_Pick_Release_Main (
                                                                                  x_err_buf          => lc_err_buf
                                                                                 ,x_ret_code         => ln_ret_code
                                                                                 ,p_inv_org_id       => ln_val_orgn_id
                                                                                 ,p_picking_rule_id  => ln_pk_rule_id
                                                                                 ,p_order_header_id  => ln_src_hdr_id
                                                                                 ,p_cancelled_order  => 'N'
                                                                                );

                            END LOOP;

                        END IF;

                    END IF;

               END IF;                            -- End of Check if Order Lines are present

               IF ( ln_cnt_del_lines > 0 ) THEN

                    lc_result := 'COMPLETE:Y';
                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Complete' );
                    RETURN lc_result;

               ELSE

                    lc_result := 'COMPLETE:N';
                    xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'No Order Lines' );
                    RETURN lc_result;

               END IF;

            ELSE

               lc_result := 'COMPLETE:Y';
               xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Order is not Booked' );
               RETURN lc_result;

            END IF;                                -- End of Check if Order is Booked

            RETURN lc_result;

        END IF;                                    -- End of Check if Func Mode is 'RUN'

      -- ------------------------------
      -- Check if Func Mode is 'CANCEL'
      -- ------------------------------
        IF ( lc_funcmode = 'CANCEL' ) THEN

            lc_result := 'COMPLETE:Y';
            xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Func Mode is ''CANCEL''' );
            RETURN lc_result;

        END IF;                                    -- End of Check if Func Mode is 'CANCEL'

      -- ------------------------------
      -- Check if Func Mode is anything
      -- other than 'RUN' or 'CANCEL'
      -- ------------------------------
        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Func Mode is neither ''RUN'' NOR ''CANCEL''' );
        lc_result := '';
        RETURN lc_result;

    EXCEPTION                                      -- Exception Block

    WHEN OTHERS THEN

        wf_core.context(
                         'xx_om_wfl_stpicktkt_pkg'
                        ,'Validate_Order_Line'
                        ,lc_itemtype
                        ,lc_itemkey
                        ,'Unknown Error: '||SQLERRM
                       );
        xx_om_stpicktkt_int_pkg.Write_Log( 0 , 'Unknown Error: '||SQLERRM );
        lc_result := wf_engine.eng_error;

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
                         ,p_entity_reference  => 'ORDER_LINE_ID'
                         ,p_entity_ref_id     => lc_itemkey
                        );

        APP_EXCEPTION.RAISE_EXCEPTION;

        RETURN lc_result;

    END  Validate_Order_Line;                      -- End Procedure Block

END xx_om_wfl_stpicktkt_pkg;                      -- End Package Block
/

SHOW ERRORS;