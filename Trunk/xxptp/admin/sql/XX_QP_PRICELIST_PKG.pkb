SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_QP_PRICELIST_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name        :  XX_QP_PRICELIST_PKG.pkb                            |
-- | Description :  This package is used to Create,update and Delete   |
-- |                Price List.                                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft 1a  24-May-2007 Madhukar Salunke Initial draft version       |
-- |Draft 1b  29-May-2007 Madhukar Salunke Updated after peer review   |
-- |Draft 1c  19-Jun-2007 Madhukar Salunke Updated UOM_CHANGE scenario |
-- |Draft 1d  04-Jul-2007 Madhukar Salunke Updated as per onsite comments|
-- |Draft 1e  30-Jul-2007 Madhukar Salunke Added delete operation for PBH|
-- |                                       line in case of same day price|
-- |                                       change.                     |
-- |Draft 1f  09-Aug-2007 Madhukar Salunke Added logic for PBH to PLL  |
-- |                                       conversion and vice versa   |
-- +===================================================================+
IS

-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- +========================================================================+
PROCEDURE LOG_ERROR(p_exception IN VARCHAR2
                   ,p_message   IN VARCHAR2
                   )
IS

BEGIN
   XX_COM_ERROR_LOG_PUB.LOG_ERROR
                        (
                         p_program_type            => G_PROG_TYPE     --IN VARCHAR2  DEFAULT NULL
                        ,p_program_name            => G_PROG_NAME     --IN VARCHAR2  DEFAULT NULL
                        ,p_module_name             => G_MODULE_NAME   --IN VARCHAR2  DEFAULT NULL
                        ,p_error_location          => p_exception      --IN VARCHAR2  DEFAULT NULL
                        ,p_error_message           => p_message        --IN VARCHAR2  DEFAULT NULL
                        ,p_notify_flag             => G_NOTIFY        --IN VARHCAR2  DEFAULT NULL
                        );
END LOG_ERROR;

--+=======================================================================================+
--| PROCEDURE  : create_pricelist_main                                                    |
--| P_Od_Price_List_Rec_Type IN    Od_Price_List_Rec_Type    Price list attribute details |
--+=======================================================================================+

PROCEDURE create_pricelist_main(
          P_Od_Price_List_Rec_Type   IN     Od_Price_List_Rec_Type
          ,x_message_data            OUT    VARCHAR2
          )
IS
   -- Declare the IN parameters of the API QP_PRICE_LIST_PUB.process_price_list
   lr_price_list_rec              QP_PRICE_LIST_PUB.Price_List_Rec_Type         := QP_PRICE_LIST_PUB.G_MISS_PRICE_LIST_REC;
   lr_price_list_val_rec          QP_PRICE_LIST_PUB.Price_List_Val_Rec_Type     := QP_PRICE_LIST_PUB.G_MISS_PRICE_LIST_VAL_REC;
   lt_price_list_line_tbl         QP_PRICE_LIST_PUB.Price_List_Line_Tbl_Type    := QP_PRICE_LIST_PUB.G_MISS_PRICE_LIST_LINE_TBL;
   lt_price_list_line_val_tbl     QP_PRICE_LIST_PUB.Price_List_Line_Val_Tbl_Type:= QP_PRICE_LIST_PUB.G_MISS_PRICE_LIST_LINE_VAL_TBL;
   lt_qualifiers_tbl              QP_Qualifier_Rules_Pub.Qualifiers_Tbl_Type    := QP_Qualifier_Rules_Pub.G_Miss_Qualifiers_Tbl;
   lt_qualifiers_val_tbl          QP_Qualifier_Rules_Pub.Qualifiers_Val_Tbl_Type:= Qp_Qualifier_Rules_Pub.G_MISS_QUALIFIERS_VAL_TBL;
   lt_pricing_attr_tbl            QP_PRICE_LIST_PUB.Pricing_Attr_Tbl_Type       := QP_Price_List_PUB.G_MISS_PRICING_ATTR_TBL;
   lt_pricing_attr_val_tbl        QP_PRICE_LIST_PUB.Pricing_Attr_Val_Tbl_Type   := QP_Price_List_PUB.G_MISS_PRICING_ATTR_VAL_TBL;

   -- Declare the OUT parameters for the API QP_PRICE_LIST_PUB.process_price_list
   lx_price_list_rec              QP_PRICE_LIST_PUB.Price_List_Rec_Type;
   lx_price_list_val_rec          QP_PRICE_LIST_PUB.Price_List_Val_Rec_Type;
   lx_price_list_line_tbl         QP_PRICE_LIST_PUB.Price_List_Line_Tbl_Type;
   lx_price_list_line_val_tbl     QP_PRICE_LIST_PUB.Price_List_Line_Val_Tbl_Type;
   lx_qualifier_rules_rec         QP_Qualifier_Rules_Pub.Qualifier_Rules_Rec_Type;
   lx_qualifier_rules_val_rec     QP_Qualifier_Rules_Pub.Qualifier_Rules_Val_Rec_Type;
   lx_qualifiers_tbl              QP_Qualifier_Rules_Pub.Qualifiers_Tbl_Type;
   lx_qualifiers_val_tbl          QP_Qualifier_Rules_Pub.Qualifiers_Val_Tbl_Type;
   lx_pricing_attr_tbl            QP_PRICE_LIST_PUB.Pricing_Attr_Tbl_Type;
   lx_pricing_attr_val_tbl        QP_PRICE_LIST_PUB.Pricing_Attr_Val_Tbl_Type;

   --Declare local variable
   lc_err_message                 VARCHAR2(4000) := NULL;
   ln_msg_count                   NUMBER;
   lc_return_status               VARCHAR2(1);
   lc_msg_data                    VARCHAR2(2500);
   lc_error_msg                   VARCHAR2(2500);
   lc_list_type_code              QP_List_Lines.list_line_type_code%TYPE;
   ln_cur_product_uom_code        QP_PRICING_ATTRIBUTES.PRODUCT_UOM_CODE%TYPE;
   ln_list_header_id              NUMBER;
   ln_pbh_Header_Id               NUMBER;
   ln_up_list_header_id           NUMBER;
   ln_inventory_item_id           NUMBER;
   ln_up_list_line_id             NUMBER;
   ln_dl_list_line_id             NUMBER;
   ln_pr_list_line_id             NUMBER;
   ln_end_list_line_id            NUMBER;
   ln_strt_list_line_id           NUMBER;
   lc_flag_strt_date              VARCHAR2(1):= 'N';-- Flag to check incoming start date with current start date
   ln_new_index                   NUMBER := 0;
   ln_del_index                   NUMBER := 1;      -- To increment index after updating line
   ln_pbh                         NUMBER := 1;
   lb_create_rec_flag             BOOLEAN := TRUE ;  -- To create new list line
   lb_pbh_flag                    BOOLEAN := FALSE ; -- for breaking pbh line in case
   lb_copy_flag                   BOOLEAN := FALSE ; -- for copying line
   lb_pbh_copy_flag               BOOLEAN := FALSE ; -- for copying line
   lb_pll_pbh_flag                BOOLEAN := TRUE ;  -- Convert PLL to PBH and PBH to PLL line
   ld_dl_end_date_active          DATE;
   ld_null_end_date_active        DATE := FND_API.G_MISS_DATE;

   EX_INVENTORY_ITEM_ID           EXCEPTION;
   EX_PRICE_LIST_NOT_EXISTS       EXCEPTION;
   EX_DELETION                    EXCEPTION;

   ----------------------------------------------------
   -- Fetch current and future records for UOM updation
   ----------------------------------------------------
   CURSOR lcu_invalid_uom (ln_product_attr_val IN VARCHAR2,ln_uom_header_id IN NUMBER)
   IS
   SELECT QLL.List_Line_Id
         ,QPA.pricing_attribute_id
   FROM QP_Pricing_Attributes QPA,
        QP_List_Headers_TL    QLH,
        QP_List_Lines         QLL
   WHERE QLH.list_header_id    = ln_uom_header_id
   AND QPA.Product_Attr_Value  = ln_product_attr_val
   AND QPA.List_Header_Id      = QLL.List_Header_Id
   AND QPA.List_Line_Id        = QLL.List_Line_Id
   AND QLL.List_Header_Id      = QLH.List_Header_Id
   AND (QLL.end_date_active    >= SYSDATE OR QLL.end_date_active IS NULL);

   ------------------------
   -- Fetch all start dates
   ------------------------
   CURSOR lcu_list_line (ln_product_attr_val IN VARCHAR2)
   IS
   SELECT  QLL.list_line_id
          ,QLH.list_header_id
          ,QLL.start_date_active
          ,QLL.list_line_type_code
   FROM    QP_Pricing_Attributes QPA
          ,QP_List_Headers_TL    QLH
          ,QP_List_Lines         QLL
   WHERE UPPER(QLH.Name)             = UPPER(P_Od_Price_List_Rec_Type.name)
   AND QPA.Product_Attr_Value        = ln_product_attr_val
   AND QPA.List_Header_Id            = QLL.List_Header_Id
   AND QPA.List_Line_Id              = QLL.List_Line_Id
   AND QLL.List_Header_Id            = QLH.List_Header_Id;

   -----------------------------------------------------------------------------------------------
   -- (PBH) Fetch list_line_id, pricing_attribute_id for operand update in case of same start date
   -----------------------------------------------------------------------------------------------
   CURSOR lcu_pbh_strt_line (ln_str_header_id IN NUMBER,
                             ln_strt_line_id IN NUMBER)
   IS
   SELECT QPB.list_header_id,
          QLL.list_line_id,
          QPB.pricing_Attribute_id
   FROM   qp_price_breaks_v QPB,
          qp_list_lines QLL
   WHERE  QPB.list_line_id (+)             = QLL.list_line_id
   AND    QLL.list_header_id               = ln_str_header_id
   AND    QPB.parent_list_line_id          = ln_strt_line_id
   AND    NVL(QLL.LIST_LINE_TYPE_CODE,'#') <> 'PBH';

   --------------------------------------------------------
   -- In case of UOM_CHANGE fetch header_id related to item
   --------------------------------------------------------
   CURSOR lcu_list_header (ln_product_attr_val IN VARCHAR2)
   IS
   SELECT DISTINCT QLL.list_header_id
   FROM  QP_List_Lines QLL,
         QP_Pricing_Attributes QPA
   WHERE QPA.Product_Attr_Value   = ln_product_attr_val
   AND   QLL.list_line_id         = QPA.list_line_id
   AND   QPA.List_Header_Id       = QLL.List_Header_Id;   

   ------------------------------------------------------------------------
   -- In case of future Delete fetch privious list_line_id of deleting line
   ------------------------------------------------------------------------
   CURSOR lcu_prvs_list_line (ln_product_attr_val    IN VARCHAR2,
                              ln_dl_List_Line_Id     IN NUMBER,
                              ld_start_date_activel  IN DATE)
   IS
   SELECT QLL.list_line_id
   FROM QP_List_Lines_V QLL
       ,QP_List_Headers_TL QLH
   WHERE UPPER(QLH.Name)            = UPPER(P_Od_Price_List_Rec_Type.name)
   AND  QLL.List_LINE_Id            <> ln_dl_List_Line_Id
   AND  QLL.List_Header_Id          = QLH.List_Header_Id
   AND  QLL.product_attr_value      = ln_product_attr_val
   AND TRUNC(QLL.start_date_active) < TRUNC(ld_start_date_activel)
   ORDER BY  QLL.end_date_active DESC;

   ---------------------------------------
   -- PBH/PLL values for creating new line
   ---------------------------------------
   CURSOR lcu_futr_line(ln_list_line_id IN NUMBER)
   IS
   SELECT list_header_id,
          product_attr_value,
          product_uom_code,
          operand,
          list_line_type_code,
          end_date_active,
          product_precedence,
          price_by_formula_id
   FROM   qp_list_lines_v
   WHERE  list_line_id  =ln_list_line_id;

   lr_lcu_futr_line   lcu_futr_line%ROWTYPE;

   -----------------------------------
   -- PBH values for creating new line
   -----------------------------------
   CURSOR lcu_copy_pbh_line(ln_prnt_line_id IN NUMBER)
   IS
   SELECT  pricing_attr_value_from,
           pricing_attr_value_to,
           operand 
   FROM  qp_price_breaks_v
   WHERE parent_list_line_id =ln_prnt_line_id
   ORDER BY pricing_attr_value_from ASC;
   
   
   TYPE copy_pbh_line_tab IS TABLE OF lcu_copy_pbh_line%ROWTYPE INDEX 
   BY BINARY_INTEGER;
   
   lt_lcu_copy_pbh_line  copy_pbh_line_tab;
   

