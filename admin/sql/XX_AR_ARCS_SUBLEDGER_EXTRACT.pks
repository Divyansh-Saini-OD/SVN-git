CREATE OR REPLACE 
PACKAGE XX_AR_ARCS_SUBLEDGER_EXTRACT
AS
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 	 	:  XX_AR_ARCS_SUBLEDGER_EXTRACT                                             |
-- |  Description	:  PLSQL Package to extract AR Subledger Accounting Information             |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
PROCEDURE subledger_arcs_extract(p_errbuf       OUT  VARCHAR2
							 ,   p_retcode      OUT  VARCHAR2
                             ,   p_period_name  IN   VARCHAR2
                                );
END XX_AR_ARCS_SUBLEDGER_EXTRACT;
/