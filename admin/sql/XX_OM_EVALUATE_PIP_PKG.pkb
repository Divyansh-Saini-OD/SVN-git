SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY xx_om_evaluate_pip_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_EVALUATE_PIP_PKG                                      |
-- | Rice ID     : E0277_PackageInsertProcess                                  |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 13-Apr-2007  Francis                Initial draft version         |
-- |DRAFT 1B 22-May-2007  Vidhya Valantina T     Added Validate_PIP_Items      |
-- |DRAFT 1C 08-Jun-2007  Pankaj Kapse           Added logic to add the        |
-- |                                             order line with promotional   |
-- |                                             item to an order.             |
-- |1.0      29-Jun-2007  Pankaj Kapse           Baselined after review        |
-- |1.1      26-Jul-2007  Pankaj Kapse           Made changes for order header,|
-- |                                             line attributes               |  
-- |1.2      22-Aug-2007  Matthew Craig          Rewrite to correct issues     |
-- +===========================================================================+

AS  -- Package Body Block

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
     lc_retcode   VARCHAR2(4000);

BEGIN                               -- Procedure Block

     ge_exception.p_error_code        := p_error_code;
     ge_exception.p_error_description := p_error_description;
     ge_exception.p_entity_ref        := p_entity_reference;
     ge_exception.p_entity_ref_id     := p_entity_ref_id;

     xx_om_global_exception_pkg.Insert_Exception(
                                                  ge_exception
                                                 ,lc_errbuf
                                                 ,lc_retcode
                                                );

END Write_Exception;                -- End Procedure Block

    -- +===================================================================+
    -- | Name  : Validate_Pip_List                                         |
    -- | Description:       This Function will be used to validate the     |
    -- |                    pip_list for a ship_to_org_id                  |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters:        p_ship_to_org_id                               |
    -- |                    p_campaign_id                                  |
    -- |                                                                   |
    -- | Returns :          lc_validation_flag                             |
    -- |                                                                   |
    -- +===================================================================+

FUNCTION Validate_Pip_List(
                               p_ship_to_org_id    IN  PLS_INTEGER
                              ,p_campaign_id       IN  PLS_INTEGER
                             ) RETURN VARCHAR2
AS

    lc_postal_code          hz_locations.postal_code%TYPE;
    lc_validation_flag      VARCHAR2(1) := 'N';
    lc_errbuf               VARCHAR2(4000);
    lc_err_code             VARCHAR2(1000);


    ln_customer_id          ra_customers.customer_id%TYPE;

    CURSOR lcu_customer_id(p_ship_to_org_id NUMBER) IS
    SELECT 
        HL.postal_code,
        RC.customer_id
    FROM   
        hz_cust_accounts       HCA,
        hz_cust_acct_sites_all HCAS,
        hz_cust_site_uses_all  HCSU,
        hz_party_sites         HPS,
        hz_locations           HL,
        ra_customers           RC
    WHERE 
            HCAS.cust_account_id    = HCA.cust_account_id
        AND HCAS.cust_acct_site_id  = HCSU.cust_acct_site_id
        AND HCSU.site_use_code      = 'SHIP_TO'
        AND HCSU.site_use_id        = p_ship_to_org_id
        AND HPS.party_site_id       = HCAS.party_site_id
        AND HPS.party_id            = HCA.party_id
        AND HL.location_id          = HPS.location_id
        AND RC.party_id             = HCA.party_id;

    CURSOR lcu_zip_code(p_campaign_id NUMBER
                       ,p_customer_id NUMBER
                       ,p_zip_code VARCHAR2) IS
    SELECT  
        count(*) qualify_count
    FROM    
        xx_om_pip_lists
    WHERE   
            campaign_id = p_campaign_id
        AND (customer_id = p_customer_id OR zip_code = p_zip_code);

BEGIN

    FOR lr_customer_id IN lcu_customer_id(p_ship_to_org_id) 
    LOOP
        lc_postal_code := lr_customer_id.postal_code;
        ln_customer_id := lr_customer_id.customer_id;
    END LOOP;

    FOR lr_zip_code IN lcu_zip_code(p_campaign_id
                                    ,ln_customer_id
                                    ,lc_postal_code) 
    LOOP

         IF lr_zip_code.qualify_count > 0 THEN
            lc_validation_flag  :=  'Y';
         ELSE
            lc_validation_flag  :=  'N';
         END IF;
         
         EXIT;
         
    END LOOP;

    RETURN(lc_validation_flag);

EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR1';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );
      RETURN(lc_validation_flag);

END Validate_Pip_List;

    -- +===================================================================+
    -- | Name  : Validate_Order_Amount                                     |
    -- | Description:       This Function will be used to validate the     |
    -- |                    order amount.                                  |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters:        p_order_amount                                 |
    -- |                    p_order_header_id                              |
    -- |                                                                   |
    -- | Returns :          lc_validation_flag                             |
    -- |                                                                   |
    -- +===================================================================+

FUNCTION Validate_Order_Amount(
                                   p_order_amount     IN  ord_amt_rec_type
                                  ,p_order_header_id  IN  PLS_INTEGER
                                 ) RETURN VARCHAR2
AS

      lc_validation_flag  VARCHAR2(1) := 'N';
      lc_errbuf           VARCHAR2(4000);
      lc_err_code         VARCHAR2(1000);

      ln_order_total      PLS_INTEGER;

BEGIN

      --MC 22-Aug-2007 changed to incorporate qty*unitptice + charges+tax
      BEGIN
         ln_order_total  :=  oe_oe_totals_summary.PRT_ORDER_TOTAL(p_order_header_id);
      EXCEPTION
      WHEN OTHERS THEN
         ln_order_total  :=  NULL;
      END;

      --MC 22-Aug-2007 added NVL to garantee proper condition check
      IF p_order_amount.order_low_amount IS NOT NULL
        OR p_order_amount.order_high_amount IS NOT NULL THEN
          IF NVL(p_order_amount.order_range_exclude_flag,'N') =   'Y'  THEN
             IF (ln_order_total NOT BETWEEN
                 NVL(p_order_amount.order_low_amount,0)
                 AND NVL(p_order_amount.order_high_amount,999999999999)) THEN
                     lc_validation_flag  :=  'Y';
             ELSE
                     lc_validation_flag  :=  'N';
             END IF;
          ELSIF NVL(p_order_amount.order_range_exclude_flag,'N') <>  'Y'  THEN
             IF (ln_order_total  BETWEEN NVL(p_order_amount.order_low_amount,0)
                 AND NVL(p_order_amount.order_high_amount,999999999999)) THEN
                 lc_validation_flag  :=   'Y';
             ELSE
                 lc_validation_flag  :=   'N';
             END IF;
          END IF;
      ELSE
         lc_validation_flag  := 'Y';
      END IF;

      RETURN(lc_validation_flag);

EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR2';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );
      RETURN(lc_validation_flag);

END Validate_Order_Amount;

    -- +===================================================================+
    -- | Name  : Get_Index                                                 |
    -- | Description:       This Procedure will derive the index to insert |
    -- |                    in the PL/SQL table                            |
    -- |                                                                   |
    -- | Parameters:        Priority                                       |
    -- |                                                                   |
    -- | Returns   :        Index                                          |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Get_Index ( x_index     OUT NOCOPY PLS_INTEGER
                        ,p_priority   IN         PLS_INTEGER)
IS

      lc_errbuf         VARCHAR2(4000);
      lc_err_code       VARCHAR2(1000);

      ln_loop_indx      PLS_INTEGER;
      ln_priority       PLS_INTEGER      := 0;

BEGIN

      x_index := 0;

      IF ( gt_store_item_table.COUNT = 0 ) THEN

         RETURN;

      END IF;

      FOR ln_loop_indx IN 0 .. gt_store_item_table.COUNT-1
      LOOP

         ln_priority := gt_store_item_table(ln_loop_indx).priority;

         IF ( ln_priority = p_priority ) THEN

             x_index := gt_store_item_table(ln_loop_indx).rec_index + 1;

             EXIT;

         ELSIF ( p_priority < ln_priority ) THEN

             x_index := gt_store_item_table(ln_loop_indx).rec_index;

             EXIT;

         ELSIF ( p_priority > ln_priority )  THEN

             x_index := gt_store_item_table(ln_loop_indx).rec_index + 1;

         END IF;

      END LOOP;

EXCEPTION
    WHEN VALUE_ERROR THEN

      x_index:=0;

    WHEN OTHERS THEN

      x_index:=0;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR3';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'DELIVERY_ID'
                       ,p_entity_ref_id     => gn_delivery_id
           );

END Get_Index;

    -- +===================================================================+
    -- | Name  : Ins_Record                                                |
    -- | Description:       This Procedure will be used to insert a record |
    -- |                    in the PL/SQL table                            |
    -- |                                                                   |
    -- | Parameters:        Index                                          |
    -- |                    Item_Rec                                       |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Ins_Record ( p_index    IN PLS_INTEGER
                          ,p_item_rec IN insert_item_type)
IS

      lc_message        VARCHAR2(4000):=NULL;
      lc_errbuf         VARCHAR2(4000);
      lc_err_code       VARCHAR2(1000);

      ln_loop_indx      PLS_INTEGER;
      ln_dup            PLS_INTEGER;

BEGIN

      --
      -- Checking for duplicate item
      --

      IF ( gt_store_item_table.COUNT > 0 ) THEN

          FOR ln_dup IN gt_store_item_table.FIRST..gt_store_item_table.LAST
          LOOP

             IF gt_store_item_table(ln_dup).insert_item_id = p_item_rec.insert_item_id THEN

                RETURN;

             END IF;

          END LOOP;

      END IF;

      --
      -- Inserting a Record at the given Index
      --

      IF ( p_index < gt_store_item_table.COUNT ) THEN

        FOR ln_loop_indx IN REVERSE p_index..gt_store_item_table.COUNT-1
        LOOP

           gt_store_item_table(ln_loop_indx+1).rec_index      := gt_store_item_table(ln_loop_indx).rec_index + 1;
           gt_store_item_table(ln_loop_indx+1).insert_item_id := gt_store_item_table(ln_loop_indx).insert_item_id;
           gt_store_item_table(ln_loop_indx+1).insert_qty := gt_store_item_table(ln_loop_indx).insert_qty;
           gt_store_item_table(ln_loop_indx+1).priority       := gt_store_item_table(ln_loop_indx).priority;
           gt_store_item_table(ln_loop_indx+1).status_flag    := gt_store_item_table(ln_loop_indx).status_flag;
           gt_store_item_table(ln_loop_indx+1).pip_campaign_id := gt_store_item_table(ln_loop_indx).pip_campaign_id;

        END LOOP;

      END IF;

      gt_store_item_table(p_index).rec_index      := p_index;
      gt_store_item_table(p_index).insert_item_id := p_item_rec.insert_item_id;
      gt_store_item_table(p_index).insert_qty := p_item_rec.insert_qty;
      gt_store_item_table(p_index).priority       := p_item_rec.priority;
      gt_store_item_table(p_index).status_flag    := p_item_rec.status_flag;
      gt_store_item_table(p_index).pip_campaign_id := p_item_rec.pip_campaign_id;

EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR4';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'DELIVERY_ID'
                       ,p_entity_ref_id     => gn_delivery_id
                      );

END Ins_Record;

    -- +===================================================================+
    -- | Name  : Del_Record                                                |
    -- | Description:       This Procedure will be used to delete a record |
    -- |                    in the PL/SQL table                            |
    -- |                                                                   |
    -- | Parameters:        Index                                          |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Del_Record ( p_index IN PLS_INTEGER )
IS

      lc_errbuf           VARCHAR2(4000);
      lc_err_code         VARCHAR2(1000);

      ln_loop_indx        PLS_INTEGER;