BEGIN

   --------------------------
   -- Validate inventory item
   --------------------------
   BEGIN
      SELECT inventory_item_id
      INTO   ln_inventory_item_id
      FROM   mtl_system_items
      WHERE  segment1 = P_Od_Price_List_Rec_Type.product_attr_value
      AND    ROWNUM < 2; -- Need only item id hence rownum < 2

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
          RAISE EX_INVENTORY_ITEM_ID;
      WHEN OTHERS THEN
          RAISE EX_INVENTORY_ITEM_ID;
   END;
   lc_err_message := NULL;
   ------------------------------------------------------
   -- Price List Line Operation = Update for updating UOM
   ------------------------------------------------------
   IF P_Od_Price_List_Rec_Type.name = 'UOM_CHANGE'   AND
      P_Od_Price_List_Rec_Type.operationa = 'UPDATE' THEN

      BEGIN
         FOR rec_header IN lcu_list_header(ln_inventory_item_id)
         LOOP

         ---------------------------------------
         -- Validate  UOM with existing line uom
         ---------------------------------------

            FOR rec_uom IN lcu_invalid_uom(ln_inventory_item_id,rec_header.list_header_id)
            LOOP
               ----------------------
               -- Update with new UOM
               ----------------------
               lt_pricing_attr_tbl(lcu_invalid_uom%ROWCOUNT).list_header_id       := rec_header.list_header_id;
               lt_pricing_attr_tbl(lcu_invalid_uom%ROWCOUNT).List_Line_Id         := rec_uom.list_line_id;
               lt_pricing_attr_tbl(lcu_invalid_uom%ROWCOUNT).Pricing_Attribute_Id := rec_uom.Pricing_Attribute_id;
               lt_pricing_attr_tbl(lcu_invalid_uom%ROWCOUNT).product_uom_code     := P_Od_Price_List_Rec_Type.product_uom_code;
               lt_pricing_attr_tbl(lcu_invalid_uom%ROWCOUNT).operation            := qp_globals.g_opr_update;

            END LOOP; -- Line loop

         --------------------------------------------------------------------
         -- API call to Create/Update Price List Header, Lines and Attributes
         --------------------------------------------------------------------
         QP_PRICE_LIST_PUB.Process_Price_List
                  (
                    p_api_version_number       => 1
                  , p_init_msg_list            => fnd_api.g_true
                  , p_return_values            => fnd_api.g_false
                  , p_commit                   => fnd_api.g_true
                  , x_return_status            => lc_return_status
                  , x_msg_count                => ln_msg_count
                  , x_msg_data                 => lc_msg_data
                  , p_price_list_rec           => lr_price_list_rec
                  , p_price_list_line_tbl      => lt_price_list_line_tbl
                  , p_qualifiers_tbl           => lt_qualifiers_tbl
                  , p_pricing_attr_tbl         => lt_pricing_attr_tbl
                  , x_price_list_rec           => lx_price_list_rec
                  , x_price_list_val_rec       => lx_price_list_val_rec
                  , x_price_list_line_tbl      => lx_price_list_line_tbl
                  , x_price_list_line_val_tbl  => lx_price_list_line_val_tbl
                  , x_qualifiers_tbl           => lx_qualifiers_tbl
                  , x_qualifiers_val_tbl       => lx_qualifiers_val_tbl
                  , x_pricing_attr_tbl         => lx_pricing_attr_tbl
                  , x_pricing_attr_val_tbl     => lx_pricing_attr_val_tbl
                  );

                 IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                    IF ln_msg_count > 0 THEN
                       FOR counter IN 1..ln_msg_count
                       LOOP

                          IF counter = 1 THEN
                             lc_err_message := FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                          ELSE
                             lc_err_message := lc_err_message||' - '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                          END IF;

                       END LOOP;
                       fnd_msg_pub.delete_msg;
                       x_message_data := SUBSTR(lc_err_message,1,4000);
                       LOG_ERROR(p_exception => 'API ERROR'
                                ,p_message   => x_message_data
                                );
                    END IF;

                 ELSE

                    x_message_data := 'UOM Updated Succecfully';

                 END IF;
                 COMMIT;

           END LOOP;   -- Header loop

        EXCEPTION

          WHEN OTHERS THEN
             x_message_data := 'Error -> '||SQLERRM;
             LOG_ERROR(p_exception => 'OTHERS'
                      ,p_message   => x_message_data
                      );
        END;

  ELSE

     -----------------------------
     -- Header operation is create
     -----------------------------
     IF P_Od_Price_List_Rec_Type.operationh = 'CREATE' THEN

        lr_price_list_rec.list_header_id        := fnd_api.g_miss_num;
        lr_price_list_rec.name                  := P_Od_Price_List_Rec_Type.name;
        lr_price_list_rec.description           := P_Od_Price_List_Rec_Type.description;
        lr_price_list_rec.start_date_active     := TRUNC(P_Od_Price_List_Rec_Type.start_date_activeh);
        lr_price_list_rec.end_date_active       := TRUNC(P_Od_Price_List_Rec_Type.end_date_activeh);
        lr_price_list_rec.creation_date         := NVL(TRUNC(P_Od_Price_List_Rec_Type.creation_date),TRUNC(SYSDATE));
        lr_price_list_rec.attribute6            := NVL(P_Od_Price_List_Rec_Type.attribute6,fnd_api.g_miss_char);
        lr_price_list_rec.attribute7            := NVL(P_Od_Price_List_Rec_Type.attribute7,fnd_api.g_miss_char);
        lr_price_list_rec.context               := 'GLOBAL';
        lr_price_list_rec.list_type_code        := 'PRL';
        lr_price_list_rec.rounding_factor       := NVL(P_Od_Price_List_Rec_Type.rounding_factor,-3);
        lr_price_list_rec.currency_code         := P_Od_Price_List_Rec_Type.currency_code;
        lr_price_list_rec.active_flag           := P_Od_Price_List_Rec_Type.active_flag;
        lr_price_list_rec.global_flag           := 'N';
        lr_price_list_rec.operation             := qp_globals.g_opr_create;

     END IF;

     -----------------------------
     -- Header operation is update
     -----------------------------
     lc_err_message := NULL;
     IF P_Od_Price_List_Rec_Type.operationh = 'UPDATE' THEN
        BEGIN
           SELECT  list_header_id
           INTO    ln_list_header_id
           FROM    qp_list_headers
           WHERE   UPPER(Name) = UPPER(P_Od_Price_List_Rec_Type.name);

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             RAISE EX_PRICE_LIST_NOT_EXISTS;
           WHEN OTHERS THEN
             RAISE EX_PRICE_LIST_NOT_EXISTS;
        END;

        lr_price_list_rec.list_header_id        := ln_list_header_id;
        lr_price_list_rec.operation             := qp_globals.g_opr_update;

     END IF;

   ------------------------------------
   -- Creating List Line and Attributes
   ------------------------------------
   lc_err_message := NULL;
   BEGIN

     IF P_Od_Price_List_Rec_Type.operationl = 'CREATE' THEN

       BEGIN

          FOR line_rec IN lcu_list_line(ln_inventory_item_id)
          LOOP
            -------------------------------------------------------------
            -- Check incoming start date with currently active start date
            -------------------------------------------------------------
            IF TRUNC(P_Od_Price_List_Rec_Type.start_date_activel) =  TRUNC(line_rec.start_date_active) THEN

               lc_flag_strt_date    := 'Y';
               ln_up_list_line_id   := line_rec.list_line_id;
               ln_up_list_header_id := line_rec.list_header_id;
               lc_list_type_code    := line_rec.list_line_type_code; 

            END IF;

         END LOOP;

         --------------------------------------------------------------------------------------------------------------------------------
         -- Check incoming record start_date_active with existing current start_date_active update operand and no need to create new line
         --------------------------------------------------------------------------------------------------------------------------------
         IF lc_flag_strt_date = 'Y' THEN

            -------------------------
            -- header record updation
            -------------------------
            lr_price_list_rec.list_header_id                    := ln_up_list_header_id;
            lr_price_list_rec.operation                         := qp_globals.g_opr_update;
            lb_create_rec_flag    := FALSE ;
            
            IF lc_list_type_code = 'PBH' AND P_Od_Price_List_Rec_Type.multi_unit1 IS NULL THEN -- CR: Draft 1f
               ln_new_index                                        := ln_new_index + 1;
               lt_price_list_line_tbl(ln_new_index).list_header_id := ln_up_list_header_id;
               lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_up_list_line_id;
               lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_delete;
               lb_create_rec_flag    := TRUE ;
               lb_pll_pbh_flag       := FALSE;
               

            ELSIF lc_list_type_code = 'PLL' AND P_Od_Price_List_Rec_Type.multi_unit1 IS NOT NULL THEN -- CR: Draft 1f
               ln_new_index                                        := ln_new_index + 1;
               lt_price_list_line_tbl(ln_new_index).list_header_id := ln_up_list_header_id;
               lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_up_list_line_id;
               lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_delete;
               lb_create_rec_flag    := TRUE ;
               lb_pll_pbh_flag       := FALSE;

            END IF;

            ---------------------
            -- Update PLL Operand
            ---------------------
            IF P_Od_Price_List_Rec_Type.multi_unit1 IS NULL AND (lb_pll_pbh_flag) THEN
               ln_new_index                                        := ln_new_index + 1;
               lt_price_list_line_tbl(ln_new_index).list_header_id := ln_up_list_header_id;
               lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_up_list_line_id;
               lt_price_list_line_tbl(ln_new_index).operand        := P_Od_Price_List_Rec_Type.operand;
               lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_update;

            ELSE
             
             BEGIN
               ln_new_index                                        := ln_new_index + 1;
               lt_price_list_line_tbl(ln_new_index).list_header_id := ln_up_list_header_id;
               lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_up_list_line_id;
               lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_update;
               -------------------------------------------
               -- Update PBH Operands for all price breaks
               -------------------------------------------
               FOR pbh_rec IN lcu_pbh_strt_line(ln_up_list_header_id,
                                                ln_up_list_line_id)
               LOOP

                  IF lcu_pbh_strt_line%ROWCOUNT = 1 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 2 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 3 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 4 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 5 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 6 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 7 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 8 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 9 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 10 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 11 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 12 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 13 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 14 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 15 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 16 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

                  IF lcu_pbh_strt_line%ROWCOUNT = 17 THEN
                     ln_new_index                                             := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_header_id      := ln_up_list_header_id;
                     lt_price_list_line_tbl(ln_new_index).list_line_id        := pbh_rec.list_line_id;
                     lt_pricing_attr_tbl(ln_new_index).pricing_Attribute_id   := pbh_rec.pricing_Attribute_id;
                     lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_delete;
                  END IF;

              END LOOP;
              --------------------------------------------------------------------
              -- API call to Create/Update Price List Header, Lines and Attributes
              --------------------------------------------------------------------
              QP_PRICE_LIST_PUB.Process_Price_List
                 (
                   p_api_version_number       => 1
                 , p_init_msg_list            => fnd_api.g_true
                 , p_return_values            => fnd_api.g_false
                 , p_commit                   => fnd_api.g_true
                 , x_return_status            => lc_return_status
                 , x_msg_count                => ln_msg_count
                 , x_msg_data                 => lc_msg_data
                 , p_price_list_rec           => lr_price_list_rec
                 , p_price_list_line_tbl      => lt_price_list_line_tbl
                 , p_qualifiers_tbl           => lt_qualifiers_tbl
                 , p_pricing_attr_tbl         => lt_pricing_attr_tbl
                 , x_price_list_rec           => lx_price_list_rec
                 , x_price_list_val_rec       => lx_price_list_val_rec
                 , x_price_list_line_tbl      => lx_price_list_line_tbl
                 , x_price_list_line_val_tbl  => lx_price_list_line_val_tbl
                 , x_qualifiers_tbl           => lx_qualifiers_tbl
                 , x_qualifiers_val_tbl       => lx_qualifiers_val_tbl
                 , x_pricing_attr_tbl         => lx_pricing_attr_tbl
                 , x_pricing_attr_val_tbl     => lx_pricing_attr_val_tbl
                 );

              ln_new_index := 0;
              lt_price_list_line_tbl.delete;

              IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 IF ln_msg_count > 0 THEN
                    FOR counter IN 1..ln_msg_count
                    LOOP
                       IF counter = 1 THEN
                          lc_err_message := FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                       ELSE
                          lc_err_message := lc_err_message||' - '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                       END IF;
                    END LOOP;
                    x_message_data := SUBSTR(x_message_data||lc_err_message,1,4000);

                    fnd_msg_pub.delete_msg;
                    LOG_ERROR(p_exception => 'API ERROR'     --IN VARCHAR2
                             ,p_message   => lc_err_message  --IN VARCHAR2
                             );
                 END IF;
              END IF;
              COMMIT;   -- delete child lines  of PBH
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   -- As per onsite comment not to log error in case of update just to continue the flow
                   NULL;
              WHEN OTHERS THEN
                   -- As per onsite comment not to log error in case of update just to continue the flow
                   NULL;
           END;           
           
       -----------------------------------
       -- create child line with new price 
       -----------------------------------
       BEGIN
          ln_new_index                                        := ln_new_index + 1;
          lt_price_list_line_tbl(ln_new_index).list_header_id := ln_up_list_header_id;
          lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_up_list_line_id;
          lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_update;
          --------------------
          -- Price Break Lines
          --------------------
          FOR counter IN 1..1
          LOOP

           IF P_Od_Price_List_Rec_Type.multi_unit1 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;

              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.Operand;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              --ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := '1';
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit1-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit2 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl1;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit1;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := qp_globals.g_opr_create;

              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit2 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl1;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit1;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit2-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := qp_globals.g_opr_create;

              IF P_Od_Price_List_Rec_Type.multi_unit3 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl2;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit2;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit3 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl2;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit2;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit3-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit4 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl3;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit3;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit4 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl3;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit3;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit4-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit5 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl4;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit4;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit5 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl4;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit4;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit5-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit6 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit5;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit6 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit5;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit6-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit7 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl6;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit6;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit7 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl6;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit6;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit7-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit8 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl7;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit7;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit8 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl7;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit7;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit8-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit9 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl8;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit8;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit9 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl8;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit8;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit9-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit10 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl9;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit9;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit10 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl9;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit9;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit10-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit11 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl10;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit10;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit11 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl10;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit10;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit11-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit12 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl11;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit11;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit12 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl11;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit11;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit12-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit13 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl12;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit12;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit13 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl12;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit12;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit13-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit14 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl13;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit13;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit14 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl13;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit13;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit14-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit15 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl14;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit14;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit15 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl14;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit14;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit15-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit16 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit15;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit16 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl15;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit15;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit16-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;


                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl16;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit16;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              END IF;
           END LOOP;               
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              -- As per onsite comment not to log error in case of update just to continue the flow
              NULL;
           WHEN OTHERS THEN
              -- As per onsite comment not to log error in case of update just to continue the flow
              NULL;
        END;           
        ln_new_index := 0;
        ln_pbh := 1;
      END IF; -- PLL/PBH
   END IF; -- Flag Y

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        lc_err_message := 'Error ->'||SQLERRM;
        x_message_data := x_message_data||lc_err_message;
        LOG_ERROR(p_exception => 'NO_DATA_FOUND'   --IN VARCHAR2
                 ,p_message   => lc_err_message    --IN VARCHAR2
                 );

     WHEN OTHERS THEN
        lc_err_message := 'Error ->'||SQLERRM;
        x_message_data := x_message_data||lc_err_message;
        LOG_ERROR(p_exception => 'OTHERS'          --IN VARCHAR2
                 ,p_message   => lc_err_message    --IN VARCHAR2
                 );
   END;

      -------------------------------------------
      -- Compare incoming start date with sysdate
      -------------------------------------------

      IF TRUNC(P_Od_Price_List_Rec_Type.start_date_activel) >=  TRUNC(SYSDATE)
         AND P_Od_Price_List_Rec_Type.operationh = 'UPDATE' THEN

         lc_err_message := NULL;
         BEGIN

            --------------------------------------------------------------------------------------------------------------
            -- fetch list_line_id between start_date_active and end_date_active on the basis of incoming start_date_active
            --------------------------------------------------------------------------------------------------------------
            lc_err_message := NULL;
            BEGIN
               SELECT List_Line_Id,
                      end_date_active
               INTO   ln_strt_list_line_id,
                      ld_null_end_date_active
               FROM   qp_list_lines_v
               WHERE  list_header_id   = ln_list_header_id
               AND    product_attr_value =ln_inventory_item_id
               AND    TRUNC(P_Od_Price_List_Rec_Type.start_date_activel) BETWEEN start_date_active
               AND    NVL(end_date_active,TRUNC(P_Od_Price_List_Rec_Type.start_date_activel)+1);

               --------------------------------------------------------------------------------
               -- Update currently active record with start_date_active - 1 and create new line
               --------------------------------------------------------------------------------
               ln_new_index                                        := ln_new_index + 1;
               lt_price_list_line_tbl(ln_new_index).list_line_id   := ln_strt_list_line_id;
               lt_price_list_line_tbl(ln_new_index).end_date_active:= TRUNC(P_Od_Price_List_Rec_Type.start_date_activel)-1;
               lt_price_list_line_tbl(ln_new_index).operation      := qp_globals.g_opr_update;

            EXCEPTION

               WHEN NO_DATA_FOUND THEN
                    -- As per onsite comment not to log error in case of update just to continue the flow
                    NULL;
               WHEN OTHERS THEN
                    -- As per onsite comment not to log error in case of update just to continue the flow
                    NULL;
            END;

            IF TRUNC(P_Od_Price_List_Rec_Type.end_date_activel) IS NOT NULL THEN

               ------------------------------------------------------------------------------------------------------------
               -- fetch list_line_id between start_date_active and end_date_active on the basis of incoming end_date_active
               ------------------------------------------------------------------------------------------------------------
               lc_err_message := NULL;
               BEGIN

                  SELECT List_Line_Id
                  INTO   ln_end_list_line_id
                  FROM   qp_list_lines_v
                  WHERE  list_header_id = ln_list_header_id
                  AND    product_attr_value =ln_inventory_item_id
                  AND    TRUNC(P_Od_Price_List_Rec_Type.end_date_activel) BETWEEN start_date_active
                  AND    NVL(end_date_active,TRUNC(P_Od_Price_List_Rec_Type.end_date_activel+1));

                  IF ln_strt_list_line_id <> ln_end_list_line_id THEN

                     --------------------------------------------------------------------
                     -- Update future record with end_date_active + 1 and create new line
                     --------------------------------------------------------------------
                     ln_new_index                                           := ln_new_index + 1;
                     lt_price_list_line_tbl(ln_new_index).list_line_id      := ln_end_list_line_id;
                     lt_price_list_line_tbl(ln_new_index).start_date_active := TRUNC(P_Od_Price_List_Rec_Type.end_date_activel+1);
                     lt_price_list_line_tbl(ln_new_index).operation         := qp_globals.g_opr_update;

                  ELSE

                    lb_copy_flag := TRUE; -- for Copying line
                    ---------------------------
                    -- for Copying line PLL/PBH
                    ---------------------------
                    OPEN   lcu_futr_line (ln_end_list_line_id);
                    FETCH  lcu_futr_line INTO lr_lcu_futr_line;
                    CLOSE  lcu_futr_line;
                    
                    IF P_Od_Price_List_Rec_Type.multi_unit1 IS NOT NULL THEN
                       
                       -- Price Break lines
                       OPEN   lcu_copy_pbh_line (ln_strt_list_line_id );
                       FETCH  lcu_copy_pbh_line BULK COLLECT INTO lt_lcu_copy_pbh_line;
                       CLOSE  lcu_copy_pbh_line;
                       
                    END IF;
                    
                 END IF;

               EXCEPTION

                  WHEN NO_DATA_FOUND THEN
                       -- As per onsite comment not to log error in case of update just to continue the flow
                       NULL;
                   WHEN OTHERS THEN
                       -- As per onsite comment not to log error in case of update just to continue the flow
                       NULL;
               END;
            END IF;

            --------------------------------------------------------------------
            -- API call to Create/Update Price List Header, Lines and Attributes
            --------------------------------------------------------------------
            lc_err_message := NULL;
            QP_PRICE_LIST_PUB.Process_Price_List
                 (
                   p_api_version_number       => 1
                 , p_init_msg_list            => fnd_api.g_true
                 , p_return_values            => fnd_api.g_false
                 , p_commit                   => fnd_api.g_true
                 , x_return_status            => lc_return_status
                 , x_msg_count                => ln_msg_count
                 , x_msg_data                 => lc_msg_data
                 , p_price_list_rec           => lr_price_list_rec
                 , p_price_list_line_tbl      => lt_price_list_line_tbl
                 , p_qualifiers_tbl           => lt_qualifiers_tbl
                 , p_pricing_attr_tbl         => lt_pricing_attr_tbl
                 , x_price_list_rec           => lx_price_list_rec
                 , x_price_list_val_rec       => lx_price_list_val_rec
                 , x_price_list_line_tbl      => lx_price_list_line_tbl
                 , x_price_list_line_val_tbl  => lx_price_list_line_val_tbl
                 , x_qualifiers_tbl           => lx_qualifiers_tbl
                 , x_qualifiers_val_tbl       => lx_qualifiers_val_tbl
                 , x_pricing_attr_tbl         => lx_pricing_attr_tbl
                 , x_pricing_attr_val_tbl     => lx_pricing_attr_val_tbl
                 );

            ln_new_index := 0;
            lt_price_list_line_tbl.delete;

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               IF ln_msg_count > 0 THEN
                  FOR counter IN 1..ln_msg_count
                  LOOP
                     IF counter = 1 THEN
                        lc_err_message := FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                     ELSE
                        lc_err_message := lc_err_message||' - '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                     END IF;
                  END LOOP;
                  x_message_data := SUBSTR(x_message_data||lc_err_message,1,4000);

                  fnd_msg_pub.delete_msg;
                  LOG_ERROR(p_exception => 'API ERROR'     --IN VARCHAR2
                           ,p_message   => lc_err_message  --IN VARCHAR2
                           );
               END IF;
            END IF;
            COMMIT;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 -- As per onsite comment not to log error in case of update
                 NULL;
            WHEN OTHERS THEN
                 -- As per onsite comment not to log error in case of update
                 NULL;
         END;
      END IF; -- UPDATE and SYSDATE

     ----------------------------
     --Create new Price List line
     ----------------------------
     IF (lb_create_rec_flag) THEN

        ln_new_index := ln_new_index + 1;

        IF P_Od_Price_List_Rec_Type.multi_unit1 IS NULL THEN
           -----------------------
           -- Price List Line(PLL)
           -----------------------
           -- Price List Line
           lt_price_list_line_tbl(ln_new_index).list_header_id      := fnd_api.g_miss_num;
           lt_price_list_line_tbl(ln_new_index).list_line_id        := fnd_api.g_miss_num;
           lt_price_list_line_tbl(ln_new_index).list_line_type_code := 'PLL';
           lt_price_list_line_tbl(ln_new_index).operand             := P_Od_Price_List_Rec_Type.Operand;
           lt_price_list_line_tbl(ln_new_index).arithmetic_operator := 'UNIT_PRICE';
           lt_price_list_line_tbl(ln_new_index).start_date_active   := TRUNC(P_Od_Price_List_Rec_Type.start_date_activel);
           lt_price_list_line_tbl(ln_new_index).end_date_active     := TRUNC(NVL(P_Od_Price_List_Rec_Type.end_date_activel,ld_null_end_date_active));
           lt_price_list_line_tbl(ln_new_index).product_precedence  := P_Od_Price_List_Rec_Type.product_precedence;
           lt_price_list_line_tbl(ln_new_index).price_by_formula_id := P_Od_Price_List_Rec_Type.price_by_formula_id;
           lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_create;

           -- Price List Line Attributes
           lt_pricing_attr_tbl(ln_pbh).List_Line_Id                 := fnd_api.g_miss_num;
           lt_pricing_attr_tbl(ln_pbh).Pricing_Attribute_Id         := fnd_api.g_miss_num;
           lt_pricing_attr_tbl(ln_pbh).creation_date                := NVL(TRUNC(P_Od_Price_List_Rec_Type.creation_date),TRUNC(SYSDATE));
           lt_pricing_attr_tbl(ln_pbh).product_attribute_context    := 'ITEM';
           lt_pricing_attr_tbl(ln_pbh).Product_Attribute            := 'PRICING_ATTRIBUTE1';
           lt_pricing_attr_tbl(ln_pbh).product_attr_value           := ln_inventory_item_id;
           lt_pricing_attr_tbl(ln_pbh).product_uom_code             := P_Od_Price_List_Rec_Type.product_uom_code;
           lt_pricing_attr_tbl(ln_pbh).price_list_line_index        := ln_new_index;
           lt_pricing_attr_tbl(ln_pbh).attribute_grouping_no        := 1;
           lt_pricing_attr_tbl(ln_pbh).excluder_flag                := 'N';
           lt_pricing_attr_tbl(ln_pbh).operation                    := qp_globals.g_opr_create;


        ELSE

           --------------------------
           -- Price Break Header(PBH)
           --------------------------
           -- Price List Line
           lt_price_list_line_tbl(ln_new_index).list_header_id        := fnd_api.g_miss_num;
           lt_price_list_line_tbl(ln_new_index).list_line_id          := fnd_api.g_miss_num;
           lt_price_list_line_tbl(ln_new_index).list_line_type_code   := 'PBH';
           lt_price_list_line_tbl(ln_new_index).arithmetic_operator   := 'UNIT_PRICE';
           lt_price_list_line_tbl(ln_new_index).price_break_type_code := 'POINT';
           lt_price_list_line_tbl(ln_new_index).operation             := qp_globals.g_opr_create;
           lt_price_list_line_tbl(ln_new_index).product_precedence    := P_Od_Price_List_Rec_Type.product_precedence;
           lt_price_list_line_tbl(ln_new_index).start_date_active     := TRUNC(P_Od_Price_List_Rec_Type.start_date_activel);
           lt_price_list_line_tbl(ln_new_index).end_date_active       := TRUNC(NVL(P_Od_Price_List_Rec_Type.end_date_activel,ld_null_end_date_active));
           lt_price_list_line_tbl(ln_new_index).price_by_formula_id   := P_Od_Price_List_Rec_Type.price_by_formula_id;

           -- Price List Line Attributes
           lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id           := fnd_api.g_miss_num;
           lt_pricing_attr_tbl(ln_pbh).list_line_id                   := fnd_api.g_miss_num;
           lt_pricing_attr_tbl(ln_pbh).creation_date                  := NVL(TRUNC(P_Od_Price_List_Rec_Type.creation_date),TRUNC(SYSDATE));
           lt_pricing_attr_tbl(ln_pbh).product_attribute_context      := 'ITEM';
           lt_pricing_attr_tbl(ln_pbh).product_attribute              := 'PRICING_ATTRIBUTE1';
           lt_pricing_attr_tbl(ln_pbh).product_attr_value             := ln_inventory_item_id;
           lt_pricing_attr_tbl(ln_pbh).product_uom_code               := P_Od_Price_List_Rec_Type.product_uom_code;
           lt_pricing_attr_tbl(ln_pbh).price_list_line_index          := ln_new_index;
           lt_pricing_attr_tbl(ln_pbh).operation                      := qp_globals.g_opr_create;

       --------------------
       -- Price Break Lines
       --------------------
        FOR counter IN 1..1
        LOOP

           IF P_Od_Price_List_Rec_Type.multi_unit1 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;

              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.Operand;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := '1';
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit1-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit2 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl1;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit1;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := qp_globals.g_opr_create;

              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit2 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl1;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit1;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit2-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := qp_globals.g_opr_create;

              IF P_Od_Price_List_Rec_Type.multi_unit3 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl2;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit2;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit3 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl2;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit2;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit3-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit4 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl3;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit3;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit4 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl3;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit3;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit4-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit5 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl4;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit4;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit5 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl4;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit4;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit5-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit6 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit5;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit6 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit5;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit6-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit7 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl6;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit6;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit7 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl6;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit6;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit7-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit8 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl7;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit7;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit8 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl7;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit7;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit8-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit9 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl8;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit8;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit9 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl8;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit8;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit9-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit10 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl9;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit9;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit10 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl9;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit9;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit10-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit11 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl10;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit10;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit11 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl10;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit10;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit11-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit12 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl11;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit11;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit12 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl11;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit11;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit12-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit13 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl12;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit12;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit13 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl12;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit12;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit13-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit14 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl13;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit13;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit14 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl13;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit13;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit14-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit15 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl14;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit14;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit15 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl14;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit14;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit15-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              IF P_Od_Price_List_Rec_Type.multi_unit16 IS NULL THEN
                 lb_pbh_flag  := TRUE;
                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl5;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit15;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
              END IF;

              IF (lb_pbh_flag) THEN
                 EXIT;
              END IF;

           END IF;

           IF P_Od_Price_List_Rec_Type.multi_unit16 IS NOT NULL THEN
              ln_new_index := ln_new_index + 1;
              --Create a Price List Line of type 'PLL', a child price break line
              lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
              lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
              lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
              lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl15;
              lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
              lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
              lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

              ln_pbh := ln_pbh + 1;
              -- record for Price List Line of type 'PLL' which is a child Price Break Line
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
              lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
              lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
              lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
              lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
              lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit15;
              lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := P_Od_Price_List_Rec_Type.multi_unit16-1;
              lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
              lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
              lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
              lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;


                 ln_new_index := ln_new_index + 1;
                 --Create a Price List Line of type 'PLL', a child price break line
                 lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
                 lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
                 lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
                 lt_price_list_line_tbl(ln_new_index).operand                 := P_Od_Price_List_Rec_Type.multi_unit_rtl16;
                 lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
                 lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
                 lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;

                 ln_pbh := ln_pbh + 1;
                 -- record for Price List Line of type 'PLL' which is a child Price Break Line
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
                 lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                 lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
                 lt_pricing_attr_tbl(ln_pbh).product_attr_value       := ln_inventory_item_id;
                 lt_pricing_attr_tbl(ln_pbh).product_uom_code         := P_Od_Price_List_Rec_Type.product_uom_code;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
                 lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := P_Od_Price_List_Rec_Type.multi_unit16;
                 lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := '999999999999';
                 lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
                 lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                 lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                 lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;

              END IF;
           END LOOP;
        END IF;
     END IF;
     ---------------------
     -- Create copied line
     ---------------------
     IF (lb_copy_flag) THEN

             ln_new_index := ln_new_index + 1;
             ----------
             -- For PLL
             ----------
             IF lr_lcu_futr_line.list_line_type_code = 'PLL'  THEN
                -- Price List Line
                lt_price_list_line_tbl(ln_new_index).list_header_id      := fnd_api.g_miss_num;
                lt_price_list_line_tbl(ln_new_index).list_line_id        := fnd_api.g_miss_num;
                lt_price_list_line_tbl(ln_new_index).list_line_type_code := 'PLL';
                lt_price_list_line_tbl(ln_new_index).operand             := lr_lcu_futr_line.Operand;
                lt_price_list_line_tbl(ln_new_index).arithmetic_operator := 'UNIT_PRICE';
                lt_price_list_line_tbl(ln_new_index).start_date_active   := TRUNC(P_Od_Price_List_Rec_Type.end_date_activel)+1;
                lt_price_list_line_tbl(ln_new_index).end_date_active     := TRUNC(lr_lcu_futr_line.end_date_active);
                lt_price_list_line_tbl(ln_new_index).product_precedence  := lr_lcu_futr_line.product_precedence;
                lt_price_list_line_tbl(ln_new_index).price_by_formula_id := lr_lcu_futr_line.price_by_formula_id;
                lt_price_list_line_tbl(ln_new_index).operation           := qp_globals.g_opr_create;

                ln_pbh := ln_pbh + 1;
                -- Price List Line Attributes
                lt_pricing_attr_tbl(ln_pbh).List_Line_Id             := fnd_api.g_miss_num;
                lt_pricing_attr_tbl(ln_pbh).Pricing_Attribute_Id     := fnd_api.g_miss_num;
                lt_pricing_attr_tbl(ln_pbh).creation_date            := NVL(TRUNC(P_Od_Price_List_Rec_Type.creation_date),TRUNC(SYSDATE));
                lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
                lt_pricing_attr_tbl(ln_pbh).Product_Attribute        := 'PRICING_ATTRIBUTE1';
                lt_pricing_attr_tbl(ln_pbh).product_attr_value       := lr_lcu_futr_line.product_attr_value;
                lt_pricing_attr_tbl(ln_pbh).product_uom_code         := lr_lcu_futr_line.product_uom_code;
                lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
                lt_pricing_attr_tbl(ln_pbh).attribute_grouping_no    := 1;
                lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
                lt_pricing_attr_tbl(ln_pbh).operation                := qp_globals.g_opr_create;

            ELSE
                lb_pbh_copy_flag :=TRUE;
                
            END IF;
        END IF;
  END IF; -- Operation Create

  ----------------------------------------------------------------------------------------------------------------------------------------
  -- Price List Line Operation = Delete for deleting future record and updating end date of privious record with end date of future record
  ----------------------------------------------------------------------------------------------------------------------------------------
  IF P_Od_Price_List_Rec_Type.operationl = 'DELETE' THEN

     ----------------------------------------------
     -- Check start date of new record with sysdate
     ----------------------------------------------
     IF TRUNC(P_Od_Price_List_Rec_Type.start_date_activel) >  TRUNC(SYSDATE) THEN
        lc_err_message := NULL;
        BEGIN
           ---------------------------------------------------
           -- Fetch list_line_id and end_date of future record
           ---------------------------------------------------

           SELECT List_Line_Id
                  ,end_date_active
           INTO    ln_dl_List_Line_Id
                  ,ld_dl_end_date_active
           FROM  qp_list_lines_v
           WHERE TRUNC(start_date_active) = TRUNC(P_Od_Price_List_Rec_Type.start_date_activel)
           AND  product_attr_value        = ln_inventory_item_id
           AND list_header_id             = ln_list_header_id;

           -------------------------
           -- Delete the future line
           -------------------------
           lt_price_list_line_tbl(ln_del_index).list_header_id        := ln_list_header_id;
           lt_price_list_line_tbl(ln_del_index).list_line_id          := ln_dl_List_Line_Id;
           lt_price_list_line_tbl(ln_del_index).operation             := qp_globals.g_opr_delete;

           ---------------------------------------------------------------------------------
           -- Select list_line_id of privious line and update with future record end date
           ---------------------------------------------------------------------------------
           FOR prv IN lcu_prvs_list_line (ln_inventory_item_id,
                                          ln_dl_List_Line_Id,
                                          P_Od_Price_List_Rec_Type.start_date_activel)
           LOOP

              IF lcu_prvs_list_line%ROWCOUNT = 1 THEN

                 ln_pr_list_line_id := prv.list_line_id;

              END IF;
              EXIT;

           END LOOP;

           ln_del_index:=ln_del_index+1;
           -------------------------------------------------------------------------------
           -- Update end_date_active of privious line with deleting record end_date_active
           -------------------------------------------------------------------------------
           lt_price_list_line_tbl(ln_del_index).list_header_id        := ln_list_header_id;
           lt_price_list_line_tbl(ln_del_index).list_line_id          := ln_pr_list_line_id;
           lt_price_list_line_tbl(ln_del_index).end_date_active       := TRUNC(ld_dl_end_date_active);
           lt_price_list_line_tbl(ln_del_index).operation             := qp_globals.g_opr_update;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

               lc_err_message := 'Item '||P_Od_Price_List_Rec_Type.product_attr_value||'to be deleted not existing on PriceList: '||P_Od_Price_List_Rec_Type.name||'. Oracle error: '||SQLERRM;
               x_message_data := x_message_data||lc_err_message;
               LOG_ERROR(p_exception => 'NO_DATA_FOUND'   --IN VARCHAR2
                        ,p_message   => lc_err_message    --IN VARCHAR2
                        );
               RETURN;
            WHEN OTHERS THEN
               lc_err_message := 'Error -> '||SQLERRM;
               x_message_data := x_message_data||lc_err_message;
               LOG_ERROR(p_exception => 'OTHERS'          --IN VARCHAR2
                        ,p_message   => lc_err_message    --IN VARCHAR2
                        );
                RETURN;

          END;
       END IF;
    END IF;

  EXCEPTION

     WHEN NO_DATA_FOUND THEN
        lc_err_message := 'Error -> '||SQLERRM;
        x_message_data := x_message_data||lc_err_message;
        LOG_ERROR(p_exception => 'NO_DATA_FOUND'   --IN VARCHAR2
                 ,p_message   => lc_err_message    --IN VARCHAR2
                 );

     WHEN OTHERS THEN
        lc_err_message := 'Error -> '||SQLERRM;
        x_message_data := x_message_data||lc_err_message;
        LOG_ERROR(p_exception => 'OTHERS'          --IN VARCHAR2
                 ,p_message   => lc_err_message    --IN VARCHAR2
                 );

   END;

   --------------------------------------------------------------------
   -- API call to Create/Update Price List Header, Lines and Attributes
   --------------------------------------------------------------------
   lc_err_message := NULL;
   QP_PRICE_LIST_PUB.Process_Price_List
                (
                  p_api_version_number       => 1
                , p_init_msg_list            => fnd_api.g_true
                , p_return_values            => fnd_api.g_false
                , p_commit                   => fnd_api.g_true
                , x_return_status            => lc_return_status
                , x_msg_count                => ln_msg_count
                , x_msg_data                 => lc_msg_data
                , p_price_list_rec           => lr_price_list_rec
                , p_price_list_line_tbl      => lt_price_list_line_tbl
                , p_qualifiers_tbl           => lt_qualifiers_tbl
                , p_pricing_attr_tbl         => lt_pricing_attr_tbl
                , x_price_list_rec           => lx_price_list_rec
                , x_price_list_val_rec       => lx_price_list_val_rec
                , x_price_list_line_tbl      => lx_price_list_line_tbl
                , x_price_list_line_val_tbl  => lx_price_list_line_val_tbl
                , x_qualifiers_tbl           => lx_qualifiers_tbl
                , x_qualifiers_val_tbl       => lx_qualifiers_val_tbl
                , x_pricing_attr_tbl         => lx_pricing_attr_tbl
                , x_pricing_attr_val_tbl     => lx_pricing_attr_val_tbl
                );

                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                   IF ln_msg_count > 0 THEN
                      FOR counter IN 1..ln_msg_count
                      LOOP
                         IF counter = 1 THEN
                            lc_err_message := FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                         ELSE
                            lc_err_message := lc_err_message||' - '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                         END IF;
                      END LOOP;
                      x_message_data := SUBSTR(x_message_data||lc_err_message,1,4000);

                      IF P_Od_Price_List_Rec_Type.operationl = 'DELETE' THEN

                         RAISE EX_DELETION;

                      ELSE

                      LOG_ERROR(p_exception => 'API Error'
                               ,p_message   => x_message_data
                               );
                      END IF;

                   END IF;
                ELSE
                   x_message_data := 'Successfully completed';
                END IF;
              COMMIT;

   END IF; -- For PL Name - UOM_CHANGE

   ---------------------
   -- Create copied line
   ---------------------

   IF (lb_pbh_copy_flag) THEN
      ln_new_index := 0;
      ln_new_index := ln_new_index + 1;
      
      ln_pbh := 0;
      ln_pbh := ln_pbh+1;

      IF lr_lcu_futr_line.list_line_type_code = 'PBH'  THEN

         ----------
         -- For PBH
         ----------
         lt_price_list_line_tbl(ln_new_index).list_header_id        := fnd_api.g_miss_num;
         lt_price_list_line_tbl(ln_new_index).list_line_id          := fnd_api.g_miss_num;
         lt_price_list_line_tbl(ln_new_index).list_line_type_code   := 'PBH';
         lt_price_list_line_tbl(ln_new_index).price_break_type_code := 'POINT';
         lt_price_list_line_tbl(ln_new_index).product_precedence    := lr_lcu_futr_line.product_precedence;
         lt_price_list_line_tbl(ln_new_index).operation             := qp_globals.g_opr_create;
         lt_price_list_line_tbl(ln_new_index).start_date_active     := TRUNC(P_Od_Price_List_Rec_Type.end_date_activel)+1;
         lt_price_list_line_tbl(ln_new_index).end_date_active       := TRUNC(lr_lcu_futr_line.end_date_active);
         lt_price_list_line_tbl(ln_new_index).price_by_formula_id   := lr_lcu_futr_line.price_by_formula_id;
         lt_price_list_line_tbl(ln_new_index).arithmetic_operator   := 'UNIT_PRICE';
         
         -- Price List Line Attributes ie product information
         lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id           := fnd_api.g_miss_num;
         lt_pricing_attr_tbl(ln_pbh).list_line_id                   := fnd_api.g_miss_num;
         lt_pricing_attr_tbl(ln_pbh).product_attribute_context      := 'ITEM';
         lt_pricing_attr_tbl(ln_pbh).product_attribute              := 'PRICING_ATTRIBUTE1';
         lt_pricing_attr_tbl(ln_pbh).product_attr_value             := lr_lcu_futr_line.product_attr_value;
         lt_pricing_attr_tbl(ln_pbh).product_uom_code               := lr_lcu_futr_line.product_uom_code;
         lt_pricing_attr_tbl(ln_pbh).price_list_line_index          := ln_new_index;
         lt_pricing_attr_tbl(ln_pbh).creation_date                  := NVL(TRUNC(P_Od_Price_List_Rec_Type.creation_date),TRUNC(SYSDATE));
         lt_pricing_attr_tbl(ln_pbh).operation                      := qp_globals.g_opr_create;
         
         FOR j IN 1..lt_lcu_copy_pbh_line.COUNT 
         LOOP
         
            ln_new_index := ln_new_index + 1;
            --Create a Price List Line of type 'PLL', a child price break line
            lt_price_list_line_tbl(ln_new_index).list_line_id            := fnd_api.g_miss_num;
            lt_price_list_line_tbl(ln_new_index).list_line_type_code     := 'PLL';
            lt_price_list_line_tbl(ln_new_index).operation               := qp_globals.g_opr_create;
            lt_price_list_line_tbl(ln_new_index).operand                 := lt_lcu_copy_pbh_line(j).operand;
            lt_price_list_line_tbl(ln_new_index).arithmetic_operator     := 'UNIT_PRICE';
            lt_price_list_line_tbl(ln_new_index).rltd_modifier_group_no  := 1;
            lt_price_list_line_tbl(ln_new_index).price_break_header_index:= 1;
   
            ln_pbh := ln_pbh + 1;
            -- record for Price List Line of type 'PLL' which is a child Price Break Line
            lt_pricing_attr_tbl(ln_pbh).pricing_attribute_id     := fnd_api.g_miss_num;
            lt_pricing_attr_tbl(ln_pbh).list_line_id             := fnd_api.g_miss_num;
            lt_pricing_attr_tbl(ln_pbh).product_attribute_context:= 'ITEM';
            lt_pricing_attr_tbl(ln_pbh).product_attribute        := 'PRICING_ATTRIBUTE1';
            lt_pricing_attr_tbl(ln_pbh).product_attr_value       := lr_lcu_futr_line.product_attr_value;
            lt_pricing_attr_tbl(ln_pbh).product_uom_code         := lr_lcu_futr_line.product_uom_code;
            lt_pricing_attr_tbl(ln_pbh).pricing_attribute_context:= 'VOLUME';
            lt_pricing_attr_tbl(ln_pbh).pricing_attribute        := 'PRICING_ATTRIBUTE10'; --'Item Quantity'
            lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_from  := lt_lcu_copy_pbh_line(j).pricing_attr_value_from;
            lt_pricing_attr_tbl(ln_pbh).pricing_attr_value_to    := lt_lcu_copy_pbh_line(j).pricing_attr_value_to;
            lt_pricing_attr_tbl(ln_pbh).comparison_operator_code := 'BETWEEN';
            lt_pricing_attr_tbl(ln_pbh).excluder_flag            := 'N';
            lt_pricing_attr_tbl(ln_pbh).price_list_line_index    := ln_new_index;
            lt_pricing_attr_tbl(ln_pbh).operation                := QP_GLOBALS.G_OPR_CREATE;
           
         END LOOP;

     END IF;
     lc_err_message := NULL;
     --------------------------------------------------------------------
     -- API call to Create/Update Price List Header, Lines and Attributes
     --------------------------------------------------------------------
     QP_PRICE_LIST_PUB.Process_Price_List
              (
                p_api_version_number       => 1
              , p_init_msg_list            => fnd_api.g_true
              , p_return_values            => fnd_api.g_false
              , p_commit                   => fnd_api.g_true
              , x_return_status            => lc_return_status
              , x_msg_count                => ln_msg_count
              , x_msg_data                 => lc_msg_data
              , p_price_list_rec           => lr_price_list_rec
              , p_price_list_line_tbl      => lt_price_list_line_tbl
              , p_qualifiers_tbl           => lt_qualifiers_tbl
              , p_pricing_attr_tbl         => lt_pricing_attr_tbl
              , x_price_list_rec           => lx_price_list_rec
              , x_price_list_val_rec       => lx_price_list_val_rec
              , x_price_list_line_tbl      => lx_price_list_line_tbl
              , x_price_list_line_val_tbl  => lx_price_list_line_val_tbl
              , x_qualifiers_tbl           => lx_qualifiers_tbl
              , x_qualifiers_val_tbl       => lx_qualifiers_val_tbl
              , x_pricing_attr_tbl         => lx_pricing_attr_tbl
              , x_pricing_attr_val_tbl     => lx_pricing_attr_val_tbl
              );
             
             IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                IF ln_msg_count > 0 THEN
                   FOR counter IN 1..ln_msg_count
                   LOOP
                      IF counter = 1 THEN
                         lc_err_message := FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                      ELSE
                         lc_err_message := lc_err_message||' - '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                      END IF;
                   END LOOP;
                   x_message_data := SUBSTR(x_message_data||lc_err_message,1,4000);

                   LOG_ERROR(p_exception => 'API ERROR'     --IN VARCHAR2
                            ,p_message   => lc_err_message  --IN VARCHAR2
                            );

                END IF;
             END IF;
             COMMIT;
     END IF;

 EXCEPTION

    WHEN EX_PRICE_LIST_NOT_EXISTS THEN

       x_message_data := 'Error -> Invalid Price List name';
       LOG_ERROR(p_exception => 'EX_PRICE_LIST_NOT_EXISTS'
                ,p_message   => x_message_data
                );

    WHEN EX_INVENTORY_ITEM_ID THEN
       x_message_data := 'Error -> Invalid Item';
       LOG_ERROR(p_exception => 'EX_INVENTORY_ITEM_ID'
                ,p_message   => x_message_data
                );

    WHEN EX_DELETION THEN
       LOG_ERROR(p_exception => 'EX_DELETION'
                ,p_message   => x_message_data
                );

    WHEN OTHERS THEN
       x_message_data := 'Error -> '||SQLERRM;
       LOG_ERROR(p_exception => 'OTHERS'
                ,p_message   => x_message_data
                );

   END create_pricelist_main;
END XX_QP_PRICELIST_PKG;
/
SHOW ERROR;

EXIT;

-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------