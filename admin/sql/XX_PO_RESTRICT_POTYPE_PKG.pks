SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_RESTRICT_POTYPE_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_RESTRICT_POTYPE_PKG                                            |
-- | Description      : Package spec for E0316 restrict by PO Type                           |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   25-MAR-2007       Vikas Raina      Initial draft version                      |
-- |DRAFT 1B   29-Jun-2007       Susheel Raina    Changes as per RCL Id NNNN                 |
-- |1.0        30-Jun-2007       Vikas Raina      Baselined after testing                    |
-- |1.1        07-DEC-2017       Uday Jadhav      Added new function validate_po_resp_access |
-- |                                             for Trade and Non Trade PO resp.              |
-- +=========================================================================================+
AS

FUNCTION PO_GET_POTYPE_PRED(
    p_schema  IN VARCHAR2,
    p_object  IN VARCHAR2)

    RETURN VARCHAR2 ;

FUNCTION PO_TYPE_HDR_PRED(
    p_schema  IN VARCHAR2,
    p_object  IN VARCHAR2)

    RETURN VARCHAR2 ;

FUNCTION validate_po_resp_access(
        p_resp_id IN NUMBER, 
        p_attribute_category IN VARCHAR2, 
        p_attribute1 IN VARCHAR2)
    RETURN VARCHAR2;

PROCEDURE SET_OD_PO_CONTEXT;

PROCEDURE CLEAR_OD_PO_CONTEXT;


END XX_PO_RESTRICT_POTYPE_PKG;
/
SHOW ERRORS

EXIT ;