BEGIN


      -- MC 22-Aug-2007 corrected loop max value
      FOR ln_loop_indx IN p_index .. gt_store_item_table.LAST-1
      LOOP

         gt_store_item_table(ln_loop_indx).rec_index       := gt_store_item_table(ln_loop_indx+1).rec_index - 1;
         gt_store_item_table(ln_loop_indx).insert_item_id  := gt_store_item_table(ln_loop_indx+1).insert_item_id;
         gt_store_item_table(ln_loop_indx).insert_qty  := gt_store_item_table(ln_loop_indx+1).insert_qty;
         gt_store_item_table(ln_loop_indx).priority        := gt_store_item_table(ln_loop_indx+1).priority;
         gt_store_item_table(ln_loop_indx).status_flag     := gt_store_item_table(ln_loop_indx+1).status_flag;
         gt_store_item_table(ln_loop_indx).pip_campaign_id := gt_store_item_table(ln_loop_indx+1).pip_campaign_id;

      END LOOP;

      -- MC 22-Aug-2007 changed value to delete
      gt_store_item_table.DELETE(gt_store_item_table.LAST);

EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR5';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'DELIVERY_ID'
                       ,p_entity_ref_id     => gn_delivery_id
                      );
END Del_Record;

    -- +===================================================================+
    -- | Name  : Del_Excess_Pip_Items                                      |
    -- | Description:       This Procedure will delete excess PIP items    |
    -- |                    from the PL/SQL table                          |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Del_Excess_Pip_Items
IS

      lc_errbuf               VARCHAR2(4000);
      lc_err_code             VARCHAR2(1000);

      ln_ind                  NUMBER;
      ln_indx                 NUMBER;
      ln_incompatible_item_id NUMBER;
      ln_next                 NUMBER;

      lt_store_item_table    insert_item_table;
      -- MC 22-Aug-2007  added table to store incompatible items
      lt_inc_item_tbl        insert_item_table;

      CURSOR lcu_incompatible_item(p_item_id NUMBER)
      IS
      SELECT XOPI.incompatible_item_id
      FROM   xx_om_pip_incompatibility   XOPI
      WHERE  XOPI.insert_item_id       = p_item_id
      AND    XOPI.active_flag          = 'Y';

BEGIN

      FOR ln_indx IN gt_store_item_table.FIRST .. gt_store_item_table.LAST
      LOOP

         ln_incompatible_item_id := 0;

         FOR incompatible_item_rec IN lcu_incompatible_item( p_item_id => gt_store_item_table(ln_indx).insert_item_id )
         LOOP

            ln_incompatible_item_id := incompatible_item_rec.incompatible_item_id;

         END LOOP;

         IF (ln_incompatible_item_id <> 0) THEN

            FOR ln_ind IN gt_store_item_table.FIRST .. gt_store_item_table.LAST
            LOOP

               IF ( ln_ind <> ln_indx ) THEN

                  IF ( ln_incompatible_item_id = gt_store_item_table(ln_ind).insert_item_id ) THEN

                      -- MC 22-Aug-2007 push item into list and remove after otherwise table count is wrong
                      ln_next := lt_inc_item_tbl.LAST+1;
                      lt_inc_item_tbl(ln_next).insert_item_id := ln_incompatible_item_id;

                  END IF;

               END IF;

            END LOOP;

         END IF;

      END LOOP;

      -- MC 22-Aug-2007 added loop to remove incompatible items
      IF lt_inc_item_tbl.count > 0 THEN
        FOR ln_ind IN lt_inc_item_tbl.FIRST ..lt_inc_item_tbl.LAST
        LOOP
            FOR ln_indx IN gt_store_item_table.FIRST..gt_store_item_table.LAST
            LOOP
                IF lt_inc_item_tbl(ln_ind).insert_item_id = 
                    gt_store_item_table(ln_indx).insert_item_id THEN
                    
                    Del_Record(ln_indx);
                    EXIT;
                END IF;
            END LOOP;
        END LOOP;
      END IF;


EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR6';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'DELIVERY_ID'
                       ,p_entity_ref_id     => gn_delivery_id
                      );

END Del_Excess_Pip_Items;

    -- +===================================================================+
    -- | Name  : Add_Freebiz_Order_Line                                    |
    -- | Description: This procedure will be used to add the free biz      |
    -- |              item to the existing order                           |
    -- |                                                                   |
    -- | Parameters: Order_Lines_Tbl                                       |
    -- |             camp_id_tbl                                           |
    -- |                                                                   |
    -- | Returns :   Delivery_Detail_Id                                    |
    -- |             Ord_Validate_Flag                                     |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Add_Freebiz_Order_Line(
                                 p_order_lines_tbl      IN  oe_order_pub.line_tbl_type
                                ,p_camp_id_tbl          IN  camp_id_tbl_type
                                ,x_delivery_detail_id   OUT NOCOPY wsh_delivery_details_pub.id_tab_type
                                ,x_ord_validate_flag    OUT NOCOPY VARCHAR2
                                )
