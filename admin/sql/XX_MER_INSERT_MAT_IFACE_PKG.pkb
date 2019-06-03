SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_MER_INSERT_MAT_IFACE_PKG AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Office Depot                                                   |
-- +===============================================================================+
-- | Name  : XX_MER_INSERT_MAT_IFACE_PKG                                           |
-- | Description  : This package contains procedures related to inserting of orders|
-- |                into material interface table for all orders where parts are   |
-- |                assigned to a service request                                  |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version    Date          Author            Remarks                             |
-- |=======    ==========    =============     ====================================|
-- |1.0        12-JUL-2011   Bapuji Nanapaneni Initial version                     |
-- |1.1        21-MAY-2012   Oracle AMS Team   Modified the transaction date while |
-- |                                           entering the MTI table,according to |
-- |                                           to defect# 18626                    |
-- |1.2        19-Oct-2015   Madhu Bolli      Remove schema for 12.2 retrofit      |
-- |1.3        19-Oct-2015   Madhu Bolli      Remove schema 'ont' for 12.2 retrofit|
-- +===============================================================================+

PROCEDURE insert_to_mat_iface( p_header_id      IN NUMBER
                             , p_batch_id       IN NUMBER
                             , p_mode           IN VARCHAR2
                             , x_return_status OUT VARCHAR2
                             ) IS

CURSOR c_sr_number_n (p_header_id IN NUMBER) IS
    SELECT x.sr_number
         , h.header_id
         , h.ship_from_org_id organization_id
      FROM oe_order_headers_all h
         , xx_om_header_attributes_all x
     WHERE x.header_id = h.header_id
       AND x.sr_number IS NOT NULL
       AND h.header_id  = p_header_id;

CURSOR c_sr_number_b (p_batch_id IN NUMBER) IS
    SELECT x.sr_number
         , h.header_id
         , h.ship_from_org_id organization_id
      FROM oe_order_headers_all h
         , xx_om_header_attributes_all x
     WHERE x.header_id = h.header_id
       AND x.sr_number IS NOT NULL
       AND h.batch_id  = p_batch_id;

CURSOR c_tds_parts(p_sr_number VARCHAR2) IS
    SELECT request_number
         , line_number
         , inventory_item_id
         , rms_sku
         , store_id
         , (-1*(quantity - NVL(excess_quantity,0)) ) quantity
         , uom
         , NVL(completion_date,SYSDATE) ship_date
         , excess_flag
      FROM xx_cs_tds_parts
     WHERE request_number = p_sr_number
       AND NVL(sales_flag,'N') = 'Y'
       AND (quantity - NVL(excess_quantity,0)) <> 0;

CURSOR c_tds_parts_b (p_sr_number VARCHAR2) IS
    SELECT request_number
         , line_number
         , inventory_item_id
         , rms_sku
         , store_id
         , (-1*(quantity - NVL(excess_quantity,0)) ) quantity
         , uom
         , NVL(completion_date,SYSDATE) ship_date
         , excess_flag
      FROM xx_cs_tds_parts
     WHERE request_number = p_sr_number
       AND NVL(sales_flag,'N') = 'Y'
       AND (quantity - NVL(excess_quantity,0)) <> 0;

/*      Local Variables      */
 ln_tran_iface_id        mtl_transactions_interface.transaction_interface_id%TYPE;
 lc_source_code          mtl_transactions_interface.source_code%TYPE                 := 'SPARE PARTS';
 ln_user_id              fnd_user.user_id%TYPE;
 ld_creation_date        oe_order_headers_all.creation_date%TYPE                 := SYSDATE;    -- 1.3
 lc_subinv_code          mtl_transactions_interface.subinventory_code%TYPE           := 'STOCK';
 ln_tran_source_type_id  mtl_transactions_interface.transaction_source_type_id%TYPE;
 ln_tran_action_id       mtl_transactions_interface.transaction_action_id%TYPE;
 ln_tran_type_id         mtl_transactions_interface.transaction_type_id%TYPE;
 lc_material_acct        mtl_transactions_interface.material_account%TYPE;
 lc_tran_ref             mtl_transactions_interface.transaction_reference%TYPE;
 lc_error_code           mtl_transactions_interface.error_code%TYPE;
 lc_error_explanation    VARCHAR2(2000); --mtl_transactions_interface.error_explanation%TYPE;

 ln_source_header_id     NUMBER;
 ln_source_line_id       NUMBER;

 j                       BINARY_INTEGER := 0;

 TYPE batch_header_type IS TABLE OF c_sr_number_b%rowtype;
 batch_header_array  batch_header_type;
 order_rec batch_header_type;

 TYPE batch_tdsparts_type IS TABLE OF c_tds_parts_b%rowtype;
 batch_tdsparts_array batch_tdsparts_type;
 line_rec batch_tdsparts_type;

 lc_material_rec XX_MER_INSERT_MAT_IFACE_PKG.material_rec_type;

