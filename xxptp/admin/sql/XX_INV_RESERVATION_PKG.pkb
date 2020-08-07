SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY XX_GI_RESERVATION_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization              |
-- +==========================================================================+
-- | Name        :  XX_GI_RESERVATION_PKG.pkb                                 |
-- | Description :                                                            |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author           Remarks                            |
-- |=======   ==========  =============    ===================================|
-- |Draft 1d  31-Oct-2007 Siddharth Singh  Initial Version.                   |
-- |                                                                          |
-- +==========================================================================+
AS

G_TRUE   CONSTANT VARCHAR2(1)  := FND_API.G_TRUE;
G_FALSE  CONSTANT VARCHAR2(1)  := FND_API.G_FALSE;

gc_key_found  VARCHAR2(1) := NULL;

gn_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
gn_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE      := NULL;
gn_reservation_id     mtl_reservations.reservation_id%TYPE           := NULL;

PROCEDURE VALIDATE_RESERVATION_KEY (p_res_key IN VARCHAR2)
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+

IS



BEGIN

    SELECT reservation_id
    INTO   gn_reservation_id
    FROM   mtl_reservations
    WHERE  demand_source_name = p_res_key;

    gc_key_found := 'Y';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    gc_key_found := 'N';
    
    
    WHEN OTHERS THEN
    gc_key_found := 'E';

END VALIDATE_RESERVATION_KEY;



PROCEDURE DELETE_RESERVATION
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+



IS

L_API_VERSION_NO CONSTANT NUMBER := 1.0;

lc_error_msg     VARCHAR2(3000) := NULL;
lc_return_status VARCHAR2(1)    := NULL;
lc_msg_data      VARCHAR2(240)  := NULL;

ln_msg_count     NUMBER      := NULL;
ln_msg_index_out NUMBER      := NULL;

lr_rsv_rec    inv_reservation_global.mtl_reservation_rec_type;

lt_dummy_sn   inv_reservation_global.serial_number_tbl_type;

BEGIN










    INV_RESERVATION_PUB.DELETE_RESERVATION(p_api_version_number  => L_API_VERSION_NO
                                          ,p_init_msg_lst        => G_TRUE
                                          ,x_return_status       => lc_return_status
                                          ,x_msg_count           => ln_msg_count
                                          ,x_msg_data            => lc_msg_data
                                          ,p_rsv_rec             => lr_rsv_rec
                                          ,p_serial_number       => lt_dummy_sn
                                           );

    IF (lc_return_status <> 'S') THEN
    
        IF (ln_msg_count = 1) THEN

            dbms_output.put_line('One Error');

            FND_MSG_PUB.GET(p_msg_index     => FND_MSG_PUB.G_FIRST
                           ,p_encoded       => G_FALSE
                           ,p_data          => lc_msg_data
                           ,p_msg_index_out => ln_msg_index_out
                           );

            dbms_output.put_line('lc_msg_data = ' || lc_msg_data);

        ELSE

            dbms_output.put_line('More Than One Error');

            FOR ln_index IN 1.. ln_msg_count 
            LOOP
                FND_MSG_PUB.GET(p_encoded       => G_FALSE
                               ,p_data          => lc_msg_data
                               ,p_msg_index_out => ln_msg_index_out
                               );

                lc_error_msg := lc_error_msg || lc_msg_data;
            END LOOP;
 
            dbms_output.put_line('ln_msg_index_out = ' || ln_msg_index_out);
            dbms_output.put_line('lc_error_msg :'||lc_error_msg );

        END IF;

    END IF;



EXCEPTION
    WHEN OTHERS THEN
    NULL;


END DELETE_RESERVATION;

PROCEDURE UPDATE_RESERVATION
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+

IS

L_API_VERSION_NO CONSTANT NUMBER := 1.0;


lc_error_msg  VARCHAR2(3000)  := NULL;

lc_return_status VARCHAR2(1)    := NULL;
lc_msg_data   VARCHAR2(240)  := NULL;

ln_msg_count     NUMBER       := NULL;
ln_msg_index_out NUMBER       := NULL;
ln_q_res         NUMBER       := NULL;

lr_rsv_old    inv_reservation_global.mtl_reservation_rec_type;
lr_rsv_new    inv_reservation_global.mtl_reservation_rec_type;

