create or replace PACKAGE BODY      CSTPACHK AS
/* $Header: CSTACHKB.pls 115.7.115100.7 2009/02/11 14:08:02 lchevala ship $ */

-- FUNCTION
--  actual_cost_hook		Cover routine to allow users to add
--				customization. This would let users circumvent
--				our transaction cost processing.  This function
--				is called by both CSTPACIN and CSTPACWP.
--
--
-- RETURN VALUES
--  integer		1	Hook has been used.
--			0  	Continue cost processing for this transaction
--				as usual.
--
function actual_cost_hook(
  I_ORG_ID	IN	NUMBER,
  I_TXN_ID	IN 	NUMBER,
  I_LAYER_ID	IN	NUMBER,
  I_COST_TYPE	IN	NUMBER,
  I_COST_METHOD	IN	NUMBER,
  I_USER_ID	IN	NUMBER,
  I_LOGIN_ID    IN	NUMBER,
  I_REQ_ID	IN	NUMBER,
  I_PRG_APPL_ID	IN	NUMBER,
  I_PRG_ID	IN 	NUMBER,
  O_Err_Num	OUT NOCOPY	NUMBER,
  O_Err_Code	OUT NOCOPY	VARCHAR2,
  O_Err_Msg	OUT NOCOPY	VARCHAR2
)
return integer  IS
BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  return 0;

EXCEPTION

  when others then
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.ACTUAL_COST_HOOK:' || substrb(SQLERRM,1,150);
    return 0;

END actual_cost_hook;

-- FUNCTION
--  cost_dist_hook		Cover routine to allow users to customize.
--				They will be able to circumvent the
--				average cost distribution processor.
--
--
-- RETURN VALUES
--  integer		1	Hook has been used.
--			0	Continue cost distribution for this transaction
--				as ususal.
--
function cost_dist_hook(
  I_ORG_ID		IN	NUMBER,
  I_TXN_ID		IN 	NUMBER,
  I_USER_ID		IN	NUMBER,
  I_LOGIN_ID    	IN	NUMBER,
  I_REQ_ID		IN	NUMBER,
  I_PRG_APPL_ID		IN	NUMBER,
  I_PRG_ID		IN 	NUMBER,
  O_Err_Num		OUT NOCOPY	NUMBER,
  O_Err_Code		OUT NOCOPY	VARCHAR2,
  O_Err_Msg		OUT NOCOPY	VARCHAR2
)
return integer  IS

l_result                 NUMBER;


BEGIN

  o_err_num := 0;
  o_err_code := '';
  O_Err_Msg := '';
-- +===================================================================================================+
-- | Custom Package - Used to derive the accounting derivation based on the item type and item number  |
-- |===================================================================================================|
-- | Version     Date         Author           Remarks						       |
-- | =========   ===========  =============    ========================================================|
-- | 1.0         12-JUL-2011  Suraj Charan     Initial version                                         |
-- +===================================================================================================+
  l_result := XX_TDS_INV_COST_HOOK_EXT_PKG.cost_dist_hook_ext( i_org_id ,  i_txn_id, i_user_id,i_login_id,
                                             i_req_id        ,
                                             i_prg_appl_id   ,
                                             i_prg_id        ,
                                             o_err_num       ,
                                             O_Err_Code      ,
                                             O_Err_Msg       );

  return l_result;

EXCEPTION
  when others then
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.COST_DIST_HOOK:' || substrb(SQLERRM,1,150);
    Return 0;

END cost_dist_hook;

-- FUNCTION
--  get_account_id		Cover routine to allow users the flexbility
--				in determining the account they want to
--				post the inventory transaction to.
--
--
-- RETURN VALUES
--  integer		>0	User selected account number
--			-1  	Use the default account for distribution.
--                       0      Error
--
function get_account_id(
  I_ORG_ID		IN	NUMBER,
  I_TXN_ID		IN 	NUMBER,
  I_DEBIT_CREDIT	IN	NUMBER,
  I_ACCT_LINE_TYPE	IN	NUMBER,
  I_COST_ELEMENT_ID	IN	NUMBER,
  I_RESOURCE_ID		IN	NUMBER,
  I_SUBINV		IN	VARCHAR2,
  I_EXP			IN	NUMBER,
  I_SND_RCV_ORG		IN	NUMBER,
  O_Err_Num		OUT NOCOPY	NUMBER,
  O_Err_Code		OUT NOCOPY	VARCHAR2,
  O_Err_Msg		OUT NOCOPY	VARCHAR2,
  I_COST_GROUP_ID       IN      NUMBER  DEFAULT NULL /*8206088*/
)
return integer  IS

l_account_num number := -1;
l_cost_method number;
l_txn_type_id number;
l_txn_act_id number;
l_txn_src_type_id number;
l_item_id number;
l_cg_id number;
l_txn_cg_id number;/*BUG 8206088*/
wf_err_num number := 0;
wf_err_code varchar2(500) := '';
wf_err_msg varchar2(500) := '';

BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  SELECT transaction_type_id,
         transaction_action_id,
         transaction_source_type_id,
         inventory_item_id,
         nvl(cost_group_id, -1)
  INTO   l_txn_type_id,
         l_txn_act_id,
         l_txn_src_type_id,
         l_item_id,
         l_txn_cg_id /*BUG 8206088*/
  FROM   MTL_MATERIAL_TRANSACTIONS
  WHERE  transaction_id = I_TXN_ID;


   /*BUG 8206088*/
   if (NVL(I_COST_GROUP_ID,0) =0) THEN

      l_cg_id :=l_txn_cg_id;
   else

      l_cg_id :=I_COST_GROUP_ID;

  end if;


  l_account_num := CSTPACWF.START_AVG_WF(i_txn_id, l_txn_type_id,l_txn_act_id,
                                          l_txn_src_type_id,i_org_id, l_item_id,
                                        i_cost_element_id,i_acct_line_type,
                                        l_cg_id,i_resource_id,
                                        wf_err_num, wf_err_code, wf_err_msg);
    o_err_num := NVL(wf_err_num, 0);
    o_err_code := NVL(wf_err_code, 'No Error in CSTPAWF.START_AVG_WF');
    o_err_msg := NVL(wf_err_msg, 'No Error in CSTPAWF.START_AVG_WF');

