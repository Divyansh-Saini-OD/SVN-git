CREATE OR REPLACE PACKAGE xx_po_calcpromdte_pkg IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name         : xx_po_calcpromdte_pkg                              |
-- | Rice Id      : E1042-Lead Time-Order Cycle                        |
-- | Description  : Calculate defaul promise date for manual po's      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0                   Antonio Morales  Initial version             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE xx_po_calcpromdte_pkg (p_order_dt IN     DATE,
                                 p_supplier IN     NUMBER,
                                 p_location IN     NUMBER,
                                 p_item     IN     NUMBER,
                                 p_prom_dt  IN OUT DATE);
END xx_po_calcpromdte_pkg;
/