lt_dummy_sn   inv_reservation_global.serial_number_tbl_type;


BEGIN




    INV_RESERVATION_PUB.UPDATE_RESERVATION ( p_api_version_number       => L_API_VERSION_NO
                                            ,p_init_msg_lst             => G_TRUE
                                            ,p_original_rsv_rec         => lr_rsv_old
                                            ,p_to_rsv_rec               => lr_rsv_new
                                            ,p_original_serial_number   => lt_dummy_sn
                                            ,p_to_serial_number         => lt_dummy_sn
                                            ,p_partial_reservation_flag => G_TRUE
                                            ,p_check_availability       => G_TRUE
                                            ,p_validation_flag          => G_TRUE
                                            ,x_return_status            => lc_return_status
                                            ,x_msg_count                => ln_msg_count
                                            ,x_msg_data                 => lc_msg_data
                                            ,x_quantity_reserved        => ln_q_res
                                           );

    IF (lc_return_status <> 'S') THEN
    
        IF (ln_msg_count = 1) THEN

            dbms_output.put_line('One Error');

            FND_MSG_PUB.GET(p_msg_index     => FND_MSG_PUB.G_FIRST
                           ,p_encoded       => G_FALSE
                           ,p_data          => lc_msg_data
                           ,p_msg_index_out => ln_msg_index_out
                           );

            dbms_output.put_line('lc_msg_data = ' || lc_msg_data);

        ELSE

            dbms_output.put_line('More Than One Error');

            FOR ln_index IN 1.. ln_msg_count 
            LOOP
                FND_MSG_PUB.GET(p_encoded       => G_FALSE
                               ,p_data          => lc_msg_data
                               ,p_msg_index_out => ln_msg_index_out
                               );

                lc_error_msg := lc_error_msg || lc_msg_data;
            END LOOP;
 
            dbms_output.put_line('ln_msg_index_out = ' || ln_msg_index_out);
            dbms_output.put_line('lc_error_msg :'||lc_error_msg );

        END IF;

    END IF;


EXCEPTION
    WHEN OTHERS THEN
    NULL;

END UPDATE_RESERVATION;


PROCEDURE QUERY_QUANTITIES(p_organization_id   IN hr_all_organization_units.organization_id%TYPE
                          ,p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE
                          ,p_subinventory_code IN VARCHAR2
                          ,x_qty_atr           OUT NUMBER
                          )
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+
IS

L_API_VERSION_NO CONSTANT NUMBER := 1.0;
L_ONHAND_SOURCE  CONSTANT NUMBER := 3;

lc_api_return_status  VARCHAR2(1)    := NULL;
lc_error_msg          VARCHAR2(3000) := NULL;
lc_msg_data           VARCHAR2(240)  := NULL;

ln_msg_count          NUMBER := NULL;
ln_msg_index_out      NUMBER := NULL;
ln_qoh                NUMBER := NULL;
ln_rqoh               NUMBER := NULL;
ln_qty_res            NUMBER := NULL;
ln_qty_sug            NUMBER := NULL;
ln_qty_att            NUMBER := NULL;
ln_qty_atr            NUMBER := NULL;


