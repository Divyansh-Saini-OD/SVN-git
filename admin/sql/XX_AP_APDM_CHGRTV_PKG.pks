SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_APDM_CHGRTV_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  XX_AP_APDM_CHGRTV_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   APDM Report                                            |
-- | Rice id  :   R1050                                                  |
-- | Description : Checks if the data is available and to submit         |
-- |               the APDM concurrent program to get output             |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       25-JUL-2007   Sambasiva Reddy D     Initial version        |
-- |                       Wipro Technologies                            |
-- +=====================================================================+

-- +==========================================================================+
-- | Name : APDMREP                                                           |
-- | Description : Checks if the data is available and to submit              |
-- |               the APDM concurrent program to get output                  |
-- |                                                                          |
-- | Parameters :  None                                                       |
-- |                                                                          |
-- |   Returns :    x_error_buff,x_ret_code                                   |
-- +==========================================================================+

   PROCEDURE APDMREP(
                     x_error_buff  OUT  VARCHAR2
                    ,x_ret_code    OUT  NUMBER
                     );

END XX_AP_APDM_CHGRTV_PKG;
/

SHO ERR 