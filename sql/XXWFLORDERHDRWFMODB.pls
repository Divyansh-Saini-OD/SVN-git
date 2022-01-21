SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_WFL_ORDERHDRWFMOD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_WFL_ORDERHDRWFMOD_PKG                                  |
-- | Description      : Package Body containing applying OD specific   |
-- |                    holds for the order                            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   04-May-2007   Shashi Kumar.    Initial Draft version    |
-- |                                                                   |
-- +===================================================================+

AS

-- Global Varibles for the exceptions --

g_entity_ref        VARCHAR2(1000);
g_entity_ref_id     NUMBER;
g_error_description VARCHAR2(4000);
g_error_code        VARCHAR2(100);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Rice Id      : E0244                                              |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  IN:                                                  |
-- |     P_Error_Code        --Custom error code                       |
-- |     P_Error_Description --Custom Error Description                |
-- |     p_exception_header  --Errors occured under the exception      |
-- |                           'NO_DATA_FOUND / OTHERS'                |
-- |     p_entity_ref        --'Hold id'                               |
-- |     p_entity_ref_id     --'Value of the Hold Id'                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   09-May-2007   Shashi Kumar     Initial draft version    |
-- +===================================================================+

/*PROCEDURE log_exceptions
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_exception_header  := 'OTHERS';
   g_exception.p_track_code        := 'OTC';
   g_exception.p_solution_domain   := 'Order Management';
   g_exception.p_function          := 'Order Header Workflow';
   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XXOD_GLOBAL_EXCEPTION_PKG.insert_exception(g_exception
                                                 ,x_errbuf
                                                 ,x_retcode
                                                 );
   END;
END log_exceptions;*/

-- +===================================================================+
-- | Name  : Apply_Hold_Before_Booking                                 |
-- |                                                                   |
-- | Description: This Procedure is used to update the holds and       |
-- |              perform inventory reservation in EBS.                |
-- |                                                                   |
-- | Parameters:  p_delivery_rec                                       |
-- |                                                                   |
-- | Returns :    x_status ,  x_message                                |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Apply_Hold_Before_Booking(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          ) IS

    p_hold_source_rec            OE_HOLDS_PVT.Hold_Source_Rec_Type;
    ln_hold_id                   NUMBER;
    ln_api_version               NUMBER;
    ln_commit                    VARCHAR2(10);
    ln_validation_level          VARCHAR2(1000);
    lc_hold_name                 varchar2(1000);
    ln_hold_until_date           DATE;
    ln_hold_comment              VARCHAR2(4000);
    x_return_status              VARCHAR2(10);
    x_msg_count                  NUMBER;
    x_msg_data                   VARCHAR2(1000);
    l_create_rsv_rec             INV_RESERVATION_GLOBAL.mtl_reservation_rec_type;
    l_qry_rsv_rec                INV_RESERVATION_GLOBAL.mtl_reservation_rec_type;
    l_dummy_sn                   INV_RESERVATION_GLOBAL.serial_number_tbl_type;
    lc_rule_fun                  VARCHAR2(32767);
    lc_rule_fun_name             VARCHAR2(1000);
    lc_hold_flag                 VARCHAR2(1);
    ln_org_id                    NUMBER;
    ln_init_msg_list             VARCHAR2(100) := fnd_api.g_true;
    lc_commit                    VARCHAR2(100);
    lc_hold_existing_flg         VARCHAR2(100);
    lc_hold_future_flg           VARCHAR2(100);
    lc_validation_level          VARCHAR2(100);
    lc_rule_func_name            VARCHAR2(1000);
    ln_ship_from_org_id          NUMBER;
    ln_header_id                 NUMBER;

    lc_partial_reservation_flag  VARCHAR2(100);
    lc_force_reservation_flag    VARCHAR2(100);
    lc_validation_flag           VARCHAR2(100);
    ln_quantity_reserved         NUMBER;
    ln_reservation_id            NUMBER;
    l_api_name          CONSTANT VARCHAR2(30) := 'Process_Line';

    p_api_version                NUMBER ;
    p_init_msg_list              VARCHAR2(1000) ;
    p_commit                     VARCHAR2(1000) := FND_API.G_FALSE;
    p_validation_level           NUMBER;
    p_order_tbl                  OE_HOLDS_PVT.order_tbl_type;
    p_hold_id                    OE_HOLD_DEFINITIONS.HOLD_ID%TYPE;
    p_hold_until_date            OE_HOLD_SOURCES.HOLD_UNTIL_DATE%TYPE;
    p_hold_comment               OE_HOLD_SOURCES.HOLD_COMMENT%TYPE ;
    l_message                    VARCHAR2(2000);
    ln_reserve_count             NUMBER;

    --variable holding the error details
    ------------------------------------
    ln_exception_occured         NUMBER       := 0;
    lc_exception_hdr             VARCHAR2(40);
    lc_error_code                VARCHAR2(40);
    lc_error_desc                VARCHAR2(1000);
    lc_entity_ref                VARCHAR2(40);
    lc_entity_ref_id             NUMBER;

    --Variables required for setting Apps contexts
    ----------------------------------------------
    ln_msg_index_out              NUMBER(10);
    ln_user_id                    NUMBER;
    ln_resp_id                    NUMBER;
    ln_appl_id                    NUMBER;

   --Cursor fetching the rule-functions for the hold id passed
   -----------------------------------------------------------
    CURSOR lcu_hold IS
    SELECT xoom.hold_definition_id,
           xoom.hold_id,
           (SELECT NAME 
            FROM oe_hold_definitions ohd 
            WHERE ohd.hold_id = xoom.hold_id
           ) NAME,
           xoom.type_code,
           xoom.hold_type,
           xoom.org_id,
           xoom.no_of_days,
           xoom.credit_authorization,
           xoom.rule_function,
           xoom.rule_function_name,
           xoom.order_booking_status,
           xoom.send_to_pool
    FROM   xx_ont_odholdframework_tbl xoom
    WHERE  xoom.hold_id IN (SELECT ohd.hold_id
                            FROM   oe_hold_definitions ohd
                            WHERE  ohd.name LIKE 'OD%'
                            AND    SYSDATE BETWEEN NVL(START_DATE_ACTIVE,sysdate-1)  AND nvl(END_DATE_ACTIVE,sysdate +1)
                            )
    AND    xoom.order_booking_status   = 'B'
    AND    xoom.apply_to_order_or_line = 'O'
    AND    xoom.hold_type = 'A';

    CURSOR lcu_line_info IS
    SELECT oola.line_id,
           oola.ordered_item_id,
           order_quantity_uom,
           ordered_quantity
    FROM   oe_order_lines_all oola
    WHERE  oola.header_id = ln_header_id;
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    DBMS_OUTPUT.PUT_LINE('In proc');

     IF command = 'RUN' THEN

        ln_header_id := TO_NUMBER(i_itemkey);

        ----------------------
        -- Set Apps Context --
        ----------------------
        ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
        ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
        ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
        fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);

        --Validating order status, which should be in Entered
        -----------------------------------------------------

            BEGIN

                SELECT ooha.org_id
                INTO   ln_org_id
                FROM   oe_order_headers_all ooha
                WHERE  ooha.header_id = ln_header_id;

            EXCEPTION WHEN OTHERS THEN
            
                g_entity_ref        := 'Unexpected Error while getting the org_id for ' || ln_header_id;
                g_entity_ref_id     := 0;

                FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                g_error_description:= FND_MESSAGE.GET;
                g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

  --              log_exceptions;

                --Logging error in standard wf error
                ------------------------------------
                WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                'Unexpected error occured while compiling the rule function :' || ln_header_id);
                resultout := 'ERROR:';
                APP_EXCEPTION.RAISE_EXCEPTION;

            END;
            
            DBMS_OUTPUT.PUT_LINE('Before compiling rule function');
            
            FOR cur_hold IN lcu_hold LOOP
            
                lc_rule_fun                        := cur_hold.rule_function;
                lc_rule_func_name                  := cur_hold.rule_function_name;
                p_hold_source_rec.hold_id          := cur_hold.hold_id;
                lc_hold_name                       := cur_hold.name;
                p_hold_source_rec.last_update_date := SYSDATE;
                p_hold_source_rec.last_updated_by  :=  2001 ; --ln_user_id;                             -- change it to the current user
                p_hold_source_rec.creation_date    := SYSDATE;
                p_hold_source_rec.created_by       := 2001;                             -- change it to the current user
                p_hold_source_rec.hold_comment     := 'XX TEST OD TO Be Determined';    -- Determine with milind
                p_hold_source_rec.org_id           := ln_org_id;
                p_hold_source_rec.header_id        := ln_header_id;