BEGIN

    INV_QUANTITY_TREE_PUB.query_quantities(p_api_version_number  => L_API_VERSION_NO
                                          ,p_init_msg_lst        => G_TRUE
                                          ,x_return_status       => lc_api_return_status
                                          ,x_msg_count           => ln_msg_count
                                          ,x_msg_data            => lc_msg_data
                                          ,p_organization_id     => 1432
                                          ,p_inventory_item_id   => 1464319               -- 1464319 ,465019 ,1436078  
                                          ,p_tree_mode           => INV_QUANTITY_TREE_PUB.g_transaction_mode
                                          ,p_onhand_source       => L_ONHAND_SOURCE
                                          ,p_is_revision_control => FALSE
                                          ,p_is_lot_control      => FALSE
                                          ,p_is_serial_control   => FALSE
                                          ,p_revision            => NULL
                                          ,p_lot_number          => NULL
                                          ,p_subinventory_code   => NULL --'STOCK'  BUYBACK  CHARGEBACK DAMAGED   REPAIR 
                                          ,p_locator_id          => NULL
                                          ,x_qoh                 => ln_qoh      --Quantity on hand  
                                          ,x_rqoh                => ln_rqoh     --reservable quantity on hand  
                                          ,x_qr                  => ln_qty_res  --quantity reserved  
                                          ,x_qs                  => ln_qty_sug  --quantity suggested  
                                          ,x_att                 => ln_qty_att  --available to transact  
                                          ,x_atr                 => ln_qty_atr  --available to reserve 
                                          );

    IF (lc_api_return_status <> 'S') THEN

        IF (ln_msg_count = 1) THEN

            dbms_output.put_line('One Error');

            FND_MSG_PUB.GET(p_msg_index     => FND_MSG_PUB.G_FIRST
                           ,p_encoded       => G_FALSE
                           ,p_data          => lc_msg_data
                           ,p_msg_index_out => ln_msg_index_out
                           );

            dbms_output.put_line('lc_msg_data = ' || lc_msg_data);

        ELSE

            dbms_output.put_line('More Than One Error');

            FOR ln_index IN 1.. ln_msg_count 
            LOOP
                FND_MSG_PUB.GET(p_encoded       => G_FALSE
                               ,p_data          => lc_msg_data
                               ,p_msg_index_out => ln_msg_index_out
                               );

                lc_error_msg := lc_error_msg || lc_msg_data;
            END LOOP;

            dbms_output.put_line('ln_msg_index_out = ' || ln_msg_index_out);
            dbms_output.put_line('lc_error_msg :'||lc_error_msg );

        END IF;

    END IF;


EXCEPTION
    WHEN OTHERS THEN
    RAISE;

END QUERY_QUANTITIES;


PROCEDURE CREATE_RESERVATION(p_organization_id              IN hr_all_organization_units.organization_id%TYPE
                            ,p_inventory_item_id            IN mtl_system_items_b.inventory_item_id%TYPE
                            ,p_demand_source_name           IN VARCHAR2
                            ,p_primary_uom_code             IN VARCHAR2
                            ,p_reservation_uom_code         IN VARCHAR2
                            ,p_primary_reservation_quantity IN NUMBER
                            ,p_subinventory                 IN VARCHAR2
                            ,p_attribute10                  IN VARCHAR2
                            )
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+
IS

    L_API_VERSION_NUMBER     CONSTANT NUMBER := 1.0;
    L_DEMAND_SOURCE_TYPE_ID  CONSTANT NUMBER := 13;

    lc_api_return_status     VARCHAR2(1)   := NULL;
    lc_msg_data              VARCHAR2(240) := NULL;

    ln_msg_count                  NUMBER        := NULL;
    ln_qty_succ_reserved          NUMBER        := NULL;
    ln_qty_available_to_reserve   NUMBER        := NULL;
    ln_org_wide_res_id            NUMBER        := NULL;

    lr_res_rec               inv_reservation_global.mtl_reservation_rec_type;

    lt_dummy_sn              inv_reservation_global.serial_number_tbl_type;

