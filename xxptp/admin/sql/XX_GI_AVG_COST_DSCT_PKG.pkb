SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_AVG_COST_DSCT_PKG

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                         Oracle NAIO                                            |
-- +================================================================================+
-- | Name       : XX_GI_AVG_COST_DSCT_PKG                                           |
-- |                                                                                |
-- | Description: This package is used to compute the cost based on the discount on |
-- |              payment terms. It also performs account distribution.             |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  10-SEP-07      Shashi Kumar     Initial draft version                 |
-- |DRAFT 1B  20-SEP-07      Shashi Kumar     After Internal Review                 |
-- |DRAFT 1C  04-OCT-07      Shashi Kumar     BaseLined After Testing               |
-- +================================================================================+

AS

   -------------------------------------------
   -- Global constants used for error handling
   -------------------------------------------
   G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_GI_AVG_COST_DSCT_PKG';
   G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'CST';
   G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'N';
   G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
   G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';

   -- To Store the discount value --
   G_DSCT_COST              NUMBER;

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
-- | Parameters  :  p_org_id            IN  NUMBER                          |
-- |                p_txn_id            IN  NUMBER                          |
-- |                p_layer_id          IN  NUMBER                          |
-- |                p_cost_type         IN  NUMBER                          |
-- |                p_cost_method       IN  NUMBER                          |
-- |                p_user_id           IN  NUMBER                          |
-- |                p_login_id          IN  NUMBER                          |
-- |                p_req_id            IN  NUMBER                          |
-- |                p_prg_appl_id       IN  NUMBER                          |
-- |                p_prg_id            IN  NUMBER                          |
-- |                p_actual_cost       IN  NUMBER                          |
-- |                p_trans_cost        IN  NUMBER                          |
-- |                p_traxn_action_id   IN  NUMBER                          |
-- |                p_primary_quantity  IN  NUMBER                          |
-- |                p_discount_percent  IN  NUMBER                          |
-- |                o_err_num           OUT NUMBER                          |
-- |                o_err_code          OUT VARCHAR2                        |
-- |                o_err_msg           OUT VARCHAR2                        |
-- +========================================================================+

FUNCTION actual_cost(
                     p_org_id            IN          NUMBER,
                     p_txn_id            IN          NUMBER,
                     p_layer_id          IN          NUMBER,
                     p_cost_type         IN          NUMBER,
                     p_cost_method       IN          NUMBER,
                     p_user_id           IN          NUMBER,
                     p_login_id          IN          NUMBER,
                     p_req_id            IN          NUMBER,
                     p_prg_appl_id       IN          NUMBER,
                     p_prg_id            IN          NUMBER,
                     p_actual_cost       IN          NUMBER,
                     p_trans_cost        IN          NUMBER,
                     p_traxn_action_id   IN          NUMBER,
                     p_primary_quantity  IN          NUMBER,
                     p_discount_percent  IN          NUMBER,
                     x_err_num           OUT NOCOPY  NUMBER,
                     x_err_code          OUT NOCOPY  VARCHAR2,
                     x_err_msg           OUT NOCOPY  VARCHAR2
                    )
RETURN NUMBER IS

ln_actual_cost           mtl_material_transactions.actual_cost%TYPE;
ln_trans_cost            mtl_material_transactions.transaction_cost%TYPE;           
ln_item_id               mtl_system_items_b.inventory_item_id%TYPE;
ln_dsct_per              NUMBER;
x_message_data           VARCHAR2(4000);
x_message_code           VARCHAR2(100);
ln_transaction_action_id NUMBER;
ln_primary_quantity      mtl_material_transactions.primary_quantity%TYPE;
ln_act_cust_cost         NUMBER;
ln_trans_cust_cost       NUMBER;