AS

    lc_return_status                VARCHAR2(1000)                              := NULL;
    ln_msg_count                    PLS_INTEGER                                      := 0;
    lc_msg_data                     VARCHAR2(4000)                              := NULL;
    ln_api_version_number           PLS_INTEGER                                      := 1.0;
    lc_init_msg_list                VARCHAR2(10)                                := FND_API.G_FALSE;
    lc_return_values                VARCHAR2(10)                                := FND_API.G_FALSE;
    lc_action_commit                VARCHAR2(10)                                := FND_API.G_FALSE;
    lr_header_rec                   oe_order_pub.header_rec_type                := oe_order_pub.g_miss_header_rec;
    lr_old_header_rec               oe_order_pub.header_rec_type                := oe_order_pub.g_miss_header_rec;
    lr_header_val_rec               oe_order_pub.header_val_rec_type            := oe_order_pub.g_miss_header_val_rec;
    lr_old_header_val_rec           oe_order_pub.header_val_rec_type            := oe_order_pub.g_miss_header_val_rec;
    lt_header_adj_tbl               oe_order_pub.header_adj_tbl_type            := oe_order_pub.g_miss_header_adj_tbl;
    lt_old_header_adj_tbl           oe_order_pub.header_adj_tbl_type            := oe_order_pub.g_miss_header_adj_tbl;
    lt_header_adj_val_tbl           oe_order_pub.header_adj_val_tbl_type        := oe_order_pub.g_miss_header_adj_val_tbl;
    lt_old_header_adj_val_tbl       oe_order_pub.header_adj_val_tbl_type        := oe_order_pub.g_miss_header_adj_val_tbl;
    lt_header_price_att_tbl         oe_order_pub.header_price_att_tbl_type      := oe_order_pub.g_miss_header_price_att_tbl;
    lt_old_header_price_att_tbl     oe_order_pub.header_price_att_tbl_type      := oe_order_pub.g_miss_header_price_att_tbl;
    lt_header_adj_att_tbl           oe_order_pub.header_adj_att_tbl_type        := oe_order_pub.g_miss_header_adj_att_tbl;
    lt_old_header_adj_att_tbl       oe_order_pub.header_adj_att_tbl_type        := oe_order_pub.g_miss_header_adj_att_tbl;
    lt_header_adj_assoc_tbl         oe_order_pub.header_adj_assoc_tbl_type      := oe_order_pub.g_miss_header_adj_assoc_tbl;
    lt_old_header_adj_assoc_tbl     oe_order_pub.header_adj_assoc_tbl_type      := oe_order_pub.g_miss_header_adj_assoc_tbl;
    lt_header_scredit_tbl           oe_order_pub.header_scredit_tbl_type        := oe_order_pub.g_miss_header_scredit_tbl;
    lt_old_header_scredit_tbl       oe_order_pub.header_scredit_tbl_type        := oe_order_pub.g_miss_header_scredit_tbl;
    lt_header_scredit_val_tbl       oe_order_pub.header_scredit_val_tbl_type    := oe_order_pub.g_miss_header_scredit_val_tbl;
    lt_old_header_scredit_val_tbl   oe_order_pub.header_scredit_val_tbl_type    := oe_order_pub.g_miss_header_scredit_val_tbl;
    lt_line_tbl                     oe_order_pub.line_tbl_type                  := oe_order_pub.g_miss_line_tbl;
    lt_old_line_tbl                 oe_order_pub.line_tbl_type                  := oe_order_pub.g_miss_line_tbl;
    lt_result_line_tbl              oe_order_pub.line_tbl_type                  := oe_order_pub.g_miss_line_tbl;
    lt_line_val_tbl                 oe_order_pub.line_val_tbl_type              := oe_order_pub.g_miss_line_val_tbl;
    lt_old_line_val_tbl             oe_order_pub.line_val_tbl_type              := oe_order_pub.g_miss_line_val_tbl;
    lt_line_adj_tbl                 oe_order_pub.line_adj_tbl_type              := oe_order_pub.g_miss_line_adj_tbl;
    lt_old_line_adj_tbl             oe_order_pub.line_adj_tbl_type              := oe_order_pub.g_miss_line_adj_tbl;
    lt_line_adj_val_tbl             oe_order_pub.line_adj_val_tbl_type          := oe_order_pub.g_miss_line_adj_val_tbl;
    lt_old_line_adj_val_tbl         oe_order_pub.line_adj_val_tbl_type          := oe_order_pub.g_miss_line_adj_val_tbl;
    lt_line_price_att_tbl           oe_order_pub.line_price_att_tbl_type        := oe_order_pub.g_miss_line_price_att_tbl;
    lt_old_line_price_att_tbl       oe_order_pub.line_price_att_tbl_type        := oe_order_pub.g_miss_line_price_att_tbl;
    lt_line_adj_att_tbl             oe_order_pub.line_adj_att_tbl_type          := oe_order_pub.g_miss_line_adj_att_tbl;
    lt_old_line_adj_att_tbl         oe_order_pub.line_adj_att_tbl_type          := oe_order_pub.g_miss_line_adj_att_tbl;
    lt_line_adj_assoc_tbl           oe_order_pub.line_adj_assoc_tbl_type        := oe_order_pub.g_miss_line_adj_assoc_tbl;
    lt_old_line_adj_assoc_tbl       oe_order_pub.line_adj_assoc_tbl_type        := oe_order_pub.g_miss_line_adj_assoc_tbl;
    lt_line_scredit_tbl             oe_order_pub.line_scredit_tbl_type          := oe_order_pub.g_miss_line_scredit_tbl;
    lt_old_line_scredit_tbl         oe_order_pub.line_scredit_tbl_type          := oe_order_pub.g_miss_line_scredit_tbl;
    lt_line_scredit_val_tbl         oe_order_pub.line_scredit_val_tbl_type      := oe_order_pub.g_miss_line_scredit_val_tbl;
    lt_old_line_scredit_val_tbl     oe_order_pub.line_scredit_val_tbl_type      := oe_order_pub.g_miss_line_scredit_val_tbl;
    lt_lot_serial_tbl               oe_order_pub.lot_serial_tbl_type            := oe_order_pub.g_miss_lot_serial_tbl;
    lt_old_lot_serial_tbl           oe_order_pub.lot_serial_tbl_type            := oe_order_pub.g_miss_lot_serial_tbl;
    lt_lot_serial_val_tbl           oe_order_pub.lot_serial_val_tbl_type        := oe_order_pub.g_miss_lot_serial_val_tbl;
    lt_old_lot_serial_val_tbl       oe_order_pub.lot_serial_val_tbl_type        := oe_order_pub.g_miss_lot_serial_val_tbl;
    lt_action_request_tbl           oe_order_pub.request_tbl_type               := oe_order_pub.g_miss_request_tbl;
    lt_header_payment_tbl           oe_order_pub.header_payment_tbl_type        := oe_order_pub.g_miss_header_payment_tbl;
    lt_old_header_payment_tbl       oe_order_pub.header_payment_tbl_type;
    lt_header_payment_val_tbl       oe_order_pub.header_payment_val_tbl_type;
    lt_old_header_payment_val_tbl   oe_order_pub.header_payment_val_tbl_type;
    lt_line_payment_tbl             oe_order_pub.line_payment_tbl_type;
    lt_old_line_payment_tbl         oe_order_pub.line_payment_tbl_type;
    lt_line_payment_val_tbl         oe_order_pub.line_payment_val_tbl_type;
    lt_old_line_payment_val_tbl     oe_order_pub.line_payment_val_tbl_type;

    lc_errbuf                       VARCHAR2(4000);
    lc_err_code                     VARCHAR2(1000);

    ln_count                        PLS_INTEGER;
    
    lt_line_attr                XX_OM_LINE_ATTRIBUTES_T;
    ln_line_id                  xx_om_line_attributes_all.line_id%TYPE := NULL;
    lc_licence_address          xx_om_line_attributes_all.licence_address%TYPE := NULL;
    lc_vendor_config_id         xx_om_line_attributes_all.vendor_config_id%TYPE := NULL;
    lc_fulfillment_type         xx_om_line_attributes_all.fulfillment_type%TYPE := NULL;
    lc_line_type                xx_om_line_attributes_all.line_type%TYPE := NULL;
    lc_line_modifier            xx_om_line_attributes_all.line_modifier%TYPE := NULL;
    lc_release_num              xx_om_line_attributes_all.release_num%TYPE := NULL;
    lc_cost_center_dept         xx_om_line_attributes_all.cost_center_dept%TYPE := NULL;
    lc_desktop_del_addr         xx_om_line_attributes_all.desktop_del_addr%TYPE := NULL;
    lc_vendor_site_id           xx_om_line_attributes_all.vendor_site_id%TYPE := NULL;
    lc_pos_trx_num              xx_om_line_attributes_all.pos_trx_num%TYPE := NULL;
    lc_one_time_deal            xx_om_line_attributes_all.one_time_deal%TYPE := NULL;
    lc_trans_line_status        xx_om_line_attributes_all.trans_line_status%TYPE := NULL;
    ln_cust_price               xx_om_line_attributes_all.cust_price%TYPE := NULL;
    lc_cust_uom                 xx_om_line_attributes_all.cust_uom%TYPE := NULL;
    lc_cust_comments            xx_om_line_attributes_all.cust_comments%TYPE := NULL;
    lc_pip_campaign_id          xx_om_line_attributes_all.pip_campaign_id%TYPE := NULL;
    ln_ext_top_model_line_id    xx_om_line_attributes_all.ext_top_model_line_id%TYPE := NULL;
    ln_ext_link_to_line_id      xx_om_line_attributes_all.ext_link_to_line_id%TYPE := NULL;
    lc_config_code              xx_om_line_attributes_all.config_code%TYPE := NULL;
    lc_gift_message             xx_om_line_attributes_all.gift_message%TYPE := NULL;
    lc_gift_email               xx_om_line_attributes_all.gift_email%TYPE := NULL;
    lc_return_rga_number        xx_om_line_attributes_all.return_rga_number%TYPE := NULL;
    ld_delivery_date_from       xx_om_line_attributes_all.delivery_date_from%TYPE := NULL;
    ld_delivery_date_to         xx_om_line_attributes_all.delivery_date_to%TYPE := NULL;
    lc_wholesaler_fac_cd        xx_om_line_attributes_all.wholesaler_fac_cd%TYPE := NULL;
    lc_wholesaler_acct_num      xx_om_line_attributes_all.wholesaler_acct_num%TYPE := NULL;
    lc_return_act_cat_code      xx_om_line_attributes_all.return_act_cat_code%TYPE := NULL;
    lc_po_del_details           xx_om_line_attributes_all.po_del_details%TYPE := NULL;
    ln_ret_ref_header_id        xx_om_line_attributes_all.ret_ref_header_id%TYPE := NULL;
    ln_ret_ref_line_id          xx_om_line_attributes_all.ret_ref_line_id%TYPE := NULL;
    lc_ship_to_flag             xx_om_line_attributes_all.ship_to_flag%TYPE := NULL;            
    lc_item_note                xx_om_line_attributes_all.item_note%TYPE := NULL;               
    lc_special_desc             xx_om_line_attributes_all.special_desc%TYPE := NULL;            
    lc_non_cd_line_type         xx_om_line_attributes_all.non_cd_line_type%TYPE := NULL;        
    lc_supplier_type            xx_om_line_attributes_all.supplier_type%TYPE := NULL;           
    lc_vendor_product_code      xx_om_line_attributes_all.vendor_product_code%TYPE := NULL;     
    lc_contract_details         xx_om_line_attributes_all.contract_details%TYPE := NULL;        
    lc_aops_orig_order_num      xx_om_line_attributes_all.aops_orig_order_num%TYPE := NULL;     
    ld_aops_orig_order_date     xx_om_line_attributes_all.aops_orig_order_date%TYPE := NULL;    
    lc_item_comments            xx_om_line_attributes_all.item_comments%TYPE := NULL;           
    ln_backordered_qty          xx_om_line_attributes_all.backordered_qty%TYPE := NULL;         
    lc_taxable_flag             xx_om_line_attributes_all.taxable_flag%TYPE := NULL;            
    ln_waca_parent_id           xx_om_line_attributes_all.waca_parent_id%TYPE := NULL;          
    ln_aops_orig_order_line_num xx_om_line_attributes_all.aops_orig_order_line_num%TYPE := NULL;
    lc_sku_dept                 xx_om_line_attributes_all.sku_dept%TYPE := NULL;                
    lc_item_source              xx_om_line_attributes_all.item_source%TYPE := NULL;             
    ln_average_cost             xx_om_line_attributes_all.average_cost%TYPE := NULL;            
    ln_canada_pst_tax           xx_om_line_attributes_all.canada_pst_tax%TYPE := NULL;          
    ln_po_cost                  xx_om_line_attributes_all.po_cost%TYPE := NULL;                 
    lc_waca_status              xx_om_line_attributes_all.waca_status%TYPE := NULL;
    lc_resourcing_flag          xx_om_line_attributes_all.resourcing_flag%TYPE := NULL;
    lc_cust_item_number         xx_om_line_attributes_all.cust_item_number%TYPE := NULL;        
    ld_pod_date                 xx_om_line_attributes_all.pod_date%TYPE := NULL;           
    ln_return_auth_id           xx_om_line_attributes_all.return_auth_id%TYPE := NULL;          
    lc_return_code              xx_om_line_attributes_all.return_code%TYPE := NULL;             
    ln_sku_list_price           xx_om_line_attributes_all.sku_list_price%TYPE := NULL;          
    lc_waca_item_ctr_num        xx_om_line_attributes_all.waca_item_ctr_num%TYPE := NULL;       
    ld_new_schedule_ship_date   xx_om_line_attributes_all.new_schedule_ship_date%TYPE := NULL ; 
    ld_new_schedule_arr_date    xx_om_line_attributes_all.new_schedule_arr_date%TYPE := NULL;   
    ln_taylor_unit_price        xx_om_line_attributes_all.taylor_unit_price%TYPE := NULL;       
    ln_taylor_unit_cost         xx_om_line_attributes_all.taylor_Unit_cost%TYPE := NULL;        
    ln_xdock_inv_org_id         xx_om_line_attributes_all.xdock_inv_org_id%TYPE := NULL;         
    lc_payment_subtype_cod_ind  xx_om_line_attributes_all.payment_subtype_cod_ind%TYPE := NULL; 
    lc_del_to_post_office_ind   xx_om_line_attributes_all.del_to_post_office_ind%TYPE := NULL;  
    lc_wholesaler_item          xx_om_line_attributes_all.wholesaler_item%TYPE := NULL;         
    lc_cust_comm_pref           xx_om_line_attributes_all.cust_comm_pref%TYPE := NULL;          
    lc_cust_pref_email          xx_om_line_attributes_all.cust_pref_email%TYPE := NULL;         
    lc_cust_pref_fax            xx_om_line_attributes_all.cust_pref_fax%TYPE := NULL;         
    lc_cust_pref_phone          xx_om_line_attributes_all.cust_pref_phone%TYPE := NULL;         
    lc_cust_pref_phextn         xx_om_line_attributes_all.cust_pref_phextn%TYPE := NULL;        
    ln_freight_line_id          xx_om_line_attributes_all.freight_line_id%TYPE := NULL;         
    ln_freight_primary_line_id  xx_om_line_attributes_all.freight_primary_line_id%TYPE := NULL; 
    ld_creation_date            xx_om_line_attributes_all.creation_date%TYPE := NULL;           
    lc_created_by               xx_om_line_attributes_all.created_by%TYPE := NULL;              
    ld_last_update_date         xx_om_line_attributes_all.last_update_date%TYPE := NULL;        
    ln_last_updated_by          xx_om_line_attributes_all.last_updated_by%TYPE := NULL;         
    ln_last_update_login        xx_om_line_attributes_all.last_update_login%TYPE := NULL;       

    -- MC 22-Aug-2007 added exception for error from line insert
    XX_OM_PIP_OE_INSERT_FAIL       EXCEPTION;
    XX_OM_ATTR_INSERT_FAIL         EXCEPTION;

      --
      --Cursor to get the delivery detail id
      --
    CURSOR lcu_delivery_details(p_source_line_id NUMBER)
    IS
    SELECT delivery_detail_id
    FROM   wsh_delivery_details
    WHERE  source_line_id = p_source_line_id;

