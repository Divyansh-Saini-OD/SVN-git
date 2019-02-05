SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_FIXLOTMULTI_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +======================================================================================+
-- | Name       : XX_PO_FIXLOTMULTI_PKG.pkb                                               |
-- |                                                                                      |
-- | Description: This package is used to validate order qty. for                         |
-- |              each PO created or modified by the user. This package consist           |
-- |              of one function VALIDATE_ORD_QTY and is being called from the           |
-- |              WHEN-VALIDATE-RECORD event of the CUSTOM.pll for the PO creation        |
-- |              form POXPOEPO.                                                          |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date        Author           Remarks                                        |
-- |=======   ==========  =============    ===============================================|
-- |DRAFT 1A 08-MAR-2007  Seemant Gour     Initial draft version                          |
-- |DRAFT 1B 15-APR-2007  Seemant Gour     Updated after peer review                      |
-- |1.0      26-JUN-2007  Seemant Gour     Baselined for Release                          |
-- |1.1      09-JUL-2007  Seemant Gour     Modified the code as per the CR and            |
-- |                                       as follows:                                    |
-- |                                       1) Added to check for Approved and Disabled    |
-- |                                          ASL.                                        |
-- |                                       2) Validating ASL on the based of ship to      |
-- |                                          organization id on the PO.                  |
-- |                                       3) If there is not Org level ASL defined       |
-- |                                          check of the Global ASL using               |
-- |                                          organization -1.                            |
-- |1.2      14-AUG-2007  Seemant Gour     Modified the code as per the CR for            |
-- |                                       Prioritization list for Purchasing RICE        |
-- |                                       changes and modified the SQL to look at the    |
-- |                                       validation org's (for the OU) values for       |
-- |                                       the pack sizes instead for each inventory org .|
-- |                                       Removed the parameter p_ship_org_id from the   |
-- |                                       function.                                      |
-- +======================================================================================+
AS

