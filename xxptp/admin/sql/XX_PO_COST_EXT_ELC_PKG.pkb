SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_COST_EXT_ELC_PKG

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                         Oracle NAIO                                            |
-- +================================================================================+
-- | Name       : XX_PO_COST_EXT_ELC_PKG                                           |
-- |                                                                                |
-- | Description: This package is used to compute the Total ELC cost based for a receipt|
-- |              corrosponding to a PO. It also performs account distribution      |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  16-OCT-07      Seemant Gour     Initial draft version                 |
-- |DRAFT 1B  21-OCT-07      Seemant Gour     updated after peer review             |
-- |DRAFT 1C  30-OCT-07      Seemant Gour     Modified with respect to merging of std.|
-- |                                          CSTPACHK for E0348B_WeightedAverageCostDiscounts|
-- |     1.0  31-OCT-07      Seemant Gour     Baseline for Release                  |
-- +================================================================================+

AS

   -------------------------------------------
   -- Global constants used for error handling
   -------------------------------------------
   G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_PO_COST_EXT_ELC_PKG';
   G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'CST';
   G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'N';
   G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
   G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';

   -- To Store the discount value --
   G_ELC_COST              NUMBER := 0;

-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error API|
-- |                with relevant parameters.                               |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+

PROCEDURE LOG_ERROR(p_exception IN VARCHAR2
                   ,p_message   IN VARCHAR2
                   ,p_code      IN NUMBER
                   )
IS

   lc_severity VARCHAR2(15) := NULL;

BEGIN

   IF p_code = -1 THEN
      lc_severity := G_MAJOR;
   ELSIF p_code = 1 THEN
      lc_severity := G_MINOR;
   END IF;

   XX_COM_ERROR_LOG_PUB.LOG_ERROR
                        (
                         p_program_type            => G_PROG_TYPE
                        ,p_program_name            => G_PROG_NAME
                        ,p_module_name             => G_MODULE_NAME
                        ,p_error_location          => p_exception
                        ,p_error_message_code      => p_code
                        ,p_error_message           => p_message
                        ,p_error_message_severity  => lc_severity
                        ,p_notify_flag             => G_NOTIFY
                        );

END LOG_ERROR;

-- +========================================================================+
-- | Name        :  actual_cost                                             |
-- |                                                                        |
-- | Description :  This procedure computes the actual cost based on the    |
-- |                payment terms.                                          |
-- |                                                                        |
-- | Parameters  :  p_org_id                   IN          NUMBER           |
-- |                p_txn_id                   IN          NUMBER           |
-- |                p_layer_id                 IN          NUMBER           |
-- |                p_cost_type                IN          NUMBER           |
-- |                p_cost_method              IN          NUMBER           |
-- |                p_user_id                  IN          NUMBER           |
-- |                p_login_id                 IN          NUMBER           |
-- |                p_req_id                   IN          NUMBER           |
-- |                p_po_number                IN          VARCHAR2         |
-- |                p_po_header_id             IN          NUMBER           |
-- |                p_po_line_id               IN          NUMBER           |
-- |                p_currency_code            IN          VARCHAR2         |
-- |                p_attribute6               IN          VARCHAR2         |
-- |                p_line_num                 IN          NUMBER           |
-- |                p_unit_meas_lookup_code    IN          VARCHAR2         |
-- |                p_actual_cost              IN          NUMBER           |
-- |                p_transaction_action_id    IN          NUMBER           |
-- |                p_transaction_cost         IN          NUMBER           |
-- |                p_prg_appl_id              IN          NUMBER           |
-- |                p_prg_id                   IN          NUMBER           |
-- |                x_err_num                  OUT         NUMBER           |
-- |                x_err_code                 OUT         VARCHAR2         |
-- |                x_err_msg                  OUT         VARCHAR2         |
-- +========================================================================+

FUNCTION actual_cost(
                     p_org_id                   IN          NUMBER,
                     p_txn_id                   IN          NUMBER,
                     p_layer_id                 IN          NUMBER,
                     p_cost_type                IN          NUMBER,
                     p_cost_method              IN          NUMBER,
                     p_user_id                  IN          NUMBER,
                     p_login_id                 IN          NUMBER,
                     p_req_id                   IN          NUMBER,
                     p_prg_appl_id              IN          NUMBER,
                     p_prg_id                   IN          NUMBER,
                     p_po_number                IN          VARCHAR2,
                     p_po_header_id             IN          NUMBER,
                     p_po_line_id               IN          NUMBER,
                     p_currency_code            IN          VARCHAR2,
                     p_attribute6               IN          VARCHAR2,
                     p_line_num                 IN          NUMBER,
                     p_unit_meas_lookup_code    IN          VARCHAR2,
                     p_actual_cost              IN          NUMBER,
                     p_transaction_action_id    IN          NUMBER,
                     p_transaction_cost         IN          NUMBER,
                     p_primary_quantity         IN          NUMBER,
                     x_err_num                  OUT NOCOPY  NUMBER,
                     x_err_code                 OUT NOCOPY  VARCHAR2,
                     x_err_msg                  OUT NOCOPY  VARCHAR2
                    )
