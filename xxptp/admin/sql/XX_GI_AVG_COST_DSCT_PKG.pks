SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
   
CREATE OR REPLACE PACKAGE XX_GI_AVG_COST_DSCT_PKG AUTHID CURRENT_USER 

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
-- |DRAFT 1C  20-SEP-07      Shashi Kumar     BaseLined After Testing               |
-- +================================================================================+

AS

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
                    ) RETURN NUMBER;

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
                  ) RETURN NUMBER;

END XX_GI_AVG_COST_DSCT_PKG;
/
SHOW ERRORS;

EXIT;