/*                BEGIN

                    DBMS_OUTPUT.PUT_LINE('Before compiling rule function1');

                    EXECUTE IMMEDIATE lc_rule_fun;
                    
                    DBMS_OUTPUT.PUT_LINE('After compiling rule function1');

                EXCEPTION
                  WHEN OTHERS THEN
                      g_entity_ref        := 'Unexpected Error in compiling the rule function' || cur_hold.rule_function;
                      g_entity_ref_id     := 0;
                      
                      DBMS_OUTPUT.PUT_LINE('Unexpected Error in compiling the rule function');

                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

  --                    log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while compiling the rule function :' || ln_header_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;
*/ -- Commented this code as the compilation is not required
                
                IF lc_hold_name LIKE '%OD%HELD%FOR%COMMENTS%' THEN
                    NULL; --lc_rule_fun_name := 'BEGIN :lc_hold_flag := ' || lc_rule_func_name || '(''APPLY'''|| ',' || cur_hold.hold_id || ',' || ln_header_id || ',' || 'NULL' || ',' || 'O' || ') ; END;';
                ELSE 
                    lc_rule_fun_name := 'BEGIN :lc_hold_flag := ' || lc_rule_func_name || '(''APPLY'''|| ',' || cur_hold.hold_id || ',' || ln_header_id || ',' || 'NULL' || ') ; END;';
                END IF;
                
                BEGIN

                    EXECUTE IMMEDIATE lc_rule_fun_name USING OUT lc_hold_flag;

                EXCEPTION
                  WHEN OTHERS THEN
                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error in calling the rule function' || cur_hold.rule_function;
                      g_entity_ref_id     := 0;

                      DBMS_OUTPUT.PUT_LINE('Unexpected Error in calling the rule function'||sqlerrm);

                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

 --                     log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while calling the rule function :' || ln_header_id || lc_rule_fun_name);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;

                p_order_tbl(1).Header_Id := ln_header_id;
                p_order_tbl(1).line_id   := NULL ;
                p_hold_id                := cur_hold.hold_id;
                p_hold_comment           := 'XX TEST OD TO Be Determined';

                IF lc_hold_flag = 'Y' THEN
                
                    oe_holds_pub.Apply_Holds (
                        p_api_version,
                        p_init_msg_list,
                        p_commit,
                        p_validation_level,
                        p_order_tbl,
                        p_hold_id,
                        p_hold_until_date,
                        p_hold_comment,
                        x_return_status,
                        x_msg_count,
                        x_msg_data
                       );
                       
                END IF;
                
            END LOOP; -- End Loop for hold cursor --

            COMMIT;

            ----------------------------------------------------------------
            /* Loop through all the lines for the order  */
            /* Create reservation for each lines */
            ----------------------------------------------------------------

            FOR cur_line_info IN lcu_line_info LOOP

                ln_api_version                                := 1.0;
                l_create_rsv_rec.reservation_id               := NULL;
                l_create_rsv_rec.requirement_date             := SYSDATE;
                lc_partial_reservation_flag                   := fnd_api.g_true;
                lc_force_reservation_flag                     := fnd_api.g_false;
                lc_validation_flag                            := fnd_api.g_true;
                l_create_rsv_rec.inventory_item_id            := cur_line_info.ordered_item_id;
                l_create_rsv_rec.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
                l_create_rsv_rec.demand_source_name           := 'Through workflow reservation';   -- To be determined
                l_create_rsv_rec.demand_source_header_id      := ln_header_id;                      -- p_mso_line_id;
                l_create_rsv_rec.demand_source_line_id        := cur_line_info.line_id;            -- p_demand_info.oe_line_id;
                l_create_rsv_rec.primary_uom_code             := cur_line_info.order_quantity_uom;
                l_create_rsv_rec.reservation_uom_code         := cur_line_info.order_quantity_uom;
                l_create_rsv_rec.primary_reservation_quantity := cur_line_info.ordered_quantity;
                l_create_rsv_rec.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
                l_create_rsv_rec.demand_source_delivery       := NULL;
                l_create_rsv_rec.primary_uom_id               := NULL;
                l_create_rsv_rec.reservation_uom_id           := NULL;
                l_create_rsv_rec.reservation_quantity         := NULL;
                l_create_rsv_rec.autodetail_group_id          := NULL;
                l_create_rsv_rec.external_source_code         := NULL;
                l_create_rsv_rec.external_source_line_id      := NULL;
                l_create_rsv_rec.supply_source_header_id      := NULL;
                l_create_rsv_rec.supply_source_line_id        := NULL;
                l_create_rsv_rec.supply_source_name           := NULL;
                l_create_rsv_rec.supply_source_line_detail    := NULL;
                l_create_rsv_rec.revision                     := NULL;
                l_create_rsv_rec.subinventory_code            := NULL;
                l_create_rsv_rec.subinventory_id              := NULL;
                l_create_rsv_rec.locator_id                   := NULL;
                l_create_rsv_rec.lot_number                   := NULL;
                l_create_rsv_rec.lot_number_id                := NULL;
                l_create_rsv_rec.pick_slip_number             := NULL;
                l_create_rsv_rec.lpn_id                       := NULL;
                l_create_rsv_rec.attribute_category           := NULL;
                l_create_rsv_rec.attribute1                   := NULL;
                l_create_rsv_rec.attribute2                   := NULL;
                l_create_rsv_rec.attribute3                   := NULL;
                l_create_rsv_rec.attribute4                   := NULL;
                l_create_rsv_rec.attribute5                   := NULL;
                l_create_rsv_rec.attribute6                   := NULL;
                l_create_rsv_rec.attribute7                   := NULL;
                l_create_rsv_rec.attribute8                   := NULL;
                l_create_rsv_rec.attribute9                   := NULL;
                l_create_rsv_rec.attribute10                  := NULL;
                l_create_rsv_rec.attribute11                  := NULL;
                l_create_rsv_rec.attribute12                  := NULL;
                l_create_rsv_rec.attribute13                  := NULL;
                l_create_rsv_rec.attribute14                  := NULL;
                l_create_rsv_rec.attribute15                  := NULL;
                l_create_rsv_rec.ship_ready_flag              := NULL;
                l_create_rsv_rec.detailed_quantity            := 0;
                
                BEGIN

                    SELECT oola.ship_from_org_id
                    INTO   ln_ship_from_org_id
                    FROM   oe_order_lines_all oola
                    WHERE  oola.line_id  = cur_line_info.line_id;

                    l_create_rsv_rec.organization_id    := ln_ship_from_org_id;

                EXCEPTION WHEN OTHERS THEN

                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error while deriving the ship from org id:' || cur_line_info.line_id;
                      g_entity_ref_id     := 0;
                      
                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

   --                   log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while getting the ship from org id :' || ln_header_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;

                -- Check if the reservation has already happened
                ------------------------------------------------

                BEGIN

                    SELECT COUNT(1)
                    INTO   ln_reserve_count
                    FROM   mtl_reservations    MR
                          ,mfg_lookups         ML
                    WHERE MR.demand_source_line_id   = cur_line_info.line_id
                    AND   MR.organization_id         = ln_ship_from_org_id
                    AND   MR.inventory_item_id       = cur_line_info.ordered_item_id
                    AND   MR.demand_source_type_id   = ML.lookup_code
                    AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
                    AND   ML.lookup_code IN (2,9);

                EXCEPTION WHEN OTHERS THEN

                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error while querying the reservations' || cur_line_info.line_id;
                      g_entity_ref_id     := 0;
                      
                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

    --                  log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while querying the reservations :' || cur_line_info.line_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;

                IF ln_reserve_count = 0 THEN

                -- Create Reservations for the line
                ------------------------------------------------
                
                    inv_reservation_pub.create_reservation
                    (
                      ln_api_version,
                      ln_init_msg_list,
                      x_return_status,
                      x_msg_count,
                      x_msg_data,
                      l_create_rsv_rec,
                      l_dummy_sn,
                      l_dummy_sn,
                      lc_partial_reservation_flag,
                      lc_force_reservation_flag,
                      lc_validation_flag,
                      ln_quantity_reserved,
                      ln_reservation_id
                    );

                    COMMIT;
                    
                    IF(NVL(x_msg_count,0) = 0) THEN
                        DBMS_OUTPUT.PUT_LINE('no message return');
                    ELSIF( x_msg_count = 1 ) THEN
                        DBMS_OUTPUT.PUT_LINE(SUBSTR(l_message,1,255));
                    ELSE

                        FOR I IN 1..x_msg_count LOOP
                            l_message := fnd_msg_pub.get(I, 'F');
                        END LOOP;

                    END IF;

                END IF;  -- END IF ln_reserve_count = 0

            END LOOP;  -- End Loop for line Info

            resultout := 'COMPLETE:Y';
            
            RETURN;

    ELSIF command = 'CANCEL' THEN
       -- no result needed
        resultout := 'COMPLETE:N';
        RETURN;
    END IF;