RETURN NUMBER IS

   
   x_message_data          VARCHAR2(4000);
   x_message_code          VARCHAR2(100);
   ln_traxn_action_id      NUMBER;
   ln_item_id              mtl_system_items_b.inventory_item_id%TYPE;
   ln_actual_cost          mtl_material_transactions.actual_cost%TYPE;
   ln_primary_quantity     mtl_material_transactions.primary_quantity%TYPE;
   ln_elc_po_nbr           NUMBER;
   ln_elc_po_line_num      NUMBER;
   lc_elc_currency_code    xx_po_elc_costs.currency_cd%TYPE;
   lc_elc_uom_code         xx_po_elc_costs.uom_cd%TYPE;
   lc_elc_import_fee_id    xx_po_elc_costs.import_fee_id%TYPE;
   ln_custom_cst           NUMBER;
   ln_sys_PO_price         NUMBER;

   -----------------------------------------------------------------------------------------
   -- Cursor to fetch the actual cost, primary cost and PO details for the current transaction
   -----------------------------------------------------------------------------------------
   CURSOR lcu_cust_elc_detail(p_po_nbr VARCHAR2, p_ln_num NUMBER) IS
   SELECT XPEC.gss_po_nbr po_number,
          XPEC.po_line_nbr po_line_num,
          SUM(XPEC.import_fee_id) import_fee_id,
          XPEC.currency_cd,
          XPEC.uom_cd
   FROM   xx_po_elc_costs XPEC
   WHERE  XPEC. gss_po_nbr        = p_po_nbr
   AND    XPEC.po_line_nbr        = p_ln_num
   GROUP BY XPEC.gss_po_nbr , XPEC.po_line_nbr,
            XPEC.currency_cd, XPEC.uom_cd;


