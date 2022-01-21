SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_QP_MODIFIERS_PKG
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                            |
-- +========================================================================================+
-- | Name        :  XX_QP_MODIFIERS_PKG.pkb                                                 |
-- | Description :  This package is used to Create,update and Delete                        |
-- |                Price List.                                                             |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author           Remarks                                          |
-- |=======   ==========  =============    =================================================|
-- |Draft 1a  19-Apr-2007 Fajna K.P        Initial draft version                            |
-- |Draft 1b  19-Jul-2007 Madhukar Salunke Added LOG_ERROR procedure                        |
-- |                                       for EBS Error Handling                           | 
-- |Draft 1c  11-Jul-07   Fajna K.P        Added code for Line Level Qualifiers             | 
-- |Draft 1d  31-Jul-07   Fajna K.P        1.Added Qualifier Context to distinguish between |                  
-- |                                         the Header level and line level Qualifiers     |
-- |                                       2.Removed 'UPDATE' operation on Qualifiers       |
-- |                                       3.Removed Modifier Parent Index for lines other  |
-- |                                         than Discount Lines                            |
-- |                                       4.Removed Logic for Benefit/Qualifier Lines      |
-- |                                                                                        |
-- |Draft 1e  08-Aug-07   Fajna K.P        1.Defaulted Line and Qualiifer Start and End     |
-- |                                         dates from header start and end dates          |
-- |                                       2.Mapped Header and Line level DFF attributes    |
-- +========================================================================================+
IS
--+=============================================================================================================+
--| PROCEDURE  : create_modifier_main                                                                           |
--| P_modifier_header      IN    QP_MODIFIERS_PUB.modifier_list_rec_type      Modifier header details           |
--| P_modifier_lines       IN    QP_MODIFIERS_PUB.modifiers_tbl_type          Modifier lines details            |
--| P_modifier_attributes  IN    QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type   Modifier attribute details        |
--| P_modifier_qualifiers  IN    QP_MODIFIERS_PUB.pricing_attr_tbl_type       Modifier qualifier details        |
--| x_message_code         OUT   NUMBER                                                                         |
--| x_message_data         OUT   VARCHAR2                                                                       |
--+=============================================================================================================+

PROCEDURE create_modifier_main(
                               P_modifier_header_rec      IN    QP_MODIFIERS_PUB.modifier_list_rec_type,
                               P_modifier_lines_tbl       IN    QP_MODIFIERS_PUB.modifiers_tbl_type ,
                               P_modifier_attributes_tbl  IN    QP_MODIFIERS_PUB.Pricing_Attr_Tbl_Type,
                               P_modifier_qualifiers_tbl  IN    QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type,
                               --to add new parameter for operating unit
                               x_message_code             OUT   NUMBER,
                               x_message_data             OUT   VARCHAR2
                              )
IS
    -- Declare the IN parameters of the API QP_MODIFIERS_PUB.process_modifiers
    lr_modifier_list_rec            QP_MODIFIERS_PUB.modifier_list_rec_type         :=  QP_MODIFIERS_PUB.g_miss_modifier_list_rec;
    lr_modifier_list_val_rec        QP_MODIFIERS_PUB.modifier_list_val_rec_type     :=  QP_MODIFIERS_PUB.g_miss_modifier_list_val_rec;
    lt_modifiers_tbl                QP_MODIFIERS_PUB.modifiers_tbl_type             :=  QP_MODIFIERS_PUB.g_miss_modifiers_tbl;
    lt_modifiers_val_tbl            QP_MODIFIERS_PUB.modifiers_val_tbl_type         :=  QP_MODIFIERS_PUB.g_miss_modifiers_val_tbl;
    lr_qualifiers_rec_type          QP_QUALIFIER_RULES_PUB.qualifiers_rec_type      :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_rec;
    lt_qualifiers_tbl               QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type      :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_tbl;
    lt_qualifiers_val_tbl           QP_QUALIFIER_RULES_PUB.qualifiers_val_tbl_type  :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_val_tbl;
    lt_pricing_attr_tbl             QP_MODIFIERS_PUB.pricing_attr_tbl_type          :=  QP_MODIFIERS_PUB.g_miss_pricing_attr_tbl;
    lt_pricing_attr_val_tbl         QP_MODIFIERS_PUB.pricing_attr_val_tbl_type      :=  QP_MODIFIERS_PUB.g_miss_pricing_attr_val_tbl;

    -- Declare the OUT parameters for the API QP_MODIFIERS_PUB.process_modifiers
    x_modifier_list_rec             QP_MODIFIERS_PUB.modifier_list_rec_type         :=  QP_MODIFIERS_PUB.g_miss_modifier_list_rec;
    x_modifier_list_val_rec         QP_MODIFIERS_PUB.modifier_list_val_rec_type     :=  QP_MODIFIERS_PUB.g_miss_modifier_list_val_rec;
    x_modifiers_tbl                 QP_MODIFIERS_PUB.modifiers_tbl_type             :=  QP_MODIFIERS_PUB.g_miss_modifiers_tbl;
    x_modifiers_val_tbl             QP_MODIFIERS_PUB.modifiers_val_tbl_type         :=  QP_MODIFIERS_PUB.g_miss_modifiers_val_tbl;
    x_qualifiers_rec_type           QP_QUALIFIER_RULES_PUB.qualifiers_rec_type      :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_rec;
    x_qualifiers_tbl                QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type      :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_tbl;
    x_qualifiers_val_tbl            QP_QUALIFIER_RULES_PUB.qualifiers_val_tbl_type  :=  QP_QUALIFIER_RULES_PUB.g_miss_qualifiers_val_tbl;
    x_pricing_attr_tbl              QP_MODIFIERS_PUB.pricing_attr_tbl_type          :=  QP_MODIFIERS_PUB.g_miss_pricing_attr_tbl;
    x_pricing_attr_val_tbl          QP_MODIFIERS_PUB.pricing_attr_val_tbl_type      :=  QP_MODIFIERS_PUB.g_miss_pricing_attr_val_tbl;

    --Declare local variables
    ln_msg_count                   NUMBER;
    lc_return_status               VARCHAR2(1);
    lc_msg_data                    VARCHAR2(2500);
    lc_error_location              VARCHAR2(50);    
    ln_list_header_id              NUMBER;
    ln_list_line_id                NUMBER;
    ln_header_id                   NUMBER:=0;
    ln_line_id                     NUMBER:=0;
    ln_pricing_attribute_id        NUMBER:=0;
    ln_pa_id                       NUMBER:=0; 
    ln_qualifier_id                NUMBER:=0; 
    ln_qua_id                      NUMBER:=0; 
    ln_pricing_phase_id            NUMBER;
    ln_qualifier_headerid          NUMBER:=0;  
    ln_qualifier_lineid            NUMBER:=0;  
    lc_adjline_name                VARCHAR2(100);
    lc_header_operation            VARCHAR2(50);
    lc_line_operation              VARCHAR2(50);
    lc_pa_operation                VARCHAR2(50);
    lc_qual_operation              VARCHAR2(50);
    lc_err_message                 VARCHAR2(2500) := NULL;   
    ln_inventory_item_id           VARCHAR2(30)   := NULL;
    ln_benefit_price_list_line_id  NUMBER         := 0;
    ln_r_operand                   NUMBER         := 0;
    ln_sum_operand                 NUMBER         := 0;
    ln_q_operand                   NUMBER         := 0;
    ln_get_operand_value           NUMBER         := 0;
    ln_line_index                  NUMBER         := 0;
    ln_pa_index                    NUMBER         := 0;      
    ln_qua_index                   NUMBER         := 0;    
    lb_type_flag                   BOOLEAN        := FALSE;
    ln_initial_parent_index        NUMBER         := 1;    
    ln_qua_ben_line                VARCHAR2(1)    := 'N';
    ln_current_line_index          NUMBER         := 0; 
    ln_older_line_index            NUMBER         := 0; 
    lc_data                        VARCHAR2(2000);
    ln_count                       NUMBER  ;
    lc_status                      VARCHAR2(1000);

    EX_MODIFIER_ERROR              EXCEPTION;
    
    -----------------------------------------------
    --To fetch list_header_id for existing Modifier 
    -----------------------------------------------
    CURSOR lcu_headerid (p_name IN VARCHAR2)
    IS
    SELECT QLH.list_header_id
    FROM   qp_list_headers QLH
    WHERE  UPPER(QLH.name) = UPPER(p_name);

    ------------------------------------------------------
    --To fetch list_line_id for existing Modifier and line
    ------------------------------------------------------
    CURSOR lcu_lineid(p_headerid    IN NUMBER, 
                      p_attribute7  IN VARCHAR2) 
    IS
    SELECT QLL.list_line_id
    FROM   qp_list_lines QLL
    WHERE  QLL.attribute7      = p_attribute7
    AND    QLL.list_header_id  = p_headerid;

    ----------------------------------------------
    --To derive inventory item Id and Validate UOM
    ----------------------------------------------
    CURSOR lcu_item(p_uom_code      IN VARCHAR2,
                    p_attr_value    IN VARCHAR2)
    IS
    SELECT MSI.inventory_item_id 
    FROM   mtl_system_items_b MSI
          ,mtl_parameters MP
    WHERE  MP.organization_id         = MP.master_organization_id
    AND    MP.master_organization_id  = MSI.organization_id
    AND    MSI.primary_uom_code       = p_uom_code
    AND    MSI.segment1               = p_attr_value;

    ---------------------------------------------------
    --To derive the Benefit List line id from 'ZONE_74'
    ---------------------------------------------------
    /*CURSOR lcu_benefit_list_line(p_inventory_item_id IN VARCHAR2)
    IS
    SELECT QLL.list_line_id
    FROM   qp_list_headers_tl QLHT
          ,qp_list_headers_b QLH
          ,qp_list_lines QLL
          ,qp_pricing_attributes QPA
    WHERE  QLHT.list_header_id     = QLH.list_header_id
    AND    QLH.list_header_id      = QLL.list_header_id
    AND    QLL.list_line_id        = QPA.list_line_id
    AND    UPPER(QLHT.name)        = UPPER('ZONE_74')
    AND    QPA.product_Attr_value  = p_inventory_item_id;*/

    -----------------------------------------
    --To derive the Unit Price from 'ZONE_71'
    -----------------------------------------
    CURSOR lcu_operand(p_inventory_item_id IN VARCHAR2)
    IS
    SELECT QLL.operand
    FROM   qp_list_headers_tl QLHT
          ,qp_list_headers_b QLH
          ,qp_list_lines QLL
          ,qp_pricing_attributes QPA
    WHERE  QLHT.list_header_id    = QLH.list_header_id
    AND    QLH.list_header_id     = QLL.list_header_id
    AND    QLL.list_line_id       = QPA.list_line_id
    AND    UPPER(QLHT.name)       = UPPER('ZONE_71')
    AND    QPA.product_Attr_value = p_inventory_item_id;

    --------------------------------
    --To derive the Pricing Phase Id 
    --------------------------------
    CURSOR lcu_phaseid(p_level_code IN VARCHAR2,
                       p_adj_name   IN VARCHAR2)
    IS
    SELECT QPP.pricing_phase_id 
    FROM   qp_pricing_phases QPP
    WHERE  QPP.Modifier_level_code         = p_level_code 
    AND    UPPER(QPP.incompat_resolve_code)= 'BEST_PRICE'
    AND    UPPER(QPP.name)=UPPER(p_adj_name);
    
    
    -------------------------------------------------------------------------
    --To derive the List Header id and List Line Id for Line Level Qualifier
    -------------------------------------------------------------------------
    CURSOR lcu_header_line_id(p_attribute7 IN VARCHAR2,
                              p_header     IN VARCHAR)
    IS    
    SELECT QLL.list_line_id
          ,QLL.list_header_id
    FROM   qp_list_lines QLL
    WHERE  QLL.attribute7=p_attribute7
    AND    QLL.list_header_id   IN 
                                (SELECT QLHT.list_header_id
                                 FROM qp_list_headers_tl QLHT
                                 WHERE UPPER(QLHT.name)=UPPER(p_header));

