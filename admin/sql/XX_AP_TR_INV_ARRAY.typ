SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        :XX_AP_TR_INV_ARRAY                                       |
-- | Description : Create xx_ap_invoice_array_type                         |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | RICE ID : E3523                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     01-Sep-2017 Paddy Sanjeevi     Baselined                      |
-- +=======================================================================+

SET TERM ON
PROMPT Creating Record type XX_AP_TR_INV_ARRAY
SET TERM OFF


create or replace TYPE XX_AP_TR_INV_ARRAY AS TABLE OF varchar2(100)
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF