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
-- |1.1        30-Jul-2007       Vikas Raina      Refer to view xx_po_vendor_sites_kff_v     |
-- |1.2        10-Dec-2007       Vikas Raina      Added to fetch from po_system_parameters   |
-- |                                              If the conversion rate is not found then   |
-- |                                              the status is set to 'FAIL' as per Victor's|
-- |                                              code review comments                       |
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
-- | Returns :          x_error_msg                                    |
-- |                    VARCHAR2                                       |
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
    lc_vendor_min       xx_po_vendor_sites_kff_v.min_prepaid_code%TYPE    := NULL;
    lc_po_status        VARCHAR2(10)   := 'PASS';
    lc_prepaid_code     xx_po_vendor_sites_kff_v.min_prepaid_code%TYPE    := NULL;
    ln_po_amount        NUMBER          := 0;
    lc_inv_curr_code    po_vendor_sites.invoice_currency_code%TYPE        := NULL;
    ln_org_id           po_vendor_sites_all.org_id%TYPE                   := NULL;

    BEGIN
        
        x_error_msg := NULL;
        
        -- Fetching the invoice currency code from the given supplier site id
        
        SELECT  PVS.invoice_currency_code
               ,XPVSK.min_prepaid_code
               ,XPVSK.vendor_min_amount
               ,org_id                     -- V1.2
        INTO    lc_inv_curr_code
               ,lc_prepaid_code
               ,lc_vendor_min
               ,ln_org_id
        FROM    po_vendor_sites_all PVS
               ,xx_po_vendor_sites_kff_v XPVSK
        WHERE   PVS.vendor_site_id  = p_supplier_site_id
        AND     XPVSK.vendor_site_id = PVS.vendor_site_id ;
        
        IF lc_inv_curr_code IS NULL THEN
        
            lc_po_status := 'FAIL'; -- Returning 'FAIL' if invoice_currency_code doesnt exist
            RETURN (lc_po_status);
            
        END IF;                
         
        IF (lc_prepaid_code IS NULL OR
            lc_vendor_min IS NULL ) THEN
            
            RETURN(lc_po_status); -- Returning 'PASS' if either vendor minimum or prepaid code is unavailable
            
        ELSIF lc_prepaid_code  = 'DL' THEN
            
            IF NVL(lc_vendor_min,0) = 0 THEN
                
                lc_po_status := 'FAIL';
                RETURN (lc_po_status);-- Returning 'FAIL' if vendor minimum is 0 for 'DL' prepaid code
            
            END IF; -- IF NVL(lc_vendor_min,0) = 0 THEN
            
            IF lc_inv_curr_code <> p_po_currency THEN
                
                -- Fetching po amount Converted from PO Currency into supplier currency
                -- Added Exception for for V1.2
              BEGIN
                SELECT (p_po_amount * GDL.conversion_rate)  converted_po_amount
                INTO    ln_po_amount
                FROM    gl_daily_rates   GDL
                       ,po_system_parameters_all psp                              -- V1.2
                WHERE   GDL.from_currency                = p_po_currency
                AND     GDL.to_currency                  = lc_inv_curr_code
--              AND     GDL.conversion_type              = 'Corporate'            -- V1.2
                AND     GDL.conversion_date              = TRUNC(SYSDATE)
                AND     psp.org_id                       = ln_org_id
                AND     GDL.conversion_type              = psp.default_rate_type; -- V1.2
                
             EXCEPTION
             
             -- ****************************************************************************
             --  If the conversion rate is not found then the status should be set to   
             --  'FAIL', so the pre-processor will create the PO in incomplete status.
             -- ****************************************************************************
                WHEN NO_DATA_FOUND THEN
                    x_error_msg      := 'For Operating Unit:'||ln_org_id||'  '||SUBSTR(SQLERRM,1,240);
                    lc_po_status     := 'FAIL';
                    RETURN (lc_po_status);
             END;
            
            ELSE 

                ln_po_amount := p_po_amount;

            END IF; -- IF lc_inv_curr_code <> p_po_currency THEN
            
            IF ln_po_amount >= (TO_NUMBER(lc_vendor_min)) THEN
                RETURN (lc_po_status); -- Returning 'PASS' for po amount greater than vendor minimum
            ELSE
                lc_po_status := 'FAIL'; -- Returning 'FAIL' if po amount is lesser than vendor minimum
                RETURN (lc_po_status);
            END IF;

        ELSIF lc_prepaid_code  <> 'DL' THEN  
        
           RETURN (lc_po_status);  -- Returning 'PASS' if  prepaid code is not 'DL'
        
        END IF; --  IF lc_inv_curr_code IS NULL THEN


    EXCEPTION
    
    WHEN NO_DATA_FOUND THEN    
        lc_po_status     := 'PASS';
        RETURN (lc_po_status); -- Returning 'PASS' if NO Data is found  
        
    WHEN OTHERS THEN    
        x_error_msg      := SUBSTR(SQLERRM,1,240);
        lc_po_status     := 'FAIL';
        RETURN (lc_po_status);

    END main_calc_vendor_min;

END XX_PO_VEN_MIN_PKG   ;
/
SHOW ERRORS;

EXIT;