BEGIN
    BEGIN
    -----------------
    -- Default values
    -----------------
    lr_modifier_list_rec    :=  x_modifier_list_rec;
    lt_modifiers_tbl        :=  x_modifiers_tbl; 
    lr_qualifiers_rec_type  :=  x_qualifiers_rec_type;
    lt_qualifiers_tbl       :=  x_qualifiers_tbl;  
    lt_pricing_attr_tbl     :=  x_pricing_attr_tbl;  
    
    -----------------------------------------------------------
    --START OF HEADER CREATION/UPDATION
    -----------------------------------------------------------
    ----------------------------------
    -- Setting Header Level Operation
    ----------------------------------
    IF (P_modifier_header_rec.operation = 'CREATE') THEN      
      lc_header_operation := qp_globals.g_opr_create;
    ELSIF (P_modifier_header_rec.operation = 'UPDATE') OR (P_modifier_header_rec.operation = 'DELETE') THEN      
      lc_header_operation := qp_globals.g_opr_update;
      ln_list_header_id:=NULL;
      OPEN lcu_headerid(P_modifier_header_rec.name);
      FETCH lcu_headerid INTO ln_list_header_id;
         IF lcu_headerid%NOTFOUND THEN
            x_message_data    := 'Invalid Modfier Name ';
            lc_error_location := 'INVALID_MODIFIER_NAME';
            RAISE EX_MODIFIER_ERROR;
         END IF;
      CLOSE lcu_headerid;
      
    END IF;
 
    -------------------------------------------------------------------------------------
    -- Decoding list_header_id for creating new Modifier or updating or deleting Modifier
    -------------------------------------------------------------------------------------
    SELECT DECODE(P_modifier_header_rec.operation,'CREATE',fnd_api.g_miss_num,ln_list_header_id)
    INTO ln_header_id
    FROM dual;

    ---------------------------
    -- Header Create or Update
    ---------------------------
    IF (P_modifier_header_rec.operation = 'CREATE') OR (P_modifier_header_rec.operation = 'UPDATE') THEN  
        lr_modifier_list_rec.list_header_id     := ln_header_id;
        lr_modifier_list_rec.operation          := lc_header_operation;
        lr_modifier_list_rec.start_date_active  := TRUNC(P_modifier_header_rec.start_date_active);
        lr_modifier_list_rec.end_date_active    := TRUNC(P_modifier_header_rec.end_date_active);
        lr_modifier_list_rec.name               := P_modifier_header_rec.name;
        lr_modifier_list_rec.description        := P_modifier_header_rec.description;
        lr_modifier_list_rec.automatic_flag     := P_modifier_header_rec.automatic_flag;
        lr_modifier_list_rec.currency_code      := P_modifier_header_rec.currency_code;
        lr_modifier_list_rec.list_type_code     := 'PRO';
        lr_modifier_list_rec.pte_code           := 'ORDFUL';
        lr_modifier_list_rec.source_system_code := 'QP';
        lr_modifier_list_rec.ask_for_flag       := P_modifier_header_rec.ask_for_flag;
        lr_modifier_list_rec.comments           := P_modifier_header_rec.comments;
        lr_modifier_list_rec.context            :='Promotional  Attributes';
        
        --Added by Fajna on 08-Aug-07 START
        lr_modifier_list_rec.attribute4         := P_modifier_header_rec.attribute4;
        lr_modifier_list_rec.attribute5         := P_modifier_header_rec.attribute5;
        --Added by Fajna on 08-Aug-07 END
        
        lr_modifier_list_rec.attribute8         := P_modifier_header_rec.attribute8;
        lr_modifier_list_rec.attribute10        := P_modifier_header_rec.attribute10;
        lr_modifier_list_rec.attribute11        := P_modifier_header_rec.attribute11;
        lr_modifier_list_rec.attribute12        := P_modifier_header_rec.attribute12;
        lr_modifier_list_rec.attribute13        := P_modifier_header_rec.attribute13;
        lr_modifier_list_rec.attribute14        := P_modifier_header_rec.attribute14;
        
        --Added by Fajna on 08-Aug-07 START
        lr_modifier_list_rec.attribute15        := P_modifier_header_rec.attribute15;
        --Added by Fajna on 08-Aug-07 END
        
        --Added by Fajna on 30-jul-07 START
        IF (P_modifier_header_rec.end_date_active IS NULL OR  P_modifier_header_rec.end_date_active > SYSDATE) THEN
            lr_modifier_list_rec.active_flag  :=  'Y';
        ELSE
            lr_modifier_list_rec.active_flag :=  'N';
        END IF;
        --lr_modifier_list_rec.active_flag        := P_modifier_header_rec.active_flag;      
        --Added by Fajna on 30-jul-07 END
        
        lr_modifier_list_rec.global_flag        := P_modifier_header_rec.global_flag;
        lr_modifier_list_rec.created_by         := fnd_global.user_id;
        lr_modifier_list_rec.creation_date      := TRUNC(SYSDATE);
        lr_modifier_list_rec.last_updated_by    := fnd_global.user_id;
        lr_modifier_list_rec.last_update_date   := TRUNC(SYSDATE);
        lr_modifier_list_rec.last_update_login  := fnd_global.user_id;
       
        ----------------------------------------------------------------------------
        -- For TYPE '2A' Calculate the operand value to get distributed among lines
        ----------------------------------------------------------------------------
        IF (P_modifier_header_rec.attribute12 in ('2A') AND P_modifier_header_rec.attribute10 > 1 AND P_modifier_header_rec.operation = 'CREATE') THEN
            lb_type_flag := TRUE;
            FOR i IN 1..P_modifier_lines_tbl.count
            LOOP
                --------------------------
                -- Validatin Item and UOM
                --------------------------
                --Modified by Fajna on 08-Aug-07 START                
                --IF P_modifier_lines_tbl(i).attribute9='Q' THEN
                IF P_modifier_lines_tbl(i).attribute9='Buy' THEN
                --Modified by Fajna on 08-Aug-07 END
                
                    OPEN lcu_item(P_modifier_attributes_tbl(i).product_uom_code,P_modifier_attributes_tbl(i).product_attr_value);
                    FETCH lcu_item INTO ln_inventory_item_id;
                    IF lcu_item%NOTFOUND THEN
                        x_message_data    := 'Invalid Item ';
                        lc_error_location := 'INVALID_ITEM';
                        RAISE EX_MODIFIER_ERROR;
                    END IF;
                    CLOSE lcu_item;    
                END IF;
                
                --------------------------------------
                -- For lines with Attribute9 as 'Get'
                --------------------------------------
                --Modified by Fajna on 08-Aug-07 START                
                --IF P_modifier_lines_tbl(i).attribute9='R' THEN
                IF P_modifier_lines_tbl(i).attribute9='Get' THEN
                --Modified by Fajna on 08-Aug-07 END

                   ln_r_operand :=  P_modifier_lines_tbl(i).operand;            
                -----------------------------------------------------
                -- For lines with Attribute9 as 'Q' deriving operand
                -----------------------------------------------------
                --Modified by Fajna on 08-Aug-07 START    
                -- ELSIF (P_modifier_lines_tbl(i).attribute9='Q' AND ln_inventory_item_id IS NOT NULL) THEN 
                ELSIF (P_modifier_lines_tbl(i).attribute9='Buy' AND ln_inventory_item_id IS NOT NULL) THEN 
                --Modified by Fajna on 08-Aug-07 END    
                
                    OPEN lcu_operand(ln_inventory_item_id);
                    FETCH lcu_operand INTO ln_q_operand;
                    IF lcu_operand%NOTFOUND THEN
                        x_message_data    := 'Operand not found for Buy item';
                        lc_error_location := 'OPERAND_Buy';
                        RAISE EX_MODIFIER_ERROR;
                    END IF;
                    CLOSE lcu_operand;
                END IF;
                ln_sum_operand:= ln_sum_operand + ln_q_operand;            
            END LOOP;
        ------------------------------------------------------
        -- Calculate the value to get distributed among lines
        ------------------------------------------------------
        ln_get_operand_value:=ln_r_operand/(ln_sum_operand/100);
        END IF;
        
    -----------------
    -- Header Delete
    -----------------
    ELSIF  P_modifier_header_rec.operation = 'DELETE' THEN
        lr_modifier_list_rec.list_header_id     := ln_header_id;
        lr_modifier_list_rec.operation          := lc_header_operation;
        lr_modifier_list_rec.start_date_active  := TRUNC(P_modifier_header_rec.start_date_active);
        lr_modifier_list_rec.end_date_active    := TRUNC(SYSDATE-1);
        lr_modifier_list_rec.name               := P_modifier_header_rec.name;
        lr_modifier_list_rec.description        := P_modifier_header_rec.description;
        lr_modifier_list_rec.automatic_flag     := P_modifier_header_rec.automatic_flag;
        lr_modifier_list_rec.currency_code      := P_modifier_header_rec.currency_code;
        lr_modifier_list_rec.list_type_code     := 'PRO';
        lr_modifier_list_rec.pte_code           := 'ORDFUL';
        lr_modifier_list_rec.source_system_code := 'QP';
        lr_modifier_list_rec.ask_for_flag       := P_modifier_header_rec.ask_for_flag;
        lr_modifier_list_rec.comments           := P_modifier_header_rec.comments;
        
        --Added by Fajna on 08-Aug-07 START
        lr_modifier_list_rec.attribute4         := P_modifier_header_rec.attribute4;
        lr_modifier_list_rec.attribute5         := P_modifier_header_rec.attribute5;
        --Added by Fajna on 08-Aug-07 END

        lr_modifier_list_rec.attribute8         := P_modifier_header_rec.attribute8;
        lr_modifier_list_rec.attribute10        := P_modifier_header_rec.attribute10;
        lr_modifier_list_rec.attribute11        := P_modifier_header_rec.attribute11;
        lr_modifier_list_rec.attribute12        := P_modifier_header_rec.attribute12;
        lr_modifier_list_rec.attribute13        := P_modifier_header_rec.attribute13;
        lr_modifier_list_rec.attribute14        := P_modifier_header_rec.attribute14;

        --Added by Fajna on 08-Aug-07 START
        lr_modifier_list_rec.attribute15        := P_modifier_header_rec.attribute15;
        --Added by Fajna on 08-Aug-07 END      
      
        --Added by Fajna on 30-jul-07 START
        IF (P_modifier_header_rec.end_date_active IS NULL OR  P_modifier_header_rec.end_date_active > SYSDATE) THEN
            lr_modifier_list_rec.active_flag  :=  'Y';
        ELSE
            lr_modifier_list_rec.active_flag :=  'N';
        END IF;
        --lr_modifier_list_rec.active_flag        := P_modifier_header_rec.active_flag;      
        --Added by Fajna on 30-jul-07 END
        
        lr_modifier_list_rec.global_flag        := P_modifier_header_rec.global_flag;
        lr_modifier_list_rec.created_by         := fnd_global.user_id;
        lr_modifier_list_rec.creation_date      := TRUNC(SYSDATE);
        lr_modifier_list_rec.last_updated_by    := fnd_global.user_id;
        lr_modifier_list_rec.last_update_date   := TRUNC(SYSDATE);
        lr_modifier_list_rec.last_update_login  := fnd_global.user_id;      
    END IF;
    -----------------------------------------------------------
    --END OF HEADER CREATION/UPDATION
    -----------------------------------------------------------
                        
                        
    -----------------------------------------------------------
    --START OF LINE CREATION/UPDATION
    -----------------------------------------------------------
    --------------------------------------------------------------------------------
    --Begin a LOOP equivalent to number of Lines associated with the Modifier header
    --------------------------------------------------------------------------------
    BEGIN
    FOR i IN 1..P_modifier_lines_tbl.count
    LOOP
        
        ln_line_index := ln_line_index + 1;
        ln_pa_index   := ln_pa_index   + 1;
        ln_qua_index  := ln_qua_index  + 1;

        --------------------------------
        -- Setting Line Level Operation
        --------------------------------
        --Added by Fajna on 30-Jul-07 START
        IF (P_modifier_lines_tbl(i).operation = 'CREATE') THEN      
            lc_line_operation := qp_globals.g_opr_create;
        ELSIF (P_modifier_lines_tbl(i).operation = 'UPDATE') OR (P_modifier_lines_tbl(i).operation = 'DELETE') THEN      
            lc_line_operation := qp_globals.g_opr_update;
            ln_list_line_id   := NULL;
            OPEN lcu_lineid(ln_header_id,P_modifier_lines_tbl(i).attribute7);
            FETCH lcu_lineid INTO ln_list_line_id;
            IF lcu_lineid%NOTFOUND THEN
                x_message_data    := 'Invalid Attribute7 ';
                lc_error_location := 'INVALID_ATTRIBUTE7';
                RAISE EX_MODIFIER_ERROR;
            END IF;
            CLOSE lcu_lineid;
            
        END IF;

        ---------------------------------------------------------------------------------------------
        -- Decoding list_line_id for creating new Modifier line or updating or deleting Modifier line
        ---------------------------------------------------------------------------------------------
        SELECT DECODE(P_modifier_lines_tbl(i).operation,'CREATE',fnd_api.g_miss_num,ln_list_line_id)
        INTO ln_line_id
        FROM dual;
        --Added by Fajna on 30-Jul-07 END

        -------------------------------------------------------------
        -- Fetch pricing_phase_id on the basis of modifier_level_code.
        -------------------------------------------------------------
        IF (P_modifier_header_rec.operation = 'CREATE')  THEN  
           --------------
           --Line Create
           --------------
            ----------------------------
            --Deriving Pricing Phase Id
            ----------------------------
            IF P_modifier_lines_tbl(i).modifier_level_code='LINE' THEN
                lc_adjline_name:='List Line Adjustment';
                OPEN lcu_phaseid(P_modifier_lines_tbl(i).modifier_level_code,lc_adjline_name);
                FETCH lcu_phaseid INTO ln_pricing_phase_id;
                IF lcu_phaseid%NOTFOUND THEN
                    x_message_data    := 'Phase ID not found for List Line Adjustment';
                    lc_error_location := 'PHASEID_NOT_FOUND';
                RAISE EX_MODIFIER_ERROR;
                END IF;
                CLOSE lcu_phaseid;
                
            ELSIF P_modifier_lines_tbl(i).modifier_level_code='ORDER' THEN
                lc_adjline_name:='Header LEVEL adjustments';
                OPEN lcu_phaseid(P_modifier_lines_tbl(i).modifier_level_code,lc_adjline_name);
                FETCH lcu_phaseid INTO ln_pricing_phase_id;
                IF lcu_phaseid%NOTFOUND THEN
                    x_message_data    := 'Phase ID not found for Header LEVEL adjustments';
                    lc_error_location := 'PHASEID_NOT_FOUND';
                    RAISE EX_MODIFIER_ERROR;
                END IF;
                CLOSE lcu_phaseid;
                
            ELSIF P_modifier_lines_tbl(i).modifier_level_code='LINEGROUP' 
                -- Added by Fajna on 30-Jul-07 START
                OR P_modifier_lines_tbl(i).modifier_level_code IS NULL THEN
                -- Added by Fajna on 30-Jul-07 END
                lc_adjline_name:='ALL Lines Adjustment';
                OPEN lcu_phaseid(P_modifier_lines_tbl(i).modifier_level_code,lc_adjline_name);
                FETCH lcu_phaseid INTO ln_pricing_phase_id;
                IF lcu_phaseid%NOTFOUND THEN
                    x_message_data    := 'Phase ID not found for ALL Lines Adjustment';
                    lc_error_location := 'PHASEID_NOT_FOUND';
                    RAISE EX_MODIFIER_ERROR;
                END IF;
                CLOSE lcu_phaseid;
                
            END IF;                 

                
            --Added by Fajna on 30-Jul-07 START
            lt_modifiers_tbl(ln_line_index).list_header_id              := ln_header_id;
            lt_modifiers_tbl(ln_line_index).list_line_id                := ln_line_id;
            --Added by Fajna on 30-Jul-07 END
            
            lt_modifiers_tbl(ln_line_index).list_line_type_code         := P_modifier_lines_tbl(i).list_line_type_code;
            lt_modifiers_tbl(ln_line_index).automatic_flag              := P_modifier_lines_tbl(i).automatic_flag;
            lt_modifiers_tbl(ln_line_index).modifier_level_code         := P_modifier_lines_tbl(i).modifier_level_code;
            lt_modifiers_tbl(ln_line_index).accrual_flag                := P_modifier_lines_tbl(i).accrual_flag;
            --Modified by Fajna on 08-Aug-07 START
            /*lt_modifiers_tbl(ln_line_index).start_date_active           := TRUNC(P_modifier_lines_tbl(i).start_date_active);
            lt_modifiers_tbl(ln_line_index).end_date_active             := TRUNC(P_modifier_lines_tbl(i).end_date_active);*/
            lt_modifiers_tbl(ln_line_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
            lt_modifiers_tbl(ln_line_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);
            --Modified by Fajna on 08-Aug-07 END
            lt_modifiers_tbl(ln_line_index).arithmetic_operator         := P_modifier_lines_tbl(i).arithmetic_operator;
            lt_modifiers_tbl(ln_line_index).pricing_phase_id            := ln_pricing_phase_id;
            lt_modifiers_tbl(ln_line_index).product_precedence          := P_modifier_lines_tbl(i).product_precedence;
            --needs to be changed
            lt_modifiers_tbl(ln_line_index).pricing_group_sequence      := P_modifier_lines_tbl(i).pricing_group_sequence;

            --Added by Fajna on 30-Jul-07 START
            --Modified by Fajna on 01-Aug-07 START
            lt_modifiers_tbl(ln_line_index).price_break_type_code := P_modifier_lines_tbl(i).price_break_type_code;
          /*IF (P_modifier_lines_tbl(i).list_line_type_code = 'DIS') THEN
                lt_modifiers_tbl(ln_line_index).price_break_type_code  :=  'POINT';
            ELSIF (P_modifier_lines_tbl(i).list_line_type_code = 'PBH') THEN
                lt_modifiers_tbl(ln_line_index).price_break_type_code  :=  'RANGE';
            ELSE
                lt_modifiers_tbl(ln_line_index).price_break_type_code := P_modifier_lines_tbl(i).price_break_type_code;
            END IF;    */
            --Modified by Fajna on 01-Aug-07 END
            --lt_modifiers_tbl(ln_line_index).price_break_type_code       := P_modifier_lines_tbl(i).price_break_type_code;
            --Added by Fajna on 30-Jul-07 END

            --Added by Fajna on 30-Jul-07 START
            --Modified by Fajna on 31-Jul-07 START
            
            --Modified by Fajna on 08-Aug-07 START
            lt_modifiers_tbl(ln_line_index).modifier_parent_index     := ln_initial_parent_index;
            --Modified by Fajna on 08-Aug-07 END
            
            /*IF P_modifier_lines_tbl(i).modifier_parent_index IS NOT NULL THEN
                lt_modifiers_tbl(ln_line_index).modifier_parent_index     := P_modifier_lines_tbl(i).modifier_parent_index;
            ELSE
                IF P_modifier_lines_tbl(i).rltd_modifier_grp_type IN ('QUALIFIER','BENEFIT') THEN
                    ln_older_line_index     :=  ln_older_line_index + 1;
                    IF ln_qua_ben_line ='N' THEN
                        lt_modifiers_tbl(ln_line_index).modifier_parent_index     := i-1;         
                        ln_current_line_index   :=  i;
                        ln_qua_ben_line         :=  'Y';
                    ELSIF ln_qua_ben_line ='Y' AND (i = ln_current_line_index + 1) THEN
                        lt_modifiers_tbl(ln_line_index).modifier_parent_index := i - ln_older_line_index;
                        ln_current_line_index   :=  i;
                    ELSE
                        lt_modifiers_tbl(ln_line_index).modifier_parent_index     := ln_initial_parent_index;
                    END IF;
                ELSE
                    lt_modifiers_tbl(ln_line_index).modifier_parent_index     := ln_initial_parent_index;
                END IF;
            END IF;*/
            --Modified by Fajna on 31-Jul-07 END
            --Added by Fajna on 30-Jul-07 END
            
            --Added by Fajna on 08-Aug-07 START
            lt_modifiers_tbl(ln_line_index).attribute7 := P_modifier_lines_tbl(i).attribute7;
            lt_modifiers_tbl(ln_line_index).attribute8 := P_modifier_lines_tbl(i).attribute8;
            lt_modifiers_tbl(ln_line_index).attribute9 := P_modifier_lines_tbl(i).attribute9;
            lt_modifiers_tbl(ln_line_index).attribute10:= P_modifier_lines_tbl(i).attribute10;
            --Added by Fajna on 08-Aug-07 END
            
            lt_modifiers_tbl(ln_line_index).operation                   := lc_line_operation;
            lt_modifiers_tbl(ln_line_index).created_by                  := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).creation_date               := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_updated_by             := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).last_update_date            := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_update_login           := fnd_global.user_id;      

            -------------------------------------------------------------------
            -- Dividing derived operand equally among lines with Attribute9='Q' 
            -------------------------------------------------------------------
            --Modified by Fajna on 08-AUG-07 START    
            /*IF  P_modifier_lines_tbl(i).attribute9='R'    AND (lb_type_flag)  THEN  
                lt_modifiers_tbl(ln_line_index).operand      := ln_r_operand;
            ELSIF P_modifier_lines_tbl(i).attribute9='Q'    AND (lb_type_flag)  THEN 
                lt_modifiers_tbl(ln_line_index).operand      := ln_get_operand_value;*/ 
            IF  P_modifier_lines_tbl(i).attribute9 = 'Get'  AND (lb_type_flag)  THEN  
                lt_modifiers_tbl(ln_line_index).operand      := ln_get_operand_value;
            ELSIF P_modifier_lines_tbl(i).attribute9 ='Buy' AND (lb_type_flag)  THEN 
                lt_modifiers_tbl(ln_line_index).operand      :=  P_modifier_lines_tbl(i).operand;       
            --Modified by Fajna on 08-AUG-07 END  
            ELSE                                             
                lt_modifiers_tbl(ln_line_index).operand      := P_modifier_lines_tbl(i).operand;  
            END IF;
            ------------------------------------------------------
            -- Deriving Inventory Item Id for the Segment1 passed
            ------------------------------------------------------
            --Modified by Fajna on 30-Jul-07 START(Added 'ITEM_CATEGORY')
            IF P_modifier_attributes_tbl(i).product_attr_value NOT IN ('ALL','ITEM_CATEGORY')  THEN
            --Modified by Fajna on 30-Jul-07 START            
                OPEN lcu_item(P_modifier_attributes_tbl(i).product_uom_code,P_modifier_attributes_tbl(i).product_attr_value);
                FETCH lcu_item INTO ln_inventory_item_id;
                IF lcu_item%NOTFOUND THEN
                    x_message_data    := 'Invalid Item';
                    lc_error_location := 'INVALID_ITEM';
                RAISE EX_MODIFIER_ERROR;
                END IF;
                CLOSE lcu_item;
                
            ELSE  
                ln_inventory_item_id :='ALL';
                
            END IF;  
            ---------------------------
            -- Benefit/Qualifier Lines
            ---------------------------
            --Added by Fajna on 30-Jul-07 START
            --Modified by Fajna on 31-Jul-07 START
            /*IF P_modifier_lines_tbl(i).rltd_modifier_grp_type IN ('BENEFIT','QUALIFIER') THEN
                lt_modifiers_tbl(ln_line_index).rltd_modifier_grp_no        := P_modifier_lines_tbl(i).rltd_modifier_grp_no;
                lt_modifiers_tbl(ln_line_index).rltd_modifier_grp_type      := P_modifier_lines_tbl(i).rltd_modifier_grp_type;
                --Added by Fajna on 30-Jul-07 END
                
                --------------------------------------------------------
                --Deriving Benefit price list line id for BENEFIT Lines
                --------------------------------------------------------
                IF (P_modifier_lines_tbl(i).rltd_modifier_grp_type = 'BENEFIT') THEN
                    
                    OPEN lcu_benefit_list_line(ln_inventory_item_id);
                    FETCH lcu_benefit_list_line INTO ln_benefit_price_list_line_id;
                    IF  lcu_benefit_list_line%NOTFOUND THEN
                        x_message_data    := 'NO Benefit line ';
                        lc_error_location := 'BENEFIT_LINE';
                        RAISE EX_MODIFIER_ERROR;
                    END IF;
                    CLOSE lcu_benefit_list_line;
                    
                    
                    lt_modifiers_tbl(ln_line_index).benefit_price_list_line_id  := ln_benefit_price_list_line_id;
                    lt_modifiers_tbl(ln_line_index).benefit_qty                 := P_modifier_attributes_tbl(i).pricing_attr_value_from;
                    lt_modifiers_tbl(ln_line_index).benefit_uom_code            := P_modifier_attributes_tbl(i).product_uom_code;
                END IF;
            END IF;*/
        --Modified by Fajna on 31-Jul-07 END    
        --Added by Fajna on 30-Jul-07 START
        --------------
        --Line Update
        --------------
        ELSIF P_modifier_lines_tbl(i).operation='UPDATE' THEN
            --Added by Fajna on 30-Jul-07 START
            lt_modifiers_tbl(ln_line_index).list_header_id              := ln_header_id;
            lt_modifiers_tbl(ln_line_index).list_line_id                := ln_line_id;
            --Added by Fajna on 30-Jul-07 END

            lt_modifiers_tbl(ln_line_index).list_line_type_code         := P_modifier_lines_tbl(i).list_line_type_code;
            lt_modifiers_tbl(ln_line_index).automatic_flag              := P_modifier_lines_tbl(i).automatic_flag;
            lt_modifiers_tbl(ln_line_index).modifier_level_code         := P_modifier_lines_tbl(i).modifier_level_code;
            lt_modifiers_tbl(ln_line_index).accrual_flag                := P_modifier_lines_tbl(i).accrual_flag;
            
            --Modified by Fajna on 08-Aug-07 START
            /*lt_modifiers_tbl(ln_line_index).start_date_active         := TRUNC(P_modifier_lines_tbl(i).start_date_active);
            lt_modifiers_tbl(ln_line_index).end_date_active             := TRUNC(P_modifier_lines_tbl(i).end_date_active);*/
            lt_modifiers_tbl(ln_line_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
            lt_modifiers_tbl(ln_line_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);
            --Modified by Fajna on 08-Aug-07 END
            
            lt_modifiers_tbl(ln_line_index).arithmetic_operator         := P_modifier_lines_tbl(i).arithmetic_operator;
            lt_modifiers_tbl(ln_line_index).pricing_phase_id            := P_modifier_lines_tbl(i).pricing_phase_id;
            lt_modifiers_tbl(ln_line_index).product_precedence          := P_modifier_lines_tbl(i).product_precedence;
            lt_modifiers_tbl(ln_line_index).pricing_group_sequence      := P_modifier_lines_tbl(i).pricing_group_sequence;
            lt_modifiers_tbl(ln_line_index).price_break_type_code       := P_modifier_lines_tbl(i).price_break_type_code;
            --Modified by Fajna on 31-Jul-7 START
            lt_modifiers_tbl(ln_line_index).modifier_parent_index       := ln_initial_parent_index;
            --Modified by Fajna on 31-Jul-7 END
            
            --Added by Fajna on 08-Aug-07 START
            lt_modifiers_tbl(ln_line_index).attribute7 := P_modifier_lines_tbl(i).attribute7;
            lt_modifiers_tbl(ln_line_index).attribute8 := P_modifier_lines_tbl(i).attribute8;
            lt_modifiers_tbl(ln_line_index).attribute9 := P_modifier_lines_tbl(i).attribute9;
            lt_modifiers_tbl(ln_line_index).attribute10:= P_modifier_lines_tbl(i).attribute10;
            --Added by Fajna on 08-Aug-07 END
            
            lt_modifiers_tbl(ln_line_index).operand                     := P_modifier_lines_tbl(i).operand;                         
            lt_modifiers_tbl(ln_line_index).operation                   := lc_line_operation;
            lt_modifiers_tbl(ln_line_index).created_by                  := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).creation_date               := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_updated_by             := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).last_update_date            := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_update_login           := fnd_global.user_id; 
            
            ---------------------------
            -- Benefit/Qualifier Lines
            ---------------------------
            --Added by Fajna on 30-Jul-07 START
            --Modified by Fajna on 31-Jul-07 START
            /*IF P_modifier_lines_tbl(i).rltd_modifier_grp_type IN ('BENEFIT','QUALIFIER') THEN
                lt_modifiers_tbl(ln_line_index).rltd_modifier_grp_no        := P_modifier_lines_tbl(i).rltd_modifier_grp_no;
                lt_modifiers_tbl(ln_line_index).rltd_modifier_grp_type      := P_modifier_lines_tbl(i).rltd_modifier_grp_type;
                --Added by Fajna on 30-Jul-07 END

                IF (P_modifier_lines_tbl(i).rltd_modifier_grp_type = 'BENEFIT') THEN
                    lt_modifiers_tbl(ln_line_index).benefit_price_list_line_id  := P_modifier_lines_tbl(i).benefit_price_list_line_id;
                    lt_modifiers_tbl(ln_line_index).benefit_qty                 := P_modifier_attributes_tbl(i).pricing_attr_value_from;
                    lt_modifiers_tbl(ln_line_index).benefit_uom_code            := P_modifier_attributes_tbl(i).product_uom_code;
                END IF;
            END IF; --'BENEFIT','QUALIFIER'*/
            --Modified by Fajna on 31-Jul-07 END
        --------------
        --Line Delete
        --------------
        ELSIF P_modifier_lines_tbl(i).operation='DELETE' OR P_modifier_header_rec.operation = 'DELETE' THEN
            lt_modifiers_tbl(ln_line_index).list_header_id              := ln_header_id;
            lt_modifiers_tbl(ln_line_index).list_line_id                := ln_line_id;
            
            --Modified by Fajna on 08-Aug-07 START
            /*lt_modifiers_tbl(ln_line_index).start_date_active         := TRUNC(P_modifier_lines_tbl(i).start_date_active);*/
            lt_modifiers_tbl(ln_line_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
            --Modified by Fajna on 08-Aug-07 END            
            
            lt_modifiers_tbl(ln_line_index).end_date_active             := TRUNC(SYSDATE-1);
            lt_modifiers_tbl(ln_line_index).operation                   := lc_line_operation;
            lt_modifiers_tbl(ln_line_index).created_by                  := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).creation_date               := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_updated_by             := fnd_global.user_id;
            lt_modifiers_tbl(ln_line_index).last_update_date            := TRUNC(SYSDATE);
            lt_modifiers_tbl(ln_line_index).last_update_login           := fnd_global.user_id;
        END IF; -- Line Operation 'CREATE','UPDATE','DELETE'
        --Added by Fajna on 30-Jul-07 END
        -----------------------------------------------------------
        --END OF LINE CREATION/UPDATION
        -----------------------------------------------------------
        
        -----------------------------------------------------------
        --START OF PRICING ATTRIBUTE CREATION/UPDATION
        -----------------------------------------------------------    
        /*HAVE CURSOR WHICH GIVES THE PRICING ATTRIBUTE ID AND QUALIFIER ID FOR UPDATION*/
        ---------------------------------------
        -- Setting Pricing Attribute Operation
        ---------------------------------------
        --Added by Fajna on 30-Jul-07 START
        IF (P_modifier_attributes_tbl(i).operation = 'CREATE') THEN      
            lc_pa_operation := qp_globals.g_opr_create;
        ELSIF (P_modifier_attributes_tbl(i).operation = 'UPDATE') OR (P_modifier_attributes_tbl(i).operation = 'DELETE') THEN      
            lc_pa_operation := qp_globals.g_opr_update;
            OPEN lcu_lineid(ln_header_id,P_modifier_lines_tbl(i).attribute7);
            FETCH lcu_lineid INTO ln_list_line_id;
            IF lcu_lineid%NOTFOUND THEN
                x_message_data    := 'Invalid Attribute7 ';
                lc_error_location := 'INVALID_ATTRIBUTE7';
                RAISE EX_MODIFIER_ERROR;
            END IF;
            CLOSE lcu_lineid;
            
        END IF;

        ---------------------------------------------------------------------------------------------
        -- Decoding list_line_id for creating new Modifier line or updating or deleting Modifier line
        ---------------------------------------------------------------------------------------------
        SELECT DECODE(P_modifier_attributes_tbl(i).operation,'CREATE',fnd_api.g_miss_num,ln_pricing_attribute_id)
        INTO ln_pa_id
        FROM dual;
        --Added by Fajna on 30-Jul-07 END
        
        IF P_modifier_attributes_tbl(i).operation='CREATE' THEN
            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute_id       := ln_pa_id;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute_context  := P_modifier_attributes_tbl(i).product_attribute_context;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute          := P_modifier_attributes_tbl(i).product_attribute;

            --Added by Fajna on 30-Jul-07 START      
            IF P_modifier_lines_tbl(i).modifier_level_code IN ('LINE') THEN
                lt_pricing_attr_tbl(ln_pa_index).product_attr_value := TO_CHAR(ln_inventory_item_id);
            ELSIF P_modifier_lines_tbl(i).modifier_level_code IN ('LINEGROUP') THEN
                IF P_modifier_attributes_tbl(i).product_attr_value = 'ALL' THEN
                  lt_pricing_attr_tbl(ln_pa_index).product_attr_value := 'ALL';
                ELSE
                   lt_pricing_attr_tbl(ln_pa_index).product_attr_value := TO_CHAR(ln_inventory_item_id);
                END IF;
            ELSE
                IF P_modifier_header_rec.attribute12 = '7' THEN
                    IF lt_pricing_attr_tbl(ln_pa_index).product_attr_value = 'ITEM_CATEGORY' THEN
                    --May need to derive the category_id if they are passing the division,group,dept,class and subclass details
                        
                        lt_pricing_attr_tbl(ln_pa_index).product_attr_value := 'ITEM_CATEGORY';
                    ELSE
                        lt_pricing_attr_tbl(ln_pa_index).product_attr_value := TO_CHAR(ln_inventory_item_id);
                    END IF;
                ELSE
                 lt_pricing_attr_tbl(ln_pa_index).product_attr_value := TO_CHAR(ln_inventory_item_id);
                END IF;
            END IF;
            --lt_pricing_attr_tbl(ln_pa_index).product_attr_value         := ln_inventory_item_id;
            --Added by Fajna on 30-Jul-07 END

            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute_context  := P_modifier_attributes_tbl(i).pricing_attribute_context;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute          := P_modifier_attributes_tbl(i).pricing_attribute;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attr_value_from    := P_modifier_attributes_tbl(i).pricing_attr_value_from;
            lt_pricing_attr_tbl(ln_pa_index).comparison_operator_code   := P_modifier_attributes_tbl(i).comparison_operator_code;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attr_value_to      := P_modifier_attributes_tbl(i).pricing_attr_value_to;
            lt_pricing_attr_tbl(ln_pa_index).product_uom_code           := P_modifier_attributes_tbl(i).product_uom_code;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute_datatype := P_modifier_attributes_tbl(i).product_attribute_datatype;
            lt_pricing_attr_tbl(ln_pa_index).excluder_flag              := P_modifier_attributes_tbl(i).excluder_flag;
            --Added by Fajna on 30-Jul-2007 START
            IF P_modifier_attributes_tbl(i).modifiers_index IS NOT NULL THEN
                lt_pricing_attr_tbl(ln_pa_index).modifiers_index            := P_modifier_attributes_tbl(i).modifiers_index;
            ELSE
                lt_pricing_attr_tbl(ln_pa_index).modifiers_index            := ln_pa_index;
            END IF;
            --Added by Fajna on 30-Jul-2007 END
            lt_pricing_attr_tbl(ln_pa_index).pricing_phase_id           := ln_pricing_phase_id;
            lt_pricing_attr_tbl(ln_pa_index).operation                  := lc_pa_operation;
            lt_pricing_attr_tbl(ln_pa_index).created_by                 := fnd_global.user_id;
            lt_pricing_attr_tbl(ln_pa_index).creation_date              := TRUNC(SYSDATE);
            lt_pricing_attr_tbl(ln_pa_index).last_updated_by            := fnd_global.user_id;
            lt_pricing_attr_tbl(ln_pa_index).last_update_date           := TRUNC(SYSDATE);
            lt_pricing_attr_tbl(ln_pa_index).last_update_login          := fnd_global.user_id; 
        ELSIF P_modifier_attributes_tbl(i).operation='UPDATE' THEN
            lt_pricing_attr_tbl(ln_pa_index).list_header_id             := ln_header_id;
            lt_pricing_attr_tbl(ln_pa_index).list_line_id               := ln_line_id;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute_id       := ln_pa_id;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute_context  := P_modifier_attributes_tbl(i).product_attribute_context;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute          := P_modifier_attributes_tbl(i).product_attribute;
            ------------------------------------------------------
            -- Deriving Inventory Item Id for the Segment1 passed
            ------------------------------------------------------
            --Modified by Fajna on 30-Jul-07 START(Added 'ITEM_CATEGORY')
            IF P_modifier_attributes_tbl(i).product_attr_value NOT IN ('ALL','ITEM_CATEGORY')  THEN
                --Modified by Fajna on 30-Jul-07 START            
                OPEN lcu_item(P_modifier_attributes_tbl(i).product_uom_code,P_modifier_attributes_tbl(i).product_attr_value);
                FETCH lcu_item INTO ln_inventory_item_id;
                IF lcu_item%NOTFOUND THEN
                    x_message_data    := 'Invalid Item';
                    lc_error_location := 'INVALID_ITEM';
                    RAISE EX_MODIFIER_ERROR;
                END IF;
                CLOSE lcu_item;                
                ELSE  
                    ln_inventory_item_id :='ALL';                    
            END IF;     
    
            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute_context  := P_modifier_attributes_tbl(i).pricing_attribute_context;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attribute          := P_modifier_attributes_tbl(i).pricing_attribute;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attr_value_from    := P_modifier_attributes_tbl(i).pricing_attr_value_from;
            lt_pricing_attr_tbl(ln_pa_index).comparison_operator_code   := P_modifier_attributes_tbl(i).comparison_operator_code;
            lt_pricing_attr_tbl(ln_pa_index).pricing_attr_value_to      := P_modifier_attributes_tbl(i).pricing_attr_value_to;
            lt_pricing_attr_tbl(ln_pa_index).product_uom_code           := P_modifier_attributes_tbl(i).product_uom_code;
            lt_pricing_attr_tbl(ln_pa_index).product_attribute_datatype := P_modifier_attributes_tbl(i).product_attribute_datatype;
            lt_pricing_attr_tbl(ln_pa_index).excluder_flag              := P_modifier_attributes_tbl(i).excluder_flag;
            
            --Added by Fajna on 30-Jul-2007 START
            IF P_modifier_attributes_tbl(i).modifiers_index IS NOT NULL THEN
                lt_pricing_attr_tbl(ln_pa_index).modifiers_index            := P_modifier_attributes_tbl(i).modifiers_index;
            ELSE
                lt_pricing_attr_tbl(ln_pa_index).modifiers_index            := ln_pa_index;
            END IF;
            --Added by Fajna on 30-Jul-2007 END
            
            lt_pricing_attr_tbl(ln_pa_index).pricing_phase_id           := P_modifier_attributes_tbl(i).pricing_phase_id;
            lt_pricing_attr_tbl(ln_pa_index).operation                  := lc_pa_operation;
            lt_pricing_attr_tbl(ln_pa_index).created_by                 := fnd_global.user_id;
            lt_pricing_attr_tbl(ln_pa_index).creation_date              := TRUNC(SYSDATE);
            lt_pricing_attr_tbl(ln_pa_index).last_updated_by            := fnd_global.user_id;
            lt_pricing_attr_tbl(ln_pa_index).last_update_date           := TRUNC(SYSDATE);
            lt_pricing_attr_tbl(ln_pa_index).last_update_login          := fnd_global.user_id;
        
        END IF;-- Pricing Attribute Operation 'CREATE','UPDATE'
        
        -----------------------------------------------------------
        --END OF PRICING ATTRIBUTE CREATION/UPDATION
        -----------------------------------------------------------  
        ---------------------------------------
        -- Setting Pricing Attribute Operation
        ---------------------------------------
        --Added by Fajna on 30-Jul-07 START
        IF (P_modifier_qualifiers_tbl(i).operation = 'CREATE') THEN      
            lc_qual_operation := qp_globals.g_opr_create;
        ELSIF (P_modifier_qualifiers_tbl(i).operation = 'UPDATE') OR (P_modifier_qualifiers_tbl(i).operation = 'DELETE') THEN      
            lc_qual_operation := qp_globals.g_opr_update;
            ln_qualifier_id   := NULL;
            OPEN lcu_lineid(ln_header_id,P_modifier_lines_tbl(i).attribute7);
            FETCH lcu_lineid INTO ln_list_line_id;
            IF lcu_lineid%NOTFOUND THEN
                x_message_data    := 'Invalid Attribute7 ';
                lc_error_location := 'INVALID_ATTRIBUTE7';
                RAISE EX_MODIFIER_ERROR;
            END IF;
            CLOSE lcu_lineid;
        END IF;

        ---------------------------------------------------------------------------------------------
        -- Decoding list_line_id for creating new Modifier line or updating or deleting Modifier line
        ---------------------------------------------------------------------------------------------
        SELECT DECODE(P_modifier_qualifiers_tbl(i).operation,'CREATE',fnd_api.g_miss_num,ln_qualifier_id)
        INTO ln_qua_id
        FROM dual;
        --Added by Fajna on 30-Jul-07 END
        
        -------------------------------------------------------------
        -- Header level Qualifiers if qualifier_context='ITEMCATEXC'
        -------------------------------------------------------------
        --Added by Fajna K.P on 31-Jul-07 START
        --IF P_modifier_lines_tbl(i).pricing_group_sequence=2 THEN
        IF P_modifier_qualifiers_tbl(i).qualifier_context='ITEMCATEXC' THEN
        --Added by Fajna K.P on 31-Jul-07 END
            IF P_modifier_qualifiers_tbl(i).operation ='CREATE' THEN              
                lt_qualifiers_tbl(ln_qua_index).qualifier_id                := ln_qua_id;
                lt_qualifiers_tbl(ln_qua_index).list_header_id              := ln_header_id;
                lt_qualifiers_tbl(ln_qua_index).list_line_id                := fnd_api.g_miss_num;
                
                --Modified by Fajna on 08-Aug-07 START
                /*lt_qualifiers_tbl(ln_qua_index).start_date_active         := TRUNC(P_modifier_qualifiers_tbl(i).start_date_active);
                lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_qualifiers_tbl(i).end_date_active);*/
                lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);
                --Modified by Fajna on 08-Aug-07 END
                
                lt_qualifiers_tbl(ln_qua_index).excluder_flag               := P_modifier_qualifiers_tbl(i).excluder_flag;
                lt_qualifiers_tbl(ln_qua_index).comparison_operator_code    := P_modifier_qualifiers_tbl(i).comparison_operator_code;
                lt_qualifiers_tbl(ln_qua_index).qualifier_context           := P_modifier_qualifiers_tbl(i).qualifier_context;
                lt_qualifiers_tbl(ln_qua_index).qualifier_attribute         := P_modifier_qualifiers_tbl(i).qualifier_attribute;
                lt_qualifiers_tbl(ln_qua_index).qualifier_attr_value        := P_modifier_qualifiers_tbl(i).qualifier_attr_value;
                lt_qualifiers_tbl(ln_qua_index).qualifier_grouping_no       := P_modifier_qualifiers_tbl(i).qualifier_grouping_no;
                lt_qualifiers_tbl(ln_qua_index).operation                   := lc_qual_operation; 
                lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id; 
            --Modified by Fajna K.P on 31-Jul-07 START
            ELSIF P_modifier_qualifiers_tbl(i).operation ='UPDATE' THEN
                lt_qualifiers_tbl(ln_qua_index).qualifier_id                := ln_qua_id;
                lt_qualifiers_tbl(ln_qua_index).list_header_id              := ln_header_id;
                lt_qualifiers_tbl(ln_qua_index).list_line_id                := fnd_api.g_miss_num;
                
                --Modified by Fajna on 08-Aug-07 START
                lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);
                --Modified by Fajna on 08-Aug-07 END
                
                lt_qualifiers_tbl(ln_qua_index).excluder_flag               := P_modifier_qualifiers_tbl(i).excluder_flag;
                lt_qualifiers_tbl(ln_qua_index).comparison_operator_code    := P_modifier_qualifiers_tbl(i).comparison_operator_code;
                lt_qualifiers_tbl(ln_qua_index).qualifier_context           := P_modifier_qualifiers_tbl(i).qualifier_context;
                lt_qualifiers_tbl(ln_qua_index).qualifier_attribute         := P_modifier_qualifiers_tbl(i).qualifier_attribute;
                lt_qualifiers_tbl(ln_qua_index).qualifier_attr_value        := P_modifier_qualifiers_tbl(i).qualifier_attr_value;
                lt_qualifiers_tbl(ln_qua_index).qualifier_grouping_no       := P_modifier_qualifiers_tbl(i).qualifier_grouping_no;
                lt_qualifiers_tbl(ln_qua_index).operation                   := lc_qual_operation; 
                lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id;
           --Modified by Fajna K.P on 31-Jul-07 END
           ELSIF P_modifier_qualifiers_tbl(i).operation ='DELETE' THEN
                lt_qualifiers_tbl(ln_qua_index).qualifier_id                := ln_qua_id;
                lt_qualifiers_tbl(ln_qua_index).list_header_id              := ln_header_id;
                lt_qualifiers_tbl(ln_qua_index).list_line_id                := fnd_api.g_miss_num;
                --Modified by Fajna on 08-Aug-07 START
                /*lt_qualifiers_tbl(ln_qua_index).start_date_active         := TRUNC(P_modifier_qualifiers_tbl(i).start_date_active);*/
                lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                --Modified by Fajna on 08-Aug-07 END
                lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(SYSDATE-1);
                lt_qualifiers_tbl(ln_qua_index).operation                   := lc_qual_operation;
                lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id;
            END IF;
        END IF;
        END LOOP; 
        EXCEPTION -- line loop exception
        WHEN OTHERS THEN
            x_message_data    := SQLERRM;
            lc_error_location := 'OTHERS';
            RAISE EX_MODIFIER_ERROR;
        END;
   

            

   --------------------------------------------------------------------------------------
   -- API call to Create/Update Modifier Header, Lines, Pricing Attributes and Qualifiers
   --------------------------------------------------------------------------------------
   QP_modifiers_pub.process_modifiers
                                  ( p_api_version_number     => 1.0
                                  , p_init_msg_list          => fnd_api.g_false
                                  , p_return_values          => fnd_api.g_false
                                  , p_commit                 => fnd_api.g_false
                                  , x_return_status          => lc_return_status
                                  , x_msg_count              => ln_msg_count
                                  , x_msg_data               => lc_msg_data
                                  , p_modifier_list_rec      => lr_modifier_list_rec
                                  , p_modifier_list_val_rec  => lr_modifier_list_val_rec
                                  , p_modifiers_tbl          => lt_modifiers_tbl
                                  , p_modifiers_val_tbl      => lt_modifiers_val_tbl
                                  , p_qualifiers_tbl         => lt_qualifiers_tbl
                                  , p_qualifiers_val_tbl     => lt_qualifiers_val_tbl
                                  , p_pricing_attr_tbl       => lt_pricing_attr_tbl
                                  , p_pricing_attr_val_tbl   => lt_pricing_attr_val_tbl
                                  , x_modifier_list_rec      => x_modifier_list_rec
                                  , x_modifier_list_val_rec  => x_modifier_list_val_rec
                                  , x_modifiers_tbl          => x_modifiers_tbl
                                  , x_modifiers_val_tbl      => x_modifiers_val_tbl
                                  , x_qualifiers_tbl         => x_qualifiers_tbl
                                  , x_qualifiers_val_tbl     => x_qualifiers_val_tbl
                                  , x_pricing_attr_tbl       => x_pricing_attr_tbl
                                  , x_pricing_attr_val_tbl   => x_pricing_attr_val_tbl
                                  );
   COMMIT;   
   
   
   
   --Added by Fajna on 31-jul-07 START
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
       lc_return_status := FND_API.G_RET_STS_ERROR;
       DBMS_OUTPUT.PUT_LINE('G_RET_STS_ERROR'||lc_data);
       

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
       lc_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       FOR k IN 1 .. ln_count 
       LOOP
           lc_data := oe_msg_pub.get( p_msg_index => k,
                               p_encoded   => 'F'
                             );
           DBMS_OUTPUT.PUT_LINE('G_EXC_UNEXPECTED_ERROR'||lc_data);
           
       END LOOP;

    WHEN OTHERS THEN
       lc_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
       FOR k IN 1 .. ln_count 
       LOOP
       lc_data := oe_msg_pub.get( p_msg_index => k,
                                  p_encoded => 'F'
                                );
       DBMS_OUTPUT.PUT_LINE('G_RET_STS_UNEXP_ERROR'||lc_data);
       

       END LOOP; 
    END;
    --Added by Fajna on 31-jul-07 END
    
   --Modified by Fajna on 31-jul-07 START
   /* IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       IF ln_msg_count > 0 THEN
          FOR counter IN 1..ln_msg_count
          LOOP
             
             lc_err_message := 'API Error'||lc_err_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
             
          END LOOP;
          x_message_code := lc_err_message;
          x_message_code  := NULL;
          lc_error_location    := 'API_ERROR';
          -- Log error in error table
          XX_COM_ERROR_LOG_PUB.LOG_ERROR
                    (
                     p_program_type            => G_PROG_TYPE     
                    ,p_program_name            => G_PROG_NAME     
                    ,p_module_name             => G_MODULE_NAME   
                    ,p_error_location          => lc_error_location
                    ,p_error_message_code      => x_message_code          
                    ,p_error_message           => x_message_data       
                    ,p_error_message_severity  => G_MAJOR     
                    ,p_notify_flag             => G_NOTIFY        
                   );
          fnd_msg_pub.delete_msg;
       ELSE
         x_message_code := 'Sucessfully completed';
       END IF;
    END IF;*/
    --Modified by Fajna on 31-jul-07 END
     
    
        -------------------------------------------------------
        --Line Level Qualifiers if qualifier_context='MODLIST'
        -------------------------------------------------------    
        BEGIN                        
            lr_modifier_list_rec    :=  x_modifier_list_rec;
            lt_modifiers_tbl        :=  x_modifiers_tbl; 
            lr_qualifiers_rec_type  :=  x_qualifiers_rec_type;
            lt_qualifiers_tbl       :=  x_qualifiers_tbl;  
            lt_pricing_attr_tbl     :=  x_pricing_attr_tbl;  
            FOR i IN 1..P_modifier_lines_tbl.count
            LOOP
                --Added by Fajna K.P on 31-Jul-07 START
                --IF P_modifier_lines_tbl(i).pricing_group_sequence=1 THEN
                IF P_modifier_qualifiers_tbl(i).qualifier_context='MODLIST' THEN
                --Added by Fajna K.P on 31-Jul-07 END
                    BEGIN
                    ln_line_index := ln_line_index + 1;
                    ln_pa_index   := ln_pa_index   + 1;
                    ln_qua_index  := ln_qua_index  + 1;
                    ln_qualifier_headerid   :=  NULL;
                    ln_qualifier_lineid     :=  NULL;

                    OPEN lcu_header_line_id(P_modifier_lines_tbl(i).attribute7,P_modifier_header_rec.name);
                    FETCH lcu_header_line_id INTO ln_qualifier_headerid,ln_qualifier_lineid;
                        IF  lcu_header_line_id%NOTFOUND THEN
                            x_message_data    := 'NO Header and line Exists with the given values ';
                            lc_error_location := 'HEADER_LINE';
                            RAISE EX_MODIFIER_ERROR;
                        END IF;
                    CLOSE lcu_header_line_id; 

                    IF P_modifier_qualifiers_tbl(i).operation ='CREATE' THEN                
                        lr_modifier_list_rec.list_header_id                         := ln_qualifier_headerid;

                        lt_qualifiers_tbl(ln_qua_index).list_line_id                := ln_qualifier_lineid;
                        
                        --Modified by Fajna on 08-Aug-07 START
                        /*lt_qualifiers_tbl(ln_qua_index).start_date_active         := TRUNC(P_modifier_qualifiers_tbl(i).start_date_active);
                        lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_qualifiers_tbl(i).end_date_active);*/
                        lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                        lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);
                        --Modified by Fajna on 08-Aug-07 END
                
                        lt_qualifiers_tbl(ln_qua_index).excluder_flag               := P_modifier_qualifiers_tbl(i).excluder_flag;
                        lt_qualifiers_tbl(ln_qua_index).comparison_operator_code    := P_modifier_qualifiers_tbl(i).comparison_operator_code;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_context           := P_modifier_qualifiers_tbl(i).qualifier_context;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_attribute         := P_modifier_qualifiers_tbl(i).qualifier_attribute;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_attr_value        := P_modifier_qualifiers_tbl(i).qualifier_attr_value;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_grouping_no       := P_modifier_qualifiers_tbl(i).qualifier_grouping_no;
                        lt_qualifiers_tbl(ln_qua_index).operation                   := QP_GLOBALS.G_OPR_CREATE; 
                        lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id;
                    --Modified by Fajna K.P on 31-Jul-07 START
                   /* ELSIF P_modifier_qualifiers_tbl(i).operation ='UPDATE' THEN
                        lr_modifier_list_rec.operation                              := QP_GLOBALS.G_OPR_UPDATE;
                        lr_modifier_list_rec.list_header_id                         := ln_qualifier_headerid;           

                        lt_qualifiers_tbl(ln_qua_index).list_line_id                := ln_qualifier_lineid;
                        
                        --Modified by Fajna on 08-Aug-07 START
                        /* lt_qualifiers_tbl(ln_qua_index).start_date_active         := TRUNC(P_modifier_qualifiers_tbl(i).start_date_active);
                        lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_qualifiers_tbl(i).end_date_active);*/
                        lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                        lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(P_modifier_header_rec.end_date_active);                                                
                        --Modified by Fajna on 08-Aug-07 END
                        
                       /* lt_qualifiers_tbl(ln_qua_index).excluder_flag               := P_modifier_qualifiers_tbl(i).excluder_flag;
                        lt_qualifiers_tbl(ln_qua_index).comparison_operator_code    := P_modifier_qualifiers_tbl(i).comparison_operator_code;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_context           := P_modifier_qualifiers_tbl(i).qualifier_context;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_attribute         := P_modifier_qualifiers_tbl(i).qualifier_attribute;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_attr_value        := P_modifier_qualifiers_tbl(i).qualifier_attr_value;
                        lt_qualifiers_tbl(ln_qua_index).qualifier_grouping_no       := P_modifier_qualifiers_tbl(i).qualifier_grouping_no;
                        lt_qualifiers_tbl(ln_qua_index).operation                   := QP_GLOBALS.G_OPR_UPDATE; 
                        lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id;*/
                    --Modified by Fajna K.P on 31-Jul-07 END
                    ELSIF P_modifier_qualifiers_tbl(i).operation ='DELETE' THEN
                        lr_modifier_list_rec.operation                              := QP_GLOBALS.G_OPR_UPDATE;
                        lr_modifier_list_rec.list_header_id                         := ln_qualifier_headerid;           
                        lt_qualifiers_tbl(ln_qua_index).list_line_id                := ln_qualifier_lineid;
                        --Modified by Fajna on 08-Aug-07 START
                        --lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_qualifiers_tbl(i).start_date_active);
                        lt_qualifiers_tbl(ln_qua_index).start_date_active           := TRUNC(P_modifier_header_rec.start_date_active);
                        --Modified by Fajna on 08-Aug-07 END
                        
                        lt_qualifiers_tbl(ln_qua_index).end_date_active             := TRUNC(SYSDATE-1);
                        lt_qualifiers_tbl(ln_qua_index).operation                   := QP_GLOBALS.G_OPR_UPDATE; 
                        lt_qualifiers_tbl(ln_qua_index).created_by                  := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).creation_date               := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_updated_by             := fnd_global.user_id;
                        lt_qualifiers_tbl(ln_qua_index).last_update_date            := TRUNC(SYSDATE);
                        lt_qualifiers_tbl(ln_qua_index).last_update_login           := fnd_global.user_id;
                    END IF;
                    END;
                END IF;
            END LOOP;

            --------------------------------------------------------------------------------------
            -- API call to Create/Update Modifier Header, Lines, Pricing Attributes and Qualifiers
            --------------------------------------------------------------------------------------
            QP_modifiers_pub.process_modifiers
                                          ( p_api_version_number     => 1.0
                                          , p_init_msg_list          => fnd_api.g_false
                                          , p_return_values          => fnd_api.g_false
                                          , p_commit                 => fnd_api.g_false
                                          , x_return_status          => lc_return_status
                                          , x_msg_count              => ln_msg_count
                                          , x_msg_data               => lc_msg_data
                                          , p_modifier_list_rec      => lr_modifier_list_rec
                                          , p_modifier_list_val_rec  => lr_modifier_list_val_rec
                                          , p_modifiers_tbl          => lt_modifiers_tbl
                                          , p_modifiers_val_tbl      => lt_modifiers_val_tbl
                                          , p_qualifiers_tbl         => lt_qualifiers_tbl
                                          , p_qualifiers_val_tbl     => lt_qualifiers_val_tbl
                                          , p_pricing_attr_tbl       => lt_pricing_attr_tbl
                                          , p_pricing_attr_val_tbl   => lt_pricing_attr_val_tbl
                                          , x_modifier_list_rec      => x_modifier_list_rec
                                          , x_modifier_list_val_rec  => x_modifier_list_val_rec
                                          , x_modifiers_tbl          => x_modifiers_tbl
                                          , x_modifiers_val_tbl      => x_modifiers_val_tbl
                                          , x_qualifiers_tbl         => x_qualifiers_tbl
                                          , x_qualifiers_val_tbl     => x_qualifiers_val_tbl
                                          , x_pricing_attr_tbl       => x_pricing_attr_tbl
                                          , x_pricing_attr_val_tbl   => x_pricing_attr_val_tbl
                                          );
        COMMIT;    
        --Added by Fajna on 31-jul-07 START
        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        EXCEPTION
        WHEN FND_API.G_EXC_ERROR THEN
           lc_return_status := FND_API.G_RET_STS_ERROR;
           DBMS_OUTPUT.PUT_LINE('G_RET_STS_ERROR'||lc_data);
           
        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
           lc_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
           FOR k IN 1 .. ln_count 
           LOOP
               lc_data := oe_msg_pub.get( p_msg_index => k,
                                   p_encoded   => 'F'
                                 );
               DBMS_OUTPUT.PUT_LINE('G_EXC_UNEXPECTED_ERROR'||lc_data);
               
           END LOOP;
        WHEN OTHERS THEN
           lc_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
           FOR k IN 1 .. ln_count 
           LOOP
           lc_data := oe_msg_pub.get( p_msg_index => k,
                                      p_encoded => 'F'
                                    );
           DBMS_OUTPUT.PUT_LINE('G_RET_STS_UNEXP_ERROR'||lc_data);
           
           END LOOP; 
        END ;
         --Added by Fajna on 31-jul-07 END

           --Modified by Fajna on 31-jul-07 START
           /* IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               IF ln_msg_count > 0 THEN
                  FOR counter IN 1..ln_msg_count
                  LOOP
                     
                     lc_err_message := 'API Error'||lc_err_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);

                  END LOOP;
                  x_message_code := lc_err_message;
                  x_message_code  := NULL;
                  lc_error_location    := 'API_ERROR';
                  -- Log error in error table
                  XX_COM_ERROR_LOG_PUB.LOG_ERROR
                            (
                             p_program_type            => G_PROG_TYPE     
                            ,p_program_name            => G_PROG_NAME     
                            ,p_module_name             => G_MODULE_NAME   
                            ,p_error_location          => lc_error_location
                            ,p_error_message_code      => x_message_code          
                            ,p_error_message           => x_message_data       
                            ,p_error_message_severity  => G_MAJOR     
                            ,p_notify_flag             => G_NOTIFY        
                           );
                  fnd_msg_pub.delete_msg;
               ELSE
                 x_message_code := 'Sucessfully completed';
               END IF;
            END IF;*/
            --Modified by Fajna on 31-jul-07 END

  --Modified by Fajna on 31-jul-07 ST        
       -- END;


   /* EXCEPTION -- main exception
     WHEN EX_MODIFIER_ERROR THEN
         x_message_code :=NULL;
         -- Log error in error table
         XX_COM_ERROR_LOG_PUB.LOG_ERROR 
         (
           p_program_type            => G_PROG_TYPE     
          ,p_program_name            => G_PROG_NAME     
          ,p_module_name             => G_MODULE_NAME   
          ,p_error_location          => lc_error_location
          ,p_error_message_code      => x_message_code          
          ,p_error_message           => x_message_data       
          ,p_error_message_severity  => G_MAJOR     
          ,p_notify_flag             => G_NOTIFY        
         );    
    WHEN NO_DATA_FOUND THEN
      x_message_code  := NULL;
      x_message_data  := SQLERRM;
      lc_error_location    := 'MAIN_NO_DATA_FOUND';
      -- Log error in error table
      XX_COM_ERROR_LOG_PUB.LOG_ERROR
          (
           p_program_type            => G_PROG_TYPE     
          ,p_program_name            => G_PROG_NAME     
          ,p_module_name             => G_MODULE_NAME   
          ,p_error_location          => lc_error_location
          ,p_error_message_code      => x_message_code          
          ,p_error_message           => x_message_data       
          ,p_error_message_severity  => G_MAJOR     
          ,p_notify_flag             => G_NOTIFY        
         );
    WHEN OTHERS THEN
      x_message_code  := NULL;
      x_message_data  := SQLERRM;
      lc_error_location    := 'MAIN_OTHERS';
      -- Log error in error table
      XX_COM_ERROR_LOG_PUB.LOG_ERROR
          (
           p_program_type            => G_PROG_TYPE     
          ,p_program_name            => G_PROG_NAME     
          ,p_module_name             => G_MODULE_NAME   
          ,p_error_location          => lc_error_location
          ,p_error_message_code      => x_message_code          
          ,p_error_message           => x_message_data       
          ,p_error_message_severity  => G_MAJOR     
          ,p_notify_flag             => G_NOTIFY        
         );*/
    END create_modifier_main;
END xx_qp_modifiers_pkg;
/
SHOW ERRORS;
--EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------
