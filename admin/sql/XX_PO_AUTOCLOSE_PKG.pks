SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_AUTOCLOSE_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_AUTOCLOSE_PKG                                                  |
-- | Description      : Package spec for PO Auto Close                                       |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   05-MAR-2007      Madhusudan Aray   Initial draft version                      |
-- |DRAFT 1B   09-APR-2007      Madhusudan Aray   Incorporated Peer review Comments          |
-- |1.0        09-APR-2007      Madhusudan Aray   Base line                                  |
-- +=========================================================================================+
AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : AUTOCLOSEPO                                                          |
-- | Description      : This procedure is used to call a standard API "PO_ACTIONS.close_po"  |
-- |                      that will close the PO Lines based on the inactivity criteria.     |
-- |                    This procedure will print Supplier Name, Supplier No, PO No,         |
-- |                      Promise Date and Last Receipt Date  in the output.                 |
-- | Parameters       : p_inactive_days                                                      |
-- |                    p_po_type                                                            |
-- |                    p_debug_flag                                                         |
-- |                    x_err_buf                                                            |
-- |                    x_ret_code                                                           |
-- +=========================================================================================+


PROCEDURE  AUTOCLOSEPO (x_err_buf        OUT  VARCHAR2
                       ,x_ret_code       OUT  NUMBER
                       ,p_inactive_days  IN   NUMBER
                       ,p_po_type        IN   VARCHAR2
                       ,p_debug_flag     IN   VARCHAR2
                       );
                       
END XX_PO_AUTOCLOSE_PKG;
/
SHOW ERRORS;
EXIT;