EXCEPTION WHEN OTHERS THEN

    resultout := 'ERROR:';
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    g_entity_ref        := 'Unexpected Error in the After booking process'|| ln_header_id ;
    g_entity_ref_id     := 0;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

--    log_exceptions;

    --Logging error in standard wf error
    ------------------------------------
    WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                    'Unexpected error occured in the Apply hold before booking proceudre:' || SQLERRM || ln_header_id);
    resultout := 'ERROR:';
    APP_EXCEPTION.RAISE_EXCEPTION;

END Apply_Hold_Before_Booking;

-- +===================================================================+
-- | Name  : Apply_Hold_After_Booking                                  |
-- |                                                                   |
-- | Description: This Procedure is used to update the holds and       |
-- |              perform inventory reservation in EBS.                |
-- |                                                                   |
-- | Parameters:  p_delivery_rec                                       |
-- |                                                                   |
-- | Returns :    x_status ,  x_message                                |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Apply_Hold_After_Booking(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          ) IS

    p_hold_source_rec            OE_HOLDS_PVT.Hold_Source_Rec_Type;
    ln_hold_id                   NUMBER;
    ln_api_version               NUMBER;
    ln_commit                    VARCHAR2(10);
    ln_validation_level          VARCHAR2(1000);
    lc_hold_name                 varchar2(1000);
    ln_hold_until_date           DATE;
    ln_hold_comment              VARCHAR2(4000);
    x_return_status              VARCHAR2(10);
    x_msg_count                  NUMBER;
    x_msg_data                   VARCHAR2(1000);
    l_create_rsv_rec             INV_RESERVATION_GLOBAL.mtl_reservation_rec_type;
    l_qry_rsv_rec                INV_RESERVATION_GLOBAL.mtl_reservation_rec_type;
    l_dummy_sn                   INV_RESERVATION_GLOBAL.serial_number_tbl_type;
    lc_rule_fun                  VARCHAR2(32767);
    lc_rule_fun_name             VARCHAR2(1000);
    lc_hold_flag                 VARCHAR2(1);
    ln_org_id                    NUMBER;
    ln_init_msg_list             VARCHAR2(100) := fnd_api.g_true;
    lc_commit                    VARCHAR2(100);
    lc_hold_existing_flg         VARCHAR2(100);
    lc_hold_future_flg           VARCHAR2(100);
    lc_validation_level          VARCHAR2(100);
    lc_rule_func_name            VARCHAR2(1000);
    ln_ship_from_org_id          NUMBER;
    ln_header_id                 NUMBER;

    lc_partial_reservation_flag  VARCHAR2(100);
    lc_force_reservation_flag    VARCHAR2(100);
    lc_validation_flag           VARCHAR2(100);
    ln_quantity_reserved         NUMBER;
    ln_reservation_id            NUMBER;
    l_api_name          CONSTANT VARCHAR2(30) := 'Process_Line';

    p_api_version                NUMBER ;
    p_init_msg_list              VARCHAR2(1000) ;
    p_commit                     VARCHAR2(1000) := FND_API.G_FALSE;
    p_validation_level           NUMBER;
    p_order_tbl                  OE_HOLDS_PVT.order_tbl_type;
    p_hold_id                    OE_HOLD_DEFINITIONS.HOLD_ID%TYPE;
    p_hold_until_date            OE_HOLD_SOURCES.HOLD_UNTIL_DATE%TYPE;
    p_hold_comment               OE_HOLD_SOURCES.HOLD_COMMENT%TYPE ;
    l_message                    VARCHAR2(2000);
    ln_reserve_count             NUMBER;

    --variable holding the error details
    ------------------------------------
    ln_exception_occured         NUMBER       := 0;
    lc_exception_hdr             VARCHAR2(40);
    lc_error_code                VARCHAR2(40);
    lc_error_desc                VARCHAR2(1000);
    lc_entity_ref                VARCHAR2(40);
    lc_entity_ref_id             NUMBER;
    ln_line_id                   NUMBER;

    --Variables required for setting Apps contexts
    ----------------------------------------------
    ln_msg_index_out              NUMBER(10);
    ln_user_id                    NUMBER;
    ln_resp_id                    NUMBER;
    ln_appl_id                    NUMBER;
    
    CURSOR lcu_line IS 
    SELECT line_id FROM oe_order_lines_all 
    WHERE  header_id = ln_header_id
    AND    source_type_code = 'EXTERNAL';
    
   --Cursor fetching the rule-functions for the hold id passed
   -----------------------------------------------------------
    CURSOR lcu_hold IS
    SELECT xoom.hold_definition_id,
           xoom.hold_id,
           (SELECT NAME 
            FROM oe_hold_definitions ohd 
            WHERE ohd.hold_id = xoom.hold_id
           ) NAME,
           xoom.type_code,
           xoom.hold_type,
           xoom.org_id,
           xoom.no_of_days,
           xoom.credit_authorization,
           xoom.rule_function,
           xoom.rule_function_name,
           xoom.order_booking_status,
           xoom.send_to_pool
    FROM   xx_ont_odholdframework_tbl xoom
    WHERE  xoom.hold_id IN (SELECT ohd.hold_id
                            FROM   oe_hold_definitions ohd
                            WHERE  ohd.name LIKE 'OD%'
                            AND    SYSDATE BETWEEN NVL(START_DATE_ACTIVE,sysdate-1)  AND nvl(END_DATE_ACTIVE,sysdate +1)
                            )
    AND    xoom.order_booking_status   = 'A'
    AND    xoom.apply_to_order_or_line = 'O'
    AND    xoom.hold_type = 'A';

    CURSOR lcu_line_info IS
    SELECT oola.line_id,
           oola.ordered_item_id,
           order_quantity_uom,
           ordered_quantity
    FROM   oe_order_lines_all oola
    WHERE  oola.header_id = ln_header_id;
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
     IF command = 'RUN' THEN

        ln_header_id := TO_NUMBER(i_itemkey);

        ----------------------
        -- Set Apps Context --
        ----------------------
        ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
        ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
        ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
        fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);

        --Validating order status, which should be in Entered
        -----------------------------------------------------

            BEGIN

                SELECT ooha.org_id
                INTO   ln_org_id
                FROM   oe_order_headers_all ooha
                WHERE  ooha.header_id = ln_header_id;

            EXCEPTION WHEN OTHERS THEN
            
                g_entity_ref        := 'Unexpected Error while getting the org_id for ' || ln_header_id;
                g_entity_ref_id     := 0;

                FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                g_error_description:= FND_MESSAGE.GET;
                g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

  --              log_exceptions;

                --Logging error in standard wf error
                ------------------------------------
                WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                'Unexpected error occured while compiling the rule function :' || ln_header_id);
                resultout := 'ERROR:';
                APP_EXCEPTION.RAISE_EXCEPTION;

            END;
            
            FOR cur_hold IN lcu_hold LOOP
            
                lc_rule_func_name := NULL;
                lc_rule_fun       := NULL;

                lc_rule_fun                        := cur_hold.rule_function;
                lc_rule_func_name                  := cur_hold.rule_function_name;
                p_hold_source_rec.hold_id          := cur_hold.hold_id;
                lc_hold_name                       := cur_hold.name;
                p_hold_source_rec.last_update_date := SYSDATE;
                p_hold_source_rec.last_updated_by  :=  2001 ; --ln_user_id;                             -- change it to the current user
                p_hold_source_rec.creation_date    := SYSDATE;
                p_hold_source_rec.created_by       := 2001;                             -- change it to the current user
                p_hold_source_rec.hold_comment     := 'XX TEST OD TO Be Determined';    -- Determine with milind
                p_hold_source_rec.org_id           := ln_org_id;
                p_hold_source_rec.header_id        := ln_header_id;
                
                INSERT INTO test791 VALUES(cur_hold.name);
                COMMIT;