BEGIN

   ln_dsct_per              :=  p_discount_percent; -- cur_dsct.discount_percent;
   ln_actual_cost           :=  p_actual_cost;      -- cur_dsct.actual_cost;
   ln_trans_cost            :=  p_trans_cost;       -- cur_dsct.transaction_cost;  
   ln_primary_quantity      :=  p_primary_quantity; -- cur_dsct.primary_quantity;
   ln_transaction_action_id :=  p_traxn_action_id;  -- cur_dsct.transaction_action_id;      

   ln_act_cust_cost   := (ln_actual_cost * NVL(ln_dsct_per,0)) / 100;
   ln_trans_cust_cost := (ln_trans_cost  * NVL(ln_dsct_per,0)) / 100;

   G_DSCT_COST := ln_act_cust_cost * ln_primary_quantity;

   BEGIN

      UPDATE mtl_material_transactions
      SET    transaction_cost        = transaction_cost - ln_trans_cust_cost
            ,actual_cost             = actual_cost      - ln_act_cust_cost
            ,last_updated_by         = p_user_id
            ,request_id              = p_req_id
            ,program_id              = p_prg_id
            ,program_application_id  = p_prg_appl_id 
      WHERE  transaction_id   = p_txn_id
      RETURNING inventory_item_id, actual_cost
      INTO   ln_item_id, ln_actual_cost;

   EXCEPTION WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

      x_message_data := FND_MESSAGE.GET;

      LOG_ERROR(p_exception => 'OTHERS'
               ,p_message   => x_message_data
               ,p_code      => x_message_code
               );

      x_err_msg  := SQLERRM;
      x_err_code := SQLCODE;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

   END;

   BEGIN

      UPDATE mtl_cst_txn_cost_details
      SET    transaction_cost        = ln_trans_cust_cost
            ,last_updated_by         = p_user_id
            ,request_id              = p_req_id
            ,program_id              = p_prg_id
            ,program_application_id  = p_prg_appl_id       
      WHERE  transaction_id          = p_txn_id
      AND    organization_id         = p_org_id
      AND    cost_element_id         = 1
      AND    level_type              = 1;

   EXCEPTION WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

      x_message_data := FND_MESSAGE.GET;

      LOG_ERROR(p_exception => 'OTHERS'
               ,p_message   => x_message_data
               ,p_code      => x_message_code
               );

      x_err_msg  := SQLERRM;
      x_err_code := SQLCODE;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

   END;

   --
   -- MTL_CST_ACTUAL_COST_DETAILS section
   --

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
                  , program_id
                  , request_id
                  , program_application_id                  
                  )
      VALUES      ( p_layer_id
                  , p_txn_id
                  , p_org_id
                  , 1
                  , 1
                  , ln_transaction_action_id
                  , SYSDATE
                  , p_user_id
                  , SYSDATE
                  , p_user_id
                  , p_login_id
                  , ln_item_id
                  , ln_actual_cost
                  , 'Y'
                  , 'Y'
                  , p_prg_id
                  , p_req_id
                  , p_prg_appl_id
                  );

      COMMIT;

   EXCEPTION WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

      x_message_data := FND_MESSAGE.GET;

      LOG_ERROR(p_exception => 'OTHERS'
               ,p_message   => x_message_data
               ,p_code      => x_message_code
               );

      x_err_msg  := SQLERRM;
      x_err_code := SQLCODE;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

   END;

RETURN 1;

EXCEPTION WHEN OTHERS THEN

   FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
   FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

   x_message_data := FND_MESSAGE.GET;

   LOG_ERROR(p_exception => 'OTHERS'
            ,p_message   => x_message_data
            ,p_code      => x_message_code
            );

   x_err_msg  := SQLERRM;
   x_err_code := SQLCODE;

   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || x_err_code || ': ' || SUBSTR(x_err_msg,1,240));

   RETURN -1;

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
                   p_org_id          IN          NUMBER,
                   p_txn_id          IN          NUMBER,
                   p_user_id         IN          NUMBER,
                   p_login_id        IN          NUMBER,
                   p_req_id          IN          NUMBER,
                   p_prg_appl_id     IN          NUMBER,
                   p_prg_id          IN          NUMBER,
                   p_item_id         IN          NUMBER,
                   p_primary_qty     IN          NUMBER,
                   p_distbn_acct_id  IN          NUMBER,
                   p_trxn_cst        IN          NUMBER,
                   x_err_num         OUT NOCOPY  NUMBER,
                   x_err_code        OUT NOCOPY  VARCHAR2,
                   x_err_msg         OUT NOCOPY  VARCHAR2
                  )
