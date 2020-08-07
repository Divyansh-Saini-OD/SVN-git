SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY CSTPACHK
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                         Oracle NAIO                                            |
-- +================================================================================+
-- | Name       : CSTPACHK                                                          |
-- |                                                                                |
-- | Description: This standard package is used to compute the custom costing       |
-- |              computation and to perform the account distribution for the       |
-- |              material transactions.                                            |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  16-OCT-07      Shashi/Seemant   Initial draft version                 |
-- |DRAFT 1B  30-OCT-07      Shashi/Seemant   Modified the package for merging      |
-- |                                          Objects E0405_CostingExtnForTotalELC  |
-- |                                          and E0348B_WeightedAverageCostDiscounts|
-- |DRAFT 1C  29-NOV-07      Seemant Gour     Added return(0) clause in the ELSE of |
-- |                                          IF condition to check for "PO Receipt"|
-- +================================================================================+

AS

-- FUNCTION
--  actual_cost_hook        Cover routine to allow users to add
--                          customization. This would let users circumvent
--                          our transaction cost processing.  This function
--                          is called by both CSTPACIN and CSTPACWP.
--
--
-- RETURN VALUES
--  integer     1   Hook has been used.
--              0   Continue cost processing for this transaction
--                  as usual.
--

FUNCTION actual_cost_hook(
                          I_ORG_ID      IN  NUMBER,
                          I_TXN_ID      IN  NUMBER,
                          I_LAYER_ID    IN  NUMBER,
                          I_COST_TYPE   IN  NUMBER,
                          I_COST_METHOD IN  NUMBER,
                          I_USER_ID     IN  NUMBER,
                          I_LOGIN_ID    IN  NUMBER,
                          I_REQ_ID      IN  NUMBER,
                          I_PRG_APPL_ID IN  NUMBER,
                          I_PRG_ID      IN  NUMBER,
                          O_Err_Num     OUT NOCOPY  NUMBER,
                          O_Err_Code    OUT NOCOPY  VARCHAR2,
                          O_Err_Msg     OUT NOCOPY  VARCHAR2
                         )
RETURN INTEGER  IS

lc_trans_type          VARCHAR2(1000);
lc_cost_pfl            VARCHAR2(100);
lc_err_num             VARCHAR2(240);
lc_err_msg             VARCHAR2(4000);

ln_actual_cost          mtl_material_transactions.actual_cost%TYPE;
ln_trans_cost           mtl_material_transactions.transaction_cost%TYPE;
ln_item_id              mtl_system_items_b.inventory_item_id%TYPE;
ln_org_id               po_headers_all.org_id%TYPE;
lc_po_nbr               po_headers_all.segment1%TYPE;
ln_po_line_id           po_lines_all.po_line_id%TYPE;
ln_po_hdr_id            po_headers_all.po_header_id%TYPE;
lc_currency_code        po_headers_all.currency_code%TYPE;
lc_attr_categ           po_headers_all.attribute_category%TYPE;
ln_tot_landed_cst       po_lines_all.attribute6%TYPE;
lc_uom_lookup           VARCHAR2(50);
ln_line_num             po_lines_all.line_num%TYPE;
x_message_data          VARCHAR2(4000);
x_message_code          VARCHAR2(100);
ln_traxn_action_id      NUMBER;
ln_primary_quantity     mtl_material_transactions.primary_quantity%TYPE;

lc_consignment_flag     VARCHAR2(10);
ln_vendor_id            NUMBER;
ln_vendor_site_id       NUMBER;
ln_discount_percent     NUMBER;

ln_po_number            po_headers_all.segment1%TYPE;

--------------------------------------------------------------------
-- Cursor to fetch the Transaction type for the current transaction
--------------------------------------------------------------------

CURSOR lcu_trans_type(l_txn_id NUMBER) IS
SELECT MTT.transaction_type_name
FROM   mtl_transaction_types     MTT,
       mtl_material_transactions MMT
WHERE  MMT.transaction_type_id = MTT.transaction_type_id
AND    MMT.transaction_id      = l_txn_id;