-- if -1 then use default account, else use this account for distribution

   return l_account_num;

EXCEPTION

  when others then
    o_err_num := -1;
    o_err_code := to_char(SQLCODE);
    o_err_msg := 'Error in CSTPACHK.GET_ACCOUNT_ID:' || substrb(SQLERRM,1,150);
    return 0;

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

function layer_hook(
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
return integer  IS
BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  return 0;

EXCEPTION

  when others then
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layer_hook:' || substrb(SQLERRM,1,150);
    return 0;

END layer_hook;

PROCEDURE layers_hook(
  i_txn_id        IN            NUMBER,
  i_required_qty  IN            NUMBER,
  i_cost_method   IN            NUMBER,
  o_custom_layers IN OUT NOCOPY inv_layer_tbl,
  o_err_num       OUT NOCOPY    NUMBER,
  o_err_code      OUT NOCOPY    VARCHAR2,
  o_err_msg       OUT NOCOPY    VARCHAR2
)
IS
BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';

  -- To customize this hook, extend o_custom_layers and populate
  -- it with inv_layer_id(s) of record(s) in CST_INV_LAYERS that
  -- correspond to the organization, item and cost group of the
  -- transaction. Also specify the quantity that should be
  -- consumed for each layer. The quantity must be positive and
  -- must be less than or equal to the available quantity in the
  -- specified layer.

  -- When the total quantity of the custom layers is less
  -- than the required quantity, the regular consumption
  -- logic will be used to derive the layers that should be
  -- consumed for the rest of the quantity. By default, this
  -- hook does not specify any custom layers, which means that
  -- the regular consumption logic will be used for all of the
  -- required quantity.

EXCEPTION
  WHEN OTHERS THEN
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layers_hook:' || substrb(SQLERRM,1,150);
END;

-- FUNCTION
--  LayerMerge_hook             This routine is a client extension that lets the
--                              user specify if layer merge should be attempted.
--
-- PARAMETERS
--  i_txn_id                    Id of the receipt transaction in
--                              MTL_MATERIAL_TRANSACTIONS
--  o_err_num                   0 indicates no error. Other values indicates errors.
--  o_err_code                  A short code to help identify errors.
--  o_err_msg                   A message to help identify errors.
--
-- RETURN VALUE
--  1                           Attempt to combine the quantity from the specified
--                              receipt transaction with an existing inventory layer
--  0                           Create a new inventory layer for the specified
--                              receipt transaction

FUNCTION LayerMerge_hook(
  i_txn_id        IN            NUMBER,
  o_err_num       OUT NOCOPY    NUMBER,
  o_err_code      OUT NOCOPY    VARCHAR2,
  o_err_msg       OUT NOCOPY    VARCHAR2
)
RETURN INTEGER
IS
BEGIN
  o_err_num := 0;
  o_err_code := '';
  o_err_msg := '';
  -- By default, the program will attempt to merge layers
  RETURN 1;
EXCEPTION
  WHEN OTHERS THEN
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layers_hook:' || substrb(SQLERRM,1,150);
    RETURN -1;
END;

function get_date(
  I_ORG_ID              IN      NUMBER,
  O_Error_Message       OUT NOCOPY     VARCHAR2
)
return date IS
BEGIN
   return (SYSDATE+1);
END get_date;

-- FUNCTION
--  get_absorption_account_id
--    Cover routing to allow users to specify the resource absorption account
--    based on the resource instance and charge department
--
--  Return Values
--   integer		> 0 	User selected account number
--   			 -1	Use default account
--                        0     get_absorption_account_id failed
--
function get_absorption_account_id (
	I_ORG_ID		IN	NUMBER,
 	I_TXN_ID		IN	NUMBER,
	I_CHARGE_DEPT_ID	IN	NUMBER,
	I_RES_INSTANCE_ID	IN	NUMBER
)
return integer IS

l_account_num 	NUMBER	:= -1;

BEGIN

 return l_account_num;

EXCEPTION
  when others then
   return 0;

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
--   0  	hook is not used or procedure raises exception
--   1		hook is used
-- VALUES for o_validate_flag
--   0		reestimation flag is not updateable
--   1          reestimation flag is updateable

function validate_job_est_status_hook (
   	i_wip_entity_id		IN	NUMBER,
	i_job_status		IN	NUMBER,
	i_curr_est_status	IN	NUMBER,
	o_validate_flag		OUT NOCOPY	NUMBER,
	o_err_num		OUT NOCOPY	NUMBER,
	o_err_code		OUT NOCOPY	VARCHAR2,
	o_err_msg		OUT NOCOPY	VARCHAR2 )
return integer IS

l_hook	NUMBER	:= 0;
l_err_num NUMBER := 0;
l_err_code VARCHAR2(240) := '';
l_err_msg  VARCHAR2(8000) := '';

BEGIN

  o_err_num := l_err_num;
  o_err_code := l_err_code;
  o_err_msg := l_err_msg;
  return l_hook;

EXCEPTION
  when others then
    o_err_num := SQLCODE;
    o_err_msg := 'CSTPACHK.layer_hook:' || substrb(SQLERRM,1,150);
    return 0;
END validate_job_est_status_hook;


END CSTPACHK;
/
SHOw errors;
exit;