RETURN NUMBER IS

ln_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE;
ln_transaction_cost        mtl_material_transactions.transaction_cost%TYPE;
ln_material_account        mtl_parameters.material_account%TYPE;
lc_return_status           VARCHAR2(1);
ln_msg_count               NUMBER;
lc_msg_data                VARCHAR2(4000);
lc_transaction_account_id  mtl_material_transactions.distribution_account_id%TYPE;
lc_cost_pfl                VARCHAR2(100);
x_message_data             VARCHAR2(4000);
x_message_code             VARCHAR2(100);
lc_error_msg               VARCHAR2(4000);
lc_nat_seg                 VARCHAR2(240);
ln_disc_account            gl_code_combinations.code_combination_id%TYPE;

----------------------------------------------------
-- Cursor to fetch the Organization material account
----------------------------------------------------

CURSOR lcu_org_mat_acct(ln_org_id NUMBER) IS
SELECT MP.material_account
FROM   mtl_parameters MP
WHERE  MP.organization_id = ln_org_id;

-----------------------------------------------------------------
-- Cursor to fetch the discount account using the natural account
-----------------------------------------------------------------

CURSOR  lcu_natural_account(lc_nat_acct_seg VARCHAR2, ln_ccid NUMBER) IS
SELECT  gcc1.code_combination_id ccid
FROM    gl_code_combinations GCC1,
        gl_code_combinations GCC2
WHERE   gcc1.segment1 = GCC2.segment1
AND     gcc1.segment2 = GCC2.segment2
AND     gcc1.segment3 = lc_nat_acct_seg
AND     gcc1.segment4 = GCC2.segment4
AND     gcc1.segment5 = GCC2.segment5
AND     gcc1.segment6 = gcc2.segment6
AND     gcc1.segment7 = gcc2.segment7
AND     gcc2.code_combination_id =  ln_ccid;

