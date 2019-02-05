SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_VEN_MIN_PKG AUTHID CURRENT_USER 
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_PO_VEN_MIN_PKG                                         |
-- | Description      : Package Specification containing function to   | 
-- |                    return PASS or FAIL value depending upon the   |
-- |                    PO total amount and vendor minimum amount.     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1a   11-May-2007   Remya Sasi       Initial draft version    |
-- |1.0        17-May-2007   Remya Sasi       Baseline                 |
-- |                                                                   |
-- +===================================================================+


--This Function will be used to validate vendor minimum amount.
FUNCTION main_calc_vendor_min (
                             p_supplier_site_id  IN  NUMBER
                            ,p_po_amount         IN  NUMBER
                            ,p_po_currency       IN  VARCHAR2
                            ,x_error_msg         OUT VARCHAR2
                            )
RETURN VARCHAR2;


END XX_PO_VEN_MIN_PKG;
/
SHOW ERRORS;
EXIT;