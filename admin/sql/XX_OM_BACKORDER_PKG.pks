SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_BACKORDER_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_BACKORDER_PKG                                      |
-- | Rice ID : E0282                                                   |
-- | Description: This package contains the function that determines   |
-- |              whether the back order is allowed or not.            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       18-Jul-07   Senthil Kumar    Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name  : IS_BACKORDERABLE                                          |
-- | Description: This Function is used to determine whether           |
-- |              back order is allowed or not.                        |
-- |                 suppliers                                         |
-- |                                                                   |
-- | Parameters :      NONE                                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         1 - Backorde Allowed                            |
-- |                   2 - Backorder Not Allowed                       |
-- |                                                                   |
-- +===================================================================+
FUNCTION IS_BACKORDERABLE (
                         p_inventory_item_id       mtl_system_items.inventory_item_id%TYPE                DEFAULT NULL
                        ,p_organization_id        hr_operating_units.organization_id%TYPE                 DEFAULT NULL
                        ,p_order_line_value       NUMBER                                                  DEFAULT NULL
                        ,p_item_status            VARCHAR2                                                DEFAULT NULL
                        ,p_customer_id            hz_cust_accounts.cust_account_id%TYPE                   DEFAULT NULL
                        ,p_replen_type            xx_inv_item_org_attributes.od_replen_type_cd%TYPE       DEFAULT NULL
                        ,p_replen_sub_type        xx_inv_item_org_attributes.od_replen_sub_type_cd%TYPE   DEFAULT NULL
                        ,p_backorder_threshold    NUMBER                                                  DEFAULT NULL
                        ,p_backorder_override     VARCHAR2                                                DEFAULT NULL
                        )
RETURN NUMBER;

END XX_OM_BACKORDER_PKG;

/
SHOW ERROR