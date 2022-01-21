SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_ITEM_FORM_PER_PKG AUTHID CURRENT_USER
AS 
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                  |
-- +==============================================================================+
-- | Name       : XX_INV_ITEM_FORM_PER_PKG                                        |
-- | Description: This package checks if the given item displayed in the Master   |
-- |              Item or the Organization Item Forms has Item Type as 'TRADE' Or |
-- |              'COMMON' corresponds to segment2 of category set ‘PO_CATEGORY’. |
-- |                                                                              |
-- |Change Record:                                                                |
-- |==============                                                                |
-- |Version   Date         Author           Remarks                               |
-- |=======   ==========   ===============  ======================================|
-- |DRAFT 1A  16-MAY-2007  Siddharth Singh  Initial version                       |
-- |DRAFT 1B  14-JUN-2007  Sriramdas S      Incorporated Peer review comments     |
-- |DRAFT 1C  14-JUN-2007  Jayshree Kale    Reviewed and updated                  |
-- |1.0       19-JUL-2007  Jayshree Kale    Baselined.                            |
-- +==============================================================================+

FUNCTION IS_TRADE_ITEM (p_inv_item_id IN NUMBER , p_org_id IN NUMBER)
RETURN VARCHAR2 ;

END XX_INV_ITEM_FORM_PER_PKG;
/

SHOW ERRORS;

EXIT;
