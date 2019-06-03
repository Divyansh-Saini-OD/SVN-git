CREATE OR REPLACE PACKAGE APPS.XX_PO_INTERFACE_PURGE_PKG AUTHID CURRENT_USER
-- +==================================================================================+
-- |                      Office Depot - Project Simplify                             |
-- |                                                                                  |
-- +==================================================================================+
-- | Name  :       XX_PO_INTERFACE_PURGE_PKG.pks                                      |
-- | Description:  This package deletes data from the Purchasing Interface Tables by  |
-- |               PO TYpe and number of days                                         |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version    Date           Author                       Remarks                    |
-- |=======   =============  ================    =====================================|
-- |1.0       01-MARCH-2008  Victor Costa        Baselined.                           |
-- +==================================================================================+
AS
PROCEDURE xx_po_main_purge(
        X_error_buff           OUT   VARCHAR2,
        X_ret_code             OUT   VARCHAR2,
        X_od_po_type           IN    VARCHAR2,
        X_accepted_flag        IN    VARCHAR2,
        X_rejected_flag        IN    VARCHAR2,
        X_number_of_days       IN    NUMBER);
END XX_PO_INTERFACE_PURGE_PKG; 
/

