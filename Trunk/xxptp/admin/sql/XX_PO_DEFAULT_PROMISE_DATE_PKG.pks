SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_DEFAULT_PROMISE_DATE_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_DEFAULT_PROMISE_DATE_PKG                                       |
-- | Description      : Package spec for Default Promise Date                                |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   26-MAY-2007      Madhusudan Aray   Initial draft version                      |
-- |DRAFT 1B   04-JUN-2007      Madhusudan Aray   Updated after RCCL                         |
-- |1.0        13-JUN-2007      Vikas Raina       Baselined                                  |
-- |1.1        13-JUL-2007      Santosh Borude    Updated as per onsite issue log comments   |
-- +=========================================================================================+

 AS 
 -- +========================================================================================+
 -- |                        Office Depot - Project Simplify                                 |
 -- |            Oracle NAIO/Office Depot/Consulting Organization                            |
 -- +========================================================================================+
 -- | Name             : CALC_PROMISE_DATE                                                   |
 -- | Description      : This function is used to derive the promise date.                   |
 -- | Parameters       : p_item                                                              |
 -- |                    p_supplier_site                                                     |
 -- |                    p_po_type                                                           |
 -- |                    p_revision_num                                                      |
 -- |                    p_order_date                                                        |
 -- |                    p_promise_date                                                      |
 -- |                    p_ship_to_location_id                                               |
 -- |                    x_error_status                                                      |
 -- +========================================================================================+
    FUNCTION  calc_promise_date ( p_item                IN  NUMBER
                                 ,p_supplier            IN  NUMBER
                                 ,p_po_type             IN  VARCHAR2
                                 ,p_revision_num        IN  NUMBER
                                 ,p_order_date          IN  VARCHAR2
                                 ,p_promise_date        IN  VARCHAR2
                                 ,p_ship_to_location_id IN  NUMBER
                                 ,p_ship_to_org_id      IN  NUMBER
                                 ,x_error_status        OUT NUMBER )

    RETURN DATE ;

    END XX_PO_DEFAULT_PROMISE_DATE_PKG ;
/
SHOW ERRORS ;

EXIT ;
