SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_map_ord_status_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_MAP_ORD_STATUS_PKG                                    |
-- | Rice ID     : E1264_TranslateMapOMOrderStatus                             |
-- | Description : Update the statuses on the Order Header Level and Order Line|
-- |               Level DFF attributes to reflect the various custom statuses.|
-- |               Status_Update API is to be called from various stages of the|
-- |               Order Processing Workflow Cyle.                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 21-Jun-2007  Sudharsana Reddy       Initial draft version         |
-- |1.0      01-Aug-2007  Vidhya Valantina T     Baselined after testing       |
-- |                                                                           |
-- +===========================================================================+

AS

-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_ref                                     |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception( p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_ref        IN  VARCHAR2
                              ,p_entity_ref_id     IN  NUMBER
                             )
    IS

      x_errbuf              VARCHAR2(1000);
      x_retcode             VARCHAR2(40);


    BEGIN

      exception_object_type.p_error_code        := p_error_code;
      exception_object_type.p_error_description := p_error_description;
      exception_object_type.p_entity_ref        := p_entity_ref;
      exception_object_type.p_entity_ref_id     := p_entity_ref_id;

      XX_OM_GLOBAL_EXCEPTION_PKG.Insert_Exception(
                                                   exception_object_type
                                                  ,x_errbuf
                                                  ,x_retcode
                                                 );

    END Write_Exception;

    -- +===================================================================+
    -- | Name        : Attribute_Update                                    |
    -- | Description : Procedure updates DFF attributes with Translated    |
    -- |               Custom Status on Order header and line levels.      |
    -- |                                                                   |
    -- | Parameters  : Header_Id                                           |
    -- |               Line_Id                                             |
    -- |               Lookup_Code                                         |
    -- |                                                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Attribute_Update ( p_header_id   IN NUMBER DEFAULT NULL
                                ,p_line_id     IN NUMBER DEFAULT NULL
                                ,p_lookup_code IN VARCHAR2
                               )
    IS

        lc_entity_ref                 VARCHAR2(40);
        lc_entity_ref_id              NUMBER;
        lc_errbuf                     VARCHAR2(4000);
        lc_error_code                 VARCHAR2(40);
        lc_error_msg                  VARCHAR2(1000);
        lc_return_status              VARCHAR2(10);

        ln_line_id                    NUMBER;

        CURSOR lcu_ord_lines ( p_header_id IN NUMBER )
        IS
        SELECT line_id
        FROM   oe_order_lines_all   OOLA
        WHERE  header_id = p_header_id;

        CURSOR lcu_ord_line_attr ( p_line_id IN NUMBER )
        IS
        SELECT *
        FROM   xx_om_line_attributes_all XOHAA
        WHERE  XOHAA.line_id = p_line_id;

        lr_line_rec                   lcu_ord_line_attr%ROWTYPE;

        lr_line_attr_rec              xx_om_line_attributes_t;

    BEGIN

        IF ( p_line_id IS NOT NULL ) THEN

            OPEN  lcu_ord_line_attr ( p_line_id );
            FETCH lcu_ord_line_attr INTO lr_line_rec;
            CLOSE lcu_ord_line_attr;

            lr_line_rec.trans_line_status := p_lookup_code;

            lr_line_attr_rec              := xx_om_line_attributes_t(
                                                                      lr_line_rec.line_id
                                                                     ,lr_line_rec.licence_address
                                                                     ,lr_line_rec.vendor_config_id
                                                                     ,lr_line_rec.fulfillment_type
                                                                     ,lr_line_rec.line_type
                                                                     ,lr_line_rec.line_modifier
                                                                     ,lr_line_rec.release_num
                                                                     ,lr_line_rec.cost_center_dept
                                                                     ,lr_line_rec.desktop_del_addr
                                                                     ,lr_line_rec.vendor_site_id
                                                                     ,lr_line_rec.pos_trx_num
                                                                     ,lr_line_rec.one_time_deal
                                                                     ,lr_line_rec.trans_line_status
                                                                     ,lr_line_rec.cust_price
                                                                     ,lr_line_rec.cust_uom
                                                                     ,lr_line_rec.cust_comments
                                                                     ,lr_line_rec.pip_campaign_id
                                                                     ,lr_line_rec.ext_top_model_line_id
                                                                     ,lr_line_rec.ext_link_to_line_id
                                                                     ,lr_line_rec.config_code
                                                                     ,lr_line_rec.gift_message
                                                                     ,lr_line_rec.gift_email
                                                                     ,lr_line_rec.return_rga_number
                                                                     ,lr_line_rec.delivery_date_from
                                                                     ,lr_line_rec.delivery_date_to
                                                                     ,lr_line_rec.wholesaler_fac_cd
                                                                     ,lr_line_rec.wholesaler_acct_num
                                                                     ,lr_line_rec.return_act_cat_code
                                                                     ,lr_line_rec.po_del_details
                                                                     ,lr_line_rec.ret_ref_header_id
                                                                     ,lr_line_rec.ret_ref_line_id
                                                                     ,lr_line_rec.ship_to_flag
                                                                     ,lr_line_rec.item_note
                                                                     ,lr_line_rec.special_desc
                                                                     ,lr_line_rec.non_cd_line_type
                                                                     ,lr_line_rec.supplier_type
                                                                     ,lr_line_rec.vendor_product_code
                                                                     ,lr_line_rec.contract_details
                                                                     ,lr_line_rec.aops_orig_order_num
                                                                     ,lr_line_rec.aops_orig_order_date
                                                                     ,lr_line_rec.item_comments
                                                                     ,lr_line_rec.backordered_qty
                                                                     ,lr_line_rec.taxable_flag
                                                                     ,lr_line_rec.waca_parent_id
                                                                     ,lr_line_rec.aops_orig_order_line_num
                                                                     ,lr_line_rec.sku_dept
                                                                     ,lr_line_rec.item_source
                                                                     ,lr_line_rec.average_cost
                                                                     ,lr_line_rec.canada_pst_tax
                                                                     ,lr_line_rec.po_cost
                                                                     ,lr_line_rec.resourcing_flag
                                                                     ,lr_line_rec.waca_status
                                                                     ,lr_line_rec.cust_item_number
                                                                     ,lr_line_rec.pod_date
                                                                     ,lr_line_rec.return_auth_id
                                                                     ,lr_line_rec.return_code
                                                                     ,lr_line_rec.sku_list_price
                                                                     ,lr_line_rec.waca_item_ctr_num
                                                                     ,lr_line_rec.new_schedule_ship_date
                                                                     ,lr_line_rec.new_schedule_arr_date
                                                                     ,lr_line_rec.taylor_unit_price
                                                                     ,lr_line_rec.taylor_unit_cost
                                                                     ,lr_line_rec.xdock_inv_org_id
                                                                     ,lr_line_rec.payment_subtype_cod_ind
                                                                     ,lr_line_rec.del_to_post_office_ind
                                                                     ,lr_line_rec.wholesaler_item
                                                                     ,lr_line_rec.cust_comm_pref
                                                                     ,lr_line_rec.cust_pref_email
                                                                     ,lr_line_rec.cust_pref_fax
                                                                     ,lr_line_rec.cust_pref_phone
                                                                     ,lr_line_rec.cust_pref_phextn
                                                                     ,lr_line_rec.freight_line_id
                                                                     ,lr_line_rec.freight_primary_line_id
                                                                     ,lr_line_rec.creation_date
                                                                     ,lr_line_rec.created_by
                                                                     ,lr_line_rec.last_update_date
                                                                     ,lr_line_rec.last_updated_by
                                                                     ,lr_line_rec.last_update_login
                                                                    );

            XX_OM_LINE_ATTRIBUTES_PKG.Update_Row( p_line_rec       => lr_line_attr_rec
                                                 ,x_return_status  => lc_return_status
                                                 ,x_errbuf         => lc_errbuf);

            IF ( lc_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN

                lc_error_msg         := lc_errbuf;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR1';
                lc_entity_ref        := 'ORDER_LINE_ID';
                lc_entity_ref_id     :=  p_line_id;

                Write_Exception ( p_error_code        => lc_error_code
                                 ,p_error_description => lc_error_msg
                                 ,p_entity_ref        => lc_entity_ref
                                 ,p_entity_ref_id     => lc_entity_ref_id
                                );

            END IF;

        ELSIF ( p_line_id IS NULL AND p_header_id IS NOT NULL ) THEN

            FOR ord_lines_rec IN lcu_ord_lines ( p_header_id )
            LOOP

                ln_line_id := ord_lines_rec.line_id;

                OPEN  lcu_ord_line_attr ( ln_line_id );
                FETCH lcu_ord_line_attr INTO lr_line_rec;
                CLOSE lcu_ord_line_attr;

                lr_line_rec.trans_line_status := p_lookup_code;

                lr_line_attr_rec              := xx_om_line_attributes_t(
                                                                          lr_line_rec.line_id
                                                                         ,lr_line_rec.licence_address
                                                                         ,lr_line_rec.vendor_config_id
                                                                         ,lr_line_rec.fulfillment_type
                                                                         ,lr_line_rec.line_type
                                                                         ,lr_line_rec.line_modifier
                                                                         ,lr_line_rec.release_num
                                                                         ,lr_line_rec.cost_center_dept
                                                                         ,lr_line_rec.desktop_del_addr
                                                                         ,lr_line_rec.vendor_site_id
                                                                         ,lr_line_rec.pos_trx_num
                                                                         ,lr_line_rec.one_time_deal
                                                                         ,lr_line_rec.trans_line_status
                                                                         ,lr_line_rec.cust_price
                                                                         ,lr_line_rec.cust_uom
                                                                         ,lr_line_rec.cust_comments
                                                                         ,lr_line_rec.pip_campaign_id
                                                                         ,lr_line_rec.ext_top_model_line_id
                                                                         ,lr_line_rec.ext_link_to_line_id
                                                                         ,lr_line_rec.config_code
                                                                         ,lr_line_rec.gift_message
                                                                         ,lr_line_rec.gift_email
                                                                         ,lr_line_rec.return_rga_number
                                                                         ,lr_line_rec.delivery_date_from
                                                                         ,lr_line_rec.delivery_date_to
                                                                         ,lr_line_rec.wholesaler_fac_cd
                                                                         ,lr_line_rec.wholesaler_acct_num
                                                                         ,lr_line_rec.return_act_cat_code
                                                                         ,lr_line_rec.po_del_details
                                                                         ,lr_line_rec.ret_ref_header_id
                                                                         ,lr_line_rec.ret_ref_line_id
                                                                         ,lr_line_rec.ship_to_flag
                                                                         ,lr_line_rec.item_note
                                                                         ,lr_line_rec.special_desc
                                                                         ,lr_line_rec.non_cd_line_type
                                                                         ,lr_line_rec.supplier_type
                                                                         ,lr_line_rec.vendor_product_code
                                                                         ,lr_line_rec.contract_details
                                                                         ,lr_line_rec.aops_orig_order_num
                                                                         ,lr_line_rec.aops_orig_order_date
                                                                         ,lr_line_rec.item_comments
                                                                         ,lr_line_rec.backordered_qty
                                                                         ,lr_line_rec.taxable_flag
                                                                         ,lr_line_rec.waca_parent_id
                                                                         ,lr_line_rec.aops_orig_order_line_num
                                                                         ,lr_line_rec.sku_dept
                                                                         ,lr_line_rec.item_source
                                                                         ,lr_line_rec.average_cost
                                                                         ,lr_line_rec.canada_pst_tax
                                                                         ,lr_line_rec.po_cost
                                                                         ,lr_line_rec.resourcing_flag
                                                                         ,lr_line_rec.waca_status
                                                                         ,lr_line_rec.cust_item_number
                                                                         ,lr_line_rec.pod_date
                                                                         ,lr_line_rec.return_auth_id
                                                                         ,lr_line_rec.return_code
                                                                         ,lr_line_rec.sku_list_price
                                                                         ,lr_line_rec.waca_item_ctr_num
                                                                         ,lr_line_rec.new_schedule_ship_date
                                                                         ,lr_line_rec.new_schedule_arr_date
                                                                         ,lr_line_rec.taylor_unit_price
                                                                         ,lr_line_rec.taylor_unit_cost
                                                                         ,lr_line_rec.xdock_inv_org_id
                                                                         ,lr_line_rec.payment_subtype_cod_ind
                                                                         ,lr_line_rec.del_to_post_office_ind
                                                                         ,lr_line_rec.wholesaler_item
                                                                         ,lr_line_rec.cust_comm_pref
                                                                         ,lr_line_rec.cust_pref_email
                                                                         ,lr_line_rec.cust_pref_fax
                                                                         ,lr_line_rec.cust_pref_phone
                                                                         ,lr_line_rec.cust_pref_phextn
                                                                         ,lr_line_rec.freight_line_id
                                                                         ,lr_line_rec.freight_primary_line_id
                                                                         ,lr_line_rec.creation_date
                                                                         ,lr_line_rec.created_by
                                                                         ,lr_line_rec.last_update_date
                                                                         ,lr_line_rec.last_updated_by
                                                                         ,lr_line_rec.last_update_login
                                                                        );

                XX_OM_LINE_ATTRIBUTES_PKG.Update_Row( p_line_rec       => lr_line_attr_rec
                                                     ,x_return_status  => lc_return_status
                                                     ,x_errbuf         => lc_errbuf);

                IF ( lc_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN

                    lc_error_msg         := lc_errbuf;
                    lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR2';
                    lc_entity_ref        := 'ORDER_LINE_ID';
                    lc_entity_ref_id     :=  p_line_id;

                    Write_Exception ( p_error_code        => lc_error_code
                                     ,p_error_description => lc_error_msg
                                     ,p_entity_ref        => lc_entity_ref
                                     ,p_entity_ref_id     => lc_entity_ref_id
                                    );

                END IF;

            END LOOP;

        END IF;

        COMMIT;

    EXCEPTION

    WHEN OTHERS THEN

        ROLLBACK;

        IF ( lcu_ord_line_attr%ISOPEN ) THEN

            CLOSE lcu_ord_line_attr;

        END IF;

        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);

        lc_error_msg         := FND_MESSAGE.GET;
        lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR3';


        IF ( p_line_id IS NULL ) THEN

            lc_entity_ref        := 'ORDER_HDR_ID';
            lc_entity_ref_id     :=  p_header_id;

        ELSE

            lc_entity_ref        := 'ORDER_LINE_ID';
            lc_entity_ref_id     :=  p_line_id;

        END IF;

        Write_Exception ( p_error_code        => lc_error_code
                         ,p_error_description => lc_error_msg
                         ,p_entity_ref        => lc_entity_ref
                         ,p_entity_ref_id     => lc_entity_ref_id
                        );

    END Attribute_Update;

    -- +===================================================================+
    -- | Name        :  Status_Update                                      |
    -- | Description :  Procedure is derive the custom (order,line) status |
    -- |                code from lookup based on Priority wise            |
    -- |                                                                   |
    -- | Parameters  :  Order_Header_Id                                    |
    -- |                Order_Line_Id                                      |
    -- |                Event                                              |
    -- |                Hold_Level                                         |
    -- |                                                                   |
    -- | Returns     :  Return_Status                                      |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE Status_Update ( p_order_header_id  IN  NUMBER   DEFAULT NULL
                             ,p_order_line_id    IN  NUMBER   DEFAULT NULL
                             ,p_event            IN  NUMBER
                             ,p_hold_level       IN  VARCHAR2 DEFAULT NULL
                             ,x_return_status    OUT VARCHAR2
                            )
    IS

        CURSOR lcu_ord_hdr_hold_stts ( p_header_id  IN NUMBER
                                      ,p_event      IN VARCHAR2
                                      ,p_hold_level IN VARCHAR2
                                     )
        IS
        SELECT FLV.lookup_code
        FROM   oe_hold_definitions   OHD
              ,oe_order_holds_all    OOHA
              ,oe_hold_sources_all   OHSA
              ,fnd_lookup_values     FLV
        WHERE  OHSA.hold_source_id = OOHA.hold_source_id
        AND    OHD.hold_id         = OHSA.hold_id
        AND    OOHA.released_flag  = 'N'
        AND    OOHA.header_id      = p_header_id
        AND    FLV.lookup_type     = 'XX_OD_OM_STATUS_LKUP'
        AND    FLV.enabled_flag    = 'Y'
        AND    TRUNC(NVL(FLV.start_date_active,sysdate)) <= TRUNC(sysdate)
        AND    TRUNC(NVL(FLV.end_date_active,sysdate))   >= TRUNC(sysdate)
        AND    UPPER(OHD.name)     LIKE '%' || UPPER(FLV.attribute4) || '%'
        AND    FLV.attribute6      = p_event
        AND    FLV.attribute7      = p_hold_level
        ORDER BY FLV.attribute8;


        CURSOR lcu_ord_lin_hold_stts ( p_header_id  IN NUMBER
                                      ,p_line_id    IN NUMBER
                                      ,p_event      IN VARCHAR2
                                      ,p_hold_level IN VARCHAR2
                                     )
        IS
        SELECT FLV.lookup_code
        FROM   oe_hold_definitions   OHD
              ,oe_order_holds_all    OOHA
              ,oe_hold_sources_all   OHSA
              ,fnd_lookup_values     FLV
        WHERE  OHSA.hold_source_id = OOHA.hold_source_id
        AND    OHD.hold_id         = OHSA.hold_id
        AND    OOHA.released_flag  = 'N'
        AND    OOHA.header_id      = p_header_id
        AND    OOHA.line_id        = p_line_id
        AND    FLV.lookup_type     = 'XX_OD_OM_STATUS_LKUP'
        AND    FLV.enabled_flag    = 'Y'
        AND    TRUNC(NVL(FLV.start_date_active,sysdate)) <= TRUNC(sysdate)
        AND    TRUNC(NVL(FLV.end_date_active,sysdate))   >= TRUNC(sysdate)
        AND    UPPER(OHD.name)     LIKE '%' || UPPER(FLV.attribute4) || '%'
        AND    FLV.attribute6      = p_event
        AND    FLV.attribute7      = p_hold_level
        ORDER BY FLV.attribute8;

        CURSOR lcu_ord_hdr_on_hold ( p_header_id IN NUMBER )
        IS
        SELECT OOHA.hold_source_id
        FROM   oe_order_holds_all   OOHA
        WHERE  OOHA.header_id     = p_header_id
        AND    OOHA.released_flag = 'N';

        CURSOR lcu_ord_lin_on_hold ( p_line_id IN NUMBER )
        IS
        SELECT OOHA.hold_source_id
        FROM   oe_order_holds_all   OOHA
        WHERE  OOHA.line_id       = p_line_id
        AND    OOHA.released_flag = 'N';

        CURSOR lcu_status_lkup ( p_status IN VARCHAR2 )
        IS
        SELECT FLV.lookup_code
        FROM   fnd_lookup_values     FLV
        WHERE  FLV.lookup_type     = 'XX_OD_OM_STATUS_LKUP'
        AND    UPPER(FLV.meaning)  = UPPER(p_status)
        AND    FLV.enabled_flag    = 'Y'
        AND    TRUNC(NVL(FLV.start_date_active,sysdate)) <= TRUNC(sysdate)
        AND    TRUNC(NVL(FLV.end_date_active,sysdate))   >= TRUNC(sysdate);

        lc_entity_ref           VARCHAR2(40);
        lc_entity_ref_id        NUMBER;
        lc_error_code           VARCHAR2(40);
        lc_error_msg            VARCHAR2(1000);
        ln_hold_source_id       NUMBER;
        lc_status               VARCHAR2(40);

    BEGIN

        IF ( p_hold_level = 'Header' ) THEN

            FOR ord_hdr_on_hold_rec IN lcu_ord_hdr_on_hold ( p_order_header_id )
            LOOP

                ln_hold_source_id  := ord_hdr_on_hold_rec.hold_source_id;

                EXIT;

            END LOOP;

            IF ( ln_hold_source_id IS NOT NULL ) THEN

                FOR ord_hdr_hold_stts_rec IN lcu_ord_hdr_hold_stts ( p_order_header_id
                                                                    ,p_event
                                                                    ,p_hold_level
                                                                   )
                LOOP

                    lc_status := ord_hdr_hold_stts_rec.lookup_code;

                    EXIT;

                END LOOP;

            END IF;

            Attribute_Update ( p_header_id   => p_order_header_id
                              ,p_line_id     => NULL
                              ,p_lookup_code => lc_status
                             );

        ELSIF ( p_hold_level = 'Line' ) THEN

            FOR ord_lin_on_hold_rec IN lcu_ord_lin_on_hold ( p_order_line_id )
            LOOP

                ln_hold_source_id  := ord_lin_on_hold_rec.hold_source_id;

                EXIT;

            END LOOP;

            IF ( ln_hold_source_id IS NOT NULL ) THEN

                FOR ord_lin_hold_stts_rec IN lcu_ord_lin_hold_stts ( p_order_header_id
                                                                    ,p_order_line_id
                                                                    ,p_event
                                                                    ,p_hold_level
                                                                   )
                LOOP

                    lc_status := ord_lin_hold_stts_rec.lookup_code;

                    EXIT;

                END LOOP;

            END IF;

            Attribute_Update ( p_header_id   => NULL
                              ,p_line_id     => p_order_line_id
                              ,p_lookup_code => lc_status
                             );

        ELSIF ( p_hold_level IS NULL ) THEN

            FOR status_lkup_rec IN lcu_status_lkup ( p_event )
            LOOP

               lc_status := status_lkup_rec.lookup_code;

            END LOOP;

            IF p_order_line_id IS NULL THEN

                Attribute_Update ( p_header_id   => p_order_header_id
                                  ,p_line_id     => NULL
                                  ,p_lookup_code => lc_status
                                 );

            ELSIF p_order_line_id IS NOT NULL THEN

                Attribute_Update ( p_header_id   => NULL
                                  ,p_line_id     => p_order_line_id
                                  ,p_lookup_code => lc_status
                                 );

            END IF;

        END IF;

    EXCEPTION

    WHEN OTHERS THEN

        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);

        lc_error_msg         := FND_MESSAGE.GET;
        lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR4';


        IF ( p_order_line_id IS NULL ) THEN

            lc_entity_ref        := 'ORDER_HDR_ID';
            lc_entity_ref_id     :=  p_order_header_id;

        ELSE

            lc_entity_ref        := 'ORDER_LINE_ID';
            lc_entity_ref_id     :=  p_order_line_id;

        END IF;

        Write_Exception ( p_error_code        => lc_error_code
                         ,p_error_description => lc_error_msg
                         ,p_entity_ref        => lc_entity_ref
                         ,p_entity_ref_id     => lc_entity_ref_id
                        );

    END Status_Update;

END xx_om_map_ord_status_pkg;
/

SHOW ERRORS;