SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_TDS_INV_COST_HOOK_EXT
PROMPT Program exits if the creation is not successful
CREATE OR REPLACE PACKAGE BODY XX_TDS_INV_COST_HOOK_EXT AS
-- +============================================================================================+
-- |  Office Depot - TDS project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- |  Name:  XX_TDS_INV_COST_HOOK_EXT                                                           |
-- |  Rice Id : I3029                                                                           |
-- |  Description:  This OD Package that contains a function to define custom extension    Item |
-- |                accounting derivation.                                                      |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    =================================================|
-- | 1.0         12-JUL-2011  Suraj Charan     Initial version                                  |
-- +============================================================================================+
   function cost_dist_hook_ext (
                                           i_org_id        IN              NUMBER,
                       i_txn_id        IN              NUMBER,
                       i_user_id       IN              NUMBER,
                       i_login_id      IN              NUMBER,
                       i_req_id        IN              NUMBER,
                       i_prg_appl_id   IN              NUMBER,
                       i_prg_id        IN              NUMBER,
                       o_err_num       OUT NOCOPY      NUMBER,
                       o_err_code      OUT NOCOPY      VARCHAR2,
                       o_err_msg       OUT NOCOPY      VARCHAR2
                                )
   return integer  IS
   
   ln_sob_id                NUMBER;
   ln_cost_grp_id           NUMBER;
   ln_item_id               NUMBER;
   ld_txn_date              DATE;
   ln_p_qty                 NUMBER;
   lv_subinv                VARCHAR2 (10);
   ln_txn_act_id            NUMBER;
   ln_txn_src_id            NUMBER;
   ln_src_type_id           NUMBER;
   lv_pri_curr              VARCHAR2 (15);
   lv_alt_curr              VARCHAR2 (10);
   ld_conv_date             DATE;
   ln_conv_rate             NUMBER;
   lv_conv_type             VARCHAR2 (30);
   ln_dist_acct             NUMBER;
   ln_logical_txn           NUMBER;
   ln_bs_txn_val            NUMBER;
   lc_structure_number      NUMBER;
   lc_conc_segments         VARCHAR2 (150);
   lc_segment1              VARCHAR2 (30);
   lc_segment2              VARCHAR2 (30);
   lc_segment3              VARCHAR2 (30);
   lc_segment4              VARCHAR2 (30);
   lc_segment5              VARCHAR2 (30);
   lc_segment6              VARCHAR2 (30);
   lc_segment7              VARCHAR2 (30);
   ln_mat_acct              NUMBER;
   lv_return_status         VARCHAR2 (1);
   ln_msg_count             NUMBER;
   lv_msg_data              VARCHAR2 (240);
   lv_item_type         VARCHAR2 (30);
   lv_department        VARCHAR2 (40);
   lv_segment1          VARCHAR2 (40);
   process_error            EXCEPTION;

   CURSOR c_parts
      IS
      SELECT *
      FROM mtl_material_transactions
      WHERE transaction_id = i_txn_id
      AND organization_id = i_org_id
        ;

      

   BEGIN
   o_err_num := 0;
   o_err_code := '';
   o_err_msg := '';

   FOR parts_rec IN c_parts
   LOOP
     
      SELECT msi.item_type ,length(msi.segment1)
      INTO lv_item_type, lv_segment1
      FROM Mtl_System_Items_B Msi
      WHERE msi.inventory_item_id = parts_rec.inventory_item_id
      AND  msi.organization_id = Parts_Rec.organization_id
      ;
      -- To check the item type is '02' and segment1 lenth is equal to 8 then perform the below logic:
      IF lv_item_type = '02' AND lv_segment1 = 8
      THEN
         SELECT set_of_books_id
         INTO ln_sob_id
         FROM   org_organization_definitions
         WHERE organization_id = i_org_id;

         SELECT currency_code
         INTO lv_pri_curr
         FROM gl_sets_of_books
         WHERE set_of_books_id = ln_sob_id;

         ln_cost_grp_id := NVL (parts_rec.cost_group_id, 1);
         ln_item_id := parts_rec.inventory_item_id;
         ld_txn_date := parts_rec.transaction_date;
         ln_p_qty := parts_rec.primary_quantity;
         lv_subinv := parts_rec.subinventory_code;
         ln_txn_act_id := parts_rec.transaction_action_id;
         ln_txn_src_id := parts_rec.transaction_source_id;
         ln_src_type_id := parts_rec.transaction_source_type_id;
         ln_dist_acct := NVL (parts_rec.distribution_account_id, -1);
         lv_alt_curr := NULL;
         ld_conv_date := NVL (parts_rec.currency_conversion_date, parts_rec.transaction_date);
         ln_conv_rate := NVL (parts_rec.currency_conversion_rate, -1);
         lv_conv_type := parts_rec.currency_conversion_type;
         ln_bs_txn_val := NVL (parts_rec.actual_cost, parts_rec.transaction_cost);

         IF (ln_txn_act_id IN (2, 5, 28, 55))
         THEN
            RETURN 0;
         ELSIF (ln_txn_act_id IN (3, 12, 21))
         THEN
            RETURN 0;
         ELSIF (ln_txn_act_id = 24 AND ln_src_type_id = 13)
         THEN
            RETURN 0;
         ELSIF (ln_logical_txn = 1)
         THEN
            RETURN 0;
         ELSIF (ln_txn_act_id = 25 AND ln_src_type_id = 1)
         THEN
            RETURN 0;
         ELSIF ln_txn_act_id IN (1, 27)
         THEN
            SELECT id_flex_num
            INTO lc_structure_number
            FROM fnd_id_flex_structures
            WHERE application_id = 101
            AND id_flex_code = 'GL#'
            AND id_flex_structure_code = 'OD_GLOBAL_COA';

            SELECT glc.segment1, glc.segment2, glc.segment4, glc.segment5,
                   glc.segment6, glc.segment7
            INTO lc_segment1, lc_segment2, lc_segment4, lc_segment5,
                 lc_segment6, lc_segment7
            FROM mtl_parameters mp, gl_code_combinations glc
            WHERE organization_id = i_org_id
            AND mp.material_account = glc.code_combination_id;


    -- DR2 – For deriving the Material account code combination, get the segment1, segment 2, segment4, segment5, segment6, segment7 
    -- from the input organization parameters material account and segment3 should be derived from the common translation tables.

        SELECT mc.segment3 
        INTO lv_department
            FROM mtl_system_items_b msi,
                 mtl_item_categories mic,
                 mtl_categories mc,
                 mtl_category_sets mcs
            WHERE 1=1
            AND  msi.inventory_item_id = mic.inventory_item_id
            AND  mic.organization_id = msi.organization_id
            AND  mic.category_id = mc.category_id
            AND  mic.category_set_id = mcs.category_set_id
            AND  mcs.category_set_name = 'Inventory'
            AND  mcs.structure_id = 101
            AND  msi.organization_id = parts_rec.organization_id --p_organization_id
            AND  msi.inventory_item_id = parts_rec.inventory_item_id --p_item_id
        ;

        SELECT xft.target_value3 -- material_account
        INTO lc_segment3
            FROM xx_fin_translatevalues xft,
                 xx_fin_translatedefinition xfd
            WHERE 1=1
            AND  xfd.translation_name = 'SALES ACCOUNTING MATRIX'
            AND xft.translate_id = xfd.translate_id
            AND xft.source_value2 = lv_item_type  
            and xft.source_value3 = lv_department 
            AND xft.enabled_flag   = 'Y'
            AND (xft.start_date_active <= SYSDATE
        AND (xft.end_date_active >= SYSDATE OR xft.end_date_active IS NULL));

    --- Logic Material Account
            lc_conc_segments :=
                  lc_segment1
               || '.'
               || lc_segment2
               || '.'
               || lc_segment3
               || '.'
               || lc_segment4
               || '.'
               || lc_segment5
               || '.'
               || lc_segment6
               || '.'
               || lc_segment7;
            ln_mat_acct :=
               fnd_flex_ext.get_ccid
                                    (application_short_name      => 'SQLGL',
                                     key_flex_code               => 'GL#',
                                     structure_number            => lc_structure_number,
                                     validation_date             => NULL,
                                     concatenated_segments       => lc_conc_segments
                                    );
            ln_dist_acct := ln_mat_acct;

            BEGIN
               IF ln_mat_acct <= 0
               THEN
                  o_err_num := SQLCODE;
                  o_err_msg :=
                      'CSTPACHK.COST_DIST_HOOK:' || SUBSTRB (SQLERRM, 1, 150);

        ELSE 
            cst_utility_pub.insert_mta
               (p_api_version        => 1.0,              
            p_init_msg_list      => fnd_api.g_false,
            p_commit             => fnd_api.g_false,
            x_return_status      => lv_return_status,
            x_msg_count          => ln_msg_count,      
            x_msg_data           => lv_msg_data,     
            p_org_id             => i_org_id,       
            p_txn_id             => i_txn_id,       
            p_user_id            => i_user_id,      
            p_login_id           => i_login_id,
            p_req_id             => i_req_id,
            p_prg_appl_id        => i_prg_appl_id,
            p_prg_id             => i_prg_id,
            p_account            => ln_mat_acct,
            p_dbt_crdt           => 1,                
            p_line_typ           => 2,                
            p_bs_txn_val         => ln_bs_txn_val,     
            p_cst_element        => 1,   
            p_resource_id        => NULL,
            p_encumbr_id         => NULL  
               );

                    cst_utility_pub.insert_mta
               (p_api_version        => 1.0,
            p_init_msg_list      => fnd_api.g_false,
            p_commit             => fnd_api.g_false,
            x_return_status      => lv_return_status,
            x_msg_count          => ln_msg_count,
            x_msg_data           => lv_msg_data,
            p_org_id             => i_org_id,
            p_txn_id             => i_txn_id,
            p_user_id            => i_user_id,
            p_login_id           => i_login_id,
            p_req_id             => i_req_id,
            p_prg_appl_id        => i_prg_appl_id,
            p_prg_id             => i_prg_id,
            p_account            => ln_mat_acct,
            p_dbt_crdt           => -1,
            p_line_typ           => 2,
            p_bs_txn_val         => ln_bs_txn_val,
            p_cst_element        => 1,
            p_resource_id        => NULL,
            p_encumbr_id         => NULL
               );

        END IF;
            END;
            -- check error;
            IF (lv_return_status <> 'S')
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'process_error CST_UTILITY_PUB.insert_MTA'
                                 );

               IF ln_msg_count <> 0
               THEN
                  FOR i IN 1 .. ln_msg_count
                  LOOP
                     fnd_file.put_line
                               (fnd_file.LOG,
                                   'process_error CST_UTILITY_PUB.insert_MTA'
                                || lv_msg_data
                               );
                  END LOOP;
               END IF;

               RAISE process_error;
            END IF;

            RETURN 1;
            COMMIT;
         END IF;                                     -- end of checking action
      ELSE
         RETURN 0;
      END IF;
   END LOOP;
   
---
  --return 0;
EXCEPTION
   WHEN OTHERS
   THEN
      o_err_num := SQLCODE;
      o_err_msg := 'CSTPACHK.COST_DIST_HOOK:' || SUBSTRB (SQLERRM, 1, 150);
      RETURN 0;

   END;
END XX_TDS_INV_COST_HOOK_EXT;
/
SHOW ERROR