/*                BEGIN

                    DBMS_OUTPUT.PUT_LINE('Before compiling rule function1');

                    EXECUTE IMMEDIATE lc_rule_fun;
                    
                    DBMS_OUTPUT.PUT_LINE('After compiling rule function1');

                EXCEPTION
                  WHEN OTHERS THEN
                      g_entity_ref        := 'Unexpected Error in compiling the rule function' || cur_hold.rule_function;
                      g_entity_ref_id     := 0;
                      
                      DBMS_OUTPUT.PUT_LINE('Unexpected Error in compiling the rule function');

                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

  --                    log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while compiling the rule function :' || ln_header_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;
*/  -- Commented the code as the rule function need not be compiled

                FOR cur_line IN lcu_line LOOP
                    ln_line_id := cur_line.line_id;
                END LOOP;
                
                IF lc_hold_name LIKE '%OD%HELD%FOR%COMMENTS%' THEN
                    NULL; --lc_rule_fun_name := 'BEGIN :lc_hold_flag := ' || lc_rule_func_name || '(''APPLY'''|| ',' || cur_hold.hold_id || ',' || ln_header_id || ',' || 'NULL' || ',' || 'O' || ') ; END;';
                ELSE 
                    lc_rule_fun_name := 'BEGIN :lc_hold_flag := ' || lc_rule_func_name || '(''APPLY'''|| ',' || cur_hold.hold_id || ',' || ln_header_id || ',' || NVL(ln_line_id,0) || ') ; END;';
                END IF;
                
                BEGIN

                    EXECUTE IMMEDIATE lc_rule_fun_name USING OUT lc_hold_flag;

                EXCEPTION
                  WHEN OTHERS THEN
                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error in calling the rule function' || cur_hold.rule_function;
                      g_entity_ref_id     := 0;

                      DBMS_OUTPUT.PUT_LINE('Unexpected Error in calling the rule function'||sqlerrm);

                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

  --                    log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while calling the rule function :' || ln_header_id || lc_rule_fun_name);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;
                
                DBMS_OUTPUT.PUT_LINE('Before applying holds');

                p_order_tbl(1).Header_Id := ln_header_id;
                p_order_tbl(1).line_id   := NULL ;
                p_hold_id                := cur_hold.hold_id;
                p_hold_comment           := 'XX TEST OD TO Be Determined';

                IF lc_hold_flag = 'Y' THEN
                
                   DBMS_OUTPUT.PUT_LINE('Applying hold');                

                    oe_holds_pub.Apply_Holds (
                        p_api_version,
                        p_init_msg_list,
                        p_commit,
                        p_validation_level,
                        p_order_tbl,
                        p_hold_id,
                        p_hold_until_date,
                        p_hold_comment,
                        x_return_status,
                        x_msg_count,
                        x_msg_data
                       );
                       
                END IF;
                
            END LOOP; -- End Loop for hold cursor --

            COMMIT;

            ----------------------------------------------------------------
            /* Loop through all the lines for the order  */
            /* Create reservation for each lines */
            ----------------------------------------------------------------

            FOR cur_line_info IN lcu_line_info LOOP

                ln_api_version                                := 1.0;
                l_create_rsv_rec.reservation_id               := NULL;
                l_create_rsv_rec.requirement_date             := SYSDATE;
                lc_partial_reservation_flag                   := fnd_api.g_true;
                lc_force_reservation_flag                     := fnd_api.g_false;
                lc_validation_flag                            := fnd_api.g_true;
                l_create_rsv_rec.inventory_item_id            := cur_line_info.ordered_item_id;
                l_create_rsv_rec.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
                l_create_rsv_rec.demand_source_name           := 'Through workflow reservation';   -- To be determined
                l_create_rsv_rec.demand_source_header_id      := ln_header_id;                      -- p_mso_line_id;
                l_create_rsv_rec.demand_source_line_id        := cur_line_info.line_id;            -- p_demand_info.oe_line_id;
                l_create_rsv_rec.primary_uom_code             := cur_line_info.order_quantity_uom;
                l_create_rsv_rec.reservation_uom_code         := cur_line_info.order_quantity_uom;
                l_create_rsv_rec.primary_reservation_quantity := cur_line_info.ordered_quantity;
                l_create_rsv_rec.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
                l_create_rsv_rec.demand_source_delivery       := NULL;
                l_create_rsv_rec.primary_uom_id               := NULL;
                l_create_rsv_rec.reservation_uom_id           := NULL;
                l_create_rsv_rec.reservation_quantity         := NULL;
                l_create_rsv_rec.autodetail_group_id          := NULL;
                l_create_rsv_rec.external_source_code         := NULL;
                l_create_rsv_rec.external_source_line_id      := NULL;
                l_create_rsv_rec.supply_source_header_id      := NULL;
                l_create_rsv_rec.supply_source_line_id        := NULL;
                l_create_rsv_rec.supply_source_name           := NULL;
                l_create_rsv_rec.supply_source_line_detail    := NULL;
                l_create_rsv_rec.revision                     := NULL;
                l_create_rsv_rec.subinventory_code            := NULL;
                l_create_rsv_rec.subinventory_id              := NULL;
                l_create_rsv_rec.locator_id                   := NULL;
                l_create_rsv_rec.lot_number                   := NULL;
                l_create_rsv_rec.lot_number_id                := NULL;
                l_create_rsv_rec.pick_slip_number             := NULL;
                l_create_rsv_rec.lpn_id                       := NULL;
                l_create_rsv_rec.attribute_category           := NULL;
                l_create_rsv_rec.attribute1                   := NULL;
                l_create_rsv_rec.attribute2                   := NULL;
                l_create_rsv_rec.attribute3                   := NULL;
                l_create_rsv_rec.attribute4                   := NULL;
                l_create_rsv_rec.attribute5                   := NULL;
                l_create_rsv_rec.attribute6                   := NULL;
                l_create_rsv_rec.attribute7                   := NULL;
                l_create_rsv_rec.attribute8                   := NULL;
                l_create_rsv_rec.attribute9                   := NULL;
                l_create_rsv_rec.attribute10                  := NULL;
                l_create_rsv_rec.attribute11                  := NULL;
                l_create_rsv_rec.attribute12                  := NULL;
                l_create_rsv_rec.attribute13                  := NULL;
                l_create_rsv_rec.attribute14                  := NULL;
                l_create_rsv_rec.attribute15                  := NULL;
                l_create_rsv_rec.ship_ready_flag              := NULL;
                l_create_rsv_rec.detailed_quantity            := 0;
                
                BEGIN

                    SELECT oola.ship_from_org_id
                    INTO   ln_ship_from_org_id
                    FROM   oe_order_lines_all oola
                    WHERE  oola.line_id  = cur_line_info.line_id;

                    l_create_rsv_rec.organization_id    := ln_ship_from_org_id;

                EXCEPTION WHEN OTHERS THEN

                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error while deriving the ship from org id:' || cur_line_info.line_id;
                      g_entity_ref_id     := 0;
                      
                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

   --                   log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while getting the ship from org id :' || ln_header_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;

                -- Check if the reservation has already happened
                ------------------------------------------------

                BEGIN

                    SELECT COUNT(1)
                    INTO   ln_reserve_count
                    FROM   mtl_reservations    MR
                          ,mfg_lookups         ML
                    WHERE MR.demand_source_line_id   = cur_line_info.line_id
                    AND   MR.organization_id         = ln_ship_from_org_id
                    AND   MR.inventory_item_id       = cur_line_info.ordered_item_id
                    AND   MR.demand_source_type_id   = ML.lookup_code
                    AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
                    AND   ML.lookup_code IN (2,9);

                EXCEPTION WHEN OTHERS THEN

                      --Logging error in custom global exception handling framework
                      -------------------------------------------------------------
                      g_entity_ref        := 'Unexpected Error while querying the reservations' || cur_line_info.line_id;
                      g_entity_ref_id     := 0;
                      
                      DBMS_OUTPUT.PUT_LINE('Unexpected Error in deriving ship from org id');                      

                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                      g_error_description:= FND_MESSAGE.GET;
                      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

    --                  log_exceptions;

                      --Logging error in standard wf error
                      ------------------------------------
                      WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                                      'Unexpected error occured while querying the reservations :' || cur_line_info.line_id);
                      resultout := 'ERROR:';
                      APP_EXCEPTION.RAISE_EXCEPTION;

                END;

                IF ln_reserve_count = 0 THEN

                -- Create Reservations for the line
                ------------------------------------------------
                
                    inv_reservation_pub.create_reservation
                    (
                      ln_api_version,
                      ln_init_msg_list,
                      x_return_status,
                      x_msg_count,
                      x_msg_data,
                      l_create_rsv_rec,
                      l_dummy_sn,
                      l_dummy_sn,
                      lc_partial_reservation_flag,
                      lc_force_reservation_flag,
                      lc_validation_flag,
                      ln_quantity_reserved,
                      ln_reservation_id
                    );

                    COMMIT;
                    
                    IF(NVL(x_msg_count,0) = 0) THEN
                        DBMS_OUTPUT.PUT_LINE('no message return');
                    ELSIF( x_msg_count = 1 ) THEN
                        DBMS_OUTPUT.PUT_LINE(SUBSTR(l_message,1,255));
                    ELSE

                        FOR I IN 1..x_msg_count LOOP
                            l_message := fnd_msg_pub.get(I, 'F');
                            DBMS_OUTPUT.PUT_LINE(SUBSTR(l_message,1,255));
                        END LOOP;

                    END IF;

                END IF;  -- END IF ln_reserve_count = 0

            END LOOP;  -- End Loop for line Info

            resultout := 'COMPLETE:Y';
            
            RETURN;

    ELSIF command = 'CANCEL' THEN
        resultout := 'COMPLETE:N';
        RETURN;
    END IF;

