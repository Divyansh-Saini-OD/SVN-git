CREATE OR REPLACE PACKAGE APPS.xx_cdh_omx_cust_info_pkg
AS
-- +=========================================================================+
-- |                        Office Depot                                      |
-- +=========================================================================+
-- | Name  : xx_cdh_omx_cust_info_pkg                                         |
-- | Rice ID: C0702                                                          |
-- | Description      : This Program will extract all the Credit                |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
--|1.0      02-MAR-2015 Abhi K          Initial draft version                |
--|1.01     15-MAR-2015 Abhi K          Code review  Version                 |
-- +=========================================================================+

   PROCEDURE EXTRACT (
      x_retcode                      OUT NOCOPY NUMBER,
      x_errbuf                       OUT NOCOPY VARCHAR2,
      p_status                       IN            VARCHAR2,
      p_debug_flag                   IN            VARCHAR2,
      p_aops_acct_number             IN            xx_cdh_omx_cust_info_stg.aops_customer_number%TYPE,
      p_default_statement_cycle      IN            xx_cdh_omx_cust_info_stg.statement_cycle%TYPE,
       p_default_credit_limit        IN              NUMBER );
      
   
END; 
/
SHOW ERRORS;