BEGIN

    /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (1,
          'ACTUAL_COST function:- PO details for traxn id : '|| p_txn_id ||' PO Number: ' ||p_po_number||' PO header ID: ' ||p_po_header_id ||' PO line ID: ' ||p_po_line_id || ' PO line num: '|| p_line_num ||
          ' actual cost: '||p_actual_cost || ' tot landed cost: '|| p_attribute6 || ' Prgm ID: ' ||p_prg_id || ' Req ID: ' ||p_req_id );
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      ---------------------------------------------------------------------------------------------------------------------------
      -- Getting all the cost component values and SUM of the cross docks values of the PO for the current delivered transaction
      ---------------------------------------------------------------------------------------------------------------------------
      FOR cur_cust_elc_detail IN lcu_cust_elc_detail(p_po_number, p_line_num) 
      LOOP
         ln_elc_po_nbr             := cur_cust_elc_detail.po_number;
         ln_elc_po_line_num        := cur_cust_elc_detail.po_line_num;
         lc_elc_import_fee_id      := cur_cust_elc_detail.import_fee_id;
         lc_elc_currency_code      := cur_cust_elc_detail.currency_cd;
         lc_elc_uom_code           := cur_cust_elc_detail.uom_cd;
      END LOOP;

     /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (2,
          'ACTUAL_COST function:- Inside IF for "Trade-Import" and custom ELC table values : '||' PO Number: ' ||ln_elc_po_nbr ||'PO line NUM: ' ||ln_elc_po_line_num ||
          'Import Fee: '||lc_elc_import_fee_id || 'CURR CD: '|| lc_elc_currency_code || 'UOM CD: '|| lc_elc_uom_code);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/
      ------------------------------------------------------
      -- Matching UOM code for the PO with the ELC line UOM
      ------------------------------------------------------
      IF ((NVL(lc_elc_uom_code, 'XXXX')) <> (NVL(p_unit_meas_lookup_code, 'XXXX'))) THEN
         FND_MESSAGE.SET_NAME('CST','XX_PO_62001_INVALID_UOM_CODE');
         FND_MESSAGE.SET_TOKEN('UOM_CD', NVL(lc_elc_uom_code, ' '));
         FND_MESSAGE.SET_TOKEN('UNIT_MEASURE', NVL(p_unit_meas_lookup_code, ' '));

         x_message_data := FND_MESSAGE.GET;
         x_message_code := SQLCODE;

         x_err_msg      := x_message_data;
         x_err_code     := x_message_code;
         
         -------------------------------------------
         -- Inserting the exception in error table
         -------------------------------------------
         BEGIN
            
            INSERT INTO XX_PO_ELC_COSTING_EXTN_ERROR
                   ( org_id
                   , po_header_id
                   , po_line_id
                   , error_code
                   , error_message
                   , last_update_date
                   , last_updated_by
                   , creation_date
                   , created_by
                   , last_update_login
                   )
            VALUES( p_org_id
                  , p_po_header_id
                  , p_po_line_id
                  , x_message_code
                  , x_message_data
                  , SYSDATE
                  , FND_GLOBAL.user_id
                  , SYSDATE
                  , FND_GLOBAL.user_id
                  , FND_GLOBAL.login_id
                  );

            RETURN (1);

         EXCEPTION
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
               FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...1');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));


               x_message_data := FND_MESSAGE.GET;
               x_message_code := SQLCODE;

               LOG_ERROR(p_exception => 'OTHERS'
                        ,p_message   => x_message_data
                        ,p_code      => x_message_code
                        );

               x_err_msg  := SUBSTR(SQLERRM,1,100);
               x_err_code := x_message_code;

               RETURN (-1);

         END;

      END IF; -- IF condition for matching UOM code.
      
      -------------------------------------------------------
      -- Matching CURRENCY code for the PO with the ELC line
      -------------------------------------------------------
      IF ((NVL(lc_elc_currency_code, 'XXXX')) <> (NVL(p_currency_code, 'XXXX'))) THEN
         FND_MESSAGE.SET_NAME('CST','XX_PO_62001_INVALID_CURR_CODE');
         FND_MESSAGE.SET_TOKEN('CURRENCY_CD', NVL(lc_elc_currency_code, ' '));
         FND_MESSAGE.SET_TOKEN('CURRENCY_CODE', NVL(p_currency_code, ' '));


         x_message_data := FND_MESSAGE.GET;
         x_message_code := SQLCODE;

         x_err_msg      := x_message_data;
         x_err_code     := x_message_code;
         
         -------------------------------------------
         -- Inserting the exception in error table
         -------------------------------------------
         BEGIN
            
            INSERT INTO XX_PO_ELC_COSTING_EXTN_ERROR
                   ( org_id
                   , po_header_id
                   , po_line_id
                   , error_code
                   , error_message
                   , last_update_date
                   , last_updated_by
                   , creation_date
                   , created_by
                   , last_update_login
                   )
            VALUES( p_org_id
                  , p_po_header_id
                  , p_po_line_id
                  , x_message_code
                  , x_message_data
                  , SYSDATE
                  , FND_GLOBAL.user_id
                  , SYSDATE
                  , FND_GLOBAL.user_id
                  , FND_GLOBAL.login_id
                  );

            RETURN (1);

         EXCEPTION
            WHEN OTHERS THEN
               FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
               FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...2');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));


               x_message_data := FND_MESSAGE.GET;
               x_message_code := SQLCODE;

               LOG_ERROR(p_exception => 'OTHERS'
                        ,p_message   => x_message_data
                        ,p_code      => x_message_code
                        );

               x_err_msg  := SUBSTR(SQLERRM,1,100);
               x_err_code := x_message_code;

            RETURN (-1);

         END;

      END IF; -- IF condition for matching CURRENCY code.

      -- Calculating system PO cost:
        ln_custom_cst := p_attribute6 - lc_elc_import_fee_id;

      -- Maintaining the system PO cost @ unit level.
      ln_sys_PO_price := ln_custom_cst * p_primary_quantity;
      G_ELC_COST      := ln_sys_PO_price;
      
      -------------------------------------------------------------------------
      -- Updating the material transaction table with the new calculated cost
      -------------------------------------------------------------------------
      BEGIN

         UPDATE mtl_material_transactions
         SET    transaction_cost       = G_ELC_COST
               ,request_id             = p_req_id
               ,program_id             = p_prg_id
               ,program_application_id = p_prg_appl_id
         WHERE transaction_id          = p_txn_id
         RETURNING inventory_item_id
                  ,actual_cost
         INTO      ln_item_id
                  ,ln_actual_cost;
          
        /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (3,
          'ACTUAL_COST function:- Updating MMT tbl with calculate trxn cost: ' || G_ELC_COST);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      EXCEPTION 
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...3');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));


            x_message_data := FND_MESSAGE.GET;
            x_message_code := SQLCODE;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SUBSTR(SQLERRM,1,100);
            x_err_code := x_message_code;

     /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (4,
          'ACTUAL_COST function:- Error in Updating MMT tbl with calculate trxn cost: ' || G_ELC_COST || x_message_data || x_err_code || x_err_msg);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured while updating MMT table in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

      END;

      BEGIN

         UPDATE mtl_cst_txn_cost_details
         SET    transaction_cost       = G_ELC_COST
               ,request_id             = p_req_id
               ,program_id             = p_prg_id
               ,program_application_id = p_prg_appl_id
         WHERE  transaction_id         = p_txn_id
         AND    organization_id        = p_org_id;

     /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (5,
          'ACTUAL_COST function:- Updating MCTCD tbl with calculate trxn cost: ' || G_ELC_COST );
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      EXCEPTION 
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...4');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

            x_message_data := FND_MESSAGE.GET;
            x_message_code := SQLCODE;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SUBSTR(SQLERRM,1,100);
            x_err_code := x_message_code;

     /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (6,
          'ACTUAL_COST function:- Error in Updating MCTCD tbl with calculate trxn cost: ' || G_ELC_COST || x_message_data || x_err_code || x_err_msg);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured while updating MCTCD table in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

      END;

      ------------------------------------------------------
      -- Inserting into MTL_CST_ACTUAL_COST_DETAILS table.
      ------------------------------------------------------

      BEGIN

         INSERT INTO mtl_cst_actual_cost_details
                     ( layer_id
                     , transaction_id
                     , organization_id
                     , cost_element_id
                     , level_type
                     , transaction_action_id
                     , last_update_date
                     , last_updated_by
                     , creation_date
                     , created_by
                     , last_update_login
                     , inventory_item_id
                     , actual_cost
                     , insertion_flag
                     , user_entered
                     )
         VALUES      ( p_layer_id
                     , p_txn_id
                     , p_org_id
                     , 1
                     , 1
                     , p_transaction_action_id
                     , SYSDATE
                     , FND_GLOBAL.user_id
                     , SYSDATE
                     , FND_GLOBAL.user_id
                     , FND_GLOBAL.login_id
                     , ln_item_id
                     , p_actual_cost
                     , 'Y'
                     , 'Y'
                     );

         COMMIT;

    /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (7,
          'ACTUAL_COST function:- Inserting into MCACD tbl with actual cost: ' || p_actual_cost || 'Trxn action id: ' || p_transaction_action_id || ' Txn ID: ' ||p_txn_id);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

      EXCEPTION 
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...5');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));
   
            x_message_data := FND_MESSAGE.GET;
            x_message_code := SQLCODE;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SUBSTR(SQLERRM,1,100);
            x_err_code := x_message_code;

    /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (8,
          'ACTUAL_COST function:- Error in inserting MCACD tbl with actual cost: ' || p_actual_cost || x_message_data || x_err_code || x_err_msg);
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured while inserting into mtl_cst_actual_cost_details table in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

      END;

      RETURN (1);

EXCEPTION 
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
      FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.actual_cost...6');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

      x_message_data := FND_MESSAGE.GET;

      LOG_ERROR(p_exception => 'OTHERS'
               ,p_message   => x_message_data
               ,p_code      => x_message_code
               );

      x_err_msg  := SUBSTR(SQLERRM,1,100);
      x_err_code := SQLCODE;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

      RETURN (-1);