BEGIN

    -- instantiate the object to insert into the extension table
    lt_line_attr := XX_OM_LINE_ATTRIBUTES_T (ln_line_id                    
                                            ,lc_licence_address             
                                            ,lc_vendor_config_id            
                                            ,lc_fulfillment_type            
                                            ,lc_line_type                   
                                            ,lc_line_modifier               
                                            ,lc_release_num                 
                                            ,lc_cost_center_dept            
                                            ,lc_desktop_del_addr        
                                            ,lc_vendor_site_id                       
                                            ,lc_pos_trx_num                 
                                            ,lc_one_time_deal               
                                            ,lc_trans_line_status           
                                            ,ln_cust_price                  
                                            ,lc_cust_uom                    
                                            ,lc_cust_comments               
                                            ,lc_pip_campaign_id             
                                            ,ln_ext_top_model_line_id       
                                            ,ln_ext_link_to_line_id         
                                            ,lc_config_code                 
                                            ,lc_gift_message                
                                            ,lc_gift_email                  
                                            ,lc_return_rga_number           
                                            ,ld_delivery_date_from          
                                            ,ld_delivery_date_to            
                                            ,lc_wholesaler_fac_cd           
                                            ,lc_wholesaler_acct_num         
                                            ,lc_return_act_cat_code         
                                            ,lc_po_del_details              
                                            ,ln_ret_ref_header_id         
                                            ,ln_ret_ref_line_id           
                                            ,lc_ship_to_flag                
                                            ,lc_item_note                   
                                            ,lc_special_desc                
                                            ,lc_non_cd_line_type            
                                            ,lc_supplier_type               
                                            ,lc_vendor_product_code         
                                            ,lc_contract_details            
                                            ,lc_aops_orig_order_num         
                                            ,ld_aops_orig_order_date        
                                            ,lc_item_comments               
                                            ,ln_backordered_qty             
                                            ,lc_taxable_flag                
                                            ,ln_waca_parent_id              
                                            ,ln_aops_orig_order_line_num    
                                            ,lc_sku_dept                    
                                            ,lc_item_source                 
                                            ,ln_average_cost                
                                            ,ln_canada_pst_tax              
                                            ,ln_po_cost                     
                                            ,lc_resourcing_flag            
                                            ,lc_waca_status                 
                                            ,lc_cust_item_number            
                                            ,ld_pod_date                    
                                            ,ln_return_auth_id              
                                            ,lc_return_code                 
                                            ,ln_sku_list_price              
                                            ,lc_waca_item_ctr_num           
                                            ,ld_new_schedule_ship_date      
                                            ,ld_new_schedule_arr_date       
                                            ,ln_taylor_unit_price           
                                            ,ln_taylor_unit_cost            
                                            ,ln_xdock_inv_org_id            
                                            ,lc_payment_subtype_cod_ind     
                                            ,lc_del_to_post_office_ind      
                                            ,lc_wholesaler_item             
                                            ,lc_cust_comm_pref              
                                            ,lc_cust_pref_email             
                                            ,lc_cust_pref_fax               
                                            ,lc_cust_pref_phone             
                                            ,lc_cust_pref_phextn            
                                            ,ln_freight_line_id             
                                            ,ln_freight_primary_line_id  
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,FND_GLOBAL.USER_ID
                                            );

    -- call OE API to create the order lines for the PIP items
    oe_order_pub.process_order (
                                    p_api_version_number           => ln_api_version_number
                                   ,p_init_msg_list                => lc_init_msg_list
                                   ,p_return_values                => lc_return_values
                                   ,p_action_commit                => lc_action_commit
                                   ,x_return_status                => lc_return_status
                                   ,x_msg_count                    => ln_msg_count
                                   ,x_msg_data                     => lc_msg_data
                                   ,p_header_rec                   => lr_header_rec
                                   ,p_old_header_rec               => lr_old_header_rec
                                   ,p_header_val_rec               => lr_header_val_rec
                                   ,p_old_header_val_rec           => lr_old_header_val_rec
                                   ,p_Header_Adj_tbl               => lt_Header_Adj_tbl
                                   ,p_old_Header_Adj_tbl           => lt_old_Header_Adj_tbl
                                   ,p_Header_Adj_val_tbl           => lt_Header_Adj_val_tbl
                                   ,p_old_Header_Adj_val_tbl       => lt_old_Header_Adj_val_tbl
                                   ,p_Header_price_Att_tbl         => lt_Header_price_Att_tbl
                                   ,p_old_Header_Price_Att_tbl     => lt_old_Header_Price_Att_tbl
                                   ,p_Header_Adj_Att_tbl           => lt_Header_Adj_Att_tbl
                                   ,p_old_Header_Adj_Att_tbl       => lt_old_Header_Adj_Att_tbl
                                   ,p_Header_Adj_Assoc_tbl         => lt_Header_Adj_Assoc_tbl
                                   ,p_old_Header_Adj_Assoc_tbl     => lt_old_Header_Adj_Assoc_tbl
                                   ,p_Header_Scredit_tbl           => lt_Header_Scredit_tbl
                                   ,p_old_Header_Scredit_tbl       => lt_old_Header_Scredit_tbl
                                   ,p_Header_Scredit_val_tbl       => lt_Header_Scredit_val_tbl
                                   ,p_old_Header_Scredit_val_tbl   => lt_old_Header_Scredit_val_tbl
                                   ,p_Header_Payment_tbl           => lt_Header_Payment_tbl
                                   ,p_old_Header_Payment_tbl       => lt_old_Header_Payment_tbl
                                   ,p_Header_Payment_val_tbl       => lt_Header_Payment_val_tbl
                                   ,p_old_Header_Payment_val_tbl   => lt_old_Header_Payment_val_tbl
                                   ,p_line_tbl                     => p_order_lines_tbl
                                   ,p_old_line_tbl                 => lt_old_line_tbl
                                   ,p_line_val_tbl                 => lt_line_val_tbl
                                   ,p_old_line_val_tbl             => lt_old_line_val_tbl
                                   ,p_Line_Adj_tbl                 => lt_Line_Adj_tbl
                                   ,p_old_Line_Adj_tbl             => lt_old_Line_Adj_tbl
                                   ,p_Line_Adj_val_tbl             => lt_Line_Adj_val_tbl
                                   ,p_old_Line_Adj_val_tbl         => lt_old_Line_Adj_val_tbl
                                   ,p_Line_price_Att_tbl           => lt_Line_price_Att_tbl
                                   ,p_old_Line_Price_Att_tbl       => lt_old_Line_Price_Att_tbl
                                   ,p_Line_Adj_Att_tbl             => lt_Line_Adj_Att_tbl
                                   ,p_old_Line_Adj_Att_tbl         => lt_old_Line_Adj_Att_tbl
                                   ,p_Line_Adj_Assoc_tbl           => lt_Line_Adj_Assoc_tbl
                                   ,p_old_Line_Adj_Assoc_tbl       => lt_old_Line_Adj_Assoc_tbl
                                   ,p_Line_Scredit_tbl             => lt_Line_Scredit_tbl
                                   ,p_old_Line_Scredit_tbl         => lt_old_Line_Scredit_tbl
                                   ,p_Line_Scredit_val_tbl         => lt_Line_Scredit_val_tbl
                                   ,p_old_Line_Scredit_val_tbl     => lt_old_Line_Scredit_val_tbl
                                   ,p_Line_Payment_tbl             => lt_Line_Payment_tbl
                                   ,p_old_Line_Payment_tbl         => lt_old_Line_Payment_tbl
                                   ,p_Line_Payment_val_tbl         => lt_Line_Payment_val_tbl
                                   ,p_old_Line_Payment_val_tbl     => lt_old_Line_Payment_val_tbl
                                   ,p_Lot_Serial_tbl               => lt_Lot_Serial_tbl
                                   ,p_old_Lot_Serial_tbl           => lt_old_Lot_Serial_tbl
                                   ,p_Lot_Serial_val_tbl           => lt_Lot_Serial_val_tbl
                                   ,p_old_Lot_Serial_val_tbl       => lt_old_Lot_Serial_val_tbl
                                   ,p_action_request_tbl           => lt_action_request_tbl
                                   ,x_header_rec                   => lr_header_rec
                                   ,x_header_val_rec               => lr_header_val_rec
                                   ,x_Header_Adj_tbl               => lt_Header_Adj_tbl
                                   ,x_Header_Adj_val_tbl           => lt_Header_Adj_val_tbl
                                   ,x_Header_price_Att_tbl         => lt_Header_price_Att_tbl
                                   ,x_Header_Adj_Att_tbl           => lt_Header_Adj_Att_tbl
                                   ,x_Header_Adj_Assoc_tbl         => lt_Header_Adj_Assoc_tbl
                                   ,x_Header_Scredit_tbl           => lt_Header_Scredit_tbl
                                   ,x_Header_Scredit_val_tbl       => lt_Header_Scredit_val_tbl
                                   ,x_Header_Payment_tbl           => lt_Header_Payment_tbl
                                   ,x_Header_Payment_val_tbl       => lt_Header_Payment_val_tbl
                                   ,x_line_tbl                     => lt_result_line_tbl
                                   ,x_line_val_tbl                 => lt_line_val_tbl
                                   ,x_Line_Adj_tbl                 => lt_Line_Adj_tbl
                                   ,x_Line_Adj_val_tbl             => lt_Line_Adj_val_tbl
                                   ,x_Line_price_Att_tbl           => lt_Line_price_Att_tbl
                                   ,x_Line_Adj_Att_tbl             => lt_Line_Adj_Att_tbl
                                   ,x_Line_Adj_Assoc_tbl           => lt_Line_Adj_Assoc_tbl
                                   ,x_Line_Scredit_tbl             => lt_Line_Scredit_tbl
                                   ,x_Line_Scredit_val_tbl         => lt_Line_Scredit_val_tbl
                                   ,x_Line_Payment_tbl             => lt_Line_Payment_tbl
                                   ,x_Line_Payment_val_tbl         => lt_Line_Payment_val_tbl
                                   ,x_Lot_Serial_tbl               => lt_Lot_Serial_tbl
                                   ,x_Lot_Serial_val_tbl           => lt_Lot_Serial_val_tbl
                                   ,x_action_request_tbl           => lt_action_request_tbl
                                   ,p_rtrim_data                   => 'N'
                                   );

    -- if there was an error returned from the API call for any of the PIP items
    -- extract the messages out of the return parm and load into the exception message
    -- raise and exception after all have been extracted
    IF lc_return_status IN (FND_API.G_RET_STS_UNEXP_ERROR, FND_API.G_RET_STS_ERROR) THEN

        FOR ln_ind IN 1..ln_msg_count LOOP

            lc_msg_data := lc_msg_data||', '||SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE),1,255);

        END LOOP;

        x_ord_validate_flag := 'N';
        RAISE XX_OM_PIP_OE_INSERT_FAIL;

    ELSE

        x_ord_validate_flag := 'Y';

    END IF;

    --
    -- Deriving the delivery_detail_id with the help of newly created line id
    --

    ln_count := 1;

    IF ( x_ord_validate_flag = 'Y' OR x_ord_validate_flag IS NULL ) AND lt_result_line_tbl.COUNT <> 0 THEN

        FOR ln_index IN lt_result_line_tbl.FIRST..lt_result_line_tbl.LAST
        LOOP

            FOR lr_delivery_details IN lcu_delivery_details( lt_result_line_tbl(ln_index).line_id )
            LOOP

                x_delivery_detail_id(ln_count) := lr_delivery_details.delivery_detail_id;

                ln_count := ln_count + 1;

            END LOOP;
            
            -- the result table will have a row for each line that was sent. 
            -- As we loop through the results write the extension row for each line
            -- the only details we need to write will be the line_id and campaign id
            lt_line_attr.line_id := lt_result_line_tbl(ln_index).line_id;
            lt_line_attr.pip_campaign_id := p_camp_id_tbl(ln_index).pip_campaign_id;
            
            xx_om_line_attributes_pkg.insert_row(
                     p_line_rec         => lt_line_attr
                    ,x_return_status    => lc_return_status
                    ,x_errbuf           => lc_errbuf);
                    
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                x_ord_validate_flag := 'N';
                RAISE XX_OM_ATTR_INSERT_FAIL;
            END IF;
            
        END LOOP;

    END IF;

    -- The commit will be done once the delivery details have been updated. If the commit
    -- was done at this point and the delivery updated was not successful we would be left 
    -- with a delivery for a PIP item

EXCEPTION
    WHEN XX_OM_PIP_OE_INSERT_FAIL THEN
    
      ROLLBACK;

      lc_errbuf    := lc_msg_data;
      lc_err_code  := 'XX_OM_65100_UNEXPECTED_ERROR10';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );
                      
    WHEN XX_OM_ATTR_INSERT_FAIL THEN
    
        -- the api called logs the exception so this just needs the rollback
        ROLLBACK;
  
    WHEN OTHERS THEN

      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf    := FND_MESSAGE.GET;
      lc_err_code  := 'XX_OM_65100_UNEXPECTED_ERROR7';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );

END Add_Freebiz_Order_Line;

    -- +===================================================================+
    -- | Name  : Details_To_Delivery                                       |
    -- | Description: This procedure will be used to assign delivery       |
    -- |              details to the delivery                              |
    -- |                                                                   |
    -- | Parameters: Tab_Of_Del_Detail                                     |
    -- |             Delivery_Id                                           |
    -- |                                                                   |
    -- | Returns   : Del_Validate_Flag                                     |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Details_To_Delivery(
                              p_tab_of_del_detail  IN  wsh_delivery_details_pub.id_tab_type
                             ,p_del_id             IN  PLS_INTEGER DEFAULT FND_API.G_MISS_NUM
                             ,x_del_validate_flag  OUT NOCOPY VARCHAR2
                             )
IS

      lc_action           VARCHAR2(30)     := 'ASSIGN';
      lc_commit           VARCHAR2(10)     := FND_API.G_FALSE;
      lc_delivery_name    VARCHAR2(100)    := FND_API.G_MISS_CHAR;
      lc_errbuf           VARCHAR2(4000);
      lc_err_code         VARCHAR2(1000);
      lc_init_msg_list    VARCHAR2(2000)   := FND_API.G_TRUE;
      lc_msg_data         VARCHAR2(4000);
      lc_return_status    VARCHAR2(100);

      ln_delivery_id      PLS_INTEGER;
      ln_msg_count        PLS_INTEGER;
      ln_tabofdeldets     wsh_delivery_details_pub.id_tab_type;
      ln_validation_level PLS_INTEGER           := FND_API.G_VALID_LEVEL_FULL;

      -- MC 22-Aug-2007 added exception for error from line insert
      XX_OM_PIP_WSH_INSERT_FAIL       EXCEPTION;