EXCEPTION WHEN OTHERS THEN

    resultout := 'ERROR:';
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    g_entity_ref        := 'Unexpected Error in the After booking process'|| ln_header_id ;
    g_entity_ref_id     := 0;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

--    log_exceptions;

    --Logging error in standard wf error
    ------------------------------------
    WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                    'Unexpected error occured in the Apply hold before booking proceudre:' || SQLERRM || ln_header_id);
    resultout := 'ERROR:';
    APP_EXCEPTION.RAISE_EXCEPTION;

END Apply_Hold_After_Booking;


-- +===================================================================+
-- | Name  : Check_For_External_Approval                               |
-- |                                                                   |
-- | Description: This Procedure is used to check the hold is waiting  |
-- |              for an external approval.                            |
-- |                                                                   |
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :    x_status ,  x_message                                |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Check_For_External_Approval(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          ) IS

    --variable holding the error details
    ------------------------------------
    ln_exception_occured         NUMBER        := 0;
    lc_exception_hdr             VARCHAR2(40);
    lc_error_code                VARCHAR2(40);
    lc_error_desc                VARCHAR2(1000);
    lc_entity_ref                VARCHAR2(40);
    lc_entity_ref_id             NUMBER;

    --Variables required for setting Apps contexts
    ----------------------------------------------
    ln_msg_index_out              NUMBER(10);
    ln_user_id                    NUMBER;
    ln_resp_id                    NUMBER;
    ln_appl_id                    NUMBER;
    
    ln_hold_count NUMBER; 
    ln_header_id  NUMBER;


   --Cursor fetching the rule-functions for the hold id passed
   -----------------------------------------------------------
    CURSOR lcu_hold IS
    SELECT count(1) hold_count
    FROM   oe_order_holds              ooh  
          ,oe_hold_sources             ohs  
          ,xx_ont_odholdframework_tbl  xxom 
          ,oe_hold_definitions         ohd  
    WHERE  ooh.hold_release_id         IS NULL   
    AND    ooh.released_flag           = 'N'
    AND    ooh.hold_source_id          = ohs.hold_source_id
    AND    ohs.hold_id                 = ohd.hold_id 
    AND    xxom.hold_id                = ohd.hold_id
    AND    xxom.hold_type              = 'A'
    AND    xxom.apply_to_order_or_line = 'O'
    AND    ooh.header_id               = ln_header_id
    AND    ohd.name                    LIKE  'OD%AWAITING%EXTERNAL%APPROVAL%HOLD';

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    IF command = 'RUN' THEN

        ln_header_id := TO_NUMBER(i_itemkey);
        
    ----------------------
    -- Set Apps Context --
    ----------------------
        ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
        ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
        ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
        fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);

        FOR cur_hold IN lcu_hold LOOP
            ln_hold_count := cur_hold.hold_count;
        END LOOP;

        IF ln_hold_count > 0 THEN
            resultout := 'COMPLETE:Y';
            RETURN;
        ELSE   
            resultout := 'COMPLETE:N';
            RETURN;
        END IF;
        
   ELSIF command = 'CANCEL' THEN
       -- no result needed
        resultout := 'COMPLETE:N';
        RETURN;
    END IF;