--------------------------------------------------------------------
-- Cursor to fetch the Transaction type for the current transaction
--------------------------------------------------------------------

CURSOR lcu_trans_dtl(ln_txn_id NUMBER) IS
SELECT PHA.segment1 po_number
      ,PHA.po_header_id
      ,PHA.currency_code
      ,PHA.org_id
      ,PHA.attribute_category
      ,PLA.po_line_id
      ,PLA.attribute6 total_landed_price
      ,PLA.line_num
      ,PLA.unit_meas_lookup_code
      ,MMT.actual_cost
      ,MMT.transaction_action_id
      ,MMT.transaction_cost
      ,MMT.primary_quantity
      ,(SELECT SUM(ATL.discount_percent)
        FROM   po_headers_all     POH,
               rcv_shipment_lines RSL,
               rcv_transactions   RT,
               ap_terms           APT,
               ap_terms_lines     ATL
        WHERE  RT.transaction_id          = MMT.rcv_transaction_id
        AND    RT.shipment_header_id      = RSL.shipment_header_id
        AND    RT.shipment_line_id        = RSL.shipment_line_id
        AND    RT.transaction_type        = 'DELIVER'
        AND    RSL.po_header_id           = POH.po_header_id
        AND    POH.terms_id               = APT.term_id
        AND    APT.term_id                = ATL.term_id
        AND    TRUNC(NVL(APT.start_date_active,SYSDATE)) <=  TRUNC(RT.transaction_date)
        AND    TRUNC(NVL(APT.end_date_active,SYSDATE))   >= TRUNC(RT.transaction_date)
        AND    NVL(APT.enabled_flag,'Y')  = 'Y')  discount_percent
FROM   rcv_transactions          RT,
       mtl_material_transactions MMT,
       po_headers_all            PHA,
       po_lines_all              PLA
WHERE  RT.transaction_id   = MMT.rcv_transaction_id
AND    RT.po_line_id       = PLA.po_line_id
AND    PLA.po_header_id    = PHA.po_header_id
AND    PHA.po_header_id    = RT.po_header_id
AND    RT.transaction_type = 'DELIVER'
AND    MMT.transaction_id  = ln_txn_id;