BEGIN


   -- Code For generating the Inventory Valuation Account --
   ----------------------------------------
   -- Get the organization material account
   ----------------------------------------

   FOR cur_org_mat_acct IN lcu_org_mat_acct(p_org_id) LOOP
      ln_material_account := cur_org_mat_acct.material_account;
   END LOOP;

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
                              p_bs_txn_val    => p_trxn_cst,
                              p_cst_element   => 1,                   --  Considering the material cost
                              p_resource_id   => NULL,
                              p_encumbr_id    => NULL
                             );

   IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
      NULL;
   ELSE
      IF ln_msg_count = 1 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
         FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

         x_message_data := FND_MESSAGE.GET;

         LOG_ERROR(p_exception => 'OTHERS'
                  ,p_message   => x_message_data
                  ,p_code      => x_message_code
                  );

         x_err_msg  := SQLERRM;
         x_err_code := SQLCODE;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

      ELSE
         FOR l_index IN 1..ln_msg_count
         LOOP
            lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                       ,p_encoded => FND_API.G_FALSE),1,255);

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

            x_message_data := FND_MESSAGE.GET;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => x_message_data
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SQLERRM;
            x_err_code := SQLCODE;

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

         END LOOP;
      END IF;
   END IF; --Return status validation

   -- For the discount account --

   ln_disc_account  := NULL;
   
   -------------------------------------------------------------------------------------------------------------------------
   -- Get the natural account segment for the discount account from the profile 'OD ACCOUNT STRING FOR ANTICIPATED DISCOUNT'
   -------------------------------------------------------------------------------------------------------------------------

   FND_PROFILE.GET('OD_ACCOUNT_STRING_FOR_ANTICIPATED_DISCOUNT',lc_nat_seg);
   
   FOR cur_natural_account IN lcu_natural_account(lc_nat_seg ,ln_material_account) LOOP
      ln_disc_account := cur_natural_account.ccid;
   END LOOP;
   
   IF  ln_disc_account IS NULL THEN
      RETURN -1;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST : The profile OD_ACCOUNT_STRING_FOR_ANTICIPATED_DISCOUNT does not have any value ');
   
   END IF;
   
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
                              p_account       => ln_disc_account,     -- Discount Account
                              p_dbt_crdt      => 1 ,                  -- 1 for debit
                              p_line_typ      => 17,                  -- Invoice price variance lookup code from 'CST_ACCOUNTING_LINE_TYPE',
                              p_bs_txn_val    => G_DSCT_COST,         -- To be the discounted value
                              p_cst_element   => 1 ,                  --  Considering the material cost
                              p_resource_id   => NULL ,
                              p_encumbr_id    => NULL
                             );

   IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
      NULL;
   ELSE
      IF ln_msg_count = 1 THEN
   
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
         FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
   
         x_message_data := FND_MESSAGE.GET;

         LOG_ERROR(p_exception => 'OTHERS'
                  ,p_message   => lc_error_msg
                  ,p_code      => x_message_code
                  );

         x_err_msg  := SQLERRM;
         x_err_code := SQLCODE;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

      ELSE
         FOR l_index IN 1..ln_msg_count
         LOOP
            lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                   ,p_encoded => FND_API.G_FALSE),1,255);

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

            x_message_data := FND_MESSAGE.GET;
   
            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => lc_error_msg
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SQLERRM;
            x_err_code := SQLCODE;

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST :' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

         END LOOP;
      END IF;
   END IF; --Return status validation
       
   -- For the Receiving Inspection --
   --------------------------------------------------------------------------
   -- The po receipt inspection This will credit to the transaction account
   --------------------------------------------------------------------------

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
                              p_account       => p_distbn_acct_id,
                              p_dbt_crdt      => -1,                                     --  -1 for credit
                              p_line_typ      => 5,                                      --  Receiving inspection lookup code from 'CST_ACCOUNTING_LINE_TYPE',
                              p_bs_txn_val    => p_trxn_cst + G_DSCT_COST,      --  pass the original purchase order cost
                              p_cst_element   => 1 ,                                     --  Considering the material cost
                              p_resource_id   => NULL ,
                              p_encumbr_id    => NULL
                             );

   IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
      NULL;
   ELSE
      IF ln_msg_count = 1 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
         FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

         x_message_data := FND_MESSAGE.GET;

         LOG_ERROR(p_exception => 'OTHERS'
                  ,p_message   => x_message_data
                  ,p_code      => x_message_code
                  );

         x_err_msg  := SQLERRM;
         x_err_code := SQLCODE;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

      ELSE
         FOR l_index IN 1..ln_msg_count
         LOOP
            lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                       ,p_encoded => FND_API.G_FALSE),1,255);

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

            x_message_data := FND_MESSAGE.GET;

            LOG_ERROR(p_exception => 'OTHERS'
                     ,p_message   => lc_error_msg
                     ,p_code      => x_message_code
                     );

            x_err_msg  := SQLERRM;
            x_err_code := SQLCODE;

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

         END LOOP;

      END IF;
   END IF; --Return status validation

   RETURN 1;

EXCEPTION WHEN OTHERS THEN

   FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62001_UNEXP_ERR');
   FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

   x_message_data := FND_MESSAGE.GET;

   LOG_ERROR(p_exception => 'OTHERS'
            ,p_message   => x_message_data
            ,p_code      => x_message_code
            );

   x_err_msg  := SQLERRM;
   x_err_code := SQLCODE;

   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST Procedure:' || x_err_msg || ': ' || SUBSTR(x_err_code,1,240));

   RETURN -1;

END cost_dist;

END XX_GI_AVG_COST_DSCT_PKG;
/

SHOW ERRORS;

--EXIT;