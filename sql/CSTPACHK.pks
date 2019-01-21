create or replace
PACKAGE CSTPACHK AUTHID CURRENT_USER AS
/* $Header: CSTACHKS.pls 115.6.115100.6 2009/02/11 14:05:54 lchevala ship $ */

TYPE inv_layer_rec IS RECORD(
  inv_layer_id   cst_inv_layers.inv_layer_id%TYPE,
  layer_quantity cst_inv_layers.layer_quantity%TYPE
);

TYPE inv_layer_tbl IS TABLE OF inv_layer_rec;

-- FUNCTION
--  actual_cost_hook		Cover routine to allow users to add
--				customization. This would let users circumvent
--				our transaction cost processing.  This function
--				is called by both CSTPACIN and CSTPACWP.
--
-- INPUT PARAMETERS
--  I_ORG_ID
--  I_TXN_ID
--  I_LAYER_ID
--  I_COST_TYPE
--  I_COST_METHOD
--  I_USER_ID
--  I_LOGIN_ID
--  I_REQ_ID
--  I_PRG_APPL_ID
--  I_PRG_ID
--  O_Err_Num
--  O_Err_Code
--  O_Err_Msg
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
  I_COST_METHOD IN	NUMBER,
  I_USER_ID	IN	NUMBER,
  I_LOGIN_ID    IN	NUMBER,
  I_REQ_ID	IN	NUMBER,
  I_PRG_APPL_ID	IN	NUMBER,
  I_PRG_ID	IN 	NUMBER,
  O_Err_Num	OUT NOCOPY	NUMBER,
  O_Err_Code	OUT NOCOPY	VARCHAR2,
  O_Err_Msg	OUT NOCOPY	VARCHAR2
)
return integer;

-- FUNCTION
--  cost_dist_hook		Cover routine to allow users to customize.
--				They will be able to circumvent the
--				average cost distribution processor.
--
-- INPUT PARAMETERS
--  I_ORG_ID
--  I_TXN_ID
--  I_USER_ID
--  I_LOGIN_ID
--  I_REQ_ID
--  I_PRG_APPL_ID
--  I_PRG_ID
--  O_Err_Num
--  O_Err_Code
--  O_Err_Msg
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
return integer  ;

-- FUNCTION
--  get_account_id		Cover routine to allow users the flexbility
--				in determining the account they want to
--				post the inventory transaction to.
--
-- INPUT PARAMETERS
--  I_ORG_ID
--  I_TXN_ID
--  I_DEBIT_CREDIT		1 for debit and -1 for credit.
--  I_ACCT_LINE_TYPE		The accounting line type.
--  I_COST_ELEMENT_ID
--  I_RESOURCE_ID
--  I_SUBINV			The subinventory involved if there is one.
--  I_EXP			Indicates that the cost distributor is looking
--				for an expense account.
--  I_SND_RCV_ORG		Indicates whether this is an sending or
--				receiving organization for interorg txns.
--  I_USER_ID
--  I_LOGIN_ID
--  I_REQ_ID
--  I_PRG_APPL_ID
--  I_PRG_ID
--  O_Err_Num
--  O_Err_Code
--  O_Err_Msg
--  I_COST_GROUP_ID         Added as part of BUG 8206088
--
-- RETURN VALUES
--  integer		>0	User selected account number
--			-1  	Use the default account for distribution.
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
  O_Err_Num		OUT     NOCOPY	NUMBER,
  O_Err_Code		OUT     NOCOPY	VARCHAR2,
  O_Err_Msg		OUT     NOCOPY	VARCHAR2,
  I_COST_GROUP_ID       IN      NUMBER  DEFAULT NULL /*8206088*/
)
return integer;

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
return integer;

-- PROCEDURE
--  layers_hook                 This routine is a client extension that lets the
--                              user specify multiple layers that a transaction
--                              should consume from.
--
-- PARAMETERS
--  i_txn_id                    Id of the inventory material transactions in
--                              MTL_MATERIAL_TRANSACTIONS
--  i_required_qty              The quantity in primary UOM that this transaction
--                              needs to consume
--  i_cost_method               The cost method of the organization. The possible
--                              values are 5 (FIFO) and 6 (LIFO).
--  o_custom_layers             A list of Ids of the inventory layers in CST_INV_LAYERS
--                              that should be consumed for the transaction and the
--                              quantity that should be consumed from each layer. The
--                              inventory layers must correspond to the organization,
--                              item and cost group of the transaction. The quantity
--                              must be positive and less than or equal to the available
--                              quantity in the specified layer
--  o_err_num                   0 indicates no error. Other values indicates errors.
--  o_err_code                  A short code to help identify errors.
--  o_err_msg                   A message to help identify errors.

PROCEDURE layers_hook(
  i_txn_id        IN            NUMBER,
  i_required_qty  IN            NUMBER,
  i_cost_method   IN            NUMBER,
  o_custom_layers IN OUT NOCOPY inv_layer_tbl,
  o_err_num       OUT NOCOPY    NUMBER,
  o_err_code      OUT NOCOPY    VARCHAR2,
  o_err_msg       OUT NOCOPY    VARCHAR2
);

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
RETURN INTEGER;

function get_date(
  I_ORG_ID              IN      NUMBER,
  O_Error_Message       OUT NOCOPY     VARCHAR2
)
return date;

-- FUNCTION
--  get_absorption_account_id
--    Cover routing to allow users to specify the resource absorption account
--    based on the resource instance and charge department
--
--  Return Values
--   integer            > 0     User selected account number
--                       -1     Use default account
--
function get_absorption_account_id (
        I_ORG_ID                IN      NUMBER,
        I_TXN_ID                IN      NUMBER,
        I_CHARGE_DEPT_ID        IN      NUMBER,
        I_RES_INSTANCE_ID       IN      NUMBER
) return integer;

-- FUNCTION validate_job_est_status_hook
--  introduced as part of support for EAM Job Costing
--  This function can be modified to contain validations that allow/disallow
--  job cost re-estimation.
--  The Work Order Value summary form calls this function, to determine if the
--  re-estimation flag can be updated or not. If the function is not used, then
--  the default validations contained in cst_eamcost_pub.validate_for_reestimation
--  procedure will be implemented
-- RETURN VALUES
--   0          hook is not used or procedure raises exception
--   1          hook is used
-- VALUES for o_validate_flag
--   0          reestimation flag is not updateable
--   1          reestimation flag is updateable

function validate_job_est_status_hook (
        i_wip_entity_id         IN      NUMBER,
        i_job_status            IN      NUMBER,
        i_curr_est_status       IN      NUMBER,
        o_validate_flag		OUT NOCOPY	NUMBER,
        o_err_num               OUT NOCOPY     NUMBER,
        o_err_code              OUT NOCOPY     VARCHAR2,
        o_err_msg               OUT NOCOPY     VARCHAR2 )
return integer;

END CSTPACHK;