BEGIN

       -- call the shipping API to change the PIP items assigned delivery to the 
       -- delivery that is currently being processed
       WSH_DELIVERY_DETAILS_PUB.Detail_to_Delivery(
                                                   p_api_version      => 1.0
                                                  ,p_init_msg_list    => lc_init_msg_list
                                                  ,p_commit           => lc_commit
                                                  ,p_validation_level => ln_validation_level
                                                  ,x_return_status    => lc_return_status
                                                  ,x_msg_count        => ln_msg_count
                                                  ,x_msg_data         => lc_msg_data
                                                  ,p_TabOfDelDets     => p_tab_of_del_detail
                                                  ,p_action           => lc_action
                                                  ,p_delivery_id      => p_del_id
                                                  ,p_delivery_name    => lc_delivery_name
                                                  );

      -- If an error occured in the API the messages will be extracted out an placed in the 
      -- exception message to be recorded
      IF lc_return_status IN (FND_API.G_RET_STS_UNEXP_ERROR, FND_API.G_RET_STS_ERROR) THEN

         FOR ln_ind IN 1..ln_msg_count LOOP

            lc_msg_data := lc_msg_data||', '||SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE),1,255);

         END LOOP;

         x_del_validate_flag := 'N';
         RAISE XX_OM_PIP_WSH_INSERT_FAIL;

      ELSE

         x_del_validate_flag := 'Y';

      END IF;


EXCEPTION
    WHEN XX_OM_PIP_WSH_INSERT_FAIL THEN
    
      ROLLBACK;

      lc_errbuf    := lc_msg_data;
      lc_err_code  := 'XX_OM_65100_UNEXPECTED_ERROR11';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );
    WHEN OTHERS THEN

      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR1';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );

END Details_To_Delivery;

    -- +===================================================================+
    -- | Name  : Validate_PIP_Items                                        |
    -- | Description : Procedure to validate the PIP Campaigns for a given |
    -- |               order                                               |
    -- |                                                                   |
    -- | Parameters :       Rule detail Start index                        |
    -- |                    Rule detail end index                          |
    -- |                    Rule Type                                      |
    -- |                    Varchar validation value                       |
    -- |                    Number validation value                        |
    -- |                                                                   |
    -- | Returns:           Validation_Flag                                |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Validate_PIP_Items(
                             p_start            IN  PLS_INTEGER 
                            ,p_end              IN  PLS_INTEGER 
                            ,p_rule_type        IN  VARCHAR2
                            ,p_char_value       IN  VARCHAR2
                            ,p_num_value        IN  NUMBER
                            ,x_validation_flag  OUT NOCOPY VARCHAR2
                            )
IS

      lc_errbuf     VARCHAR2(4000);
      lc_err_code   VARCHAR2(1000);

      ln_indx       PLS_INTEGER;
      ln_org_id     PLS_INTEGER;

BEGIN

    x_validation_flag := NULL;

    FOR ln_indx IN p_start..p_end
    LOOP
        -- Rule matches the one being checked
        IF gt_rule_dtl_tbl(ln_indx).rule_type = p_rule_type THEN
        
            --Rule is defined as an include. Each rule will be either include or 
            -- exclude and not both
            IF gt_rule_dtl_tbl(ln_indx).inc_exc_flag = 'I' THEN
            
                -- if the number value was not supplied it will be a charater comparison
                IF p_num_value IS NULL THEN

                    IF gt_rule_dtl_tbl(ln_indx).char_value = p_char_value THEN
                        x_validation_flag := 'Y';
                        RETURN;
                    ELSE
                        x_validation_flag := 'N';
                    END IF;
                -- this will be a numerical comparison
                ELSE
                    IF gt_rule_dtl_tbl(ln_indx).num_value = p_num_value THEN
                        x_validation_flag := 'Y';
                        RETURN;
                    ELSE
                        x_validation_flag := 'N';
                    END IF;
                END IF;
            -- Rule will be evaluated for exclusion
            ELSE

                -- if the number value was not supplied it will be a charater comparison
                IF p_num_value IS NULL THEN

                    IF gt_rule_dtl_tbl(ln_indx).char_value = p_char_value THEN
                        x_validation_flag := 'N';
                        RETURN;
                    ELSE
                        x_validation_flag := 'Y';
                    END IF;
                -- this will be a numerical comparison
                ELSE
                    IF gt_rule_dtl_tbl(ln_indx).num_value = p_num_value THEN
                        x_validation_flag := 'N';
                       RETURN;
                    ELSE
                        x_validation_flag := 'Y';
                    END IF;
                END IF;
            END IF;
            
        -- the rule dtl tbl is ordered so if table value is greater there is no rule defined
        ELSIF gt_rule_dtl_tbl(ln_indx).rule_type > p_rule_type THEN
            IF x_validation_flag IS NULL THEN
                x_validation_flag := 'Y';
            END IF;
            RETURN;
        END IF;
    END LOOP;

    -- if there was no detail rule defined for the rule type return success as there is no
    -- check defined
    IF x_validation_flag IS NULL THEN
        x_validation_flag := 'Y';
        RETURN;
    END IF;
    

EXCEPTION
    WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR8';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'DELIVERY_ID'
                      ,p_entity_ref_id     => gn_delivery_id
                      );

END Validate_PIP_Items;

-- +===================================================================+
-- | Name  : Determine_Pip_Items                                       |
-- | Description:       This Procedure will have different procedures  |
-- |                    functions to evaluate the rules based on the   |
-- |                    Order Attribute and come up with list of PIP   |
-- |                    items and then add the items to the Order      |
-- |                    Additional Delivery Detail Information         |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        Delivery_Id                                    |
-- |                    Batch_Mode                                     |
-- |                    Web_Url1                                       |
-- |                    Web_Url2                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Status_Flag                                    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Determine_PIP_Items(
                               p_delivery_id  IN  NUMBER
                              ,p_batch_mode   IN  VARCHAR2
                              ,p_web_url1     IN  VARCHAR2
                              ,p_web_url2     IN  VARCHAR2
                              ,p_status_flag  OUT NOCOPY VARCHAR2
                             )

IS

    lc_no_pick              VARCHAR2(100);
    lc_cust_association     VARCHAR2(10);
    lc_cust_order           hz_parties.total_num_of_orders%TYPE;
    ln_customer_type        hz_parties.attribute18%TYPE;
    ln_employees_total      hz_parties.employees_total%TYPE;
    lc_sic_code             hz_parties.sic_code%TYPE;

    ld_ordered_date         oe_order_headers.ordered_date%TYPE;
    ln_order_header_id      oe_order_headers_all.header_id%TYPE;
    ln_org_id               oe_order_headers_all.org_id%TYPE;

    ln_ship_from_org_id     oe_order_lines_all.ship_from_org_id%TYPE;

    ln_csc_count            xx_om_pip_insert_count.csc_count%TYPE;
    ln_max_csc_count        xx_om_pip_insert_count.max_csc_count%TYPE;

    lt_line_item_details    oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;

    lt_delivery_detail_id   wsh_delivery_details_pub.id_tab_type;
    lt_del_detail_id        wsh_delivery_details_pub.id_tab_type;
    
    lt_camp_id_tbl          camp_id_tbl_type;

    ln_cust_account_id      hz_cust_accounts.cust_account_id%TYPE := -1;

    lc_reward_customer      hz_org_profiles_ext_b.c_ext_attr2%TYPE;

    lc_item_dept            mtl_categories_b.segment3%TYPE;
    lc_item_class           mtl_categories_b.segment4%TYPE;

    lc_state                hz_locations.state%TYPE;
    
    lc_catalog_src_cd       xx_om_header_attributes_all.catalog_src_cd%TYPE;
    
    ln_order_amount         ord_amt_rec_type;
    lr_item_rec             insert_item_type;

    lc_del_validate_flag    VARCHAR2(10):='Y';
    lc_errbuf               VARCHAR2(4000);
    lc_err_code             VARCHAR2(1000);
    lc_insert_item1_valid   VARCHAR2(1);
    lc_insert_item2_valid   VARCHAR2(1);
    lc_null_validation      VARCHAR2(1);
    lc_ord_validate_flag    VARCHAR2(1):='Y';
    lc_validation_flag      VARCHAR2(10);
    lc_value                VARCHAR2(240);

    ln_ind                  PLS_INTEGER := 0;
    ln_indexs               PLS_INTEGER := 0;
    ln_number_of_record     PLS_INTEGER  :=  0;
    ln_onhand_qty           PLS_INTEGER;
    ln_price_list_id        PLS_INTEGER ;
    rule_count              PLS_INTEGER;
    rule_dtl_cnt            PLS_INTEGER;
    cmp_cnt                 PLS_INTEGER;
    i                       PLS_INTEGER;
    j                       PLS_INTEGER;
    ln_insert_item_limit    PLS_INTEGER;
    last_dtl_rule           PLS_INTEGER;
    ln_value                NUMBER;

    ld_freq_date            DATE;

    EX_UPDATE_FAILURE       EXCEPTION;

    -- get the header id, ship from and order date for the delivery. Limit to just one order line
    CURSOR  lcu_ship_from_org_id IS
    SELECT  
         OOHA.header_id
        ,OOLA.ship_from_org_id
        ,OOHA.ordered_date
        ,x.catalog_src_cd
        ,OOHA.org_id
    FROM    
         wsh_new_deliveries           WND
        ,wsh_delivery_assignments     WDA
        ,wsh_delivery_details         WDD
        ,oe_order_headers_all         OOHA
        ,oe_order_lines_all           OOLA
        ,xx_om_pip_item_repak         PR
        ,xx_om_header_attributes_all  x
    WHERE   
            WND.delivery_id           =  p_delivery_id
        AND WDA.delivery_id           =  WND.delivery_id
        AND WDD.delivery_detail_id    =  WDA.delivery_detail_id
        AND OOHA.header_id            =  WDD.source_header_id
        AND OOHA.header_id = x.header_id
-- OPEN ISSUE mfc no idea why shipping method is being checked
/*
        AND     OOHA.shipping_method_code =  (
                                             SELECT F.lookup_code
                                             FROM   fnd_lookup_values_vl F
                                             WHERE  lookup_type = 'SHIP_METHOD'
                                             AND    UPPER(F.lookup_code) LIKE '%DELIVERY%'
                                             AND EXISTS (
                                                         SELECT 1
                                                         FROM    wsh_carriers WC,
                                                                 wsh_carrier_services WCS
                                                         WHERE WC.carrier_id = WCS.carrier_id
                                                         AND NVL (WC.generic_flag, 'N') = 'N'
                                                         AND WCS.ship_method_code = F.lookup_code
                                                         ))*/
        AND OOLA.header_id = OOHA.header_id
        AND OOLA.line_id = WDD.source_line_id
        AND OOLA.ship_from_org_id IS NOT NULL
        AND NVL(OOLA.cancelled_flag, 'N') = 'N'
        AND OOLA.source_type_code = 'INTERNAL'
        AND PR.inventory_item_id = OOLA.inventory_item_id
        AND PR.warehouse_id = OOLA.ship_from_org_id
        AND NVL(PR.repak_flag,'N') = 'Y'