-- +===================================================================================+
-- | Name         : VALIDATE_ORD_QTY                                                   |
-- |                                                                                   |
-- | Description  : This Function will be used to fetch order qty,                     |
-- |                validate it for multiple with inner/case pack size and purchasing  |
-- |                UOM for a item of given order and returns the order qty after      |
-- |                calculating the multiple of inner/case pack size.                  |
-- |                                                                                   |
-- |Parameters   :     p_ord_qty                                                       |
-- |                   p_po_type                                                       |
-- |                   p_vendor_site_id                                                |
-- |                   p_item_id                                                       |
-- |                   p_prompt_status                                                 |
-- |                   p_purchasing_uom                                                |
-- |                   p_err_buf                                                       |
-- |                                                                                   |
-- | Returns      :    Order_quantity                                                  |
-- +===================================================================================+

   FUNCTION VALIDATE_ORD_QTY (p_ord_qty        IN  NUMBER
                            , p_po_type        IN  VARCHAR2
                            , p_vendor_site_id IN  NUMBER
                            , p_item_id        IN  NUMBER
                            , p_purchasing_uom IN  VARCHAR2
                            , p_prompt_status  OUT VARCHAR2
                            , p_err_buf        OUT VARCHAR2
                             )
                            RETURN NUMBER
   IS
      ----------------------------
      -- Declaring Local variables
      ----------------------------
      ln_converted_qty    NUMBER;
      ln_po_line_qty      NUMBER;
      ln_inner_size       NUMBER;
      ln_case_size        NUMBER;
      lc_primary_uom      mtl_system_items_b.primary_unit_of_measure%TYPE;
      ln_inner_round_qty  NUMBER;
      ln_case_round_qty   NUMBER;

   ----------------------------
   -- Begining of the Function
   ----------------------------
   BEGIN
      --------------------------------
      -- Initializing Local variables
      --------------------------------
      ln_converted_qty  := p_ord_qty;
      p_prompt_status   := 'N';

            --------------------------------------
            -- Getting Inner/Case pack size value 
            --------------------------------------
            BEGIN
 
                BEGIN
 
                   SELECT XISA.supp_pack_size
                         ,XISA.inner_pack_size
                   INTO   ln_case_size
                        , ln_inner_size
                   FROM   po_approved_supplier_list POSL
                        , xxpo_item_supp_rms_attribute  XISA
                        , financials_system_parameters  FSP
                   WHERE POSL.attribute1             = XISA.combination_id
                   AND   POSL.vendor_site_id         = p_vendor_site_id 
                   AND   POSL.item_id                = p_item_id 
                   /* Added as per the CR Version 1.1*/
                   --AND   POSL.using_organization_id  = p_ship_org_id                 -- Commented As perPrioritization list for Purchasing RICE changes. CR Version 1.2
                   AND   POSL.using_organization_id  = FSP.inventory_organization_id   -- Added As perPrioritization list for Purchasing RICE changes. CR Version 1.2
                   AND   POSL.asl_status_id          = 2
                   AND   NVL(POSL.disable_flag, 'N') = 'N'
                   AND   ROWNUM                      = 1;
               
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      SELECT XISA.supp_pack_size,XISA.inner_pack_size
                      INTO   ln_case_size
                           , ln_inner_size
                      FROM   po_approved_supplier_list POSL
                           , xxpo_item_supp_rms_attribute  XISA
                           , po_vendor_sites PVS
                           , financials_system_parameters  FSP
                      WHERE POSL.attribute1             = XISA.combination_id
                      AND   PVS.vendor_site_id          = p_vendor_site_id 
                      AND   POSL.item_id                = p_item_id
                      AND   PVS.vendor_id               = POSL.vendor_id
                      /* Added as per the CR Version 1.1*/ 
                      --AND   POSL.using_organization_id  = p_ship_org_id                 -- Commented As perPrioritization list for Purchasing RICE changes. CR Version 1.2
                      AND   POSL.using_organization_id  = FSP.inventory_organization_id   -- Added As perPrioritization list for Purchasing RICE changes. CR Version 1.2
                      AND   POSL.asl_status_id          = 2
                      AND   NVL(POSL.disable_flag, 'N') = 'N'
                      AND   ROWNUM                      = 1;
               
                END;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data found in getting ORG level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                  p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                  p_err_buf := 'No Data found in getting ORG level Inner/Case Pack Size.'|| p_err_buf;
                  p_prompt_status   := 'N';
                  --RETURN p_ord_qty;
                  
                  -- Addeded as per the CR Version 1.1 
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Approved Supplier List is Active. ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                  p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                  p_err_buf := 'No Data found in getting ORG level Inner/Case Pack Size.'|| p_err_buf;
                  p_prompt_status   := 'N';
                  --RETURN p_ord_qty;
               WHEN TOO_MANY_ROWS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Too Many Rows found in getting ORG level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                  p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                  p_err_buf := 'Too Many Rows found in getting ORG level Inner/Case Pack Size.'|| p_err_buf ;
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in getting ORG level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                  p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                  p_err_buf := 'Error in getting ORG level Inner/Case Pack Size.'|| p_err_buf;

            END;
            
            ---------------------------------------------------
            -- IF condition Addeded as per the CR Version 1.1
            ---------------------------------------------------
            IF (ln_case_size IS NULL) AND (ln_inner_size IS NULL) THEN
                ------------------------------------------------------------------------------------------------------------------------
                -- Getting Inner/Case pack size value when the value of Ship to Organization id is NULL and checking for Global ASL
                ------------------------------------------------------------------------------------------------------------------------
                BEGIN
     
                    BEGIN
     
                       SELECT XISA.supp_pack_size,XISA.inner_pack_size
                       INTO   ln_case_size
                            , ln_inner_size
                       FROM   po_approved_supplier_list POSL
                            , xxpo_item_supp_rms_attribute  XISA
                       WHERE POSL.attribute1             = XISA.combination_id
                       AND   POSL.vendor_site_id         = p_vendor_site_id 
                       AND   POSL.item_id                = p_item_id 
                       AND   POSL.using_organization_id  = -1
                       AND   POSL.asl_status_id          = 2
                       AND   NVL(POSL.disable_flag, 'N') = 'N'
                       AND   ROWNUM                      = 1;
                   
                    EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                          SELECT XISA.supp_pack_size,XISA.inner_pack_size
                          INTO   ln_case_size
                               , ln_inner_size
                          FROM   po_approved_supplier_list POSL
                               , xxpo_item_supp_rms_attribute  XISA
                               , po_vendor_sites PVS
                          WHERE POSL.attribute1             = XISA.combination_id
                          AND   PVS.vendor_site_id          = p_vendor_site_id 
                          AND   POSL.item_id                = p_item_id
                          AND   PVS.vendor_id               = POSL.vendor_id
                          AND   POSL.using_organization_id  = -1
                          AND   POSL.asl_status_id          = 2
                          AND   NVL(POSL.disable_flag, 'N') = 'N'
                          AND   ROWNUM                      = 1;
                   
                    END;

                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data found in getting GLOBAL level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                      p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                      p_err_buf := 'No Data found in getting Inner/Case Pack Size.'|| p_err_buf;
                      p_prompt_status   := 'N';
                      -- Addeded as per the CR Version 1.1 
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'No GLOBAL Approved Supplier List is Active. ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                      p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                      p_err_buf := 'No Data found in getting Inner/Case Pack Size.'|| p_err_buf;
                      p_prompt_status   := 'N';
                   WHEN TOO_MANY_ROWS THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Too Many Rows found in getting GLOBAL level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                      p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                      p_err_buf := 'Too Many Rows found in getting Inner/Case Pack Size.'|| p_err_buf ;
                   WHEN OTHERS THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in getting GLOBAL level Inner/Case Pack Size: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                      p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                      p_err_buf := 'Error in getting Inner/Case Pack Size.'|| p_err_buf;

                END;
            
            END IF;
            ---------------------------------------------------------
            -- END of IF condition Addeded as per the CR Version 1.1
            ---------------------------------------------------------

            ------------------------------------
            -- Getting primary UOM of the Item
            ------------------------------------
            BEGIN

                SELECT DISTINCT msib.primary_unit_of_measure
                INTO   lc_primary_uom
                FROM   mtl_system_items_b MSIB
                WHERE  msib.inventory_item_id = p_item_id
                AND    ROWNUM  = 1 ;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data found in getting primary UOM: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                       p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                       p_err_buf := 'No Data found in getting primary UOM.'|| p_err_buf;
                       p_prompt_status   := 'N';
                WHEN TOO_MANY_ROWS THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Too Many rows found in getting primary UOM: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                       p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                       p_err_buf := 'Too Many rows found in getting primary UOM.'|| p_err_buf;
                       p_prompt_status   := 'N';
                WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in getting primary UOM: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
                       p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
                       p_err_buf := 'Too Many rows found in getting primary UOM.'|| p_err_buf;
                       p_prompt_status   := 'N';
            END;

            -- Addeded IF Condition as per the CR Version 1.1
            ---------------------------------------------------------------------------
            --  IF condition(1) for checking ln_case_size and ln_inner_size NULL value.
            ---------------------------------------------------------------------------
            IF (ln_case_size IS NOT NULL) AND (ln_inner_size IS NOT NULL) THEN
               --------------------------------------------------------
               --  IF condition(2) for checking the PO_Type for 'TRADE'
               --------------------------------------------------------
               IF (UPPER(p_po_type) = 'TRADE') THEN
                  --------------------------------------------------------------
                  -- IF condition(3) for checking purchasing UOM and Primary UOM
                  --------------------------------------------------------------
                  IF (p_purchasing_uom <> lc_primary_uom) THEN
                     ------------------------------------------------------------------------------
                     -- Converting the PO line quantity into primary UOM Qty using below given API.
                     ------------------------------------------------------------------------------
                     ln_converted_qty :=   INV_CONVERT.INV_UM_CONVERT (p_item_id
                                                                     , NULL
                                                                     , 1
                                                                     , p_purchasing_uom
                                                                     , lc_primary_uom
                                                                     , NULL
                                                                     , NULL
                                                                       );
                  ELSE
                     ln_converted_qty := 1 ;
                  END IF;
                  ----------------------------------------------------------------------
                  -- END of IF condition(3) for checking purchasing UOM and Primary UOM
                  ----------------------------------------------------------------------

                  --------------------------------------------------------------
                  -- Rounding up the quantity in multiples of inner pack size
                  --------------------------------------------------------------
                  SELECT CEIL ((ln_converted_qty * p_ord_qty )/ln_inner_size) * ln_inner_size
                  INTO   ln_inner_round_qty
                  FROM   DUAL;

                  ----------------------------------------------------------------------------------
                  -- IF condition(4) for checking for the Purchasing UOM <> Primary UOM, if not then
                  -- Re-convert the rounded up quantity back into purchasing UOM quanitity;
                  ----------------------------------------------------------------------------------
                  IF (p_purchasing_uom <> lc_primary_uom) THEN
                     ln_po_line_qty := ROUND (ln_inner_round_qty / ln_converted_qty, 2);   /* 2 is precision*/
                  ELSE
                     ln_po_line_qty := ROUND(ln_inner_round_qty ,2);
                  END IF;
                  -------------------------------------------------------------------------------------------
                  -- END of IF condition (4) for checking for the Purchasing UOM <> Primary UOM, if not then
                  -- Re-convert the rounded up quantity back into purchasing UOM quanitity;
                  ------------------------------------------------------------------------------------------

                  --------------------------------------------------------------------------
                  -- IF condition(5) for checking derived ord qty with user entered ord qty.
                  --------------------------------------------------------------------------
                  IF (ln_po_line_qty <> p_ord_qty) THEN
                       p_prompt_status := 'Y';
                  END IF;
                  ---------------------------------------------------------------------------------------
                  -- END of IF condition(5) for checking derived ord qty with user entered ord qty.
                  ---------------------------------------------------------------------------------------

                  RETURN ln_po_line_qty;

               -----------------------------------------------------------
               -- ELSEIF condition for checking PO_Type for 'TRADE-IMPORT'
               -----------------------------------------------------------
               ELSIF (UPPER(p_po_type) = 'TRADE-IMPORT') THEN
                  --------------------------------------------------------------
                  -- IF condition(6) for checking purchasing UOM and Primary UOM
                  --------------------------------------------------------------
                  IF (p_purchasing_uom <> lc_primary_uom) THEN
                     ------------------------------------------------------------------------------
                     -- Converting the PO line quantity into primary UOM Qty using below given API.
                     ------------------------------------------------------------------------------
                     ln_converted_qty :=   INV_CONVERT.INV_UM_CONVERT (p_item_id
                                                                     , NULL
                                                                     , 1
                                                                     , p_purchasing_uom
                                                                     , lc_primary_uom
                                                                     , NULL
                                                                     , NULL
                                                                      );
                  ELSE
                     ln_converted_qty := 1 ;
                  END IF;
                  ----------------------------------------------------------------------------
                  -- END of IF condition(6) for checking purchasing UOM and Primary UOM
                  ----------------------------------------------------------------------------

                  --------------------------------------------------------------
                  -- Rounding up the quantity in multiples of case pack size
                  --------------------------------------------------------------
                  SELECT CEIL ((ln_converted_qty*p_ord_qty)/ln_case_size) * ln_case_size
                  INTO   ln_case_round_qty
                  FROM   DUAL;

                  ----------------------------------------------------------------------------------
                  -- IF condition(7) for checking for the Purchasing UOM <> Primary UOM, if not then
                  -- Re-convert the rounded up quantity back into purchasing UOM quanitity;
                  ----------------------------------------------------------------------------------
                  IF (p_purchasing_uom <> lc_primary_uom) THEN
                     ln_po_line_qty := ROUND (ln_case_round_qty / ln_converted_qty, 2);   /* 2 is precision*/
                  ELSE
                     ln_po_line_qty := ROUND(ln_case_round_qty ,2);
                  END IF;
                  --------------------------------------------------------------------------------------------------
                  -- END of IF condition(7)for checking for the Purchasing UOM <> Primary UOM, if not then
                  -- Re-convert the rounded up quantity back into purchasing UOM quanitity;
                  --------------------------------------------------------------------------------------------------

                  --------------------------------------------------------------------------
                  -- IF condition(8) for checking derived ord qty with user entered ord qty.
                  --------------------------------------------------------------------------
                  IF (ln_po_line_qty <> p_ord_qty) THEN
                       p_prompt_status := 'Y';
                  END IF;
                  -----------------------------------------------------------------------------------------
                  -- END of IF condition(8) for checking derived ord qty with user entered ord qty.
                  -----------------------------------------------------------------------------------------

                  RETURN ln_po_line_qty;
               END IF;
               --------------------------------------------------------------
               -- END of IF condition(2) for checking the PO_Type for 'TRADE'
               --------------------------------------------------------------

            ELSE
               RETURN p_ord_qty;
            END IF;
            ---------------------------------------------------------------------------------
            -- END of IF condition(1) for checking ln_case_size and ln_inner_size IS NULL value.
            ----------------------------------------------------------------------------------
            -- Addeded IF Condition as per the CR Version 1.1

   EXCEPTION
   WHEN OTHERS THEN
   --Logging error as per the standards;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in XX_PO_FIXLOTMULTI_PKG.VALIDATE_ORD_QTY: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));
       p_err_buf := p_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);
       p_err_buf := 'Error in XX_PO_FIXLOTMULTI_PKG.VALIDATE_ORD_QTY.'|| p_err_buf;
       RETURN p_ord_qty;
   END VALIDATE_ORD_QTY;

END XX_PO_FIXLOTMULTI_PKG;
/
SHOW ERRORS;
EXIT;
