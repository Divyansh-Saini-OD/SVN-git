SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE xx_om_dps_conf_rel_pkg
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | Description      : This package is used to call the various       |
-- |                    procedures to do all necessary validations     |
-- |                    get the informaton needed for updating the     |
-- |                    sales order.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |  1.0     23.03.07   Srividhya                                     |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name  : DPS_CONF_LINE_UPD                                         |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'HLD Production'                                  |
-- |                                                                   |
-- | Parameters :       p_order_number                                 |
-- |                    p_line_number                                  |
-- |                    p_item                                         |
-- |                    p_user_name				       |
-- |                    p_resp_name				       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_status                                        |
-- |                   x_message                                       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE DPS_CONF_LINE_UPD(
      p_po_number      IN       oe_order_headers_all.cust_po_number%TYPE
     ,p_order_number   IN       oe_order_headers_all.order_number%TYPE
     ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
     ,p_item           IN       oe_order_lines_all.ordered_item%TYPE
     ,p_user_name      IN       fnd_user.user_name%TYPE
     ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
     ,x_status         OUT      VARCHAR2
     ,x_message        OUT      VARCHAR2
   );

-- +===================================================================+
-- | Name  : DPS_HOLD_REL                                              |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'Reconciled'                                      |
-- |                                                                   |
-- | Parameters :      p_order_number                                  |
-- |                   p_line_number                                   |
-- |                   p_item_id                                       |
-- |                   p_user_name				       |
-- |                   p_resp_name				       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :     x_status                                            |
-- |               x_message                                           |
-- |                                                                   |
-- +===================================================================+
      PROCEDURE DPS_HOLD_REL (
          p_order_number   IN       oe_order_headers_all.order_number%TYPE
         ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
         ,p_item           IN       oe_order_lines_all.ordered_item%TYPE
         ,p_user_name      IN       fnd_user.user_name%TYPE
         ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
         ,x_status         OUT      VARCHAR2
         ,x_message        OUT      VARCHAR2
     );
END xx_om_dps_conf_rel_pkg;
/
SHOW ERROR