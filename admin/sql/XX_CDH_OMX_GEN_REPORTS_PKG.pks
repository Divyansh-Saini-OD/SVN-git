CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_GEN_REPORTS_PKG 
AS
-- +============================================================================================+
-- |                        Office Depot                                                        |
-- +============================================================================================+
-- | Name  : XX_CDH_OMX_GEN_REPORTS_PKG                                                         |
-- | Rice ID: C0700                                                                             |
-- | Description      : This package is used to generate Address Exception report ,             |
-- |                    MOD4 status report,sfdc status file and ebill contacts exception report |                                                                      
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version Date        Author            Remarks                                               |
-- |======= =========== =============== ========================================================|
-- |1.0     26-FEB-2015 Havish Kasina   Initial draft version                                   |
-- |2.0     13-MAR-2015 Havish Kasina   Code review changes                                     |
-- |3.0     31-MAR-2015 Havish Kasina   changes done as per defect id: 1009                     |
-- +============================================================================================+
   
  PROCEDURE gen_address_exception_report 
  (
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_execution_date       IN              VARCHAR2,
      p_status               IN              VARCHAR2,
      p_debug_flag           IN              VARCHAR2      
  );
  
  PROCEDURE generate_sfdc_status_file 
  ( 
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_execution_date       IN              VARCHAR2,
      p_debug_flag           IN              VARCHAR2      
  );
  
  PROCEDURE gen_ebillcont_exception_report 
  ( 
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_execution_date       IN              VARCHAR2,
      p_debug_flag           IN              VARCHAR2,
      p_status               IN              VARCHAR2,
      p_aops_acct_number     IN              VARCHAR2      
  );
  
  PROCEDURE reconcile_omx_counts 
  (
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_batch_id             IN              NUMBER,
      p_debug_flag           IN              VARCHAR2,
      p_status               IN              VARCHAR2,
      p_execution_date       IN              VARCHAR2
  );
  
  PROCEDURE generate_status_report 
  (
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_execution_date       IN              VARCHAR2,
      p_debug_flag           IN              VARCHAR2,
      p_aops_acct_number     IN              VARCHAR2
  );
 
END;
/
SHOW ERRORS;