EXCEPTION WHEN OTHERS THEN

    resultout := 'ERROR:';
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    g_entity_ref        := 'Unexpected Error in the After booking process'|| ln_header_id ;
    g_entity_ref_id     := 0;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

    --log_exceptions;

    --Logging error in standard wf error
    ------------------------------------
    WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Check_For_External_Approval',i_itemtype,i_itemkey,
                    'Unexpected error occured while  checking for external approval  booking :' ||SQLERRM|| ln_header_id);
    resultout := 'ERROR:';
    APP_EXCEPTION.RAISE_EXCEPTION;

END Check_For_External_Approval;

-- +===================================================================+
-- | Name  : check_hold_days                                           |
-- |                                                                   |
-- | Description: This Procedure is used to check the hold if it has   |
-- |              to wait for specified number of days.                |
-- |                                                                   |
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :    x_status ,  x_message                                |
-- |                                                                   |
-- +===================================================================+

PROCEDURE check_hold_days(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          ) IS
          
   ln_hold_count   NUMBER;
   ln_user_id      NUMBER;
   ln_resp_id      NUMBER;
   ln_appl_id      NUMBER;
   ln_header_id    NUMBER;   
          
   --Cursor fetching the Hold for number of days for the hold id passed
   ---------------------------------------------------------------------
    CURSOR lcu_hold IS
    SELECT COUNT(1) hold_count
    FROM   oe_hold_definitions ohd,
           oe_hold_sources     ohs,
           oe_order_holds      ooh,
           xx_ont_odholdframework_tbl xoot
    WHERE  ooh.hold_source_id          = ohs.hold_source_id
    AND    ohs.hold_id                 = ohd.hold_id
    AND    ohd.hold_id                 = xoot.hold_id
    AND    xoot.order_booking_status   = 'B'
    AND    xoot.apply_to_order_or_line = 'O'
    AND    (TRUNC(SYSDATE) - NVL(TRUNC(ooh.creation_date),TRUNC(SYSDATE))) > NVL(xoot.no_of_days,0) 
    AND    ooh.header_id               = ln_header_id
    AND    ooh.released_flag           = 'N';
          