BEGIN

   o_err_num := 0;
   o_err_code := '';
   o_err_msg := '';

   GC_ELC_CST_FLG   := NULL;
   GC_AVG_CST_FLG   := NULL;

   ------------------------------------------------------------------------------------------------------------
   -- Get the Transaction type for the current transaction IF the transaction type is 'PO Receipt' then proceed
   ------------------------------------------------------------------------------------------------------------

   FOR cur_trans_type IN lcu_trans_type(i_txn_id) LOOP
      lc_trans_type            :=  cur_trans_type.transaction_type_name;
   END LOOP;

   FOR cur_trans_dtl IN lcu_trans_dtl(i_txn_id) LOOP
      ln_org_id                :=  cur_trans_dtl.org_id;
      lc_po_nbr                :=  cur_trans_dtl.po_number;
      ln_po_hdr_id             :=  cur_trans_dtl.po_header_id;
      lc_currency_code         :=  cur_trans_dtl.currency_code;
      lc_attr_categ            :=  cur_trans_dtl.attribute_category;
      ln_po_line_id            :=  cur_trans_dtl.po_line_id;
      ln_tot_landed_cst        :=  cur_trans_dtl.total_landed_price;
      ln_line_num              :=  cur_trans_dtl.line_num;
      lc_uom_lookup            :=  cur_trans_dtl.unit_meas_lookup_code;
      ln_actual_cost           :=  cur_trans_dtl.actual_cost;
      ln_traxn_action_id       :=  cur_trans_dtl.transaction_action_id;
      ln_trans_cost            :=  cur_trans_dtl.transaction_cost;
      ln_primary_quantity      :=  cur_trans_dtl.primary_quantity;
      ln_discount_percent      :=  cur_trans_dtl.discount_percent;
   END LOOP;

   IF NVL(lc_trans_type,'XXXX') = 'PO Receipt' THEN
   
      IF UPPER(lc_attr_categ) = UPPER('Trade-Import') THEN
      
         FND_PROFILE.GET('XX_PO_OD_USE_COST_HOOK_FOR_ELC',lc_cost_pfl);
         
         IF (NVL(UPPER(lc_cost_pfl),'XXXX') = 'YES') THEN
         
            GC_ELC_CST_FLG := 'Y';
            
            RETURN XX_PO_COST_EXT_ELC_PKG.actual_cost(
                                                      i_org_id,           
                                                      i_txn_id,           
                                                      i_layer_id,         
                                                      i_cost_type,        
                                                      i_cost_method,      
                                                      i_user_id,          
                                                      i_login_id,         
                                                      i_req_id,           
                                                      i_prg_appl_id,      
                                                      i_prg_id,           
                                                      lc_po_nbr,          
                                                      ln_po_hdr_id,       
                                                      ln_po_line_id,      
                                                      lc_currency_code,   
                                                      ln_tot_landed_cst,  
                                                      ln_line_num,        
                                                      lc_uom_lookup,      
                                                      ln_actual_cost,     
                                                      ln_traxn_action_id, 
                                                      ln_trans_cost,      
                                                      ln_primary_quantity,
                                                      o_err_num,          
                                                      o_err_code,         
                                                      o_err_msg           
                                                     );
         ELSE
            RETURN (0);
         END IF;
      ELSE
         FND_PROFILE.GET('OD_ADJUST_UNIT_COST_FOR_DISCOUNTS',lc_cost_pfl);
         
         IF (NVL(UPPER(lc_cost_pfl),'XXXX') = 'YES') THEN
         
            GC_AVG_CST_FLG := 'Y';
            
            RETURN XX_GI_AVG_COST_DSCT_PKG.actual_cost(
                                                       i_org_id,
                                                       i_txn_id,
                                                       i_layer_id,
                                                       i_cost_type,
                                                       i_cost_method,
                                                       i_user_id,
                                                       i_login_id,
                                                       i_req_id,
                                                       i_prg_appl_id,
                                                       i_prg_id,
                                                       ln_actual_cost,
                                                       ln_trans_cost,
                                                       ln_traxn_action_id,
                                                       ln_primary_quantity,
                                                       ln_discount_percent,
                                                       o_err_num,
                                                       o_err_code,
                                                       o_err_msg
                                                      );
            
         ELSE
         
            RETURN (0);
            
         END IF;
         
      END IF;
      
   ELSE
      RETURN (0); 
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      
      o_err_num := SQLCODE;
      o_err_msg := 'CSTPACHK.ACTUAL_COST_HOOK:' || SUBSTRB(SQLERRM,1,150);

      lc_err_num := o_err_num;
      lc_err_msg := o_err_msg;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the ACTUAL_COST_HOOK :' || lc_err_num || SUBSTR(lc_err_msg,1,240));

      RETURN (0);

END actual_cost_hook;

-- FUNCTION
--  cost_dist_hook      Cover routine to allow users to customize.
--                      They will be able to circumvent the
--                      average cost distribution processor.
--
--
-- RETURN VALUES
--  integer     1   Hook has been used.
--              0   Continue cost distribution for this transaction
--                  as ususal.
--
FUNCTION cost_dist_hook(
                        I_ORG_ID      IN  NUMBER,
                        I_TXN_ID      IN  NUMBER,
                        I_USER_ID     IN  NUMBER,
                        I_LOGIN_ID    IN  NUMBER,
                        I_REQ_ID      IN  NUMBER,
                        I_PRG_APPL_ID IN  NUMBER,
                        I_PRG_ID      IN  NUMBER,
                        O_Err_Num     OUT NOCOPY  NUMBER,
                        O_Err_Code    OUT NOCOPY  VARCHAR2,
                        O_Err_Msg     OUT NOCOPY  VARCHAR2
                       )
RETURN INTEGER  IS

lc_trans_type        VARCHAR2(1000);
lc_cost_pfl          VARCHAR2(100);