BEGIN


    QUERY_QUANTITIES (p_organization_id   => p_organization_id
                     ,p_inventory_item_id => p_inventory_item_id
                     ,p_subinventory_code => 'STOCK'
                     ,x_qty_atr           => ln_qty_available_to_reserve
                     );

    IF (ln_qty_available_to_reserve < p_primary_reservation_quantity) THEN
    
        dbms_output.put_line('available_to_reserve < requested');
        --Log a shortage message in the OM Error Message Log Framework
    
    END IF;

    lr_res_rec.organization_id              := p_organization_id;
    lr_res_rec.inventory_item_id            := p_inventory_item_id;
    lr_res_rec.demand_source_type_id        := L_DEMAND_SOURCE_TYPE_ID;
    lr_res_rec.demand_source_name           := p_demand_source_name;
    lr_res_rec.primary_uom_code             := p_primary_uom_code;
    lr_res_rec.reservation_uom_code         := p_reservation_uom_code;
    lr_res_rec.primary_reservation_quantity := p_primary_reservation_quantity;
    lr_res_rec.supply_source_type_id        := L_DEMAND_SOURCE_TYPE_ID;                              ---check this
    lr_res_rec.attribute10                  := p_attribute10;

    lr_res_rec.demand_source_header_id      := NULL;
    lr_res_rec.demand_source_line_id        := NULL;
    lr_res_rec.demand_source_delivery       := NULL;
    lr_res_rec.primary_uom_id               := NULL;
    lr_res_rec.reservation_uom_id           := NULL;
    lr_res_rec.reservation_quantity         := NULL;          -- quantity in reservation uom code
    lr_res_rec.autodetail_group_id          := NULL;
    lr_res_rec.external_source_code         := NULL;
    lr_res_rec.external_source_line_id      := NULL;
    lr_res_rec.supply_source_line_detail    := NULL;
    lr_res_rec.revision                     := NULL;
    lr_res_rec.subinventory_code            := NULL;
    lr_res_rec.subinventory_id              := NULL;
    lr_res_rec.locator_id                   := NULL;
    lr_res_rec.lot_number                   := NULL;
    lr_res_rec.lot_number_id                := NULL;
    lr_res_rec.pick_slip_number             := NULL;
    lr_res_rec.lpn_id                       := NULL;
    lr_res_rec.ship_ready_flag              := NULL;
    lr_res_rec.detailed_quantity            := 2;            ---check this

    lr_res_rec.attribute_category := NULL;
    lr_res_rec.attribute1         := NULL;
    lr_res_rec.attribute2         := NULL;
    lr_res_rec.attribute3         := NULL;
    lr_res_rec.attribute4         := NULL;
    lr_res_rec.attribute5         := NULL;
    lr_res_rec.attribute6         := NULL;
    lr_res_rec.attribute7         := NULL;
    lr_res_rec.attribute8         := NULL;
    lr_res_rec.attribute9         := NULL;
    lr_res_rec.attribute11        := NULL;
    lr_res_rec.attribute12        := NULL;
    lr_res_rec.attribute13        := NULL;
    lr_res_rec.attribute14        := NULL;
    lr_res_rec.attribute15        := NULL;
    lr_res_rec.ship_ready_flag    := NULL;
    lr_res_rec.reservation_id     := NULL;
    lr_res_rec.requirement_date   := SYSDATE;            ---check this
    
    

    
    
    INV_RESERVATION_PUB.create_reservation(p_api_version_number            => 1.0
                                          ,p_init_msg_lst                  => G_TRUE
                                          ,x_return_status                 => lc_api_return_status
                                          ,x_msg_count                     => ln_msg_count
                                          ,x_msg_data                      => lc_msg_data
                                          ,p_serial_number                 => lt_dummy_sn
                                          ,x_serial_number                 => lt_dummy_sn
                                          ,p_rsv_rec                       => lr_res_rec
                                          ,p_partial_reservation_flag      => G_TRUE
                                          ,p_force_reservation_flag        => G_FALSE
                                          ,p_validation_flag               => G_TRUE
                                          ,x_quantity_reserved             => ln_qty_succ_reserved
                                          ,x_reservation_id                => ln_org_wide_res_id
                                          );

   IF (lc_api_return_status <> 'S') THEN
   
       NULL;   --ROLLBACK;
       --Stop processing; 
       --return the error to the calling function, 
       --log error in the OM Error Message Log Framework
   
   
   ELSE 
   
      NULL; --Call the OM Demand API to create manual demand in the MTL_DEMANDS table.
   
   END IF;


EXCEPTION
    WHEN OTHERS THEN
    RAISE;

END CREATE_RESERVATION;


PROCEDURE INVENTORY_RESERVATION (p_reserve_option                IN VARCHAR2
                                ,p_reservation_key               IN VARCHAR2
                                ,p_demand_type_id                IN VARCHAR2  DEFAULT 13
                                ,p_location                      IN VARCHAR2
                                ,p_item_number                   IN VARCHAR2
                                ,p_primary_uom_code              IN VARCHAR2
                                ,p_reservation_uom_code          IN VARCHAR2
                                ,p_primary_reservation_quantity  IN NUMBER
                                ,p_creation_date                 IN VARCHAR2
                                ,p_subinventory                  IN VARCHAR2  DEFAULT 'STOCK'
                                ,p_attribute11                   IN VARCHAR2
                                ,p_attribute12                   IN VARCHAR2
                                ,p_attribute13                   IN VARCHAR2
                                ,p_attribute14                   IN VARCHAR2
                                ,p_attribute15                   IN VARCHAR2
                                ,x_status                        OUT VARCHAR2
                                ,x_error_message                 OUT VARCHAR2
                                )