--        AND     'LOCAL DELIVERY'   = 'LOCAL DELIVERY'           --OPEN ISSUE local delivery
        AND NOT EXISTS ( 
                SELECT 1
                FROM   
                    xx_om_line_attributes_all KF
                WHERE  
                        KF.line_id= OOLA.line_id
                    AND    KF.pip_campaign_id IS NOT NULL 
                );

    -- retrieve all the lines in the order referenced by the delivery
    CURSOR  lcu_order_details( p_order_header_id  NUMBER
                              ,p_ship_from_org_id NUMBER
                             )  IS
    SELECT  
        OOLA. *
    FROM    
        oe_order_lines_all         OOLA
    WHERE   
            OOLA.header_id = p_order_header_id
        AND OOLA.ship_from_org_id = p_ship_from_org_id
        AND NVL(OOLA.cancelled_flag, 'N') = 'N'
        AND OOLA.source_type_code   = 'INTERNAL'
        AND NOT EXISTS (
                SELECT 1
                FROM   xx_om_line_attributes_all  XOLAA
                WHERE  
                        XOLAA.line_id      = OOLA.line_id
                    AND XOLAA.pip_campaign_id IS NOT NULL
                );

    -- get all of the rules that are currently active
    CURSOR  lcu_pip_rules(p_no_pick VARCHAR2, p_org_id NUMBER )IS
    SELECT  
        x.*
    FROM    
        xx_om_pip_campaign_rules_all x
    WHERE   
            NVL(x.approved_flag,'N') ='Y'
        AND NVL(x.inactive_flag,'N') = 'N' 
        AND DECODE(p_no_pick,'N','Y','Y',NVL(x.override_no_pick_flag,'N'))='Y'
        AND SYSDATE BETWEEN NVL (x.from_date,SYSDATE) AND NVL(x.to_date,SYSDATE)
        AND x.org_id = p_org_id
        AND NVL(x.approved_flag,'N') = 'Y';

    -- extract the rule details based for the associated campaign
    CURSOR  lcu_pip_rule_dtl(p_pip_campaign_id NUMBER )IS
    SELECT  
        d.*
    FROM    
        xx_om_pip_rule_details_all d
    WHERE   
        d.pip_campaign_id = p_pip_campaign_id
    ORDER BY
        d.rule_type;

    -- get all the items in the order to check if PIP item already there
    CURSOR  lcu_insert_item_id(p_item_order_header_id PLS_INTEGER) IS
    SELECT  
        OOLA.inventory_item_id
    FROM    
        oe_order_lines_all OOLA
    WHERE   
            OOLA.header_id = p_item_order_header_id
        AND NVL(OOLA.cancelled_flag, 'N') = 'N';

    -- get the state where delivery is being sent
    CURSOR lcu_state( p_sold_to_org_id NUMBER
                     ,p_ship_to_org_id NUMBER) IS
    SELECT HL.state
    FROM   
         hz_cust_accounts          HCA
        ,hz_cust_acct_sites_all    HCAS
        ,hz_cust_site_uses_all     HCSU
        ,hz_party_sites            HPS
        ,hz_locations              HL
    WHERE  
            HCA.cust_account_id     = p_sold_to_org_id
        AND HCAS.cust_account_id    = HCA.cust_account_id
        AND HCAS.cust_acct_site_id  = HCSU.cust_acct_site_id
        AND HCSU.site_use_code      = 'SHIP_TO'
        AND HCSU.site_use_id        = p_ship_to_org_id
        AND HPS.party_site_id       = HCAS.party_site_id
        AND HPS.party_id            = HCA.party_id
        AND HL.location_id          = HPS.location_id;

    -- get the item assigned dept and class
    CURSOR lcu_dept_class  ( p_item_id mtl_item_categories.inventory_item_id%TYPE
                            ,p_org_id mtl_item_categories.organization_id%TYPE) IS
    SELECT 
        MCB.segment3 dept,
        MCB.segment4 class
    FROM   
         mtl_item_categories mic
        ,mtl_default_category_sets_fk_v MDCS
        ,mtl_categories_b    MCB
    WHERE
            mic.inventory_item_id = p_item_id
        AND mic.organization_id = p_org_id
        AND UPPER(MDCS.functional_area_desc) = UPPER('Order Management')
        AND MDCS.category_set_id = mic.category_set_id
        AND MCB.category_id  = mic.category_id;

 
    -- gets the PIP insert count for the CSC
    CURSOR lcu_csc_count(p_csc_ship_from_org_id NUMBER) IS
    SELECT 
         max_csc_count
        ,csc_count
    FROM   
        xx_om_pip_insert_count
    WHERE  
        ship_from_org_id = p_csc_ship_from_org_id;

    -- counts the number of times the campaign was applied
    CURSOR lcu_count_order_lines( p_pip_campaign_id VARCHAR2
                                 ,p_from_date       DATE
                                 ,p_sold_to_org_id NUMBER) IS
    SELECT 
        COUNT(OOL.line_id)  value
    FROM   
         oe_order_lines_all         OOL
        ,xx_om_line_attributes_all XOMLAA
    WHERE  
            OOL.creation_date BETWEEN p_from_date AND SYSDATE
        AND OOL.line_id = XOMLAA.line_id
        AND XOMLAA.pip_campaign_id = p_pip_campaign_id
        AND OOL.sold_to_org_id = p_sold_to_org_id;

    -- current order then compared the month of the orders to that month
    -- locates if customer ordered this month already 
    CURSOR lcu_mon_count( p_sold_to_org_id  NUMBER
                         ,p_ordered_date DATE) IS
    SELECT 
        OOHA.header_id
    FROM   
        oe_order_headers_all OOHA
    WHERE  
            TO_CHAR(OOHA.ordered_date,'MON-YYYY') = TO_CHAR(p_ordered_date,'MON-YYYY')
        AND OOHA.header_id IN (
                SELECT OOLA.header_id
                FROM   oe_order_lines_all OOLA
                WHERE  OOLA.sold_to_org_id = p_sold_to_org_id
                )
    ORDER BY OOHA.creation_date;

    -- select the total onhand at an inv org excluding subinv where not reservable
    CURSOR lcu_onhand_quantity( p_inventory_item_id NUMBER
                               ,p_organization_id   NUMBER ) IS
    SELECT 
        SUM(mo.primary_transaction_quantity) onhand_quantity
    FROM   
         mtl_onhand_quantities_detail mo
        ,mtl_secondary_inventories ms
    WHERE  
            mo.inventory_item_id = p_inventory_item_id
        AND mo.organization_id   = p_organization_id
        AND mo.organization_id = ms.organization_id
        AND ms.reservable_type = 1;

    -- extract all the customer attributes for validation
    CURSOR lcu_cust_attributes(p_cust_account_id NUMBER) IS
    SELECT 
         c.cust_account_id
        ,'N' no_pick_list                     --OPEN ISSUE
        ,ope.c_ext_attr2 reward_customer                  
        ,NULL cust_association                 --OPEN ISSUE
        ,NVL(p.employees_total,0) employees_total
        ,c.attribute18 customer_type
        ,p.total_num_of_orders cust_order
        ,p.sic_code
    FROM   
         hz_cust_accounts c
        ,hz_parties p
        ,hz_organization_profiles op
        ,hz_org_profiles_ext_b ope
    WHERE  
            c.cust_account_id =p_cust_account_id
        AND p.party_id = c.party_id
        AND op.party_id = p.party_id
        AND ope.organization_profile_id(+) = op.organization_profile_id;


-- OPEN ISSUE what price list is to be use for PIP
    CURSOR lcu_price_list IS
    SELECT 
        qlh.list_header_id
    FROM   
        qp_list_headers qlh
    WHERE  
            UPPER(NAME) LIKE 'QP%'
        AND qlh.active_flag = 'Y'
        AND SYSDATE BETWEEN NVL (qlh.start_date_active,SYSDATE)
        AND NVL(qlh.end_date_active,SYSDATE);

