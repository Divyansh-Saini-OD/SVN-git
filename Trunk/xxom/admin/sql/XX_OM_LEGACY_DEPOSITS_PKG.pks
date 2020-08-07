CREATE OR REPLACE PACKAGE apps.xx_om_legacy_deposits_pkg
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_POS_RECEIPT_PKG                                                              |
-- |                                                                                            |
-- |  Description:  This package creates a report of transactions that are in error status in   |
-- |                XX_OM_LEGACY_DEPOSITS table                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         18-Mar-2016  Shubhashree Rajanna  Initial version                              |
-- +============================================================================================+
   PROCEDURE  create_legacy_deposits_err_rpt (   x_retcode       OUT NOCOPY NUMBER,
                                                 x_errbuf        OUT NOCOPY VARCHAR2,
                                                 p_from_date     IN  VARCHAR2,
                                                 p_to_date       IN  VARCHAR2,
                                                 p_process_code  IN  VARCHAR2,
                                                 p_i1025_status  IN  VARCHAR2,
                                                 p_od_payment_type  IN  VARCHAR2,
                                                 p_single_pay_ind   IN  VARCHAR2,
                                                 p_i1025_message    IN  VARCHAR2);
                                                 
END xx_om_legacy_deposits_pkg;
/

SHOW ERRORS;
