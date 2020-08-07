SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_FIXLOTMULTI_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_PO_FIXLOTMULTI_PKG.pks                            |
-- | Description: This package is used to validate order qty. for      |
-- | each PO created or modified by the user. This package consist     |
-- | of one function VALIDATE_ORD_QTY and is being called from the     |
-- | WHEN-VALIDATE-RECORD event of the CUSTOM.pll for the PO creation  |
-- | form POXPOEPO.                                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 08-MAR-2007  Seemant Gour     Initial draft version       |
-- |     1.0 26-JUL-2007  Seemant Gour     Baseline for Release        |
-- |     1.1 14-Aug-2007  Seemant Gour     Update as per the Prioritization|
-- |                                       list for Purchasing RICE change.|
-- |                                       Removed the parameter p_ship_org_id|
-- |                                       from the function.          |
-- +===================================================================+

AS
  
-- +====================================================================+
-- | Name         : VALIDATE_ORD_QTY                                    |
-- | Description  : This Function will be used to fetch order qty,      |
-- | validate it for multiple of inner/case pack size and purchasing    |
-- | UOM for a item of given order and returns the order qty after      |
-- | calculating in multiples of inner/case pack size.                  |
-- | Parameters   :     p_ord_qty                                       |
-- |                    p_po_type                                       |
-- |                    p_vendor_site_id                                |
-- |                    p_item_id                                       |
-- |                    p_prompt_status                                 |
-- |                    p_purchasing_uom                                |
-- |                    p_err_buf                                       |
-- |                                                                    |
-- | Returns      :     Order_quantity                                  |
-- +====================================================================+

   FUNCTION VALIDATE_ORD_QTY (p_ord_qty        IN  NUMBER
                            , p_po_type        IN  VARCHAR2
                            , p_vendor_site_id IN  NUMBER
                            , p_item_id        IN  NUMBER
                            , p_purchasing_uom IN  VARCHAR2
                            , p_prompt_status  OUT VARCHAR2
                            , p_err_buf        OUT VARCHAR2
                            )
                            RETURN NUMBER;


END XX_PO_FIXLOTMULTI_PKG;
/

SHOW ERRORS

EXIT;
