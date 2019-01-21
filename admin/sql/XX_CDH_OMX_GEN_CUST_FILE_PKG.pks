CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_GEN_CUST_FILE_PKG 
AS
-- +===============================================================================+
-- |                        Office Depot                                           |
-- +===============================================================================+
-- | Name  : XX_CDH_OMX_GEN_CUST_FILE_PKG                                          |
-- | Rice ID: C0700                                                                |
-- | Description      : This program will extract the records from the             |
-- |                    xx_cdh_sfdc_mod4_cust_stg table and generate the position  |
-- |                    based file and sent to OMX                                 |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version Date        Author            Remarks                                  |
-- |======= =========== =============== ===========================================|
-- |1.0     13-FEB-2015 Havish Kasina   Initial draft version                      |
-- |2.0     06-MAR-2015 Havish Kasina   Code Review Changes                        |
-- +===============================================================================+

   g_debug_flag  BOOLEAN;
   PROCEDURE EXTRACT (
                         x_retcode              OUT NOCOPY      NUMBER,
                         x_errbuf               OUT NOCOPY      VARCHAR2,
                         p_status               IN              VARCHAR2,
                         p_debug_flag           IN              VARCHAR2,
                         p_aops_customer_number IN              VARCHAR2      
   );
END;
/
SHOW ERRORS;