BEGIN
          
     IF command = 'RUN' THEN

        ln_header_id := TO_NUMBER(i_itemkey);
        
        ----------------------
        -- Set Apps Context --
        ----------------------
        ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
        ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
        ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
        fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);

        FOR cur_hold IN lcu_hold LOOP 

            ln_hold_count := cur_hold.hold_count;

        END LOOP;

        IF ln_hold_count > 0 THEN
            resultout := 'COMPLETE:Y';
        ELSE 
            resultout := 'COMPLETE:N';
        END IF;

    ELSIF command = 'CANCEL' THEN
        resultout := 'COMPLETE:NO';
        RETURN;
    END IF;

EXCEPTION WHEN OTHERS THEN

    resultout := 'ERROR:';
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    g_entity_ref        := 'Unexpected Error in the After booking process'|| ln_header_id ;
    g_entity_ref_id     := 0;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

--    log_exceptions;

    --Logging error in standard wf error
    ------------------------------------
    WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Check_For_External_Approval',i_itemtype,i_itemkey,
                    'Unexpected error occured while  checking for external approval  booking :'|| SQLERRM || ln_header_id);
    resultout := 'ERROR:';
    APP_EXCEPTION.RAISE_EXCEPTION;
          
END check_hold_days;

-------------------------------------------------------------------------------------------------
-------------- Dummy process for the external approval process to be removed --------------------
-------------------------------------------------------------------------------------------------

PROCEDURE dummy(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          ) IS

BEGIN
    resultout := 'COMPLETE:Y';
RETURN;

EXCEPTION WHEN OTHERS THEN

    resultout := 'ERROR:';
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    g_entity_ref        := 'Unexpected Error in the After booking process';
    g_entity_ref_id     := 0;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

--    log_exceptions;

    --Logging error in standard wf error
    ------------------------------------
    WF_CORE.CONTEXT('xx_wfl_orderhdrwfmod_pkg','Check_For_External_Approval',i_itemtype,i_itemkey,
                    'Unexpected error occured while  checking for external approval  booking :' || SQLERRM);
    resultout := 'ERROR:';
    APP_EXCEPTION.RAISE_EXCEPTION;

END dummy;
          
END XX_WFL_ORDERHDRWFMOD_PKG;
/
SHOW ERRORS;