END actual_cost;

-- +========================================================================+
-- | Name        :  cost_dist                                               |
-- |                                                                        |
-- | Description :  This procedure is used for the cost distribution based  |
-- |                on the inventory account.                               |
-- |                                                                        |
-- | Parameters  :  p_org_id      IN  NUMBER,                               |
-- |                p_txn_id      IN  NUMBER,                               |
-- |                p_user_id     IN  NUMBER,                               |
-- |                p_login_id    IN  NUMBER,                               |
-- |                p_req_id      IN  NUMBER,                               |
-- |                p_prg_appl_id IN  NUMBER,                               |
-- |                p_prg_id      IN  NUMBER,                               |
-- |                x_err_num     OUT NUMBER,                               |
-- |                x_err_code    OUT VARCHAR2                              |
-- |                x_err_msg     OUT VARCHAR2                              |
-- |                                                                        |
-- +========================================================================+

FUNCTION cost_dist(
                   p_org_id                   IN          NUMBER,
                   p_txn_id                   IN          NUMBER,
                   p_user_id                  IN          NUMBER,
                   p_login_id                 IN          NUMBER,
                   p_req_id                   IN          NUMBER,
                   p_prg_appl_id              IN          NUMBER,
                   p_prg_id                   IN          NUMBER,
                   p_po_number                IN          VARCHAR2,
                   p_po_header_id             IN          NUMBER,
                   p_po_line_id               IN          NUMBER,
                   p_actual_cost              IN          NUMBER,
                   p_transaction_action_id    IN          NUMBER,
                   p_transaction_cost         IN          NUMBER,
                   p_primary_quantity         IN          NUMBER,
                   p_dist_account_id          IN          NUMBER,
                   x_err_num                  OUT NOCOPY  NUMBER,
                   x_err_code                 OUT NOCOPY  VARCHAR2,
                   x_err_msg                  OUT NOCOPY  VARCHAR2
                  )
RETURN NUMBER IS

   ln_material_account        mtl_parameters.material_account%TYPE;
   lc_return_status           VARCHAR2(1);
   ln_msg_count               NUMBER;
   lc_msg_data                VARCHAR2(4000);
   x_message_data             VARCHAR2(4000);
   x_message_code             VARCHAR2(100);
   lc_error_msg               VARCHAR2(4000);
   ln_ccid                    po_distributions_all.code_combination_id%TYPE;
   lc_material_code           po_distributions_all.code_combination_id%TYPE;
   ln_code_comb_id            po_distributions_all.code_combination_id%TYPE;
   ln_transaction_cost        mtl_material_transactions.transaction_cost%TYPE;
   lc_enabled_flg             gl_code_combinations.enabled_flag%TYPE;
   lc_seg1                    gl_code_combinations.segment1%TYPE;
   lc_seg2                    gl_code_combinations.segment2%TYPE;
   lc_seg3                    gl_code_combinations.segment3%TYPE;
   lc_seg4                    gl_code_combinations.segment4%TYPE;
   lc_seg5                    gl_code_combinations.segment5%TYPE;
   lc_seg6                    gl_code_combinations.segment6%TYPE;
   lc_seg7                    gl_code_combinations.segment7%TYPE;
   x_msg                      VARCHAR2(2000);


   CURSOR lcu_po_details(ln_po_hdr_id NUMBER, ln_po_line_id NUMBER) IS
      SELECT  GCC.code_combination_id ccid
             ,GCC.enabled_flag
             ,GCC.segment1
             ,GCC.segment2
             ,GCC.segment3
             ,GCC.segment4
             ,GCC.segment5
             ,GCC.segment6
             ,GCC.segment7
      FROM   po_distributions_all PDA,
             gl_code_combinations GCC
      WHERE PDA.code_combination_id = GCC.code_combination_id
      AND   PDA.po_header_id        = ln_po_hdr_id
      AND   PDA.po_line_id          = ln_po_line_id;

   ----------------------------------------------------
   -- Cursor to fetch the Organization material account
   ----------------------------------------------------
   CURSOR lcu_org_mat_acct(ln_org_id NUMBER) IS
   SELECT MP.material_account
   FROM   mtl_parameters MP
   WHERE  MP.organization_id = ln_org_id;