lc_err_num           VARCHAR2(240);
lc_err_msg           VARCHAR2(4000);

ln_po_header_id      NUMBER;
ln_po_line_id        NUMBER;
ln_actual_cost       NUMBER;
ln_trxn_actn_id      NUMBER;
ln_trxn_cst          NUMBER;
ln_distbn_acct_id    NUMBER;
ln_primary_qty       NUMBER;
ln_po_number         po_headers_all.segment1%TYPE;
ln_item_id           NUMBER;
LN_TRANS_COST        NUMBER;

--------------------------------------------------------------------
-- Cursor to fetch the Transaction type for the current transaction
--------------------------------------------------------------------

CURSOR lcu_trans_type(l_txn_id NUMBER) IS
SELECT MTT.transaction_type_name
FROM   mtl_transaction_types     MTT,
       mtl_material_transactions MMT
WHERE  MMT.transaction_type_id = MTT.transaction_type_id
AND    MMT.transaction_id      = l_txn_id;

--------------------------------------------------------------------------------
-- Cursor to fetch the transaction account distribution and the material details
--------------------------------------------------------------------------------

CURSOR lcu_po_details(ln_txn_id NUMBER) IS
SELECT  PHA.attribute_category
       ,PHA.po_header_id
       ,PLA.po_line_id
       ,MMT.actual_cost
       ,MMT.transaction_action_id
       ,MMT.transaction_cost
       ,MMT.distribution_account_id
       ,MMT.inventory_item_id
       ,MMT.primary_quantity
       ,PHA.segment1
       ,MMT.primary_quantity * transaction_cost trans_cost
FROM   po_headers_all PHA,
       po_lines_all PLA,
       po_distributions_all PDA,
       rcv_transactions RT,
       mtl_material_transactions MMT
WHERE PHA.po_header_id        = PLA.po_header_id
AND   PLA.po_header_id        = PDA.po_header_id
AND   PLA.po_line_id          = PDA.po_line_id
AND   PDA.po_line_id          = RT.po_line_id
AND   PDA.po_header_id        = RT.po_header_id
AND   PDA.po_distribution_id  = RT.po_distribution_id
AND   RT.transaction_type     = 'DELIVER'
AND   RT.transaction_id       = MMT.rcv_transaction_id
AND   MMT.transaction_id      = ln_txn_id;

BEGIN

   o_err_num := 0;
   o_err_code := '';
   o_err_msg := '';

   FOR cur_po_details IN lcu_po_details(i_txn_id) LOOP

      ln_po_number       := cur_po_details.segment1;
      ln_po_header_id    := cur_po_details.po_header_id;
      ln_po_line_id      := cur_po_details.po_line_id;
      ln_actual_cost     := cur_po_details.actual_cost;
      ln_trxn_actn_id    := cur_po_details.transaction_action_id;
      ln_trxn_cst        := cur_po_details.transaction_cost;
      ln_distbn_acct_id  := cur_po_details.distribution_account_id;
      ln_primary_qty     := cur_po_details.primary_quantity;
      ln_item_id         := cur_po_details.inventory_item_id;
      ln_trans_cost      := cur_po_details.trans_cost;

   END LOOP;

   IF GC_ELC_CST_FLG ='Y' THEN

      -- Call the E0405 object for account distribution --
      RETURN  XX_PO_COST_EXT_ELC_PKG.cost_dist(
                                               i_org_id,
                                               i_txn_id,
                                               i_user_id,
                                               i_login_id,
                                               i_req_id,
                                               i_prg_appl_id,
                                               i_prg_id,
                                               ln_po_number,
                                               ln_po_header_id,
                                               ln_po_line_id,
                                               ln_actual_cost,
                                               ln_trxn_actn_id,
                                               ln_trxn_cst,
                                               ln_distbn_acct_id,
                                               ln_primary_qty,
                                               o_err_num,
                                               o_err_code,
                                               o_err_msg
                                              );
                                              
   ELSIF GC_AVG_CST_FLG = 'Y' THEN
   
      RETURN  XX_GI_AVG_COST_DSCT_PKG.cost_dist(
                                                i_org_id,
                                                i_txn_id,
                                                i_user_id,
                                                i_login_id,
                                                i_req_id,
                                                i_prg_appl_id,
                                                i_prg_id,
                                                ln_item_id,
                                                ln_primary_qty,
                                                ln_distbn_acct_id,
                                                ln_trxn_cst,
                                                o_err_num,
                                                o_err_code,
                                                o_err_msg
                                               );

      -- Call the E0348b object --

   ELSE
   
      RETURN (0);
      
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      o_err_num := SQLCODE;
      o_err_msg := 'CSTPACHK.COST_DIST_HOOK:' || SUBSTRB(SQLERRM,1,150);

      lc_err_num := o_err_num;
      lc_err_msg := o_err_msg;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured in the COST_DIST_HOOK :' || lc_err_num || SUBSTR(lc_err_msg,1,240));

      RETURN (0);