BEGIN
    ln_user_id      := fnd_global.user_id;
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    /* Derive transaction_source_type_id */
    BEGIN

    SELECT transaction_source_type_id
      INTO ln_tran_source_type_id
      FROM mtl_txn_source_types
     WHERE transaction_source_type_name = 'Inventory';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No_Data_Found for ln_tran_source_type_id :::');
            ln_tran_source_type_id := NULL;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised for ln_tran_source_type_id :::'||SQLERRM);
            ln_tran_source_type_id := NULL;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    END;

    /* Derive transaction_type_id and transaction_action_id */
    BEGIN
        SELECT transaction_action_id
             , transaction_type_id
          INTO ln_tran_action_id
             , ln_tran_type_id
          FROM mtl_transaction_types
         WHERE transaction_type_name = 'OD TDS Parts Issue';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No_Data_Found for ln_tran_type_id and ln_tran_action_id :::');
            ln_tran_type_id        := NULL;
            ln_tran_action_id      := NULL;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised for ln_tran_type_id and ln_tran_action_id :::'||SQLERRM);
            ln_tran_type_id        := NULL;
            ln_tran_action_id      := NULL;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    END;

    IF p_mode = 'HVOP' THEN
        OPEN c_sr_number_b(p_batch_id);
        LOOP
            FETCH c_sr_number_b BULK COLLECT INTO batch_header_array LIMIT 100;

                FOR i IN 1..batch_header_array.COUNT LOOP

                    ln_source_header_id := batch_header_array(i).header_id;

                    OPEN c_tds_parts_b(batch_header_array(i).sr_number);
                    LOOP
                        FETCH c_tds_parts_b BULK COLLECT INTO batch_tdsparts_array LIMIT 500;

                            FOR i IN 1..batch_tdsparts_array.COUNT LOOP
                                j := j+1;

                                lc_material_rec.transaction_interface_id(j)     := NULL;
                                lc_material_rec.source_code(j)                  := NULL;
                                lc_material_rec.source_line_id(j)               := NULL;
                                lc_material_rec.source_header_id(j)             := NULL;
                                lc_material_rec.validation_required(j)          := NULL;
                                lc_material_rec.inventory_item_id(j)            := NULL;
                                lc_material_rec.organization_id(j)              := NULL;
                                lc_material_rec.transaction_quantity(j)         := NULL;
                                lc_material_rec.transaction_uom(j)              := NULL;
                                lc_material_rec.transaction_date(j)             := NULL;
                                lc_material_rec.subinventory_code(j)            := NULL;
                                lc_material_rec.transaction_source_type_id(j)   := NULL;
                                lc_material_rec.transaction_action_id(j)        := NULL;
                                lc_material_rec.transaction_type_id(j)          := NULL;
                                lc_material_rec.transaction_reference(j)        := NULL;
                                lc_material_rec.distribution_account_id(j)      := NULL;
                                lc_material_rec.process_flag(j)	                := NULL;
                                lc_material_rec.transaction_mode(j)             := NULL;
                                lc_material_rec.error_code(j)                   := NULL;
                                lc_material_rec.error_explanation(j)            := NULL;

                                SELECT mtl_material_transactions_s.NEXTVAL INTO lc_material_rec.transaction_interface_id(j) FROM DUAL;

                                SELECT material_account INTO lc_material_rec.distribution_account_id(j)
                                  FROM mtl_parameters
                                 WHERE organization_id = batch_tdsparts_array(i).store_id;

                                lc_material_rec.source_code(j)                  := 'SPARE PARTS';
                                lc_material_rec.source_header_id(j)             := ln_source_header_id;
                                lc_material_rec.validation_required(j)          := 1;
                                lc_material_rec.subinventory_code(j)            := 'STOCK';
                                lc_material_rec.transaction_source_type_id(j)   := ln_tran_source_type_id;
                                lc_material_rec.transaction_action_id(j)        := ln_tran_action_id;
                                lc_material_rec.transaction_type_id(j)          := ln_tran_type_id;
                                lc_material_rec.process_flag(j)	                := 1;
                                lc_material_rec.transaction_mode(j)             := 3;
                                lc_material_rec.source_line_id(j)        := lc_material_rec.source_header_id(j)||batch_tdsparts_array(i).line_number;
                                lc_material_rec.inventory_item_id(j)     := batch_tdsparts_array(i).inventory_item_id;
                                lc_material_rec.organization_id(j)       := batch_tdsparts_array(i).store_id;
                                lc_material_rec.transaction_quantity(j)	 := batch_tdsparts_array(i).quantity;
                                lc_material_rec.transaction_uom(j)	 := batch_tdsparts_array(i).uom;
                                --As per defect#18626, earlier the completion date from xx_cs_tds_parts was not in the same period as the Order Date of the Service Order, 
                                --which was taking those Material Transaction(Issue Outs) into close period and resulting in erroring in Interface                                
                                lc_material_rec.transaction_date(j)	 := sysdate ;
                                --lc_material_rec.transaction_date(j)	 := batch_tdsparts_array(i).ship_date;  /* Commented as per defect# 18626*/
                                lc_material_rec.transaction_reference(j) := batch_tdsparts_array(i).request_number||'-'||batch_tdsparts_array(i).line_number;

                                IF lc_material_rec.transaction_source_type_id(j) IS NULL THEN
                                    lc_material_rec.transaction_source_type_id(j) := NULL ;
                                    lc_error_code          := 'HVOP';
                                    lc_error_explanation   := ' No tran_source_type is set up for source_type_name = Inventory ';
                                END IF;

                                IF lc_material_rec.transaction_action_id(j) IS NULL THEN
                                    lc_material_rec.transaction_action_id(j) := NULL;
                                    lc_error_code          := 'HVOP';
                                    lc_error_explanation   := lc_error_explanation||' No tran_action is set up for source_type_name = OD SPARE PARTS ISSUE ';
                                END IF;

                                IF lc_material_rec.transaction_type_id(j) IS NULL THEN
                                    lc_material_rec.transaction_type_id(j) := -1;
                                    lc_error_code          := 'HVOP';
                                    lc_error_explanation   := lc_error_explanation||' No tran_type is set up for source_type_name = OD SPARE PARTS ISSUE ';
                                END IF;

                                lc_material_rec.error_code(j)        := lc_error_code;
                                lc_material_rec.error_explanation(j) := substr(lc_error_explanation,1,239);
                            END LOOP;
                                EXIT WHEN c_tds_parts_b%NOTFOUND;
                    END LOOP;
                    CLOSE c_tds_parts_b;
                END LOOP;
                    EXIT WHEN c_sr_number_b%NOTFOUND;
        END LOOP;
        CLOSE c_sr_number_b;
            FORALL k IN lc_material_rec.transaction_interface_id.FIRST ..lc_material_rec.transaction_interface_id.LAST
                INSERT INTO mtl_transactions_interface
			                      ( transaction_interface_id
			                      , source_code
			                      , source_line_id
			                      , source_header_id
			                      , validation_required
			                      , last_update_date
			                      , last_updated_by
			                      , creation_date
			                      , created_by
			                      , last_update_login
			                      , inventory_item_id
			                      , organization_id
			                      , transaction_quantity
			                      , transaction_uom
			                      , transaction_date
			                      , subinventory_code
			                      , transaction_source_type_id
			                      , transaction_action_id
			                      , transaction_type_id
			                      , transaction_reference
			                      , distribution_account_id
			                      , process_flag
			                      , transaction_mode
			                      , error_code
			                      , error_explanation
			                      ) VALUES
			                      ( lc_material_rec.transaction_interface_id(k)
			                      , lc_material_rec.source_code(k)
			                      , lc_material_rec.source_line_id(k)
			                      , lc_material_rec.source_header_id(k)
			                      , lc_material_rec.validation_required(k)
			                      , SYSDATE
			                      , ln_user_id
			                      , SYSDATE
			                      , ln_user_id
			                      , NULL
			                      , lc_material_rec.inventory_item_id(k)
			                      , lc_material_rec.organization_id(k)
			                      , lc_material_rec.transaction_quantity(k)
			                      , lc_material_rec.transaction_uom(k)
			                      , lc_material_rec.transaction_date(k)
			                      , lc_material_rec.subinventory_code(k)
			                      , lc_material_rec.transaction_source_type_id(k)
			                      , lc_material_rec.transaction_action_id(k)
			                      , lc_material_rec.transaction_type_id(k)
			                      , lc_material_rec.transaction_reference(k)
			                      , lc_material_rec.distribution_account_id(k)
			                      , lc_material_rec.process_flag(k)
			                      , lc_material_rec.transaction_mode(k)
			                      , lc_material_rec.error_code(k)
			                      , substr(lc_material_rec.error_explanation(k),1,239)
		                              );

    ELSE
        FOR r_sr_number IN c_sr_number_n(p_header_id) LOOP

        ln_source_header_id := r_sr_number.header_id;

        FOR r_tds_parts IN c_tds_parts(r_sr_number.sr_number) LOOP

        SELECT mtl_material_transactions_s.NEXTVAL INTO ln_tran_iface_id FROM DUAL;

        SELECT material_account
         INTO lc_material_acct
         FROM mtl_parameters
        WHERE organization_id = r_tds_parts.store_id;

        IF ln_tran_source_type_id IS NULL THEN
            ln_tran_source_type_id :=  NULL;
            lc_error_code          := 'HVOP';
            lc_error_explanation   := ' No tran_source_type is set up for source_type_name = Inventory ';
        END IF;

        IF ln_tran_action_id IS NULL THEN
            ln_tran_action_id := NULL;
            lc_error_code          := 'HVOP';
            lc_error_explanation   := lc_error_explanation||' No tran_action is set up for source_type_name = OD SPARE PARTS ISSUE ';
        END IF;

        IF ln_tran_type_id IS NULL THEN
            ln_tran_type_id := -1;
            lc_error_code          := 'HVOP';
            lc_error_explanation   := lc_error_explanation||' No tran_type is set up for source_type_name = OD SPARE PARTS ISSUE ';
        END IF;

        ln_source_line_id := r_sr_number.header_id||r_tds_parts.line_number;
        lc_tran_ref       := r_tds_parts.request_number||'-'||r_tds_parts.line_number;

            INSERT INTO mtl_transactions_interface
	    			                  ( transaction_interface_id
	    			                  , source_code
	    			                  , source_line_id
	    			                  , source_header_id
	    			                  , validation_required
	    			                  , last_update_date
	    			                  , last_updated_by
	    			                  , creation_date
	    			                  , created_by
	    			                  , last_update_login
	    			                  , inventory_item_id
	    			                  , organization_id
	    			                  , transaction_quantity
	    			                  , transaction_uom
	    			                  , transaction_date
	    			                  , subinventory_code
	    			                  , transaction_source_type_id
	    			                  , transaction_action_id
	    			                  , transaction_type_id
	    			                  , transaction_reference
	    			                  , distribution_account_id
	    			                  , process_flag
	    			                  , transaction_mode
	    			                  , error_code
	    			                  , error_explanation
	    			                  ) VALUES
	    			                  ( ln_tran_iface_id
	    			                  , lc_source_code
	    			                  , ln_source_line_id
	    			                  , ln_source_header_id
	    			                  , 1
	    			                  , ld_creation_date
	    			                  , ln_user_id
	    			                  , ld_creation_date
	    			                  , ln_user_id
	    			                  , NULL
	    			                  , r_tds_parts.inventory_item_id
	    			                  , r_tds_parts.store_id
	    			                  , r_tds_parts.quantity
	    			                  , r_tds_parts.uom
	    			                  , sysdate
                             			 --Commented as per Defect# 18626 
                             			 --,r_tds_parts.ship_date
	    			                  , lc_subinv_code
	    			                  , ln_tran_source_type_id
	    			                  , ln_tran_action_id
	    			                  , ln_tran_type_id
	    			                  , lc_tran_ref
	    			                  , lc_material_acct
	    			                  , 1
	    			                  , 3
	    			                  , lc_error_code
	    			                  , SUBSTR(lc_error_explanation,1,239)
	    			                  );
        END LOOP; -- TDS_PARTS_LOOP
        END LOOP; -- HEADER LOOP

    END IF;
COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found to Process :::');
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised :::'||SQLERRM);
        x_return_status := FND_API.G_RET_STS_ERROR;
END insert_to_mat_iface;

END XX_MER_INSERT_MAT_IFACE_PKG;
/
SHOW ERRORS PACKAGE BODY XX_MER_INSERT_MAT_IFACE_PKG;
  
EXIT;
