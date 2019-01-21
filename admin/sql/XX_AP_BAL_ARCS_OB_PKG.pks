create or replace package XX_AP_BAL_ARCS_OB_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_BAL_ARCS_OB_PKG                                                       |
-- |  RICE ID 	 :  AP Balances Outbound Interface to ARCS   	                                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         23-APR-18    CREDROIUTHU      Initi1:1             |
-- +============================================================================================+


PROCEDURE populate_ap_out_file(p_errbuf  OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_period_name   IN  VARCHAR2
                      	 ,p_debug         IN  VARCHAR2);

PROCEDURE process_ap_balances_ob (p_errbuf  OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_period_name    IN   VARCHAR2
                      	 ,p_debug         IN   VARCHAR2);


END XX_AP_BAL_ARCS_OB_PKG;
/