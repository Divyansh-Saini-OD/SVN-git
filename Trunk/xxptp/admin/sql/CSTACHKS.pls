SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE CSTPACHK AUTHID CURRENT_USER

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
-- +================================================================================+

AS

GC_CONSIGNED_FLG VARCHAR2(1) := 'N';
GC_ELC_CST_FLG   VARCHAR2(1) := 'N';
GC_AVG_CST_FLG   VARCHAR2(1) := 'N';

-- FUNCTION
--  actual_cost_hook        Cover routine to allow users to add
--              customization. This would let users circumvent
--              our transaction cost processing.  This function
--              is called by both CSTPACIN and CSTPACWP.
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
--  integer     1   Hook has been used.
--          0   Continue cost processing for this transaction
--              as usual.
--
FUNCTION actual_cost_hook(
  I_ORG_ID  IN  NUMBER,
  I_TXN_ID  IN  NUMBER,
  I_LAYER_ID    IN  NUMBER,
  I_COST_TYPE   IN  NUMBER,
  I_COST_METHOD IN  NUMBER,
  I_USER_ID IN  NUMBER,
  I_LOGIN_ID    IN  NUMBER,
  I_REQ_ID  IN  NUMBER,
  I_PRG_APPL_ID IN  NUMBER,
  I_PRG_ID  IN  NUMBER,
  O_Err_Num OUT NOCOPY  NUMBER,
  O_Err_Code    OUT NOCOPY  VARCHAR2,
  O_Err_Msg OUT NOCOPY  VARCHAR2
)
RETURN INTEGER;

-- FUNCTION
--  cost_dist_hook      Cover routine to allow users to customize.
--              They will be able to circumvent the
--              average cost distribution processor.
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
--  integer     1   Hook has been used.
--          0   Continue cost distribution for this transaction
--              as ususal.
--
FUNCTION cost_dist_hook(
  I_ORG_ID      IN  NUMBER,
  I_TXN_ID      IN  NUMBER,
  I_USER_ID     IN  NUMBER,
  I_LOGIN_ID        IN  NUMBER,
  I_REQ_ID      IN  NUMBER,
  I_PRG_APPL_ID     IN  NUMBER,
  I_PRG_ID      IN  NUMBER,
  O_Err_Num     OUT NOCOPY  NUMBER,
  O_Err_Code        OUT NOCOPY  VARCHAR2,
  O_Err_Msg     OUT NOCOPY  VARCHAR2
)
RETURN INTEGER  ;

-- FUNCTION
--  get_account_id      Cover routine to allow users the flexbility
--              in determining the account they want to
--              post the inventory transaction to.
--
-- INPUT PARAMETERS
--  I_ORG_ID
--  I_TXN_ID
--  I_DEBIT_CREDIT      1 for debit and -1 for credit.
--  I_ACCT_LINE_TYPE        The accounting line type.
--  I_COST_ELEMENT_ID
--  I_RESOURCE_ID
--  I_SUBINV            The subinventory involved if there is one.
--  I_EXP           Indicates that the cost distributor is looking
--              for an expense account.
--  I_SND_RCV_ORG       Indicates whether this is an sending or
--              receiving organization for interorg txns.
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
--  integer     >0  User selected account number
--          -1      Use the default account for distribution.
--
FUNCTION get_account_id(
  I_ORG_ID      IN  NUMBER,
  I_TXN_ID      IN  NUMBER,
  I_DEBIT_CREDIT    IN  NUMBER,
  I_ACCT_LINE_TYPE  IN  NUMBER,
  I_COST_ELEMENT_ID IN  NUMBER,
  I_RESOURCE_ID     IN  NUMBER,
  I_SUBINV      IN  VARCHAR2,
  I_EXP         IN  NUMBER,
  I_SND_RCV_ORG     IN  NUMBER,
  O_Err_Num     OUT NOCOPY  NUMBER,
  O_Err_Code        OUT NOCOPY  VARCHAR2,
  O_Err_Msg     OUT NOCOPY  VARCHAR2
)
RETURN INTEGER;

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
RETURN INTEGER;


FUNCTION get_date(
  I_ORG_ID              IN      NUMBER,
  O_Error_Message       OUT NOCOPY     VARCHAR2
)
RETURN DATE;

-- FUNCTION
--  get_absorption_account_id
--    Cover routing to allow users to specify the resource absorption account
--    based on the resource instance and charge department
--
--  Return Values
--   integer            > 0     User selected account number
--                       -1     Use default account
--
FUNCTION get_absorption_account_id (
        I_ORG_ID                IN      NUMBER,
        I_TXN_ID                IN      NUMBER,
        I_CHARGE_DEPT_ID        IN      NUMBER,
        I_RES_INSTANCE_ID       IN      NUMBER
) RETURN INTEGER;


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

FUNCTION validate_job_est_status_hook (
        i_wip_entity_id         IN      NUMBER,
        i_job_status            IN      NUMBER,
        i_curr_est_status       IN      NUMBER,
        o_validate_flag     OUT NOCOPY  NUMBER,
        o_err_num               OUT NOCOPY     NUMBER,
        o_err_code              OUT NOCOPY     VARCHAR2,
        o_err_msg               OUT NOCOPY     VARCHAR2 )
RETURN INTEGER;


END CSTPACHK;
/

SHOW ERRORS;

EXIT;