-- +===============================================================================+
-- |                                                                               |
-- | Name             :                                                            |
-- |                                                                               |
-- | Description      :                                                            |
-- |                                                                               |
-- |                                                                               |
-- |                  :                                                            |
-- |                                                                               |
-- +===============================================================================+
IS


EX_NOT_VALID_RECORD   EXCEPTION;
EX_UNKNOWN_EXCEPTION  EXCEPTION;
EX_END_PROC           EXCEPTION;

lc_error_message VARCHAR2(3000)  := NULL;

ln_count         NUMBER          := NULL;




BEGIN

    -- Fetching organization_id from location code
    BEGIN
       SELECT organization_id
       INTO   gn_organization_id
       FROM   hr_all_organization_units
       WHERE  attribute1 = p_location;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          fnd_message.set_name ('XXPTP', 'XX_INV_12_ORG_ID_NULL');
          lc_error_message := fnd_message.get;
          RAISE EX_NOT_VALID_RECORD;
       WHEN OTHERS THEN
          lc_error_message := SQLERRM;
          RAISE EX_UNKNOWN_EXCEPTION;
    END;


    -- Checking whether the item exists
    BEGIN
       SELECT inventory_item_id
       INTO   gn_inventory_item_id
       FROM   mtl_system_items_b msi
       WHERE  segment1         = p_item_number
       AND    organization_id  = gn_organization_id
       AND    primary_uom_code = p_primary_uom_code
       AND    enabled_flag     = 'Y'
       AND    TRUNC(SYSDATE) BETWEEN NVL (msi.start_date_active,TRUNC (SYSDATE))
                                 AND NVL (msi.end_date_active,TRUNC (SYSDATE) + 1);

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          fnd_message.set_name ('XXPTP', 'XX_INV_13_ITEM_INVALID');
          lc_error_message := fnd_message.get;
          RAISE EX_NOT_VALID_RECORD;
       WHEN OTHERS THEN
          lc_error_message := SQLERRM;
          RAISE EX_UNKNOWN_EXCEPTION;
    END;


    -- Checking validity for subinventory
    IF (p_subinventory IS NOT NULL) THEN
        ln_count := 0;

        SELECT COUNT (*)
        INTO   ln_count
        FROM   mtl_item_sub_inventories
        WHERE  secondary_inventory = p_subinventory
        AND    organization_id     = gn_organization_id;

        IF (ln_count = 0) THEN
           fnd_message.set_name ('XXPTP','XX_INV_14_SUBINV_INVALID');
           lc_error_message := fnd_message.get;
           RAISE EX_NOT_VALID_RECORD;
        END IF;

    -- If sub inventory is null it will default to 'STOCK'
    ELSE
      -- p_subinventory := 'STOCK';
      NULL;
    END IF;

    VALIDATE_RESERVATION_KEY (p_res_key => p_reservation_key);

    IF (p_reserve_option = 'C') THEN

        IF (gc_key_found = 'Y') THEN
        
            dbms_output.put_line('Reservaton Key Already Exists, Cannot Create');
            RAISE EX_END_PROC;
        
        END IF;
        
        CREATE_RESERVATION( p_organization_id              => gn_organization_id
                           ,p_inventory_item_id            => gn_inventory_item_id
                           ,p_demand_source_name           => p_reservation_key
                           ,p_primary_uom_code             => p_primary_uom_code
                           ,p_reservation_uom_code         => p_reservation_uom_code
                           ,p_primary_reservation_quantity => p_primary_reservation_quantity
                           ,p_subinventory                 => p_subinventory
                           ,p_attribute10                  => p_creation_date
                          );
    
    ELSIF (p_reserve_option = 'U') THEN
    
        UPDATE_RESERVATION();
    
    ELSIF (p_reserve_option = 'D') THEN
    
        NULL;
    
    
    ELSE
    
        dbms_output.put_line('Invalid Reserve Option.');
    
    END IF;


EXCEPTION
    
    WHEN EX_NOT_VALID_RECORD THEN
    NULL;
    
    WHEN EX_UNKNOWN_EXCEPTION THEN
    NULL;
    
    
    WHEN EX_END_PROC THEN
    NULL;
    
    WHEN OTHERS THEN
    NULL;

END INVENTORY_RESERVATION;

END XX_GI_RESERVATION_PKG;
/
SHOW ERRORS;
EXIT;