BEGIN

   FOR cur_po_details IN lcu_po_details(p_po_header_id, p_po_line_id) LOOP
         ln_ccid                   := cur_po_details.ccid;
         lc_enabled_flg            := cur_po_details.enabled_flag;
         lc_seg1                   := cur_po_details.segment1;
         lc_seg2                   := cur_po_details.segment2;
         lc_seg3                   := cur_po_details.segment3;
         lc_seg4                   := cur_po_details.segment4;
         lc_seg5                   := cur_po_details.segment5;
         lc_seg6                   := cur_po_details.segment6;
         lc_seg7                   := cur_po_details.segment7;
   END LOOP;

   /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (1,
          ' COST_DIST function:- Inside IF for Trade-Import and traxn id is: '|| p_txn_id ||' PO header ID: ' ||p_po_header_id ||' PO line ID: ' ||p_po_line_id || ' Prgm ID: ' ||p_prg_id || ' Req ID: ' ||p_req_id );
         COMMIT;
     EXCEPTION WHEN OTHERS THEN 
        NULL;
     END;*/
     
      ln_transaction_cost := p_transaction_cost * p_primary_quantity;

      -- Code For generating the Inventory Valuation Account --
      ----------------------------------------
      -- Get the organization material account
      ----------------------------------------
      FOR cur_org_mat_acct IN lcu_org_mat_acct(p_org_id) LOOP
         ln_material_account := cur_org_mat_acct.material_account;
      END LOOP;

      /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (2,
          'COST_DIST function:-  Material Account of txn: '|| ln_material_account);
         COMMIT;
      EXCEPTION WHEN OTHERS THEN 
        NULL;
      END;*/

      /* BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (3,
            'COST_DIST function:- Before Std API insertion for inv. valuation A/c ' || 'p_org_id: ' ||p_org_id ||' p_txn_id: '||p_txn_id ||
                       ' p_user_id: '|| p_user_id || 'p_prg_id: '||p_prg_id || 'ln_material_account: '||ln_material_account ||'ln_transaction_cost: '|| ln_transaction_cost);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/
      -------------------------------------------------------------
      -- Build the account of the transaction
      -- The Data will get inserted to transaction material account
      -------------------------------------------------------------
      FND_MSG_PUB.INITIALIZE;

      Cst_Utility_Pub.insert_MTA(p_api_version   => 1.0 ,
                                 p_init_msg_list => Fnd_Api.G_TRUE,
                                 p_commit        => Fnd_Api.G_TRUE,
                                 x_return_status => lc_return_status,
                                 x_msg_count     => ln_msg_count,
                                 x_msg_data      => lc_msg_data,
                                 p_org_id        => p_org_id,
                                 p_txn_id        => p_txn_id,
                                 p_user_id       => p_user_id,
                                 p_login_id      => p_login_id,
                                 p_req_id        => p_req_id,
                                 p_prg_appl_id   => p_prg_appl_id,
                                 p_prg_id        => p_prg_id,
                                 p_account       => ln_material_account,
                                 p_dbt_crdt      => 1,                   -- 1 for debit
                                 p_line_typ      => 1,                   -- Inventory valuation lookup code from 'CST_ACCOUNTING_LINE_TYPE',
                                 p_bs_txn_val    => ln_transaction_cost,
                                 p_cst_element   => 1,                   --  Considering the material cost
                                 p_resource_id   => NULL,
                                 p_encumbr_id    => NULL
                                );
      
      /*BEGIN
        INSERT INTO XXSAM1
        (POSITION,    
         REASON) 
        VALUES
         (4,
          'COST_DIST function:- After call to std API for Inventory Valuation debit Account' || lc_return_status || 'MSG count: '||ln_msg_count ||' Error msg: '||lc_msg_data);
         COMMIT;
       EXCEPTION WHEN OTHERS THEN 
          NULL;
       END;*/

      IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
         NULL;
      ELSE
         IF ln_msg_count = 1 THEN

            FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...1');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

            x_message_data := FND_MESSAGE.GET;
            x_message_code := SQLCODE;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SUBSTR(SQLERRM,1,100);
            x_err_code := x_message_code;
           
            /*BEGIN
              INSERT INTO XXSAM1
              (POSITION,    
               REASON) 
              VALUES
               (5,
                'COST_DIST function:- After call to std API for Inventory Valuation Account logging error' || lc_return_status || x_message_data || x_err_msg);
               COMMIT;
             EXCEPTION WHEN OTHERS THEN 
                NULL;
             END;*/

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

         ELSE
            FOR l_index IN 1..ln_msg_count
            LOOP
               lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                          ,p_encoded => FND_API.G_FALSE),1,100);

               FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
               FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...2');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

               x_message_data := FND_MESSAGE.GET;
               x_message_code := SQLCODE;

               LOG_ERROR(p_exception => 'OTHERS'
                        ,p_message   => x_message_data
                        ,p_code      => x_message_code
                        );

               x_err_msg  := SUBSTR(SQLERRM,1,100);
               x_err_code := x_message_code;

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

            END LOOP;
         END IF;
      END IF; --Return status validation
      -- End of Inventory Valuation Account --

      -- Code For generating the Receiving Inspection Account --
      --------------------------------------------------------------------------
      -- The po receipt inspection This will credit to the transaction account
      --------------------------------------------------------------------------
      /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (6,
            'COST_DIST function:- Before Std API insertion for Recv. Insp. A/c ' || 'p_org_id: ' ||p_org_id ||' p_txn_id: '||p_txn_id ||
                       ' p_user_id: '|| p_user_id || 'p_prg_id: '||p_prg_id || 'p_dist_account_id: '||p_dist_account_id ||'ln_transaction_cost: '|| ln_transaction_cost);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      Cst_Utility_Pub.insert_MTA(p_api_version   => 1.0 ,
                                 p_init_msg_list => Fnd_Api.G_TRUE,
                                 p_commit        => Fnd_Api.G_TRUE,
                                 x_return_status => lc_return_status,
                                 x_msg_count     => ln_msg_count,
                                 x_msg_data      => lc_msg_data,
                                 p_org_id        => p_org_id,
                                 p_txn_id        => p_txn_id,
                                 p_user_id       => p_user_id,
                                 p_login_id      => p_login_id,
                                 p_req_id        => p_req_id,
                                 p_prg_appl_id   => p_prg_appl_id,
                                 p_prg_id        => p_prg_id,
                                 p_account       => p_dist_account_id,                      -- lc_dist_account_id,
                                 p_dbt_crdt      => -1,                                     --  -1 for credit
                                 p_line_typ      => 5,                                      --  Receiving inspection lookup code from 'CST_ACCOUNTING_LINE_TYPE',
                                 p_bs_txn_val    => ln_transaction_cost,                    --  pass the original purchase order cost
                                 p_cst_element   => 1 ,                                     --  Considering the material cost
                                 p_resource_id   => NULL ,
                                 p_encumbr_id    => NULL
                                );

          /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (7,
            'COST_DIST function:- After call to std API for Receiving Inspection Credit Account ' || lc_return_status || ' MSG count: '||ln_msg_count ||' Error msg: '||lc_msg_data);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
         NULL;
      ELSE
         IF ln_msg_count = 1 THEN

            FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...3');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

            x_message_data := FND_MESSAGE.GET;
            x_message_code := SQLCODE;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SUBSTR(SQLERRM,1,100);
            x_err_code := x_message_code;

         /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (8,
            'COST_DIST function:- After call to std API for Receiving Inspection Account logging error  ' || lc_return_status || x_message_data || x_err_msg);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure: ' || x_err_msg || '  :  ' || SUBSTR(x_err_code,1,240));

         ELSE
            FOR l_index IN 1..ln_msg_count
            LOOP
               lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                          ,p_encoded => FND_API.G_FALSE),1,100);

               FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
               FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...4');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

               x_message_data := FND_MESSAGE.GET;
               x_message_code := SQLCODE;

               LOG_ERROR(p_exception => 'OTHERS'
                        ,p_message   => lc_error_msg
                        ,p_code      => x_message_code
                        );

               x_err_msg  := SUBSTR(SQLERRM,1,100);
               x_err_code := x_message_code;

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

            END LOOP;
            

         END IF;
      END IF; --Return status validation
      -- End of Receiving Inspection Account --

       /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (9,
            'COST_DIST function:- before checking for enabled flag:  ' || lc_enabled_flg);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      --------------------------------------------------------------------------------------------------------------
      -- Code for Generating all the Custom Account on the basis of custom table XX_PO_ELC_COST_EXTN_ACC_DIST --
      --------------------------------------------------------------------------------------------------------------
     /* IF lc_enabled_flg = 'N' THEN
         FND_MESSAGE.SET_NAME('CST','XX_PO_62001_CCID_DISABLED');
         FND_MESSAGE.SET_TOKEN('ACCOUNT-SEGMENTS', lc_seg1||'.'||lc_seg2||'.'||lc_seg3||'.'|| lc_seg4||'.'||lc_seg5||'.'||lc_seg6||'.'|| lc_seg7);
         x_message_data := FND_MESSAGE.GET;
         x_message_code := SQLCODE;

          BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (10,
            'COST_DIST function:- Inside check for enabled flag, before inserting into error table:  ');
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END; 
         -------------------------------------------
         -- Inserting the exception in error table
         -------------------------------------------
         INSERT INTO XX_PO_ELC_COSTING_EXTN_ERROR
                ( org_id
                , po_header_id
                , po_line_id
                , error_code
                , error_message
                , last_update_date
                , last_updated_by
                , creation_date
                , created_by
                , last_update_login
                )
         VALUES( p_org_id
               , p_po_header_id
               , p_po_line_id
               , x_message_code
               , x_message_data
               , SYSDATE
               , FND_GLOBAL.user_id
               , SYSDATE
               , FND_GLOBAL.user_id
               , FND_GLOBAL.login_id
               );

         BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (11,
            'COST_DIST function:- Enabled flag for CCID is "N"' || x_message_data || 'PO header ID: '||p_po_header_id ||' PO line ID: '|| p_po_line_id ||'After logging into error table');
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END; 

         RETURN (-1);
      END IF;
      */
      ------------------------------------------------------------------------------------
      -- The natural account segment from custom table will replace the segment3 of the
      -- Charge account of Purchase order for which the receipt has been created.
      ------------------------------------------------------------------------------------
        /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (12,
            'COST_DIST function:- ELSE of lc_enable_flag IF condition, Before cur_idx cursor  FOR LOOP');
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      FOR cur_idx IN (SELECT * 
                  FROM XX_PO_ELC_COST_EXTN_ACC_DIST) 
      LOOP

      /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (13,
            'COST_DIST function:- Inside cur_idx FOR LOOP ' || '  lc_seg1:  ' ||lc_seg1 ||'  lc_seg2:  '||lc_seg2 ||
                       '  lc_seg4:  '|| lc_seg4 || '  lc_seg5:  '||lc_seg5 || '  lc_seg6:  '||lc_seg6 ||'  lc_seg7:  '|| lc_seg7);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

     ----------------------------------------------------------------------------
     -- Code for Generating all the Custom Account on the basis of custom table 
     -- natural account XX_PO_ELC_COST_EXTN_ACC_DIST      
     ----------------------------------------------------------------------------
          BEGIN

             SELECT  GCC1.code_combination_id ccid,
                     GCC1.enabled_flag
             INTO    ln_code_comb_id
                    ,lc_enabled_flg
             FROM    gl_code_combinations GCC1
             WHERE   GCC1.segment1 = lc_seg1
             AND     GCC1.segment2 = lc_seg2
             AND     GCC1.segment3 = cur_idx.natural_account
             AND     GCC1.segment4 = lc_seg4
             AND     GCC1.segment5 = lc_seg5
             AND     GCC1.segment6 = lc_seg6
             AND     GCC1.segment7 = lc_seg7;
             
             IF lc_enabled_flg = 'N' THEN
	              FND_MESSAGE.SET_NAME('CST','XX_PO_62001_CCID_DISABLED');
	              FND_MESSAGE.SET_TOKEN('Account Segments: ', lc_seg1||'.'||lc_seg2||'.'||
	                                                          cur_idx.natural_account||'.'|| 
	                                                          lc_seg4||'.'||lc_seg5||'.'||
	                                                          lc_seg6||'.'|| lc_seg7);
	              x_message_data := FND_MESSAGE.GET;
	              x_message_code := SQLCODE;
	     
	              /*BEGIN
	               INSERT INTO XXSAM1
	               (POSITION,    
	                REASON) 
	               VALUES
	                (10,
	                 'COST_DIST function:- Inside check for enabled flag, before inserting into error table:  ');
	                COMMIT;
	              EXCEPTION WHEN OTHERS THEN 
	                 NULL;
	              END;*/
	              -------------------------------------------
	              -- Inserting the exception in error table
	              -------------------------------------------
	              INSERT INTO XX_PO_ELC_COSTING_EXTN_ERROR
	                     ( org_id
	                     , po_header_id
	                     , po_line_id
	                     , error_code
	                     , error_message
	                     , last_update_date
	                     , last_updated_by
	                     , creation_date
	                     , created_by
	                     , last_update_login
	                     )
	              VALUES( p_org_id
	                    , p_po_header_id
	                    , p_po_line_id
	                    , x_message_code
	                    , x_message_data
	                    , SYSDATE
	                    , FND_GLOBAL.user_id
	                    , SYSDATE
	                    , FND_GLOBAL.user_id
	                    , FND_GLOBAL.login_id
	                    );
	     
	             /*BEGIN
	               INSERT INTO XXSAM1
	               (POSITION,    
	                REASON) 
	               VALUES
	                (11,
	                 'COST_DIST function:- Enabled flag for CCID is "N"' || x_message_data || 'PO header ID: '||p_po_header_id ||' PO line ID: '|| p_po_line_id ||'After logging into error table');
	                COMMIT;
	              EXCEPTION WHEN OTHERS THEN 
	                 NULL;
	              END;*/
	     
	              RETURN (-1);
                 END IF;
         
         /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (14,
            'COST_DIST function:- Getting CCID from custom table is :  ' || ln_code_comb_id || '  for segments value '|| lc_seg1||'.'||lc_seg2||'.'|| cur_idx.natural_account ||'.'||lc_seg4||'.'||lc_seg5||'.'|| lc_seg6||'.'||lc_seg7);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
              
                BEGIN

                   FND_MESSAGE.SET_NAME ('CST','XX_PO_62001_CCID_NOT_FOUND');
                   FND_MESSAGE.SET_TOKEN ('ACCOUNT-SEGMENTS ', lc_seg1||'.'||lc_seg2||'.'||
                                                               cur_idx.natural_account||'.'||lc_seg4||'.'||
                                                               lc_seg5||'.'|| lc_seg6||'.'||lc_seg7);

                   x_message_data := FND_MESSAGE.GET;
                   x_message_code := SQLCODE;

                   -------------------------------------------
                   -- Inserting the exception in error table
                   -------------------------------------------
                   INSERT INTO XX_PO_ELC_COSTING_EXTN_ERROR
                            ( org_id
                            , po_header_id
                            , po_line_id
                            , error_code
                            , error_message
                            , last_update_date
                            , last_updated_by
                            , creation_date
                            , created_by
                            , last_update_login
                            )
                   VALUES( p_org_id
                         , p_po_header_id
                         , p_po_line_id
                         , x_message_code
                         , x_message_data
                         , SYSDATE
                         , FND_GLOBAL.user_id
                         , SYSDATE
                         , FND_GLOBAL.user_id
                         , FND_GLOBAL.login_id
                         );
                EXCEPTION
                   WHEN OTHERS THEN
                      x_msg := substr(sqlerrm,1,400);
                          /*INSERT INTO XXSAM1
                                  (POSITION,    
                                   REASON) 
                                  VALUES
                                   (15.1,
                                    'COST_DIST function: ' || x_msg||' ===' || x_message_data);*/
                END;

                    /*BEGIN
                      INSERT INTO XXSAM1
                       (POSITION,    
                       REASON) 
                      VALUES
                       (15,
                       'COST_DIST function:- Inside NO_DATA_FOUND exect. for gettingCCID from custom table: ' || ln_code_comb_id || x_message_data);
                      COMMIT;
                    EXCEPTION WHEN OTHERS THEN 
                       NULL;
                    END;*/

                     RETURN (-1);
             

             WHEN OTHERS THEN
               x_message_data := 'For Account : ' || lc_seg1||'.'||lc_seg2||'.'||cur_idx.natural_account||'.'||lc_seg4||'.'||lc_seg5||'.'|| lc_seg6||'.'||lc_seg7 ||' some other error occured';
               x_message_code := SUBSTR(SQLERRM,1,100);
               
               x_err_msg  := x_message_data ||SUBSTR(SQLERRM,1,100);
               x_err_code := x_message_code;

               RETURN (-1);
            
          END;
         
          IF cur_idx.debit IS NOT NULL THEN
             
             -- Generate the debit account distribution for the N/A account 
             -- Assign the lookup code of the 'N/A' and store it in lc_material_code variable.

             Cst_Utility_Pub.insert_MTA
                 ( p_api_version     => 1.0,
                   p_init_msg_list   => Fnd_Api.G_TRUE,
                   p_commit          => Fnd_Api.G_TRUE,
                   x_return_status   => lc_return_status,
                   x_msg_count       => ln_msg_count,
                   x_msg_data        => lc_msg_data,
                   p_org_id          => p_org_id,
                   p_txn_id          => p_txn_id,
                   p_user_id         => p_user_id,
                   p_login_id        => p_login_id,
                   p_req_id          => p_req_id,
                   p_prg_appl_id     => p_prg_appl_id,
                   p_prg_id          => p_prg_id,
                   p_account         => ln_code_comb_id,
                   p_dbt_crdt        => 1,                   -- 1 for debit 
                   p_line_typ        => lc_material_code,    -- Lookup code 17,
                   p_bs_txn_val      => cur_idx.debit,       -- custom table debit value
                   p_cst_element     => 1,
                   p_resource_id     => NULL,
                   p_encumbr_id      => NULL 
                           );

        /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (16,
            'COST_DIST function:-  After Std. API call for N/A account for debit: ' || cur_idx.debit || lc_return_status);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

             IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
               NULL;
             ELSE
                IF ln_msg_count = 1 THEN
                   FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
                   FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...5');
                   FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

                   x_message_data := FND_MESSAGE.GET;
                   x_message_code := SQLCODE;

                   LOG_ERROR(p_exception => 'OTHERS'
                            ,p_message   => x_message_data
                            ,p_code      => x_message_code
                            );

                   x_err_msg  := SUBSTR(SQLERRM,1,100);
                   x_err_code := x_message_code;

        /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (17,
            'COST_DIST function:-  Error After Std. API call for N/A account for debit: ' || lc_return_status || x_message_data || x_err_msg);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));
                ELSE
                   FOR l_index IN 1..ln_msg_count
                   LOOP
                      lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                                 ,p_encoded => FND_API.G_FALSE),1,100);

                      FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
                      FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...6');
                      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

                      x_message_data := FND_MESSAGE.GET;
                      x_message_code := SQLCODE;

                      LOG_ERROR(p_exception => 'OTHERS'
                               ,p_message   => lc_error_msg
                               ,p_code      => x_message_code
                               );

                      x_err_msg  := SUBSTR(SQLERRM,1,100);
                      x_err_code := x_message_code;

                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));
                   END LOOP;
                END IF;  -- End of ln_msg_count =1 check
             END IF; -- End of lc_return_status check
          ELSE 
            /*Generate the credit account distribution for the N/A account */

            -- Assign the lookup code of the 'N/A' and store it in lc_material_code variable.

            Cst_Utility_Pub.insert_MTA
                ( p_api_version     => 1.0,
                  p_init_msg_list   => Fnd_Api.G_TRUE,
                  p_commit          => Fnd_Api.G_TRUE,
                  x_return_status   => lc_return_status,
                  x_msg_count       => ln_msg_count,
                  x_msg_data        => lc_msg_data,
                  p_org_id          => p_org_id,
                  p_txn_id          => p_txn_id,
                  p_user_id         => p_user_id,
                  p_login_id        => p_login_id,
                  p_req_id          => p_req_id,
                  p_prg_appl_id     => p_prg_appl_id,
                  p_prg_id          => p_prg_id,
                  p_account         => ln_code_comb_id,
                  p_dbt_crdt        => -1,                  -- -1 for credit 
                  p_line_typ        => lc_material_code,    -- Lookup code --17,
                  p_bs_txn_val      => cur_idx.credit,      -- Custom table credit value
                  p_cst_element     => 1,
                  p_resource_id     => NULL,
                  p_encumbr_id      => NULL 
                          );

        /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (18,
            'COST_DIST function:-  After Std. API call for N/A account for credit: ' || cur_idx.credit || lc_return_status );
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

            IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
              NULL;
            ELSE
               IF ln_msg_count = 1 THEN
                  FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
                  FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...7');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

                  x_message_data := FND_MESSAGE.GET;
                  x_message_code := SQLCODE;

                  LOG_ERROR(p_exception => 'OTHERS'
                           ,p_message   => x_message_data
                           ,p_code      => x_message_code
                           );

                  x_err_msg  := SUBSTR(SQLERRM,1,100);
                  x_err_code := x_message_code;

        /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (19,
            'COST_DIST function:-  Error After Std. API call for N/A account for credit: ' || cur_idx.credit || lc_return_status || x_message_data || x_err_msg);
          COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));
               ELSE
                  FOR l_index IN 1..ln_msg_count
                  LOOP
                     lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                                ,p_encoded => FND_API.G_FALSE),1,100);

                     FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
                     FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...8');
                     FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));

                     x_message_data := FND_MESSAGE.GET;
                     x_message_code := SQLCODE;

                     LOG_ERROR(p_exception => 'OTHERS'
                              ,p_message   => lc_error_msg
                              ,p_code      => x_message_code
                              );

                     x_err_msg  := SUBSTR(SQLERRM,1,100);
                     x_err_code := x_message_code;

                     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));
                  END LOOP;
                  
               END IF;  -- End of ln_msg_count =1 check
             END IF; -- End of lc_return_status check
          END IF; -- Checking for debit value not null

      END LOOP;
      
       /*BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (20,
            'COST_DIST function:-  Successful creation of N/A account for credit/debit before returning (1)');
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      RETURN (1); -- Returning a value of 1 means the cost hook is used.

EXCEPTION 
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('CST','XX_PO_62001_UNEXP_ERR');
      FND_MESSAGE.SET_TOKEN('PROC','XX_PO_COST_EXT_ELC_PKG.cost_dist...9');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SUBSTR(SQLERRM,1,100));
 
      x_message_data := FND_MESSAGE.GET;
      x_message_code := SQLCODE;
      
      /*DECLARE 
        x_err VARCHAR2(2000) := SQLCODE;
        xmsg  VARCHAR2(2000) := SQLERRM;
      BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (21,
            'COST_DIST function:- Main Error for function '|| x_err  || xmsg);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      LOG_ERROR(p_exception => 'OTHERS'
               ,p_message   => x_message_data
               ,p_code      => x_message_code
               );

      x_err_msg  := SUBSTR(SQLERRM,1,100);
      x_err_code := x_message_code;

     /*/BEGIN
          INSERT INTO XXSAM1
          (POSITION,    
           REASON) 
          VALUES
           (22,
            'COST_DIST function:-  In the main OTHERS except of the function ' ||x_message_data || x_err_msg);
           COMMIT;
         EXCEPTION WHEN OTHERS THEN 
            NULL;
         END;*/

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

      RETURN (-1);

END cost_dist;

END XX_PO_COST_EXT_ELC_PKG;
/

SHOW ERRORS;

EXIT;