BEGIN

        --
        -- Assigning delivey_id to global variable
        --
    gn_delivery_id := p_delivery_id;

    --
    -- Clearing the PIP Item PL/SQL Table
    --

    gt_store_item_table.DELETE;

    FOR lr_ship_from_org_id IN  lcu_ship_from_org_id
    LOOP

        ln_ship_from_org_id :=  lr_ship_from_org_id.ship_from_org_id;
        ln_order_header_id  :=  lr_ship_from_org_id.header_id;
        ld_ordered_date := lr_ship_from_org_id.ordered_date;
        lc_catalog_src_cd := lr_ship_from_org_id.catalog_src_cd;
        ln_org_id := lr_ship_from_org_id.org_id;
        EXIT;
            
    END LOOP;
    
    lc_validation_flag  :=   NULL;

    -- call the csc count cursor here, if the csc is maxed already no 
    -- need to process further        
    IF ln_ship_from_org_id IS NOT NULL AND ln_order_header_id IS NOT NULL THEN

        FOR lr_csc_count IN lcu_csc_count( ln_ship_from_org_id )
        LOOP

            ln_max_csc_count := lr_csc_count.max_csc_count;
            ln_csc_count     := lr_csc_count.csc_count;

        END LOOP;
    END IF; 

    -- If we got the header information and have not hit the max at csc 
    -- the PIP eval can be processed
    IF ln_ship_from_org_id IS NOT NULL AND ln_order_header_id IS NOT NULL 
        AND ln_max_csc_count >= ln_csc_count THEN
        
        cmp_cnt := 0;

        -- loop through the order lines on the delivery to eval for PIP items
        FOR lr_order_details IN lcu_order_details(ln_order_header_id,ln_ship_from_org_id) -- loop for cu_order_details
        LOOP
  
            --  If it is the same customer no need to load everything again. There should
            -- only be one customer per delivery
            IF ln_cust_account_id <> lr_order_details.sold_to_org_id THEN
                
                --
                --  Deriving Customer attributes 
                --
                FOR lr_cust_attributes IN lcu_cust_attributes(lr_order_details.sold_to_org_id)
                LOOP
                    ln_cust_account_id  := lr_cust_attributes.cust_account_id;
                    lc_no_pick          := lr_cust_attributes.no_pick_list;
                    lc_reward_customer  := lr_cust_attributes.reward_customer;
                    lc_cust_association := lr_cust_attributes.cust_association;
                    lc_cust_order := lr_cust_attributes.cust_order;
                    ln_employees_total:= lr_cust_attributes.employees_total;
                    ln_customer_type  := lr_cust_attributes.customer_type;
                    lc_sic_code := lr_cust_attributes.sic_code;


                    -- Remove any rows that have been loaded previously
                    IF NVL(gt_rule_dtl_tbl.last,0) > 0 THEN
                        gt_rule_dtl_tbl.delete(1,gt_rule_dtl_tbl.last);
                    END IF;
                    
                    IF NVL(gt_rule_tbl.last,0) > 0 THEN
                        gt_rule_tbl.delete(1,gt_rule_tbl.last);
                    END IF;
                        
                    rule_count := 0;
                    rule_dtl_cnt := 0;

                    -- Since this is a new customer the rules have to be extracted
                    FOR lr_pip_rules IN lcu_pip_rules(lc_no_pick, ln_org_id)
                    LOOP
                        -- Storing the campaign header rules
                        rule_count := rule_count + 1;
                        gt_rule_tbl(rule_count).pip_campaign_id := lr_pip_rules.pip_campaign_id;
                        gt_rule_tbl(rule_count).campaign_id := lr_pip_rules.campaign_id;
                        gt_rule_tbl(rule_count).from_date := lr_pip_rules.from_date;
                        gt_rule_tbl(rule_count).end_date := NVL(lr_pip_rules.to_date, lr_pip_rules.from_date+999);
                        gt_rule_tbl(rule_count).order_source_id := lr_pip_rules.order_source_id;
                        gt_rule_tbl(rule_count).priority := lr_pip_rules.priority;
                        gt_rule_tbl(rule_count).order_count_flag := lr_pip_rules.order_count_flag;
                        gt_rule_tbl(rule_count).insert_qty := lr_pip_rules.insert_qty;
                        gt_rule_tbl(rule_count).insert_item1_id := lr_pip_rules.insert_item1_id;
                        gt_rule_tbl(rule_count).insert_item2_id := lr_pip_rules.insert_item2_id;
                        gt_rule_tbl(rule_count).customer_type := lr_pip_rules.customer_type;
                        gt_rule_tbl(rule_count).frequency_type := lr_pip_rules.frequency_type;
                        gt_rule_tbl(rule_count).frequency_number := lr_pip_rules.frequency_number;
                        gt_rule_tbl(rule_count).employees_min := lr_pip_rules.employees_min;
                        gt_rule_tbl(rule_count).employees_max := lr_pip_rules.employees_max;
                        gt_rule_tbl(rule_count).employees_exclude_flag := lr_pip_rules.employees_exclude_flag;
                        gt_rule_tbl(rule_count).sameday_del_flag := lr_pip_rules.sameday_del_flag;
                        gt_rule_tbl(rule_count).rewards_cust_flag := lr_pip_rules.rewards_cust_flag;
                        gt_rule_tbl(rule_count).order_low_amount := lr_pip_rules.order_low_amount;
                        gt_rule_tbl(rule_count).order_high_amount := lr_pip_rules.order_high_amount;
                        gt_rule_tbl(rule_count).order_range_exclude_flag := lr_pip_rules.order_range_exclude_flag;
                        gt_rule_tbl(rule_count).used_flag := 'N';
                        
                        -- extracting and storing any defined detail rules. Detail rules are not
                        -- required
                        last_dtl_rule := rule_dtl_cnt;
                        FOR lr_pip_rule_dtl IN lcu_pip_rule_dtl(lr_pip_rules.pip_campaign_id)
                        LOOP
                            rule_dtl_cnt := rule_dtl_cnt + 1;
                            gt_rule_dtl_tbl(rule_dtl_cnt).rule_type := lr_pip_rule_dtl.rule_type; 
                            gt_rule_dtl_tbl(rule_dtl_cnt).inc_exc_flag := lr_pip_rule_dtl.inc_exc_flag;
                            gt_rule_dtl_tbl(rule_dtl_cnt).char_value := lr_pip_rule_dtl.char_value; 
                            gt_rule_dtl_tbl(rule_dtl_cnt).num_value := lr_pip_rule_dtl.num_value;
                        END LOOP;
                        
                        -- store the start and end index of the detail rules. If no rules were
                        -- defined store a -1
                        IF last_dtl_rule >= rule_dtl_cnt THEN
                            gt_rule_tbl(rule_count).start_index := -1;
                            gt_rule_tbl(rule_count).end_index := -1;
                        ELSE
                            gt_rule_tbl(rule_count).start_index := last_dtl_rule + 1;
                            gt_rule_tbl(rule_count).end_index := rule_dtl_cnt;
                        END IF;
                       
                    END LOOP;
                            
                END LOOP;
            END IF;

            -- loop through all of the rules to validate the order line    
            FOR j IN gt_rule_tbl.first..gt_rule_tbl.last
            LOOP
 

              -- if the rule has been inserted for this delivery already no need to try again
              IF gt_rule_tbl(j).used_flag = 'N' THEN

                lc_validation_flag := 'Y';
                IF gt_rule_tbl(j).campaign_id IS NOT NULL THEN

                    --
                    -- Validation for customer id and zip code
                    --

                    lc_validation_flag := Validate_Pip_List(
                                                            lr_order_details.ship_to_org_id
                                                            ,gt_rule_tbl(j).campaign_id
                                                           );

                ELSE

                    --
                    -- Validate for Customer No. Of Employee
                    --

                    IF lc_validation_flag  =   'Y' THEN

                        -- if either the min or max number of employes is null skip the validation
                        IF gt_rule_tbl(j).employees_min IS NULL
                           OR gt_rule_tbl(j).employees_max IS NULL THEN
                                
                           lc_validation_flag  :=  'Y';

                        -- exclude if emp count is outside the range of employees
                        ELSIF NVL(gt_rule_tbl(j).employees_exclude_flag,'N') = 'Y' 
                              AND (ln_employees_total < gt_rule_tbl(j).employees_min
                                   OR ln_employees_total > gt_rule_tbl(j).employees_max) THEN

                            lc_validation_flag  :=   'Y';

                        -- include if the count is in the range
                        ELSIF NVL(gt_rule_tbl(j).employees_exclude_flag,'N') = 'N' 
                              AND ln_employees_total >= gt_rule_tbl(j).employees_min
                              AND ln_employees_total <= gt_rule_tbl(j).employees_max THEN

                            lc_validation_flag  :=   'Y';

                        ELSE

                            lc_validation_flag  := 'N';

                        END IF;

                    END IF;
                    
                    --
                    -- Validation for Customer Type
                    --
                    IF lc_validation_flag = 'Y' THEN

                       IF gt_rule_tbl(j).customer_type IS NULL THEN

                            lc_validation_flag := 'Y';

                        ELSIF ln_customer_type = gt_rule_tbl(j).customer_type THEN

                            lc_validation_flag  := 'Y';

                        ELSE

                            lc_validation_flag  := 'N';

                        END IF;

                    END IF;

                    --
                    -- Validation for Rewards Customer Include and Exclude
                    --

                    IF lc_validation_flag  =   'Y'    THEN

                        IF NVL(gt_rule_tbl(j).rewards_cust_flag,'N') !=  'N'  THEN

                            IF (gt_rule_tbl(j).rewards_cust_flag = 'I' 
                                AND lc_reward_customer IS NOT NULL)  OR
                               (gt_rule_tbl(j).rewards_cust_flag = 'E' 
                                AND lc_reward_customer IS NULL) THEN

                                lc_validation_flag  :=  'Y';

                            ELSE

                                lc_validation_flag  :=  'N';

                            END IF;

                        END IF;

                    END IF;
                
                
                END IF; 
                
                -- Validate that the schedule ship date and the pick date(now) is within
                -- the campaign definition
                IF lc_validation_flag = 'Y' THEN

                    IF lr_order_details.schedule_ship_date >= gt_rule_tbl(j).from_date
                       AND lr_order_details.schedule_ship_date <= gt_rule_tbl(j).end_date
                       AND SYSDATE >= gt_rule_tbl(j).from_date
                       AND SYSDATE <= gt_rule_tbl(j).end_date THEN

                        lc_validation_flag := 'Y';

                    ELSE

                        lc_validation_flag := 'N';

                    END IF;
                END IF;

                --
                -- Order Source Id Validation
                --

                IF lc_validation_flag = 'Y' THEN

                    IF gt_rule_tbl(j).order_source_id IS NOT NULL THEN

                        IF lr_order_details.order_source_id = gt_rule_tbl(j).order_source_id THEN

                            lc_validation_flag := 'Y';

                        ELSE

                            lc_validation_flag := 'N';

                        END IF;

                    END IF;

                END IF;

                --
                --  Validation for Sameday_Del_flag
                --