END cost_dist_hook;

-- FUNCTION
--  get_account_id      Cover routine to allow users the flexbility
--                      in determining the account they want to
--                      post the inventory transaction to.
--
--
-- RETURN VALUES
--  integer    >0  User selected account number
--             -1  Use the default account for distribution.
--              0  Error
--
FUNCTION get_account_id(
                        I_ORG_ID          IN  NUMBER,
                        I_TXN_ID          IN  NUMBER,
                        I_DEBIT_CREDIT    IN  NUMBER,
                        I_ACCT_LINE_TYPE  IN  NUMBER,
                        I_COST_ELEMENT_ID IN  NUMBER,
                        I_RESOURCE_ID     IN  NUMBER,
                        I_SUBINV          IN  VARCHAR2,
                        I_EXP             IN  NUMBER,
                        I_SND_RCV_ORG     IN  NUMBER,
                        O_Err_Num         OUT NOCOPY  NUMBER,
                        O_Err_Code        OUT NOCOPY  VARCHAR2,
                        O_Err_Msg         OUT NOCOPY  VARCHAR2
                       )
RETURN INTEGER  IS

l_account_num NUMBER := -1;
l_cost_method NUMBER;
l_txn_type_id NUMBER;
l_txn_act_id NUMBER;
l_txn_src_type_id NUMBER;
l_item_id NUMBER;
l_cg_id NUMBER;
wf_err_num NUMBER := 0;
wf_err_code VARCHAR2(500) := '';
wf_err_msg VARCHAR2(500) := '';

BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  SELECT transaction_type_id,
         transaction_action_id,
         transaction_source_type_id,
         inventory_item_id,
         NVL(cost_group_id, -1)
  INTO   l_txn_type_id,
         l_txn_act_id,
         l_txn_src_type_id,
         l_item_id,
         l_cg_id
  FROM   MTL_MATERIAL_TRANSACTIONS
  WHERE  transaction_id = I_TXN_ID;


  l_account_num := CSTPACWF.START_AVG_WF(i_txn_id, l_txn_type_id,l_txn_act_id,
                                          l_txn_src_type_id,i_org_id, l_item_id,
                                        i_cost_element_id,i_acct_line_type,
                                        l_cg_id,i_resource_id,
                                        wf_err_num, wf_err_code, wf_err_msg);
    o_err_num := NVL(wf_err_num, 0);
    o_err_code := NVL(wf_err_code, 'No Error in CSTPAWF.START_AVG_WF');
    o_err_msg := NVL(wf_err_msg, 'No Error in CSTPAWF.START_AVG_WF');

-- if -1 then use default account, else use this account for distribution

   RETURN l_account_num;

EXCEPTION

  WHEN OTHERS THEN
    o_err_num := -1;
    o_err_code := TO_CHAR(SQLCODE);
    o_err_msg := 'Error in CSTPACHK.GET_ACCOUNT_ID:' || SUBSTRB(SQLERRM,1,150);
    RETURN 0;

END get_account_id;

