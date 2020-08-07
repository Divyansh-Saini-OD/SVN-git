SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_GI_TO_AP_CONSIGN_LOAD_PKG 
--Version Draft 1A
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_TO_AP_CONSIGN_LOAD_PKG                                  |
-- |Purpose      : This package contains procedures that picks up the            |
-- |                consignment data from GL staging table(Custom) and transform |
-- |                it into consignment invoices to AP staging table(Custom).    |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |XX_GI_TO_AP_STG              : S,U                                           |
-- |XX_AP_INV_INTERFACE_STG      : I                                             |
-- |XX_AP_INV_LINES_INTERFACE_STG: I                                             |
-- |XX_AP_INV_BATCH_INTERFACE_STG: I,U                                           | 
-- |HR_ORG_INFORMATION           : S                                             |
-- |PO_VENDOR_SITES_ALL          : S                                             |
-- |PO_VENDORS                   : S                                             |
-- |AP_TERMS               
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  16-Oct-2007   Arun Andavar     Draft version                        |
-- +=============================================================================+
IS
PROCEDURE TRANSFORM_TO_AP_INVOICE_STG(x_error_message        OUT VARCHAR2
                                     ,x_error_code           OUT PLS_INTEGER
                                     ,p_daily_or_weekly      IN  VARCHAR2
                                     );


END XX_GI_TO_AP_CONSIGN_LOAD_PKG;
/
EXIT