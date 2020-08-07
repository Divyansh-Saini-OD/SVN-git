SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPEC XX_AP_INV_BLD_NON_PO_LINES_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AP_INV_BLD_NON_PO_LINES_PKG
AS
-- +===============================================================================================+
-- |                  Office Depot - Project Simplify                                              |
-- |                       WIPRO Technologies                                                      |
-- +===============================================================================================+
-- | Name :  XX_AP_INV_BLD_PO_LINES_PKG                                                            |
-- | Description :  This package is used to create invoices distribution lines for Non PO related  |
-- |                invoices.This package is created as part of the fix for defect 3845 and CR #326|
-- |                                                                                               |
-- |                                                                                               |
-- |Change Record:                                                                                 |
-- |===============                                                                                |
-- |Version   Date           Author                 Remarks                                        |
-- |======   ==========     =============           =======================                        |
-- |1.0       08-JAN-2008   Aravind A.              Initial draft version                          |
-- |1.1       03-MAR-2008   Aravind A.              Fixed defect 4998 and CR 354                   |
-- +===============================================================================================+

-- +===================================================================+
-- | Name        : XX_AP_CREATE_NON_PO_INV_LINES                       |
-- |                                                                   |
-- | Description : This procedure is used to create invoices           |
-- |               distribution lines for Non PO invoices.             |
-- |                                                                   |
-- | Parameters  : p_source                                            |
-- |                                                                   |
-- | Returns     :                                                     |
-- +===================================================================+

   PROCEDURE xx_ap_create_non_po_inv_lines (p_source IN VARCHAR2);

END XX_AP_INV_BLD_NON_PO_LINES_PKG;

/
SHOW ERROR