-- FUNCTION
--  layer_hook                  This routine is a client extension that lets the
--                              user specify which layer to consume from.
--
--
-- RETURN VALUES
--  integer             >0      Hook has been used,return value is inv layer id.
--                      0       Hook has not been used.
--                      -1      Error in Hook.

FUNCTION layer_hook(
                    I_ORG_ID      IN      NUMBER,
                    I_TXN_ID      IN      NUMBER,
                    I_LAYER_ID    IN      NUMBER,
                    I_COST_METHOD IN      NUMBER,
                    I_USER_ID     IN      NUMBER,
                    I_LOGIN_ID    IN      NUMBER,
                    I_REQ_ID      IN      NUMBER,
                    I_PRG_APPL_ID IN      NUMBER,
                    I_PRG_ID      IN      NUMBER,
                    O_Err_Num     OUT NOCOPY     NUMBER,
                    O_Err_Code    OUT NOCOPY     VARCHAR2,
                    O_Err_Msg     OUT NOCOPY     VARCHAR2
                   )
RETURN INTEGER  IS
BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  RETURN 0;

EXCEPTION

  WHEN OTHERS THEN
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layer_hook:' || SUBSTRB(SQLERRM,1,150);
    RETURN 0;

END layer_hook;


FUNCTION get_date(
                  I_ORG_ID        IN             NUMBER,
                  O_Error_Message OUT NOCOPY     VARCHAR2
                 )
RETURN DATE IS
BEGIN
   RETURN (SYSDATE+1);
END get_date;

-- FUNCTION
--  get_absorption_account_id
--    Cover routing to allow users to specify the resource absorption account
--    based on the resource instance and charge department
--
--  Return Values
--   integer        > 0     User selected account number
--                 -1 Use default account
--                  0     get_absorption_account_id failed
--
FUNCTION get_absorption_account_id(
                                   I_ORG_ID            IN  NUMBER,
                                   I_TXN_ID            IN  NUMBER,
                                   I_CHARGE_DEPT_ID    IN  NUMBER,
                                   I_RES_INSTANCE_ID   IN  NUMBER
                                  )
RETURN INTEGER IS

l_account_num   NUMBER  := -1;

BEGIN

 RETURN l_account_num;

EXCEPTION
  WHEN OTHERS THEN
   RETURN 0;

END get_absorption_account_id;


-- FUNCTION validate_job_est_status_hook
--  introduced as part of support for EAM Job Costing
--  This function can be modified to contain validations that allow/disallow
--  job cost re-estimation.
--  The Work Order Value summary form calls this function, to determine if the
--  re-estimation flag can be updated or not. If the function is not used, then
--  the default validations contained in cst_eamcost_pub.validate_for_reestimation
--  procedure will be implemented
-- RETURN VALUES
--   0      hook is not used or procedure raises exception
--   1      hook is used
-- VALUES for o_validate_flag
--   0      reestimation flag is not updateable
--   1          reestimation flag is updateable

FUNCTION validate_job_est_status_hook (
                                       i_wip_entity_id     IN  NUMBER,
                                       i_job_status        IN  NUMBER,
                                       i_curr_est_status   IN  NUMBER,
                                       o_validate_flag     OUT NOCOPY  NUMBER,
                                       o_err_num           OUT NOCOPY  NUMBER,
                                       o_err_code          OUT NOCOPY  VARCHAR2,
                                       o_err_msg           OUT NOCOPY  VARCHAR2
                                      )

RETURN INTEGER IS

l_hook  NUMBER  := 0;
l_err_num NUMBER := 0;
l_err_code VARCHAR2(240) := '';
l_err_msg  VARCHAR2(8000) := '';

BEGIN

  o_err_num := l_err_num;
  o_err_code := l_err_code;
  o_err_msg := l_err_msg;
  RETURN l_hook;

EXCEPTION
  WHEN OTHERS THEN
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layer_hook:' || SUBSTRB(SQLERRM,1,150);
    RETURN 0;
END validate_job_est_status_hook;

END CSTPACHK;
/

SHOW ERRORS;

EXIT;