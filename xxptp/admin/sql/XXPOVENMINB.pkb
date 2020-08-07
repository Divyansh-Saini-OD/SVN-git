SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_VEN_MIN_PKG  
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_PO_VEN_MIN_PKG                                                              |
-- | Description      : Package Body containing function to return PASS or FAIL value        |
-- |                    depending upon the PO total amount and vendor minimum amount.        |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1a   11-May-2007       Remya Sasi       Initial draft version                      |
-- |1.0        17-May-2007       Remya Sasi       Baselined                                  |
-- |                                                                                         |
-- +=========================================================================================+
   AS


-- +===================================================================+
-- | Name  : main_calc_vendor_min                                      |
-- | Description:       This Function will be used to validate vendor  |
-- |                    minimum amount                                 |
-- | Parameters:        p_supplier_site_id                             |
-- |                    p_po_amount                                    |
-- |                    p_po_currency                                  |
-- |                    x_error_msg                                    |
-- |                                                                   |
-- | Returns :          X_Error_Msg                                    |
-- |                                                                   |
-- +===================================================================+
FUNCTION main_calc_vendor_min (
                             p_supplier_site_id  IN  NUMBER
                            ,p_po_amount         IN  NUMBER
                            ,p_po_currency       IN  VARCHAR2
                            ,x_error_msg         OUT VARCHAR2
                            )
RETURN VARCHAR2

IS
    ------------------------------------------------
    -- Local variables to be used in the function --
    ------------------------------------------------
    lc_vendor_min       VARCHAR2(30)    := NULL;
    lc_po_status        VARCHAR2(150)   := 'PASS';
    lc_prepaid_code     VARCHAR2(150)   := NULL;
    ln_po_amount        NUMBER          := 0;
    lc_attribute10      VARCHAR2(150)   := NULL;
    lc_inv_curr_code    VARCHAR2(15)    := NULL;

    BEGIN
        
        x_error_msg := NULL;
        
        -- Fetching the unique identifier for Vendor minimum details
        -- and invoice currency code from the given supplier site id
        SELECT  PVS.attribute10
               ,PVS.invoice_currency_code
        INTO    lc_attribute10
               ,lc_inv_curr_code
        FROM    po_vendor_sites PVS
        WHERE   PVS.vendor_site_id  = p_supplier_site_id;
        
        IF lc_attribute10 IS NULL THEN
        
            RETURN (lc_po_status); -- Returning 'PASS' if lc_attribute10 IS NULL
            
        ELSIF lc_inv_curr_code IS NULL THEN
        
            lc_po_status := 'FAIL'; -- Returning 'FAIL' if invoice_currency_code doesnt exist
            RETURN (lc_po_status);
            
        END IF;
        
        SELECT  XPVSK.segment4
               ,XPVSK.segment5
        INTO    lc_prepaid_code
               ,lc_vendor_min
        FROM   xx_po_vendor_sites_kff XPVSK
        WHERE  XPVSK.vs_kff_id     = lc_attribute10;

         
        IF (lc_prepaid_code IS NULL OR
            lc_vendor_min IS NULL ) THEN
            
            RETURN(lc_po_status); -- Returning 'PASS' if either vendor minimum or prepaid code is unavailable
            
        ELSIF lc_prepaid_code  = 'DL' THEN
            
            IF NVL(lc_vendor_min,0) = 0 THEN
                
                lc_po_status := 'FAIL';
                RETURN (lc_po_status);-- Returning 'FAIL' if vendor minimum is 0 for 'DL' prepaid code
            
            END IF;
            
            IF lc_inv_curr_code <> p_po_currency THEN
                
                -- Fetching po amount Converted from PO Currency into supplier currency
                SELECT (p_po_amount * GDL.conversion_rate)  converted_po_amount
                INTO    ln_po_amount
                FROM    gl_daily_rates   GDL
                WHERE   GDL.from_currency                = p_po_currency
                AND     GDL.to_currency                  = lc_inv_curr_code
                AND     GDL.conversion_type              = 'Corporate'
                AND     GDL.conversion_date              = TRUNC(SYSDATE);
                
            
            ELSE 

                ln_po_amount := p_po_amount;

            END IF;
            
            IF ln_po_amount >= (TO_NUMBER(lc_vendor_min)) THEN
                RETURN (lc_po_status); -- Returning 'PASS' for po amount greater than vendor minimum
            ELSE
                lc_po_status := 'FAIL'; -- Returning 'FAIL' if po amount is lesser than vendor minimum
                RETURN (lc_po_status);
            END IF;

        ELSIF lc_prepaid_code  <> 'DL' THEN  
            RETURN (lc_po_status);  -- Returning 'PASS' if  prepaid code is not 'DL'
        END IF;


    EXCEPTION
        
    WHEN OTHERS THEN
    
        x_error_msg      := SUBSTR(SQLERRM,1,240);
        lc_po_status     := 'FAIL';
        RETURN (lc_po_status);

    END main_calc_vendor_min;

END XX_PO_VEN_MIN_PKG   ;
/
SHOW ERRORS;
EXIT;