--OPEN issue need new definition of sameday
                IF  lc_validation_flag = 'Y' THEN

                    IF NVL(gt_rule_tbl(j).sameday_del_flag,'N') <> 'N' THEN

                        IF gt_rule_tbl(j).sameday_del_flag = 'I'
                           AND TO_CHAR(ld_ordered_date,'dd-mon-yyyy') = 
                                TO_CHAR(lr_order_details.schedule_ship_date,'dd-mon-yyyy') THEN

                                lc_validation_flag := 'Y';

                        ELSIF gt_rule_tbl(j).sameday_del_flag = 'E'
                              AND TO_CHAR(ld_ordered_date,'dd-mon-yyyy')  <> 
                                  TO_CHAR(lr_order_details.schedule_ship_date,'dd-mon-yyyy') THEN

                            lc_validation_flag := 'Y';

                        ELSE

                            lc_validation_flag := 'N';

                        END IF;

                    END IF;

                END IF;

                --
                -- Validation for order amount
                --

                IF lc_validation_flag  =   'Y' THEN

                    ln_order_amount.order_low_amount    :=  gt_rule_tbl(j).order_low_amount;
                    ln_order_amount.order_high_amount   :=  gt_rule_tbl(j).order_high_amount;
                    ln_order_amount.order_range_exclude_flag :=  gt_rule_tbl(j).order_range_exclude_flag;
                    lc_validation_flag:=  Validate_Order_Amount( ln_order_amount,ln_order_header_id );

                END IF;
                
                --
                -- Validation for the customer's order No First,Second or Third
                --
                IF lc_validation_flag  =   'Y' 
                   AND gt_rule_tbl(j).order_count_flag IS NOT NULL THEN

                    -- First order 
                    IF UPPER(gt_rule_tbl(j).order_count_flag)    = 'F'  AND lc_cust_order = '1' THEN

                        lc_validation_flag  :=   'Y';

                    -- Second order
                    ELSIF UPPER(gt_rule_tbl(j).order_count_flag) = 'S' AND lc_cust_order = '2' THEN

                        lc_validation_flag  :=   'Y';

                    -- third order
                    ELSIF UPPER(gt_rule_tbl(j).order_count_flag) = 'T'  AND lc_cust_order = '3' THEN

                        lc_validation_flag  :=   'Y';

                    -- No validation for order count
                    ELSIF UPPER((NVL(gt_rule_tbl(j).order_count_flag,'N'))) = 'N' THEN

                        lc_validation_flag  :=   'Y';
                    
                    -- first order number of the scheduled month
                    ELSIF UPPER(gt_rule_tbl(j).order_count_flag) = 'M' THEN
                    
                        --
                        -- Validation for order of the month
                        --

                        FOR lr_mon_count IN lcu_mon_count(lr_order_details.sold_to_org_id
                                                          ,ld_ordered_date)
                        LOOP

                            -- the cursor orders the query so the first order on the month
                            -- appears as the first row.If is matches our order all is well
                            IF lr_mon_count.header_id = ln_order_header_id THEN

                                lc_validation_flag  :=  'Y';

                            ELSE

                                lc_validation_flag  :=  'N';

                            END IF;

                            EXIT;

                        END LOOP;

                    ELSE

                        lc_validation_flag  :=   'N';

                    END IF;

                END IF;

                    --
                    -- Validation for Number of Orders for a customer
                    --

                IF lc_validation_flag = 'Y' THEN

                    IF UPPER(NVL(gt_rule_tbl(j).frequency_type,'I')) <> 'I' THEN
                        
                        -- set the days to look back to see if campaign was used. 
                        -- If once then set date range to 30 years, otherwise used the number of 
                        -- days in the rule
                        IF gt_rule_tbl(j).frequency_type = 'O' THEN

                            ld_freq_date := ld_ordered_date - 9999;

                        ELSE

                            ld_freq_date := ld_ordered_date - gt_rule_tbl(j).frequency_number;

                        END IF;
                        
                        FOR lr_count_order_line IN lcu_count_order_lines( gt_rule_tbl(j).pip_campaign_id 
                                                                         ,ld_freq_date
                                                                         ,lr_order_details.sold_to_org_id)
                        LOOP
                        
                            -- if there are any order lines in range then we failed
                            IF lr_count_order_line.value = 0  THEN

                                    lc_validation_flag  :=  'Y';

                            ELSE

                                        lc_validation_flag  :=  'N';

                            END IF;
 
                        END LOOP;

                    ELSE

                        lc_validation_flag  :=  'Y';

                    END IF;

                END IF;
                
                -- Validate the Rules details if there are any for the rule
                
                IF gt_rule_tbl(j).start_index > -1 THEN
                
                    -- if this is not a SAS generated campaign evaluate these
                    IF gt_rule_tbl(j).campaign_id IS NULL THEN
                    
                        -- validate the campaign/catalog code of the order
                        IF lc_validation_flag  =  'Y' THEN
                    
                             Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                          ,p_end => gt_rule_tbl(j).end_index
                                          ,p_rule_type => 'CAMP_CODE'
                                          ,p_char_value => lc_catalog_src_cd
                                          ,p_num_value => NULL
                                          ,x_validation_flag => lc_validation_flag
                                         );
                        END IF;
                   
                        -- validate the SIC code assigned to the customer
                        IF lc_validation_flag  =  'Y' THEN
                    
                             Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                          ,p_end => gt_rule_tbl(j).end_index
                                          ,p_rule_type => 'SIC_CODE'
                                          ,p_char_value => lc_sic_code
                                          ,p_num_value => NULL
                                          ,x_validation_flag => lc_validation_flag
                                         );
                        END IF;

                        -- validate the Assocaition the customer has defined
                        IF lc_validation_flag  =  'Y' THEN
                    
                             Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                          ,p_end => gt_rule_tbl(j).end_index
                                          ,p_rule_type => 'CUST_ASOCIATION'
                                          ,p_char_value => lc_cust_association
                                          ,p_num_value => NULL
                                          ,x_validation_flag => lc_validation_flag
                                         );
                        END IF;
                        
                        -- validate the effort code, aka price list, used for the line
                        IF lc_validation_flag  =  'Y' THEN
                    
                             Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                          ,p_end => gt_rule_tbl(j).end_index
                                          ,p_rule_type => 'EFFORT_CODE'
                                          ,p_char_value => NULL
                                          ,p_num_value => lr_order_details.price_list_id
                                          ,x_validation_flag => lc_validation_flag
                                         );
                        END IF;
                    END IF;
                    
                    -- General validations for all campaigns
                    
                    -- Validate the dept and class for the item on the order line
                    IF lc_validation_flag  =  'Y' THEN

                        lc_item_class := NULL;
                        lc_item_dept := NULL;
                        lc_state := NULL;
                      
                        FOR lr_dept_class IN lcu_dept_class (lr_order_details.inventory_item_id
                                                            ,lr_order_details.ship_from_org_id)
                        LOOP
                            lc_item_class := lr_dept_class.class;
                            lc_item_dept := lr_dept_class.dept;
                            EXIT;
                        END LOOP;

                        Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                       ,p_end => gt_rule_tbl(j).end_index
                                       ,p_rule_type => 'ITEM_CLASS'
                                       ,p_char_value => lc_item_class
                                       ,p_num_value => NULL
                                       ,x_validation_flag => lc_validation_flag
                                      );
                        
                        IF lc_validation_flag  =  'Y' THEN

                            Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                          ,p_end => gt_rule_tbl(j).end_index
                                          ,p_rule_type => 'ITEM_DEPT'
                                          ,p_char_value => lc_item_class
                                          ,p_num_value => NULL
                                          ,x_validation_flag => lc_validation_flag
                                         );
                        END IF;
                    END IF;
                    
                    -- validate the ship to state for the delivery
                    IF lc_validation_flag  =  'Y' THEN
                        FOR  lr_state IN lcu_state( lr_order_details.sold_to_org_id
                                                   ,lr_order_details.ship_to_org_id )
                        LOOP
                            lc_state := lr_state.state;
                            EXIT;
                        END LOOP;
                    
                        Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                       ,p_end => gt_rule_tbl(j).end_index
                                       ,p_rule_type => 'STATE_PROVINCE'
                                       ,p_char_value => lc_state
                                       ,p_num_value => NULL
                                       ,x_validation_flag => lc_validation_flag
                                      );
                    END IF;
                   
                    -- validate if the ordered item qualifies
                    IF lc_validation_flag  =  'Y' THEN

                        Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                       ,p_end => gt_rule_tbl(j).end_index
                                       ,p_rule_type => 'ORDER_ITEM'
                                       ,p_char_value => NULL
                                       ,p_num_value => lr_order_details.inventory_item_id
                                       ,x_validation_flag => lc_validation_flag
                                      );

                    END IF;

                    -- validate the ship from for the deilvery
                    IF lc_validation_flag  =  'Y' THEN

                        Validate_PIP_Items( p_start => gt_rule_tbl(j).start_index
                                       ,p_end => gt_rule_tbl(j).end_index
                                       ,p_rule_type => 'SHIP_FROM_ORG'
                                       ,p_char_value => NULL
                                       ,p_num_value => lr_order_details.ship_from_org_id
                                       ,x_validation_flag => lc_validation_flag
                                      );

                    END IF;
                END IF;

                --
                -- All Validations are successful
                -- Check if the Insert SKU is not already present on the order
                -- Store the Valid Insert SKUs into a PL/SQL Table
                --

                IF lc_validation_flag  =   'Y' THEN
                
                    -- once rule has passed no need to try again, flag it so we can skip it
                    -- for the rest of the lines in the delivery
                    gt_rule_tbl(j).used_flag := 'Y';
                    
                    lc_insert_item1_valid  :=  'Y';
                    lc_insert_item2_valid  :=  'Y';

                    -- check if the insert items are already on the order. If they are skip them
                    FOR lr_insert_item_rec  IN  lcu_insert_item_id(ln_order_header_id)
                    LOOP

                        IF ( lr_insert_item_rec.inventory_item_id = gt_rule_tbl(j).insert_item1_id ) THEN

                            lc_insert_item1_valid  :=  'N';

                        ELSIF (gt_rule_tbl(j).insert_item2_id IS NOT NULL
                               AND lr_insert_item_rec.inventory_item_id = gt_rule_tbl(j).insert_item2_id ) THEN

                            lc_insert_item2_valid  :=  'N';

                        END IF;

                    END LOOP;

                    -- push the insert items into the item array
                    IF (lc_insert_item1_valid ='Y') THEN

                        Get_Index ( x_index     => ln_number_of_record
                                   ,p_priority  => gt_rule_tbl(j).priority );

                        lr_item_rec.rec_index      := ln_number_of_record;
                        lr_item_rec.insert_item_id := gt_rule_tbl(j).insert_item1_id;
                        lr_item_rec.insert_qty     := gt_rule_tbl(j).insert_qty;
                        lr_item_rec.priority       := gt_rule_tbl(j).priority;
                        lr_item_rec.status_flag    := 'Y';
                        lr_item_rec.pip_campaign_id := gt_rule_tbl(j).pip_campaign_id;

                        Ins_Record ( p_index    => ln_number_of_record
                                    ,p_item_rec => lr_item_rec );

                        ln_number_of_record :=  ln_number_of_record + 1;

                        IF  (gt_rule_tbl(j).insert_item2_id IS NOT NULL
                             AND lc_insert_item2_valid        =  'Y' ) THEN

                            lr_item_rec.rec_index      := ln_number_of_record;
                            lr_item_rec.insert_item_id := gt_rule_tbl(j).insert_item2_id;
                            lr_item_rec.insert_qty     := gt_rule_tbl(j).insert_qty;
                            lr_item_rec.priority       := gt_rule_tbl(j).priority;
                            lr_item_rec.status_flag    := 'Y';
                            lr_item_rec.pip_campaign_id := gt_rule_tbl(j).pip_campaign_id;

                            Ins_Record ( p_index    => ln_number_of_record
                                        ,p_item_rec => lr_item_rec );

                        END IF;

                        lc_validation_flag  :=  'Y';

                    ELSE

                        lc_validation_flag  :=   'N';

                    END IF;

                END IF;
              END IF;
            END LOOP;-- loop for pip_rules
        END LOOP;-- loop for lcu_order_details

        --
        -- Removing excess SKUs and incompatible SKUs
        -- from the Insert SKUs PL/SQL Table
        --
            
        Del_Excess_Pip_Items;

        -- if we did not hit the max at the CSCS and there are items to insert, proceed
        IF ln_max_csc_count >= ln_csc_count 
           AND gt_store_item_table.COUNT > 0 THEN

            -- to count the items inserted
            ln_insert_item_limit := 0;

            FOR ln_indexs IN 0..gt_store_item_table.COUNT-1
            LOOP
                --
                -- Calculating On hand Quantity
                --

                FOR lr_onhand IN lcu_onhand_quantity(
                                                     gt_store_item_table(ln_indexs).insert_item_id
                                                     ,ln_ship_from_org_id
                                                    )
                LOOP

                    ln_onhand_qty := lr_onhand.onhand_quantity;

                END LOOP;

                --
                -- Adding item to the table type
                --

                IF ln_onhand_qty >0 THEN
                    --  limit of 3 items to be inserted based 
                    --   n the item list and if the item has onhand qty
                    ln_insert_item_limit := ln_insert_item_limit + 1;
                    IF ln_insert_item_limit > gn_insert_item_limit THEN
                        EXIT;
                    ELSE
                    
                        FOR lr_price_list IN lcu_price_list
                        LOOP
                           ln_price_list_id := lr_price_list.list_header_id;
                        END LOOP;
                        
                        lt_line_item_details(ln_insert_item_limit) := OE_ORDER_PUB.G_MISS_LINE_REC;
                        lt_line_item_details(ln_insert_item_limit).header_id := ln_order_header_id;
                        lt_line_item_details(ln_insert_item_limit).inventory_item_id := gt_store_item_table(ln_indexs).insert_item_id;
                        lt_line_item_details(ln_insert_item_limit).price_list_id := ln_price_list_id;
                        lt_line_item_details(ln_insert_item_limit).ship_from_org_id := ln_ship_from_org_id;
                        lt_line_item_details(ln_insert_item_limit).schedule_ship_date := sysdate;
                        
                        lt_line_item_details(ln_insert_item_limit).ordered_quantity := gt_store_item_table(ln_indexs).insert_qty;
                        lt_line_item_details(ln_insert_item_limit).operation := OE_GLOBALS.G_OPR_CREATE;
                        
                        -- save the campaign id to write the extension row for the order line inserted
                        lt_camp_id_tbl(ln_insert_item_limit).pip_campaign_id := gt_store_item_table(ln_indexs).pip_campaign_id;
                    END IF;
                END IF;

            END LOOP;

            -- if there are lines tom be inserted call the APIs to insert them
            IF lt_line_item_details.COUNT > 0 THEN

                --
                -- Adding order line for PIP items
                --
                Add_Freebiz_Order_Line(
                                        p_order_lines_tbl    => lt_line_item_details
                                       ,p_camp_id_tbl        => lt_camp_id_tbl
                                       ,x_delivery_detail_id => lt_delivery_detail_id
                                       ,x_ord_validate_flag  => lc_ord_validate_flag
                                      );

                -- loop through the sucesssfully inserted order lines to load them into
                -- the array to be sent to the API
                IF lc_ord_validate_flag = 'Y' THEN
                    FOR ln_ind IN lt_delivery_detail_id.FIRST..lt_delivery_detail_id.LAST
                    LOOP

                        lt_del_detail_id(ln_ind) := NVL(lt_delivery_detail_id(ln_ind),0);

                    END LOOP;
                END IF;

                --
                -- Assigning delivery details to current delivery
                --

                IF lc_ord_validate_flag = 'Y' THEN

                    Details_To_Delivery(
                                         p_tab_of_del_detail   => lt_del_detail_id
                                        ,p_del_id              => p_delivery_id
                                        ,x_del_validate_flag   => lc_del_validate_flag
                                       );

                END IF;

                IF lc_del_validate_flag = 'Y' AND lc_ord_validate_flag = 'Y' THEN

                    --
                    -- Updating the count for CSC
                    --

                    BEGIN

                        UPDATE xx_om_pip_insert_count
                        SET    csc_count        = NVL(csc_count,0) + 1
                        WHERE  ship_from_org_id = ln_ship_from_org_id;
                        
                    EXCEPTION
                        WHEN OTHERS THEN

                            ROLLBACK;

                            FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

                            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                            lc_errbuf   := FND_MESSAGE.GET;
                            lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR8';

                            -- -------------------------------------
                            -- Call the Write_Exception procedure to
                            -- insert into Global Exception Table
                            -- -------------------------------------

                            Write_Exception (
                                             p_error_code        => lc_err_code
                                            ,p_error_description => lc_errbuf
                                            ,p_entity_reference  => 'DELIVERY_ID'
                                            ,p_entity_ref_id     => gn_delivery_id
                                            );

                            RAISE EX_UPDATE_FAILURE;

                    END;

                    COMMIT;

                ELSE
                    -- there was an error somewhere so rollback all the inserts
                    ROLLBACK;
                END IF;

                p_status_flag   :=  'Campaign Completed';

            ELSE

                p_status_flag   :=  'Campaign Completed';

            END IF;

            lt_line_item_details.DELETE;

            gt_store_item_table.DELETE;

        ELSE

            p_status_flag   :=  'Campaign Completed';

        END IF;

    ELSE

        p_status_flag   :=  'Campaign Completed';

    END IF; -- ln_ship_from_org_id

EXCEPTION
    WHEN EX_UPDATE_FAILURE THEN

            p_status_flag   :=  'Campaign Not Completed';

    WHEN OTHERS THEN

            ROLLBACK;

            FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

            lc_errbuf   := FND_MESSAGE.GET;
            lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR9';

            -- -------------------------------------
            -- Call the Write_Exception procedure to
            -- insert into Global Exception Table
            -- -------------------------------------

            Write_Exception (
                          p_error_code        => lc_err_code
                         ,p_error_description => lc_errbuf
                         ,p_entity_reference  => 'Delivery Id'
                         ,p_entity_ref_id     => gn_delivery_id
                          );

            p_status_flag   :=  'Campaign Not Completed';

END Determine_PIP_Items;

END xx_om_evaluate_pip_pkg;           -- End Package Body Block
/

SHOW ERRORS;

--EXIT
