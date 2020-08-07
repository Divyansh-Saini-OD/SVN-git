SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
   
CREATE OR REPLACE PACKAGE XX_PO_COST_EXT_ELC_PKG AUTHID CURRENT_USER 

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
-- |     1.0  31-OCT-07      Seemant Gour     Baseline for Release                  |
-- +================================================================================+

AS

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
                    ) RETURN NUMBER;

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
                  ) RETURN NUMBER;

END XX_PO_COST_EXT_ELC_PKG;
/
SHOW ERRORS;

EXIT;
