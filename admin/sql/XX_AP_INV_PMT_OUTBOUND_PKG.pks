--@c:\build\I0159\xxapobips.pls
-- drop package XX_AP_INV_PMT_OUTBOUND_PKG;

--WHENEVER SQLERROR CONTINUE 
REM ============================================================================
REM Create the package:
REM ============================================================================
--PROMPT Creating package APPS.XX_AP_INV_PMT_OUTBOUND_PKG . . .
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package  XX_AP_INV_PMT_OUTBOUND_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_AP_INV_PMT_OUTBOUND_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Providge  Consulting                        |
-- +===================================================================+
-- | Name             :   XX_AP_INV_PMT_OUTBOUND_PKG                   |
-- | Description      :   Generate AP Invoice Payments outbound files  |
-- |                      to Below Vendor Applications                 |
-- |                      1. Big Sky          2. Consignment Inventory |
-- |                      3. Retail Lease     4. Financial Planning    |
-- |                      5. Sales Accounting 6. PAID  7. TDM  8. GSS  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0       05-Mar-2007  Sarat Uppalapati    Initial version         |
-- |1.1       13-Oct-2008  Sandeep Pandhare    11935 - Add Date        |
-- |                                           Input Parameter         |
-- |1.2       15-Apr-2010  Dhanya V            Defect 3254-Add         |
-- |                                          Interface Input Parameter|
-- +===================================================================+
IS
-- +===================================================================+
-- |         Name : START_PROCESS                                      |
-- | Description : This procedure will be the executable of concurrent |
-- |               program, to call the vendor procedures defined in   |
-- |              this package to create invoice payment outbound      |
-- |                   files to the below vendor applications          |
-- |                      1. Big Sky          2. Consignment Inventory |
-- |                      3. Retail Lease     4. Financial Planning    |
-- |                      5. Sales Accounting 6. PAID  7. TDM  8. GSS  |
-- | Program: "OD: AP Invoice Payments Outbound Interface to Vendors"  |
-- |   Parameters: p_errbuff, p_retcode                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE START_PROCESS ( p_errbuf  OUT VARCHAR2
                         ,p_retcode OUT VARCHAR2
                         ,p_extract_date IN VARCHAR2
                         ,p_Interface    IN VARCHAR2                    --Added for the Defect 3254.
                         );
END XX_AP_INV_PMT_OUTBOUND_PKG;
/
SHOW ERR